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
    Future.delayed(const Duration(milliseconds: 1150), () { if (mounted) _next(); });
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
    else { w = _Dark(ph: ph, err: err, onUnlock: _unlock); }
    return AnimatedSwitcher(duration: const Duration(milliseconds: 380), child: KeyedSubtree(key: ValueKey(ph), child: w));
  }
}

class _Dark extends StatelessWidget {
  final int ph; final String? err; final VoidCallback onUnlock;
  const _Dark({required this.ph, this.err, required this.onUnlock});
  @override
  Widget build(BuildContext c) => AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent), child: Scaffold(
        backgroundColor: const Color(0xFF121214),
        body: Stack(children: [
          Positioned(top: -120, right: -100, child: Opacity(opacity: .55, child: Container(width: 320, height: 320, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [Color(0x665A3DF0), Color(0x005A3DF0)]))))),
          Center(child: Padding(padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(tween: Tween(begin: .7, end: 1), duration: const Duration(milliseconds: 700), curve: Curves.easeOutBack,
              builder: (_, v, ch) => Transform.scale(scale: v, child: Opacity(opacity: ((v - .7) / .3).clamp(0.0, 1.0), child: ch)),
              child: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), boxShadow: const [BoxShadow(color: Color(0x805A3DF0), blurRadius: 40, offset: Offset(0, 14))]), child: const Logo(size: 96))),
            const SizedBox(height: 20),
            Text('szuflada', style: ts(36, w: w8, c: const Color(0xFFF4F4F7), ls: -1.4)),
            const SizedBox(height: 4),
            Text(ph == 2 ? 'Twoje dokumenty są zablokowane.' : 'Paragony i gwarancje w jednym miejscu.', textAlign: TextAlign.center, style: ts(15, c: const Color(0xFF9B9CAD))),
            if (ph == 2) ...[
              const SizedBox(height: 28),
              if (err != null) Padding(padding: const EdgeInsets.only(bottom: 14), child: Text(err!, textAlign: TextAlign.center, style: ts(14, c: const Color(0xFFFF8A80)))),
              SizedBox(width: 260, child: Cta('Odblokuj', onUnlock, icon: 'lock', color: const Color(0xFFA99BFF), fg: const Color(0xFF14141A))),
            ],
          ]))),
        ]),
      ));
}

// ============ ekrany powitalne ============
class _Slide { final String art; final List<List<Object>> h; final String p, btn; const _Slide(this.art, this.h, this.p, this.btn); }
class Onboarding extends StatefulWidget {
  final Future<void> Function() onDone; const Onboarding({super.key, required this.onDone});
  @override
  State<Onboarding> createState() => _OnbState();
}
class _OnbState extends State<Onboarding> {
  final pc = PageController(); int i = 0; bool busy = false;
  late final slides = [
    _Slide(artDrawer, [['Wszystkie paragony,'], [['w jednej szufladzie', 1], '.']], 'Zrób zdjęcie paragonu lub faktury. Szuflada sama odczyta sklep, datę i cenę.', 'Zaczynamy'),
    _Slide(artBell, [['Nie przegap'], [['końca gwarancji', 1], '.']], 'Przypomnimy 30 i 7 dni przed końcem gwarancji, o zwrocie zakupów z internetu i o terminach reklamacji.', 'Włącz przypomnienia'),
    _Slide(artClaim, [['Reklamacja'], [['bez stresu', 1], '.']], 'Wybierz rękojmię lub gwarancję, opisz usterkę i gotowe. Pismo w PDF przygotujemy za Ciebie.', 'Otwórz szufladę'),
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
    final mq = MediaQuery.of(c); final last = i == slides.length - 1;
    final size = (mq.size.width * .086).clamp(30.0, 38.0);
    return AnnotatedRegion<SystemUiOverlayStyle>(value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent), child: Scaffold(
      backgroundColor: const Color(0xFF121214),
      body: Stack(children: [
        Column(children: [
          Expanded(child: PageView.builder(controller: pc, itemCount: slides.length, onPageChanged: (v) => setState(() => i = v), itemBuilder: (_, k) {
            final s = slides[k];
            return Padding(padding: EdgeInsets.fromLTRB(26, mq.padding.top + 16, 26, 0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: Center(child: TweenAnimationBuilder<double>(
                key: ValueKey('art$k$i'), tween: Tween<double>(begin: k == i ? 0.0 : 1.0, end: 1.0), duration: const Duration(milliseconds: 650), curve: Curves.easeOutBack,
                builder: (_, v, ch) => Opacity(opacity: v.clamp(0.0, 1.0), child: Transform.translate(offset: Offset(0, 16 * (1 - v)), child: Transform.scale(scale: .86 + .14 * v, child: ch))),
                child: SvgPicture.string(s.art, width: (mq.size.width - 52).clamp(0.0, 380.0))))),
              Headline(s.h, size: size),
              Text(s.p, style: ts(15, c: const Color(0xFF9B9CAD), h: 1.5)),
            ]));
          })),
          Padding(padding: EdgeInsets.fromLTRB(26, 20, 26, 22 + mq.padding.bottom), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [for (var k = 0; k < slides.length; k++) AnimatedContainer(duration: const Duration(milliseconds: 250), margin: const EdgeInsets.only(right: 6), width: k == i ? 26 : 8, height: 8, decoration: BoxDecoration(color: k == i ? const Color(0xFFA99BFF) : const Color(0xFF34343F), borderRadius: BorderRadius.circular(99)))]),
            const SizedBox(height: 18),
            Cta(slides[i].btn, _go, busy: busy, color: const Color(0xFFA99BFF), fg: const Color(0xFF14141A)),
            if (last) ...[
              const SizedBox(height: 10),
              Tap(onTap: () async { await loadDemo(); await widget.onDone(); }, child: Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: const Color(0xFF1C1C20), borderRadius: BorderRadius.circular(99)),
                child: Text('Zobacz na przykładach', textAlign: TextAlign.center, style: ts(15, w: w7, c: const Color(0xFFF4F4F7))))),
            ],
          ])),
        ]),
        if (!last) Positioned(top: mq.padding.top + 10, right: 14, child: Tap(onTap: () => pc.animateToPage(slides.length - 1, duration: const Duration(milliseconds: 420), curve: Curves.easeOutCubic),
          child: Padding(padding: const EdgeInsets.all(8), child: Text('Pomiń', style: ts(14, w: w7, c: const Color(0xFF9B9CAD)))))),
      ]),
    ));
  }
}
// nagłówek z podkreślonym słowem
class Headline extends StatelessWidget {
  final List<List<Object>> lines; final double size; final Color color;
  const Headline(this.lines, {super.key, required this.size, this.color = const Color(0xFFF4F4F7)});
  @override
  Widget build(BuildContext c) {
    final st = ts(size, w: w8, c: color, ls: -1.2, h: 1.12);
    return Padding(padding: const EdgeInsets.only(top: 6, bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final ln in lines) Wrap(crossAxisAlignment: WrapCrossAlignment.end, children: [
        for (final pc in ln)
          if (pc is List) Stack(clipBehavior: Clip.none, children: [Text('${pc[0]}', style: st), Positioned(left: -4, right: -4, bottom: -5, height: 13, child: SvgPicture.string(underlineSvg, fit: BoxFit.fill))])
          else Text('$pc', style: st),
      ]),
    ]));
  }
}

