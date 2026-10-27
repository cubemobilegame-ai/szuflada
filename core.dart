import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services.dart';

const freeLimit = 15;
const appVersion = '1.2.0';
const supportMail = 'cubemobilegame@gmail.com';

// ---------- kategorie ----------
class Cat {
  final String name, icon; final Color color;
  const Cat(this.name, this.icon, this.color);
}
const cats = <Cat>[
  Cat('Elektronika', 'device', Color(0xFF2F6BFF)),
  Cat('AGD', 'washer', Color(0xFF0FA38A)),
  Cat('Dom i ogród', 'sofa', Color(0xFF8B5CF6)),
  Cat('Auto', 'car', Color(0xFF475569)),
  Cat('Odzież i buty', 'shirt', Color(0xFFE64980)),
  Cat('Zdrowie', 'heart', Color(0xFF22A559)),
  Cat('Sport', 'bike', Color(0xFFF2711C)),
  Cat('Inne', 'box', Color(0xFF5A3DF0)),
];
Cat catOf(String n) => cats.firstWhere((c) => c.name == n, orElse: () => cats.last);

const _kw = <String, List<String>>{
  'Elektronika': ['telefon', 'smartfon', 'laptop', 'notebook', ' tv', 'telewizor', 'słuchawk', 'sluchawk', 'iphone', 'ipad', 'macbook', 'galaxy', 'xiaomi', 'tablet', 'monitor', 'x-kom', 'media expert', 'media markt', 'rtv euro', 'konsol', 'playstation', 'xbox', 'kamera', 'aparat foto', 'smartwatch', 'zegarek', 'głośnik', 'glosnik', 'drukark', 'router', 'komputer', 'klawiatur', 'mysz', 'powerbank', 'ładowark', 'ladowark', 'soundbar', 'czytnik', 'kindle'],
  'AGD': ['pralk', 'lodówk', 'lodowk', 'zmywark', 'odkurzacz', 'ekspres', 'czajnik', 'piekarnik', 'suszark', 'mikrofal', 'blender', 'robot kuch', 'mikser', 'toster', 'żelazk', 'zelazk', 'okap', 'płyta indukc', 'plyta indukc', 'frytkownic', 'zamrażark', 'zamrazark', 'golark', 'lokówk', 'prostownic'],
  'Dom i ogród': ['mebl', 'ikea', 'castorama', 'leroy', 'obi', 'wiertark', 'wkrętark', 'wkretark', 'szlifierk', 'pilark', 'narzędz', 'narzedz', 'lampa', 'materac', 'jysk', 'kosiark', 'sofa', 'kanap', 'fotel', 'krzesł', 'biurk', 'grill', 'myjk', 'agata', 'black red'],
  'Auto': ['opony', 'opona', 'olej', 'akumulator', 'samoch', 'moto', 'kask', 'wycieraczk', 'nawigac', 'kamerka', 'fotelik'],
  'Odzież i buty': ['buty', 'kurtk', 'sukienk', 'spodnie', 'zalando', 'reserved', 'nike', 'adidas', 'plecak', 'płaszcz', 'plaszcz', 'bluz', 'koszul', 'ccc', 'deichmann', 'eobuwie', 'h&m', 'zara'],
  'Zdrowie': ['okulary', 'ciśnieniomierz', 'cisnieniomierz', 'termometr', 'szczoteczk', 'inhalator', 'glukometr', 'apteka', 'waga łazienk'],
  'Sport': ['rower', 'decathlon', 'hulajnog', 'namiot', 'bieżni', 'biezni', 'orbitrek', 'narty', 'rolki', 'hantl', 'sport'],
};
String guessCat(String t) {
  final s = ' ${t.toLowerCase()} ';
  for (final e in _kw.entries) { for (final k in e.value) { if (s.contains(k)) return e.key; } }
  return 'Inne';
}
// popularne sklepy (podpowiedzi w formularzu)
const popularStores = ['Media Expert', 'RTV Euro AGD', 'Media Markt', 'x-kom', 'Allegro', 'Amazon', 'Leroy Merlin', 'Castorama', 'OBI', 'Ikea', 'Decathlon', 'Neonet', 'Komputronik', 'Empik', 'Zalando', 'Apple', 'Samsung'];

