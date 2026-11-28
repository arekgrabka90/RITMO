# RITMO v1.3 — Architecture & Technical Decisions

*RITMO v1.3 Documentation Baseline — Frozen · 27.11.2026 · baza: `ritmo-develop`, HEAD `f39ac37` (GitHub jest jedynym źródłem prawdy)*

**Oznaczenia:** **\[Zweryfikowane\]** potwierdzone bezpośrednio w kodzie na `f39ac37` · **\[Niezweryfikowane\]** nie udało się potwierdzić · **\[Rekomendacja\]** proponowane rozwiązanie, nie opis istniejącej implementacji · decyzje czekające na użytkownika: Product Specification §11. Test bez dowodu z GitHub Actions ma status „Nieuruchomione”. W audycie nie uruchamiano kodu ani testów, a konektor GitHub nie udostępnia wyników GitHub Actions, więc żaden test nie jest uznany za przechodzący. Repozytorium nie zostało zmienione.

## 1. Zasady architektury

1. Ewolucja istniejącego kodu, bez przepisywania od zera.
2. Technologie: Flutter, Dart, SQLite (`sqflite`), repozytoria, typowane warstwy dostępu do danych, testy jednostkowe i integracyjne.
3. Nowa struktura powstaje obok starej i ekrany przenosimy, gdy i tak je zmieniamy.
4. Tanie furtki (wersjonowanie schematu, `calc_version`, interfejsy) tak. Infrastruktura bez potwierdzonej potrzeby nie.
5. Każda zmiana danych: addytywna, z testem na kopii prawdziwej bazy.

## 2. Wyniki audytu etapu 1

### 2.1 Repozytorium i build

| Ustalenie | Status |
| --- | --- |
| Zdalnie są dwie gałęzie: `main` (same README) i `ritmo-develop` (`f39ac37`). Gałęzi `napiwnik-flutter` i `ci/initial-build` nie ma | Zweryfikowane |
| Projekt w `napiwnik/`: `lib` (16 plików i `screens` z 12), `test` (16 plików), `tool`, `pubspec.yaml` (wersja `0.1.0+1`) | Zweryfikowane |
| Workflow `napiwnik-build.yml` startuje po pushu tylko na `napiwnik-flutter` albo ręcznie, więc push na `ritmo-develop` go nie uruchamia | Zweryfikowane |
| `android/` nie jest w repo, powstaje w CI przez `flutter create --org pl.napiwnik --project-name napiwnik` | Zweryfikowane |
| Flutter w CI: kanał `stable`, niepinowany. `intl: any` w `pubspec` | Zweryfikowane |
| Testy w CI mają `continue-on-error`, `flutter analyze` nie blokuje ostrzeżeń | Zweryfikowane |
| Podpis własnym kluczem z sekretów. Bez sekretów APK dostaje klucz debug (ostrzeżenie w logu) | Zweryfikowane |
| Numer wersji APK to `github.run_number`, etykieta aplikacji ustawiana na „Napiwnik” przez `sed` | Zweryfikowane |
| Zależności: `share_plus`, `file_picker`, `crypto`, `fl_chart`. Brak `timezone`, `local_auth`, powiadomień, Drift, `sqflite_common_ffi` | Zweryfikowane |
| Dokładny `applicationId` (wynika z flag, spodziewane `pl.napiwnik.napiwnik`) | Niezweryfikowane |
| Wyniki uruchomienia testów i GitHub Actions (niedostępne przez konektor); lokalnej kopii nie ma, więc porównanie z nią nie dotyczy | Niezweryfikowane |

### 2.2 Baza danych i dane

