import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'add.dart';
import 'claim.dart';
import 'core.dart';
import 'letters.dart';
import 'services.dart';

void toast(BuildContext c, String m) => ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
Color statusColor(int n) => n < 0 ? Colors.grey : n < 14 ? const Color(0xFFD93025) : n < 60 ? const Color(0xFFE37400) : const Color(0xFF1E8E3E);

// ---- Ekran startowy z ładowaniem i blokadą ----
class Gate extends StatefulWidget { const Gate({super.key}); @override State<Gate> createState() => _G(); }
class _G extends State<Gate> {
  int ph = 0;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () async {
      if (!mounted) return;
      if (store.lockOn) { setState(() => ph = 1); await _unlock(); } else { setState(() => ph = 2); }
    });
  }
  Future<void> _unlock() async {
    if (!await Auth.supported()) { if (mounted) setState(() => ph = 2); return; }
    if (await Auth.unlock() && mounted) setState(() => ph = 2);
  }
  @override
  Widget build(BuildContext c) {
    if (ph == 2) return const Shell();
    final cs = Theme.of(c).colorScheme;
    return Scaffold(body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 84, height: 84, decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(24)), child: const Center(child: Text('🧾', style: TextStyle(fontSize: 44)))),
      const SizedBox(height: 16), Text('Szuflada', style: Theme.of(c).textTheme.headlineMedium), const SizedBox(height: 4),
      const Text('Paragony i gwarancje w jednym miejscu'), const SizedBox(height: 24),
      ph == 0 ? const SizedBox(width: 140, child: LinearProgressIndicator()) : FilledButton.icon(onPressed: _unlock, icon: const Icon(Icons.lock_open), label: const Text('Odblokuj')),
    ])));
  }
}

class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _S(); }
class _S extends State<Shell> {
  int i = 0;
  void _add() {
    if (!store.pro && store.items.length >= 15) { toast(context, 'Limit 15 paragonów w planie Start – zobacz Pro'); setState(() => i = 3); return; }
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddPage()));
  }
  @override
  Widget build(BuildContext c) => Scaffold(
        body: SafeArea(child: ListenableBuilder(listenable: store, builder: (_, __) => const [HomePage(), ListPage(), RemindersPage(), PlanPage()][i])),
        floatingActionButton: FloatingActionButton(onPressed: _add, child: const Icon(Icons.add)),
        bottomNavigationBar: NavigationBar(selectedIndex: i, onDestinationSelected: (v) => setState(() => i = v), destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Start'),
          NavigationDestination(icon: Icon(Icons.folder_outlined), label: 'Paragony'),
          NavigationDestination(icon: Icon(Icons.notifications_outlined), label: 'Przypomnienia'),
          NavigationDestination(icon: Icon(Icons.star_outline), label: 'Plan'),
        ]),
      );
}

class Ring extends StatelessWidget {
  final Item it; const Ring(this.it, {super.key});
  @override
  Widget build(BuildContext c) {
    final n = it.left; final total = max(1, it.end.difference(it.date).inDays);
    return SizedBox(width: 52, height: 52, child: Stack(alignment: Alignment.center, children: [
      CircularProgressIndicator(value: (n / total).clamp(0.0, 1.0), strokeWidth: 5, color: statusColor(n), backgroundColor: Colors.black12),
      Text(n < 0 ? '—' : n > 99 ? '${(n / 30).round()}\nmies.' : '$n\ndni', textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, height: 1.1)),
    ]));
  }
}
class Tile extends StatelessWidget {
  final Item it; const Tile(this.it, {super.key});
  @override
  Widget build(BuildContext c) => Card(child: ListTile(
        leading: Ring(it), title: Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${icons[it.cat]} ${it.cat}${it.store.isNotEmpty ? ' · ${it.store}' : ''}\n${it.left < 0 ? 'Gwarancja zakończona' : 'Gwarancja do'} ${fmtD.format(it.end)}'),
        isThreeLine: true, onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => DetailPage(it.id))),
      ));
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext c) {
    final act = store.items.where((e) => e.left >= 0).toList();
    final soon = act.where((e) => e.left < 60).toList()..sort((a, b) => a.left.compareTo(b.left));
    final val = act.fold<double>(0, (s, e) => s + e.price); final cs = Theme.of(c).colorScheme;
    final recent = [...store.items]..sort((a, b) => b.id.compareTo(a.id));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Szuflada', style: Theme.of(c).textTheme.headlineMedium),
      const SizedBox(height: 12),
      Card(color: cs.primaryContainer, child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${act.length}', style: TextStyle(fontSize: 44, color: cs.onPrimaryContainer)),
        Text('${pl(act.length, 'produkt', 'produkty', 'produktów')} na gwarancji${val > 0 ? ' o wartości ${val.round()} zł' : ''}', style: TextStyle(color: cs.onPrimaryContainer)),
      ]))),
      if (store.items.isEmpty) const Padding(padding: EdgeInsets.all(24), child: Text('Szuflada jest pusta. Dotknij +, zeskanuj pierwszy paragon, a przypomnę o końcu gwarancji.', textAlign: TextAlign.center)),
      if (soon.isNotEmpty) ...[const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('Kończy się wkrótce', style: TextStyle(fontSize: 18))), ...soon.take(4).map(Tile.new)],
      if (recent.isNotEmpty) ...[const Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child: Text('Ostatnio dodane', style: TextStyle(fontSize: 18))), ...recent.take(3).map(Tile.new)],
    ]);
  }
}