// ---------- daty i liczby ----------
final fmtD = DateFormat('d MMM y', 'pl_PL');
final fmtDM = DateFormat('d MMM', 'pl_PL');
final fmtMonth = DateFormat('LLLL y', 'pl_PL');
final fmtNum = DateFormat('dd.MM.yyyy');
DateTime today() { final n = DateTime.now(); return DateTime(n.year, n.month, n.day); }
DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime addDays(DateTime d, int n) => DateTime(d.year, d.month, d.day + n);
DateTime addMonths(DateTime d, int m) {
  final t = d.month - 1 + m; final y = d.year + t ~/ 12; final mo = t % 12 + 1;
  final last = DateTime(y, mo + 1, 0).day;
  return DateTime(y, mo, d.day > last ? last : d.day);
}
// liczba dni między datami (odporna na zmianę czasu letni/zimowy)
int daysBetween(DateTime a, DateTime b) => DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
String pl(int n, String a, String b, String c) {
  final x = n.abs();
  return x == 1 ? a : (x % 10 >= 2 && x % 10 <= 4 && (x % 100 < 10 || x % 100 >= 20)) ? b : c;
}
String daysTxt(int n) => n == 0 ? 'dziś' : '$n ${pl(n, 'dzień', 'dni', 'dni')}';
// krótki zapis pozostałego czasu: „12 dni”, „5 mies.”, „2 lata”
String leftShort(int n) {
  if (n < 0) return 'po terminie';
  if (n < 100) return daysTxt(n);
  final m = (n / 30.4).round();
  if (m < 24) return '$m mies.';
  final y = (n / 365).floor();
  return '$y ${pl(y, 'rok', 'lata', 'lat')}';
}
String money(double v) {
  final whole = v == v.roundToDouble();
  final s = NumberFormat(whole ? '#,##0' : '#,##0.00', 'pl_PL').format(v);
  return '$s zł';
}
double? parseMoney(String s) {
  final t = s.replaceAll(RegExp(r'[\s zł]'), '').replaceAll(',', '.');
  if (t.isEmpty) return null;
  return double.tryParse(t);
}
String monthsTxt(int m) {
  if (m % 12 == 0) { final y = m ~/ 12; return '$y ${pl(y, 'rok', 'lata', 'lat')}'; }
  return '$m ${pl(m, 'miesiąc', 'miesiące', 'miesięcy')}';
}

// ---------- model ----------
class Claim {
  String basis, status, desc, seller; DateTime date; String? photo; int req; DateTime? closed;
  Claim({required this.basis, required this.date, this.photo, this.status = 'open', this.req = 0, this.desc = '', this.seller = '', this.closed});
  bool get open => status == 'open';
  bool get rek => basis == 'rek';
  DateTime get answerBy => addDays(date, 14);
  Map<String, dynamic> toJson() => {'b': basis, 'd': date.toIso8601String(), 'p': photo, 'st': status, 'rq': req, 'ds': desc, 'sl': seller, 'cl': closed?.toIso8601String()};
  factory Claim.fromJson(Map j) => Claim(
      basis: j['b'] ?? 'rek', date: DateTime.parse(j['d']), photo: j['p'], status: j['st'] ?? 'open', req: j['rq'] ?? 0,
      desc: j['ds'] ?? '', seller: j['sl'] ?? '', closed: j['cl'] == null ? null : DateTime.tryParse(j['cl']));
}

