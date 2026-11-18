# RITMO

### Osobisty planer pracy i rozliczanie zmian

**RITMO** to osobisty planer pracy dla osób pracujących w gastronomii. Łączy grafik, ewidencję zmian i ich rozliczenia w jednej aplikacji na Androida.

**Status projektu:** 0.0.1 w trakcie rozwoju  
**Platforma:** telefony i tablety z Androidem  
**Model działania:** aplikacja osobista, lokalna i offline

**Inne języki:** [English](README.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md)

---

## Wizja projektu

Praca w gastronomii wiąże się ze zmiennymi grafikami, różnymi miejscami i stanowiskami pracy, godzinami, napiwkami, gotówką i płatnościami kartą. RITMO ma zapewnić jedno praktyczne miejsce do zapisywania i porządkowania tych informacji.

RITMO jest projektowane jako narzędzie osobiste dla pojedynczego pracownika gastronomii. Nie jest systemem zarządzania restauracją, personelem ani produktem SaaS.

## Główne założenia

- **Osobiste:** początkowo przeznaczone dla jednego użytkownika.
- **Offline:** podstawowe funkcje i dane działają lokalnie na urządzeniu.
- **Prywatność:** w początkowym zakresie brak kont, backendu, chmury i synchronizacji.
- **Rozwój etapami:** funkcje są dodawane stopniowo.
- **Niezawodność:** integralność danych, testowane migracje bazy oraz kopie zapasowe i przywracanie są ważnymi wymaganiami.
- **Adaptacyjność:** jedna aplikacja na telefony i tablety z Androidem.
- **Rozdzielenie danych:** wynagrodzenie od pracodawcy i rozliczenia zmian są niezależnymi obszarami.

## Wersja 0.0.1

Pierwsze wydanie koncentruje się na fundamencie aplikacji i podstawowym zarządzaniu pracą.

### Miejsca pracy i stanowiska
- Tworzenie i edycja miejsc pracy.
- Ustawianie nazwy, koloru, waluty i notatki.
- Tworzenie stanowisk przypisanych do konkretnego miejsca pracy.
- Archiwizowanie i przywracanie miejsc pracy oraz stanowisk.

### Zmiany i grafik
- Dodawanie, edycja i usuwanie zmian.
- Przypisanie miejsca pracy i opcjonalnie stanowiska.
- Ręczne wpisywanie godzin rozpoczęcia i zakończenia.
- Oznaczanie zmian jako zaplanowane lub przepracowane.
- Dodawanie notatek.
- Przegląd zmian według dni i nawigacja między miesiącami.

Punch in/out, przerwy, zaokrąglanie czasu i automatyczne obliczanie wynagrodzenia nie należą do wersji 0.0.1.

### Rozliczenia zmian

Rozliczenie jest powiązane z konkretną zmianą. Wersja 0.0.1 zakłada jedno rozliczenie na zmianę i obsługę kategorii:

1. Napiwki gotówkowe — całkowita kwota napiwków gotówkowych.
2. Napiwki kartowe — całkowita kwota napiwków kartowych.
3. Podatek od napiwków kartowych.
4. Pay out — wypłaty z napiwków dla kuchni i baru.
5. Sprzedaż i płatności — dane sprzedażowe i uzgodnienie płatności.
6. Kontrola gotówki — kontrola kasy.

Użytkownik może dodawać pozycje z opcjonalną etykietą, kwotą i notatką. Dostępne są również pozycje własne.

**Aplikacja nie wykonuje obliczeń rozliczeniowych.** W tej wersji RITMO nie sumuje, nie odejmuje, nie interpretuje ani nie rozdziela automatycznie kwot, nie oblicza podatków i nie narzuca procedur rozliczeniowych.

### Ustawienia i interfejs
- Motyw jasny, ciemny i systemowy.
- Adaptacyjna nawigacja i układy na telefony oraz tablety.
- Lokalny zapis danych i ustawień.
- Planowane sekcje: Dziś, Grafik, Rozliczenia, Finanse i Więcej.

Niektóre sekcje będą celowo ograniczone w pierwszym wydaniu.

