import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'core.dart';
import 'pages.dart';
import 'services.dart';

class AddPage extends StatefulWidget { final Item? edit; const AddPage({super.key, this.edit}); @override State<AddPage> createState() => _A(); }
class _A extends State<AddPage> {
  final n = TextEditingController(), st = TextEditingController(), pr = TextEditingController(), mo = TextEditingController(text: '24'), nt = TextEditingController(), dn = TextEditingController(), by = TextEditingController();
  DateTime date = today(); String cat = 'Inne', doc = 'Paragon'; bool online = false, busy = false, lowDate = false, scanned = false, empty = false;
  String? photoName, newPath; String raw = ''; List<Line> lines = [];

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) { n.text = e.name; st.text = e.store; pr.text = e.price > 0 ? e.price.toStringAsFixed(2) : ''; mo.text = '${e.months}'; nt.text = e.note; dn.text = e.docNo; by.text = e.buyer; date = e.date; cat = e.cat; doc = e.doc; online = e.online; photoName = e.photo; }
  }

  Future<Parsed?> _fromGallery() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 95);
    return x == null ? null : Scanner.fromFile(x.path);
  }

  Future<void> _scan({bool gallery = false}) async {
    setState(() => busy = true);
    try {
      final r = gallery ? await _fromGallery() : await Scanner.run();
      if (r == null) return;
      setState(() {
        newPath = r.path; st.text = r.store; if (r.date != null) date = r.date!; lowDate = r.date == null; doc = r.doc; dn.text = r.docNo; by.text = r.buyer;
        lines = r.lines..forEach((l) => l.on = l.price > store.threshold);
        final on = lines.where((l) => l.on);
        if (on.isNotEmpty) { n.text = on.first.name; pr.text = on.first.price.toStringAsFixed(2); } else if (r.total != null) { pr.text = r.total!.toStringAsFixed(2); }
        if (n.text.isEmpty && r.nameGuess.isNotEmpty) n.text = r.nameGuess; raw = r.raw; cat = guessCat('${n.text} ${st.text}'); scanned = true; empty = r.store.isEmpty && r.lines.isEmpty && r.total == null;
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

  Widget _sec(BuildContext c, String s) => Padding(padding: const EdgeInsets.only(top: 22, bottom: 10), child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: .4, color: Theme.of(c).colorScheme.primary)));
  Widget _gap() => const SizedBox(height: 12);

  @override
  Widget build(BuildContext c) {
    final cs = Theme.of(c).colorScheme;
    final img = newPath != null ? File(newPath!) : store.img(photoName);
    return Scaffold(appBar: AppBar(title: Text(widget.edit == null ? 'Nowy dokument' : 'Edytuj dokument')), body: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 28), children: [
      Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Icon(Icons.document_scanner_outlined, size: 34, color: cs.primary), const SizedBox(height: 6),
        const Text('Zeskanuj paragon lub fakturę', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        Text('Dane uzupełnimy automatycznie, Ty tylko sprawdzasz.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: FilledButton.icon(onPressed: busy ? null : _scan, icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_camera_outlined, size: 20), label: Text(busy ? 'Odczyt…' : 'Skanuj'))),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton.icon(onPressed: busy ? null : () => _scan(gallery: true), icon: const Icon(Icons.photo_library_outlined, size: 20), label: const Text('Z galerii'))),
        ]),
      ]))),
      if (img != null && img.existsSync()) Padding(padding: const EdgeInsets.only(top: 6), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(img, height: 200, width: double.infinity, fit: BoxFit.cover))),
      if (scanned) Container(margin: const EdgeInsets.only(top: 10), padding: const EdgeInsets.all(12), decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: cs.primary), color: cs.primaryContainer.withOpacity(.4)),
        child: Text(empty ? 'Nie udało się odczytać danych. Uzupełnij je ręcznie.' : 'Dane odczytano ze zdjęcia. Sprawdź je i popraw, jeśli coś się nie zgadza.${lowDate ? ' Data nie została rozpoznana – ustaw ją ręcznie.' : ''}', style: const TextStyle(fontSize: 13.5))),
      if (raw.isNotEmpty) Theme(data: Theme.of(c).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(tilePadding: EdgeInsets.zero, title: Text('Pokaż odczytany tekst', style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant)), children: [SelectableText(raw, style: const TextStyle(fontSize: 12)), TextButton(onPressed: () { Clipboard.setData(ClipboardData(text: raw)); toast(c, 'Skopiowano'); }, child: const Text('Kopiuj tekst'))])),
      if (lines.length > 1) ...[
        _sec(c, 'POZYCJE Z DOKUMENTU (ZAZNACZONE: POWYŻEJ ${store.threshold} ZŁ)'),
        Card(child: Column(children: List.generate(lines.length, (i) => CheckboxListTile(dense: true, controlAffinity: ListTileControlAffinity.leading, value: lines[i].on, title: Text(lines[i].name, maxLines: 2, overflow: TextOverflow.ellipsis), secondary: Text('${lines[i].price.toStringAsFixed(2)} zł', style: const TextStyle(fontWeight: FontWeight.w500)),
          onChanged: (v) => setState(() { lines[i].on = v ?? false; final on = lines.where((l) => l.on); if (on.isNotEmpty) { n.text = on.first.name; pr.text = on.first.price.toStringAsFixed(2); } }))))),
      ],
      _sec(c, 'PRODUKT'),
      TextField(controller: n, decoration: _d('Nazwa produktu', low: scanned && n.text.isEmpty)), _gap(),
      TextField(controller: st, decoration: _d('Sklep')), _gap(),
      TextField(controller: pr, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: _d('Cena brutto (zł)')), _gap(),
      DropdownButtonFormField<String>(value: cat, decoration: _d('Kategoria'), items: icons.keys.map((e) => DropdownMenuItem(value: e, child: Text('${icons[e]} $e'))).toList(), onChanged: (v) => setState(() => cat = v!)),
      _sec(c, 'ZAKUP I GWARANCJA'),
      InkWell(borderRadius: BorderRadius.circular(12), onTap: () async { final d = await showDatePicker(context: c, initialDate: date, firstDate: DateTime(2000), lastDate: DateTime.now().add(const Duration(days: 1))); if (d != null) setState(() { date = d; lowDate = false; }); },
        child: InputDecorator(decoration: _d('Data zakupu', low: lowDate).copyWith(suffixIcon: const Icon(Icons.calendar_today_outlined, size: 20)), child: Text(fmtD.format(date)))), _gap(),
      TextField(controller: mo, keyboardType: TextInputType.number, decoration: _d('Gwarancja (miesiące)')),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Zakup przez internet', style: TextStyle(fontSize: 15)), subtitle: const Text('Przypomnę o 14 dniach na zwrot'), value: online, onChanged: (v) => setState(() => online = v)),
      _sec(c, 'DOKUMENT'),
      DropdownButtonFormField<String>(value: doc, decoration: _d('Rodzaj dokumentu'), items: const ['Paragon', 'Faktura imienna'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) => setState(() => doc = v!)), _gap(),
      TextField(controller: dn, decoration: _d('Numer dokumentu')),
      if (doc == 'Faktura imienna') ...[_gap(), TextField(controller: by, decoration: _d('Nabywca'))], _gap(),
      TextField(controller: nt, decoration: _d('Notatka (numer seryjny, nr zamówienia…)')),
      const SizedBox(height: 24), FilledButton(onPressed: _save, child: Text(widget.edit == null ? 'Zapisz w szufladzie' : 'Zapisz zmiany')),
    ]));
  }
}
