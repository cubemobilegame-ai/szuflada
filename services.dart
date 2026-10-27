import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'core.dart';
import 'ui.dart';

// Przypomnienia: lokalne powiadomienia, działają przy zamkniętej aplikacji
final openItemN = ValueNotifier<int?>(null); // dotknięte powiadomienie -> otwórz dokument
class Notifier {
  static final _p = FlutterLocalNotificationsPlugin();
  static AndroidFlutterLocalNotificationsPlugin? get _a => _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  static const _details = NotificationDetails(android: AndroidNotificationDetails('gwarancje', 'Przypomnienia o gwarancjach',
      channelDescription: 'Koniec gwarancji, zwroty i terminy reklamacji', importance: Importance.high, priority: Priority.high, color: Color(0xFF5A3DF0)));
  static void _open(NotificationResponse r) { final id = int.tryParse(r.payload ?? ''); if (id != null) openItemN.value = id; }
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    try {
      await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('ic_stat_szuflada')), onDidReceiveNotificationResponse: _open);
    } catch (_) {
      await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')), onDidReceiveNotificationResponse: _open);
    }
    try {
      final l = await _p.getNotificationAppLaunchDetails();
      final r = l?.notificationResponse;
      if (l != null && l.didNotificationLaunchApp && r != null) _open(r);
    } catch (_) {}
  }
  static Future<bool> enabled() async { try { return await _a?.areNotificationsEnabled() ?? true; } catch (_) { return true; } }
  static Future<bool> request() async { try { return await _a?.requestNotificationsPermission() ?? true; } catch (_) { return false; } }
  static Future<void> test() => _p.show(1, 'Szuflada', 'Tak będą wyglądać przypomnienia o końcu gwarancji.', _details);
  static Future<void> reschedule(List<Item> items) async {
    await _p.cancelAll();
    final now = DateTime.now(); var n = 0;
    for (final r in remindersFor(items)) {
      final at = DateTime(r.d.year, r.d.month, r.d.day, store.remindHour);
      if (at.isBefore(now)) continue;
      if (++n > 400) break; // Android ogranicza liczbę zaplanowanych alarmów
      await _p.zonedSchedule(
        (r.it.id % 100000000) * 10 + r.kind, r.it.name, r.txt, tz.TZDateTime.from(at, tz.UTC), _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, payload: '${r.it.id}',
      );
    }
  }
}

// Płatności: Google Play Billing (subskrypcja roczna)
class Billing {
  static const sku = 'szuflada_plan_roczny'; // ID produktu z Play Console (Monetyzacja -> Subskrypcje)
  static ProductDetails? product; // pełna cena (plan bazowy)
  static ProductDetails? trial;   // oferta z darmowym okresem - tylko jeśli Google pokazuje ją temu użytkownikowi
  static bool available = false;
  static String get price => product?.price ?? '29,99 zł';
  static bool get hasTrial => trial != null;
  static String get note => hasTrial
      ? 'Potem $price rocznie. Subskrypcja odnawia się automatycznie, anulujesz ją w każdej chwili w Google Play.'
      : 'Subskrypcja odnawia się automatycznie co rok. Anulujesz ją w każdej chwili w Google Play.';
  static String get buyLabel => hasTrial ? 'Wypróbuj $trialLabel za darmo' : 'Wykup Pro – $price / rok';
  // długość okresu próbnego z oferty Google (np. P14D, P1W, P1M); gdy się nie da odczytać - tekst ogólny
  static String get trialLabel {
    try {
      final dd = trial as dynamic;
      final String p = dd.productDetails.subscriptionOfferDetails[dd.subscriptionIndex].pricingPhases.first.billingPeriod;
      final m = RegExp(r'^P(?:(\d+)Y)?(?:(\d+)M)?(?:(\d+)W)?(?:(\d+)D)?$').firstMatch(p);
      if (m != null) {
        final y = int.tryParse(m.group(1) ?? '') ?? 0, mo = int.tryParse(m.group(2) ?? '') ?? 0;
        final w = int.tryParse(m.group(3) ?? '') ?? 0, d = int.tryParse(m.group(4) ?? '') ?? 0;
        final days = w * 7 + d;
        if (y == 0 && mo == 0 && days > 0) return '$days ${days == 1 ? 'dzień' : 'dni'}';
        if (y == 0 && mo > 0 && days == 0) return mo == 1 ? 'miesiąc' : '$mo mies.';
      }
    } catch (_) {}
    return 'okres próbny';
  }
  static Future<void> init() async {
    final iap = InAppPurchase.instance;
    try { available = await iap.isAvailable(); } catch (_) { available = false; }
    if (!available) return;
    iap.purchaseStream.listen((list) async {
      for (final p in list) {
        if (p.productID == sku && (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)) {
          final was = store.pro; await store.setPro();
          if (!was && p.status == PurchaseStatus.purchased) toast('Dziękujemy! Szuflada Pro jest aktywna.');
        }
        if (p.status == PurchaseStatus.pending) toast('Płatność oczekuje na potwierdzenie.');
        if (p.status == PurchaseStatus.error) toast('Płatność nie powiodła się. Spróbuj ponownie.');
        if (p.pendingCompletePurchase) await iap.completePurchase(p); // potwierdzenie zakupu (acknowledge) - bez tego Google zwraca pieniądze po 3 dniach
      }
    }, onError: (_) {});
    try {
      final r = await iap.queryProductDetails({sku});
      final list = r.productDetails.where((d) => d.id == sku).toList();
      if (list.isNotEmpty) {
        list.sort((a, b) => b.rawPrice.compareTo(a.rawPrice)); // najdroższa pozycja = plan bazowy
        product = list.first;
        trial = null;
        for (final d in list) { if (d.rawPrice == 0) { trial = d; break; } }
        store.touch();
      }
      await iap.restorePurchases();
    } catch (_) {}
  }
  static Future<bool> buy() async {
    final d = trial ?? product; if (d == null) return false;
    try { return await InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d)); } catch (_) { return false; }
  }
  static Future<void> restore() async { try { await InAppPurchase.instance.restorePurchases(); } catch (_) {} }
}

