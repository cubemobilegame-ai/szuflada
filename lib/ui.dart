import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'art.dart';
import 'core.dart';

// ---------- kolory (te same co w TapPass) ----------
class T {
  final bool dark; final Color bg, card, panel, text, sub, line, accent, on;
  const T(this.dark, this.bg, this.card, this.panel, this.text, this.sub, this.line, this.accent, this.on);
  static const light = T(false, Color(0xFFF4F5FB), Color(0xFFFFFFFF), Color(0xFFE7EAFB), Color(0xFF14141A), Color(0xFF6F7285), Color(0xFFE8E9F1), Color(0xFF5A3DF0), Color(0xFFFFFFFF));
  static const night = T(true, Color(0xFF121214), Color(0xFF1C1C20), Color(0xFF222238), Color(0xFFF4F4F7), Color(0xFF9B9CAD), Color(0xFF2B2B33), Color(0xFFA99BFF), Color(0xFF14141A));
  List<BoxShadow> get shadow => [BoxShadow(color: dark ? const Color(0x73000000) : const Color(0x1F28285A), blurRadius: 30, offset: const Offset(0, 10))];
  List<BoxShadow> get softShadow => [BoxShadow(color: dark ? const Color(0x59000000) : const Color(0x1428285A), blurRadius: 16, offset: const Offset(0, 4))];
}
const cGreen = Color(0xFF34C759), cRed = Color(0xFFFF3B30), cOrange = Color(0xFFFF9500), cAmber = Color(0xFFFF9F0A), cPink = Color(0xFFFF375F), cBlue = Color(0xFF007AFF), cGray = Color(0xFF8E8E93), cIndigo = Color(0xFF5856D6), cYellow = Color(0xFFFFD166);
extension Ctx on BuildContext {
  T get t => Theme.of(this).brightness == Brightness.dark ? T.night : T.light;
}
Color mix(Color a, Color b, double p) => Color.lerp(b, a, p)!;
String hexOf(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
// kolor statusu wg liczby dni do końca
Color dayColor(int n) => n < 0 ? cGray : n <= 14 ? cRed : n <= 60 ? cOrange : cGreen;

TextStyle ts(double size, {FontWeight w = FontWeight.w400, Color? c, double? h, double ls = 0, TextDecoration? deco}) =>
    TextStyle(fontFamily: 'Jakarta', fontSize: size, fontWeight: w, color: c, height: h, letterSpacing: ls, decoration: deco, decorationColor: c);
const w5 = FontWeight.w500, w6 = FontWeight.w600, w7 = FontWeight.w700, w8 = FontWeight.w800;

// ---------- ikony ----------
class Ic extends StatelessWidget {
  final String name; final double size, width; final Color color;
  const Ic(this.name, {super.key, this.size = 19, this.color = Colors.white, this.width = 2});
  @override
  Widget build(BuildContext c) {
    final hx = hexOf(color);
    final body = (ic[name] ?? ic['box']!).replaceAll('#fff', hx);
    final op = (color.a).toStringAsFixed(2);
    return SvgPicture.string('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="$hx" stroke-opacity="$op" stroke-width="$width" stroke-linecap="round" stroke-linejoin="round">$body</svg>', width: size, height: size);
  }
}
class Logo extends StatelessWidget {
  final double size; const Logo({super.key, this.size = 76});
  @override
  Widget build(BuildContext c) => SvgPicture.string(logoSvg, width: size, height: size);
}

// ---------- drobne elementy ----------
// naciśnięcie: lekkie zmniejszenie, jak w TapPass
class Tap extends StatefulWidget {
  final Widget child; final VoidCallback? onTap; final double scale; final bool haptic;
  const Tap({super.key, required this.child, this.onTap, this.scale = .97, this.haptic = false});
  @override
  State<Tap> createState() => _TapState();
}
class _TapState extends State<Tap> {
  bool down = false;
  @override
  Widget build(BuildContext c) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null ? null : (_) => setState(() => down = true),
        onTapUp: widget.onTap == null ? null : (_) => setState(() => down = false),
        onTapCancel: () => setState(() => down = false),
        onTap: widget.onTap == null ? null : () { if (widget.haptic) HapticFeedback.selectionClick(); widget.onTap!(); },
        child: AnimatedScale(scale: down ? widget.scale : 1, duration: const Duration(milliseconds: 120), curve: Curves.easeOut, child: widget.child),
      );
}

