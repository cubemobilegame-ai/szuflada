import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'core.dart';
import 'services.dart';
import 'ui.dart';

Future<void> openAddSheet(BuildContext c, {Item? edit, bool autoScan = false}) => showSheet(c, (ctx) => AddForm(edit: edit, autoScan: autoScan));

class AddForm extends StatefulWidget {
  final Item? edit; final bool autoScan;
  const AddForm({super.key, this.edit, this.autoScan = false});
  @override
  State<AddForm> createState() => _AddState();
}
class _AddState extends State<AddForm> {
  final n = TextEditingController(), st = TextEditingController(), pr = TextEditingController(), nt = TextEditingController(), dn = TextEditingController(), by = TextEditingController(), mo = TextEditingController();
  final nameFocus = FocusNode();
  DateTime date = today(); String cat = 'Inne', doc = 'Paragon'; int months = 24; bool customMonths = false;
  bool online = false, busy = false, scanned = false, empty = false, lowDate = false, catTouched = false, showRaw = false, saving = false;
  String? photoName, newPath; String raw = ''; List<Line> lines = [];

  bool get editing => widget.edit != null;
  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    if (e != null) {
      n.text = e.name; st.text = e.store; pr.text = e.price > 0 ? _price(e.price) : ''; nt.text = e.note; dn.text = e.docNo; by.text = e.buyer;
      date = e.date; cat = e.cat; doc = e.doc; online = e.online; photoName = e.photo; months = e.months; catTouched = true;
      customMonths = ![12, 24, 36, 60].contains(e.months); mo.text = '${e.months}';
    }
    if (widget.autoScan) WidgetsBinding.instance.addPostFrameCallback((_) => _scan());
  }
  @override
  void dispose() { for (final x in [n, st, pr, nt, dn, by, mo]) { x.dispose(); } nameFocus.dispose(); super.dispose(); }
  String _price(double v) => v.toStringAsFixed(2).replaceAll('.', ',');
  void _autoCat() { if (!catTouched) setState(() => cat = guessCat('${n.text} ${st.text}')); }

  Future<void> _scan({bool gallery = false}) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      Parsed? r;
      if (gallery) {
        final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 2400, imageQuality: 95);
        if (x == null) return;
        r = await Scanner.fromFile(x.path);
      } else {
        r = await Scanner.run();
      }
      if (r == null || !mounted) return;
      final p = r;
      setState(() {
        newPath = p.path; scanned = true; raw = p.raw;
        if (p.store.isNotEmpty) st.text = p.store;
        if (p.date != null) date = p.date!;
        lowDate = p.date == null;
        doc = p.doc; if (p.docNo.isNotEmpty) dn.text = p.docNo; if (p.buyer.isNotEmpty) by.text = p.buyer;
        lines = p.lines; for (final l in lines) { l.on = l.price >= store.threshold; }
        if (lines.isNotEmpty && !lines.any((l) => l.on)) { final top = lines.reduce((a, b) => a.price >= b.price ? a : b); top.on = true; }
        final on = lines.where((l) => l.on);
        if (on.isNotEmpty) { n.text = on.first.name; pr.text = _price(on.first.price); }
        else if (p.total != null) { pr.text = _price(p.total!); }
        if (n.text.isEmpty && p.nameGuess.isNotEmpty) n.text = p.nameGuess;
        empty = p.store.isEmpty && p.lines.isEmpty && p.total == null;
        if (!catTouched) cat = guessCat('${n.text} ${st.text}');
      });
      HapticFeedback.mediumImpact();
    } on PlatformException catch (e) {
      toast(e.code == 'canceled' || e.code == 'cancel' ? 'Anulowano skanowanie' : 'Skaner jest niedostępny. Wybierz zdjęcie z galerii.');
    } catch (_) {
      toast('Nie udało się odczytać dokumentu. Uzupełnij dane ręcznie.');
    } finally { if (mounted) setState(() => busy = false); }
  }

  void _pickLine(int i, bool v) {
    setState(() {
      lines[i].on = v;
      final on = lines.where((l) => l.on);
      if (on.isNotEmpty) { n.text = on.first.name; pr.text = _price(on.first.price); }
      if (!catTouched) cat = guessCat('${n.text} ${st.text}');
    });
  }

  Future<void> _date() async {
    final d = await showDatePicker(context: context, initialDate: date.isAfter(today()) ? today() : date, firstDate: DateTime(2000), lastDate: today(), helpText: 'Data zakupu', locale: const Locale('pl'));
    if (d != null) setState(() { date = d; lowDate = false; });
  }

  Future<void> _save() async {
    if (saving) return;
    final name = n.text.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (name.isEmpty) { toast('Wpisz nazwę produktu'); nameFocus.requestFocus(); return; }
    final price = parseMoney(pr.text);
    if (pr.text.trim().isNotEmpty && price == null) { toast('Sprawdź cenę, np. 1299,99'); return; }
    var m = months;
    if (customMonths) { final v = int.tryParse(mo.text.trim()); if (v == null || v < 1 || v > 240) { toast('Podaj gwarancję w miesiącach (1–240)'); return; } m = v; }
    setState(() => saving = true);
    try {
      var ph = photoName; if (newPath != null) ph = await store.importImage(newPath!);
      final e = widget.edit;
      final base = Item(id: e?.id ?? DateTime.now().millisecondsSinceEpoch, name: name, store: st.text.trim(), cat: cat, doc: doc, docNo: dn.text.trim(), buyer: doc == 'Faktura imienna' ? by.text.trim() : '',
          note: nt.text.trim(), date: date, price: price ?? 0, months: m, online: online, photo: ph, claim: e?.claim);
      if (e != null) {
        final i = store.items.indexWhere((x) => x.id == e.id);
        if (i >= 0) store.items[i] = base;
      } else {
        store.items.add(base); var k = 1; var skipped = 0;
        for (final l in lines.where((l) => l.on).skip(1)) {
          if (!store.canAdd) { skipped++; continue; }
          store.items.add(base.copy(id: base.id + k++, name: l.name, price: l.price, cat: guessCat('${l.name} ${base.store}')));
        }
        if (skipped > 0) toast('Pominięto $skipped ${pl(skipped, 'pozycję', 'pozycje', 'pozycji')} – limit planu Start');
      }
      await store.save();
      if (!mounted) return;
      Navigator.pop(context);
      final cnt = editing ? 0 : 1 + lines.where((l) => l.on).skip(1).length;
      toast(editing ? 'Zapisano zmiany' : cnt > 1 ? 'Zapisano $cnt ${pl(cnt, 'produkt', 'produkty', 'produktów')}' : 'Zapisano. Przypomnimy przed końcem gwarancji.');
    } catch (_) {
      toast('Nie udało się zapisać. Spróbuj ponownie.');
    } finally { if (mounted) setState(() => saving = false); }
  }

  @override
  Widget build(BuildContext c) {
    final t = c.t;
    final img = newPath != null ? File(newPath!) : store.img(photoName);
    final hasImg = img != null && img.existsSync();
    final q = st.text.trim().toLowerCase();
    final known = <String>{...store.items.map((e) => e.store).where((s) => s.isNotEmpty), ...popularStores}.toList();
    final sugg = known.where((s) => q.isEmpty ? true : s.toLowerCase().contains(q) && s.toLowerCase() != q).take(10).toList();
    final selected = lines.where((l) => l.on).length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      H2(editing ? 'Edytuj dokument' : 'Nowy dokument'),
      Row(children: [
        Expanded(child: ActionTile('camera', hasImg ? 'Skanuj ponownie' : 'Skanuj aparatem', busy ? null : () => _scan(), sub: 'kadruje i czyta sam')),
        const SizedBox(width: 10),
        Expanded(child: ActionTile('image', 'Z galerii', busy ? null : () => _scan(gallery: true), sub: 'zdjęcie lub zrzut')),
      ]),
      const SizedBox(height: 14),
      AnimatedSize(duration: const Duration(milliseconds: 250), curve: Curves.easeOut, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (busy) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(16), decoration: cardDeco(c),
          child: Row(children: [SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.6, color: t.accent)), const SizedBox(width: 14), Expanded(child: Text('Odczytuję dokument…', style: ts(15, w: w7, c: t.text)))])),
        if (!busy && hasImg) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(12), decoration: cardDeco(c),
          child: Row(children: [
            ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(img, width: 60, height: 80, fit: BoxFit.cover, cacheWidth: 240, errorBuilder: (_, __, ___) => const SizedBox(width: 60, height: 80))),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (scanned) ...[
                Row(children: [Ic(empty ? 'alert' : 'check', size: 18, color: empty ? cOrange : cGreen, width: 2.6), const SizedBox(width: 6), Expanded(child: Text(empty ? 'Nie udało się odczytać danych' : 'Dane odczytane', style: ts(15, w: w7, c: t.text)))]),
                const SizedBox(height: 3),
                Text(empty ? 'Uzupełnij pola ręcznie. Zdjęcie i tak zapiszemy.' : 'Sprawdź je i popraw, jeśli coś się nie zgadza.${lowDate ? ' Daty nie rozpoznano.' : ''}', style: ts(13, c: t.sub, h: 1.35)),
                if (raw.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 4), child: LinkBtn(showRaw ? 'Ukryj odczytany tekst' : 'Pokaż odczytany tekst', () => setState(() => showRaw = !showRaw))),
              ] else ...[Text('Zdjęcie dokumentu', style: ts(15, w: w7, c: t.text)), Text('Zeskanuj ponownie, aby je zmienić.', style: ts(13, c: t.sub))],
            ])),
          ])),
        if (showRaw && raw.isNotEmpty) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SelectableText(raw, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: t.text, height: 1.4)),
            LinkBtn('Kopiuj tekst', () { Clipboard.setData(ClipboardData(text: raw)); toast('Skopiowano'); }),
          ])),
        if (!editing && lines.length > 1) Container(margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.fromLTRB(14, 14, 14, 6), decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(24)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [Expanded(child: Text('Pozycje z dokumentu', style: ts(17, w: w8, c: t.text))), Text('$selected z ${lines.length}', style: ts(13, c: t.sub))]),
            Padding(padding: const EdgeInsets.only(top: 2, bottom: 6), child: Text('Każda zaznaczona pozycja zapisze się jako osobny produkt z tym samym paragonem.', style: ts(13, c: t.sub, h: 1.35))),
            for (var i = 0; i < lines.length; i++) Tap(onTap: () => _pickLine(i, !lines[i].on), scale: .99, child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(border: i == lines.length - 1 ? null : Border(bottom: BorderSide(color: t.text.withValues(alpha: .08)))),
              child: Row(children: [
                AnimatedContainer(duration: const Duration(milliseconds: 150), width: 26, height: 26, decoration: BoxDecoration(shape: BoxShape.circle, color: lines[i].on ? cGreen : Colors.transparent, border: Border.all(color: lines[i].on ? cGreen : t.text.withValues(alpha: .35), width: 2)),
                  child: lines[i].on ? const Center(child: Ic('check', size: 15, width: 3)) : null),
                const SizedBox(width: 12),
                Expanded(child: Text(lines[i].name, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(15, w: lines[i].on ? w6 : w5, c: lines[i].on ? t.text : t.sub))),
                const SizedBox(width: 8),
                Text(money(lines[i].price), style: ts(14, w: w7, c: t.text)),
              ]),
            )),
          ])),
      ])),
      Field('Nazwa produktu', n, hint: 'np. Pralka Bosch Serie 6', focus: nameFocus, warn: scanned && n.text.trim().isEmpty, maxLines: 2, onChanged: (_) => _autoCat(), action: TextInputAction.next),
      Field('Sklep', st, hint: 'np. Media Expert', onChanged: (_) { _autoCat(); setState(() {}); }, action: TextInputAction.next, caps: TextCapitalization.words),
      if (sugg.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 14), child: Bleed(SizedBox(height: 36, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 18), children: [
        for (final s in sugg) Padding(padding: const EdgeInsets.only(right: 8), child: Tap(onTap: () { st.text = s; st.selection = TextSelection.collapsed(offset: s.length); _autoCat(); setState(() {}); FocusScope.of(c).unfocus(); },
          child: Container(padding: const EdgeInsets.symmetric(horizontal: 14), alignment: Alignment.center, decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(14), boxShadow: t.softShadow),
            child: Row(mainAxisSize: MainAxisSize.min, children: [Ic('store', size: 15, color: t.accent, width: 2.1), const SizedBox(width: 6), Text(s, style: ts(14, w: w6, c: t.text))])))),
      ])), by: 18, height: 36)),
      LayoutBuilder(builder: (_, cons) {
        final price = Field('Cena (zł)', pr, hint: '2299,00', kb: const TextInputType.numberWithOptions(decimal: true), fmt: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))]);
        final day = FieldBtn('Data zakupu', fmtD.format(date), _date, warn: lowDate);
        if (cons.maxWidth < 330) return Column(children: [price, day]);
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: price), const SizedBox(width: 10), Expanded(child: day)]);
      }),
      Padding(padding: const EdgeInsets.only(bottom: 6, left: 2), child: Text('Gwarancja', style: ts(13, c: t.sub))),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final m in [12, 24, 36, 60]) _choice(c, m % 12 == 0 ? '${m ~/ 12} ${pl(m ~/ 12, 'rok', 'lata', 'lat')}' : '$m mies.', !customMonths && months == m, () => setState(() { months = m; customMonths = false; })),
        _choice(c, 'Inna', customMonths, () => setState(() { customMonths = true; if (mo.text.isEmpty) mo.text = '$months'; })),
      ]),
      const SizedBox(height: 10),
      if (customMonths) Field('Gwarancja w miesiącach', mo, hint: 'np. 30', kb: TextInputType.number, fmt: [FilteringTextInputFormatter.digitsOnly]),
      Padding(padding: const EdgeInsets.only(bottom: 12, left: 2), child: Text('Koniec gwarancji: ${fmtD.format(addMonths(date, customMonths ? (int.tryParse(mo.text) ?? months) : months))}', style: ts(13, w: w6, c: t.accent))),
      Padding(padding: const EdgeInsets.only(bottom: 6, left: 2), child: Row(children: [Text('Kategoria', style: ts(13, c: t.sub)), if (!catTouched && cat != 'Inne') Text(' · wykryta automatycznie', style: ts(13, c: t.accent))])),
      Padding(padding: const EdgeInsets.only(bottom: 14), child: Bleed(Chips(items: [for (final k in cats) k.name], value: cat, icons: {for (final k in cats) k.name: k.icon}, iconColors: {for (final k in cats) k.name: k.color}, onPick: (v) => setState(() { cat = v; catTouched = true; }), pad: const EdgeInsets.symmetric(horizontal: 18)), by: 18)),
      Seg<String>(values: const ['Paragon', 'Faktura imienna'], labels: const ['Paragon', 'Faktura imienna'], value: doc, onChanged: (v) => setState(() => doc = v)),
      const SizedBox(height: 12),
      Field(doc == 'Paragon' ? 'Numer paragonu (opcjonalnie)' : 'Numer faktury', dn, hint: doc == 'Paragon' ? 'np. 1234/56' : 'np. FV/10/2026/0412', caps: TextCapitalization.characters),
      if (doc == 'Faktura imienna') Field('Nabywca', by, hint: 'imię i nazwisko z faktury', caps: TextCapitalization.words),
      Tap(onTap: () => setState(() => online = !online), scale: .99, child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13), decoration: cardDeco(c),
        child: Row(children: [
          const IconSq('globe', cBlue, size: 32), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Kupione przez internet', style: ts(15, w: w7, c: t.text)), Text('Przypomnimy o 14 dniach na zwrot', style: ts(13, c: t.sub))])),
          Sw(online, s: .85),
        ]))),
      Field('Notatka', nt, hint: 'numer seryjny, nr zamówienia…', maxLines: 3),
      const SizedBox(height: 6),
      Cta(editing ? 'Zapisz zmiany' : selected > 1 ? 'Zapisz $selected ${pl(selected, 'produkt', 'produkty', 'produktów')}' : 'Zapisz w szufladzie', busy ? null : _save, busy: saving, icon: 'check'),
    ]);
  }

  Widget _choice(BuildContext c, String label, bool on, VoidCallback tap) {
    final t = c.t;
    return Tap(onTap: () { HapticFeedback.selectionClick(); tap(); }, child: AnimatedContainer(duration: const Duration(milliseconds: 150), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: on ? t.accent : t.card, borderRadius: BorderRadius.circular(14), boxShadow: on ? null : t.softShadow),
        child: Text(label, style: ts(14, w: w7, c: on ? t.on : t.text))));
  }
}
