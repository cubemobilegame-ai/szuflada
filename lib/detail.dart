import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add.dart';
import 'claim.dart';
import 'core.dart';
import 'pages.dart';
import 'services.dart';
import 'ui.dart';

// szczegóły dokumentu: kolorowy nagłówek kategorii, karta wysuwa się od dołu
class DetailPage extends StatefulWidget {
  final int id; const DetailPage(this.id, {super.key});
  @override
  State<DetailPage> createState() => _DetailState();
}
class _DetailState extends State<DetailPage> with SingleTickerProviderStateMixin {
  late final AnimationController up = AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..forward();
  @override
  void dispose() { up.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext c) => ListenableBuilder(listenable: store, builder: (_, __) {
        final it = store.byId(widget.id);
        if (it == null) return Scaffold(backgroundColor: c.t.bg);
        return _body(c, it);
      });

  Widget _body(BuildContext c, Item it) {
    final t = c.t; final mq = MediaQuery.of(c); final k = catOf(it.cat); final cl = it.claim;
    final img = store.img(it.photo);
    final hasImg = img != null && img.existsSync();
    final anim = CurvedAnimation(parent: up, curve: Curves.easeOutBack);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent), child: Scaffold(
      backgroundColor: t.bg,
      body: SingleChildScrollView(physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), child: Column(children: [
        // nagłówek
        Container(
          width: double.infinity,
          decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.6, -1), end: const Alignment(.6, 1), colors: [k.color, mix(k.color, Colors.black, .58)])),
          child: ClipRect(child: Stack(children: [
            Positioned(right: -30, bottom: -60, child: Opacity(opacity: .13, child: Ic(k.icon, size: 230, width: 1.5))),
            Padding(padding: EdgeInsets.fromLTRB(20, mq.padding.top + 14, 16, 58), child: Column(children: [
              Row(children: [
                Tap(onTap: () => Navigator.pop(c), child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: const Color(0x38FFFFFF), borderRadius: BorderRadius.circular(99)), child: const Ic('back', size: 20, width: 2.4))),
                const Spacer(),
                Tap(onTap: () => openAddSheet(c, edit: it), child: Container(padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 16), decoration: BoxDecoration(color: const Color(0x38FFFFFF), borderRadius: BorderRadius.circular(99)),
                  child: Row(children: [const Ic('edit', size: 16, width: 2.2), const SizedBox(width: 6), Text('Edytuj', style: ts(15, w: w7, c: Colors.white))]))),
              ]),
              const SizedBox(height: 18),
              CatTile(it.cat, size: 64, radius: 19, translucent: true),
              const SizedBox(height: 12),
              Text(it.name, textAlign: TextAlign.center, maxLines: 3, style: ts(26, w: w8, c: Colors.white, ls: -.5, h: 1.2)),
              const SizedBox(height: 4),
              Text([if (it.store.isNotEmpty) it.store, k.name].join(' · '), textAlign: TextAlign.center, style: ts(14, c: const Color(0xE6FFFFFF))),
            ])),
          ])),
        ),
        // karta
        AnimatedBuilder(animation: anim, builder: (_, ch) => Opacity(opacity: up.value, child: Transform.translate(offset: Offset(0, 60 * (1 - anim.value)), child: ch)),
          child: Transform.translate(offset: const Offset(0, -28), child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: t.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
            padding: EdgeInsets.fromLTRB(14, 18, 14, 24 + mq.padding.bottom),
            child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              _countdown(c, it),
              if (cl != null) ...[const SizedBox(height: 12), _claimCard(c, it, cl)],
              const SizedBox(height: 12), _receiptCard(c, it, hasImg ? img : null),
              Group([
                if (it.price > 0) _info(c, 'coins', cAmber, 'Cena', money(it.price)),
                _info(c, 'calendar', cRed, 'Data zakupu', fmtD.format(it.date)),
                _info(c, 'shield', cGreen, 'Gwarancja', '${monthsTxt(it.months)} · do ${fmtD.format(it.end)}'),
                if (it.months != 24) _info(c, 'store', cIndigo, 'Rękojmia (sklep)', '2 lata · do ${fmtD.format(it.rekEnd)}'),
                if (it.online) _info(c, 'globe', cBlue, 'Zakup w internecie', 'zwrot do ${fmtD.format(addDays(it.date, 14))}'),
                _info(c, 'receipt', cGray, it.doc, it.docNo.isEmpty ? 'bez numeru' : 'nr ${it.docNo}', copy: it.docNo),
                if (it.buyer.isNotEmpty) _info(c, 'user', t.accent, 'Nabywca', it.buyer),
                if (it.note.isNotEmpty) _info(c, 'note', cOrange, 'Notatka', it.note, copy: it.note),
              ]),
              Cta(cl != null && cl.open ? 'Zobacz reklamację' : 'Złóż reklamację', () {
                if (cl != null && cl.open) { showClaimStatus(c, it); return; }
                if (!store.pro) { showPaywall(c); return; }
                openClaim(c, it);
              }, icon: 'flag'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _act(c, 'share', 'Udostępnij', () => shareItem(it))),
                const SizedBox(width: 10),
                Expanded(child: _act(c, 'edit', 'Edytuj', () => openAddSheet(c, edit: it))),
                const SizedBox(width: 10),
                Expanded(child: _act(c, 'trash', 'Usuń', () async {
                  if (await confirmBox(c, 'Usunąć dokument?', '„${it.name}” zniknie z szuflady razem z przypomnieniami.', 'Usuń')) {
                    if (c.mounted) Navigator.pop(c);
                    await store.remove(it); toast('Usunięto');
                  }
                }, color: cRed)),
              ]),
            ]))),
          )),
        ),
      ])),
    ));
  }

  Widget _countdown(BuildContext c, Item it) {
    final t = c.t; final n = it.left; final col = dayColor(n);
    final big = n < 0 ? '—' : n < 100 ? '$n' : n < 730 ? '${(n / 30.4).round()}' : '${n ~/ 365}';
    final unit = n < 0 ? 'po terminie' : n < 100 ? pl(n, 'dzień', 'dni', 'dni') : n < 730 ? 'mies.' : pl(n ~/ 365, 'rok', 'lata', 'lat');
    final line = n < 0 ? 'Gwarancja minęła ${fmtD.format(it.end)}' : n == 0 ? 'Gwarancja kończy się dziś' : 'Zostało ${daysTxt(n)} gwarancji';
    return Container(padding: const EdgeInsets.all(16), decoration: cardDeco(c, r: 26), child: Row(children: [
      SizedBox(width: 96, height: 96, child: TweenAnimationBuilder<double>(tween: Tween(begin: 0, end: it.progress), duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
        builder: (_, v, __) => CustomPaint(painter: RingPaint(v, col, t.text.withValues(alpha: .08)), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(big, style: ts(26, w: w8, c: t.text, ls: -1, h: 1)), Text(unit, style: ts(11, w: w6, c: t.sub)),
        ]))))),
      const SizedBox(width: 16),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Gwarancja do', style: ts(13, c: t.sub)),
        Text(fmtD.format(it.end), style: ts(22, w: w8, c: t.text, ls: -.5)),
        const SizedBox(height: 6),
        Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 6), Expanded(child: Text(line, style: ts(13, w: w7, c: col)))]),
        if (n < 0 && it.rekLeft >= 0) Padding(padding: const EdgeInsets.only(top: 4), child: Text('Rękojmia w sklepie trwa jeszcze ${daysTxt(it.rekLeft)}.', style: ts(12, c: t.sub, h: 1.3))),
      ])),
    ]));
  }

  Widget _claimCard(BuildContext c, Item it, Claim cl) {
    final t = c.t; final n = daysBetween(today(), cl.answerBy);
    final (String txt, Color col) = !cl.open ? (cl.status == 'ok' ? ('Reklamacja uznana', cGreen) : ('Reklamacja odrzucona', cRed))
        : cl.rek ? (n < 0 ? ('Sklep nie odpowiedział w 14 dni, więc reklamacja jest uznana', cGreen) : ('Sklep ma czas na odpowiedź do ${fmtD.format(cl.answerBy)}', cOrange))
        : ('Zgłoszono producentowi ${fmtD.format(cl.date)}', cBlue);
    return Tap(onTap: () => showClaimStatus(c, it), child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: col.withValues(alpha: .12), borderRadius: BorderRadius.circular(20), border: Border.all(color: col.withValues(alpha: .35), width: 1.5)),
      child: Row(children: [
        IconSq('flag', col), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Reklamacja · ${cl.rek ? 'rękojmia' : 'gwarancja'}', style: ts(15, w: w7, c: t.text)),
          Text(txt, style: ts(13, c: t.sub, h: 1.35)),
        ])),
        Ic('chev', size: 16, color: t.sub, width: 2.2),
      ]),
    ));
  }

  // podgląd paragonu: zdjęcie na pełnym ekranie albo paragon odtworzony z danych
  Widget _receiptCard(BuildContext c, Item it, File? img) {
    final t = c.t;
    return Tap(onTap: () => img != null ? Navigator.of(c).push(fadeRoute(PhotoView(img, title: '${it.doc}${it.docNo.isNotEmpty ? ' nr ${it.docNo}' : ''}'))) : showDigitalReceipt(c, it), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), decoration: cardDeco(c, r: 18),
      child: Row(children: [
        ClipRRect(borderRadius: BorderRadius.circular(10), child: img != null
            ? Image.file(img, width: 52, height: 68, fit: BoxFit.cover, cacheWidth: 200, errorBuilder: (_, __, ___) => const SizedBox(width: 52, height: 68))
            : Container(width: 52, height: 68, color: t.panel, child: Center(child: Ic('receipt', size: 26, color: t.sub, width: 1.8)))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Podgląd paragonu', style: ts(16, w: w8, c: t.text)),
          Text('${it.doc}${it.docNo.isNotEmpty ? ' nr ${it.docNo}' : ''} · ${img != null ? 'zdjęcie dokumentu' : 'zapis bez zdjęcia'}', maxLines: 2, style: ts(13, c: t.sub)),
        ])),
        Ic('chev', size: 18, color: t.sub, width: 2.2),
      ]),
    ));
  }

  Widget _info(BuildContext c, String icon, Color bg, String label, String value, {String copy = ''}) {
    final t = c.t;
    return InkWell(
      onLongPress: copy.isEmpty ? null : () { Clipboard.setData(ClipboardData(text: copy)); toast('Skopiowano'); },
      child: Container(padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16), decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.line))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconSq(icon, bg, size: 32), const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: ts(12, c: t.sub)), const SizedBox(height: 1), Text(value, style: ts(15, w: w6, c: t.text, h: 1.35))])),
        ])),
    );
  }

  Widget _act(BuildContext c, String icon, String label, VoidCallback onTap, {Color? color}) {
    final t = c.t;
    return Tap(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: 14), decoration: cardDeco(c),
        child: Column(children: [Ic(icon, size: 22, color: color ?? t.accent), const SizedBox(height: 4), Text(label, style: ts(13, w: w7, c: color ?? t.accent))])));
  }
}