### Kopia zapasowa i przywracanie
Wersja 0.0.1 obejmuje ręczne tworzenie i przywracanie kopii bazy:
- Eksport kopii bazy do pliku wybranego przez użytkownika.
- Weryfikacja kopii przed przywróceniem.
- Sprawdzenie integralności bazy i zgodności schematu przed zastąpieniem aktualnych danych.

Systemowa kopia Androida do chmury jest wyłączona zgodnie z decyzją projektową. Pliki kopii należy przechowywać w bezpiecznym miejscu. Odinstalowanie aplikacji może usunąć lokalną bazę.

## Prywatność i własność danych

Początkowa wersja aplikacji jest projektowana do działania bez konta internetowego i zdalnego backendu. Każde urządzenie przechowuje własną lokalną bazę. Synchronizacja między urządzeniami nie jest uwzględniona.

Projekt nie zakłada przesyłania osobistych danych o pracy i rozliczeniach na zewnętrzne serwery.

## Technologie

Planowany stos technologiczny Android:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

Ostateczne wersje bibliotek i szczegóły implementacji są ustalane podczas rozwoju.

## Integralność danych i obsługa czasu

Implementacja powinna spełniać następujące zasady:
- Jawne migracje bazy z testami na bazach zawierających istniejące dane.
- Brak destrukcyjnego mechanizmu migracji awaryjnej.
- Integralność referencyjna i odpowiednie ograniczenia bazy.
- Kwoty pieniężne zapisywane jako liczby całkowite w najmniejszych jednostkach waluty.
- Znaczniki czasu zapisywane w UTC wraz z identyfikatorem pierwotnej strefy czasowej.
- Prawidłowa obsługa zmian przechodzących przez północ i zmian czasu letniego, w tym nieistniejących i powtarzających się godzin lokalnych.
- Weryfikacja kopii przed przywróceniem lub zastąpieniem aktywnej bazy.

## Plan rozwoju

| Wersja | Planowany kierunek |
|---|---|
| 0.0.1 | Fundament aplikacji, miejsca pracy, stanowiska, zmiany, podstawowe rozliczenia i ręczny backup/restore |
| 0.0.2 | Punch in/out i dalsze funkcje ewidencji czasu |
| Przyszłe wersje | Zarządzanie wynagrodzeniem, rozszerzone narzędzia finansowe i dodatkowe możliwości rozliczeń |

Przyszłe funkcje będą osobno opisywane i zatwierdzane.

## Poza zakresem 0.0.1

- Konta i obsługa wielu użytkowników.
- Backend, chmura i synchronizacja.
- Integracje POS i systemów restauracyjnych.
- Automatyczne obliczanie podatków lub podział napiwków.
- Silnik reguł i automatyczne obliczenia rozliczeń.
- Obliczanie wynagrodzeń.
- Zaawansowana analityka i prognozowanie finansowe.
- Punch in/out, przerwy i zaokrąglanie czasu.
- Geofencing, Wear OS i widżety.
- Rozbudowane powiadomienia.
- Zaawansowany eksport PDF i arkuszy kalkulacyjnych.
- Udostępnianie zapisów innym osobom.

## Dokumentacja repozytorium

Specyfikacje projektu i decyzje rozwojowe są przechowywane osobno:

- `RITMO_0.0.1_SCOPE.md` — zakres pierwszego wydania.
- `RITMO_0.0.1_ROADMAP.md` — etapy implementacji.
- `RITMO_0.0.1_DATA_MODEL.md` — proponowany model danych.
- `RITMO_0.0.1_ACCEPTANCE.md` — kryteria akceptacji i testy.
- `RITMO_DECISIONS.md` — zatwierdzone decyzje, propozycje i kwestie otwarte.

## Status rozwoju

RITMO 0.0.1 jest w trakcie rozwoju. Ten README opisuje cele i planowany zakres projektu; nie oznacza, że wszystkie wymienione funkcje zostały już zaimplementowane lub zweryfikowane.

Przed uznaniem wydania za ukończone należy zweryfikować kompilację, testy automatyczne, migracje bazy, backup/restore oraz działanie na telefonach i tabletach.

---

**RITMO — Organizuj swoją pracę. Zachowaj kontrolę nad swoimi danymi.**
