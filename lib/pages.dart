import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'add.dart';
import 'art.dart';
import 'claim.dart';
import 'core.dart';
import 'detail.dart';
import 'services.dart';
import 'ui.dart';

// ============ start: logo, powitanie, blokada ============
class Gate extends StatefulWidget { const Gate({super.key}); @override State<Gate> createState() => _GateState(); }
class _GateState extends State<Gate> with WidgetsBindingObserver {
  int ph = 0; // 0 logo, 1 powitanie, 2 zablokowane, 3 aplikacja
  String? err; DateTime? pausedAt; bool unlocking = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.delayed(const Duration(milliseconds: 1000), () { if (mounted) _next(); });
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  void _next() {
    if (!store.onboarded) { setState(() => ph = 1); return; }
    if (store.lockOn) { setState(() => ph = 2); _unlock(); return; }
    setState(() => ph = 3);
  }
  // po 5 minutach w tle aplikacja blokuje się ponownie
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.paused) pausedAt = DateTime.now();
    if (s == AppLifecycleState.resumed && ph == 3 && store.lockOn && pausedAt != null && DateTime.now().difference(pausedAt!).inMinutes >= 5) {
      setState(() { ph = 2; err = null; }); _unlock();
    }
  }
  Future<void> _unlock() async {
    if (unlocking) return; unlocking = true;
    try {
      if (!await Auth.supported()) { if (mounted) setState(() => ph = 3); return; }
      final e = await Auth.unlock();
      if (!mounted) return;
      if (e == null || e == 'NotAvailable' || e == 'NotEnrolled' || e == 'PasscodeNotSet') { setState(() { ph = 3; err = null; }); return; }
      setState(() => err = e == 'cancel' ? 'Odblokowanie anulowane. Spróbuj jeszcze raz.' : 'Nie udało się odblokować. Spróbuj jeszcze raz.');
    } finally { unlocking = false; }
  }
  @override
  Widget build(BuildContext c) {
    final Widget w;
    if (ph == 3) { w = const Shell(); }
    else if (ph == 1) { w = Onboarding(onDone: () async { await store.setOnboarded(true); if (!mounted) return; if (store.lockOn) { setState(() => ph = 2); _unlock(); } else { setState(() => ph = 3); } }); }
    else { w = _Splash(locked: ph == 2, err: err, onUnlock: _unlock); }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 350), child: KeyedSubtree(key: ValueKey(ph), child: w));
  }
}

class _Splash extends StatelessWidget {
  final bool locked; final String? err; final VoidCallback onUnlock;
  const _Splash({required this.locked, this.err, required this.onUnlock});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Scaffold(backgroundColor: t.bg, body: Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      TweenAnimationBuilder<double>(tween: Tween(begin: .8, end: 1), duration: const Duration(milliseconds: 600), curve: Curves.easeOutBack,
        builder: (_, v, ch) => Transform.scale(scale: v, child: Opacity(opacity: ((v - .8) / .2).clamp(0.0, 1.0), child: ch)),
        child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x33141E3C), blurRadius: 28, offset: Offset(0, 10))]), child: const Logo(size: 88))),
      const SizedBox(height: 18),
      Text('Szuflada', style: ts(30, w: w8, c: t.text, ls: -.6)),
      const SizedBox(height: 2),
      Text(locked ? 'Twoje dokumenty są zablokowane.' : 'Paragony i gwarancje w jednym miejscu.', textAlign: TextAlign.center, style: ts(14, c: t.sub)),
      if (locked) ...[
        const SizedBox(height: 26),
        if (err != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(err!, textAlign: TextAlign.center, style: ts(14, c: cRed))),
        SizedBox(width: 240, child: Cta('Odblokuj', onUnlock, icon: 'lock')),
      ],
    ]))));
  }
}

// ============ ekrany powitalne ============
class _Slide { final String art, h1, h2, p, btn; const _Slide(this.art, this.h1, this.h2, this.p, this.btn); }
class Onboarding extends StatefulWidget {
  final Future<void> Function() onDone; const Onboarding({super.key, required this.onDone});
  @override
  State<Onboarding> createState() => _OnbState();
}
class _OnbState extends State<Onboarding> {
  final pc = PageController(); int i = 0; bool busy = false;
  late final slides = [
    _Slide(artDrawer, 'Wszystkie paragony ', 'w jednej szufladzie', 'Zrób zdjęcie paragonu lub faktury. Szuflada sama odczyta sklep, datę i cenę.', 'Dalej'),
    _Slide(artBell, 'Nie przegap ', 'końca gwarancji', 'Przypomnimy 30 i 7 dni przed końcem gwarancji, o zwrocie zakupów z internetu i o terminach reklamacji.', 'Włącz przypomnienia'),
    _Slide(artClaim, 'Reklamacja ', 'bez stresu', 'Wybierz rękojmię lub gwarancję, opisz usterkę i gotowe. Pismo przygotujemy za Ciebie.', 'Zaczynamy'),
  ];
  Future<void> _go() async {
    if (busy) return;
    if (i == 1) { setState(() => busy = true); await Notifier.request(); if (mounted) setState(() => busy = false); }
    if (i < slides.length - 1) { pc.animateToPage(i + 1, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic); }
    else { await widget.onDone(); }
  }
  @override
  void dispose() { pc.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) {
    final t = c.t; final mq = MediaQuery.of(c); final last = i == slides.length - 1;
    return Scaffold(backgroundColor: t.bg, body: Column(children: [
      Expanded(child: PageView.builder(controller: pc, itemCount: slides.length, onPageChanged: (v) => setState(() => i = v), itemBuilder: (_, k) => Padding(
        padding: EdgeInsets.fromLTRB(18, mq.padding.top + 18, 18, 0),
        child: Container(decoration: BoxDecoration(color: const Color(0xFF171A21), borderRadius: BorderRadius.circular(30)), padding: const EdgeInsets.all(12),
          child: Center(child: SvgPicture.string(slides[k].art, width: (mq.size.width - 60).clamp(0.0, 340.0))))))),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Padding(padding: EdgeInsets.fromLTRB(24, 24, 24, 20 + mq.padding.bottom), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [for (var k = 0; k < slides.length; k++) AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.only(right: 6), width: k == i ? 24 : 8, height: 8, decoration: BoxDecoration(color: k == i ? t.accent : t.line, borderRadius: BorderRadius.circular(99)))]),
        const SizedBox(height: 16),
        Text.rich(TextSpan(style: ts((mq.size.width * .08).clamp(26.0, 34.0), w: w8, c: t.text, ls: -.8, h: 1.15), children: [TextSpan(text: slides[i].h1), TextSpan(text: slides[i].h2, style: TextStyle(color: t.accent))])),
        const SizedBox(height: 10),
        Text(slides[i].p, style: ts(15, c: t.sub, h: 1.5)),
        const SizedBox(height: 22),
        Cta(slides[i].btn, _go, busy: busy),
        const SizedBox(height: 6),
        Center(child: last
            ? LinkBtn('Zobacz na przykładach', () async { if (store.items.isEmpty) await loadDemo(); await widget.onDone(); })
            : LinkBtn('Pomiń', () => pc.animateToPage(slides.length - 1, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic), color: t.sub)),
      ])))),
    ]));
  }
}