// zdjęcie na pełnym ekranie z powiększaniem
class PhotoView extends StatelessWidget {
  final File f; final String title;
  const PhotoView(this.f, {super.key, required this.title});
  @override
  Widget build(BuildContext c) {
    final mq = MediaQuery.of(c);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light, child: Scaffold(backgroundColor: Colors.black, body: Stack(children: [
      Positioned.fill(child: InteractiveViewer(minScale: 1, maxScale: 6, child: Center(child: Image.file(f, fit: BoxFit.contain)))),
      Positioned(top: mq.padding.top + 12, left: 16, right: 16, child: Row(children: [
        Expanded(child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, w: w7, c: Colors.white))),
        Tap(onTap: () => Navigator.pop(c), child: Container(padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 18), decoration: BoxDecoration(color: const Color(0x38FFFFFF), borderRadius: BorderRadius.circular(99)),
          child: Text('Zamknij', style: ts(15, w: w7, c: Colors.white)))),
      ])),
      Positioned(bottom: mq.padding.bottom + 18, left: 0, right: 0, child: Center(child: Text('Rozsuń palce, aby powiększyć', style: ts(13, c: const Color(0x99FFFFFF))))),
    ])));
  }
}

// paragon odtworzony z danych (gdy brak zdjęcia)
Future<void> showDigitalReceipt(BuildContext c, Item it) => showSheet(c, (ctx) {
      final rows = it.store.isEmpty ? [it] : store.items.where((x) => (x.photo ?? '').isEmpty && x.store == it.store && dayOf(x.date) == dayOf(it.date) && x.docNo == it.docNo).toList();
      final list = rows.isEmpty ? [it] : rows;
      final sum = list.fold<double>(0, (s, x) => s + x.price);
      const ink = Color(0xFF1D1F24);
      Widget dash() => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: LayoutBuilder(builder: (_, cons) => Row(children: List.generate((cons.maxWidth / 8).floor(), (_) => Container(width: 4, height: 1.5, margin: const EdgeInsets.only(right: 4), color: const Color(0x40000000))))));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Podgląd paragonu'),
        const Muted('Brak zdjęcia. Tak wygląda zapis z danych dokumentu.'),
        const SizedBox(height: 14),
        ClipPath(clipper: _Zigzag(), child: Container(color: const Color(0xFFFFFDF7), padding: const EdgeInsets.fromLTRB(20, 26, 20, 26), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text((it.store.isEmpty ? 'Sklep' : it.store).toUpperCase(), textAlign: TextAlign.center, style: ts(16, w: w8, c: ink, ls: .5)),
          Text('${it.doc}${it.docNo.isNotEmpty ? ' nr ${it.docNo}' : ''}', textAlign: TextAlign.center, style: ts(12, c: const Color(0xB31D1F24))),
          Text(fmtD.format(it.date), textAlign: TextAlign.center, style: ts(12, c: const Color(0xB31D1F24))),
          dash(),
          for (final x in list) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Text(x.name, style: ts(14, c: ink))), const SizedBox(width: 10), Text(x.price > 0 ? money(x.price) : '—', style: ts(14, w: w8, c: ink))])),
          dash(),
          Row(children: [Expanded(child: Text('SUMA', style: ts(16, w: w8, c: ink))), Text(sum > 0 ? money(sum) : '—', style: ts(16, w: w8, c: ink))]),
          if (it.buyer.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text('Nabywca: ${it.buyer}', style: ts(12, c: const Color(0xB31D1F24)))),
          dash(),
          Text('Gwarancja do ${fmtD.format(it.end)}', textAlign: TextAlign.center, style: ts(12, c: const Color(0xB31D1F24))),
        ]))),
      ]);
    });
class _Zigzag extends CustomClipper<Path> {
  @override
  Path getClip(Size s) {
    const z = 8.0, w = 16.0; final p = Path()..moveTo(0, z);
    for (double x = 0; x < s.width; x += w) { p.lineTo(x + w / 2, 0); p.lineTo(x + w, z); }
    p.lineTo(s.width, s.height - z);
    for (double x = s.width; x > 0; x -= w) { p.lineTo(x - w / 2, s.height); p.lineTo(x - w, s.height - z); }
    p.close(); return p;
  }
  @override
  bool shouldReclip(CustomClipper<Path> o) => false;
}