class ListPage extends StatefulWidget { const ListPage({super.key}); @override State<ListPage> createState() => _L(); }
class _L extends State<ListPage> {
  String q = '', cat = 'Wszystkie';
  @override
  Widget build(BuildContext c) {
    final L = store.items.where((i) => (cat == 'Wszystkie' || i.cat == cat) && '${i.name} ${i.store} ${i.cat} ${i.note}'.toLowerCase().contains(q.toLowerCase())).toList()..sort((a, b) => a.end.compareTo(b.end));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Paragony', style: Theme.of(c).textTheme.headlineMedium), const SizedBox(height: 12),
      TextField(decoration: const InputDecoration(hintText: 'Szukaj po nazwie, sklepie, notatce…', prefixIcon: Icon(Icons.search)), onChanged: (v) => setState(() => q = v)),
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['Wszystkie', ...icons.keys].map((k) => Padding(padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8), child: ChoiceChip(label: Text('${icons[k] ?? ''} $k'.trim()), selected: cat == k, onSelected: (_) => setState(() => cat = k)))).toList())),
      if (L.isEmpty) const Padding(padding: EdgeInsets.all(16), child: Text('Brak wyników.')) else ...L.map(Tile.new),
    ]);
  }
}

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});
  @override
  Widget build(BuildContext c) {
    final R = remindersFor(store.items); final t = today();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Przypomnienia', style: Theme.of(c).textTheme.headlineMedium),
      const Text('Powiadomimy Cię o 9:00, zanim będzie za późno – nawet gdy aplikacja jest zamknięta.'), const SizedBox(height: 12),
      if (R.isEmpty) const Text('Brak zaplanowanych przypomnień. Dodaj paragon, a pojawią się tutaj.'),
      ...R.map((r) { final n = r.d.difference(t).inDays; return Card(child: ListTile(
        leading: Icon(Icons.circle, size: 12, color: n < 8 ? const Color(0xFFD93025) : n < 31 ? const Color(0xFFE37400) : const Color(0xFF1E8E3E)),
        title: Text(r.it.name), subtitle: Text(r.txt), trailing: Text(n == 0 ? 'dziś' : 'za $n dni'),
        onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => DetailPage(r.it.id))))); }),
    ]);
  }
}

class PlanPage extends StatelessWidget {
  const PlanPage({super.key});
  Widget _sec(BuildContext c, String t, List<Widget> ch) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)), const SizedBox(height: 8), ...ch])));
  @override
  Widget build(BuildContext c) {
    final price = Billing.product?.price ?? '29,99 zł';
    Widget f(String s) => Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check, size: 18, color: Color(0xFF1E8E3E)), const SizedBox(width: 8), Expanded(child: Text(s))]));
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Plan', style: Theme.of(c).textTheme.headlineMedium),
      const Text('Płacisz za spokój, nie za reklamy. Aplikacja nigdy nie pokazuje reklam.'), const SizedBox(height: 12),
      _sec(c, 'Start – 0 zł', [f('Do 15 paragonów i faktur'), f('Skaner z automatycznym kadrowaniem i odczytem'), f('Wyszukiwanie po nazwie'), f('Przypomnienia o gwarancji')]),
      _sec(c, 'Pro – $price / rok', [
        f('Bez limitu paragonów'), f('Moduł reklamacji: rękojmia i gwarancja, gotowe pismo w PDF'), f('Podpowiedzi, jak zgłosić do serwisu marki'), f('Kopia zapasowa i przeniesienie na nowy telefon'),
        const SizedBox(height: 8),
        if (store.pro) const Chip(label: Text('Plan Pro aktywny')) else Column(children: [
          SizedBox(width: double.infinity, child: FilledButton(onPressed: () async { if (!await Billing.buy() && c.mounted) toast(c, 'Zakupy są niedostępne (sprawdź konto Google Play)'); }, child: Text('Wykup Pro – $price / rok'))),
          TextButton(onPressed: () async { await Billing.restore(); if (c.mounted) toast(c, 'Sprawdzam zakupy…'); }, child: const Text('Przywróć zakupy')),
        ]),
        const Text('Płatność przez Google Play (karta, Google Pay i inne metody dostępne na koncie). Subskrypcję anulujesz w Google Play.', style: TextStyle(fontSize: 12)),
      ]),
      _sec(c, 'Wygląd', [SegmentedButton<ThemeMode>(segments: const [ButtonSegment(value: ThemeMode.system, label: Text('Auto')), ButtonSegment(value: ThemeMode.light, label: Text('Jasny')), ButtonSegment(value: ThemeMode.dark, label: Text('Ciemny'))], selected: {store.theme}, onSelectionChanged: (s) => store.setTheme(s.first))]),
      _sec(c, 'Blokada', [SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Odcisk palca, twarz lub PIN telefonu'), value: store.lockOn, onChanged: (v) async {
        if (v && !await Auth.supported()) { if (c.mounted) toast(c, 'Ustaw blokadę ekranu w telefonie'); return; }
        if (v && !await Auth.unlock()) return;
        await store.setLock(v);
      })]),
      _sec(c, 'Kopia zapasowa', [
        const Text('Zapisz plik ZIP (dane i zdjęcia) np. na Dysku Google. Po zmianie telefonu wczytaj go z powrotem.'), const SizedBox(height: 8),
        FilledButton.tonal(onPressed: Backup.export, child: const Text('Zapisz kopię')), const SizedBox(height: 8),
        OutlinedButton(onPressed: () async { final n = await Backup.import(); if (c.mounted) toast(c, n < 0 ? 'Nie udało się wczytać kopii' : 'Wczytano: $n ${pl(n, 'pozycję', 'pozycje', 'pozycji')}'); }, child: const Text('Wczytaj kopię')),
      ]),
      _sec(c, 'Ustawienia', [
        TextFormField(initialValue: '${store.threshold}', keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Zaznaczaj pozycje z paragonu powyżej (zł)'), onChanged: (v) => store.setThreshold(int.tryParse(v) ?? 150)),
        const SizedBox(height: 12), const Text('Moje dane do pism reklamacyjnych'), const SizedBox(height: 6),
        for (final e in {'n': 'Imię i nazwisko', 'a': 'Adres', 'c': 'E-mail lub telefon'}.entries) Padding(padding: const EdgeInsets.only(bottom: 8), child: TextFormField(initialValue: store.me[e.key] ?? '', decoration: InputDecoration(labelText: e.value), onChanged: (v) => store.setMe({...store.me, e.key: v}))),
      ]),
    ]);
  }
}