// ============ powłoka: zakładki na dole z „+” na środku ============
class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  int tab = 0;
  final scrolls = List.generate(5, (_) => ScrollController());
  @override
  void initState() {
    super.initState();
    openItemN.addListener(_openFromNotif);
    WidgetsBinding.instance.addPostFrameCallback((_) => _openFromNotif());
  }
  @override
  void dispose() { openItemN.removeListener(_openFromNotif); for (final s in scrolls) { s.dispose(); } super.dispose(); }
  void _openFromNotif() {
    final id = openItemN.value; if (id == null || !mounted) return;
    openItemN.value = null;
    final it = store.byId(id);
    if (it != null) Navigator.of(context).push(fadeRoute(DetailPage(it.id)));
  }
  void goTab(int k) {
    HapticFeedback.selectionClick();
    if (k == tab && scrolls[k].hasClients) { scrolls[k].animateTo(0, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic); return; }
    setState(() => tab = k);
  }
  @override
  Widget build(BuildContext c) {
    final t = c.t; final mq = MediaQuery.of(c); final narrow = mq.size.width < 375;
    final tabs = <List<String>?>[['drawer', 'Start'], ['receipt', 'Paragony'], null, ['bell', narrow ? 'Terminy' : 'Przypomnienia'], ['star', 'Plan']];
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (did, _) { if (!did && tab != 0) setState(() => tab = 0); },
      child: Scaffold(
        backgroundColor: t.bg,
        body: ListenableBuilder(listenable: store, builder: (_, __) => IndexedStack(index: tab, children: [
          HomeView(ctrl: scrolls[0], onTab: goTab), DocsView(ctrl: scrolls[1]), const SizedBox(), RemsView(ctrl: scrolls[3]), PlanView(ctrl: scrolls[4]),
        ])),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(color: t.card, border: Border(top: BorderSide(color: t.line))),
          padding: EdgeInsets.fromLTRB(8, 6, 8, 6 + mq.padding.bottom),
          child: Center(heightFactor: 1, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var k = 0; k < 5; k++)
              Expanded(child: tabs[k] == null
                  ? Center(child: Tap(onTap: () => openAdd(c), haptic: true, child: Container(width: 46, height: 46, margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(color: t.accent, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: t.accent.withValues(alpha: .4), blurRadius: 16, offset: const Offset(0, 6))]),
                      child: Center(child: Ic('plus', size: 22, color: t.on, width: 2.6)))))
                  : Tap(onTap: () => goTab(k), child: Padding(padding: const EdgeInsets.only(top: 6, bottom: 4), child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Ic(tabs[k]![0], size: 22, color: tab == k ? t.accent : t.sub, width: tab == k ? 2.2 : 1.8),
                      const SizedBox(height: 3),
                      Text(tabs[k]![1], maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(narrow ? 10.5 : 11, w: w7, c: tab == k ? t.accent : t.sub)),
                    ])))),
          ]))),
        ),
      ),
    );
  }
}

// otwarcie formularza z kontrolą limitu planu Free
Future<void> openAdd(BuildContext c, {bool scan = false}) async {
  if (!store.canAdd) { toast('W planie Free zmieścisz $freeLimit dokumentów.'); await showPaywall(c); return; }
  await openAddSheet(c, autoScan: scan);
}
void openDetail(BuildContext c, Item it) => Navigator.of(c).push(fadeRoute(DetailPage(it.id)));

// ============ strona: kolorowy nagłówek i karta nachodząca od dołu ============
class PageFrame extends StatelessWidget {
  final ScrollController ctrl; final String icon; final List<Widget> head, body;
  const PageFrame({super.key, required this.ctrl, required this.icon, required this.head, required this.body});
  @override
  Widget build(BuildContext c) {
    final t = c.t; final mq = MediaQuery.of(c); final maxW = mq.size.width >= 700 ? 600.0 : 480.0;
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent), child: ColoredBox(color: t.bg, child: ListView(
      controller: ctrl, padding: EdgeInsets.zero, physics: const ClampingScrollPhysics(),
      children: [
        Container(
          decoration: BoxDecoration(gradient: LinearGradient(begin: const Alignment(-.6, -1), end: const Alignment(.6, 1), colors: [t.hd1, t.hd2])),
          child: ClipRect(child: Stack(children: [
            Positioned(right: -34, bottom: -56, child: Opacity(opacity: .1, child: Ic(icon, size: 200, width: 1.4))),
            Padding(padding: EdgeInsets.fromLTRB(18, mq.padding.top + 18, 18, 50), child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: head)))),
          ])),
        ),
        Transform.translate(offset: const Offset(0, -28), child: Container(
          decoration: BoxDecoration(color: t.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          child: Center(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: maxW), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: body))),
        )),
      ],
    )));
  }
}
Widget headTitle(BuildContext c, String title, {bool badge = true}) => Row(children: [
      Expanded(child: Text(title, style: ts(MediaQuery.of(c).size.width < 375 ? 25 : 28, w: w8, c: Colors.white, ls: -.6, h: 1.2))),
      if (badge) PlanBadge(store.pro, onTap: () => showPaywall(c)),
    ]);
Widget headSub(String s) => Padding(padding: const EdgeInsets.only(top: 2), child: Text(s, style: ts(14, w: w6, c: const Color(0xE0FFFFFF))));
Widget secHead(BuildContext c, String title, {String? link, VoidCallback? onLink}) => Padding(padding: const EdgeInsets.fromLTRB(2, 24, 2, 10), child: Row(children: [
      Expanded(child: Text(title, style: ts(18, w: w8, c: c.t.text, ls: -.2))),
      if (link != null && onLink != null) LinkBtn(link, onLink),
    ]));
Widget itemList(BuildContext c, List<Item> items) => Group([for (var k = 0; k < items.length; k++) ItemRow(items[k], onTap: () => openDetail(c, items[k]), last: k == items.length - 1)], margin: EdgeInsets.zero);
Widget emptyBox(String s) => Group([Empty(s)], margin: EdgeInsets.zero);

class StatTile extends StatelessWidget {
  final String value, label; final Color? color; final VoidCallback? onTap;
  const StatTile(this.value, this.label, {super.key, this.color, this.onTap});
  @override
  Widget build(BuildContext c) => Tap(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13), decoration: cardDeco(c, r: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: ts(24, w: w8, c: color ?? c.t.text, ls: -.5, h: 1.1)),
        Text(label, style: ts(13, w: w6, c: c.t.sub)),
      ])));
}