// pomarańczowo-liliowa poświata w kafelkach
class Orb extends StatelessWidget {
  final double size; const Orb(this.size, {super.key});
  @override
  Widget build(BuildContext c) => IgnorePointer(child: Container(width: size, height: size, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(
        center: Alignment(-.1, -.1), radius: .55 * 1.82,
        colors: [Color(0xFFFF6A2B), Color(0xF2FF6A2B), Color(0xB3C9A7FF), Color(0x00C9A7FF)], stops: [0, .36, .64, .9]))));
}

// przełącznik w stylu iOS
class Sw extends StatelessWidget {
  final bool on; final double s;
  const Sw(this.on, {super.key, this.s = 1});
  @override
  Widget build(BuildContext c) => AnimatedContainer(
        duration: const Duration(milliseconds: 180), width: 51 * s, height: 31 * s,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: on ? cGreen : const Color(0x52787880)),
        child: AnimatedAlign(duration: const Duration(milliseconds: 180), curve: Curves.easeOut, alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(margin: EdgeInsets.all(2 * s), width: 27 * s, height: 27 * s, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2))]))),
      );
}

// kwadracik z ikoną kategorii
class CatTile extends StatelessWidget {
  final String cat; final double size, radius; final bool translucent;
  const CatTile(this.cat, {super.key, this.size = 46, this.radius = 13, this.translucent = false});
  @override
  Widget build(BuildContext c) {
    final k = catOf(cat);
    return Container(width: size, height: size, decoration: BoxDecoration(color: translucent ? const Color(0x38FFFFFF) : k.color, borderRadius: BorderRadius.circular(radius)),
        child: Center(child: Ic(k.icon, size: size * .52, width: 2)));
  }
}
class IconSq extends StatelessWidget {
  final String icon; final Color bg; final double size;
  const IconSq(this.icon, this.bg, {super.key, this.size = 34});
  @override
  Widget build(BuildContext c) => Container(width: size, height: size, decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * .32)), child: Center(child: Ic(icon, size: size * .56)));
}

class Pill extends StatelessWidget {
  final String text; final Color bg, fg; final String? icon;
  const Pill(this.text, {super.key, required this.bg, required this.fg, this.icon});
  @override
  Widget build(BuildContext c) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [if (icon != null) ...[Ic(icon!, size: 13, color: fg, width: 2.4), const SizedBox(width: 5)], Text(text, style: ts(12, w: w8, c: fg))]));
}
class ProBadge extends StatelessWidget {
  final bool pro; const ProBadge(this.pro, {super.key});
  @override
  Widget build(BuildContext c) => pro
      ? Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), gradient: const LinearGradient(colors: [cAmber, cPink]), boxShadow: c.t.softShadow),
          child: Text('PRO', style: ts(11, w: w8, c: Colors.white, ls: .5)))
      : Container(padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5), decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: c.t.card, boxShadow: c.t.softShadow),
          child: Text('START', style: ts(11, w: w8, c: c.t.text, ls: .5)));
}

// ---------- tekst ----------
class H1 extends StatelessWidget {
  final String text; const H1(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(top: 10, bottom: 4), child: Text(text, style: ts(34, w: w8, c: c.t.text, ls: -.8, h: 1.2)));
}
class H2 extends StatelessWidget {
  final String text; final double right; const H2(this.text, {super.key, this.right = 44});
  @override
  Widget build(BuildContext c) => Padding(padding: EdgeInsets.only(bottom: 14, right: right), child: Text(text, style: ts(26, w: w8, c: c.t.text, ls: -.6, h: 1.23)));
}
class H3 extends StatelessWidget {
  final String text; const H3(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(top: 20, bottom: 6), child: Text(text, style: ts(16, w: w8, c: c.t.text)));
}
class P extends StatelessWidget {
  final String text; final Color? color; final double size;
  const P(this.text, {super.key, this.color, this.size = 14});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: ts(size, c: color ?? c.t.text, h: 1.6)));
}
class Muted extends StatelessWidget {
  final String text; final TextAlign align; final double size;
  const Muted(this.text, {super.key, this.align = TextAlign.start, this.size = 14});
  @override
  Widget build(BuildContext c) => Text(text, textAlign: align, style: ts(size, c: c.t.sub, h: 1.4));
}
class Li extends StatelessWidget {
  final String text; const Li(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 14, child: Text('•', style: ts(14, c: c.t.text, h: 1.55))), Expanded(child: Text(text, style: ts(14, c: c.t.text, h: 1.55)))]));
}
class Sec extends StatelessWidget {
  final String text; const Sec(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.fromLTRB(16, 26, 16, 0), child: Text(text.toUpperCase(), style: ts(12, w: w7, c: c.t.sub, ls: .8)));
}
class Empty extends StatelessWidget {
  final String text; const Empty(this.text, {super.key});
  @override
  Widget build(BuildContext c) => Padding(padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 10), child: Text(text, textAlign: TextAlign.center, style: ts(16, c: c.t.sub, h: 1.5)));
}