| Ustalenie | Status |
| --- | --- |
| Baza `napiwnik.db`, wersja 4, tabele `workplaces`, `tips`, `shifts`; migracje addytywne w `onUpgrade` (`ALTER TABLE ADD COLUMN`) | Zweryfikowane |
| Klucze obce włączone. `tips.workplace_id`, `shifts.workplace_id` i `shifts.tip_id` mają `ON DELETE SET NULL`. Indeksy po dacie | Zweryfikowane |
| Brak `CHECK` i brak `UNIQUE` na `shifts.tip_id`. Brak kopii pliku bazy przed migracją | Zweryfikowane |
| Brak testów bazy, migracji i `Store` w odczytanych plikach (brak `sqflite_common_ffi`) | Zweryfikowane (w zakresie przeczytanych plików) |
| Kwoty to `int` w groszach. Brak typu `Money`. `Tip.hours` to `double?`, czas zmiany w minutach | Zweryfikowane |
| Ustawienia w `SharedPreferences` (`goal`, `theme`, `range_start`, `range_end`, `week_start`, `period_type`, `period_anchor`, `pay_day`, `pay_offset`, `templates`, `last_backup`, `pin_hash`, `pin_salt`, `onboarded`) | Zweryfikowane |
| Settery ustawień nie czekają na wynik zapisu (`setInt` bez `await`), a stan w pamięci zmienia się przed zapisem | Zweryfikowane |
| Restore: baza w jednej transakcji, ale ustawienia zapisywane osobno po niej, więc całość nie jest atomowa. Plik jest walidowany przed zapisem | Zweryfikowane |
| Kopia JSON: marker `app = napiwnik`, wersje 1 i 2, bez szyfrowania, bez PIN-u | Zweryfikowane |

### 2.3 Pola, które wskazałeś do audytu

| Pole | Ustalenie | Status |
| --- | --- | --- |
| `Tip.tipOut` | Kwota wpisywana ręcznie („Odliczenie”). `net = cash + card − tipOut`. Walidacja: nie więcej niż gotówka plus karta. Brak procentu, sposobu rozliczenia i kanału | Zweryfikowane |
| `Tip.sales` | Opcjonalny utarg w groszach, „tylko informacyjnie”. Zero w formularzu zapisuje się jako brak. Nie jest `cash_due` | Zweryfikowane |
| % utargu | Liczony od napiwków brutto. Na Dashboardzie i w raporcie jako suma brutto z wpisów z utargiem przez sumę utargów | Zweryfikowane |
| `Tip.hours` | Godziny wpisu. W `computePeriodStats` liczone tylko dla wpisów niepowiązanych ze zmianą. Ekran Statystyki liczy „Średnio na godzinę” wyłącznie z `Tip.hours`. Formularz podpowiada godziny zmiany zaokrąglone do 2 miejsc | Zweryfikowane |
| `Shift.durationMin` | Nominalny: gdy koniec ≤ start, zmiana kończy się następnego dnia. Ignoruje zmianę czasu. Gdy start = koniec, model dałby 1440 min, ale `TimeRange.valid` i import kopii to odrzucają | Zweryfikowane |
| Formularz zmiany a start = koniec | UI używa walidacji start ≠ koniec (`shift_form.dart`, patrz 2.6) | Zweryfikowane |

*Korekta wcześniejszego raportu:* stwierdzenie, że zmiana o identycznym starcie i końcu „daje 24 h”, dotyczy tylko modelu. Walidacja w `TimeRange` i w imporcie je odrzuca.

### 2.4 Obliczenia

| Ustalenie | Status |
| --- | --- |
| Obliczenia okresu są w czystej funkcji `computePeriodStats` (`overview.dart`) i mają testy | Zweryfikowane (istnienie testów; treść nieczytana) |
| Wynagrodzenie = stawka × minuty **zaplanowanej** zmiany (do chwili obecnej), zaokrąglane `round()` na zmianę | Zweryfikowane |
| Stawka to bieżąca wartość `Workplace.hourlyRate`. Zmiana stawki zmienia obliczenia przeszłych okresów. Brak historii stawek | Zweryfikowane |
| Minione zaplanowane zmiany liczą się jako przepracowane bez potwierdzenia. Brak statusu zmiany (odwołana, trwa) i brak czasu rzeczywistego oraz przerw | Zweryfikowane |
| Dwa źródła godzin dla wskaźnika na godzinę: Dashboard (godziny ze zmian) i Statystyki (`Tip.hours`) | Zweryfikowane |
| Brak `calc_version` i fikstur w odczytanych plikach | Zweryfikowane (zakres: przeczytane pliki) |
| Pozostałe pliki: `dates.dart`, `period.dart`, `buckets.dart`, `export.dart`, `util.dart`, `widgets.dart`, `dashboard.dart`, `home.dart`, `schedule.dart`, `shift_form.dart`, `shift_actions.dart`, `bulk_plan.dart`, `period_details.dart`, `tiles.dart`, treść testów | Niezweryfikowane |

