import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'core.dart';

final _f = DateFormat('dd.MM.yyyy');
String _o(String? s, String d) => (s == null || s.trim().isEmpty) ? d : s.trim();

const rekReq = ['naprawy towaru', 'wymiany towaru na nowy, wolny od wad', 'obniżenia ceny', 'odstąpienia od umowy i zwrotu ceny'];
const rekLbl = ['Naprawa', 'Wymiana na nowy', 'Obniżenie ceny', 'Odstąpienie od umowy (zwrot pieniędzy)'];
const gwReq = ['naprawy zgodnie z warunkami gwarancji', 'wymiany towaru na nowy', 'zwrotu ceny (jeśli warunki gwarancji to przewidują)'];
const gwLbl = ['Naprawa', 'Wymiana na nowy', 'Zwrot ceny'];

// [fragment nazwy, nazwa, wskazówka]
const brands = [
  [' samsung', 'Samsung', 'Zgłoszenie serwisowe złożysz też w aplikacji Samsung Members.'],
  [' apple', 'Apple', 'Wsparcie Apple pozwala umówić naprawę w autoryzowanym serwisie; przygotuj numer seryjny.'],
  [' bosch', 'Bosch', 'Numer fabryczny urządzenia AGD jest na tabliczce znamionowej; serwis o niego zapyta.'],
  [' siemens', 'Siemens', 'Numer fabryczny urządzenia AGD jest na tabliczce znamionowej.'],
  [' whirlpool', 'Whirlpool', 'Model i numer serwisowy są na tabliczce znamionowej urządzenia.'],
  [' lg ', 'LG', 'Przyda się model i numer seryjny z tabliczki lub naklejki.'],
  [' sony', 'Sony', 'Przyda się model i numer seryjny z naklejki na urządzeniu.'],
  [' philips', 'Philips', 'Przyda się dokładny model i numer seryjny.'],
  [' makita', 'Makita', 'Elektronarzędzia przyjmują zwykle autoryzowane serwisy; lista jest na stronie producenta.'],
  [' dyson', 'Dyson', 'Przygotuj numer seryjny z tabliczki na urządzeniu.'],
  [' lenovo', 'Lenovo', 'Zgłoszenie opiera się na numerze seryjnym z naklejki na urządzeniu.'],
];
List<String>? brandOf(Item it) {
  final t = ' ${it.name} ${it.store} '.toLowerCase();
  for (final b in brands) { if (t.contains(b[0])) return b; }
  return null;
}

String buildLetter(Item it, String basis, int req, String desc, DateTime dt, String seller, String addr, Map<String, String> me) {
  final rek = basis == 'rek';
  final nm = _o(me['n'], '[imię i nazwisko]');
  final who = '$nm\n${_o(me['a'], '[adres]')}\n${_o(me['c'], '[e-mail lub telefon]')}';
  final cena = it.price > 0 ? ' (cena ${it.price.toStringAsFixed(2)} zł)' : '';
  final nr = it.docNo.isNotEmpty ? ' nr ${it.docNo}' : '';
  final proof = '${it.doc}$nr z dnia ${_f.format(it.date)}';
  final by = it.buyer.isNotEmpty ? 'Dane nabywcy zgodne z fakturą: ${it.buyer}.\n\n' : '';
  final to = '${_o(seller, rek ? '[sprzedawca]' : '[gwarant / producent]')}\n${_o(addr, '[adres]')}';
  final head = 'Miejscowość, dnia ${_f.format(DateTime.now())}\n\n$who\n\n$to\n\n';
  final w = 'W dniu ${_f.format(dt)} stwierdziłem(am) wadę towaru: ${_o(desc, '[opis wady]')}.\n\n';
  if (rek) {
    return '${head}Reklamacja z tytułu rękojmi\n\nDnia ${_f.format(it.date)} kupiłem(am) u Państwa: ${it.name}$cena. Dowód zakupu: $proof.\n\n$by$w'
        'Na podstawie przepisów o rękojmi za wady rzeczy sprzedanej (art. 556 i nast. oraz art. 43a i nast. Kodeksu cywilnego) żądam: ${rekReq[req]}.\n\n'
        'Proszę o ustosunkowanie się do żądania w terminie 14 dni od otrzymania pisma. Brak odpowiedzi w tym terminie oznacza, że żądanie zostało uznane za uzasadnione.\n\n'
        'Odpowiedź proszę przesłać na: ${_o(me['c'], '[e-mail lub telefon]')}.\n\nZałączniki: kopia dowodu zakupu, zdjęcia wady.\n\nZ poważaniem,\n$nm';
  }
  return '${head}Zgłoszenie reklamacyjne z tytułu gwarancji\n\nDnia ${_f.format(it.date)} kupiłem(am): ${it.name}$cena. Dowód zakupu: $proof. Towar jest objęty gwarancją do dnia ${_f.format(it.end)}.\n\n$by$w'
      'Zgodnie z warunkami gwarancji zgłaszam wadę i żądam: ${gwReq[req]}. Proszę o potwierdzenie przyjęcia zgłoszenia, podanie jego numeru oraz wskazanie sposobu przekazania towaru do serwisu.\n\n'
      'Zastrzegam, że zgłoszenie gwarancyjne nie wyłącza moich uprawnień z tytułu rękojmi wobec sprzedawcy.\n\nZałączniki: kopia dowodu zakupu, zdjęcia wady.\n\nZ poważaniem,\n$nm';
}

// PDF z polskimi znakami (czcionka Roboto pobierana przy pierwszym użyciu; do pracy offline dołącz TTF do assets)
Future<void> sharePdf(String text, String name) async {
  final font = await PdfGoogleFonts.robotoRegular();
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(48), build: (c) => [pw.Text(text, style: pw.TextStyle(font: font, fontSize: 11, lineSpacing: 3))]));
  await Printing.sharePdf(bytes: await doc.save(), filename: '$name.pdf');
}
