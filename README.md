# Szuflada – paragony i gwarancje (Flutter, Android)

## Uruchomienie przez GitHub (bez instalowania czegokolwiek)
1. Utwórz prywatne repozytorium i wgraj całą zawartość tego folderu (zachowaj `.github/`).
2. Wejdź w **Actions → Build Android → Run workflow**. Po kilku minutach pobierz artefakt `szuflada`.
3. `app-release.apk` zainstaluj na telefonie do testów, `app-release.aab` jest do Google Play.
4. Pierwszy build prawdopodobnie ujawni drobne błędy kompilacji (kod nie był kompilowany). Skopiuj komunikat z Actions i popraw wskazaną linię.

## Co jest zaimplementowane
- Skaner dokumentów Google (ML Kit): kadrowanie, prostowanie, poprawa kontrastu, import z galerii.
- Odczyt tekstu (ML Kit, offline) i parser: sklep, data, kwota, pozycje, faktura imienna (numer, nabywca).
- Przypomnienia lokalne o 9:00 (30 i 7 dni przed końcem gwarancji, 14 dni na zwrot, 14 dni na odpowiedź sprzedawcy) – działają przy zamkniętej aplikacji i po restarcie telefonu.
- Płatności: Google Play Billing (subskrypcja `pro_yearly`, 29,99 zł / rok), przywracanie zakupów.
- Reklamacje: rękojmia i gwarancja, pismo, PDF, wskazówki kontaktu z serwisem marki, zdjęcie wady.
- Kopia zapasowa ZIP (dane + zdjęcia) i przywracanie na nowym telefonie. Dodatkowo działa systemowa kopia Androida (Auto Backup).
- Blokada odciskiem palca / twarzą / PIN-em telefonu, motyw jasny / ciemny / auto, edycja wpisów.

## Płatności w Google Play – kroki
Cyfrowe subskrypcje w aplikacji **muszą** iść przez Google Play Billing (Google Pay jest jedną z metod płatności w oknie Google Play, nie osobną integracją).
1. Załóż konto w Google Play Console (jednorazowo ok. 25 USD).
2. Utwórz aplikację, wgraj `.aab` na ścieżkę testów wewnętrznych (musi być podpisany – patrz niżej).
3. Monetyzacja → Produkty → Subskrypcje: ID produktu **`pro_yearly`**, plan roczny, cena 29,99 PLN.
4. Dodaj testerów licencji (Ustawienia → Testowanie licencji) i testuj zakup z konta testera.
5. Przed skalowaniem dodaj weryfikację zakupów po stronie serwera (Google Play Developer API). W tej wersji uprawnienie Pro odświeża się przy starcie aplikacji.

## Podpis wydania (wymagany do Play)
Wygeneruj klucz: `keytool -genkey -v -keystore upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`.
Dodaj go do GitHub Secrets i skonfiguruj podpisywanie w `android/app/build.gradle.kts` (instrukcja: docs.flutter.dev/deployment/android). Plik klucza i hasła przechowuj w bezpiecznym miejscu – utrata klucza blokuje aktualizacje.

## Do zrobienia przed publikacją
- Polityka prywatności i formularz „Bezpieczeństwo danych” w Play Console (aplikacja przetwarza zdjęcia dokumentów).
- Przegląd wzorów pism przez prawnika; aktualizacja przy zmianie przepisów.
- Czcionka PDF: `printing` pobiera Roboto przy pierwszym użyciu. Do pracy offline dołącz plik TTF do `assets/`.
- Własna ikona i ekran startowy (pakiety `flutter_launcher_icons`, `flutter_native_splash`).
- Wersja angielska (pakiet `intl` + pliki ARB), konto rodzinne i chmura (wymagają serwera).
- Testy parsera na prawdziwych paragonach (plik `lib/services.dart`, klasa `Scanner`).
