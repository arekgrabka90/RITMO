# RITMO

Osobisty planer pracy i zarobków dla pracownika zmianowego (pierwszy profil: gastronomia). Aplikacja działa lokalnie, bez konta i bez chmury.

**Gałąź rozwoju:** `ritmo-develop`

## Aplikacja

Kod znajduje się w katalogu [`napiwnik/`](napiwnik/): aplikacja na Androida napisana we Flutterze (Dart, SQLite przez `sqflite`). Nazwa wyświetlana to „Napiwnik”.

Obecny zakres funkcji (stan z `f39ac37`, zweryfikowany w kodzie):

- grafik zmian z szablonami, planowaniem zbiorczym i kopiowaniem tygodnia,
- wpisy napiwków: gotówka, karta, odliczenie, godziny, opcjonalny utarg (tylko informacyjnie),
- okres rozliczeniowy (tydzień, dwa tygodnie, miesiąc), dzień wypłaty, cel napiwków,
- statystyki i eksport CSV,
- kopia zapasowa JSON (wczytuje formaty v1 i v2).

Opis ekranów i sposobu użycia: [`napiwnik/README.md`](napiwnik/README.md).

## Budowanie

APK buduje workflow GitHub Actions [`napiwnik-build.yml`](.github/workflows/napiwnik-build.yml) (uruchamiany ręcznie albo po pushu na gałąź `napiwnik-flutter`). Szczegóły i znane ograniczenia CI są w dokumentacji architektury.

## Dokumentacja

Indeks dokumentacji: [`docs/README.md`](docs/README.md).

- Aktualna specyfikacja produktu: [`docs/product/RITMO_Product_Specification.md`](docs/product/RITMO_Product_Specification.md) (RITMO v1.3 Documentation Baseline, zakres zamrożony, czeka na formalne zatwierdzenie).
- Architektura i decyzje techniczne: [`docs/architecture/RITMO_Architecture_Technical_Decisions.md`](docs/architecture/RITMO_Architecture_Technical_Decisions.md).
- Plan prac (Etapy 1–3, kryteria akceptacji, pierwszy pakiet): [`docs/development/RITMO_Stages_1-3.md`](docs/development/RITMO_Stages_1-3.md).
- Historia: [`docs/history/`](docs/history/) (koncepcja v1.2, poprzednia treść README, changelog).

Poprzedni opis projektu (koncepcja 0.0.1: Kotlin, Jetpack Compose, Room, bez obliczeń) nie odpowiada obecnemu kodowi. Zachowano go w [`docs/history/RITMO_README_0.0.1_Kotlin_concept.md`](docs/history/RITMO_README_0.0.1_Kotlin_concept.md).

## Następny krok

Dokończenie audytu Etapu 1, a potem pakiet M0-A „Jedno źródło godzin i etykiety” (szczegóły w sekcji „NEXT STEP” dokumentu Etapy 1–3).
