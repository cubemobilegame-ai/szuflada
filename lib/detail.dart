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
              if (hasImg) ...[const SizedBox(height: 12), _photo(c, img, it)],
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
              if (!hasImg) Padding(padding: const EdgeInsets.only(bottom: 12), child: Ghost('Dodaj zdjęcie paragonu', () => openAddSheet(c, edit: it, autoScan: true), icon: 'camera')),
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

  Widget _photo(BuildContext c, File img, Item it) => Tap(onTap: () => Navigator.of(c).push(fadeRoute(PhotoView(img, title: it.name))), child: Container(
        height: 210, decoration: cardDeco(c, r: 24),
        child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(fit: StackFit.expand, children: [
          Image.file(img, fit: BoxFit.cover, cacheWidth: 900, errorBuilder: (_, __, ___) => const SizedBox()),
          Positioned(left: 12, bottom: 12, child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0xB3000000), borderRadius: BorderRadius.circular(99)),
            child: Row(children: [const Ic('eye', size: 15, width: 2.2), const SizedBox(width: 6), Text('Zdjęcie dokumentu', style: ts(12, w: w7, c: Colors.white))]))),
        ])),
      ));

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
