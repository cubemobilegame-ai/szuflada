import 'dart:io';
import 'package:flutter/material.dart';
import 'core.dart';
import 'pages.dart';
import 'services.dart';

class AddPage extends StatefulWidget { final Item? edit; const AddPage({super.key, this.edit}); @override State<AddPage> createState() => _A(); }
class _A extends State<AddPage> {
  final n = TextEditingController(), st = TextEditingController(), pr = TextEditingController(), mo = TextEditingController(text: '24'), nt = TextEditingController(), dn = TextEditingController(), by = TextEditingController();
  DateTime date = today(); String cat = 'Inne', doc = 'Paragon'; bool online = false, busy = false, lowDate = false, scanned = false, empty = false;
  String? photoName, newPath; List<Line> lines = [];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) { n.text = e.name; st.text = e.store; pr.text = e.price > 0 ? e.price.toStringAsFixed(2) : ''; mo.text = '${e.months}'; nt.text = e.note; dn.text = e.docNo; by.text = e.buyer; date = e.date; cat = e.cat; doc = e.doc; online = e.online; photoName = e.photo; }
  }

  Future<void> _scan() async {
    setState(() => busy = true);
    try {
      final r = await Scanner.run();
      if (r == null) return;
      setState(() {
        newPath = r.path; st.text = r.store; if (r.date != null) date = r.date!; lowDate = r.date == null; doc = r.doc; dn.text = r.docNo; by.text = r.buyer;
        lines = r.lines..forEach((l) => l.on = l.price > store.threshold);
        final on = lines.where((l) => l.on);
        if (on.isNotEmpty) { n.text = on.first.name; pr.text = on.first.price.toStringAsFixed(2); } else if (r.total != null) { pr.text = r.total!.toStringAsFixed(2); }
        cat = guessCat('${n.text} ${st.text}'); scanned = true; empty = r.store.isEmpty && r.lines.isEmpty && r.total == null;
      });
    } catch (e) { if (mounted) toast(context, 'Skanowanie nie powiodło się. Uzupełnij dane ręcznie.'); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _save() async {
    if (n.text.trim().isEmpty) { toast(context, 'Wpisz nazwę produktu'); return; }
    var ph = photoName; if (newPath != null) ph = await store.importImage(newPath!);
    final base = Item(id: widget.edit?.id ?? DateTime.now().millisecondsSinceEpoch, name: n.text.trim(), store: st.text.trim(), cat: cat, doc: doc, docNo: dn.text.trim(), buyer: by.text.trim(), note: nt.text.trim(), date: date,
        price: double.tryParse(pr.text.replaceAll(',', '.')) ?? 0, months: int.tryParse(mo.text) ?? 24, online: online, photo: ph, claim: widget.edit?.claim);
    if (widget.edit != null) { store.items[store.items.indexWhere((e) => e.id == base.id)] = base; }
    else {
      store.items.add(base); var k = 1;
      for (final l in lines.where((l) => l.on).skip(1)) { store.items.add(base.copy(id: base.id + k++, name: l.name, price: l.price, cat: guessCat('${l.name} ${base.store}'))); }
    }
    await store.save();
    if (mounted) Navigator.pop(context);
  }

  InputDecoration _d(String l, {bool low = false}) => InputDecoration(labelText: l, filled: low, fillColor: low ? Colors.amber.withOpacity(.2) : null);

  @override
  Widget build(BuildContext c) {
    final img = newPath != null ? File(newPath!) : store.img(photoName);
    return Scaffold(appBar: AppBar(title: Text(widget.edit == null ? 'Nowy dokument zakupu' : 'Edytuj dokument')), body: ListView(padding: const EdgeInsets.all(16), children: [
      FilledButton.icon(onPressed: busy ? null : _scan, icon: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.document_scanner), label: Text(busy ? 'Odczytuję…' : (img == null ? 'Skanuj paragon lub fakturę' : 'Skanuj ponownie'))),
      if (img != null && img.existsSync()) Padding(padding: const EdgeInsets.only(top: 12), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(img, height: 220, width: double.infinity, fit: BoxFit.cover))),
      if (scanned) Card(color: Theme.of(c).colorScheme.primaryContainer, child: Padding(padding: const EdgeInsets.all(12), child: Text(empty
          ? 'Nie udało się odczytać danych. Uzupełnij je ręcznie.'
          : 'Dokument wykadrowano, dane odczytano. Sprawdź je i popraw, jeśli coś się nie zgadza.${lowDate ? ' Data nie została rozpoznana – ustaw ją ręcznie.' : ''}'))),
      if (lines.length > 1) ...[const SizedBox(height: 8), Text('Pozycje z dokumentu (zaznaczone: powyżej ${store.threshold} zł)'), ...List.generate(lines.length, (i) => CheckboxListTile(dense: true, contentPadding: EdgeInsets.zero, value: lines[i].on, title: Text(lines[i].name), secondary: Text('${lines[i].price.toStringAsFixed(2)} zł'),
          onChanged: (v) => setState(() { lines[i].on = v ?? false; final on = lines.where((l) => l.on); if (on.isNotEmpty) { n.text = on.first.name; pr.text = on.first.price.toStringAsFixed(2); } })))],
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(value: doc, decoration: _d('Rodzaj dokumentu'), items: const ['Paragon', 'Faktura imienna'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => doc = v!)),
      const SizedBox(height: 12), TextField(controller: n, decoration: _d('Nazwa produktu', low: scanned && n.text.isEmpty)),
      const SizedBox(height: 12), TextField(controller: st, decoration: _d('Sklep')),
      const SizedBox(height: 12), TextField(controller: pr, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _d('Cena brutto (zł)')),
      const SizedBox(height: 12), InkWell(onTap: () async { final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1))); if (d != null) setState(() { date = d; lowDate = false; }); },
        child: InputDecorator(decoration: _d('Data zakupu', low: lowDate), child: Text(fmtD.format(date)))),
      const SizedBox(height: 12), DropdownButtonFormField<String>(value: cat, decoration: _d('Kategoria'), items: icons.keys.map((e) => DropdownMenuItem(value: e, child: Text('${icons[e]} $e'))).toList(), onChanged: (v) => setState(() => cat = v!)),
      const SizedBox(height: 12), TextField(controller: mo, keyboardType: TextInputType.number, decoration: _d('Gwarancja (miesiące)')),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Zakup przez internet (przypomnę o 14 dniach na zwrot)'), value: online, onChanged: (v) => setState(() => online = v)),
      TextField(controller: dn, decoration: _d('Numer dokumentu')), const SizedBox(height: 12),
      TextField(controller: by, decoration: _d('Nabywca (faktura imienna)')), const SizedBox(height: 12),
      TextField(controller: nt, decoration: _d('Notatka (numer seryjny, nr zamówienia…)')),
      const SizedBox(height: 16), FilledButton(onPressed: _save, child: Text(widget.edit == null ? 'Zapisz w szufladzie' : 'Zapisz zmiany')),
    ]));
  }
}