// ============ główna powłoka z pływającym paskiem zakładek ============
class Shell extends StatefulWidget { const Shell({super.key}); @override State<Shell> createState() => _ShellState(); }
class _ShellState extends State<Shell> {
  int tab = 0;
  final scrolls = List.generate(4, (_) => ScrollController());
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
    final t = c.t; final mq = MediaQuery.of(c);
    const tabs = [['drawer', 'Szuflada'], ['bell', 'Terminy'], ['flag', 'Reklamacje'], ['sliders', 'Ustawienia']];
    return PopScope(
      canPop: tab == 0,
      onPopInvokedWithResult: (did, _) { if (!did && tab != 0) setState(() => tab = 0); },
      child: Scaffold(
        backgroundColor: t.bg,
        body: Stack(children: [
          Positioned.fill(child: ListenableBuilder(listenable: store, builder: (_, __) => IndexedStack(index: tab, children: [
            HomeView(ctrl: scrolls[0], onTab: goTab), TermsView(ctrl: scrolls[1]), ClaimsView(ctrl: scrolls[2]), SettingsView(ctrl: scrolls[3]),
          ]))),
          Positioned(left: 0, right: 0, bottom: 14 + mq.padding.bottom, child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [
            Expanded(child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: t.dark ? const Color(0x99000000) : const Color(0x331E1E46), blurRadius: 32, offset: const Offset(0, 12))]),
              child: Row(children: [
                for (var k = 0; k < 4; k++)
                  Expanded(flex: tab == k ? 24 : 10, child: Tap(onTap: () => goTab(k), child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220), curve: Curves.easeOut, height: 46,
                    decoration: BoxDecoration(color: tab == k ? t.text : Colors.transparent, borderRadius: BorderRadius.circular(22)),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Ic(tabs[k][0], size: 21, color: tab == k ? t.bg : t.sub, width: 1.9),
                      if (tab == k) ...[const SizedBox(width: 6), Flexible(child: FittedBox(fit: BoxFit.scaleDown, child: Text(tabs[k][1], maxLines: 1, style: ts(13, w: w7, c: t.bg))))],
                    ]),
                  ))),
              ]),
            )),
            const SizedBox(width: 10),
            Tap(onTap: () => openAdd(c), haptic: true, child: Container(width: 58, height: 58,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [mix(t.accent, Colors.white, .8), t.accent]),
                  boxShadow: [BoxShadow(color: t.accent.withValues(alpha: .45), blurRadius: 20, offset: const Offset(0, 8))]),
              child: Center(child: Ic('plus', size: 28, color: t.on, width: 2.6)))),
          ])))),
          ),
        ]),
      ),
    );
  }
}

// otwarcie formularza z kontrolą limitu planu Start
Future<void> openAdd(BuildContext c, {bool scan = false}) async {
  if (!store.canAdd) { toast('W planie Start zmieścisz $freeLimit dokumentów.'); await showPaywall(c); return; }
  await openAddSheet(c, autoScan: scan);
}
void openDetail(BuildContext c, Item it) => Navigator.of(c).push(fadeRoute(DetailPage(it.id)));

EdgeInsets pagePad(BuildContext c) { final mq = MediaQuery.of(c); return EdgeInsets.fromLTRB(12, mq.padding.top + 16, 12, 130 + mq.padding.bottom); }
Widget pageList(BuildContext c, ScrollController ctrl, List<Widget> children) => Align(alignment: Alignment.topCenter, child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: ListView(controller: ctrl, padding: pagePad(c), physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()), children: children)));

// kafelek statystyki
class StatTile extends StatelessWidget {
  final String title, sub, value; final Color? valueColor; final bool orb; final VoidCallback? onTap;
  const StatTile({super.key, required this.title, required this.sub, required this.value, this.valueColor, this.orb = false, this.onTap});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Expanded(child: Tap(onTap: onTap, child: Container(
      constraints: const BoxConstraints(minHeight: 70), decoration: cardDeco(c),
      child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Stack(children: [
        if (orb) const Positioned(right: -20, bottom: -26, child: Orb(76)),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: ts(13, w: w7, c: t.text)), const SizedBox(height: 2),
            Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(12, c: t.sub)),
          ])),
          Text(value, style: ts(28, w: w8, c: valueColor ?? t.text, ls: -1)),
        ])),
      ])),
    )));
  }
}
// kolorowy pasek alertu
class Banner2 extends StatelessWidget {
  final String icon, title, text; final Color color; final VoidCallback onTap;
  const Banner2({super.key, required this.icon, required this.title, required this.text, required this.color, required this.onTap});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 12), child: Tap(onTap: onTap, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), gradient: LinearGradient(colors: [color, mix(color, const Color(0xFFFF375F), .8)])),
        child: Row(children: [
          Ic(icon, size: 24), const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: ts(15, w: w7, c: Colors.white)), Text(text, maxLines: 2, overflow: TextOverflow.ellipsis, style: ts(13, c: const Color(0xF2FFFFFF), h: 1.35))])),
          Ic('chev', size: 18, width: 2.4),
        ]),
      )));
}

