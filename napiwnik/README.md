# Napiwnik

Aplikacja dla kelnera we Flutterze: grafik zmian, napiwki, godziny i zarobki w okresie rozliczeniowym.
Bez konta, bez chmury i bez internetu. Dane są w SQLite na telefonie. To nie jest kasa (POS):
utarg jest tylko opcjonalną informacją.

## Ekrany

- **Dashboard**: karta „Dziś” (przepracowane godziny, status zmiany; zmiana zostaje 4 h po zakończeniu),
  licznik do wypłaty (7 dni przed), zmiany do uzupełnienia, kafelki okresu (napiwki, godziny, zarobki),
  najbliższe zmiany. Dotknięcie kafelka otwiera szczegóły okresu.
- **Grafik**: widok tygodnia i miesiąca, planowanie całego tygodnia lub miesiąca naraz (te same godziny
  dla zaznaczonych dni albo własne godziny dla wybranego dnia).
- **Statystyki**: 7 dni, wybrany okres rozliczeniowy, rok, całość; wykresy, średnie, gotówka vs karta,
  podział na miejsca.
- **Ustawienia**: miejsca pracy ze stawką godzinową, okres rozliczeniowy (tydzień / 2 tygodnie /
  miesiąc kalendarzowy) i jego początek, cel napiwków na okres, pierwszy dzień tygodnia, dzień wypłaty,
  motyw, CSV, kopia zapasowa i przywracanie (razem z ustawieniami).

## Zasady interfejsu

- Mniej przycisków: **dotknięcie** otwiera pozycję lub podsumowanie, **przytrzymanie** daje opcje,
  **przesunięcie w lewo** usuwa (z „Cofnij”). Przyciski tylko tam, gdzie są konieczne (np. Zapisz).
- Napiwki wpisuje się dotykając zakończonej zmiany. Nie można ich wpisać do zmiany, która się jeszcze
  nie odbyła, ani z przyszłą datą.
- Filtr miejsca pracy (chipsy u góry) działa tak samo na Dashboardzie, w Grafiku i w Statystykach.
- Okres rozliczeniowy jest jeden: ten sam na Dashboardzie, w szczegółach i w Statystykach.
- Kolory: turkus (`kTeal`) i mosiądz (`kBrass`) z `lib/theme.dart`; kafelki to `Panel`.

## Budowanie

APK buduje GitHub Actions (`.github/workflows/napiwnik-build.yml`): generuje `android/`, uruchamia
`flutter analyze` i `flutter build apk`, a potem podpisuje własnym kluczem z sekretów repozytorium
(`NAPIWNIK_KEYSTORE_B64`, `NAPIWNIK_KEYSTORE_PASSWORD`, `NAPIWNIK_KEY_ALIAS`, `NAPIWNIK_KEY_PASSWORD`).
Ten sam klucz przy każdej wersji pozwala aktualizować aplikację bez odinstalowywania. Plik klucza
przechowuj poza repozytorium.

Lokalnie:

```bash
flutter create --org pl.napiwnik --project-name napiwnik --platforms=android .
flutter pub get
flutter run
```

Jeśli `flutter create` nadpisze `lib/main.dart` lub `pubspec.yaml`, skopiuj je z repozytorium ponownie.

## Dane

- Kwoty w groszach (int). Zmiana schematu bazy: podnieś `version` w `lib/db.dart` i dopisz migrację
  w `onUpgrade` (obecnie wersja 4: grafik, stawka godzinowa, utarg).
- Kopia zapasowa (JSON, wersja 2) zawiera wpisy, zmiany, miejsca pracy, cel i ustawienia okresu, tygodnia
  i wypłaty. Starsze kopie nadal się wczytują.
- CSV: separator `;`, przecinek dziesiętny, działa w polskim Excelu.

## Testy

Testy jednostkowe są w `test/` (daty, okresy, kopia zapasowa, podsumowania, formatowanie). Workflow je
pomija, więc uruchamiaj lokalnie: `flutter test`.