// ---------- kontenery ----------
BoxDecoration cardDeco(BuildContext c, {double r = 20}) => BoxDecoration(color: c.t.card, borderRadius: BorderRadius.circular(r), boxShadow: c.t.shadow);

class Panel extends StatelessWidget {
  final String title; final Widget? right; final List<Widget> children;
  const Panel({super.key, required this.title, this.right, required this.children});
  @override
  Widget build(BuildContext c) => Container(
        margin: const EdgeInsets.only(bottom: 14), padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: c.t.panel, borderRadius: BorderRadius.circular(30)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(padding: const EdgeInsets.only(bottom: 12, left: 2), child: Row(children: [Expanded(child: Text(title, style: ts(18, w: w8, c: c.t.text))), if (right != null) right!])),
          ...children,
        ]));
}
class LinkBtn extends StatelessWidget {
  final String text; final VoidCallback onTap; final Color? color;
  const LinkBtn(this.text, this.onTap, {super.key, this.color});
  @override
  Widget build(BuildContext c) => Tap(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2), child: Text(text, style: ts(14, w: w7, c: color ?? c.t.accent))));
}

class Group extends StatelessWidget {
  final List<Widget> children; final EdgeInsets margin;
  const Group(this.children, {super.key, this.margin = const EdgeInsets.symmetric(vertical: 12)});
  @override
  Widget build(BuildContext c) => Container(margin: margin, decoration: cardDeco(c, r: 24),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Material(type: MaterialType.transparency, child: Column(children: children))));
}
class SetRow extends StatelessWidget {
  final String? icon; final Color? bg; final String title; final String? sub; final VoidCallback? onTap; final Widget? trailing; final bool last, chevron; final Widget? titleRight; final Color? titleColor;
  const SetRow({super.key, this.icon, this.bg, required this.title, this.sub, this.onTap, this.trailing, this.last = false, this.chevron = true, this.titleRight, this.titleColor});
  @override
  Widget build(BuildContext c) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(border: last ? null : Border(bottom: BorderSide(color: c.t.line))),
          child: Row(children: [
            if (icon != null) ...[IconSq(icon!, bg ?? cGray), const SizedBox(width: 14)],
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Flexible(child: Text(title, style: ts(16, w: w7, c: titleColor ?? c.t.text))), if (titleRight != null) titleRight!]),
              if (sub != null && sub!.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, style: ts(13, c: c.t.sub, h: 1.35))),
            ])),
            const SizedBox(width: 8),
            trailing ?? (chevron && onTap != null ? Ic('chev', size: 16, color: c.t.sub, width: 2.2) : const SizedBox()),
          ]),
        ),
      );
}

// filtry w formie kapsułek
class Chips extends StatelessWidget {
  final List<String> items; final String value; final ValueChanged<String> onPick; final Map<String, String>? icons; final EdgeInsets pad;
  const Chips({super.key, required this.items, required this.value, required this.onPick, this.icons, this.pad = const EdgeInsets.symmetric(horizontal: 14)});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return SizedBox(height: 38, child: ListView(scrollDirection: Axis.horizontal, padding: pad, children: [
      for (final k in items)
        Padding(padding: const EdgeInsets.only(right: 8), child: Tap(onTap: () { HapticFeedback.selectionClick(); onPick(k); }, child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(99), color: value == k ? t.text : Colors.transparent, border: Border.all(color: value == k ? t.text : t.text.withValues(alpha: .75), width: 1.5)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            if (icons != null && icons![k] != null) ...[Ic(icons![k]!, size: 15, color: value == k ? t.bg : t.text, width: 2.1), const SizedBox(width: 6)],
            Text(k, style: ts(14, w: w6, c: value == k ? t.bg : t.text)),
          ]),
        ))),
    ]));
  }
}