// ============ zakładka: Szuflada ============
class HomeView extends StatefulWidget {
  final ScrollController ctrl; final ValueChanged<int> onTab;
  const HomeView({super.key, required this.ctrl, required this.onTab});
  @override
  State<HomeView> createState() => _HomeState();
}
class _HomeState extends State<HomeView> {
  String cat = 'Wszystkie', q = ''; bool searching = false, showExpired = false;
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
              trailing: store.sort == opts[k][0] ? CheckDot(color: t.accent) : const SizedBox(width: 24),
              onTap: () { store.setSort(opts[k][0]); Navigator.pop(ctx); })], margin: EdgeInsets.zero),
        ]);
      });
  @override
  Widget build(BuildContext c) {
    final t = c.t; final items = store.items;
    final active = items.where((e) => e.active).toList();
    final soon = active.where((e) => e.left <= 60).toList()..sort((a, b) => a.left.compareTo(b.left));
    final value = active.fold<double>(0, (s, e) => s + e.price);
    final usedCats = ['Wszystkie', ...cats.map((e) => e.name).where((n) => items.any((i) => i.cat == n))];
    final cc = usedCats.contains(cat) ? cat : 'Wszystkie';
    final ql = q.trim().toLowerCase();
    bool match(Item i) => (cc == 'Wszystkie' || i.cat == cc) && (ql.isEmpty || '${i.name} ${i.store} ${i.note} ${i.docNo} ${i.buyer}'.toLowerCase().contains(ql));
    final shown = _sorted(items.where((i) => i.active && match(i)).toList());
    final expired = items.where((i) => !i.active && match(i)).toList()..sort((a, b) => b.end.compareTo(a.end));
    // alert: termin odpowiedzi sklepu lub kończąca się gwarancja
    Widget? banner;
    final waiting = items.where((i) => i.claim != null && i.claim!.open && i.claim!.rek).toList()..sort((a, b) => a.claim!.answerBy.compareTo(b.claim!.answerBy));
    final overdue = waiting.where((i) => daysBetween(today(), i.claim!.answerBy) < 0).toList();
    if (overdue.isNotEmpty) {
      final it = overdue.first;
      banner = Banner2(icon: 'flag', color: cGreen, title: 'Sklep nie odpowiedział w 14 dni', text: '${it.name}: to oznacza, że uznał Twoją reklamację. Dotknij, aby zakończyć.', onTap: () => openDetail(c, it));
    } else if (soon.isNotEmpty && soon.first.left <= 30) {
      final it = soon.first;
      banner = Banner2(icon: 'alert', color: cOrange, title: it.left == 0 ? 'Gwarancja kończy się dziś' : 'Gwarancja kończy się za ${daysTxt(it.left)}', text: '${it.name}. Sprawdź, czy wszystko działa.', onTap: () => openDetail(c, it));
    }
    return pageList(c, widget.ctrl, [
      Padding(padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('szuflada', style: ts(36, w: w8, c: t.text, ls: -1.4, h: 1.1)), const SizedBox(width: 10),
          Padding(padding: const EdgeInsets.only(top: 5), child: Tap(onTap: () => showPaywall(c), child: ProBadge(store.pro))),
        ]),
        const SizedBox(height: 4), Muted('Paragony i gwarancje w jednym miejscu.'),
      ])),
      const SizedBox(height: 14),
      Row(children: [
        StatTile(title: 'Na gwarancji', sub: value > 0 ? 'wartość ${money(value)}' : store.pro ? 'bez limitu' : '${items.length} z $freeLimit w planie Start', value: '${active.length}', orb: true, onTap: active.isEmpty ? null : () { setState(() => cat = 'Wszystkie'); }),
        const SizedBox(width: 10),
        StatTile(title: 'Kończy się', sub: 'w ciągu 60 dni', value: '${soon.length}', valueColor: soon.isEmpty ? null : cOrange, onTap: () => widget.onTab(1)),
      ]),
      const SizedBox(height: 12),
      if (banner != null) banner,
      if (items.isEmpty) _empty(c) else Panel(
        title: 'Moje dokumenty',
        right: Row(mainAxisSize: MainAxisSize.min, children: [
          Tap(onTap: () => setState(() { searching = !searching; if (!searching) { q = ''; qc.clear(); } }), child: Padding(padding: const EdgeInsets.all(6), child: Ic(searching ? 'close' : 'search', size: 19, color: t.text))),
          Tap(onTap: _sortSheet, child: Padding(padding: const EdgeInsets.all(6), child: Ic('sort', size: 19, color: t.text))),
          const SizedBox(width: 6), LinkBtn('+ Dodaj', () => openAdd(c)),
        ]),
        children: [
          AnimatedSize(duration: const Duration(milliseconds: 200), child: searching ? Padding(padding: const EdgeInsets.only(bottom: 12), child: TextField(
            controller: qc, autofocus: true, onChanged: (v) => setState(() => q = v), style: ts(16, c: t.text), cursorColor: t.accent,
            decoration: InputDecoration(hintText: 'Szukaj: nazwa, sklep, notatka…', hintStyle: ts(15, c: t.sub), filled: true, fillColor: t.card, isDense: true,
              prefixIcon: Padding(padding: const EdgeInsets.all(12), child: Ic('search', size: 18, color: t.sub)), contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none)),
          )) : const SizedBox(width: double.infinity)),
          if (usedCats.length > 2) Padding(padding: const EdgeInsets.only(bottom: 14), child: Bleed(Chips(items: usedCats, value: cc, onPick: (v) => setState(() => cat = v), icons: {for (final k in cats) k.name: k.icon}))),
          if (shown.isEmpty && expired.isEmpty) Empty(ql.isNotEmpty ? 'Nic nie znaleziono dla „$q”.' : 'Brak dokumentów w tej kategorii.'),
          if (shown.isEmpty && expired.isNotEmpty && ql.isEmpty) const Empty('Wszystkie gwarancje w tej kategorii już minęły.'),
          for (var k = 0; k < shown.length; k++) DocCard(shown[k], onTap: () => openDetail(c, shown[k]), last: k == shown.length - 1 && expired.isEmpty),
          if (expired.isNotEmpty) ...[
            Tap(onTap: () => setState(() => showExpired = !showExpired), child: Padding(padding: EdgeInsets.only(top: shown.isEmpty ? 0 : 14, bottom: 4, left: 2), child: Row(children: [
              Text('Po gwarancji (${expired.length})', style: ts(15, w: w7, c: t.sub)), const SizedBox(width: 6),
              AnimatedRotation(turns: showExpired ? .5 : 0, duration: const Duration(milliseconds: 200), child: Ic('chevDown', size: 16, color: t.sub, width: 2.4)),
            ]))),
            if (showExpired || ql.isNotEmpty) ...[const SizedBox(height: 8), for (var k = 0; k < expired.length; k++) DocCard(expired[k], onTap: () => openDetail(c, expired[k]), last: k == expired.length - 1)],
          ],
        ],
      ),
      if (!store.pro) _proPromo(c),
    ]);
  }
  Widget _empty(BuildContext c) {
    final t = c.t;
    return Panel(title: 'Moje dokumenty', children: [
      Container(height: 190, decoration: BoxDecoration(color: const Color(0xFF121214), borderRadius: BorderRadius.circular(22)), padding: const EdgeInsets.all(8), child: SvgPicture.string(artDrawer)),
      const SizedBox(height: 16),
      Text('Twoja szuflada czeka', textAlign: TextAlign.center, style: ts(20, w: w8, c: t.text)),
      const SizedBox(height: 6),
      const Muted('Zeskanuj pierwszy paragon lub fakturę. Dane uzupełnią się same, a my przypomnimy o końcu gwarancji.', align: TextAlign.center),
      const SizedBox(height: 16),
      Cta('Zeskanuj pierwszy paragon', () => openAdd(c, scan: true), icon: 'scan'),
      const SizedBox(height: 10),
      Ghost('Dodaj ręcznie', () => openAdd(c), icon: 'edit'),
      const SizedBox(height: 4),
      Center(child: LinkBtn('Zobacz na przykładach', () async { await loadDemo(); toast('Dodano przykładowe dokumenty'); })),
    ]);
  }
  Widget _proPromo(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 14), child: Tap(onTap: () => showPaywall(c), child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), gradient: const LinearGradient(begin: Alignment(-1, -.6), end: Alignment(1, .6), colors: [cAmber, cPink])),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('✨ Przejdź na Pro', style: ts(17, w: w7, c: Colors.white)),
            Text('Bez limitu dokumentów, reklamacje z gotowym pismem i kopia zapasowa.', style: ts(13, c: const Color(0xF2FFFFFF), h: 1.35)),
          ])),
          const SizedBox(width: 8), const Ic('chev', size: 18, width: 2.4),
        ]),
      )));
}

