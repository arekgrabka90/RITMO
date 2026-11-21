# Napiwnik

Lokalny dziennik napiwków we Flutterze. Bez konta, bez Supabase, bez internetu.
Dane są w SQLite na telefonie.

## Uruchomienie

```bash
flutter create --org pl.twojanazwa --project-name napiwnik .   # generuje android/ i resztę, nie rusza lib/ ani pubspec.yaml
flutter pub get
flutter run
```

Jeśli `flutter create` nadpisze `lib/main.dart` lub `pubspec.yaml`, skopiuj je z paczki ponownie.

## Funkcje

- Wpisy: data, miejsce pracy, gotówka, karta, odliczenie (podział z barem/kuchnią), godziny, notatka
- Netto i stawka za godzinę liczone automatycznie
- Wiele miejsc pracy i filtr po miejscu
- Cel miesięczny z paskiem postępu
- Statystyki: 7 dni, 30 dni, rok, całość; wykresy dzień po dniu / miesiąc po miesiącu, średnia wg dnia tygodnia, gotówka vs karta, podział na miejsca
- Eksport CSV (separator `;`, przecinek dziesiętny, działa w polskim Excelu)
- Kopia zapasowa i przywracanie z pliku JSON
- Jasny, ciemny lub systemowy motyw
- Usuwanie przesunięciem z możliwością cofnięcia

## Uwagi

- Kod nie był kompilowany w tym środowisku (brak Flutter SDK). Przy pierwszym `flutter run` mogą wyjść drobne błędy zależne od wersji pakietów, więc wklej mi komunikat, a poprawię.
- Zmiana schematu bazy: podnieś `version` w `lib/db.dart` i dopisz migrację w `onUpgrade`.
