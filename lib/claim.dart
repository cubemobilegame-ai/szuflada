import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'core.dart';
import 'letters.dart';
import 'pages.dart';

class ClaimPage extends StatefulWidget { final Item it; const ClaimPage(this.it, {super.key}); @override State<ClaimPage> createState() => _C(); }
class _C extends State<ClaimPage> {
  String b = 'rek'; int req = 0; DateTime dt = today(); bool out = false; String? photo;
  final desc = TextEditingController(), seller = TextEditingController(), addr = TextEditingController(), lt = TextEditingController();
  final m = <String, TextEditingController>{};
  @override
  void initState() {
    super.initState();
    seller.text = widget.it.store;
    for (final k in ['n', 'a', 'c']) { m[k] = TextEditingController(text: store.me[k] ?? (k == 'n' ? widget.it.buyer : '')); }
  }
  void _basis(String v) => setState(() { b = v; req = 0; out = false; final br = brandOf(widget.it); seller.text = v == 'rek' ? widget.it.store : (br != null ? br[1] : ''); });

  Widget _tips() {
    final br = brandOf(widget.it); final n = br != null ? br[1] : 'producenta';
    return Card(child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Jak skontaktować się z serwisem $n', style: const TextStyle(fontWeight: FontWeight.w600)), const SizedBox(height: 6),
      Text('1. Znajdź kartę gwarancyjną – jest tam adres i telefon gwaranta.\n2. Wejdź na stronę $n → Wsparcie lub Serwis → zgłoszenie online.\n3. Przygotuj model, numer seryjny, dowód zakupu, opis oraz zdjęcia lub film wady.\n4. Poproś o numer zgłoszenia i zachowaj potwierdzenie.\n5. Zapytaj, kto pokrywa koszt przesyłki do serwisu.'),
      if (br != null) Padding(padding: const EdgeInsets.only(top: 6), child: Text(br[2])),
      const Padding(padding: EdgeInsets.only(top: 6), child: Text('Aktualne dane kontaktowe sprawdź na stronie producenta lub w karcie gwarancyjnej.', style: TextStyle(fontSize: 12))),
    ])));
  }

  @override
  Widget build(BuildContext c) {
    final rek = b == 'rek'; final lbl = rek ? rekLbl : gwLbl;
    return Scaffold(appBar: AppBar(title: const Text('Reklamacja')), body: ListView(padding: const EdgeInsets.all(16), children: [
      Text(widget.it.name, style: Theme.of(c).textTheme.titleMedium), const SizedBox(height: 8),
      SegmentedButton<String>(segments: const [ButtonSegment(value: 'rek', label: Text('Rękojmia')), ButtonSegment(value: 'gw', label: Text('Gwarancja'))], selected: {b}, onSelectionChanged: (s) => _basis(s.first)),
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(rek
          ? 'Rękojmia: ustawowe prawo kupującego, 2 lata od wydania towaru, niezależnie od gwarancji. Reklamację kierujesz do sklepu. Zwykle najprostsza i najmocniejsza droga.'
          : 'Gwarancja: dobrowolne zobowiązanie gwaranta opisane w karcie gwarancyjnej. Warunki ustala gwarant. Gwarancja nie wyłącza rękojmi.')),
      TextField(controller: desc, maxLines: 3, decoration: const InputDecoration(labelText: 'Co się stało? Opisz wadę')), const SizedBox(height: 12),
      InkWell(onTap: () async { final d = await showDatePicker(context: c, initialDate: dt, firstDate: DateTime(2000), lastDate: DateTime.now()); if (d != null) setState(() => dt = d); }, child: InputDecorator(decoration: const InputDecoration(labelText: 'Kiedy zauważyłeś wadę?'), child: Text(fmtD.format(dt)))),
      const SizedBox(height: 12), DropdownButtonFormField<int>(value: req, decoration: const InputDecoration(labelText: 'Czego żądasz?'), items: List.generate(lbl.length, (i) => DropdownMenuItem(value: i, child: Text(lbl[i]))), onChanged: (v) => setState(() => req = v!)),
      if (rek) const Padding(padding: EdgeInsets.only(top: 4), child: Text('Zwykle zaczyna się od naprawy lub wymiany. Obniżenie ceny lub odstąpienie od umowy przysługuje m.in. gdy naprawa lub wymiana jest niemożliwa albo się nie udała.', style: TextStyle(fontSize: 12))),
      const SizedBox(height: 12), TextField(controller: seller, decoration: InputDecoration(labelText: rek ? 'Sprzedawca' : 'Gwarant (producent)')),
      const SizedBox(height: 12), TextField(controller: addr, decoration: InputDecoration(labelText: 'Adres ${rek ? 'sprzedawcy' : 'gwaranta'} (z paragonu lub karty gwarancyjnej)')),
      const SizedBox(height: 12), const Text('Twoje dane'),
      for (final e in {'n': 'Imię i nazwisko', 'a': 'Adres', 'c': 'E-mail lub telefon'}.entries) Padding(padding: const EdgeInsets.only(top: 8), child: TextField(controller: m[e.key], decoration: InputDecoration(labelText: e.value))),
      const SizedBox(height: 12),
      OutlinedButton.icon(onPressed: () async {
        final x = await ImagePicker().pickImage(source: ImageSource.camera, imageQuality: 80, maxWidth: 1600);
        if (x != null) { final n = await store.importImage(x.path); setState(() => photo = n); }
      }, icon: const Icon(Icons.photo_camera), label: Text(photo == null ? 'Dodaj zdjęcie wady (opcjonalnie)' : 'Zdjęcie wady dodane')),
      const SizedBox(height: 12),
      FilledButton(onPressed: () async {
        final me = {for (final e in m.entries) e.key: e.value.text.trim()};
        await store.setMe(me);
        setState(() { lt.text = buildLetter(widget.it, b, req, desc.text, dt, seller.text, addr.text, me); out = true; });
      }, child: const Text('Przygotuj pismo')),
      if (out) ...[
        const SizedBox(height: 16), const Text('Gotowe pismo. Możesz je poprawić. To wzór ogólny, a nie porada prawna.'), const SizedBox(height: 8),
        TextField(controller: lt, maxLines: 16, decoration: const InputDecoration(alignLabelWithHint: true)), const SizedBox(height: 8),
        FilledButton.tonal(onPressed: () { Clipboard.setData(ClipboardData(text: lt.text)); toast(c, 'Skopiowano pismo'); }, child: const Text('Kopiuj pismo')), const SizedBox(height: 8),
        FilledButton.tonal(onPressed: () => sharePdf(lt.text, 'reklamacja-${widget.it.name}'), child: const Text('Zapisz / udostępnij jako PDF')), const SizedBox(height: 8),
        FilledButton(onPressed: () async {
          widget.it.claim = Claim(basis: b, date: today(), photo: photo);
          await store.save();
          if (c.mounted) { toast(c, rek ? 'Zapisano. Przypomnę po 14 dniach.' : 'Zapisano zgłoszenie gwarancyjne.'); Navigator.pop(c); }
        }, child: Text('Oznacz jako złożoną${rek ? ' i ustaw przypomnienie' : ''}')),
        if (rek) const Card(child: Padding(padding: EdgeInsets.all(14), child: Text('Jak wysłać: mailem do sklepu lub listem poleconym, i zachowaj potwierdzenie. Po 14 dniach bez odpowiedzi przypomnimy, że żądanie uznaje się za uzasadnione.'))) else _tips(),
      ],
    ]));
  }
}