// ============ zakładka: Terminy ============
const _remKinds = <int, List<Object>>{
  1: ['Gwarancja: zostało 30 dni', 'clock', cOrange], 2: ['Gwarancja: zostało 7 dni', 'alert', cRed], 6: ['Koniec gwarancji', 'shield', cGray],
  5: ['Rękojmia: zostało 30 dni', 'clock', cIndigo], 3: ['Ostatni dzień na zwrot', 'globe', cBlue], 4: ['Sklep musi odpowiedzieć', 'flag', cGreen],
};
class TermsView extends StatefulWidget {
  final ScrollController ctrl; const TermsView({super.key, required this.ctrl});
  @override
  State<TermsView> createState() => _TermsState();
}
class _TermsState extends State<TermsView> with WidgetsBindingObserver {
  String f = 'Wszystkie'; bool? notifOn;
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _check(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState s) { if (s == AppLifecycleState.resumed) _check(); }
  Future<void> _check() async { final v = await Notifier.enabled(); if (mounted) setState(() => notifOn = v); }
  @override
  Widget build(BuildContext c) {
    final t = c.t; final td = today();
    final all = remindersFor(store.items);
    const map = {'Gwarancje': 'gw', 'Zwroty': 'zwrot', 'Reklamacje': 'rekl'};
    final list = all.where((r) => f == 'Wszystkie' || r.group == map[f]).toList();
    // wykres: końce gwarancji w najbliższych 6 miesiącach
    final months = List.generate(6, (k) => DateTime(td.year, td.month + k, 1));
    final counts = months.map((m) => store.items.where((i) => i.end.year == m.year && i.end.month == m.month && !i.end.isBefore(td)).length).toList();
    final mx = counts.fold<int>(1, (a, b) => b > a ? b : a);
    final total = counts.fold<int>(0, (a, b) => a + b);
    final next = all.isEmpty ? null : all.first;
    final groups = <String, List<Rem>>{};
    for (final r in list) { groups.putIfAbsent(fmtMonth.format(r.d), () => []).add(r); }
    return pageList(c, widget.ctrl, [
      const H1('Terminy'),
      Muted('Przypomnimy o ${store.remindHour}:00, nawet gdy aplikacja jest zamknięta.'),
      const SizedBox(height: 18),
      if (notifOn == false) Banner2(icon: 'bell', color: cOrange, title: 'Powiadomienia są wyłączone', text: 'Bez nich nie przypomnimy o końcu gwarancji. Dotknij, aby włączyć.', onTap: () async {
        final ok = await Notifier.request(); await _check();
        if (!ok && notifOn == false) toast('Włącz powiadomienia dla Szuflady w ustawieniach telefonu');
      }),
      IntrinsicHeight(child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: cardDeco(c, r: 26), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pół roku', style: ts(15, w: w7, c: t.text)),
          const SizedBox(height: 10),
          SizedBox(height: 84, child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (var k = 0; k < 6; k++) Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 3), child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
              Container(width: 14, height: (counts[k] / mx * 60).clamp(8, 60).toDouble(), decoration: BoxDecoration(borderRadius: BorderRadius.circular(99),
                gradient: counts[k] > 0 ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF8A3D), Color(0xFFFF5A1F)]) : null,
                color: counts[k] > 0 ? null : t.text.withValues(alpha: .14))),
              const SizedBox(height: 4), Text(DateFormatShort.month(months[k]), style: ts(10, c: t.sub)),
            ]))),
          ])),
          const SizedBox(height: 6),
          RichText(text: TextSpan(style: ts(14, c: t.sub), children: [TextSpan(text: '$total ', style: ts(14, w: w7, c: t.text)), TextSpan(text: pl(total, 'gwarancja wygasa', 'gwarancje wygasają', 'gwarancji wygasa'))])),
        ]))),
        const SizedBox(width: 12),
        Expanded(child: Tap(onTap: next == null ? null : () => openDetail(c, next.it), child: Container(decoration: cardDeco(c, r: 26), child: ClipRRect(borderRadius: BorderRadius.circular(26), child: Stack(children: [
          const Positioned(right: -34, top: -34, child: Orb(110)),
          Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Najbliższy', style: ts(15, w: w7, c: t.text)),
            if (next != null) ...[
              const SizedBox(height: 10), CatTile(next.it.cat), const Spacer(),
              Text(next.it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(18, w: w8, c: t.text, ls: -.4)),
              Text(daysBetween(td, next.d) == 0 ? 'dziś' : 'za ${daysTxt(daysBetween(td, next.d))}', style: ts(14, c: t.sub)),
            ] else ...[const Spacer(), Muted('Nic w planach')],
          ])),
        ]))))),
      ])),
      const SizedBox(height: 14),
      Panel(title: 'Kalendarz', right: Text('${list.length} ${pl(list.length, 'termin', 'terminy', 'terminów')}', style: ts(14, c: t.sub)), children: [
        Bleed(Chips(items: const ['Wszystkie', 'Gwarancje', 'Zwroty', 'Reklamacje'], value: f, onPick: (v) => setState(() => f = v))),
        const SizedBox(height: 14),
        if (list.isEmpty) Empty(store.items.isEmpty ? 'Dodaj pierwszy dokument,\na terminy pojawią się tutaj.' : 'Brak nadchodzących terminów\nw tej kategorii.'),
        for (final g in groups.entries) ...[
          Padding(padding: EdgeInsets.only(top: g.key == groups.keys.first ? 0 : 16, bottom: 2, left: 2), child: Text(g.key.toUpperCase(), style: ts(12, w: w8, c: t.sub, ls: .6))),
          for (var k = 0; k < g.value.length; k++) _remRow(c, g.value[k], k == g.value.length - 1),
        ],
      ]),
    ]);
  }
  Widget _remRow(BuildContext c, Rem r, bool last) {
    final t = c.t; final n = daysBetween(today(), r.d); final kd = _remKinds[r.kind]!;
    return Tap(onTap: () => openDetail(c, r.it), scale: .99, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: t.text.withValues(alpha: .08)))),
      child: Row(children: [
        CatTile(r.it.cat, size: 40, radius: 12), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(r.it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, w: w7, c: t.text)),
          Text('${kd[0]} · ${fmtDM.format(r.d)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: t.sub)),
        ])),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          IconSq(kd[1] as String, kd[2] as Color, size: 30),
          const SizedBox(height: 3), Text(n == 0 ? 'dziś' : 'za ${n}d', style: ts(11, w: w7, c: n <= 7 ? cRed : t.sub)),
        ]),
      ]),
    ));
  }
}
class DateFormatShort { static const _m = ['sty', 'lut', 'mar', 'kwi', 'maj', 'cze', 'lip', 'sie', 'wrz', 'paź', 'lis', 'gru']; static String month(DateTime d) => _m[d.month - 1]; }