class DetailPage extends StatelessWidget {
  final int id; const DetailPage(this.id, {super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: store, builder: (_, __) {
        final i = store.items.indexWhere((e) => e.id == id);
        if (i < 0) return const Scaffold();
        final it = store.items[i]; final img = store.img(it.photo); final cl = it.claim;
        return Scaffold(appBar: AppBar(title: Text(it.name)), body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [Expanded(child: Text('${icons[it.cat]} ${it.cat}${it.store.isNotEmpty ? ' · ${it.store}' : ''}')), Ring(it)]),
          if (img != null && img.existsSync()) Padding(padding: const EdgeInsets.only(top: 12), child: GestureDetector(
            onTap: () => showDialog(context: c, builder: (_) => Dialog(child: InteractiveViewer(child: Image.file(img)))),
            child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(img, height: 240, width: double.infinity, fit: BoxFit.cover)))),
          Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${it.doc}${it.docNo.isNotEmpty ? ' nr ${it.docNo}' : ''}${it.buyer.isNotEmpty ? ' · nabywca: ${it.buyer}' : ''}'),
            Text('Zakup: ${fmtD.format(it.date)}${it.price > 0 ? ' · ${it.price.toStringAsFixed(2)} zł' : ''}'),
            Text('Gwarancja do: ${fmtD.format(it.end)} (${it.left < 0 ? 'zakończona' : 'zostało ${it.left} ${pl(it.left, 'dzień', 'dni', 'dni')}'})', style: TextStyle(color: statusColor(it.left), fontWeight: FontWeight.w600)),
            if (it.note.isNotEmpty) Text(it.note),
          ]))),
          if (cl != null) Card(color: Theme.of(c).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Reklamacja (${cl.basis == 'rek' ? 'rękojmia' : 'gwarancja'}) z ${fmtD.format(cl.date)}${cl.basis == 'rek' ? '. Sprzedawca ma 14 dni na odpowiedź – do ${fmtD.format(cl.date.add(const Duration(days: 14)))}.' : '.'}'),
            if (store.img(cl.photo) != null) Padding(padding: const EdgeInsets.only(top: 8), child: Image.file(store.img(cl.photo)!, height: 140)),
          ]))),
          const SizedBox(height: 8),
          FilledButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => ClaimPage(it))), child: const Text('Złóż reklamację')),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => AddPage(edit: it))), child: const Text('Edytuj')),
          TextButton(style: TextButton.styleFrom(foregroundColor: const Color(0xFFD93025)), onPressed: () async {
            final ok = await showDialog<bool>(context: c, builder: (d) => AlertDialog(title: const Text('Usunąć ten paragon?'), actions: [TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('Anuluj')), TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('Usuń'))]));
            if (ok == true) { store.items.removeWhere((e) => e.id == it.id); await store.save(); if (c.mounted) Navigator.pop(c); }
          }, child: const Text('Usuń paragon')),
        ]));
      });
}