// rozciąga zawartość na pełną szerokość panelu (poza jego wewnętrzny margines 14)
class Bleed extends StatelessWidget {
  final Widget child; final double by; final double height;
  const Bleed(this.child, {super.key, this.by = 14, this.height = 38});
  @override
  Widget build(BuildContext c) => SizedBox(height: height, child: LayoutBuilder(builder: (_, cons) => OverflowBox(minWidth: cons.maxWidth + by * 2, maxWidth: cons.maxWidth + by * 2, child: child)));
}

// przełącznik segmentowy (np. Paragon / Faktura)
class Seg<V> extends StatelessWidget {
  final List<V> values; final List<String> labels; final V value; final ValueChanged<V> onChanged;
  const Seg({super.key, required this.values, required this.labels, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        for (var i = 0; i < values.length; i++)
          Expanded(child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () { HapticFeedback.selectionClick(); onChanged(values[i]); }, child: AnimatedContainer(
            duration: const Duration(milliseconds: 160), padding: const EdgeInsets.symmetric(vertical: 9),
            decoration: BoxDecoration(color: values[i] == value ? t.card : Colors.transparent, borderRadius: BorderRadius.circular(11),
                boxShadow: values[i] == value ? const [BoxShadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1))] : null),
            child: Text(labels[i], textAlign: TextAlign.center, style: ts(14, w: values[i] == value ? w7 : w5, c: t.text)),
          ))),
      ]));
  }
}

// główny przycisk (kapsuła w kolorze akcentu)
class Cta extends StatelessWidget {
  final String text; final VoidCallback? onTap; final Color? color, fg; final String? icon; final bool busy;
  const Cta(this.text, this.onTap, {super.key, this.color, this.fg, this.icon, this.busy = false});
  @override
  Widget build(BuildContext c) {
    final t = c.t; final on = onTap != null && !busy;
    final f = fg ?? t.on;
    return Tap(onTap: on ? onTap : null, haptic: true, child: AnimatedOpacity(duration: const Duration(milliseconds: 150), opacity: onTap == null ? .4 : 1, child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 17, horizontal: 16),
      decoration: BoxDecoration(color: color ?? t.accent, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (busy) ...[SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.4, color: f)), const SizedBox(width: 10)]
        else if (icon != null) ...[Ic(icon!, size: 20, color: f, width: 2.3), const SizedBox(width: 8)],
        Flexible(child: Text(text, textAlign: TextAlign.center, style: ts(17, w: w8, c: f))),
      ]),
    )));
  }
}
// przycisk drugoplanowy
class Ghost extends StatelessWidget {
  final String text; final VoidCallback? onTap; final String? icon; final Color? fg;
  const Ghost(this.text, this.onTap, {super.key, this.icon, this.fg});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Tap(onTap: onTap, child: Container(
      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 14),
      decoration: BoxDecoration(color: t.card, borderRadius: BorderRadius.circular(99), boxShadow: t.softShadow),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        if (icon != null) ...[Ic(icon!, size: 18, color: fg ?? t.text, width: 2.1), const SizedBox(width: 8)],
        Flexible(child: Text(text, textAlign: TextAlign.center, style: ts(15, w: w7, c: fg ?? t.text))),
      ]),
    ));
  }
}
// duży kafelek akcji (np. „Skanuj aparatem”)
class ActionTile extends StatelessWidget {
  final String icon, label; final VoidCallback? onTap; final String? sub;
  const ActionTile(this.icon, this.label, this.onTap, {super.key, this.sub});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Tap(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8), decoration: cardDeco(c, r: 20),
      child: Column(children: [
        Ic(icon, size: 26, color: t.accent, width: 1.9), const SizedBox(height: 6),
        Text(label, textAlign: TextAlign.center, style: ts(13, w: w7, c: t.accent)),
        if (sub != null) Padding(padding: const EdgeInsets.only(top: 2), child: Text(sub!, textAlign: TextAlign.center, style: ts(11, c: t.sub))),
      ]),
    ));
  }
}