class Item {
  int id; String name, store, cat, doc, docNo, buyer, note; DateTime date; double price; int months; bool online; String? photo; Claim? claim;
  Item({required this.id, required this.name, this.store = '', this.cat = 'Inne', this.doc = 'Paragon', this.docNo = '', this.buyer = '', this.note = '', required this.date, this.price = 0, this.months = 24, this.online = false, this.photo, this.claim});
  DateTime get end => addMonths(date, months);           // koniec gwarancji
  DateTime get rekEnd => addMonths(date, 24);            // koniec rękojmi (2 lata)
  int get left => daysBetween(today(), end);
  int get rekLeft => daysBetween(today(), rekEnd);
  bool get active => left >= 0;
  double get progress { final tot = daysBetween(date, end); return tot <= 0 ? 0 : (left / tot).clamp(0.0, 1.0); }
  Item copy({int? id, String? name, double? price, String? cat}) => Item(id: id ?? this.id, name: name ?? this.name, store: store, cat: cat ?? this.cat, doc: doc, docNo: docNo, buyer: buyer, note: note, date: date, price: price ?? this.price, months: months, online: online, photo: photo, claim: claim);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'store': store, 'cat': cat, 'doc': doc, 'docNo': docNo, 'buyer': buyer, 'note': note, 'date': date.toIso8601String(), 'price': price, 'months': months, 'online': online, 'photo': photo, 'claim': claim?.toJson()};
  factory Item.fromJson(Map j) => Item(
      id: (j['id'] as num).toInt(), name: j['name'] ?? '', store: j['store'] ?? '', cat: j['cat'] ?? 'Inne', doc: j['doc'] ?? 'Paragon', docNo: j['docNo'] ?? '', buyer: j['buyer'] ?? '', note: j['note'] ?? '',
      date: DateTime.parse(j['date']), price: ((j['price'] ?? 0) as num).toDouble(), months: ((j['months'] ?? 24) as num).toInt(), online: j['online'] ?? false, photo: j['photo'],
      claim: j['claim'] == null ? null : Claim.fromJson(j['claim']));
}

// ---------- przypomnienia ----------
// kind: 1 gwarancja 30 dni, 2 gwarancja 7 dni, 3 zwrot online, 4 odpowiedź na reklamację, 5 koniec rękojmi, 6 koniec gwarancji
class Rem {
  final DateTime d; final Item it; final String txt; final int kind;
  Rem(this.d, this.it, this.txt, this.kind);
  String get group => kind == 3 ? 'zwrot' : kind == 4 ? 'rekl' : 'gw';
}
List<Rem> remindersFor(List<Item> items, {bool past = false}) {
  final t = today(); final r = <Rem>[];
  void add(DateTime d, Item it, String s, int k) { if (past || !d.isBefore(t)) r.add(Rem(dayOf(d), it, s, k)); }
  for (final it in items) {
    final e = it.end;
    add(addDays(e, -30), it, 'Gwarancja kończy się za 30 dni. Sprawdź, czy wszystko działa.', 1);
    add(addDays(e, -7), it, 'Zostało 7 dni gwarancji. To ostatni moment na zgłoszenie usterki.', 2);
    add(e, it, 'Dziś kończy się gwarancja.', 6);
    if (it.months != 24) add(addDays(it.rekEnd, -30), it, 'Za 30 dni kończy się rękojmia (2 lata od zakupu). Sprawdź, czy wszystko działa.', 5);
    if (it.online) add(addDays(it.date, 14), it, 'Ostatni dzień na zwrot zakupu z internetu (14 dni).', 3);
    final c = it.claim;
    if (c != null && c.open && c.rek) add(c.answerBy, it, 'Mija 14 dni na odpowiedź sprzedawcy. Brak odpowiedzi oznacza, że uznał Twoją reklamację.', 4);
  }
  r.sort((a, b) => a.d.compareTo(b.d));
  return r;
}