### 2.5 Interfejs i bezpieczeństwo

| Ustalenie | Status |
| --- | --- |
| Nawigacja: 4 zakładki (Dashboard, Grafik, Statystyki, Ustawienia). Po powrocie z tła `refreshClock` | Zweryfikowane |
| Błąd wczytania danych przy starcie pokazuje ekran z ponowną próbą | Zweryfikowane |
| `Store` ma `setPin`, `checkPin`: `sha256(sól + pin)` w `SharedPreferences`. `main.dart` i `settings.dart` blokady nie wywołują | Zweryfikowane |
| Czy PIN jest użyty w innych plikach | Niezweryfikowane |
| `settings.dart` ma kontrolkę tylko dla dnia wypłaty miesięcznej (brak kontrolki `payOffset`) | Zweryfikowane |
| `Store` jest jedną klasą ok. 18 KB (stan, zapis SQL, ustawienia, PIN, kopie) | Zweryfikowane |
| Funkcja `shiftsOverlap` istnieje (wykrywanie kolizji) | Zweryfikowane. Użycie w UI: Niezweryfikowane |
| Backup: odrzucenie wpisu z `hours ≤ 0`. Czy formularz może zapisać zero godzin | Niezweryfikowane (potencjalne ryzyko niezgodności) |

### 2.6 Uzupełnienie audytu (odczyt kolejnych plików z `f39ac37`)

| Ustalenie | Status |
| --- | --- |
| `parseHours` odrzuca godziny ≤ 0 i > 48, zgodnie z walidacją kopii. Zero godzin w formularzu jest niemożliwe, więc wcześniejsze podejrzenie niezgodności z importem odpada | Zweryfikowane |
| `parseMoney` parsuje tekst bez `double`, limit pojedynczej kwoty 1 000 000,00 zł; `csvCell` zabezpiecza komórki CSV przed formułami | Zweryfikowane |
| `ShiftForm` używa `TimeRange.valid` (start ≠ koniec) i ostrzega o nakładających się zmianach (`shiftsOverlap`). Rozstrzyga to wcześniejsze „Niezweryfikowane” o formularzu | Zweryfikowane |
| Formularz zmiany informuje, że zmiana godzin zmiany nie zmienia wpisu napiwków, co potwierdza dwa niezależne źródła godzin | Zweryfikowane |
| `period.dart`: okresy tygodniowe i dwutygodniowe liczone od kotwicy, miesięczny kalendarzowy; `nextPayday` (dzień miesiąca, w krótszych miesiącach ostatni dzień) i `nextPaydayAfterPeriod` (przesunięcie 0–14 dni) istnieją | Zweryfikowane |
| `dashboard.dart` używa tylko `daysToPayday(today, store.payDay)`, czyli dnia miesiąca; przesunięcie po okresie nie jest tam użyte ani ustawiane w `settings.dart` | Zweryfikowane |
| Użycie przesunięcia wypłaty w pozostałych plikach | Niezweryfikowane |
| Dashboard: karta „Dziś”, „Do uzupełnienia” (zakończone zmiany bez wpisu), „Zarobki w okresie” = wynagrodzenie z planu + napiwki netto bez oznaczenia szacunku, brak przypomnienia o kopii | Zweryfikowane |
| Dotknięcie, przytrzymanie i przesunięcie zmiany (`openShiftDefault`, `showShiftOptions`, `ShiftDismissible`): nazwy w kodzie; zachowanie i ewentualne cofnięcie (`shift_actions.dart`) | Niezweryfikowane |

**Nadal nieprzeczytane:** `dates.dart`, `buckets.dart`, `export.dart`, `widgets.dart`, `home.dart`, `schedule.dart`, `shift_actions.dart`, `bulk_plan.dart`, `period_details.dart`, `tiles.dart`, `percent.dart`, `theme.dart`, treść plików testów i `tool/`. Dopóki ich nie przeczytano, twierdzenia o nich są **\[Niezweryfikowane\]**.

### 2.7 Dokumentacja w repozytorium (inwentaryzacja `f39ac37`)