// ============ zakładka: Reklamacje ============
class ClaimsView extends StatelessWidget {
  final ScrollController ctrl; const ClaimsView({super.key, required this.ctrl});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    final withClaim = store.items.where((i) => i.claim != null).toList()..sort((a, b) {
      final ao = a.claim!.open ? 0 : 1, bo = b.claim!.open ? 0 : 1;
      return ao != bo ? ao - bo : b.claim!.date.compareTo(a.claim!.date);
    });
    final open = withClaim.where((i) => i.claim!.open).length;
    final won = withClaim.where((i) => i.claim!.status == 'ok').length;
    return pageList(c, ctrl, [
      const H1('Reklamacje'),
      const Muted('Rękojmia albo gwarancja. Pismo gotowe w minutę.'),
      const SizedBox(height: 18),
      if (!store.pro) ...[
        HeroBox(top: const Text('📨', style: TextStyle(fontSize: 40)), title: 'Reklamacje w Pro', text: 'Podpowiemy, czy wybrać rękojmię, czy gwarancję, i przygotujemy gotowe pismo w PDF.'),
        const SizedBox(height: 16),
        Cta('Odblokuj w Pro', () => showPaywall(c), icon: 'star'),
        const SizedBox(height: 16),
      ] else ...[
        Row(children: [
          StatTile(title: 'W toku', sub: 'czekają na odpowiedź', value: '$open', orb: true),
          const SizedBox(width: 10),
          StatTile(title: 'Uznane', sub: 'zakończone sukcesem', value: '$won', valueColor: won > 0 ? cGreen : null),
        ]),
        const SizedBox(height: 14),
        Panel(title: 'Twoje reklamacje', right: store.items.isEmpty ? null : LinkBtn('+ Nowa', () => pickForClaim(c)), children: [
          if (withClaim.isEmpty) ...[
            const Empty('Nie masz jeszcze reklamacji.\nOby tak zostało!'),
            if (store.items.isNotEmpty) Cta('Złóż reklamację', () => pickForClaim(c), icon: 'flag'),
          ],
          for (var k = 0; k < withClaim.length; k++) _row(c, withClaim[k], k == withClaim.length - 1),
        ]),
      ],
      Group([
        SetRow(icon: 'help', bg: cIndigo, title: 'Rękojmia czy gwarancja?', sub: 'Krótko o Twoich prawach', onTap: () => showLawInfo(c)),
        SetRow(icon: 'info', bg: cBlue, title: 'Gdy sklep odmawia lub milczy', sub: 'Co zrobić krok po kroku', onTap: () => showRefusalHelp(c), last: true),
      ]),
    ]);
  }
  Widget _row(BuildContext c, Item it, bool last) {
    final t = c.t; final cl = it.claim!;
    final n = daysBetween(today(), cl.answerBy);
    final (String st, Color col) = !cl.open ? (cl.status == 'ok' ? ('uznana', cGreen) : ('odrzucona', cRed))
        : cl.rek ? (n < 0 ? ('uznana z mocy prawa', cGreen) : ('czeka · ${daysTxt(n)}', cOrange)) : ('u producenta', cBlue);
    final sub = !cl.open ? 'Zakończona ${fmtD.format(cl.closed ?? cl.date)}'
        : cl.rek ? (n < 0 ? 'Sklep nie odpowiedział w 14 dni' : 'Sklep ma czas do ${fmtD.format(cl.answerBy)}') : 'Zgłoszona ${fmtD.format(cl.date)}';
    return Tap(onTap: () => showClaimStatus(c, it), scale: .99, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: t.text.withValues(alpha: .08)))),
      child: Row(children: [
        CatTile(it.cat, size: 40, radius: 12), const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(16, w: w7, c: t.text)),
          Text('${cl.rek ? 'Rękojmia' : 'Gwarancja'} · $sub', maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: t.sub)),
        ])),
        const SizedBox(width: 8),
        Pill(st, bg: col.withValues(alpha: .14), fg: col),
      ]),
    ));
  }
}