// nagłówek z gradientem i kręgami (Pro, informacje)
class HeroBox extends StatelessWidget {
  final Widget top; final String title, text;
  const HeroBox({super.key, required this.top, required this.title, required this.text});
  @override
  Widget build(BuildContext c) => ClipRRect(borderRadius: BorderRadius.circular(30), child: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment(-.34, -1), end: Alignment(.34, 1), colors: [Color(0xFF2B1B86), Color(0xFF5A3DF0), Color(0xFF2F95FF)], stops: [0, .55, 1])),
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(child: Center(child: OverflowBox(maxWidth: 320, maxHeight: 320, child: Container(width: 320, height: 320, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x33FFFFFF), width: 1.5)))))),
          Positioned.fill(child: Center(child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: const Color(0x45FFFFFF), width: 1.5))))),
          Padding(padding: const EdgeInsets.fromLTRB(20, 26, 20, 22), child: Column(children: [
            top, const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: ts(30, w: w8, c: Colors.white, ls: -.6, h: 1.2)), const SizedBox(height: 6),
            Text(text, textAlign: TextAlign.center, style: ts(16, c: const Color(0xEBFFFFFF), h: 1.4)),
          ])),
        ]),
      ));
}

class CheckDot extends StatelessWidget {
  final Color? color; const CheckDot({super.key, this.color});
  @override
  Widget build(BuildContext c) => Container(width: 24, height: 24, decoration: BoxDecoration(color: color ?? c.t.accent, shape: BoxShape.circle), child: Center(child: Ic('check', size: 14, color: c.t.on, width: 3)));
}

// pole formularza z etykietą (styl TapPass)
class Field extends StatelessWidget {
  final String label; final TextEditingController ctrl; final String? hint; final TextInputType? kb; final int maxLines; final bool warn; final ValueChanged<String>? onChanged;
  final Widget? suffix; final TextCapitalization caps; final FocusNode? focus; final TextInputAction? action; final ValueChanged<String>? onSubmit; final List<TextInputFormatter>? fmt;
  const Field(this.label, this.ctrl, {super.key, this.hint, this.kb, this.maxLines = 1, this.warn = false, this.onChanged, this.suffix, this.caps = TextCapitalization.sentences, this.focus, this.action, this.onSubmit, this.fmt});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: warn ? cOrange : t.line, width: 1.5));
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (label.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 6, left: 2), child: Row(children: [
        Text(label, style: ts(13, c: t.sub)),
        if (warn) ...[const SizedBox(width: 6), Text('· sprawdź', style: ts(13, w: w7, c: cOrange))],
      ])),
      TextField(
        controller: ctrl, focusNode: focus, keyboardType: kb, maxLines: maxLines, minLines: 1, onChanged: onChanged, textCapitalization: caps, textInputAction: action, onSubmitted: onSubmit, inputFormatters: fmt,
        style: ts(16, c: t.text), cursorColor: t.accent,
        decoration: InputDecoration(
          hintText: hint, hintStyle: ts(16, c: t.sub), filled: true, fillColor: warn ? cOrange.withValues(alpha: .08) : t.card, isDense: true, suffixIcon: suffix,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          border: border, enabledBorder: border, focusedBorder: border.copyWith(borderSide: BorderSide(color: t.accent, width: 2)),
        ),
      ),
    ]));
  }
}
// wiersz-przycisk wyglądający jak pole (data, wybór)
class FieldBtn extends StatelessWidget {
  final String label, value; final VoidCallback onTap; final String icon; final bool warn;
  const FieldBtn(this.label, this.value, this.onTap, {super.key, this.icon = 'calendar', this.warn = false});
  @override
  Widget build(BuildContext c) {
    final t = c.t;
    return Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.only(bottom: 6, left: 2), child: Row(children: [Text(label, style: ts(13, c: t.sub)), if (warn) ...[const SizedBox(width: 6), Text('· sprawdź', style: ts(13, w: w7, c: cOrange))]])),
      Tap(onTap: onTap, scale: .99, child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(color: warn ? cOrange.withValues(alpha: .08) : t.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: warn ? cOrange : t.line, width: 1.5)),
        child: Row(children: [Expanded(child: Text(value, style: ts(16, c: t.text))), Ic(icon, size: 19, color: t.sub)]),
      )),
    ]));
  }
}