| Plik | Ustalenie | Status |
| --- | --- | --- |
| `README.md` (katalog główny) | opisuje koncepcję 0.0.1: Kotlin, Jetpack Compose, Room, DataStore, miejsca pracy ze stanowiskami i kolorem, sześć kategorii rozliczeń, „No settlement calculations”, obliczenia wynagrodzeń poza zakresem, roadmapa 0.0.1 i 0.0.2 | Zweryfikowane |
| `README.md`, sekcja „Repository documentation” | wskazuje `RITMO_0.0.1_SCOPE.md`, `RITMO_0.0.1_ROADMAP.md`, `RITMO_0.0.1_DATA_MODEL.md`, `RITMO_0.0.1_ACCEPTANCE.md`, `RITMO_DECISIONS.md`; żadnego z nich nie ma w katalogu głównym `ritmo-develop` ani w `main` | Zweryfikowane |
| `README.md` a kod | stos (Kotlin, Compose, Room) i zakres (brak obliczeń) są sprzeczne z kodem w `napiwnik/` (Flutter, sqflite, obliczenia zarobków i napiwków) oraz z v1.3; patrz D19 | Zweryfikowane |
| `README.{pl,es,de,fr,ru,it,pt-BR}.md` | tłumaczenia; rozmiary zbliżone do `README.md`, treść nieczytana | Niezweryfikowane |
| `napiwnik/README.md` | opisuje aplikację Flutter „Napiwnik”: ekrany, zasady interfejsu (w tym „Cofnij” przy usuwaniu przez przesunięcie), budowanie w GitHub Actions, dane, kopię v2; utarg tylko informacyjnie; w tych punktach zgodne z odczytanym kodem | Zweryfikowane (deklaracja „Cofnij”: Niezweryfikowane w kodzie) |
| `napiwnik/README.md`, sekcja „Testy” | twierdzi, że workflow pomija testy i każe uruchamiać je lokalnie; workflow uruchamia testy z `continue-on-error`, a lokalnej kopii nie ma | Zweryfikowane (workflow), do poprawy |
| `docs/` | nie istnieje | Zweryfikowane |

**Co zachować:** `computePeriodStats` jako bazę kalkulatora, walidację kopii, migracje addytywne, testy modeli i dat. **Co poprawić:** źródło godzin, historia stawek, `await` ustawień, atomowość restore, CI. **Co wycofać z pierwszej wersji:** wszystko z listy odkładanych w Changelog.

## 3. Stopniowe porządkowanie warstwy danych

**\[Rekomendacja\]** Bez przepisywania. Modele mają `toMap` i `fromMap` **\[Zweryfikowane\]**, ale SQL jest rozproszony w `Store` **\[Zweryfikowane\]**.

1. Kalkulator: zostaje w czystych funkcjach. Nowe obliczenia dodajemy obok `computePeriodStats`, z fiksturami.
2. Repozytoria wprowadzamy per obszar (np. `ShiftRepository` przy Etapie 2), gdy dany kod i tak się zmienia.
3. `Store` dzielimy na kontrolery przy okazji kolejnych funkcji (np. wydzielone ustawienia).
4. Interfejs nie wywołuje SQL bezpośrednio. W odczytanych plikach tego nie stwierdzono **\[Zweryfikowane\]**, reszta **\[Niezweryfikowane\]**.

## 4. Model danych v1.3

| Obszar | Teraz | Dodajemy | Poza v1 |
| --- | --- | --- | --- |
| `workplaces` | nazwa, stawka | profil rozliczeń (M3) | wersjonowane ustawienia rozbudowane |
| `wage_rates` | brak | stawka od daty (M1b przy D11 = A, w przeciwnym razie M2) | stawki per stanowisko |
| `shifts` | data, start i koniec planu, notatka, `tip_id` | `status`, `actual_start`, `actual_end`, `timezone_id`, `time_model` (Etap 2) | `WorkSession` |
| `breaks` | brak | przerwy z płatnością (Etap 2) |  |
| `tips` | gotówka, karta, odliczenie, godziny, utarg | `confirmed_at` (Etap 3) | `ShiftReport`, `cash_due`, `Offset` |
| `payouts` | brak | wypłaty (M2) | `payout_allocations` |
| `period_closures` | brak | snapshot, reguły, `calc_version`, wyniki, korekty (M4) | `ReplayClosure` |

