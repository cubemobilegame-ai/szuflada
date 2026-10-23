import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services.dart';

const icons = {'Elektronika': '💻', 'AGD': '🧺', 'Dom i ogród': '🛋️', 'Auto': '🚗', 'Odzież i buty': '👟', 'Zdrowie': '🩺', 'Sport': '🚴', 'Inne': '📦'};
const _kw = <String, List<String>>{
  'Elektronika': ['telefon', 'laptop', 'tv', 'telewizor', 'słuchawk', 'iphone', 'samsung', 'xiaomi', 'tablet', 'monitor', 'x-kom', 'media expert', 'rtv euro', 'konsol', 'kamera', 'smartwatch'],
  'AGD': ['pralk', 'lodówk', 'zmywark', 'odkurzacz', 'ekspres', 'czajnik', 'piekarnik', 'suszark', 'mikrofal', 'blender', 'robot'],
  'Dom i ogród': ['mebl', 'ikea', 'castorama', 'leroy', 'obi', 'wiertark', 'narzędz', 'lampa', 'materac', 'jysk', 'kosiark'],
  'Auto': ['opony', 'opona', 'olej', 'akumulator', 'auto', 'moto', 'kask'],
  'Odzież i buty': ['buty', 'kurtka', 'sukienk', 'spodnie', 'zalando', 'reserved', 'nike', 'adidas', 'plecak'],
  'Zdrowie': ['okulary', 'ciśnieniomierz', 'termometr', 'szczoteczk'],
  'Sport': ['rower', 'decathlon', 'hulajnog', 'namiot', 'bieżni'],
};
String guessCat(String t) {
  final s = t.toLowerCase();
  for (final e in _kw.entries) { for (final k in e.value) { if (s.contains(k)) return e.key; } }
  return 'Inne';
}

const catIcons = <String, IconData>{'Elektronika': Icons.devices_other, 'AGD': Icons.local_laundry_service, 'Dom i ogród': Icons.chair, 'Auto': Icons.directions_car, 'Odzież i buty': Icons.checkroom, 'Zdrowie': Icons.health_and_safety, 'Sport': Icons.pedal_bike, 'Inne': Icons.inventory_2};
const catColors = <String, Color>{'Elektronika': Color(0xFF1A73E8), 'AGD': Color(0xFF00897B), 'Dom i ogród': Color(0xFF7E57C2), 'Auto': Color(0xFF5F6368), 'Odzież i buty': Color(0xFFE91E63), 'Zdrowie': Color(0xFF1E8E3E), 'Sport': Color(0xFFEF6C00), 'Inne': Color(0xFF5F6368)};

class CatIcon extends StatelessWidget {
  final String cat; final double size;
  const CatIcon(this.cat, {super.key, this.size = 36});
  @override
  Widget build(BuildContext c) {
    final col = catColors[cat] ?? Colors.grey;
    return Container(width: size, height: size, decoration: BoxDecoration(color: col.withOpacity(.14), borderRadius: BorderRadius.circular(size * .3)), child: Icon(catIcons[cat] ?? Icons.inventory_2, size: size * .58, color: col));
  }
}

final fmtD = DateFormat('d MMM y', 'pl_PL');
DateTime today() { final n = DateTime.now(); return DateTime(n.year, n.month, n.day); }
DateTime addMonths(DateTime d, int m) {
  final t = d.month - 1 + m; final y = d.year + t ~/ 12; final mo = t % 12 + 1;
  final last = DateTime(y, mo + 1, 0).day;
  return DateTime(y, mo, d.day > last ? last : d.day);
}
String pl(int n, String a, String b, String c) => n == 1 ? a : (n % 10 >= 2 && n % 10 <= 4 && (n % 100 < 10 || n % 100 >= 20)) ? b : c;

class Claim {
  String basis; DateTime date; String? photo;
  Claim({required this.basis, required this.date, this.photo});
  Map<String, dynamic> toJson() => {'b': basis, 'd': date.toIso8601String(), 'p': photo};
  factory Claim.fromJson(Map j) => Claim(basis: j['b'] ?? 'rek', date: DateTime.parse(j['d']), photo: j['p']);
}

