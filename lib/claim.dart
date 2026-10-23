import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'core.dart';
import 'letters.dart';
import 'ui.dart';

Future<void> openClaim(BuildContext c, Item it, {bool reopen = false}) => Navigator.of(c).push(fadeRoute(ClaimFlow(it, reopen: reopen)));

class ClaimFlow extends StatefulWidget {
  final Item it; final bool reopen;
  const ClaimFlow(this.it, {super.key, this.reopen = false});
  @override
  State<ClaimFlow> createState() => _ClaimState();
}
class _ClaimState extends State<ClaimFlow> {
  int step = 0; String b = 'rek'; int req = 0; DateTime dt = today(); String? photo; bool working = false, descWarn = false;
  final desc = TextEditingController(), seller = TextEditingController(), addr = TextEditingController(), lt = TextEditingController();
  final m = <String, TextEditingController>{};
  final sc = ScrollController();
  Item get it => widget.it;

  @override
  void initState() {
    super.initState();
    for (final k in ['n', 'a', 'c']) { m[k] = TextEditingController(text: store.me[k] ?? (k == 'n' ? it.buyer : '')); }
    final cl = it.claim;
    b = it.rekLeft >= 0 ? 'rek' : 'gw';
    if (cl != null) { b = cl.basis; req = cl.req; desc.text = cl.desc; photo = cl.photo; if (widget.reopen) dt = cl.date; }
    seller.text = cl != null && cl.seller.isNotEmpty ? cl.seller : _defSeller(b);
    if (widget.reopen && cl != null) { lt.text = _letter(); step = 2; }
  }
  @override
  void dispose() { for (final x in [desc, seller, addr, lt, ...m.values]) { x.dispose(); } sc.dispose(); super.dispose(); }
  String _defSeller(String basis) { final br = brandOf(it); return basis == 'rek' ? it.store : (br != null ? br[1] : ''); }
  Map<String, String> get _me => {for (final e in m.entries) e.key: e.value.text.trim()};
  String _letter() => buildLetter(it, b, req, desc.text.trim(), dt, seller.text.trim(), addr.text.trim(), _me);
  void _go(int s) { FocusScope.of(context).unfocus(); setState(() => step = s); if (sc.hasClients) sc.jumpTo(0); }

  Future<void> _photo(ImageSource src) async {
    try {
      final x = await ImagePicker().pickImage(source: src, imageQuality: 82, maxWidth: 1800);
      if (x == null) return;
      final n = await store.importImage(x.path);
      setState(() => photo = n);
    } catch (_) { toast('Nie udało się dodać zdjęcia'); }
  }