Detale kolumn Etap 2 i 3: dokument „Etapy 1–3”. Wszystkie zmiany addytywne, z wartościami domyślnymi, które nie zmieniają istniejących wyników.

## 5. Kalkulator i zasady obliczeń

- Kwoty w groszach (`int`). **\[Rekomendacja\]** Typ `Money` wprowadzamy stopniowo (nowy kod), bez masowej zamiany.
- Czas pracy w całkowitych minutach. Dla nowych zmian: różnica znaczników czasu (Etap 2).
- Zaokrąglanie: do grosza na poziomie linii (zmiany), suma dokładna. Dziś `round()` w Darcie (połowa od zera). **\[Rekomendacja\]** Zapisać regułę w kodzie i fiksturą.
- `calc_version = 1` oznacza obecną logikę. Zmiana algorytmu podnosi numer. Fikstury (wejście i oczekiwany wynik) powstają z istniejących testów, nie z nowej infrastruktury.
- Kalkulator jest deterministyczny i jedyny. Ekrany, raporty i asystent korzystają z tych samych funkcji.
- Zamknięcie okresu zapisuje dane wejściowe, reguły, `calc_version` i wyniki. Nie przechowujemy starych implementacji kodu.

**5a. Znaczenie `calc_version`.**

- **Wersja 1 = obecna logika z `f39ac37`**, nie kalkulator „po M0”. **\[Zweryfikowane\]** To `computePeriodStats` w `overview.dart`: wynagrodzenie = bieżąca stawka × minuty planu do chwili obecnej, zaokrąglone do grosza na zmianę; godziny ze zmian, a z `Tip.hours` tylko dla wpisów niepowiązanych ze zmianą; napiwki netto = brutto − odliczenie; % utargu = suma brutto z wpisów z utargiem podzielona przez sumę ich utargów.
- **M0 ma zachować wyniki wersji 1** (refaktoryzacja, jedno źródło godzin w Statystykach, etykiety) i udowodnić to fiksturami. Poprawka, która zmienia wynik dla wejścia poprawnego do tej pory, jest zmianą algorytmu.
- **Reguła wersjonowania:** numer rośnie wtedy i tylko wtedy, gdy to samo wejście daje inny wynik. Nowa gałąź dla danych, których wersja 1 nie znała (zmiany z czasem rzeczywistym w Etapie 2, stawka z historią przy jednej stawce), numeru nie podnosi, ale dostaje własne fikstury. Podniesienie byłoby np. przy liczeniu wynagrodzenia dopiero po potwierdzeniu (D10, wariant B) albo przy zmianie reguły zaokrąglania.
- **Fikstury:** pary wejście → oczekiwany wynik z istniejących testów (treść **\[Niezweryfikowane\]**) i z przykładów w dokumentacji. Zmiana wersji dodaje fikstury i nie usuwa starych.
- **Jedno obliczenie dla wszystkich:** Dashboard, Statystyki, raport, eksport i zamknięcie okresu wywołują te same funkcje, a test zgodności porównuje liczby u wszystkich konsumentów dla tych samych danych. **\[Zweryfikowane\]** Dziś Statystyki liczą własne sumy, a „Średnio na godzinę” z `Tip.hours`.
- `calc_version` to na razie stała w kodzie. Zapisuje się dopiero w zamknięciu okresu (M4) razem z danymi wejściowymi. Nie utrzymujemy starych implementacji ani wielu wersji na zapas.

## 6. Migracje i ochrona istniejacych danych

**Nie zmieniamy bez osobnego audytu i Twojej zgody:** `applicationId`, nazwę bazy `napiwnik.db`, klucze `SharedPreferences`, marker kopii `app = napiwnik`, kompatybilność importu JSON v1 i v2.

**\[Rekomendacja\]** Procedura każdej migracji: (1) tylko `ADD COLUMN` i nowe tabele z wartościami domyślnymi; (2) kopia pliku bazy przed migracją (dziś jej nie ma, **Zweryfikowane**); (3) test na bazie utworzonej w wersji 4 z `sqflite_common_ffi`; (4) bramka: sumy zarobków, napiwków i godzin per okres identyczne przed i po; (5) nowe kolumny czasu rzeczywistego nie zmieniają już zapisanych zmian (`time_model = legacy`).