// Udostępnianie dokumentu (zdjęcie + opis)
Future<void> shareItem(Item it) async {
  final txt = '${it.name}${it.store.isNotEmpty ? ' (${it.store})' : ''}\nZakup: ${fmtD.format(it.date)}${it.price > 0 ? ' · ${money(it.price)}' : ''}\nGwarancja do: ${fmtD.format(it.end)}${it.docNo.isNotEmpty ? '\n${it.doc} nr ${it.docNo}' : ''}';
  final f = store.img(it.photo);
  if (f != null && await f.exists()) { await Share.shareXFiles([XFile(f.path)], text: txt); } else { await Share.share(txt); }
}

// Blokada: odcisk palca, twarz lub PIN telefonu
class Auth {
  static final _a = LocalAuthentication();
  static Future<bool> supported() async { try { return await _a.isDeviceSupported(); } catch (_) { return false; } }
  // null = sukces, w przeciwnym razie kod: 'cancel' lub kod błędu systemu
  static Future<String?> unlock() async {
    try {
      final ok = await _a.authenticate(localizedReason: 'Odblokuj Szufladę', options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true));
      return ok ? null : 'cancel';
    } on PlatformException catch (e) { return e.code; } catch (e) { return 'error: $e'; }
  }
}

// Kopia zapasowa: ZIP z danymi i zdjęciami
class Backup {
  static Future<void> export() async {
    final a = Archive();
    final js = utf8.encode(jsonEncode({'v': 1, 'items': store.items.map((e) => e.toJson()).toList(), 'me': store.me}));
    a.addFile(ArchiveFile('data.json', js.length, js));
    for (final it in store.items) {
      for (final n in [it.photo, it.claim?.photo]) {
        final f = store.img(n);
        if (f != null && await f.exists()) { final b = await f.readAsBytes(); a.addFile(ArchiveFile('img/$n', b.length, b)); }
      }
    }
    final p = '${(await getTemporaryDirectory()).path}/szuflada-kopia-${DateTime.now().toIso8601String().substring(0, 10)}.zip';
    await File(p).writeAsBytes(ZipEncoder().encode(a)!);
    await Share.shareXFiles([XFile(p)], text: 'Kopia zapasowa Szuflady');
  }
  // Zwraca liczbę dodanych pozycji, -1 gdy plik jest nieprawidłowy lub anulowano
  static Future<int> import() async {
    final r = await FilePicker.platform.pickFiles();
    final path = r?.files.single.path; if (path == null) return -1;
    try {
      final arc = ZipDecoder().decodeBytes(await File(path).readAsBytes());
      Map? data; final ok = RegExp(r'^img/[\w.\-]+$');
      for (final f in arc) {
        if (!f.isFile) continue;
        final bytes = f.content as List<int>;
        if (f.name == 'data.json') { data = jsonDecode(utf8.decode(bytes)); }
        else if (ok.hasMatch(f.name)) { await File('${store.dir.path}/${f.name}').writeAsBytes(bytes); }
      }
      if (data == null) return -1;
      final ids = store.items.map((e) => e.id).toSet(); var n = 0;
      for (final j in (data['items'] as List)) { final it = Item.fromJson(j); if (!ids.contains(it.id)) { store.items.add(it); n++; } }
      if (store.me.isEmpty && data['me'] != null) await store.setMe(Map<String, String>.from(data['me']));
      await store.save();
      return n;
    } catch (_) { return -1; }
  }
}