// ============ zakładka: Start ============
class HomeView extends StatelessWidget {
  final ScrollController ctrl; final ValueChanged<int> onTab;
  const HomeView({super.key, required this.ctrl, required this.onTab});
  @override
  Widget build(BuildContext c) {
    final t = c.t; final it = store.items;
    final act = it.where((e) => e.active).toList();
    final soon = act.where((e) => e.left <= 60).toList()..sort((a, b) => a.left.compareTo(b.left));
    final val = act.fold<double>(0, (s, e) => s + e.price);
    final ok = act.length - soon.length, ended = it.length - act.length;
    final claims = it.where((e) => e.claim != null && e.claim!.open).toList();
    final recent = [...it]..sort((a, b) => b.id.compareTo(a.id));
    final narrow = MediaQuery.of(c).size.width < 375;
    if (it.isEmpty) {
      return PageFrame(ctrl: ctrl, icon: 'drawer', head: [headTitle(c, 'Szuflada'), headSub('Paragony i gwarancje w jednym miejscu.')], body: [
        Container(padding: const EdgeInsets.fromLTRB(20, 26, 20, 22), decoration: cardDeco(c), child: Column(children: [
          Container(width: 72, height: 72, decoration: BoxDecoration(color: t.accSoft, borderRadius: BorderRadius.circular(22)), child: Center(child: Ic('receipt', size: 34, color: t.accent, width: 1.8))),
          const SizedBox(height: 14),
          Text('Zacznij od pierwszego paragonu', textAlign: TextAlign.center, style: ts(20, w: w8, c: t.text)),
          const SizedBox(height: 6),
          const Muted('Zrób zdjęcie paragonu lub faktury. Dane uzupełnią się same, a my przypomnimy o końcu gwarancji.', align: TextAlign.center),
        ])),
        const SizedBox(height: 14),
        Cta('Skanuj pierwszy dokument', () => openAdd(c, scan: true), icon: 'scan'),
        const SizedBox(height: 10),
        Ghost('Dodaj ręcznie', () => openAdd(c), icon: 'edit'),
        const SizedBox(height: 6),
        Center(child: LinkBtn('Zobacz na przykładach', () async { await loadDemo(); toast('Dodano przykładowe dokumenty'); })),
      ]);
    }
    Widget legend(Color col, String s) => Row(mainAxisSize: MainAxisSize.min, children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 6), Text(s, style: ts(12, w: w6, c: const Color(0xEBFFFFFF)))]);
    const cOk = Color(0xFF5EE39B), cSoon = Color(0xFFFFB347), cEnd = Color(0x73FFFFFF);
    return PageFrame(ctrl: ctrl, icon: 'drawer', head: [
      headTitle(c, 'Szuflada'),
      const SizedBox(height: 16),
      Text('${act.length}', style: ts(narrow ? 46 : 54, w: w8, c: Colors.white, ls: -2, h: 1)),
      headSub('${pl(act.length, 'produkt', 'produkty', 'produktów')} na gwarancji${val > 0 ? ' o wartości ${money(val)}' : ''}'),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: BorderRadius.circular(99), child: Container(height: 6, color: const Color(0x33FFFFFF), child: Row(children: [
        if (ok > 0) Expanded(flex: ok, child: Container(color: cOk)),
        if (ok > 0 && soon.isNotEmpty) const SizedBox(width: 2),
        if (soon.isNotEmpty) Expanded(flex: soon.length, child: Container(color: cSoon)),
        if (ended > 0 && (ok > 0 || soon.isNotEmpty)) const SizedBox(width: 2),
        if (ended > 0) Expanded(flex: ended, child: Container(color: cEnd)),
      ]))),
      const SizedBox(height: 8),
      Wrap(spacing: 14, runSpacing: 4, children: [legend(cOk, '$ok spokojnie'), legend(cSoon, '${soon.length} wkrótce'), legend(cEnd, '$ended po terminie')]),
    ], body: [
      Row(children: [
        Expanded(child: StatTile('${soon.length}', 'kończy się w 2 mies.', color: soon.isEmpty ? null : cOrange, onTap: () => onTab(3))),
        const SizedBox(width: 10),
        Expanded(child: StatTile('${it.length}', '${pl(it.length, 'dokument', 'dokumenty', 'dokumentów')} w szufladzie', onTap: () => onTab(1))),
      ]),
      if (claims.isNotEmpty) ...[
        secHead(c, 'Reklamacje w toku'),
        Group([for (var k = 0; k < claims.length; k++) ItemRow(claims[k], onTap: () => showClaimStatus(c, claims[k]), last: k == claims.length - 1)], margin: EdgeInsets.zero),
      ],
      secHead(c, 'Kończy się wkrótce', link: soon.length > 4 ? 'Wszystkie' : null, onLink: () => onTab(3)),
      soon.isEmpty ? emptyBox('Nic nie wygasa w ciągu 2 miesięcy.') : itemList(c, soon.take(4).toList()),
      secHead(c, 'Ostatnio dodane', link: 'Wszystkie', onLink: () => onTab(1)),
      itemList(c, recent.take(3).toList()),
    ]);
  }
}

// ============ zakładka: Paragony ============
class DocsView extends StatefulWidget {
  final ScrollController ctrl; const DocsView({super.key, required this.ctrl});
  @override
  State<DocsView> createState() => _DocsState();
}
class _DocsState extends State<DocsView> {
  String cat = 'Wszystkie', q = ''; bool showExpired = false;
  final qc = TextEditingController();
  @override
  void dispose() { qc.dispose(); super.dispose(); }
  List<Item> _sorted(List<Item> l) {
    switch (store.sort) {
      case 'new': l.sort((a, b) => b.date.compareTo(a.date)); break;
      case 'price': l.sort((a, b) => b.price.compareTo(a.price)); break;
      case 'name': l.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase())); break;
      default: l.sort((a, b) => a.end.compareTo(b.end));
    }
    return l;
  }
  void _sortSheet() => showSheet(context, (ctx) {
        final t = ctx.t;
        const opts = [['end', 'Najbliższy koniec gwarancji', 'clock'], ['new', 'Najnowsze zakupy', 'calendar'], ['price', 'Najdroższe', 'coins'], ['name', 'Alfabetycznie', 'sort']];
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const H2('Sortuj'),
          Group([for (var k = 0; k < opts.length; k++) SetRow(icon: opts[k][2], bg: t.accent, title: opts[k][1], last: k == opts.length - 1, chevron: false,
              trailing: store.sort == opts[k][0] ? Ic('check', size: 20, color: t.accent, width: 2.6) : const SizedBox(width: 20),
              onTap: () { store.setSort(opts[k][0]); Navigator.pop(ctx); })], margin: EdgeInsets.zero),
        ]);
      });
  @override
  Widget build(BuildContext c) {
    final t = c.t; final items = store.items;
    final used = ['Wszystkie', ...cats.map((e) => e.name).where((n) => items.any((i) => i.cat == n))];
    final cc = used.contains(cat) ? cat : 'Wszystkie';
    final ql = q.trim().toLowerCase();
    bool match(Item i) => (cc == 'Wszystkie' || i.cat == cc) && (ql.isEmpty || '${i.name} ${i.store} ${i.note} ${i.docNo} ${i.buyer}'.toLowerCase().contains(ql));
    final shown = _sorted(items.where((i) => i.active && match(i)).toList());
    final expired = items.where((i) => !i.active && match(i)).toList()..sort((a, b) => b.end.compareTo(a.end));
    const sl = {'end': 'Najbliższy koniec', 'new': 'Najnowsze', 'price': 'Najdroższe', 'name': 'A–Z'};
    return PageFrame(ctrl: widget.ctrl, icon: 'receipt', head: [
      headTitle(c, 'Paragony'),
      headSub('${items.length} ${pl(items.length, 'dokument', 'dokumenty', 'dokumentów')}${store.pro ? '' : ' z $freeLimit w planie Free'}'),
      const SizedBox(height: 14),
      TextField(
        controller: qc, onChanged: (v) => setState(() => q = v), style: ts(16, c: Colors.white), cursorColor: Colors.white,
        decoration: InputDecoration(
          hintText: 'Szukaj: nazwa, sklep, notatka', hintStyle: ts(16, c: const Color(0xB3FFFFFF)), filled: true, fillColor: const Color(0x2EFFFFFF), isDense: true,
          prefixIcon: const Padding(padding: EdgeInsets.all(13), child: Ic('search', size: 18, color: Color(0xCCFFFFFF))),
          suffixIcon: q.isEmpty ? null : IconButton(onPressed: () { qc.clear(); setState(() => q = ''); FocusScope.of(c).unfocus(); }, icon: const Ic('close', size: 16, width: 2.4)),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
      ),
    ], body: [
      if (used.length > 2) Padding(padding: const EdgeInsets.only(bottom: 14), child: Bleed(Chips(items: used, value: cc, onPick: (v) => setState(() => cat = v),
          icons: {for (final k in cats) k.name: k.icon}, iconColors: {for (final k in cats) k.name: k.color}, pad: const EdgeInsets.symmetric(horizontal: 16)), by: 16)),
      Padding(padding: const EdgeInsets.fromLTRB(2, 0, 2, 10), child: Row(children: [
        Expanded(child: Text('${shown.length} na gwarancji', style: ts(14, w: w6, c: t.sub))),
        Tap(onTap: _sortSheet, child: Row(children: [Ic('sort', size: 16, color: t.sub, width: 2.1), const SizedBox(width: 6), Text(sl[store.sort] ?? '', style: ts(13, w: w7, c: t.sub))])),
      ])),
      shown.isEmpty ? emptyBox(ql.isNotEmpty ? 'Nic nie znaleziono.' : items.isEmpty ? 'Szuflada jest pusta. Dotknij „+”, aby dodać paragon.' : 'Brak dokumentów w tej kategorii.') : itemList(c, shown),
      if (expired.isNotEmpty) ...[
        Tap(onTap: () => setState(() => showExpired = !showExpired), child: Padding(padding: const EdgeInsets.fromLTRB(2, 24, 2, 10), child: Row(children: [
          Expanded(child: Text('Po gwarancji (${expired.length})', style: ts(18, w: w8, c: t.sub))),
          AnimatedRotation(turns: showExpired || ql.isNotEmpty ? .5 : 0, duration: const Duration(milliseconds: 200), child: Ic('chevDown', size: 16, color: t.sub, width: 2.4)),
        ]))),
        if (showExpired || ql.isNotEmpty) itemList(c, expired),
      ],
    ]);
  }
}