**Wpływ na obecnych użytkowników:** dodanie kolumn z wartościami domyślnymi nie zmienia istniejących rekordów ani wyników. Historia stawek wymaga zasilenia pierwszego wiersza obecną stawką z datą „od początku”, więc przeszłe okresy liczą się tak jak dziś. To trzeba pokazać w podglądzie przed wdrożeniem (M1b przy D11 = A, w przeciwnym razie M2).

**6a. Przywracanie kopii: procedura.** **\[Zweryfikowane\]** Dziś plik jest w całości walidowany przed zapisem, dane (trzy tabele) zapisują się w jednej transakcji SQLite, a ustawienia z kopii (okres, dzień wypłaty i inne) zapisują się osobno po niej, bez sprawdzenia wyniku zapisu. **Nie deklarujemy atomowości całej operacji:** SQLite i SharedPreferences to dwa magazyny, a atomowa jest tylko transakcja bazy. Spójność całości zapewnia procedura z dziennikiem (flaga i trwałe pliki) oraz możliwością dokończenia albo wycofania. **\[Rekomendacja\]** Bez zmiany formatu kopii, nazwy `napiwnik.db`, istniejących kluczy i markera `napiwnik`; import JSON v1 i v2 bez zmian.

Pliki robocze leżą w katalogu dokumentów aplikacji (nie w pamięci podręcznej) i mają wspólny identyfikator operacji `<id>`:

- `restore-source-<id>.json`: kopia bajt w bajt importowanego pliku,
- `pre-restore-<id>.json`: eksport bieżących danych w formacie v2,
- `pre-restore-settings-<id>.json`: dotychczasowe wartości dokładnie tych kluczy ustawień, które restore zapisze.

Kroki:

1. Walidacja całego pliku (jak dziś). Błąd kończy operację, nic się nie zmienia.
2. Trwałe zabezpieczenie importowanej kopii: zapis `restore-source-<id>.json` i odczyt kontrolny (rozmiar i skrót). Niepowodzenie kończy operację.
3. Zabezpieczenie bieżącego stanu: zapis `pre-restore-<id>.json` i `pre-restore-settings-<id>.json` z odczytem kontrolnym. Niepowodzenie kończy operację.
4. Zapis flagi `restore_in_progress = <id>` (D14 = A).
5. Zapis ustawień z kopii z kontrolą wyniku każdego zapisu. Błąd: przywrócenie wartości z pliku ustawień, usunięcie flagi, komunikat.
6. Transakcja bazy (wyczyszczenie i wstawienie danych z kopii). Błąd: rollback bazy, przywrócenie ustawień, usunięcie flagi, komunikat.
7. Weryfikacja: liczby rekordów i sumy kwot w bazie zgodne z plikiem źródłowym. Sukces: usunięcie flagi i odświeżenie stanu. Pliki robocze zostają do ręcznego usunięcia lub udostępnienia.

Ustawienia zapisujemy przed bazą, bo ich wycofanie jest tanie i działa z pliku, a po zatwierdzeniu transakcji bazy nie zostaje krok, który mógłby się nie udać.

**Wykrywanie przerwanej operacji i odzyskiwanie.** Przy starcie flaga `restore_in_progress` oznacza przerwaną operację (zabity proces, restart telefonu). Aplikacja nic nie robi sama: pokazuje ekran odzyskiwania, ustala, czy baza odpowiada plikowi źródłowemu (te same liczby rekordów i sumy), czy plikowi `pre-restore`, i oferuje **Dokończ** (dane i ustawienia z `restore-source-<id>.json`) albo **Wycofaj** (dane z `pre-restore-<id>.json` i ustawienia z `pre-restore-settings-<id>.json`). Po wyborze flaga jest usuwana. Gdy brakuje pliku potrzebnego dla opcji, ta opcja jest niedostępna, a użytkownik widzi powód. Przy D14 = B rolę klucza pełni plik-marker.