// wybór dokumentu do reklamacji
Future<void> pickForClaim(BuildContext c) async {
  final list = [...store.items]..sort((a, b) => b.date.compareTo(a.date));
  final it = await showSheet<Item>(c, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Czego dotyczy reklamacja?'),
        for (var k = 0; k < list.length; k++) DocCard(list[k], onTap: () => Navigator.pop(ctx, list[k]), last: k == list.length - 1),
      ]));
  if (it != null && c.mounted) await openClaim(c, it);
}

// status reklamacji: zakończenie, ponowne pismo
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
        Container(padding: const EdgeInsets.all(16), decoration: cardDeco(ctx), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [IconSq(cl.rek ? 'store' : 'shield', cl.rek ? cGreen : cBlue), const SizedBox(width: 12), Expanded(child: Text(cl.rek ? 'Rękojmia (wobec sklepu)' : 'Gwarancja (wobec producenta)', style: ts(16, w: w7, c: t.text)))]),
          const SizedBox(height: 12),
          Text('Złożona: ${fmtD.format(cl.date)}${cl.seller.isNotEmpty ? ' · ${cl.seller}' : ''}', style: ts(14, c: t.sub)),
          if (cl.desc.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('„${cl.desc}”', style: ts(14, c: t.text, h: 1.4))),
          if (cl.open && cl.rek) Padding(padding: const EdgeInsets.only(top: 10), child: Text(n < 0
              ? 'Minęło 14 dni bez odpowiedzi. Zgodnie z prawem sklep uznał Twoją reklamację. Powołaj się na to w rozmowie ze sklepem.'
              : 'Sklep ma czas na odpowiedź do ${fmtD.format(cl.answerBy)} (${daysTxt(n)}). Przypomnimy Ci o tym terminie.', style: ts(14, w: w6, c: n < 0 ? cGreen : t.text, h: 1.45))),
          if (!cl.open) Padding(padding: const EdgeInsets.only(top: 10), child: Text(cl.status == 'ok' ? 'Reklamacja uznana ✓' : 'Reklamacja odrzucona', style: ts(15, w: w8, c: cl.status == 'ok' ? cGreen : cRed))),
        ])),
        const SizedBox(height: 16),
        if (cl.open) ...[
          Text('Jak zakończyła się reklamacja?', style: ts(15, w: w7, c: t.text)), const SizedBox(height: 10),
          Row(children: [
            Expanded(child: Cta('Uznana', () => close('ok'), color: cGreen, fg: Colors.white, icon: 'check')),
            const SizedBox(width: 10),
            Expanded(child: Cta('Odrzucona', () => close('no'), color: cRed, fg: Colors.white, icon: 'close')),
          ]),
          const SizedBox(height: 10),
        ],
        if (cl.status == 'no') ...[Ghost('Co zrobić, gdy sklep odmawia', () { Navigator.pop(ctx); showRefusalHelp(c); }, icon: 'info'), const SizedBox(height: 10)],
        Ghost('Pokaż pismo ponownie', () { Navigator.pop(ctx); openClaim(c, it, reopen: true); }, icon: 'doc'),
        const SizedBox(height: 10),
        Ghost('Otwórz dokument zakupu', () { Navigator.pop(ctx); openDetail(c, it); }, icon: 'receipt'),
        const SizedBox(height: 6),
        Center(child: LinkBtn('Usuń reklamację', () async {
          if (await confirmBox(ctx, 'Usunąć reklamację?', 'Dokument zakupu zostanie w szufladzie.', 'Usuń')) { it.claim = null; await store.save(); if (ctx.mounted) Navigator.pop(ctx); }
        }, color: cRed)),
      ]);
    });