// Skaner dokumentów (ML Kit), odczyt tekstu i parser paragonów / faktur
class Line { String name; double price; bool on = false; Line(this.name, this.price); }
class Parsed {
  String path, store = '', doc = 'Paragon', docNo = '', buyer = '', raw = '', nameGuess = ''; DateTime? date; double? total; List<Line> lines = [];
  Parsed(this.path);
}
class Scanner {
  static Future<Parsed?> run() async {
    final sc = DocumentScanner(options: DocumentScannerOptions(documentFormat: DocumentFormat.jpeg, mode: ScannerMode.full, pageLimit: 1, isGalleryImport: true));
    try {
      final r = await sc.scanDocument();
      final imgs = r.images;
      if (imgs == null || imgs.isEmpty) return null;
      return _ocr(imgs.first);
    } finally { sc.close(); }
  }
  // Odczyt ze zdjęcia z galerii (paragon lub faktura zapisane w telefonie)
  static Future<Parsed?> fromFile(String path) => _ocr(path);

  static Future<Parsed?> _ocr(String path) async {
    final rec = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final t = await rec.processImage(InputImage.fromFilePath(path));
      return parse(_rows(t), path);
    } finally { await rec.close(); }
  }

  // Składa tekst w wiersze według położenia na zdjęciu: nazwa produktu i cena z drugiej kolumny trafiają do jednej linii
  static String _rows(RecognizedText t) {
    final ls = <TextLine>[];
    for (final b in t.blocks) { ls.addAll(b.lines); }
    ls.sort((a, b) => a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));
    final rows = <List<TextLine>>[];
    for (final l in ls) {
      if (rows.isNotEmpty) {
        final r = rows.last;
        final cy = r.map((e) => e.boundingBox.center.dy).reduce((a, b) => a + b) / r.length;
        final h = r.map((e) => e.boundingBox.height).reduce((a, b) => a + b) / r.length;
        if ((l.boundingBox.center.dy - cy).abs() < h * 0.6) { r.add(l); continue; }
      }
      rows.add([l]);
    }
    return rows.map((r) { r.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left)); return r.map((e) => e.text).join('  '); }).join('\n');
  }

  static final _pr = RegExp(r'(\d{1,6})\s?[.,]\s?(\d{2})(?!\d)');
  static final _skip = RegExp(r'SUMA|RAZEM|PTU|SPRZED|GOT[ÓO]WK|KARTA|RESZTA|ZAP[ŁL]AT|NIP|RABAT|PODATEK|VAT|PARAGON|FISKAL|KASJER|WYDRUK|NR SYS|GODZ|OPODATK', caseSensitive: false);
  static final _letters = RegExp(r'[A-Za-zĄąĆćĘęŁłŃńÓóŚśŹźŻż]{3,}');
  static double _val(RegExpMatch m) => double.parse('${m[1]}.${m[2]}');
  static String _fix(String s) => s.replaceAllMapped(RegExp(r'(?<=\d)[Oo](?=\d)'), (_) => '0').replaceAllMapped(RegExp(r'(?<=\d)[lI](?=\d)'), (_) => '1');
  // usuwa numery artykułów i słowo „Opis”
  static String _clean(String s) => s.replaceAll(RegExp(r'^\s*\d[\d./\- ]*\s+'), '').replaceAll(RegExp(r'^Opis:?\s*', caseSensitive: false), '').trim();
  // WIELKIE LITERY -> Wielkie Litery
  static String _nice(String s) {
    final l = s.replaceAll(RegExp(r'[^A-Za-zĄąĆćĘęŁłŃńÓóŚśŹźŻż]'), '');
    if (l.isEmpty) return s;
    final low = l.replaceAll(RegExp(r'[^a-ząćęłńóśźż]'), '').length;
    if (low / l.length > .3) return s;
    return s.toLowerCase().split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  }
  // znane sklepy rozpoznawane także przy błędach odczytu (np. NEDIA MARKT)
  static const _stores = {'MARKT': 'Media Markt', 'MEDIA EXPERT': 'Media Expert', 'RTV EURO': 'RTV Euro AGD', 'X-KOM': 'x-kom', 'LEROY': 'Leroy Merlin', 'CASTORAMA': 'Castorama', 'BIEDRONKA': 'Biedronka', 'LIDL': 'Lidl', 'IKEA': 'Ikea', 'DECATHLON': 'Decathlon', 'ALLEGRO': 'Allegro', 'NEONET': 'Neonet', 'KAUFLAND': 'Kaufland', 'OBI': 'OBI', 'EMPIK': 'Empik'};

  static Parsed parse(String text, String path) {
    final p = Parsed(path)..raw = text;
    final rows = text.split('\n').map((e) => _fix(e.trim())).where((e) => e.isNotEmpty).toList();
    final up = text.toUpperCase();
    final bad = RegExp(r'^(NIP|PARAGON|FAKTURA|UL\.|\d)', caseSensitive: false);
    var storeIdx = -1;
    for (var i = 0; i < rows.length && i < 6; i++) { if (_letters.hasMatch(rows[i]) && !bad.hasMatch(rows[i])) { p.store = _nice(rows[i]); storeIdx = i; break; } }
    for (final e in _stores.entries) { if (up.contains(e.key)) { p.store = e.value; break; } }
    final d1 = RegExp(r'(\d{2})\s?[.\-/]\s?(\d{2})\s?[.\-/]\s?(\d{4})').firstMatch(text);
    final d2 = RegExp(r'(\d{4})\s?[.\-/]\s?(\d{2})\s?[.\-/]\s?(\d{2})').firstMatch(text);
    try {
      if (d2 != null) { p.date = DateTime(int.parse(d2[1]!), int.parse(d2[2]!), int.parse(d2[3]!)); }
      else if (d1 != null) { p.date = DateTime(int.parse(d1[3]!), int.parse(d1[2]!), int.parse(d1[1]!)); }
      if (p.date != null && (p.date!.year < 2000 || p.date!.isAfter(DateTime.now().add(const Duration(days: 2))))) p.date = null;
    } catch (_) { p.date = null; }

    String? p1, p2; // dwa ostatnie wiersze tekstu bez ceny (nazwa bywa rozbita na 2 linie)
    for (var i = 0; i < rows.length; i++) {
      final r = rows[i]; final prices = _pr.allMatches(r).toList();
      if (RegExp(r'SUMA|RAZEM|DO ZAP', caseSensitive: false).hasMatch(r)) { if (prices.isNotEmpty) p.total = _val(prices.last); p1 = p2 = null; continue; }
      if (_skip.hasMatch(r)) { p1 = p2 = null; continue; }
      if (prices.isEmpty) {
        if (_letters.hasMatch(r) && r.length >= 4) { p2 = p1; p1 = r; if (p.nameGuess.isEmpty && i != storeIdx && !r.toLowerCase().contains('ul.')) p.nameGuess = _nice(_clean(r)); } else { p1 = p2 = null; }
        continue;
      }
      var name = r.substring(0, prices.first.start).replaceAll(RegExp(r'(?:\s+\d+(?:[.,]\d+)?\s*[xX*])?[\s=]*$'), '').replaceAll(RegExp(r'^\d+[.)]?\s+'), '').trim();
      if (!_letters.hasMatch(name)) {
        if (p1 != null && p1.toLowerCase().startsWith('opis') && p2 != null) { name = '${_clean(p2)} – ${_clean(p1)}'; }
        else if (p1 != null) { name = _clean(p1); }
        else { name = ''; }
      }
      p1 = p2 = null;
      final price = _val(prices.last);
      if (_letters.hasMatch(name) && price > 0) p.lines.add(Line(_nice(name), price));
    }
    p.total ??= p.lines.isEmpty ? null : p.lines.map((e) => e.price).reduce((a, b) => a > b ? a : b);
    if (up.contains('FAKTURA')) {
      p.doc = 'Faktura imienna';
      final m = RegExp(r'FAKTURA\s*(?:VAT)?\s*(?:NR|NO)?\.?\s*:?\s*([A-Z0-9][A-Z0-9/\-]*\d[A-Z0-9/\-]*)').firstMatch(up);
      if (m != null) p.docNo = m[1]!;
      for (var i = 0; i < rows.length; i++) {
        if (rows[i].toUpperCase().startsWith('NABYWCA')) {
          final same = rows[i].split(':');
          p.buyer = same.length > 1 && same[1].trim().isNotEmpty ? same[1].trim() : (i + 1 < rows.length ? rows[i + 1] : '');
          break;
        }
      }
    }
    return p;
  }
}