**6b. Migracja istniejących rozliczeń i wpisów bez zmiany.** Zasady i procedura prezentacji: „Etapy 1–3”, §3.2, oraz Product Specification §12. Technicznie: tylko nowe kolumny z wartościami domyślnymi, żadna kwota ani godzina się nie zmienia, a dane ze starego modelu są rozpoznawalne po braku czasu rzeczywistego (`time_model = legacy`). **Wpisy napiwków bez powiązanej zmiany** (wiersze `tips` bez wskazującego na nie `shifts.tip_id`) są pełnoprawnym rodzajem wpisu **\[Zweryfikowane\]** (`computePeriodStats` liczy ich `Tip.hours` osobno): klasyfikujemy je jako „wpis samodzielny, stary model”, nie jako błąd, nie usuwamy ich i zachowują kwoty oraz dotychczasową semantykę. Mają status rozliczenia „Wpisano”, a wynagrodzenia się do nich nie dolicza.

**6c. Oznaczanie wpisów napiwków jako „stary model” (techniczne).** **\[Rekomendacja\]** Migracja dodaje do `tips` kolumnę `record_model TEXT NOT NULL DEFAULT 'legacy'` (w tej samej migracji co `confirmed_at`, Etap 3). Dzięki wartości domyślnej wszystkie istniejące wiersze, powiązane i niepowiązane ze zmianą, dostają `legacy` bez zmiany jakiejkolwiek kwoty, godziny, utargu ani odliczenia. Każdy nowy wpis utworzony po migracji, także samodzielny, kod zapisuje jawnie jako `current`. Wpis samodzielny to wiersz `tips` bez wskazującego na niego `shifts.tip_id`; historyczny wpis samodzielny ma `legacy`, nowy `current`, więc da się je odróżnić. Ograniczenie: kopia JSON v1 i v2 nie zawiera tego pola (format bez zmian), więc przywrócenie kopii oznacza wszystkie wpisy jako `legacy`; to ostrożne i bez utraty danych, a rozszerzenie formatu jest częścią D18. Analogicznie `shifts.time_model` (`legacy` lub `instants`) oznacza zmiany z Etapu 2. Kryterium i test: E3-K10 w „Etapach 1–3”.

## 7. Bezpieczeństwo

- **Blokada aplikacji.** Stan: kod PIN w `Store` istnieje, nieużywany w `main.dart` i `settings.dart` **\[Zweryfikowane\]**. **\[Rekomendacja\]** Uwierzytelnianie systemowe (`local_auth`), PIN w aplikacji tylko jako ekran prywatności. Hash PIN-u w ustawieniach nie chroni po wycieku pliku.
- **Kopia zapasowa.** Dziś JSON bez szyfrowania. **\[Rekomendacja\]** Szyfrowanie hasłem po M4, z ostrzeżeniem o utracie hasła.
- **Android.** Reguły kopii systemowych i `allowBackup`: **\[Niezweryfikowane\]**, bo `android/` powstaje w CI.
- **AI.** Brak kluczy dostawcy w aplikacji. Klucz BYOK w magazynie systemowym, poza kopią.

## 8. CI i build

**\[Rekomendacja\]** (wymaga Twojej zgody, dotyka `.github`; decyzja D6): wyzwalacz na `ritmo-develop`; testy blokujące build; `flutter analyze` z błędami na ostrzeżeniach istotnych; przypięta wersja Fluttera; brak sekretów daje błąd buildu release zamiast cichego klucza debug lub wyraźne ostrzeżenie; zachować stały klucz podpisu, żeby aktualizacja nadal działała. Numer wersji z `run_number` zadziała, póki workflow nie jest odtwarzany od zera.

**Zakres tej dokumentacji.** Workflow `napiwnik-build.yml` nie jest zmieniany. **\[Zweryfikowane\]** Jest skonfigurowany pod gałąź `napiwnik-flutter`, a właściwą gałęzią rozwoju jest `ritmo-develop`; testy mają `continue-on-error`, a Flutter `stable` nie jest przypięty. Naprawa CI jest odrębnym zadaniem i wymaga osobnej zgody użytkownika (D6). **\[Niezweryfikowane\]** Wyniki dotychczasowych uruchomień GitHub Actions są niedostępne przez konektor, więc nie twierdzimy, że testy przechodzą. Procedura weryfikacji bez lokalnej kopii: odczyt kodu i testów z przypiętego SHA, a wyniki testów dopiero z GitHub Actions (po D6 albo z ręcznego uruchomienia workflow). Testy, których nie udało się uruchomić, są oznaczane jako nieuruchomione.