// ============ zakładka: Przypomnienia ============
const _remKinds = <int, List<Object>>{
  1: ['Gwarancja: zostało 30 dni', cOrange], 2: ['Gwarancja: zostało 7 dni', cRed], 6: ['Koniec gwarancji', cGray],
  5: ['Rękojmia: zostało 30 dni', cIndigo], 3: ['Ostatni dzień na zwrot', cBlue], 4: ['Sklep musi odpowiedzieć', cGreen],
};
class RemsView extends StatefulWidget {
  final ScrollController ctrl; const RemsView({super.key, required this.ctrl});
  @override
  State<RemsView> createState() => _RemsState();
}
class _RemsState extends State<RemsView> with WidgetsBindingObserver {
  bool? notifOn;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _check(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.resumed) _check(); }
  Future<void> _check() async { final v = await Notifier.enabled(); if (mounted) setState(() => notifOn = v); }
  @override
  Widget build(BuildContext c) {
    final t = c.t; final td = today(); final all = remindersFor(store.items);
    final next = all.isEmpty ? null : all.first;
    final in30 = all.where((r) => daysBetween(td, r.d) <= 30).length;
    final groups = <String, List<Rem>>{};
    for (final r in all) { groups.putIfAbsent(fmtMonth.format(r.d), () => []).add(r); }
    Widget pill(String icon, String s) => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7), decoration: BoxDecoration(color: const Color(0x2EFFFFFF), borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Ic(icon, size: 15, width: 2.2), const SizedBox(width: 6), Text(s, style: ts(13, w: w7, c: Colors.white))]));
    return PageFrame(ctrl: widget.ctrl, icon: 'bell', head: [
      headTitle(c, 'Przypomnienia', badge: false),
      headSub('Powiadomimy Cię o ${store.remindHour}:00, także gdy aplikacja jest zamknięta.'),
      const SizedBox(height: 14),
      Wrap(spacing: 8, runSpacing: 8, children: [
        pill('bell', '$in30 w ciągu 30 dni'),
        if (next != null) pill('clock', daysBetween(td, next.d) == 0 ? 'najbliższe dziś' : 'najbliższe za ${daysTxt(daysBetween(td, next.d))}'),
      ]),
    ], body: [
      Group([
        if (notifOn == false) SetRow(icon: 'alert', bg: cOrange, title: 'Powiadomienia są wyłączone', sub: 'Dotknij, aby je włączyć', onTap: () async {
          final ok = await Notifier.request(); await _check();
          if (!ok && notifOn == false) toast('Włącz powiadomienia dla Szuflady w ustawieniach telefonu');
        }),
        SetRow(icon: 'clock', bg: t.accent, title: 'Godzina przypomnień', sub: '${store.remindHour}:00 · dotknij, aby zmienić', onTap: () => hourSheet(c), last: true),
      ], margin: EdgeInsets.zero),
      if (all.isEmpty) ...[const SizedBox(height: 14), emptyBox('Brak zaplanowanych przypomnień.\nDodaj paragon, a pojawią się tutaj.')],
      for (final g in groups.entries) ...[
        Padding(padding: const EdgeInsets.fromLTRB(4, 22, 4, 8), child: Text(g.key.toUpperCase(), style: ts(12, w: w8, c: t.sub, ls: .7))),
        Group([for (var k = 0; k < g.value.length; k++) _remRow(c, g.value[k], k == g.value.length - 1)], margin: EdgeInsets.zero),
      ],
    ]);
  }
  Widget _remRow(BuildContext c, Rem r, bool last) {
    final t = c.t; final n = daysBetween(today(), r.d); final kd = _remKinds[r.kind]!;
    return InkWell(onTap: () => openDetail(c, r.it), child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: t.line))),
      child: Row(children: [
        CatTile(r.it.cat, size: 38, radius: 12), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15.5, w: w7, c: t.text)),
          Row(children: [Container(width: 8, height: 8, decoration: BoxDecoration(color: kd[1] as Color, shape: BoxShape.circle)), const SizedBox(width: 6),
            Flexible(child: Text(kd[0] as String, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: t.sub)))]),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(n == 0 ? 'dziś' : 'za ${daysTxt(n)}', style: ts(13, w: w8, c: n <= 7 ? cRed : t.text)),
          Text(fmtDM.format(r.d), style: ts(12, w: w6, c: t.sub)),
        ]),
      ]),
    ));
  }
}