// ---------- dane ----------
final store = Store();
class Store extends ChangeNotifier {
  List<Item> items = []; int threshold = 150; ThemeMode theme = ThemeMode.system; bool lockOn = false; bool onboarded = false;
  int remindHour = 9; String sort = 'end'; Map<String, String> me = {}; int proSeenMs = 0;
  late SharedPreferences sp; late Directory dir;
  bool get pro => DateTime.now().millisecondsSinceEpoch - proSeenMs < 14 * 86400000;
  bool get canAdd => pro || items.length < freeLimit;
  Item? byId(int id) { for (final i in items) { if (i.id == id) return i; } return null; }

  Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    dir = await getApplicationDocumentsDirectory();
    await Directory('${dir.path}/img').create(recursive: true);
    final f = File('${dir.path}/items.json');
    try {
      if (await f.exists()) { items = (jsonDecode(await f.readAsString()) as List).map((e) => Item.fromJson(e)).toList(); }
    } catch (_) {
      // uszkodzony plik: zachowaj kopię, aby nie stracić danych
      try { await f.copy('${dir.path}/items-uszkodzony-${DateTime.now().millisecondsSinceEpoch}.json'); } catch (_) {}
      items = [];
    }
    threshold = sp.getInt('th') ?? 150;
    final ti = sp.getInt('theme') ?? 0; theme = ThemeMode.values[ti.clamp(0, 2)];
    lockOn = sp.getBool('lock') ?? false;
    onboarded = sp.getBool('onb') ?? items.isNotEmpty;
    remindHour = sp.getInt('hour') ?? 9;
    sort = sp.getString('sort') ?? 'end';
    proSeenMs = sp.getInt('pro') ?? 0;
    try { me = Map<String, String>.from(jsonDecode(sp.getString('me') ?? '{}')); } catch (_) { me = {}; }
  }
  Future<void> save() async {
    final f = File('${dir.path}/items.json'); final tmp = File('${dir.path}/items.tmp');
    await tmp.writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()), flush: true);
    await tmp.rename(f.path);
    notifyListeners();
    try { await Notifier.reschedule(items); } catch (_) {}
  }
  void touch() => notifyListeners();
  Future<void> upsert(Item it) async {
    final i = items.indexWhere((e) => e.id == it.id);
    if (i < 0) { items.add(it); } else { items[i] = it; }
    await save();
  }
  Future<void> remove(Item it) async {
    items.removeWhere((e) => e.id == it.id);
    await save();
    // zdjęcia usuwamy dopiero, gdy nikt już z nich nie korzysta (pozycje z jednego paragonu dzielą zdjęcie)
    for (final n in [it.photo, it.claim?.photo]) {
      if (n == null || n.isEmpty) continue;
      if (items.any((e) => e.photo == n || e.claim?.photo == n)) continue;
      try { await img(n)?.delete(); } catch (_) {}
    }
  }
  Future<void> removeAll() async {
    items = []; await save();
    try { final d = Directory('${dir.path}/img'); if (await d.exists()) { await d.delete(recursive: true); } await d.create(recursive: true); } catch (_) {}
  }
  Future<void> setPro() async { proSeenMs = DateTime.now().millisecondsSinceEpoch; await sp.setInt('pro', proSeenMs); notifyListeners(); }
  Future<void> clearPro() async { proSeenMs = 0; await sp.setInt('pro', 0); notifyListeners(); }
  Future<void> setTheme(ThemeMode m) async { theme = m; await sp.setInt('theme', m.index); notifyListeners(); }
  Future<void> setLock(bool v) async { lockOn = v; await sp.setBool('lock', v); notifyListeners(); }
  Future<void> setOnboarded(bool v) async { onboarded = v; await sp.setBool('onb', v); notifyListeners(); }
  Future<void> setThreshold(int v) async { threshold = v; await sp.setInt('th', v); notifyListeners(); }
  Future<void> setSort(String v) async { sort = v; await sp.setString('sort', v); notifyListeners(); }
  Future<void> setHour(int h) async { remindHour = h; await sp.setInt('hour', h); notifyListeners(); try { await Notifier.reschedule(items); } catch (_) {} }
  Future<void> setMe(Map<String, String> m) async { me = m; await sp.setString('me', jsonEncode(m)); notifyListeners(); }
  File? img(String? n) => (n == null || n.isEmpty) ? null : File('${dir.path}/img/$n');
  Future<String> importImage(String path) async {
    final n = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(path).copy('${dir.path}/img/$n');
    return n;
  }
}

// Tylko dla testów (test/screens_test.dart). Aplikacja tej funkcji nie używa i nie ma do niej przycisków.
Future<void> loadDemo() async {
  final t = today(); var k = 0; final base = DateTime.now().millisecondsSinceEpoch;
  final demo = <List<Object>>[
    ['Pralka Bosch Serie 6', 'Media Expert', -700, 2299.0, 24, false],
    ['Słuchawki Sony WH-1000XM5', 'x-kom', -40, 1199.0, 24, true],
    ['Wiertarka Makita DF333', 'Leroy Merlin', -340, 459.0, 36, false],
    ['Telewizor Samsung QE55Q60D', 'RTV Euro AGD', -5, 2799.0, 24, true],
    ['Rower Kross Hexagon', 'Decathlon', -120, 1899.0, 24, false],
  ];
  for (final x in demo) {
    store.items.add(Item(id: base + k++, name: x[0] as String, store: x[1] as String, cat: guessCat('${x[0]} ${x[1]}'), date: addDays(t, x[2] as int), price: x[3] as double, months: x[4] as int, online: x[5] as bool));
  }
  await store.save();
}
