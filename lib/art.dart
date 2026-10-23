// Grafiki wektorowe: ikony liniowe (24x24, ten sam zestaw co w TapPass), logo i ilustracje ekranu powitalnego.

const ic = <String, String>{
  'star': '<path d="M12 3.5l2.6 5.3 5.8.8-4.2 4.1 1 5.8L12 16.8l-5.2 2.7 1-5.8-4.2-4.1 5.8-.8z"/>',
  'refresh': '<path d="M20 12a8 8 0 1 1-2.4-5.7M20 4v5h-5"/>',
  'gear': '<circle cx="12" cy="12" r="3"/><path d="M12 2.5v3M12 18.5v3M2.5 12h3M18.5 12h3M5.3 5.3l2.1 2.1M16.6 16.6l2.1 2.1M5.3 18.7l2.1-2.1M16.6 7.4l2.1-2.1"/>',
  'theme': '<circle cx="12" cy="12" r="8.5"/><path d="M12 3.5a8.5 8.5 0 0 0 0 17z" fill="#fff"/>',
  'mail': '<rect x="3" y="5.5" width="18" height="13" rx="2.5"/><path d="M3.8 7l8.2 6 8.2-6"/>',
  'doc': '<path d="M7 3h7l5 5v13H7z"/><path d="M14 3v5h5M10 13h6M10 17h6"/>',
  'lock': '<rect x="5" y="11" width="14" height="10" rx="2.5"/><path d="M8.5 11V8a3.5 3.5 0 0 1 7 0v3"/>',
  'clock': '<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  'trash': '<path d="M4 7h16M10 11v6M14 11v6M6 7l1 12a2 2 0 0 0 2 2h6a2 2 0 0 0 2-2l1-12M9 7V4h6v3"/>',
  'tool': '<path d="M14.5 5.5a4 4 0 0 0 4.9 4.9L11 18.8a2.1 2.1 0 0 1-3-3l8.4-8.4"/><path d="M14.5 5.5l2.2-2.2 4 4-2.2 2.2"/>',
  'alert': '<path d="M12 3.5l9.5 16.5h-19z"/><path d="M12 10v4.5M12 17.3v.2"/>',
  'check': '<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  'bell': '<path d="M6 16v-5a6 6 0 0 1 12 0v5l1.8 2H4.2z"/><path d="M10 20.5a2.2 2.2 0 0 0 4 0"/>',
  'camera': '<rect x="3" y="7" width="18" height="13" rx="3"/><circle cx="12" cy="13.5" r="3.5"/><path d="M8.5 7l1.5-2.5h4L15.5 7"/>',
  'image': '<rect x="3" y="4" width="18" height="16" rx="3"/><circle cx="8.5" cy="9.5" r="1.6"/><path d="M21 15.5l-5-5-9.5 9.5"/>',
  'receipt': '<path d="M6 3h12v18l-3-2-3 2-3-2-3 2z"/><path d="M9 8h6M9 12h6"/>',
  'plus': '<path d="M12 5v14M5 12h14"/>',
  'sun': '<circle cx="12" cy="12" r="4"/><path d="M12 2.5v2M12 19.5v2M2.5 12h2M19.5 12h2M5.3 5.3l1.4 1.4M17.3 17.3l1.4 1.4M5.3 18.7l1.4-1.4M17.3 6.7l1.4-1.4"/>',
  'drawer': '<rect x="3" y="4" width="18" height="16" rx="3"/><path d="M3 12h18M10 16h4M10 8h4"/>',
  'sliders': '<path d="M4 7h10M18 7h2M4 17h2M10 17h10"/><circle cx="16" cy="7" r="2"/><circle cx="8" cy="17" r="2"/>',
  'search': '<circle cx="11" cy="11" r="6.5"/><path d="M20 20l-4.3-4.3"/>',
  'edit': '<path d="M4 20h4L19 9a2.8 2.8 0 0 0-4-4L4 16z"/><path d="M13.5 6.5l4 4"/>',
  'share': '<path d="M12 3v12M7.5 7.5L12 3l4.5 4.5"/><path d="M5 12v6.5A2.5 2.5 0 0 0 7.5 21h9a2.5 2.5 0 0 0 2.5-2.5V12"/>',
  'calendar': '<rect x="3.5" y="5" width="17" height="15.5" rx="3"/><path d="M3.5 10h17M8 3v4M16 3v4"/>',
  'shield': '<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8-7.5 9.5-4.3-1.5-7.5-4.9-7.5-9.5V6z"/><path d="M8.8 12l2.2 2.2 4.3-4.4"/>',
  'close': '<path d="M6 6l12 12M18 6L6 18"/>',
  'chev': '<path d="M9 5l7 7-7 7"/>',
  'chevDown': '<path d="M5 9l7 7 7-7"/>',
  'back': '<path d="M15 5l-7 7 7 7"/>',
  'scan': '<path d="M4 8V6a2 2 0 0 1 2-2h2M16 4h2a2 2 0 0 1 2 2v2M20 16v2a2 2 0 0 1-2 2h-2M8 20H6a2 2 0 0 1-2-2v-2M7 12h10"/>',
  'copy': '<rect x="8" y="8" width="12" height="12" rx="2.5"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>',
  'download': '<path d="M12 4v11M7.5 10.5L12 15l4.5-4.5M5 20h14"/>',
  'upload': '<path d="M12 15V4M7.5 8.5L12 4l4.5 4.5M5 20h14"/>',
  'user': '<circle cx="12" cy="8.5" r="3.8"/><path d="M4.5 20a7.5 7.5 0 0 1 15 0"/>',
  'info': '<circle cx="12" cy="12" r="8.5"/><path d="M12 11v5M12 7.8v.2"/>',
  'coins': '<ellipse cx="12" cy="6.5" rx="7" ry="3"/><path d="M5 6.5v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5M5 11.5v5c0 1.7 3.1 3 7 3s7-1.3 7-3v-5"/>',
  'store': '<path d="M4 9.5l1.5-5h13L20 9.5M4 9.5h16M4 9.5a2.7 2.7 0 0 0 5.3 0 2.7 2.7 0 0 0 5.4 0 2.7 2.7 0 0 0 5.3 0M5.5 12.5V20h13v-7.5M10 20v-4.5h4V20"/>',
  'sort': '<path d="M7 4v16M3.5 16.5L7 20l3.5-3.5M17 20V4M13.5 7.5L17 4l3.5 3.5"/>',
  'flag': '<path d="M5 21V4M5 4h11l-2 4 2 4H5"/>',
  'spark': '<path d="M12 3c.6 4.2 2.8 6.4 7 7-4.2.6-6.4 2.8-7 7-.6-4.2-2.8-6.4-7-7 4.2-.6 6.4-2.8 7-7z" fill="#fff"/>',
  'globe': '<circle cx="12" cy="12" r="8.5"/><path d="M3.5 12h17M12 3.5c2.5 2.6 3.5 5.4 3.5 8.5s-1 5.9-3.5 8.5c-2.5-2.6-3.5-5.4-3.5-8.5s1-5.9 3.5-8.5z"/>',
  'note': '<path d="M5 4h14v11l-5 5H5z"/><path d="M14 20v-5h5M8.5 9h7M8.5 12.5h4"/>',
  'hash': '<path d="M5 9h14M5 15h14M10 4l-2 16M16 4l-2 16"/>',
  'pen': '<path d="M3 21c3-1 5-3 6.5-5.5M14 4l6 6-8.5 8.5-6-6z"/><path d="M12 6l6 6"/>',
  'send': '<path d="M21 3L10 14M21 3l-6.5 18-4-7.5L3 9.5z"/>',
  'eye': '<path d="M2.5 12S6 5.5 12 5.5 21.5 12 21.5 12 18 18.5 12 18.5 2.5 12 2.5 12z"/><circle cx="12" cy="12" r="3"/>',
  'help': '<circle cx="12" cy="12" r="8.5"/><path d="M9.6 9.4a2.5 2.5 0 0 1 4.8 1c0 1.7-2.4 2.1-2.4 3.6M12 17.2v.2"/>',
  'box': '<path d="M3.5 7.5L12 3.5l8.5 4v9L12 20.5l-8.5-4z"/><path d="M3.5 7.5L12 11.5l8.5-4M12 11.5v9"/>',
  'device': '<rect x="4.5" y="5" width="15" height="10.5" rx="1.8"/><path d="M2.5 19h19"/>',
  'washer': '<rect x="4.5" y="3" width="15" height="18" rx="2.5"/><circle cx="12" cy="13" r="4.5"/><path d="M8 6.5h1M11 6.5h1"/>',
  'sofa': '<path d="M5 11V8a3 3 0 0 1 3-3h8a3 3 0 0 1 3 3v3"/><path d="M3 13a2 2 0 0 1 4 0v1h10v-1a2 2 0 0 1 4 0v4.5H3zM5 17.5V20M19 17.5V20"/>',
  'car': '<path d="M4 13l1.8-5.2A2 2 0 0 1 7.7 6.5h8.6a2 2 0 0 1 1.9 1.3L20 13v4.5H4z"/><path d="M4 13h16M6 17.5V20M18 17.5V20"/>',
  'shirt': '<path d="M8.5 3.5L4 6l1.5 4.5 2.5-1v11h8v-11l2.5 1L20 6l-4.5-2.5a3.5 3.5 0 0 1-7 0z"/>',
  'heart': '<path d="M12 20s-7.5-4.6-7.5-10.2A4.3 4.3 0 0 1 12 7a4.3 4.3 0 0 1 7.5 2.8C19.5 15.4 12 20 12 20z"/><path d="M7 12h2.5l1.5-2 2 4 1.5-2H17"/>',
  'bike': '<circle cx="6" cy="16" r="3.5"/><circle cx="18" cy="16" r="3.5"/><path d="M6 16l4-7h6l2 7M10 9L8.5 6H7M12.5 16L16 9"/>',
};