// ---------- komunikaty ----------
final toastN = ValueNotifier<String?>(null);
int _toastId = 0;
void toast(String m) {
  final id = ++_toastId; toastN.value = m;
  Future.delayed(const Duration(milliseconds: 2600), () { if (_toastId == id) toastN.value = null; });
}
class ToastHost extends StatelessWidget {
  final Widget child; const ToastHost({super.key, required this.child});
  @override
  Widget build(BuildContext c) => Stack(fit: StackFit.expand, children: [
        child,
        Positioned(left: 24, right: 24, bottom: 104 + MediaQuery.of(c).padding.bottom, child: IgnorePointer(child: ValueListenableBuilder<String?>(valueListenable: toastN, builder: (_, m, __) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (w, a) => FadeTransition(opacity: a, child: SlideTransition(position: Tween(begin: const Offset(0, .3), end: Offset.zero).animate(a), child: w)),
          child: m == null ? const SizedBox(key: ValueKey('none')) : Center(key: ValueKey(m), child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11), decoration: BoxDecoration(color: const Color(0xF01E1E20), borderRadius: BorderRadius.circular(99)),
            child: Text(m, textAlign: TextAlign.center, style: ts(14, c: Colors.white, w: w5)))),
        )))),
      ]);
}

Future<bool> confirmBox(BuildContext c, String title, String text, String ok, {bool danger = true}) async {
  final r = await showGeneralDialog<bool>(
    context: c, barrierDismissible: true, barrierLabel: 'zamknij', barrierColor: const Color(0x70000000), transitionDuration: const Duration(milliseconds: 200),
    transitionBuilder: (_, a, __, w) => FadeTransition(opacity: a, child: ScaleTransition(scale: Tween(begin: .94, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: w)),
    pageBuilder: (ctx, _, __) {
      final t = ctx.t;
      return Center(child: Padding(padding: const EdgeInsets.all(24), child: Material(type: MaterialType.transparency, child: Container(
        constraints: const BoxConstraints(maxWidth: 340), padding: const EdgeInsets.all(22), decoration: cardDeco(ctx, r: 28),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: ts(20, w: w8, c: t.text)), const SizedBox(height: 6), Text(text, style: ts(14, c: t.sub, h: 1.45)), const SizedBox(height: 18),
          Row(children: [
            Expanded(child: Tap(onTap: () => Navigator.pop(ctx, false), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: t.bg, borderRadius: BorderRadius.circular(99)), child: Text('Anuluj', textAlign: TextAlign.center, style: ts(16, w: w7, c: t.text))))),
            const SizedBox(width: 10),
            Expanded(child: Tap(onTap: () => Navigator.pop(ctx, true), child: Container(padding: const EdgeInsets.all(13), decoration: BoxDecoration(color: danger ? cRed : t.accent, borderRadius: BorderRadius.circular(99)), child: Text(ok, textAlign: TextAlign.center, style: ts(16, w: w7, c: danger ? Colors.white : t.on))))),
          ]),
        ]),
      ))));
    },
  );
  return r ?? false;
}

// arkusz od dołu (zaokrąglony, z przyciskiem zamknięcia)
Future<R?> showSheet<R>(BuildContext c, Widget Function(BuildContext) builder, {bool scroll = true}) => showModalBottomSheet<R>(
      context: c, isScrollControlled: true, useSafeArea: true, backgroundColor: Colors.transparent, barrierColor: const Color(0x70000000),
      builder: (ctx) => SheetFrame(scroll: scroll, child: Builder(builder: builder)),
    );
class SheetFrame extends StatelessWidget {
  final Widget child; final bool scroll;
  const SheetFrame({super.key, required this.child, this.scroll = true});
  @override
  Widget build(BuildContext c) {
    final t = c.t; final mq = MediaQuery.of(c);
    return Padding(padding: EdgeInsets.only(bottom: mq.viewInsets.bottom), child: Align(alignment: Alignment.bottomCenter, child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 520, maxHeight: mq.size.height * .92),
      child: Container(
        decoration: BoxDecoration(color: t.bg, borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
        child: ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(32)), child: Stack(children: [
          scroll
              ? SingleChildScrollView(padding: EdgeInsets.fromLTRB(18, 22, 18, 26 + mq.padding.bottom), child: child)
              : Padding(padding: EdgeInsets.fromLTRB(18, 22, 18, 26 + mq.padding.bottom), child: child),
          Positioned(top: 8, left: 0, right: 0, child: Center(child: Container(width: 38, height: 5, decoration: BoxDecoration(color: t.line, borderRadius: BorderRadius.circular(99))))),
          Positioned(top: 16, right: 16, child: CloseX(onTap: () => Navigator.maybePop(c))),
        ])),
      ),
    )));
  }
}
class CloseX extends StatelessWidget {
  final VoidCallback onTap; const CloseX({super.key, required this.onTap});
  @override
  Widget build(BuildContext c) => Tap(onTap: onTap, child: Container(width: 34, height: 34, decoration: BoxDecoration(color: c.t.card, shape: BoxShape.circle, boxShadow: c.t.softShadow), child: Center(child: Ic('close', size: 15, color: c.t.sub, width: 2.4))));
}