// ============ zakładka: Ustawienia ============
class SettingsView extends StatefulWidget {
  final ScrollController ctrl; const SettingsView({super.key, required this.ctrl});
  @override
  State<SettingsView> createState() => _SettingsState();
}
class _SettingsState extends State<SettingsView> {
  bool? notif;
  @override
  void initState() { super.initState(); Notifier.enabled().then((v) { if (mounted) setState(() => notif = v); }); }
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
    final t = c.t; final m = store.me;
    final meSub = [m['n'], m['c']].where((e) => e != null && e.isNotEmpty).join(' · ');
    return pageList(c, widget.ctrl, [
      const H1('Ustawienia'),
      const Sec('Plan'),
      Group([
        SetRow(icon: 'star', bg: cAmber, title: store.pro ? 'Szuflada Pro' : 'Przejdź na Pro', sub: store.pro ? 'Aktywny · bez limitu dokumentów' : '${Billing.price} / rok · bez limitu, reklamacje, kopia', onTap: () => showPaywall(c)),
        SetRow(icon: 'refresh', bg: cBlue, title: 'Przywróć zakupy', onTap: () async { toast('Sprawdzam zakupy…'); await Billing.restore(); }, last: !store.pro),
        if (store.pro) SetRow(icon: 'gear', bg: cGray, title: 'Zarządzaj subskrypcją', sub: 'Google Play', last: true,
          onTap: () => launchUrl(Uri.parse('https://play.google.com/store/account/subscriptions?sku=${Billing.sku}&package=pl.szuflada.szuflada'), mode: LaunchMode.externalApplication)),
      ]),
      const Sec('Wygląd'),
      Group([Padding(padding: const EdgeInsets.all(16), child: Column(children: [
        Row(children: [const IconSq('theme', cIndigo), const SizedBox(width: 14), Text('Motyw', style: ts(16, w: w7, c: t.text))]),
        const SizedBox(height: 12),
        Seg<ThemeMode>(values: const [ThemeMode.system, ThemeMode.light, ThemeMode.dark], labels: const ['Jak telefon', 'Jasny', 'Ciemny'], value: store.theme, onChanged: store.setTheme),
      ]))]),
      const Sec('Przypomnienia'),
      Group([
        SetRow(icon: 'bell', bg: notif == false ? cOrange : cRed, title: 'Powiadomienia', sub: notif == false ? 'Wyłączone · dotknij, aby włączyć' : 'Włączone', onTap: () async {
          final ok = await Notifier.request(); final v = await Notifier.enabled(); if (mounted) setState(() => notif = v);
          if (!ok && !v) toast('Włącz powiadomienia dla Szuflady w ustawieniach telefonu');
        }, trailing: notif == true ? const CheckDot(color: cGreen) : null),
        SetRow(icon: 'clock', bg: cOrange, title: 'Godzina przypomnień', sub: '${store.remindHour}:00', onTap: () => _hourSheet(c)),
        SetRow(icon: 'send', bg: cBlue, title: 'Wyślij testowe powiadomienie', last: true, onTap: () async { await Notifier.request(); try { await Notifier.test(); toast('Wysłano. Sprawdź pasek powiadomień.'); } catch (_) { toast('Nie udało się wysłać powiadomienia'); } }),
      ]),
      const Sec('Bezpieczeństwo'),
      Group([SetRow(icon: 'lock', bg: cGray, title: 'Blokada aplikacji', sub: 'Odcisk palca, twarz lub PIN telefonu', onTap: _toggleLock, trailing: Sw(store.lockOn), last: true)]),
      const Sec('Dokumenty'),
      Group([
        SetRow(icon: 'user', bg: t.accent, title: 'Moje dane do pism', sub: meSub.isEmpty ? 'Imię, adres, kontakt' : meSub, onTap: () => editMe(c)),
        SetRow(icon: 'scan', bg: cGreen, title: 'Skaner: zaznaczaj pozycje od', sub: money(store.threshold.toDouble()), onTap: () => _thresholdSheet(c), last: true),
      ]),
      const Sec('Kopia zapasowa'),
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
      ]),
      const Sec('Pomoc'),
      Group([
        SetRow(icon: 'help', bg: cIndigo, title: 'Rękojmia czy gwarancja?', onTap: () => showLawInfo(c)),
        SetRow(icon: 'mail', bg: cGreen, title: 'Napisz do nas', sub: supportMail, onTap: () => launchUrl(Uri.parse('mailto:$supportMail?subject=Szuflada')).catchError((_) => false)),
        SetRow(icon: 'shield', bg: cGray, title: 'Prywatność', sub: 'Dane zostają na Twoim telefonie', onTap: () => showPrivacy(c), last: true),
      ]),
      const Sec('Dane'),
      Group([SetRow(icon: 'trash', bg: cRed, title: 'Usuń wszystkie dokumenty', sub: '${store.items.length} na tym telefonie', last: true, onTap: () async {
        if (store.items.isEmpty) return;
        if (await confirmBox(c, 'Usunąć wszystko?', 'Wszystkie dokumenty i zdjęcia zostaną usunięte z telefonu. Tego nie da się cofnąć.', 'Usuń wszystko')) { await store.removeAll(); toast('Szuflada jest pusta'); }
      })]),
      if (testerMode) ...[
        const Sec('Dla testera'),
        Group([
          SetRow(icon: 'tool', bg: const Color(0xFF636366), title: 'Tryb Pro (test)', sub: 'Bez płatności. Przed publikacją wyłącz narzędzia testera.', onTap: () => store.pro ? store.clearPro() : store.setPro(), trailing: Sw(store.pro)),
          SetRow(icon: 'box', bg: const Color(0xFF636366), title: 'Dodaj przykładowe dokumenty', onTap: () async { await loadDemo(); toast('Dodano przykłady'); }),
          SetRow(icon: 'spark', bg: const Color(0xFF636366), title: 'Pokaż ekran powitalny', last: true, onTap: () async { await store.setOnboarded(false); toast('Uruchom aplikację ponownie'); }),
        ]),
      ],
      const SizedBox(height: 10),
      Center(child: Text('Szuflada $appVersion · Cube Mobile Games', style: ts(13, c: t.sub))),
    ]);
  }
  void _hourSheet(BuildContext c) => showSheet(c, (ctx) {
        final t = ctx.t;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const H2('Godzina przypomnień'),
          const Muted('O tej porze przyjdą powiadomienia o końcu gwarancji i terminach.'),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final h in [7, 8, 9, 10, 12, 15, 18, 20])
            Tap(onTap: () { store.setHour(h); Navigator.pop(ctx); toast('Przypomnienia o $h:00'); }, child: Container(width: 74, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: store.remindHour == h ? t.accent : t.card, borderRadius: BorderRadius.circular(16), boxShadow: t.softShadow),
              child: Text('$h:00', textAlign: TextAlign.center, style: ts(16, w: w7, c: store.remindHour == h ? t.on : t.text))))]),
        ]);
      });
  void _thresholdSheet(BuildContext c) => showSheet(c, (ctx) {
        final t = ctx.t;
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const H2('Które pozycje zaznaczać?'),
          const Muted('Po skanie paragonu automatycznie zaznaczymy produkty droższe niż wybrana kwota. Tanie drobiazgi pominiemy.'),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [for (final v in [0, 50, 100, 150, 300, 500])
            Tap(onTap: () { store.setThreshold(v); Navigator.pop(ctx); }, child: Container(width: 96, padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(color: store.threshold == v ? t.accent : t.card, borderRadius: BorderRadius.circular(16), boxShadow: t.softShadow),
              child: Text(v == 0 ? 'wszystkie' : 'od $v zł', textAlign: TextAlign.center, style: ts(15, w: w7, c: store.threshold == v ? t.on : t.text))))]),
        ]);
      });
}

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
      Widget feat(String s) => Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [const CheckDot(), const SizedBox(width: 12), Expanded(child: Text(s, style: ts(16, w: w6, c: t.text)))]));
      Widget soon(String s) => Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.sub, width: 1.5)), child: Center(child: Ic('clock', size: 13, color: t.sub, width: 2.2))),
            const SizedBox(width: 12), Expanded(child: Text(s, style: ts(14, c: t.sub, h: 1.4)))]));
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        HeroBox(top: Container(decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), boxShadow: const [BoxShadow(color: Color(0x61000000), blurRadius: 20, offset: Offset(0, 10))]), child: const Logo(size: 84)),
            title: 'Szuflada Pro', text: 'Płacisz za spokój, nie za reklamy. Szuflada nigdy nie pokazuje reklam.'),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4), child: Column(children: [
          feat('Bez limitu dokumentów'), feat('Reklamacje z gotowym pismem PDF'), feat('Podpowiedzi, jak zgłosić usterkę do serwisu marki'), feat('Kopia zapasowa i przeniesienie na nowy telefon'),
        ])),
        Container(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16), decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(22), border: Border.all(color: t.accent, width: 2)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Rocznie · ${Billing.price}', style: ts(16, w: w7, c: t.text)), Text('około 2,50 zł miesięcznie', style: ts(14, c: t.sub))])),
            CheckDot(color: t.accent),
          ])),
        const SizedBox(height: 16),
        if (store.pro) Cta('Pro jest aktywne ✓', null, color: cGreen, fg: Colors.white)
        else Cta('Wykup Pro', () async {
          if (!Billing.available || Billing.product == null) { toast('Zakupy są chwilowo niedostępne. Sprawdź konto Google Play.'); return; }
          if (!await Billing.buy()) toast('Nie udało się rozpocząć płatności');
        }, icon: 'star'),
        const SizedBox(height: 10),
        Text('Płatność przez Google Play. Subskrypcję anulujesz w każdej chwili w Google Play.', textAlign: TextAlign.center, style: ts(13, c: t.sub, h: 1.4)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          LinkBtn('Przywróć zakupy', () async { toast('Sprawdzam zakupy…'); await Billing.restore(); }), const SizedBox(width: 18),
          LinkBtn('Prywatność', () => showPrivacy(ctx)),
        ]),
        const SizedBox(height: 18),
        Text('Wkrótce w Pro', style: ts(16, w: w8, c: t.text)), const SizedBox(height: 6),
        soon('Konto rodzinne: wspólna szuflada dla pary i rodziny'),
        soon('Przegląd przed końcem gwarancji: co sprawdzić w danym sprzęcie'),
        soon('Eksport wszystkich dokumentów do jednego pliku PDF'),
      ]);
    });