class Item {
  int id; String name, store, cat, doc, docNo, buyer, note; DateTime date; double price; int months; bool online; String? photo; Claim? claim;
  Item({required this.id, required this.name, this.store = '', this.cat = 'Inne', this.doc = 'Paragon', this.docNo = '', this.buyer = '', this.note = '', required this.date, this.price = 0, this.months = 24, this.online = false, this.photo, this.claim});
  DateTime get end => addMonths(date, months);
  int get left => end.difference(today()).inDays;
  Item copy({int? id, String? name, double? price, String? cat}) => Item(id: id ?? this.id, name: name ?? this.name, store: store, cat: cat ?? this.cat, doc: doc, docNo: docNo, buyer: buyer, note: note, date: date, price: price ?? this.price, months: months, online: online, photo: photo, claim: claim);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'store': store, 'cat': cat, 'doc': doc, 'docNo': docNo, 'buyer': buyer, 'note': note, 'date': date.toIso8601String(), 'price': price, 'months': months, 'online': online, 'photo': photo, 'claim': claim?.toJson()};
  factory Item.fromJson(Map j) => Item(id: j['id'], name: j['name'], store: j['store'] ?? '', cat: j['cat'] ?? 'Inne', doc: j['doc'] ?? 'Paragon', docNo: j['docNo'] ?? '', buyer: j['buyer'] ?? '', note: j['note'] ?? '', date: DateTime.parse(j['date']), price: (j['price'] ?? 0).toDouble(), months: j['months'] ?? 24, online: j['online'] ?? false, photo: j['photo'], claim: j['claim'] == null ? null : Claim.fromJson(j['claim']));
}

class Rem { final DateTime d; final Item it; final String txt; final int kind; Rem(this.d, this.it, this.txt, this.kind); }
List<Rem> remindersFor(List<Item> items) {
  final t = today(); final r = <Rem>[];
  void add(DateTime d, Item it, String s, int k) { if (!d.isBefore(t)) r.add(Rem(d, it, s, k)); }
  for (final it in items) {
    add(it.end.subtract(const Duration(days: 30)), it, 'Gwarancja kończy się za 30 dni – sprawdź, czy wszystko działa', 1);
    add(it.end.subtract(const Duration(days: 7)), it, 'Zostało 7 dni gwarancji – ostatni moment na zgłoszenie usterki', 2);
    if (it.online) add(it.date.add(const Duration(days: 14)), it, 'Ostatni dzień na odstąpienie od zakupu online (14 dni)', 3);
    final c = it.claim;
    if (c != null && c.basis == 'rek') add(c.date.add(const Duration(days: 14)), it, 'Minął termin 14 dni na odpowiedź sprzedawcy – brak odpowiedzi oznacza uznanie żądania', 4);
  }
  r.sort((a, b) => a.d.compareTo(b.d));
  return r;
}

final store = Store();
class Store extends ChangeNotifier {
  List<Item> items = []; int threshold = 150; ThemeMode theme = ThemeMode.system; bool lockOn = false; Map<String, String> me = {}; int proSeenMs = 0;
  late SharedPreferences sp; late Directory dir;
  bool get pro => DateTime.now().millisecondsSinceEpoch - proSeenMs < 14 * 86400000;
  Future<void> init() async {
    sp = await SharedPreferences.getInstance();
    dir = await getApplicationDocumentsDirectory();
    await Directory('${dir.path}/img').create(recursive: true);
    final f = File('${dir.path}/items.json');
    if (await f.exists()) { items = (jsonDecode(await f.readAsString()) as List).map((e) => Item.fromJson(e)).toList(); }
    threshold = sp.getInt('th') ?? 150; theme = ThemeMode.values[sp.getInt('theme') ?? 0]; lockOn = sp.getBool('lock') ?? false;
    proSeenMs = sp.getInt('pro') ?? 0; me = Map<String, String>.from(jsonDecode(sp.getString('me') ?? '{}'));
  }
  Future<void> save() async {
    await File('${dir.path}/items.json').writeAsString(jsonEncode(items.map((e) => e.toJson()).toList()));
    notifyListeners();
    await Notifier.reschedule(items);
  }
  void touch() => notifyListeners();
  Future<void> setPro() async { proSeenMs = DateTime.now().millisecondsSinceEpoch; await sp.setInt('pro', proSeenMs); notifyListeners(); }
  Future<void> setTheme(ThemeMode m) async { theme = m; await sp.setInt('theme', m.index); notifyListeners(); }
  Future<void> setLock(bool v) async { lockOn = v; await sp.setBool('lock', v); notifyListeners(); }
  Future<void> setThreshold(int v) async { threshold = v; await sp.setInt('th', v); }
  Future<void> setMe(Map<String, String> m) async { me = m; await sp.setString('me', jsonEncode(m)); }
  File? img(String? n) => (n == null || n.isEmpty) ? null : File('${dir.path}/img/$n');
  Future<String> importImage(String path) async {
    final n = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    await File(path).copy('${dir.path}/img/$n');
    return n;
  }
}