void hourSheet(BuildContext c) => showSheet(c, (ctx) {
      final t = ctx.t;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Godzina przypomnień'),
        const Muted('O tej porze przyjdą powiadomienia o końcu gwarancji i terminach.'),
        const SizedBox(height: 16),
        Wrap(spacing: 10, runSpacing: 10, children: [for (final h in [7, 8, 9, 10, 12, 15, 18, 20])
          Tap(onTap: () { store.setHour(h); Navigator.pop(ctx); toast('Przypomnienia o $h:00'); }, child: Container(width: 72, padding: const EdgeInsets.symmetric(vertical: 13),
            decoration: BoxDecoration(color: store.remindHour == h ? t.accent : t.card, borderRadius: BorderRadius.circular(12), boxShadow: store.remindHour == h ? null : t.shadow),
            child: Text('$h:00', textAlign: TextAlign.center, style: ts(15, w: w7, c: store.remindHour == h ? t.on : t.text))))]),
      ]);
    });

// ============ zakładka: Plan (z ustawieniami) ============
class PlanView extends StatefulWidget {
  final ScrollController ctrl;
  const PlanView({super.key, required this.ctrl});
  @override
  State<PlanView> createState() => _PlanState();
}
class _PlanState extends State<PlanView> {
  Future<void> _toggleLock() async {
    final v = !store.lockOn;
    if (v && !await Auth.supported()) { toast('Najpierw ustaw blokadę ekranu w telefonie'); return; }
    final e = await Auth.unlock();
    if (e != null && e != 'NotAvailable') { toast(e == 'cancel' ? 'Anulowano' : 'Nie udało się potwierdzić'); return; }
    await store.setLock(v);
    toast(v ? 'Blokada włączona' : 'Blokada wyłączona');
  }
  @override
  Widget build(BuildContext c) {
    final t = c.t; final m = store.me; final cl = store.items.where((i) => i.claim != null).length;
    final meSub = [m['n'], m['c']].where((e) => e != null && e.isNotEmpty).join(' · ');
    Widget f(String s, {bool soon = false}) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          soon ? Ic('clock', size: 18, color: t.sub, width: 2) : const Ic('check', size: 18, color: cGreen, width: 2.6), const SizedBox(width: 10),
          Expanded(child: Text(s, style: ts(14, c: soon ? t.sub : t.text, h: 1.4)))]));
    Widget yours() => Container(margin: const EdgeInsets.only(left: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: t.accSoft, borderRadius: BorderRadius.circular(99)), child: Text('Twój plan', style: ts(11, w: w8, c: t.accInk)));
    Widget gt(String s) => Padding(padding: const EdgeInsets.fromLTRB(4, 24, 4, 8), child: Text(s.toUpperCase(), style: ts(12, w: w7, c: t.sub, ls: .8)));
    return PageFrame(ctrl: widget.ctrl, icon: 'star', head: [
      headTitle(c, 'Plan'),
      headSub('Płacisz za spokój, nie za reklamy. Szuflada nigdy nie pokazuje reklam.'),
    ], body: [
      Container(padding: const EdgeInsets.all(16), decoration: cardDeco(c), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Text('Free', style: ts(17, w: w8, c: t.text)), Text(' · 0 zł', style: ts(17, w: w7, c: t.sub)), const Spacer(), if (!store.pro) yours()]),
        f('Do $freeLimit dokumentów'), f('Skaner z automatycznym odczytem'), f('Przypomnienia o końcu gwarancji'),
      ])),
      const SizedBox(height: 10),
      Container(padding: const EdgeInsets.all(16), decoration: cardDeco(c).copyWith(border: Border.all(color: t.accent, width: 2)), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [Text('Pro', style: ts(17, w: w8, c: t.text)), Flexible(child: Text(' · ${Billing.price} / rok', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(17, w: w7, c: t.sub))), const Spacer(), if (store.pro) yours()]),
        Padding(padding: const EdgeInsets.only(top: 4), child: Text('Około 2,50 zł miesięcznie. Jeden uratowany paragon zwraca się wielokrotnie.', style: ts(14, c: t.sub, h: 1.4))),
        f('Bez limitu dokumentów'), f('Reklamacje: rękojmia i gwarancja, gotowe pismo PDF'), f('Kopia zapasowa i przeniesienie na nowy telefon'),
        Padding(padding: const EdgeInsets.only(top: 14), child: Text('Wkrótce w Pro', style: ts(14, w: w8, c: t.text))),
        f('Konto rodzinne: wspólna szuflada', soon: true), f('Przegląd przed końcem gwarancji', soon: true), f('Eksport wszystkich dokumentów do PDF', soon: true),
        if (!store.pro) ...[
          const SizedBox(height: 16),
          Cta('Wykup Pro – ${Billing.price} / rok', () => buyPro()),
          const SizedBox(height: 6),
          Center(child: LinkBtn('Przywróć zakupy', () async { toast('Sprawdzam zakupy…'); await Billing.restore(); })),
        ],
      ])),
      gt('Reklamacje'),
      Group([
        SetRow(icon: 'flag', bg: cGreen, title: 'Twoje reklamacje', sub: cl > 0 ? '$cl ${pl(cl, 'reklamacja', 'reklamacje', 'reklamacji')}' : 'Złożysz ją z poziomu produktu', onTap: () => showClaimList(c)),
        SetRow(icon: 'help', bg: cIndigo, title: 'Rękojmia czy gwarancja?', onTap: () => showLawInfo(c)),
        SetRow(icon: 'info', bg: cBlue, title: 'Gdy sklep odmawia lub milczy', onTap: () => showRefusalHelp(c), last: true),
      ], margin: EdgeInsets.zero),
      gt('Wygląd'),
      Group([Padding(padding: const EdgeInsets.all(12), child: Seg<ThemeMode>(values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark], labels: const ['Jak telefon', 'Jasny', 'Ciemny'], value: store.theme, onChanged: store.setTheme))], margin: EdgeInsets.zero),
      gt('Ustawienia'),
      Group([
        SetRow(icon: 'lock', bg: cGray, title: 'Blokada aplikacji', sub: 'Odcisk palca, twarz lub PIN telefonu', onTap: _toggleLock, trailing: Sw(store.lockOn)),
        SetRow(icon: 'clock', bg: cOrange, title: 'Godzina przypomnień', sub: '${store.remindHour}:00', onTap: () => hourSheet(c)),
        SetRow(icon: 'send', bg: cBlue, title: 'Wyślij testowe powiadomienie', onTap: () async { await Notifier.request(); try { await Notifier.test(); toast('Wysłano. Sprawdź pasek powiadomień.'); } catch (_) { toast('Nie udało się wysłać powiadomienia'); } }),
        SetRow(icon: 'user', bg: t.accent, title: 'Moje dane do pism', sub: meSub.isEmpty ? 'Imię, adres, kontakt' : meSub, onTap: () => editMe(c)),
        SetRow(icon: 'scan', bg: cGreen, title: 'Zaznaczaj pozycje z paragonu od', sub: store.threshold == 0 ? 'wszystkie' : money(store.threshold.toDouble()), onTap: () => _thresholdSheet(c), last: true),
      ], margin: EdgeInsets.zero),
      gt('Kopia zapasowa'),
      Group([
        SetRow(icon: 'upload', bg: cBlue, title: 'Zapisz kopię', sub: 'Plik ZIP z dokumentami i zdjęciami', titleRight: store.pro ? null : Padding(padding: const EdgeInsets.only(left: 6), child: Ic('lock', size: 14, color: t.sub, width: 2.2)), onTap: () async {
          if (!store.pro) { showPaywall(c); return; }
          if (store.items.isEmpty) { toast('Szuflada jest pusta'); return; }
          try { await Backup.export(); } catch (_) { toast('Nie udało się zapisać kopii'); }
        }),
        SetRow(icon: 'download', bg: cGreen, title: 'Wczytaj kopię', sub: 'Z pliku zapisanego wcześniej', last: true, onTap: () async {
          final n = await Backup.import();
          toast(n < 0 ? 'Nie udało się wczytać kopii' : n == 0 ? 'Wszystkie dokumenty z kopii już są w szufladzie' : 'Wczytano: $n ${pl(n, 'dokument', 'dokumenty', 'dokumentów')}');
        }),
      ], margin: EdgeInsets.zero),
      gt('Inne'),
      Group([
        SetRow(icon: 'shield', bg: cGray, title: 'Polityka prywatności', sub: 'Dane zostają na Twoim telefonie', onTap: () => showPrivacy(c)),
        SetRow(icon: 'doc', bg: cIndigo, title: 'Informacje prawne', sub: 'Rękojmia, gwarancja i wzory pism', onTap: () => showLegal(c)),
        SetRow(icon: 'mail', bg: cGreen, title: 'Napisz do nas', sub: supportMail, onTap: () => launchUrl(Uri.parse('mailto:$supportMail?subject=Szuflada')).catchError((_) => false)),
        SetRow(icon: 'trash', bg: cRed, title: 'Usuń wszystkie dokumenty', sub: '${store.items.length} na tym telefonie', last: true, onTap: () async {
          if (store.items.isEmpty) return;
          if (await confirmBox(c, 'Usunąć wszystko?', 'Wszystkie dokumenty i zdjęcia zostaną usunięte z telefonu. Tego nie da się cofnąć.', 'Usuń wszystko')) { await store.removeAll(); toast('Szuflada jest pusta'); }
        }),
      ], margin: EdgeInsets.zero),
      if (testerMode) ...[
        gt('Dla testera'),
        Group([
          SetRow(icon: 'tool', bg: const Color(0xFF636A78), title: 'Tryb Pro (test)', sub: 'Bez płatności. Przed publikacją wyłączymy.', onTap: () => store.pro ? store.clearPro() : store.setPro(), trailing: Sw(store.pro)),
          SetRow(icon: 'box', bg: const Color(0xFF636A78), title: 'Dodaj przykładowe dokumenty', onTap: () async { await loadDemo(); toast('Dodano przykłady'); }),
          SetRow(icon: 'spark', bg: const Color(0xFF636A78), title: 'Pokaż ekran powitalny', last: true, onTap: () async { await store.setOnboarded(false); toast('Uruchom aplikację ponownie'); }),
        ], margin: EdgeInsets.zero),
      ],
      const SizedBox(height: 18),
      Center(child: Text('Szuflada $appVersion · Cube Mobile Games', style: ts(12, c: t.sub))),
    ]);
  }
  void _thresholdSheet(BuildContext c) => showSheet(c, (ctx) {
        final t = ctx.t;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const H2('Które pozycje zaznaczać?'),
          const Muted('Po skanie zaznaczymy produkty droższe niż wybrana kwota. Tanie drobiazgi pominiemy.'),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final v in [0, 50, 100, 150, 300, 500])
            Tap(onTap: () { store.setThreshold(v); Navigator.pop(ctx); }, child: Container(width: 96, padding: const EdgeInsets.symmetric(vertical: 13),
              decoration: BoxDecoration(color: store.threshold == v ? t.accent : t.card, borderRadius: BorderRadius.circular(12), boxShadow: store.threshold == v ? null : t.shadow),
              child: Text(v == 0 ? 'wszystkie' : 'od $v zł', textAlign: TextAlign.center, style: ts(14, w: w7, c: store.threshold == v ? t.on : t.text))))]),
        ]);
      });
}