  @override
  Widget build(BuildContext c) {
    final t = c.t; final mq = MediaQuery.of(c);
    const titles = ['Na jakiej podstawie?', 'Opisz usterkę', 'Gotowe pismo'];
    return PopScope(
      canPop: step == 0 || widget.reopen,
      onPopInvokedWithResult: (did, _) { if (!did) _go(step - 1); },
      child: Scaffold(backgroundColor: t.bg, body: Column(children: [
        Padding(padding: EdgeInsets.fromLTRB(12, mq.padding.top + 10, 12, 6), child: Row(children: [
          Tap(onTap: () => (step == 0 || widget.reopen) ? Navigator.pop(c) : _go(step - 1), child: Container(width: 40, height: 40, decoration: BoxDecoration(color: t.card, shape: BoxShape.circle, boxShadow: t.softShadow), child: Center(child: Ic('back', size: 20, color: t.text, width: 2.3)))),
          const Spacer(),
          if (!widget.reopen) Row(children: [for (var k = 0; k < 3; k++) AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.only(left: 6), width: k == step ? 26 : 8, height: 8,
            decoration: BoxDecoration(color: k <= step ? t.accent : t.line, borderRadius: BorderRadius.circular(99)))]),
          const Spacer(),
          const SizedBox(width: 40),
        ])),
        Expanded(child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: SingleChildScrollView(
          controller: sc, padding: EdgeInsets.fromLTRB(16, 4, 16, 28 + mq.padding.bottom),
          child: AnimatedSwitcher(duration: const Duration(milliseconds: 260), transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(.04, 0), end: Offset.zero).animate(a), child: w)),
            child: KeyedSubtree(key: ValueKey(step), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              H1(titles[step]),
              Padding(padding: const EdgeInsets.only(bottom: 16), child: Muted('${it.name}${it.store.isNotEmpty ? ' · ${it.store}' : ''} · kupione ${fmtD.format(it.date)}')),
              ...[_basis, _form, _out][step](c),
            ]))),
        )))),
      ])),
    );
  }

  // krok 1: rękojmia czy gwarancja
  List<Widget> _basis(BuildContext c) {
    final rekOk = it.rekLeft >= 0;
    return [
      _option(c, 'rek', 'store', cGreen, 'Rękojmia', 'wobec sklepu',
          'Twoje prawo z ustawy: 2 lata od zakupu, niezależnie od gwarancji. Sklep ma 14 dni na odpowiedź, a jeśli milczy, reklamacja jest uznana.',
          rekOk ? 'Zalecane · do ${fmtD.format(it.rekEnd)}' : 'Minęły 2 lata od zakupu', rekOk),
      const SizedBox(height: 12),
      _option(c, 'gw', 'shield', cBlue, 'Gwarancja', 'wobec producenta',
          'Dobrowolna obietnica producenta. Zasady opisuje karta gwarancyjna, naprawą zwykle zajmuje się serwis. Nie odbiera prawa do rękojmi.',
          it.active ? 'Ważna do ${fmtD.format(it.end)}' : 'Minęła ${fmtD.format(it.end)} · sprawdź kartę gwarancyjną', true),
      const SizedBox(height: 16),
      Center(child: LinkBtn('Nie wiesz, co wybrać? Przeczytaj krótko', () => _lawQuick(c))),
    ];
  }
  Widget _option(BuildContext c, String key, String icon, Color col, String title, String sub, String text, String badge, bool enabled) {
    final t = c.t;
    return Opacity(opacity: enabled ? 1 : .5, child: Tap(onTap: enabled ? () { setState(() { if (b != key) { b = key; req = 0; seller.text = _defSeller(key); } }); _go(1); } : null, child: Container(
      padding: const EdgeInsets.all(18), decoration: cardDeco(c, r: 26),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [IconSq(icon, col, size: 40), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ts(19, w: w8, c: t.text)), Text(sub, style: ts(13, c: t.sub))])),
          Ic('chev', size: 18, color: t.sub, width: 2.2)]),
        const SizedBox(height: 12),
        Text(text, style: ts(14, c: t.text, h: 1.5)),
        const SizedBox(height: 12),
        Pill(badge, bg: col.withValues(alpha: .13), fg: enabled ? col : t.sub),
      ]),
    )));
  }
  void _lawQuick(BuildContext c) => showSheet(c, (ctx) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        H2('Co wybrać?'),
        P('Najczęściej najlepsza jest rękojmia: składasz ją w sklepie, sklep musi odpowiedzieć w 14 dni, a brak odpowiedzi oznacza uznanie reklamacji.'),
        P('Gwarancję wybierz, gdy minęły 2 lata od zakupu, gdy sklep już nie istnieje albo gdy producent oferuje wygodny serwis, np. odbiór kurierem.'),
        P('Wybór gwarancji nie zamyka drogi do rękojmi.'),
      ]));

  // krok 2: formularz
  List<Widget> _form(BuildContext c) {
    final t = c.t; final rek = b == 'rek'; final lbl = rek ? rekLbl : gwLbl;
    final ph = store.img(photo);
    return [
      Field('Co się stało?', desc, hint: 'np. pralka nie wiruje i pokazuje błąd E18', maxLines: 4, warn: descWarn, onChanged: (_) { if (descWarn) setState(() => descWarn = false); }),
      FieldBtn('Kiedy zauważyłeś usterkę?', fmtD.format(dt), () async {
        final d = await showDatePicker(context: c, initialDate: dt.isBefore(it.date) ? it.date : dt, firstDate: it.date, lastDate: today(), helpText: 'Data zauważenia usterki', locale: const Locale('pl'));
        if (d != null) setState(() => dt = d);
      }),
      Padding(padding: const EdgeInsets.only(bottom: 8, left: 2), child: Text('Czego żądasz?', style: ts(13, c: t.sub))),
      Container(decoration: cardDeco(c, r: 22), child: Column(children: [
        for (var k = 0; k < lbl.length; k++) Tap(onTap: () => setState(() => req = k), scale: .99, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(border: k == lbl.length - 1 ? null : Border(bottom: BorderSide(color: t.line))),
          child: Row(children: [
            AnimatedContainer(duration: const Duration(milliseconds: 150), width: 22, height: 22, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: req == k ? t.accent : t.sub, width: req == k ? 7 : 1.8))),
            const SizedBox(width: 12), Expanded(child: Text(lbl[k], style: ts(15, w: req == k ? w7 : w5, c: t.text))),
          ]),
        )),
      ])),
      Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 16), child: Text(rek
          ? 'Zwykle zaczyna się od naprawy lub wymiany. Obniżenie ceny lub zwrot pieniędzy przysługuje m.in., gdy naprawa lub wymiana jest niemożliwa albo się nie udała.'
          : 'Sprawdź w karcie gwarancyjnej, co obejmuje gwarancja.', style: ts(13, c: t.sub, h: 1.4))),
      Field(rek ? 'Sprzedawca' : 'Gwarant (producent)', seller, hint: rek ? 'nazwa sklepu' : 'np. Samsung Electronics Polska', caps: TextCapitalization.words),
      Field('Adres ${rek ? 'sklepu' : 'gwaranta'}', addr, hint: rek ? 'z paragonu lub strony sklepu' : 'z karty gwarancyjnej', maxLines: 2),
      const SizedBox(height: 6),
      Text('Twoje dane', style: ts(16, w: w8, c: t.text)), const SizedBox(height: 10),
      Field('Imię i nazwisko', m['n']!, caps: TextCapitalization.words),
      Field('Adres', m['a']!, maxLines: 2),
      Field('E-mail lub telefon', m['c']!, kb: TextInputType.emailAddress, caps: TextCapitalization.none),
      Text('Zdjęcie usterki (opcjonalnie)', style: ts(16, w: w8, c: t.text)), const SizedBox(height: 10),
      if (ph != null && ph.existsSync()) Container(margin: const EdgeInsets.only(bottom: 10), height: 160, decoration: cardDeco(c, r: 20), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(fit: StackFit.expand, children: [
        Image.file(ph, fit: BoxFit.cover, cacheWidth: 900),
        Positioned(top: 10, right: 10, child: CloseX(onTap: () => setState(() => photo = null))),
      ]))),
      Row(children: [
        Expanded(child: ActionTile('camera', 'Zrób zdjęcie', () => _photo(ImageSource.camera))),
        const SizedBox(width: 10),
        Expanded(child: ActionTile('image', 'Z galerii', () => _photo(ImageSource.gallery))),
      ]),
      const SizedBox(height: 20),
      Cta('Przygotuj pismo', () async {
        if (desc.text.trim().isEmpty) { setState(() => descWarn = true); toast('Opisz krótko usterkę'); if (sc.hasClients) sc.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut); return; }
        await store.setMe(_me);
        lt.text = _letter(); _go(2);
      }, icon: 'doc'),
    ];
  }

  // krok 3: pismo
  List<Widget> _out(BuildContext c) {
    final t = c.t; final rek = b == 'rek'; final br = brandOf(it); final cl = it.claim;
    return [
      Container(padding: const EdgeInsets.all(4), decoration: cardDeco(c, r: 22), child: TextField(
        controller: lt, maxLines: null, minLines: 12, style: ts(14, c: t.text, h: 1.5), cursorColor: t.accent,
        decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(14)),
      )),
      Padding(padding: const EdgeInsets.fromLTRB(4, 8, 4, 16), child: Text('Możesz poprawić treść. To wzór ogólny, a nie porada prawna.', style: ts(12, c: t.sub))),
      Cta('Zapisz PDF i udostępnij', working ? null : () async {
        setState(() => working = true);
        try { await sharePdf(lt.text, 'reklamacja-${it.name}', receipt: store.img(it.photo), defect: store.img(photo)); }
        catch (_) { toast('Nie udało się utworzyć PDF'); }
        finally { if (mounted) setState(() => working = false); }
      }, icon: 'download', busy: working),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: Ghost('Kopiuj', () { Clipboard.setData(ClipboardData(text: lt.text)); toast('Skopiowano pismo'); }, icon: 'copy')),
        const SizedBox(width: 10),
        Expanded(child: Ghost('Wyślij', () => Share.share(lt.text, subject: rek ? 'Reklamacja: ${it.name}' : 'Zgłoszenie gwarancyjne: ${it.name}'), icon: 'send')),
      ]),
      const SizedBox(height: 18),
      if (cl == null || widget.reopen == false) Cta(rek ? 'Oznacz jako złożoną i przypomnij za 14 dni' : 'Oznacz jako złożoną', () async {
        it.claim = Claim(basis: b, date: today(), photo: photo, req: req, desc: desc.text.trim(), seller: seller.text.trim());
        await store.save();
        if (!mounted) return;
        Navigator.pop(context);
        toast(rek ? 'Zapisano. Przypomnimy, gdy minie 14 dni.' : 'Zapisano zgłoszenie gwarancyjne.');
      }, color: cGreen, fg: Colors.white, icon: 'check'),
      const SizedBox(height: 18),
      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: t.panel, borderRadius: BorderRadius.circular(24)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: rek ? [
        Text('Jak wysłać reklamację', style: ts(16, w: w8, c: t.text)), const SizedBox(height: 8),
        const Li('E-mailem do sklepu lub listem poleconym. Zachowaj potwierdzenie wysłania.'),
        const Li('Możesz też zanieść pismo i towar do sklepu. Poproś o potwierdzenie przyjęcia.'),
        const Li('Dołącz kopię paragonu lub faktury i zdjęcia usterki.'),
        const Li('Sklep ma 14 dni na odpowiedź. Przypomnimy Ci o tym terminie.'),
      ] : [
        Text('Jak zgłosić usterkę do serwisu ${br != null ? br[1] : 'producenta'}', style: ts(16, w: w8, c: t.text)), const SizedBox(height: 8),
        const Li('Znajdź kartę gwarancyjną. Jest tam adres i telefon gwaranta.'),
        Li('Wejdź na stronę ${br != null ? br[1] : 'producenta'} → Wsparcie lub Serwis → zgłoszenie online.'),
        const Li('Przygotuj model, numer seryjny, dowód zakupu, opis oraz zdjęcia lub film usterki.'),
        const Li('Poproś o numer zgłoszenia i zachowaj potwierdzenie.'),
        const Li('Zapytaj, kto płaci za przesyłkę do serwisu.'),
        if (br != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(br[2], style: ts(13, c: t.sub, h: 1.4))),
      ])),
    ];
  }
}