// ---------- karta dokumentu (jak karta lojalnościowa w TapPass) ----------
class DocCard extends StatelessWidget {
  final Item it; final VoidCallback onTap; final bool last;
  const DocCard(this.it, {super.key, required this.onTap, this.last = false});
  @override
  Widget build(BuildContext c) {
    final k = catOf(it.cat); final n = it.left; final expired = n < 0;
    final base = expired ? mix(k.color, const Color(0xFF6B6B78), .35) : k.color;
    final cl = it.claim;
    return Padding(padding: EdgeInsets.only(bottom: last ? 0 : 12), child: Tap(onTap: onTap, scale: .98, child: Container(
      height: 132,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(24), boxShadow: const [BoxShadow(color: Color(0x2E000000), blurRadius: 22, offset: Offset(0, 8))],
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [base, mix(base, Colors.black, .58)])),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Stack(children: [
        Positioned(right: -18, bottom: -30, child: Opacity(opacity: .14, child: Ic(k.icon, size: 150, width: 1.6))),
        Padding(padding: const EdgeInsets.fromLTRB(18, 16, 16, 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CatTile(it.cat, size: 36, radius: 11, translucent: true),
            const Spacer(),
            if (cl != null && cl.open) ...[const Pill('reklamacja', bg: Color(0x38FFFFFF), fg: Colors.white, icon: 'flag'), const SizedBox(width: 6)],
            DaysPill(n),
          ]),
          const Spacer(),
          Text(it.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(20, w: w8, c: Colors.white, h: 1.25)),
          const SizedBox(height: 2),
          Text([if (it.store.isNotEmpty) it.store, fmtD.format(it.date), if (it.price > 0) money(it.price)].join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: ts(13, c: const Color(0xD9FFFFFF))),
          const SizedBox(height: 9),
          ClipRRect(borderRadius: BorderRadius.circular(99), child: Stack(children: [
            Container(height: 4, color: const Color(0x33FFFFFF)),
            FractionallySizedBox(alignment: Alignment.centerLeft, widthFactor: it.progress, child: Container(height: 4, color: Colors.white)),
          ])),
        ])),
      ])),
    )));
  }
}
class DaysPill extends StatelessWidget {
  final int n; const DaysPill(this.n, {super.key});
  @override
  Widget build(BuildContext c) {
    final col = dayColor(n);
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: const Color(0xF2FFFFFF), borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 7, height: 7, decoration: BoxDecoration(color: col, shape: BoxShape.circle)), const SizedBox(width: 6),
        Text(n < 0 ? 'gwarancja minęła' : 'zostało ${leftShort(n)}', style: ts(12, w: w8, c: const Color(0xFF14141A))),
      ]));
  }
}

// pierścień odliczania
class RingPaint extends CustomPainter {
  final double p; final Color color, track; final double stroke;
  RingPaint(this.p, this.color, this.track, {this.stroke = 10});
  @override
  void paint(Canvas cv, Size s) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, s.width - stroke, s.height - stroke);
    final bg = Paint()..color = track..style = PaintingStyle.stroke..strokeWidth = stroke;
    final fg = Paint()..color = color..style = PaintingStyle.stroke..strokeWidth = stroke..strokeCap = StrokeCap.round;
    cv.drawArc(r, 0, math.pi * 2, false, bg);
    if (p > 0) cv.drawArc(r, -math.pi / 2, math.pi * 2 * p, false, fg);
  }
  @override
  bool shouldRepaint(RingPaint o) => o.p != p || o.color != color || o.track != track;
}

// płynne przejście do pełnego ekranu
Route<R> fadeRoute<R>(Widget w) => PageRouteBuilder<R>(
      transitionDuration: const Duration(milliseconds: 320), reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => w,
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: CurvedAnimation(parent: a, curve: Curves.easeOut), child: SlideTransition(
        position: Tween(begin: const Offset(0, .04), end: Offset.zero).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)), child: child)),
    );