// ============ informacje ============
Future<void> showLawInfo(BuildContext c) => showSheet(c, (ctx) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const HeroBox(top: Text('⚖️', style: TextStyle(fontSize: 40)), title: 'Rękojmia czy gwarancja?', text: 'Masz dwie drogi. Możesz wybrać tę, która jest dla Ciebie wygodniejsza.'),
      const H3('Rękojmia (wobec sklepu)'),
      const P('To Twoje prawo z ustawy. Obowiązuje 2 lata od wydania towaru, niezależnie od tego, czy produkt ma gwarancję. Reklamację składasz w sklepie, w którym kupiłeś.'),
      const Li('Sklep ma 14 dni na odpowiedź. Jeśli milczy, reklamacja jest uznana.'),
      const Li('Możesz żądać naprawy lub wymiany, a gdy to się nie uda, obniżenia ceny albo zwrotu pieniędzy.'),
      const Li('To zwykle najprostsza i najmocniejsza droga.'),
      const H3('Gwarancja (wobec producenta)'),
      const P('To dobrowolna obietnica producenta lub sklepu. Jej zasady i czas trwania opisuje karta gwarancyjna. Często naprawą zajmuje się autoryzowany serwis.'),
      const Li('Bywa dłuższa niż 2 lata, np. 3 lub 5 lat.'),
      const Li('Gwarancja nie odbiera Ci prawa do rękojmi.'),
      const H3('Zwrot zakupu z internetu'),
      const P('Rzecz kupioną przez internet możesz zwrócić bez podania przyczyny w ciągu 14 dni od jej otrzymania.'),
      const SizedBox(height: 8),
      Muted('To ogólne informacje, a nie porada prawna. W razie wątpliwości skontaktuj się z miejskim lub powiatowym rzecznikiem konsumentów.', size: 13),
    ]));

Future<void> showRefusalHelp(BuildContext c) => showSheet(c, (ctx) {
      final t = ctx.t;
      final steps = [
        ['Poproś o odpowiedź na piśmie', 'Sklep powinien uzasadnić odmowę. Zachowaj ją razem z paragonem.'],
        ['Wyślij ponaglenie', 'Napisz, że podtrzymujesz reklamację, i powołaj się na rękojmię (art. 43a i nast. ustawy o prawach konsumenta).'],
        ['Zgłoś się do rzecznika konsumentów', 'Miejski lub powiatowy rzecznik konsumentów pomaga bezpłatnie i może interweniować w sklepie.'],
        ['Rozważ ekspertyzę', 'Niezależna opinia rzeczoznawcy wzmacnia Twoje stanowisko, gdy sklep twierdzi, że wada powstała z Twojej winy.'],
        ['Polubowne rozwiązanie sporu', 'Inspekcja Handlowa prowadzi mediacje i stałe sądy polubowne. Informacje znajdziesz na stronie UOKiK.'],
      ];
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const H2('Gdy sklep odmawia lub milczy'),
        const Muted('Nie rezygnuj od razu. Tak możesz postąpić krok po kroku.'),
        const SizedBox(height: 10),
        for (var k = 0; k < steps.length; k++) Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 26, height: 26, decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle), child: Center(child: Text('${k + 1}', style: ts(13, w: w8, c: t.on)))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(steps[k][0], style: ts(15, w: w7, c: t.text)), Text(steps[k][1], style: ts(14, c: t.text, h: 1.5))])),
        ])),
        const SizedBox(height: 8),
        Ghost('Strona UOKiK dla konsumentów', () => launchUrl(Uri.parse('https://prawakonsumenta.uokik.gov.pl'), mode: LaunchMode.externalApplication), icon: 'globe'),
        const SizedBox(height: 10),
        const Muted('To ogólne informacje, a nie porada prawna.', size: 13, align: TextAlign.center),
      ]);
    });

Future<void> showPrivacy(BuildContext c) => showSheet(c, (ctx) => const Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      H2('Prywatność'),
      P('Szuflada przechowuje Twoje dokumenty, zdjęcia i dane do pism wyłącznie na Twoim telefonie. Nie mamy serwera i nie widzimy, co kupujesz.'),
      H3('Skaner'),
      P('Odczyt tekstu z paragonu odbywa się na telefonie (Google ML Kit), bez wysyłania zdjęć do internetu.'),
      H3('Kopia zapasowa'),
      P('Plik kopii tworzysz sam i sam decydujesz, gdzie go zapiszesz, np. na Dysku Google. Android może też automatycznie zachować dane aplikacji w kopii systemowej Twojego konta Google.'),
      H3('Płatności'),
      P('Subskrypcję obsługuje Google Play. Nie otrzymujemy danych Twojej karty.'),
      H3('Kontakt'),
      P('Cube Mobile Games · $supportMail'),
    ]));