// logo aplikacji (to samo co ikona na telefonie)
const logoSvg = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024"><defs>
<linearGradient id="bg" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1f1d2b"/><stop offset="1" stop-color="#121214"/></linearGradient>
<linearGradient id="dr" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#b3a6ff"/><stop offset="1" stop-color="#5a3df0"/></linearGradient>
<linearGradient id="pp" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#e9e5ff"/></linearGradient></defs>
<rect width="1024" height="1024" rx="230" fill="url(#bg)"/><g transform="translate(82 100) scale(.84)">
<g transform="rotate(10 485 440)"><path d="M330 640V258l25.8-22 25.9 22 25.8-22 25.9 22 25.8-22 25.9 22 25.8-22 25.9 22 25.8-22 25.9 22 25.8-22 25.9 22v382z" fill="url(#pp)"/>
<rect x="372" y="300" width="120" height="30" rx="15" fill="#5a3df0"/><rect x="372" y="370" width="218" height="22" rx="11" fill="#c9c0ff"/><rect x="372" y="420" width="168" height="22" rx="11" fill="#c9c0ff"/><circle cx="586" cy="316" r="20" fill="#ffd166"/></g>
<g transform="rotate(-6 512 640)"><rect x="196" y="486" width="630" height="314" rx="66" fill="url(#dr)"/><rect x="420" y="618" width="184" height="42" rx="21" fill="#fff" opacity=".94"/></g></g></svg>''';

const _swoosh = '<path d="M-20 230 C 40 120, 150 60, 230 90 S 330 200, 250 250 S 90 250, 120 170 S 260 60, 340 40" fill="none" stroke="#24242c" stroke-width="26" stroke-linecap="round"/>';
String _sp(double x, double y, double s, String c) => '<path d="M0,-9 C1.2,-2.4 2.4,-1.2 9,0 C2.4,1.2 1.2,2.4 0,9 C-1.2,2.4 -2.4,1.2 -9,0 C-2.4,-1.2 -1.2,-2.4 0,-9Z" transform="translate($x $y) scale($s)" fill="$c"/>';
String _receipt(double x, double y, double w, double h, String bar, double rot) {
  final n = 6; final st = w / n; final b = StringBuffer('M$x ${y + h}V${y + 8}');
  for (var i = 0; i < n; i++) { b.write('l${st / 2} -8l${st / 2} 8'); }
  b.write('V${y + h}z');
  return '<g transform="rotate($rot ${x + w / 2} ${y + h / 2})"><path d="$b" fill="#f4f4f7" stroke="#14141a" stroke-width="3" stroke-linejoin="round"/>'
      '<rect x="${x + 10}" y="${y + 18}" width="${w * .42}" height="7" rx="3.5" fill="$bar"/>'
      '<rect x="${x + 10}" y="${y + 34}" width="${w - 20}" height="5" rx="2.5" fill="#c9c0ff"/>'
      '<rect x="${x + 10}" y="${y + 46}" width="${w - 30}" height="5" rx="2.5" fill="#c9c0ff"/>'
      '<rect x="${x + 10}" y="${y + 58}" width="${w - 44}" height="5" rx="2.5" fill="#c9c0ff"/>'
      '<rect x="${x + w - 30}" y="${y + h - 20}" width="20" height="8" rx="4" fill="$bar"/></g>';
}

// 1: szuflada z paragonami
final artDrawer = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 300">$_swoosh'
    '<rect x="72" y="150" width="176" height="112" rx="14" fill="#2b2b3a" stroke="#f4f4f7" stroke-width="3"/><rect x="90" y="222" width="140" height="26" rx="8" fill="#1c1c20" stroke="#3a3a4d" stroke-width="3"/><rect x="140" y="230" width="40" height="8" rx="4" fill="#3a3a4d"/>'
    '${_receipt(96, 54, 74, 112, '#5a3df0', -12)}${_receipt(150, 40, 78, 120, '#ff8a3d', 9)}'
    '<rect x="58" y="128" width="204" height="70" rx="14" fill="#a99bff" stroke="#14141a" stroke-width="3"/><rect x="134" y="154" width="52" height="12" rx="6" fill="#fff"/>'
    '<g transform="translate(262 82)"><circle r="24" fill="#34c759" stroke="#14141a" stroke-width="3"/><path d="M-10 0l7 7 13-14" fill="none" stroke="#fff" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/></g>'
    '<circle cx="262" cy="22" r="0" fill="none"/>'
    '${_sp(56, 64, 1.1, '#ffd166')}${_sp(296, 170, .8, '#f4f4f7')}${_sp(30, 238, .9, '#f4f4f7')}${_sp(250, 276, .7, '#ffd166')}'
    '<circle cx="44" cy="140" r="3" fill="none" stroke="#f4f4f7" stroke-width="2"/><circle cx="300" cy="120" r="2.5" fill="none" stroke="#f4f4f7" stroke-width="2"/><circle cx="110" cy="284" r="2.5" fill="none" stroke="#f4f4f7" stroke-width="2"/></svg>';

// 2: kalendarz i dzwonek
final artBell = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 300">$_swoosh'
    '<rect x="56" y="92" width="178" height="164" rx="18" fill="#2b2b3a" stroke="#f4f4f7" stroke-width="3"/><path d="M56 128v-18a18 18 0 0 1 18-18h142a18 18 0 0 1 18 18v18z" fill="#ff8a3d" stroke="#f4f4f7" stroke-width="3"/>'
    '<rect x="90" y="78" width="10" height="28" rx="5" fill="#f4f4f7"/><rect x="190" y="78" width="10" height="28" rx="5" fill="#f4f4f7"/>'
    '${[for (var r = 0; r < 3; r++) for (var c = 0; c < 5; c++) '<rect x="${76 + c * 30}" y="${146 + r * 32}" width="20" height="20" rx="6" fill="${r == 1 && c == 3 ? '#a99bff' : '#3a3a4d'}"/>'].join()}'
    '<circle cx="176" cy="188" r="20" fill="none" stroke="#a99bff" stroke-width="3" stroke-dasharray="3 6"/>'
    '<g transform="translate(250 92)"><path d="M-22 18V2a22 22 0 0 1 44 0v16l7 7h-58z" fill="#ffd166" stroke="#14141a" stroke-width="3" stroke-linejoin="round"/><path d="M-8 30a8 8 0 0 0 16 0" fill="none" stroke="#14141a" stroke-width="3"/>'
    '<path d="M30 -14q10 10 0 24M38 -22q18 18 0 40" fill="none" stroke="#ffd166" stroke-width="3" stroke-linecap="round"/></g>'
    '<g transform="rotate(-5 120 40)"><rect x="30" y="16" width="170" height="52" rx="16" fill="#f4f4f7"/><rect x="40" y="26" width="32" height="32" rx="9" fill="#5a3df0"/><path d="M50 46v-6a6 6 0 0 1 12 0v6l2 2H48z" fill="none" stroke="#fff" stroke-width="2.4" stroke-linejoin="round"/>'
    '<rect x="80" y="28" width="62" height="7" rx="3.5" fill="#14141a"/><rect x="80" y="41" width="104" height="6" rx="3" fill="#9b9cad"/><rect x="80" y="52" width="74" height="6" rx="3" fill="#9b9cad"/></g>'
    '${_sp(290, 170, .9, '#f4f4f7')}${_sp(30, 200, .9, '#ffd166')}${_sp(270, 262, .7, '#f4f4f7')}'
    '<circle cx="24" cy="110" r="3" fill="none" stroke="#f4f4f7" stroke-width="2"/><circle cx="300" cy="226" r="2.5" fill="none" stroke="#f4f4f7" stroke-width="2"/></svg>';

// 3: pismo reklamacyjne z pieczątką
final artClaim = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 300">$_swoosh'
    '<g transform="rotate(-6 160 150)"><rect x="92" y="44" width="140" height="190" rx="14" fill="#f4f4f7" stroke="#14141a" stroke-width="3"/>'
    '<rect x="110" y="64" width="60" height="10" rx="5" fill="#5a3df0"/><rect x="110" y="88" width="104" height="6" rx="3" fill="#c9c0ff"/><rect x="110" y="102" width="92" height="6" rx="3" fill="#c9c0ff"/><rect x="110" y="116" width="100" height="6" rx="3" fill="#c9c0ff"/>'
    '<rect x="110" y="138" width="80" height="6" rx="3" fill="#c9c0ff"/><rect x="110" y="152" width="96" height="6" rx="3" fill="#c9c0ff"/>'
    '<path d="M112 200c10-14 18-14 20 0s12 10 18-4 14-8 20 2" fill="none" stroke="#14141a" stroke-width="3" stroke-linecap="round"/></g>'
    '<g transform="translate(228 206) rotate(-14)"><circle r="38" fill="#2b2b3a" stroke="#34c759" stroke-width="4"/><circle r="29" fill="none" stroke="#34c759" stroke-width="2" stroke-dasharray="3 5"/>'
    '<path d="M-14 0l9 9 18-19" fill="none" stroke="#34c759" stroke-width="6" stroke-linecap="round" stroke-linejoin="round"/></g>'
    '<path d="M38 104l40-16-12 40-8-15z" fill="#a99bff" stroke="#14141a" stroke-width="3" stroke-linejoin="round"/><path d="M58 113l20-25" stroke="#14141a" stroke-width="2.5"/>'
    '<path d="M30 150 q14 -14 28 0 q14 14 28 0" fill="none" stroke="#f4f4f7" stroke-width="2.5" stroke-linecap="round" stroke-dasharray="1 7"/>'
    '<g transform="translate(262 62)"><path d="M0 -26l20 8v14c0 12-8 21-20 25-12-4-20-13-20-25v-14z" fill="#ff8a3d" stroke="#14141a" stroke-width="3" stroke-linejoin="round"/><path d="M-8 0l6 6 11-12" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/></g>'
    '${_sp(60, 40, 1.0, '#ffd166')}${_sp(296, 150, .8, '#f4f4f7')}${_sp(40, 250, .9, '#f4f4f7')}'
    '<circle cx="200" cy="22" r="2.5" fill="none" stroke="#f4f4f7" stroke-width="2"/><circle cx="290" cy="270" r="3" fill="none" stroke="#f4f4f7" stroke-width="2"/></svg>';

const underlineSvg = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 140 13" preserveAspectRatio="none"><path d="M3 9 C 40 2, 96 1, 137 6" fill="none" stroke="#ffd166" stroke-width="3.5" stroke-linecap="round"/></svg>';