**CI a zakres M0.** Naprawa workflow CI (D6) nie jest elementem M0 i nie blokuje jego pakietów. M0 osiąga „Tests passed” na podstawie logu rzeczywistego, ręcznie uruchomionego workflow (`workflow_dispatch`), który nie wymaga zmiany pliku workflow. Uruchomienie takiego workflow wykonuje użytkownik, bo konektor GitHub nie udostępnia GitHub Actions. Do czasu zgody na D6 zielony status zadania nie jest dowodem, bo testy mają `continue-on-error`; liczy się wynik `flutter test` w logu.

## 9. Wybór technologii

Zostajemy przy Flutterze, Darcie i `sqflite`. Drift i migracja technologiczna nie są etapem roadmapy. Powrót do Drift tylko, gdy pojawi się udokumentowany problem, którego typowane DAO i testy migracji nie rozwiązują. `Riverpod` i `go_router` tylko przy uzasadnieniu konkretnego modułu.

## 10. Nazewnictwo i `applicationId`

| Element | Obecnie | Status |
| --- | --- | --- |
| Produkt | RITMO | decyzja |
| Nazwa na telefonie | „Napiwnik” (przez `sed` w CI) | Zweryfikowane |
| Repozytorium i katalog | `RITMO`, `napiwnik/` | Zweryfikowane |
| Pakiet Dart, baza, marker kopii | `napiwnik`, `napiwnik.db`, `napiwnik` | Zweryfikowane |
| `applicationId` | wynika z `pl.napiwnik` + `napiwnik` | Niezweryfikowane |

**Analiza wpływu zmiany `applicationId`:** Android traktuje inny identyfikator jako **inną aplikację**. Nowa wersja nie zaktualizuje starej, instalacje się rozdzielą, dane starej aplikacji nie przeniosą się same (jedyna droga to kopia JSON), a podpis i klucz mogą zostać, ale identyfikacja w systemie się zmieni. **\[Rekomendacja\]** Nie zmieniać. Zmiana samej nazwy wyświetlanej na RITMO jest bezpieczna dla danych. Zmiana markera kopii `napiwnik` zepsułaby import starych plików, chyba że nowy kod przyjmie oba. Decyzja D7 należy do Ciebie.

## 11. Architektura AI (skrót)

**\[Rekomendacja\]** Warstwa poleceń (Action Layer) wprowadzana stopniowo: najpierw dla nowych akcji (start, przerwa, koniec, wpis napiwków), bez opakowywania całego kodu. Moduł `ai/` zależy tylko od tej warstwy. Zapis tylko przez propozycję i zatwierdzenie interfejsu. Dostawca modelu za interfejsem, tryb bez AI zawsze działa.

## 12. Słownik nazw i konwencje

Nie zmieniamy nazw istniejących elementów kodu, żeby dopasować je do dokumentacji. Opisujemy stan obecny, a nowe nazwy są **\[Rekomendacja\]** na czas wprowadzenia danej funkcji.

| Pojęcie | Stan w kodzie `f39ac37` | Rekomendowana nazwa | Uwagi |
| --- | --- | --- | --- |
| potwierdzenie rozliczenia | brak (zmiana „zrobiona” = ma `tip_id`) | kolumna `confirmed_at` (nazwa `earnings_confirmed_at` z v1.2 jest historyczna i nieużywana) | D2 |
| historia stawek | brak; jest `Workplace.hourlyRate` | tabela `wage_rates`, model Dart `WageRate` | D11; `hourlyRate` zostaje stawką bieżącą |
| status rozliczenia | brak | Brak wpisu, Wpisano, Potwierdzono; w kodzie np. `none`, `entered`, `confirmed` | niezależny od statusu liczby |
| status liczby | brak | Szacowane, Obliczone, Potwierdzone; w kodzie np. `estimated`, `computed`, `confirmed` | osobny typ niż status rozliczenia |
| dane starego modelu | brak | `time_model = legacy` | Etap 2 |
| aktywna zmiana | brak | `status = in_progress` | Etap 2 |
| czas przerw | brak | `breaks.start_at`, `breaks.end_at` w UTC (milisekundy), jak `actual_start` i `actual_end` | Etap 2 |
| kryteria akceptacji | v1.2: K0–K4 według M0–M4 | v1.3: `E1-K<n>`, `E2-K<n>`, `E3-K<n>` według Etapów 1–3 | kryteria v1.2 zostają historyczne |