Future<void> buyPro() async {
  if (!Billing.available || Billing.product == null) { toast('Zakupy są chwilowo niedostępne. Sprawdź konto Google Play.'); return; }
  if (!await Billing.buy()) toast('Nie udało się rozpocząć płatności');
}

// ============ reklamacje ============
Future<void> showClaimList(BuildContext c) => showSheet(c, (ctx) {
      final w = store.items.where((i) => i.claim != null).toList()..sort((a, b) => b.claim!.date.compareTo(a.claim!.date));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Twoje reklamacje'),
        if (w.isEmpty) emptyBox('Nie masz jeszcze reklamacji.\nZłożysz ją, otwierając produkt.')
        else Group([for (var k = 0; k < w.length; k++) _claimRow(ctx, w[k], k == w.length - 1, () { Navigator.pop(ctx); showClaimStatus(c, w[k]); })], margin: EdgeInsets.zero),
      ]);
    });
(String, Color, String) claimState(Claim cl) {
  final n = daysBetween(today(), cl.answerBy);
  if (!cl.open) return cl.status == 'ok' ? ('uznana', cGreen, 'zakończona ${fmtD.format(cl.closed ?? cl.date)}') : ('odrzucona', cRed, 'zakończona ${fmtD.format(cl.closed ?? cl.date)}');
  if (cl.rek) return n < 0 ? ('uznana', cGreen, 'sklep nie odpowiedział w 14 dni') : ('czeka', cOrange, 'odpowiedź do ${fmtD.format(cl.answerBy)}');
  return ('u producenta', cBlue, 'zgłoszona ${fmtD.format(cl.date)}');
}
Widget _claimRow(BuildContext c, Item it, bool last, VoidCallback onTap) {
  final t = c.t; final (st, col, sub) = claimState(it.claim!);
  return InkWell(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: t.line))),
    child: Row(children: [
      CatTile(it.cat, size: 40, radius: 12), const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(15.5, w: w7, c: t.text)),
        Text('${it.claim!.rek ? 'Rękojmia' : 'Gwarancja'} · $sub', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: t.sub)),
      ])),
      const SizedBox(width: 8),
      Pill(st, bg: col.withValues(alpha: .14), fg: col),
    ]),
  ));
}

