import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'core.dart';

// Przypomnienia: lokalne powiadomienia, działają przy zamkniętej aplikacji
class Notifier {
  static final _p = FlutterLocalNotificationsPlugin();
  static Future<void> init() async {
    tzdata.initializeTimeZones();
    await _p.initialize(const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')));
    await _p.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
  }
  static Future<void> reschedule(List<Item> items) async {
    await _p.cancelAll();
    final now = DateTime.now();
    for (final r in remindersFor(items)) {
      final at = DateTime(r.d.year, r.d.month, r.d.day, 9);
      if (at.isBefore(now)) continue;
      await _p.zonedSchedule(
        (r.it.id % 100000000) * 10 + r.kind, r.it.name, r.txt, tz.TZDateTime.from(at, tz.UTC),
        const NotificationDetails(android: AndroidNotificationDetails('gwarancje', 'Przypomnienia o gwarancjach', importance: Importance.high, priority: Priority.high)),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

// Płatności: Google Play Billing (subskrypcja roczna)
class Billing {
  static const sku = 'pro_yearly';
  static ProductDetails? product;
  static Future<void> init() async {
    final iap = InAppPurchase.instance;
    if (!await iap.isAvailable()) return;
    iap.purchaseStream.listen((list) async {
      for (final p in list) {
        if (p.productID == sku && (p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored)) await store.setPro();
        if (p.pendingCompletePurchase) await iap.completePurchase(p);
      }
    });
    final r = await iap.queryProductDetails({sku});
    if (r.productDetails.isNotEmpty) { product = r.productDetails.first; store.touch(); }
    await iap.restorePurchases();
  }
  static Future<bool> buy() async {
    final d = product; if (d == null) return false;
    return InAppPurchase.instance.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: d));
  }
  static Future<void> restore() => InAppPurchase.instance.restorePurchases();
}

// Blokada: odcisk palca, twarz lub PIN telefonu
class Auth {
  static final _a = LocalAuthentication();
  static Future<bool> supported() async { try { return await _a.isDeviceSupported(); } catch (_) { return false; } }
  static Future<bool> unlock() async {
    try { return await _a.authenticate(localizedReason: 'Odblokuj Szufladę', options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true)); } catch (_) { return false; }
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
  String path, store = '', doc = 'Paragon', docNo = '', buyer = ''; DateTime? date; double? total; List<Line> lines = [];
  Parsed(this.path);
}
class Scanner {
  static Future<Parsed?> run() async {
    final sc = DocumentScanner(options: DocumentScannerOptions(documentFormat: DocumentFormat.jpeg, mode: ScannerMode.full, pageLimit: 1, isGalleryImport: true));
    try {
      final r = await sc.scanDocument();
      final imgs = r.images;
      if (imgs == null || imgs.isEmpty) return null;
      final rec = TextRecognizer(script: TextRecognitionScript.latin);
      final t = await rec.processImage(InputImage.fromFilePath(imgs.first));
      await rec.close();
      return parse(t.text, imgs.first);
    } finally { sc.close(); }
  }

  static final _price = RegExp(r'(\d{1,6}[.,]\d{2})');
  static final _skip = RegExp(r'SUMA|RAZEM|PTU|SPRZED|GOT[ÓO]WK|KARTA|RESZTA|ZAP[ŁL]AT|NIP|RABAT|PODATEK|VAT|PARAGON|FISKAL', caseSensitive: false);
  static double _num(String s) => double.parse(s.replaceAll(',', '.'));

  static Parsed parse(String text, String path) {
    final p = Parsed(path);
    final rows = text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final up = text.toUpperCase();
    final letters = RegExp(r'[A-Za-zĄąĆćĘęŁłŃńÓóŚśŹźŻż]{3,}');
    final bad = RegExp(r'^(NIP|PARAGON|FAKTURA|UL\.|\d)', caseSensitive: false);
    for (final r in rows) { if (letters.hasMatch(r) && !bad.hasMatch(r)) { p.store = r; break; } }
    for (final s in ['Media Expert', 'RTV Euro AGD', 'x-kom', 'Leroy Merlin', 'Castorama', 'Biedronka', 'Lidl', 'Media Markt', 'Ikea', 'Decathlon', 'Allegro']) {
      if (up.contains(s.toUpperCase())) { p.store = s; break; }
    }
    final d1 = RegExp(r'(\d{2})[.\-/](\d{2})[.\-/](\d{4})').firstMatch(text);
    final d2 = RegExp(r'(\d{4})[.\-/](\d{2})[.\-/](\d{2})').firstMatch(text);
    try {
      if (d2 != null) { p.date = DateTime(int.parse(d2[1]!), int.parse(d2[2]!), int.parse(d2[3]!)); }
      else if (d1 != null) { p.date = DateTime(int.parse(d1[3]!), int.parse(d1[2]!), int.parse(d1[1]!)); }
      if (p.date != null && (p.date!.year < 2000 || p.date!.isAfter(DateTime.now().add(const Duration(days: 2))))) p.date = null;
    } catch (_) { p.date = null; }
    final lineRe = RegExp(r'^(.{3,}?)\s+(?:\d+(?:[.,]\d+)?\s*[xX*]\s*\d+[.,]\d{2}\s+)?(\d{1,6}[.,]\d{2})\s*[A-Ca-c]?$');
    for (final r in rows) {
      final m = lineRe.firstMatch(r);
      if (m != null && !_skip.hasMatch(r) && letters.hasMatch(m[1]!)) p.lines.add(Line(m[1]!.trim(), _num(m[2]!)));
      if (RegExp(r'SUMA|RAZEM|DO ZAP', caseSensitive: false).hasMatch(r)) { final all = _price.allMatches(r).toList(); if (all.isNotEmpty) p.total = _num(all.last[1]!); }
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