Future<void> showClaimStatus(BuildContext c, Item it) => showSheet(c, (ctx) {
      final t = ctx.t; final cl = it.claim!; final n = daysBetween(today(), cl.answerBy);
      Future<void> close(String st) async {
        cl.status = st; cl.closed = DateTime.now(); await store.save();
        if (ctx.mounted) Navigator.pop(ctx);
        toast(st == 'ok' ? 'Gratulacje! Reklamacja uznana.' : 'Zapisano. Zobacz, co możesz zrobić dalej.');
        if (st == 'no' && c.mounted) showRefusalHelp(c);
      }
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        H2(it.name),
        Container(padding: const EdgeInsets.all(16), decoration: cardDeco(ctx, r: 18), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [IconSq(cl.rek ? 'store' : 'shield', cl.rek ? cGreen : cBlue), const SizedBox(width: 12), Expanded(child: Text(cl.rek ? 'Rękojmia (wobec sklepu)' : 'Gwarancja (wobec producenta)', style: ts(16, w: w7, c: t.text)))]),
          const SizedBox(height: 12),
          Text('Złożona: ${fmtD.format(cl.date)}${cl.seller.isNotEmpty ? ' · ${cl.seller}' : ''}', style: ts(14, c: t.sub)),
          if (cl.desc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('„${cl.desc}”', style: ts(14, c: t.text, h: 1.4))),
          if (cl.open && cl.rek) Padding(padding: const EdgeInsets.only(top: 10), child: Text(n < 0
              ? 'Minęło 14 dni bez odpowiedzi. Zgodnie z prawem sklep uznał Twoją reklamację.'
              : 'Sklep ma czas na odpowiedź do ${fmtD.format(cl.answerBy)} (${daysTxt(n)}). Przypomnimy Ci o tym terminie.', style: ts(14, w: w7, c: n < 0 ? cGreen : t.text, h: 1.45))),
          if (!cl.open) Padding(padding: const EdgeInsets.only(top: 10), child: Text(cl.status == 'ok' ? 'Reklamacja uznana ✓' : 'Reklamacja odrzucona', style: ts(15, w: w8, c: cl.status == 'ok' ? cGreen : cRed))),
        ])),
        const SizedBox(height: 16),
        if (cl.open) ...[
          Text('Jak zakończyła się reklamacja?', style: ts(15, w: w7, c: t.text)), const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Cta('Uznana', () => close('ok'), color: cGreen, fg: Colors.white)),
            const SizedBox(width: 10),
            Expanded(child: Cta('Odrzucona', () => close('no'), color: cRed, fg: Colors.white)),
          ]),
          const SizedBox(height: 10),
        ],
        if (cl.status == 'no') ...[Ghost('Co zrobić, gdy sklep odmawia', () { Navigator.pop(ctx); showRefusalHelp(c); }, icon: 'info'), const SizedBox(height: 10)],
        Ghost('Pokaż pismo ponownie', () { Navigator.pop(ctx); openClaim(c, it, reopen: true); }, icon: 'doc'),
        const SizedBox(height: 6),
        Center(child: LinkBtn('Usuń reklamację', () async {
          if (await confirmBox(ctx, 'Usunąć reklamację?', 'Dokument zakupu zostanie w szufladzie.', 'Usuń')) { it.claim = null; await store.save(); if (ctx.mounted) Navigator.pop(ctx); }
        }, color: cRed)),
      ]);
    });

// dane do pism
Future<void> editMe(BuildContext c) => showSheet(c, (ctx) => const _MeForm());
class _MeForm extends StatefulWidget { const _MeForm(); @override State<_MeForm> createState() => _MeFormState(); }
class _MeFormState extends State<_MeForm> {
  late final n = TextEditingController(text: store.me['n'] ?? ''), a = TextEditingController(text: store.me['a'] ?? ''), k = TextEditingController(text: store.me['c'] ?? '');
  @override
  void dispose() { n.dispose(); a.dispose(); k.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Moje dane do pism'),
        const Muted('Wstawimy je do pisma reklamacyjnego. Zostają tylko na Twoim telefonie.'),
        const SizedBox(height: 16),
        Field('Imię i nazwisko', n, hint: 'np. Jan Kowalski', caps: TextCapitalization.words),
        Field('Adres', a, hint: 'ulica, kod, miasto', maxLines: 2),
        Field('E-mail lub telefon', k, hint: 'do odpowiedzi sprzedawcy', kb: TextInputType.emailAddress, caps: TextCapitalization.none),
        const SizedBox(height: 6),
        Cta('Zapisz', () async { await store.setMe({'n': n.text.trim(), 'a': a.text.trim(), 'c': k.text.trim()}); if (c.mounted) Navigator.pop(c); toast('Zapisano'); }),
      ]);
}

// ============ Pro ============
Future<void> showPaywall(BuildContext c) => showSheet(c, (ctx) {
      final t = ctx.t;
      Widget feat(String s) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(children: [
            Container(width: 22, height: 22, decoration: const BoxDecoration(color: cGreen, shape: BoxShape.circle), child: const Center(child: Ic('check', size: 13, width: 3))),
            const SizedBox(width: 12), Expanded(child: Text(s, style: ts(15, w: w6, c: t.text)))]));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Center(child: Container(margin: const EdgeInsets.only(top: 6), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Color(0x33141E3C), blurRadius: 24, offset: Offset(0, 10))]), child: const Logo(size: 72))),
        const SizedBox(height: 14),
        Text('Szuflada Pro', textAlign: TextAlign.center, style: ts(24, w: w8, c: t.text, ls: -.4)),
        Text('Bez reklam. Płacisz raz w roku.', textAlign: TextAlign.center, style: ts(14, c: t.sub)),
        const SizedBox(height: 18),
        Container(padding: const EdgeInsets.all(14), decoration: cardDeco(ctx, r: 18), child: Column(children: [
          feat('Bez limitu dokumentów'), feat('Reklamacje z gotowym pismem PDF'), feat('Podpowiedzi, jak zgłosić usterkę do serwisu marki'), feat('Kopia zapasowa i przeniesienie na nowy telefon'),
        ])),
        const SizedBox(height: 14),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: t.accent, width: 2)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Rocznie · ${Billing.price}', style: ts(16, w: w8, c: t.text)), Text('około 2,50 zł miesięcznie', style: ts(14, c: t.sub))])),
        const SizedBox(height: 14),
        if (store.pro) Cta('Pro jest aktywne ✓', null, color: cGreen, fg: Colors.white) else Cta('Wykup Pro', () => buyPro()),
        const SizedBox(height: 10),
        Text('Płatność przez Google Play. Subskrypcję anulujesz w każdej chwili.', textAlign: TextAlign.center, style: ts(13, c: t.sub, h: 1.4)),
        Center(child: LinkBtn('Przywróć zakupy', () async { toast('Sprawdzam zakupy…'); await Billing.restore(); })),
      ]);
    });

// ============ informacje ============
Future<void> showLawInfo(BuildContext c) => showSheet(c, (ctx) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      H2('Rękojmia czy gwarancja?'),
      Muted('Masz dwie drogi. Wybierz wygodniejszą.'),
      H3('Rękojmia (wobec sklepu)'),
      P('Twoje prawo z ustawy. Obowiązuje 2 lata od wydania towaru, niezależnie od gwarancji. Reklamację składasz w sklepie.'),
      Li('Sklep ma 14 dni na odpowiedź. Jeśli milczy, reklamacja jest uznana.'),
      Li('Możesz żądać naprawy lub wymiany, a gdy to się nie uda, obniżenia ceny albo zwrotu pieniędzy.'),
      H3('Gwarancja (wobec producenta)'),
      P('Dobrowolna obietnica producenta. Zasady opisuje karta gwarancyjna, naprawą zwykle zajmuje się serwis. Nie odbiera prawa do rękojmi.'),
      H3('Zwrot zakupu z internetu'),
      P('Rzecz kupioną przez internet zwrócisz bez podania przyczyny w ciągu 14 dni od otrzymania.'),
      SizedBox(height: 8),
      Muted('To ogólne informacje, a nie porada prawna.', size: 13),
    ]));

Future<void> showRefusalHelp(BuildContext c) => showSheet(c, (ctx) {
      final t = ctx.t;
      const steps = [
        ['Poproś o odpowiedź na piśmie', 'Sklep powinien uzasadnić odmowę. Zachowaj ją razem z paragonem.'],
        ['Wyślij ponaglenie', 'Podtrzymaj reklamację i powołaj się na art. 43a i nast. ustawy o prawach konsumenta.'],
        ['Zgłoś się do rzecznika konsumentów', 'Miejski lub powiatowy rzecznik konsumentów pomaga bezpłatnie.'],
        ['Rozważ ekspertyzę', 'Opinia rzeczoznawcy pomaga, gdy sklep twierdzi, że usterka powstała z Twojej winy.'],
        ['Polubowne rozwiązanie sporu', 'Inspekcja Handlowa prowadzi mediacje i sądy polubowne.'],
      ];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Gdy sklep odmawia lub milczy'),
        const Muted('Tak możesz postąpić krok po kroku.'),
        const SizedBox(height: 10),
        for (var k = 0; k < steps.length; k++) Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: t.accSoft, shape: BoxShape.circle), child: Center(child: Text('${k + 1}', style: ts(13, w: w8, c: t.accInk)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(steps[k][0], style: ts(15, w: w7, c: t.text)), Text(steps[k][1], style: ts(14, c: t.text, h: 1.5))])),
        ])),
        const SizedBox(height: 8),
        Ghost('Strona UOKiK dla konsumentów', () => launchUrl(Uri.parse('https://prawakonsumenta.uokik.gov.pl'), mode: LaunchMode.externalApplication), icon: 'globe'),
      ]);
    });

const _legal = [
  'Informacje o rękojmi, gwarancji, zwrotach i terminach oraz wzory pism w Szufladzie mają charakter ogólny i edukacyjny. Nie stanowią porady prawnej ani opinii prawnej w Twojej sprawie.',
  'Nie jesteśmy radcami prawnymi ani adwokatami. Dokładamy starań, aby treści były rzetelne, aktualne i pomocne, ale przepisy się zmieniają, a każda sprawa może wyglądać inaczej (np. warunki konkretnej gwarancji, zakup jako firma, a nie konsument).',
  'Przed złożeniem reklamacji zapoznaj się z obowiązującymi przepisami, w szczególności z ustawą z dnia 30 maja 2014 r. o prawach konsumenta i Kodeksem cywilnym, oraz z warunkami karty gwarancyjnej. Treść pisma sprawdź i dostosuj do swojej sytuacji przed wysłaniem.',
  'W razie wątpliwości skorzystaj z bezpłatnej pomocy miejskiego lub powiatowego rzecznika konsumentów albo skonsultuj się z prawnikiem. Twórca aplikacji nie odpowiada za skutki decyzji podjętych wyłącznie na podstawie tych informacji.',
];
Future<void> showLegal(BuildContext c) => showSheet(c, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const H2('Informacje prawne'),
      for (final s in _legal) P(s),
    ]));

Future<void> showPrivacy(BuildContext c) => showSheet(c, (ctx) {
      final t = ctx.t;
      Widget b(String bold, String rest) => Padding(padding: const EdgeInsets.only(left: 4, top: 4, bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: 14, child: Text('•', style: ts(14, c: t.text, h: 1.55))),
            Expanded(child: Text.rich(TextSpan(style: ts(14, c: t.text, h: 1.55), children: [TextSpan(text: bold, style: const TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: rest)]))),
          ]));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Polityka prywatności'),
        Text('Obowiązuje od: [data publikacji]', style: ts(13, c: t.sub)),
        const SizedBox(height: 8),
        Text.rich(TextSpan(style: ts(14, c: t.text, h: 1.6), children: const [TextSpan(text: 'W skrócie. ', style: TextStyle(fontWeight: FontWeight.w800)), TextSpan(text: 'Szuflada działa bez konta i bez naszego serwera. Twoje dokumenty, zdjęcia paragonów i dane do pism zostają na Twoim telefonie. Nie pokazujemy reklam, nie śledzimy Cię i nie sprzedajemy danych.')])),
        const H3('1. Administrator danych'),
        const P('Administratorem jest twórca aplikacji Szuflada, działający pod marką Cube Mobile Games. Pełne dane administratora i adres kontaktowy: [do uzupełnienia].'),
        const H3('2. Jakie dane przetwarzamy'),
        b('Dane dokumentów zakupu', ', które sam wprowadzasz lub skanujesz: nazwa produktu, sklep, data, cena, numer dokumentu, nabywca, notatki i zdjęcia paragonów lub faktur.'),
        b('Dane do pism reklamacyjnych', ': imię i nazwisko, adres i kontakt, jeśli je podasz, oraz opis i zdjęcia usterki.'),
        b('Ustawienia aplikacji', ': motyw, godzina przypomnień, blokada.'),
        b('Status subskrypcji', ' przekazywany przez Google Play. Nie otrzymujemy danych Twojej karty ani konta płatniczego.'),
        const H3('3. Gdzie są przechowywane'),
        const P('Wszystkie powyższe dane są zapisane wyłącznie w pamięci Twojego telefonu. Nie wysyłamy ich na żaden serwer i nie mamy do nich dostępu.'),
        const H3('4. Skaner i odczyt tekstu'),
        const P('Skanowanie dokumentów i odczyt tekstu odbywa się na telefonie za pomocą bibliotek Google ML Kit, bez wysyłania zdjęć do internetu. Usługi Google Play mogą jednorazowo pobrać moduł skanera na telefon.'),
        const H3('5. Uprawnienia'),
        b('Aparat i zdjęcia', ': tylko do zrobienia lub wybrania zdjęcia dokumentu albo usterki.'),
        b('Powiadomienia', ': do przypomnień o końcu gwarancji, zwrotach i terminach reklamacji.'),
        b('Biometria lub PIN telefonu', ': tylko gdy włączysz blokadę. Odcisk palca i twarz obsługuje system, aplikacja ich nie widzi.'),
        const H3('6. Kopie zapasowe i udostępnianie'),
        const P('Plik kopii zapasowej tworzysz sam i sam decydujesz, gdzie go zapiszesz (np. na Dysku Google). Android może też zachować dane aplikacji w automatycznej kopii Twojego konta Google, zgodnie z ustawieniami telefonu. Gdy udostępniasz dokument lub pismo (np. e-mailem), przekazujesz je wybranemu odbiorcy na własne życzenie.'),
        const H3('7. Podmioty trzecie'),
        const P('Korzystamy z Google Play (instalacja, płatności, subskrypcja) oraz bibliotek Google ML Kit działających na telefonie. Zasady przetwarzania danych przez Google opisuje polityka prywatności Google.'),
        const H3('8. Jak długo przechowujemy dane'),
        const P('Dane są na telefonie, dopóki ich nie usuniesz. Możesz usunąć pojedynczy dokument, wszystkie dokumenty (Plan → Usuń wszystkie dokumenty) lub odinstalować aplikację.'),
        const H3('9. Twoje prawa'),
        const P('Zgodnie z RODO masz prawo dostępu do danych, ich sprostowania, usunięcia, ograniczenia przetwarzania i przenoszenia oraz prawo wniesienia skargi do Prezesa Urzędu Ochrony Danych Osobowych. Ponieważ dane są tylko na Twoim telefonie, większość tych praw zrealizujesz sam w aplikacji.'),
        const H3('10. Dzieci'),
        const P('Aplikacja nie jest skierowana do dzieci poniżej 16 lat.'),
        const H3('11. Zmiany polityki'),
        const P('O istotnych zmianach poinformujemy w aplikacji przed ich wejściem w życie.'),
        const H3('12. Zastrzeżenie prawne'),
        for (final s in _legal) P(s),
      ]);
    });
