# RITMO Professional — docelowa koncepcja produktu (Etap 3, wersja 1.2)

*Etap 3.2 · wersja 1.2 (zastępuje v1.1) · aktualizacja 25.11.2026 · baza: gałąź `napiwnik-flutter` (HEAD z Etapu 1: `f39ac37`; przed implementacją stan trzeba zweryfikować ponownie)*

**Zakres zmian v1.2:** (1) migracja danych historycznych i zmiany czasu bez zmiany zapisanych wartości (C.6c); (2) pełna odtwarzalność `PeriodClosure` ze snapshotem danych i wersjonowanym kalkulatorem (F.5a); (3) jednoznaczny model `Payout` i `PayoutAllocation` z przykładami liczbowymi (F.6, F.6a); (4) rozdzielenie osi uprawnień AI i udostępniania danych dostawcy (D.3a, D.4a); (5) jeden kanoniczny model `ShiftReport` i `Tip.sales` (C.5a); (6) kanał `other` i kontrola tip-outu względem gotówki (F.1, F.2a); (7) sekcja I uporządkowana według kategorii, wewnętrzne etapowanie M3 i czytelne zależności etapów (G). Pełna lista: „Historia zmian v1.1 → v1.2” na końcu.

**Legenda:** ✅ decyzja zatwierdzona przez właściciela · 🔷 moja rekomendacja · ❓ kwestia otwarta (🔬 = rozstrzygnięcie dopiero po PoC lub testach) · 🚫 rozwiązanie, którego nie rekomenduję

**Numeracja i oznaczenia:** w tekście „decyzja N” odnosi się do 24 decyzji zatwierdzonych w Etapie 3, „decyzja 3.1/N” do 18 decyzji z Etapu 3.1, a „decyzja 3.2/N” do domyślnych rozstrzygnięć koncepcyjnych z Etapu 3.2 (sekcja I). Oznaczenie 🔬 dotyczy kwestii wymagających audytu kodu, PoC lub testów; ich wyniki nie są jeszcze znane i nie są tu przedstawiane jako znane. Wersja 1.2 zastępuje v1.1.

## 0. Najważniejsze zmiany względem Etapu 2

1. **AI jest centralną funkcją, ale nie fundamentem danych.** ✅ Przyjmuję Twoją decyzję. Zmieniam jednak moją wcześniejszą architekturę: zamiast „AI jako dodatek” proponuję **warstwę poleceń (Action Layer)**, przez którą działają wszystkie sposoby sterowania aplikacją: dotyk, głos, powiadomienia, widgety, automatyzacje i AI. Dzięki temu każda nowa funkcja rodzi się razem z narzędziem dla asystenta, a asystent nie wymaga osobnej, „drugiej” aplikacji.
2. **AI pojawia się w planie od pierwszego etapu**, najpierw w postaci deterministycznej (paleta poleceń, odpowiedzi z szablonów), potem z modelem językowym. Zakładka asystenta istnieje wcześnie i działa offline.
3. **Model danych jest prostszy niż w raporcie:** `WorkSession` nie jest osobną encją (opcja C zatwierdzona w Etapie 3.1; porównanie w sekcji C.5), `Settlement` zastąpiony zamknięciem okresu z migawką i korektami.
4. **Nowe pojęcie, którego brakowało w obu wcześniejszych dokumentach:** kanał wypłaty składnika (`paidBy`). Gotówka z napiwków trafia do pracownika od razu, a pensja i napiwki kartą zwykle przychodzą od pracodawcy. Bez tego „uzgodnienie wypłaty” liczyłoby źle. W v1.1 pojęcie paidBy rozdzielono na kanał, podmiot i sposób rozliczenia tip-outu (F.1).
5. **Zmiany tylko w kodzie nie wystarczą:** `android/` musi być w repozytorium, żeby powstały widgety, kafelek, udostępnianie i powiadomienia (potwierdzone w Twojej decyzji nr 10).

---

# A. Wizja produktu

## A.1. Czym jest RITMO

**RITMO to osobisty system pracy i pieniędzy dla osób pracujących zmianowo.** Planuje zmiany, mierzy rzeczywisty czas, rozlicza zarobki i napiwki, pilnuje wypłat i tłumaczy każdą liczbę. Asystent AI obsługuje aplikację razem z użytkownikiem, ale wszystkie kwoty pochodzą z kontrolowanego silnika obliczeń.

🔷 Hasło robocze: **„RITMO — Twoja praca. Twoje pieniądze.”** (wcześniejsze „Your Life” wraca dopiero wtedy, gdy Money lite będzie dojrzałe). Nazwa wymaga jeszcze sprawdzenia dostępności przed publikacją.

## A.2. Dla kogo

✅ Najpierw osoba pracująca w gastronomii, potem inne branże zmianowe (handel, magazyn, opieka, usługi).

**Persona pierwsza:** kelner lub barman, który pracuje w 1–3 miejscach, ma zmienny grafik, napiwki gotówką i kartą, tip-out i wypłatę, która nie jest prostą sumą godzin. Rzadko ma czas na wpisywanie, więc liczy się szybkość. Ceni prywatność i nie chce zakładać kont.

**Cechy wspólne wszystkich branż zmianowych:** zmienny grafik, zmienne dochody, więcej niż jeden pracodawca, wypłata różna od oczekiwanej, brak narzędzia, które łączy czas pracy z pieniędzmi.

✅ Status: osobiste narzędzie z możliwością przyszłej publikacji. 🔷 Konsekwencja: projektujemy tak, jakby produkt miał być publikowany (czytelne granice danych, zgody, brak twardo wpisanych założeń), ale **nie ponosimy kosztów publikacji przed jej decyzją** (konto deweloperskie, backend AI, wsparcie).

## A.3. Jakie problemy rozwiązuje

1. „Ile naprawdę zarobiłem i ile jeszcze mi się należy?”
2. „Czy wypłata się zgadza?” (uzgodnienie należnego z otrzymanym, z dowodem godzin)
3. „Gdzie zarabiam najlepiej na godzinę?” (miejsca, stanowiska, dni, rodzaje zmian)
4. „Nie pamiętam wpisać napiwków” (przypomnienia, szybkie rozliczenie w kilka sekund)
5. „Ile mogę bezpiecznie wydać do wypłaty przy nieregularnych dochodach?” (Safe-to-Spend)
6. Chaos z grafikami z różnych miejsc (kolizje, kopiowanie, import)

## A.4. Czym się wyróżnia

| Typowe aplikacje | RITMO |
| --- | --- |
| Rejestratory czasu pracy nie znają napiwków, tip-outu ani utargu | Pętla **Zmiana → Zarobek → Wypłata** w jednym modelu |
| Aplikacje budżetowe nie znają zmian ani grafiku | Safe-to-Spend z potwierdzonych, jeszcze nieotrzymanych wpływów |
| Kalkulatory napiwków liczą jeden dzień | Okresy, zamknięcia, korekty i historia stawek |
| Chatboty „o finansach” zgadują | Asystent korzysta z narzędzi i pokazuje źródło każdej liczby |
| Usługi w chmurze wymagają konta | Local-first, offline, własne kopie zapasowe |

**Główne wyróżniki, które warto komunikować:** (1) uzgodnienie wypłaty z rozbiciem „skąd ta różnica”, (2) składanie rozliczeń z kontrolowanych składników per miejsce pracy, (3) szybkie wpisywanie (10 sekund po zmianie), (4) asystent, który wykonuje zadania, ale nigdy nie zapisuje niczego bez zatwierdzenia, (5) prywatność.

## A.5. Zasady produktu

1. Każda liczba ma źródło i jest oznaczona jako **fakt, szacunek lub prognoza**.
2. **Jeden kalkulator** dla wszystkich ekranów, asystenta i raportów.
3. Nic nie zmienia danych finansowych bez zatwierdzenia użytkownika.
4. Podstawowe funkcje działają bez internetu i bez AI.
5. Branże nie zmuszają się nawzajem do swoich funkcji (profile).
6. Aplikacja nie deklaruje prawidłowego wynagrodzenia netto ✅.
7. Ważne funkcje mają widoczną drogę, nie tylko gest ✅.
8. Zachowanie istniejących danych i funkcji ma pierwszeństwo przed nowościami ✅.

---

# B. Zakres funkcjonalny

## B.1. Moduły podstawowe (rdzeń: Zmiana → Zarobek → Wypłata ✅)

| Moduł | Zawartość |
| --- | --- |
| **Miejsca pracy i profile** | wiele miejsc, stanowiska, własne ustawienia rozliczeń każdego miejsca ✅, profil branżowy lub własny |
| **Grafik** | tydzień/miesiąc, szablony, kopiowanie, planowanie zbiorcze, kolizje czasowe, nieobecności |
| **Zmiana** | plan i fakt, timer, przerwy, status, notatki, szczegóły zmiany |
| **Zarobki** | wynagrodzenie bazowe i dodatki, napiwki, tip-out, utarg, kontrola kasy, korekty |
| **Wypłaty** | wypłaty, zaliczki, częściowe wypłaty, uzgodnienie |
| **Okresy** | zamknięcie z migawką ✅, korekty, raport i dowód godzin |
| **Centrum kontroli danych** | brakujące wpisy i stawki, niespójności, błędy importu, stare kopie |
| **Dashboard adaptacyjny** | automatyczny układ i personalizacja ✅ |
| **Dane i bezpieczeństwo** | backup, restore, eksport, blokada aplikacji |
| **Przypomnienia** | gotowe przypomnienia zamiast edytora reguł ✅ |

## B.2. Moduły dodatkowe (po rdzeniu)

- **Money lite** ✅ jako rozszerzenie: cele, Safe-to-Spend, rachunki i zobowiązania, proste wydatki. Bez kopert budżetowych i kont w pierwszej wersji. Aktywowany w ustawieniach ✅ (decyzja 3.1/4), nigdy domyślnie.
- **Analityka i prognozy** (deterministyczne).
- **Widgety i szybkie akcje** (kafelek „Start/Koniec zmiany”, skróty aplikacji).
- **Eksport do kalendarza** (jednokierunkowy) i raporty PDF/CSV.
- **Import przez udostępnianie Androida** (tekst i obrazy z komunikatorów).
- **OCR** grafików, pasków wynagrodzeń i paragonów.
- **Pamięć asystenta i głos** (sekcja D).

## B.3. Funkcje branżowe i profile

🔷 **Wspólny rdzeń + „profil miejsca pracy” zbudowany ze składników.** Profil to nie gałąź kodu, tylko zestaw włączonych składników rozliczenia, szablonów zmian i domyślnych ustawień.

- **Gastronomia (pierwszy priorytet ✅):** napiwki gotówkowe i kartowe, napiwki zespołowe (pula), tip-out (do baru/kuchni; jako procent napiwków, procent utargu albo kwota; odbiorca i sposób rozliczenia, F.1), różne stanowiska. **Rozdzielone semantycznie ✅ (decyzja 3.1/14):** opcjonalny „podatek od napiwków kartą” i inne potrącenia to składniki rozliczenia (wartość deklarowana przez użytkownika; RITMO nie ocenia jej poprawności), a *utarg i kontrola kasy* należą do raportu zmiany (`ShiftReport`) i nie są automatycznie zarobkiem pracownika.
- **Ogólny zmianowy ✅ (profil startowy):** stawka godzinowa lub za zmianę, dodatki (noc, weekend, święta, nadgodziny), premie, potrącenia.
- **Własny profil ✅ (kierunek):** użytkownik składa miejsce pracy z katalogu składników. To odpowiedź na „elastyczne, ale kontrolowane” (decyzja 15).
- **Handel detaliczny ✅ jako pierwsza dodatkowa branża testowa (decyzja 3.1/11):** to test uniwersalności wspólnego modelu, nie kompletny moduł handlowy. 🔷 Kryterium: profil handlu da się skonfigurować wyłącznie z istniejących składników i szablonów, bez zmian w kodzie domenowym; jeśli wymaga zmian, wspólny model jest za wąski. Walidacja z prawdziwym użytkownikiem z handlu przed M8. Kolejne branże (opieka, logistyka) dopiero po tym teście.

🔷 **Reguła trzech:** nie budujemy ogólnego silnika profili na zapas. Najpierw działa Gastronomia i „Ogólny”, abstrakcję zaostrzamy po trzecim realnym przypadku.

## B.4. Funkcje AI i integracje

- Asystent w osobnej zakładce i kontekstowo, tekst i głos, dokumenty, planowanie, zatwierdzane zadania (szczegóły w D).
- Integracje: udostępnianie do RITMO, kalendarz (eksport), widgety, powiadomienia, kafelek i skróty, lokalny OCR.

## B.5. Czego nie robimy teraz

- ✅ Integracja bankowa AIS.
- ✅ Uniwersalny edytor WHEN/IF/THEN. 🔷 Wbudowane przypomienia z parametrami dają większość wartości.
- 🚫 Geofencing na obecnym etapie. 🔷 Zamiast tego pytanie „Zaczynasz zmianę?” o planowanej godzinie.
- 🚫 Własne obliczanie netto i podatków ✅.
- 🚫 Pełny budżet kopertowy i wiele kont w pierwszej wersji.
- 🚫 Synchronizacja w chmurze zarządzana przez RITMO w v1 (backup jako plik, który użytkownik sam przechowuje).
- 🚫 Asystent działający w tle i zmieniający dane bez wiedzy użytkownika.
- 🚫 Wear OS i wiele urządzeń w v1.

---

# C. Architektura techniczna

## C.1. Zasady

- ✅ Ewolucja istniejącego Fluttera, bez masowej migracji technologicznej.
- ✅ Trwały `android/`, przypięta wersja Flutter, testy i analiza blokują CI. 🔷 Rozdzielone workflow *debug* i *release*; release wymaga prawdziwego klucza.
- ✅ Nowe narzędzia tylko z konkretnym uzasadnieniem, nigdy hurtem.
- 🔷 **Metoda „strangler”:** nowa struktura powstaje obok starej. Ekrany przenosimy do niej wtedy, gdy i tak je zmieniamy. Żaden etap nie jest tylko przenoszeniem plików.

## C.2. Warstwy

1. **`domain/`** — czysty Dart bez Fluttera: `Money`, czas zmiany i DST, stawki i składniki, kalkulator zarobków, okresy i zamknięcia, prognozy, walidacja. Najlepiej testowana część.
2. **`application/`** — **Action Layer**: zapytania (*Query*) i polecenia (*Command*). To jedyne API używane przez interfejs, asystenta, głos, powiadomienia, widgety i przypomnienia.
3. **`data/`** — repozytoria (interfejsy po stronie domeny), SQLite, migracje, backup/restore, importy.
4. **`platform/`** — natywny Android: powiadomienia, widgety, kafelek, udostępnianie, mowa, uwierzytelnianie.
5. **`ui/`** — ekrany według funkcji i design system.
6. **`ai/`** — dostawcy, rejestr narzędzi, orkiestrator, pamięć, zasady bezpieczeństwa.

🔷 **Dlaczego Action Layer jest kluczowy:** jedna definicja operacji (np. `AddTips`) ma walidację, podgląd zmian (*Proposal*), zapis w transakcji, wpis audytu i token cofnięcia. Przycisk, polecenie głosowe i asystent wywołują to samo. Dzięki temu AI nie ma osobnej drogi do danych, a wszystkie operacje są testowalne w jednym miejscu. Koszt: trzeba pisać polecenia zamiast wołać `store.addTip` z ekranu. Opłaca się od pierwszego polecenia, bo `StartShift` i `EndShift` będą używane z kafelka, powiadomienia i głosu.

## C.3. Stan i nawigacja

- Teraz zostaje `ChangeNotifier`. 🔷 Rozbijamy 18-KB `Store` na kontrolery i repozytoria przy okazji kolejnych funkcji.
- ❓ **Riverpod:** bramka decyzyjna ✅ (decyzja 3.1/8): wprowadzamy tylko wtedy, gdy konkretny moduł rzeczywiście uzasadni taką potrzebę (wspólny reaktywny stan) (kandydat: Dashboard v2 lub AI Workspace). Zasada: jeden mechanizm na moduł, bez mieszania w jednym ekranie ✅.
- 🚫 `go_router` na razie. `Navigator` i cztery–pięć zakładek wystarczają. Wracamy do tematu, gdy głębokie linki z widgetów lub powiadomień naprawdę tego wymagają.
- 🚫 Freezed. 🔷 Zamiast tego rekordy i `sealed` z Darta 3 oraz mały typ `Money` (extension type).

## C.4. Baza i migracje

- ✅ `sqflite` pozostaje domyślnie. ❓ **Drift:** PoC na kopii istniejącej bazy z jasnymi kryteriami: (a) czy typowane zapytania usuwają realne błędy, (b) czy generowane testy migracji są prostsze, (c) wpływ `build_runner` na czas CI i proces pracy, (d) koszt przepisania warstwy `data/`. Decyzja na końcu M1 🔬 (bramka, decyzja 3.1/8). Kryterium dodatkowe (e): Drift musi przejąć schemat wprowadzony w M1 bez zmian i bez utraty danych, bo migracje M1 powstają w sqflite. Jeśli korzyść nie jest wyraźna, zostajemy przy sqflite z typowanymi obiektami dostępu do danych.
- 🔷 Migracje: każda wersja schematu w osobnym pliku, **tylko addytywne** (dodajemy, nie niszczymy), z **automatyczną kopią pliku bazy przed migracją**. Testy na prawdziwych plikach baz v1–v4, odtworzonych z historii repozytorium.
- 🔷 Ustawienia przenosimy do tabeli `settings` w bazie. Wtedy restore jest atomowy, a SharedPreferences zostaje tylko dla stanu czysto lokalnego (np. skrót ostatnio użytych godzin).
- 🔷 Ograniczenia w bazie: `CHECK` (kwoty ≥ 0 tam, gdzie to sens, minuty 0–1439), `UNIQUE` na `shifts.tip_id`, indeksy na datach, klucze obce, `source + external_id` pod idempotentny import, `uuid` w nowych tabelach.

## C.5. Model danych: najprostszy poprawny

### Porównanie: Shift i WorkSession (decyzja 12)

| Opcja | Opis |
| --- | --- |
| **A** | `Shift` zawiera plan i fakt (pola `planned_*` oraz `actual_*`) |
| **B** | `Shift` (plan) + osobne `WorkSession` (fakt), relacja 1:N |
| **C** | `Shift` jako „dzień pracy” z opcjonalnym planem i opcjonalnym faktem; zmiana bez planu jest dozwolona |

| Scenariusz | A | B | C |
| --- | --- | --- | --- |
| Plan wykonany zgodnie z planem | prosto | prosto | prosto |
| Przyszedłem później, wyszedłem wcześniej | prosto | prosto | prosto |
| Zmiana dodatkowa bez planu | wymaga pustego planu | osobna sesja bez zmiany | prosto |
| Zmiana przerwana i wznowiona | przerwy | wiele sesji | przerwy |
| Zmiana rozdzielona (lunch + kolacja) | dwie zmiany | dwie sesje albo dwie zmiany | dwie zmiany (tak jak dziś) |
| Plan odwołany lub choroba | status | status | status |
| Przez północ i DST | jedno miejsce | dwa miejsca | jedno miejsce |
| Migracja obecnych danych | trywialna | złożona | trywialna |
| Kolizje i kopiowanie tygodnia | jeden typ | dwa typy | jeden typ |

✅ **Zatwierdzona opcja C (decyzja 3.1/1).** `Shift` ma opcjonalny plan i opcjonalny fakt; zmiana bez planu jest dozwolona; osobna encja `WorkSession` nie istnieje. Tabela powyżej zostaje jako uzasadnienie. 🔷 `WorkSession` wraca wyłącznie wtedy, gdy analiza ujawni rzeczywisty, nieobsługiwany scenariusz; wtedy `actual_*` można przenieść do tabeli sesji bez zmiany reszty modelu. Wielokrotne przerwy w jednej zmianie obsługuje `Break` (C.6b), a rozdzielone zmiany to nadal dwie zmiany.

### Encje (docelowo)

- **Workplace** (+ ustawienia rozliczeń, wersjonowane od daty) ✅ własne ustawienia każdego miejsca; **`timezone_id`** (identyfikator strefy IANA, domyślnie strefa telefonu w chwili utworzenia).
- **Position** (opcjonalne stanowisko w miejscu pracy).
- **WageRate**: miejsce, stanowisko, `valid_from`, rodzaj (godzinowa/za zmianę), kwota. Nowa stawka to nowy wiersz od daty; wiersze nie są edytowane wstecz. Zmiana stawki nigdy nie zmienia przeszłości.
- **Shift**: miejsce, stanowisko, `timezone_id` (kopiowany z miejsca pracy przy tworzeniu), data, `planned_start/end` (lokalna data i minuty w strefie zmiany; opcjonalne), `actual_start`/`actual_end` (UTC; opcjonalne), status (`planned`, `inProgress`, `completed`, `cancelled`), `earnings_confirmed_at`, **`time_model`** (`legacy` dla zmian sprzed migracji, `instants` dla nowych; C.6c), **`review_status`** (`ok` lub `needs_review`), notatka.
- **Break** (wiele na zmianę): `start_at`, `end_at` (UTC; pusty koniec oznacza przerwę w toku), `paid`.
- **Tip** (dzisiejsza tabela zostaje ✅, decyzja 3.1/3; `Tip.sales` jest od M2 tylko lustrem legacy, C.5a) + **EarningLine** (nowe składniki: premie, dodatki, potrącenia, korekty; pola klasyfikacji z F.1). Kalkulator sumuje oba źródła. Nie robimy przedwczesnej migracji wszystkiego do jednej księgi ✅.
- **ShiftReport**: **jedyne kanoniczne miejsce** danych raportowych zmiany (utarg, gotówka do rozliczenia z pracodawcą, kontrola kasy, pola przyszłe); to nie są kwoty zarobku. Należy do zmiany albo, dla historycznych wpisów `Tip` bez zmiany, do wpisu (C.5a).
- **Payout** (rzeczywisty przepływ pieniędzy od pracodawcy, pełna kwota) + **PayoutAllocation** (przypisanie części wypłaty do okresu lub grupy składników; nie jest drugim przepływem; F.6) oraz Offset (kompensacja napiwków kartowych z utargiem gotówkowym: operacja rozliczenia z pracodawcą, która nie jest wypłatą; F.2b).
- **PeriodClosure** (nagłówek: miejsce, zakres, czas zamknięcia, wersja kalkulatora, skróty danych) + **ClosureItem** (kopia danych wejściowych każdej zmiany, w tym kompensacji i pól raportu, oraz obliczone linie) + **ClosureRules** (kopia reguł użytych w obliczeniu) + **Adjustment** (F.5, F.5a).
- **AuditEntry**: tylko dla operacji finansowych po fakcie (zamknięcia, korekty, wypłaty i alokacje, stawki i profile, migracje, operacje asystenta).
- **AiThread** i **AiMessage** (historia rozmów) oraz **AiMemory** (pamięć profilu) jako odrębne tabele ✅ (decyzja 3.1/7; D.5).
- **Settings**, **ImportRecord** (źródło, hash, status), a później **Goal**, **Bill**, **Expense**, **BalanceAnchor** (ręczne saldo do Safe-to-Spend, F.9).

🔷 **`earnings_confirmed_at`** rozwiązuje ukryty problem dzisiejszej aplikacji: odróżnia „brak napiwków” od „jeszcze nie wpisałem”. Użytkownik zatwierdza „wszystko wpisane” jednym dotknięciem (także z wartością zero). Centrum kontroli danych pokazuje tylko niepotwierdzone zmiany.

🔷 **Stan rozliczenia zmiany jest wyliczany**, a nie przechowywany (brak wpisu / wpisano / potwierdzono / w zamkniętym okresie). Mniej pól oznacza mniej rozjazdów.

🔷 **Zamiast `Settlement` jako encji:** zamknięcie okresu z migawką i korektami (F.5). Obejmuje to potrzebę „zamknięcia i późniejszych korekt” (decyzja 13; doprecyzowana w 3.1/2: niezmienna migawka i korekty, bez ponownego otwierania okresów, także w krótkim oknie) bez trzeciej, pośredniej encji.

## C.5a. ShiftReport i Tip.sales: jedno źródło prawdy

🔷 Te same dane nie mogą być przechowywane niezależnie w dwóch miejscach. Model kanoniczny:

1. **Jedno miejsce zapisu:** po M2 `ShiftReport.sales` jest jedynym źródłem utargu. `Tip.sales` zostaje fizycznie w tabeli (zgodność ze starszymi rekordami i kopiami), ale jest **polem tylko do odczytu (lustro legacy)**: nowy kod nigdy go nie zapisuje (reguła jednego zapisującego), a odczyty idą przez `ShiftReport`. Do M2 `Tip.sales` pozostaje jedynym magazynem, więc nie ma duplikacji.
2. **Powiązanie raportu ze zmianą:** `ShiftReport` należy do `Shift` (zmiana ma co najwyżej jeden raport). Dla historycznych wpisów `Tip` bez zmiany migracja tworzy raport powiązany z wpisem (`legacy_tip_id`), z datą i miejscem pracy wpisu. Każdy raport ma więc dokładnie jednego właściciela (`shift_id` albo `legacy_tip_id`).
3. **Migracja (M2, addytywna):** dla każdego `Tip` z niepustym `sales` powstaje `ShiftReport.sales` ze źródłem `legacy_tip`. Nie zakładamy kompletności historycznych rekordów: rekordy bez danych zostają bez raportu. 🔬 Jeśli audyt wykaże, że 0 jest domyślnym zapisem „brak danych”, trafia jako wartość nieznana; w przeciwnym razie wartość zostaje zachowana dosłownie.
4. **Zgodność:** import kopii v1 i v2 mapuje `sales` do `ShiftReport`; eksport w formacie zgodnym ze starszą wersją wypełnia `sales` z `ShiftReport`; nowy format zapisuje raporty jako osobną sekcję.
5. **Weryfikacja:** po migracji dla każdego `Tip` z niepustym `sales` istnieje raport o tej samej wartości; test architektury potwierdza, że żadna ścieżka zapisu nie dotyka `Tip.sales`.
6. **Rozszerzalność:** stałe kolumny dla znanych pól (utarg, gotówka do rozliczenia z pracodawcą przed kompensacją, gotówka policzona, gotówka oczekiwana) oraz pole `extras` z numerem schematu na dane przyszłe. Dane raportowe nigdy nie wchodzą do zarobku. Gdy podstawą tip-outu jest procent utargu, a utargu brak, kalkulator zgłasza ostrzeżenie zamiast przyjmować zero.
7. 🔬 **Wymaga potwierdzenia przed M2:** znaczenie i dopuszczalność wartości pustej w `Tip.sales`, miejsca jego użycia w kodzie (statystyki, CSV, kopia zapasowa) oraz pola kontroli kasy (specyfikacja właściciela, sekcja I).

## C.6. Warstwa domenowa i kalkulator

- `Money` (extension type na `int`, grosze). Brak `double` w finansach ✅. Czas pracy w minutach całkowitych, liczony z różnicy znaczników czasu (C.6a), nigdy z różnicy godzin lokalnych zapisanych jako tekst.
- **Czas:** pełny model w C.6a (strefa IANA, godziny niejednoznaczne i nieistniejące, testy niezależne od strefy maszyny) i C.6b (cykl życia zmiany, przerwy, timer).
- **RateResolver** (stawka po dacie i stanowisku), **ComponentRules** (składniki z kanałem i podmiotem, F.1–F.2), **TipOutRules**, **Calculator**.
- **Wynik kalkulatora to drzewo z wyjaśnieniem** (każda kwota ma wzór, dane wejściowe i identyfikator reguły). Ekran „skąd ta kwota”, raport i asystent korzystają z tego samego wyniku.
- **Zaokrąglenie:** zasada jawna, np. do grosza na poziomie linii, suma dokładna. Wersja kalkulatora (`calc_version`) trafia do migawek.
- 🚫 Podatki i netto: zgodnie z decyzją 16 nie liczymy. 🔷 Dopuszczamy tylko ręcznie wpisany współczynnik lub kwotę „szacunkowych potrąceń” per miejsce pracy, zawsze oznaczoną jako szacunek użytkownika.

## C.6a. Model czasu: strefy, DST i znaczniki czasu

🔷 Rzeczywisty czas pracy jest zawsze liczony z różnicy dwóch znaczników czasu (UTC). Model jest minimalny: jeden identyfikator strefy i jedna funkcja zamiany czasu lokalnego na znacznik.

1. **Co jest zapisane.** Plan: lokalna data, minuty od północy i nominalny czas trwania w strefie `timezone_id` zmiany. Fakt: `actual_start`, `actual_end` oraz `Break.start_at/end_at` jako UTC. `timezone_id` (IANA, np. Europe/Warsaw) należy do miejsca pracy i jest kopiowany do zmiany przy jej utworzeniu, więc zmiana strefy telefonu ani miejsca pracy nie przepisuje historii.
2. **Interpretacja czasu lokalnego.** Godziny planu są godzinami ściennymi w strefie zmiany. Jedna funkcja `resolveLocal(date, minutes, zone)` zwraca znacznik UTC oraz status `ok`, `ambiguous` lub `nonexistent`. Koniec planu to początek plus nominalny czas trwania w czasie ściennym, więc zmiana 22:00–06:00 w nocy zmiany czasu trwa wiosną o godzinę krócej, a jesienią o godzinę dłużej. Do obliczeń zawsze służy różnica znaczników.
3. **Godzina niejednoznaczna (powtarza się jesienią).** Domyślnie pierwsze wystąpienie (wcześniejszy offset); formularz oznacza sytuację i pozwala wybrać drugie. Dla faktu niejednoznaczności nie ma, bo znacznik jest w UTC.
4. **Godzina nieistniejąca (brakuje jej wiosną).** Plan jest przesuwany na pierwszą istniejącą chwilę po luce, z ostrzeżeniem w formularzu.
5. **Okna czasowe składników (noc, weekend, święta).** Rzeczywisty przedział jest dzielony na segmenty według północy i granic okien liczonych w strefie zmiany; święto rozpoznaje data lokalna w tej strefie.
6. **Wyświetlanie.** Godziny pokazujemy w strefie zmiany, z plakietką, gdy różni się od strefy telefonu. Zmiana strefy telefonu w trakcie zmiany ani po niej nie zmienia zapisanych znaczników ani wyniku.
7. **Prostota.** Bez historii zmian stref miejsca pracy, bez stref per przerwa.

🔷 **Nowa zależność ✅ (decyzja 3.2/1; reguła 3 z raportu):** biblioteka bazy stref (`timezone`) i odczyt strefy urządzenia. Uzasadnienie: CI działa w UTC, a lokalny `DateTime` zależy od strefy maszyny, więc bez jawnej strefy nie da się napisać deterministycznych testów DST. Alternatywa bez zależności: wyłącznie strefa telefonu (prościej, ale bez tych testów i bez miejsca pracy w innej strefie). 🔬 Testy DST na wybranej bibliotece potwierdza PoC w M1.1.

**Testy obowiązkowe (blokujące CI, z wymuszoną strefą testową niezależną od maszyny):**

- przejście przez północ (22:00→06:00 w zwykłą noc: 8 h);
- wiosna, brakująca godzina: ta sama zmiana trwa 7 h;
- jesień, powtórzona godzina: ta sama zmiana trwa 9 h;
- plan zaczynający się w godzinie nieistniejącej i niejednoznacznej (wynik i status);
- segmentacja dodatku nocnego w nocy zmiany czasu;
- zmiana strefy urządzenia w trakcie zmiany i po niej;
- miejsce pracy w strefie innej niż strefa urządzenia;
- historyczne zmiany z nocy zmiany czasu po migracji zachowują dotychczasowe wartości i dostają status do weryfikacji (C.6c).

## C.6b. Cykl życia zmiany, przerwy i timer

✅ Opcja C bez `WorkSession`: zmiana ma stan, a przerwy są osobnymi interwałami.

1. **Stany:** `planned` → `inProgress` → `completed`; `cancelled` z `planned` lub `inProgress`. Przerwa nie jest stanem zmiany: zmiana jest na przerwie, gdy istnieje `Break` bez `end_at`.
2. **Polecenia (Action Layer):** `StartShift` (zapisuje `actual_start` i status `inProgress`, z planowanej zmiany albo jako zmiana bez planu), `StartBreak(paid)`, `ResumeShift` (ustawia `end_at` otwartej przerwy), `EndShift` (zamyka otwartą przerwę, zapisuje `actual_end`, status `completed`), `CancelShift`. Przerwanie to rozpoczęcie przerwy, wznowienie to jej zakończenie.
3. **Wiele przerw:** dowolnie wiele na zmianę, każda z początkiem, końcem i własną płatnością. Walidacja: wewnątrz przedziału zmiany, bez nakładania. Płatność domyślna pochodzi z profilu miejsca pracy i można ją zmienić. Czas płatny to czas od `actual_start` do `actual_end` minus przerwy niepłatne.
4. **Timer to zapisany `actual_start`, nie zegar interfejsu.** Wyświetlany czas to „teraz minus początek minus przerwy”, liczony przy każdym odświeżeniu; ticker tylko odświeża widok.
5. **Zapis natychmiastowy.** Każde polecenie to jedna transakcja zapisana od razu; stanu aktywnej zmiany nie ma wyłącznie w pamięci. Po awaryjnym zamknięciu aplikacji, zabiciu procesu lub restarcie telefonu aplikacja odczytuje zmianę `inProgress` z bazy i odtwarza ekran oraz powiadomienie.
6. **Zapomniana zmiana.** Gdy zmiana `inProgress` trwa nietypowo długo (próg domyślny 16 h 🔬), aplikacja pyta, czy trwa, i proponuje ustawienie końca. **Nigdy nie kończy zmiany sama.**
7. **Jedna aktywna zmiana naraz** (ograniczenie w bazie) ✅ (decyzja 3.2/2).
8. **Korekty.** Edycja początku, końca i przerw poza zamkniętym okresem to zwykła edycja z `updated_at`; po zamknięciu okresu przechodzi przez korektę (F.5).
9. **Zegar urządzenia.** Czas pochodzi z zegara systemowego; Centrum kontroli danych zgłasza wartości nietypowe (ujemny czas, ponad 24 h), a użytkownik zawsze może poprawić czasy ręcznie.

**Testy akceptacyjne:** zabicie procesu w trakcie zmiany i w trakcie przerwy, restart telefonu, wiele przerw płatnych i niepłatnych, `EndShift` z otwartą przerwą, zapomniana zmiana nie kończy się automatycznie, druga aktywna zmiana jest odrzucona.

## C.6c. Dane historyczne i zmiany czasu

✅ (decyzja 3.2/4) Nowy model czasu (C.6a) obowiązuje dla **nowych** zmian i przyszłych operacji. Historyczne zmiany nigdy nie są automatycznie przeliczane w sposób, który zmieniałby wcześniej zapisane wartości finansowe. Cztery obszary są rozdzielone:

1. **Interpretacja danych historycznych.** Zmiana zapisana w obecnej aplikacji ma datę, minutę startu i nominalny czas trwania, bez strefy. Zapisane wartości uznajemy za obowiązujące. Takie zmiany dostają `time_model = legacy`: czas płatny to dotychczasowy czas trwania, bez `actual_*` i bez liczenia ze znaczników. Strefa zapisana przy migracji (strefa telefonu) ma status „założona” i służy tylko do wykrywania niejednoznaczności.
2. **Migracja techniczna.** Wyłącznie addytywna: nowe kolumny i tabele, żadnej zmiany istniejących wartości. Dodatkowo skan wykrywa historyczne zmiany, których interpretacja czasu jest niejednoznaczna lub mogłaby dać inny wynik (zmiana obejmująca noc zmiany czasu w założonej strefie, nietypowy czas trwania). Takie rekordy zachowują wartości i dostają `review_status = needs_review`; lista trafia do `AuditEntry` (typ: migracja).
3. **Przyszłe obliczenia według nowego modelu.** Tylko zmiany z `time_model = instants`: czas liczony z różnicy znaczników (C.6a). Zmiana strefy telefonu, aktualizacja bazy stref lub zmiana reguł DST nie zmienia zapisanych znaczników UTC ani wyniku zakończonych zmian; zamknięte okresy chroni snapshot (F.5a).
4. **Ręczna korekta zatwierdzona przez użytkownika.** Centrum kontroli danych pokazuje zmiany `needs_review` z wartością zapisaną, wartością alternatywną i różnicą w złotych. Użytkownik wybiera „Zachowaj” (status wraca do `ok`) albo „Zastosuj korektę”. Korekta jest jawna i audytowalna: w okresie otwartym to edycja z `AuditEntry` (przed, po, powód, aktor), w okresie zamkniętym `Adjustment` (F.5). Nigdy nie jest stosowana po cichu ani automatycznie; zbiorcze zastosowanie jest możliwe wyłącznie po podglądzie wszystkich kwot i jawnym potwierdzeniu.

🔬 Liczba i charakter rekordów `needs_review` zależą od audytu obecnych danych i kodu (`Shift.durationMin`, przejścia przez północ); wynik nie jest jeszcze znany.

## C.7. Offline

- Cała logika, baza, grafik, rozliczenia, statystyki i przypomnienia działają bez internetu ✅.
- AI ma tryb deterministyczny, OCR ma ręczne wprowadzanie, import ma zapis lokalny. Nic nie czeka w kolejce na sieć.
- Dane z zewnątrz mają pochodzenie i datę.

## C.8. Bezpieczeństwo (trzy osobne tematy ✅)

1. **Blokada aplikacji ✅ (decyzja 3.1/9):** uwierzytelnianie urządzenia przez `local_auth` (biometria lub PIN/wzór telefonu), bo limit prób wymusza wtedy sprzęt. Własny PIN w aplikacji tylko jako opcja dla telefonów bez blokady ekranu i nazwany uczciwie ekranem prywatności. Powód: przy 4–6 cyfrach żaden KDF nie ochroni hasha po jego wycieku. Pełny przepływ blokady wchodzi w M0.
2. **Backup ✅:** szyfrowanie hasłem (AES-GCM, KDF o wysokim koszcie, bo to hasło, a nie PIN), z jasnym ostrzeżeniem, że zgubione hasło oznacza utraconą kopię. Walidacja przed restore, automatyczna kopia stanu przed przywróceniem, `integrity_check` po. Kopie to pliki zarządzane przez użytkownika, bez synchronizacji RITMO w v1 ✅ (decyzja 3.1/18). Wchodzi w M4.
3. **Szyfrowanie bazy 🔬 (decyzja 3.1/9: po analizie zagrożeń):** chroni głównie przed rootem i wyciekiem pliku, wymaga klucza w Keystore i migracji istniejącej bazy. Rozstrzygnięcie po analizie zagrożeń, najwcześniej przy M4.
4. **Android:** `allowBackup` i reguły eksportu danych (do sprawdzenia po zacommitowaniu `android/`), powiadomienia bez kwot na ekranie blokady, opcjonalnie ukrywanie zawartości w przełączniku aplikacji.
5. **AI:** minimalizacja danych, zgody per dostawca, dziennik wysłanych danych (D.4a); klucze dostawców w bezpiecznym magazynie, poza kopią zapasową.

## C.9. Android i integracje natywne

- Trwały `android/` jest warunkiem wszystkich poniższych.
- Powiadomienie aktywnej zmiany: trwałe powiadomienie z chronometrem na zapisanym `startedAt`. 🔷 Usługa pierwszoplanowa dopiero, jeśli testy wykażą realną potrzebę.
- Widget „Dziś”, kafelek szybkich ustawień, skróty aplikacji.
- Udostępnianie do RITMO (tekst i obrazy), eksport do kalendarza, mowa (SpeechRecognizer), OCR (ML Kit on-device), uwierzytelnianie.
- Mostek do natywnego kodu: małe, nazwane moduły (nie jeden duży). Każdy moduł ma interfejs po stronie Darta, żeby dało się go podmienić w testach.
- ❓ Minimalna wersja Androida i wspierane urządzenia (✅ roboczo API 26+, decyzja 3.1/10; 🔬 ostateczne potwierdzenie po testach kompatybilności i na urządzeniach).

## C.10. Ochrona istniejących danych i zgodność wsteczna

✅ Istniejące dane i funkcje mają pierwszeństwo przed nowymi.

- Kopie JSON v1 i v2 wczytują się zawsze. Nowy format zapisuje wersję schematu i opcjonalne szyfrowanie; import starszych wersji mapuje dane na nowe tabele (w tym `Tip.sales` do `ShiftReport`, C.5a). Testy na zapisanych kopiach z poprzednich wersji.
- Przed każdą migracją automatyczna kopia pliku bazy; migracje wyłącznie addytywne (C.4); `Tip` i jego kolumny zostają.
- Nie zmieniamy `applicationId`, nazwy pliku bazy ani kluczy SharedPreferences bez osobnej analizy i zgody. Ustawienia są przenoszone do bazy jednorazowo, a stare klucze zostają jako zapas na jedną wersję.
- `Tip.hours` pozostaje wyłącznie dla wpisów bez zmiany (zgodność); dla wpisu powiązanego ze zmianą liczą się godziny zmiany.
- **Dane historyczne i czas ✅ (decyzja 3.2/4):** historyczne zmiany nie są automatycznie przeliczane i zachowują dotychczasowe wartości finansowe. Zmiana strefy ani reguł DST nie zmienia wcześniejszych zarobków. Szczegóły w C.6c.
- **Bramka akceptacji migracji:** na kopii prawdziwej bazy z wersji 1.0 sumy zarobków, napiwków i godzin per okres są **identyczne** przed i po migracji, bez wyjątków. Rekordy o niejednoznacznej interpretacji czasu dostają status do weryfikacji, a ich wartości się nie zmieniają.
- 🔬 **Audyty przed migracją:** znaczenie i znak `Tip.tipOut` (migracja tego pola nie jest ustalana bez audytu, decyzja 3.2/5), znaczenie i dopuszczalność wartości pustej w `Tip.sales`, użycie `Tip.hours` i `Shift.durationMin`. Domyślny kanał napiwków kartą dla istniejących miejsc pracy (F.1) ustalany dopiero po tych audytach.

---

# D. RITMO AI

## D.1. Rola asystenta

✅ AI jest centralną funkcją produktu: osobna zakładka, użycie kontekstowe na ekranach, tekst i głos, analiza danych i dokumentów, planowanie i wykonywanie zatwierdzonych zadań. Asystent ma trzy tryby pracy:

- **Zapytaj** — odpowiada na pytania o pracę i pieniądze na podstawie danych z narzędzi.
- **Zrób** — przygotowuje operacje jako propozycje, które użytkownik zatwierdza.
- **Obserwuj** — wykrywa braki i nieprawidłowości (właściwa analiza jest deterministyczna, model językowy tylko je opowiada).

🔷 **Zasada nadrzędna:** model językowy jest *interfejsem do aplikacji*, a nie jej mózgiem finansowym. Wszystko, co musi być poprawne (kwoty, daty, sumy), wykonuje kod domenowy.

## D.2. Architektura

Przepływ każdego zapytania:

1. **UI** (AI Workspace, kontekstowe wejścia, głos, powiadomienia).
2. **Orkiestrator**: prowadzi rozmowę, dobiera narzędzia, pilnuje limitów i kosztów.
3. **Router dostawców**: wybiera tryb (brak AI / on-device / chmura) według zasad prywatności i dostępności.
4. **Rejestr narzędzi**: typowane narzędzia z opisem, schematem parametrów i klasą ryzyka.
5. **Action Layer** (C.2): zapytania i polecenia domenowe.
6. **Domena i dane**: kalkulator, repozytoria.

Obok: **Policy Engine** (klasy ryzyka i zgody), **Context Builder** (co trafia do modelu i w jakiej formie), **Pamięć**, **Dziennik i ślad** (jakie narzędzia wywołano i jakie dane wysłano).

✅ AI nie ma bezpośredniego dostępu do SQLite. 🔷 Nie ma też narzędzia „zapisz”: **model nie może zatwierdzać propozycji**. Zatwierdzenie jest zdarzeniem interfejsu użytkownika.

🔷 **Egzekwowanie (asystent nie może ominąć Action Layer ani zatwierdzić zapisu):** moduł `ai/` zależy wyłącznie od `application/` (zapytania i propozycje), a reguła zależności jest sprawdzana testem architektury w CI. Zastosowanie propozycji jest dostępne tylko z warstwy `ui/` i wymaga **tokenu zatwierdzenia** wystawianego przez zdarzenie użytkownika (dotknięcie, a dla klasy L1 także głosowe „tak”) i związanego z konkretną propozycją i sesją. Dzięki temu nawet błąd w orkiestratorze nie zapisze danych.

## D.3. Narzędzia

**Odczyt (R)** — zwracają dane ustrukturyzowane z oznaczeniem pochodzenia (*fakt / szacunek / prognoza*), identyfikatorami źródeł i wersją kalkulatora:

- `earnings_summary(range, workplace?)`, `compare_periods(a, b)`, `workplace_performance(range)`,
- `schedule(range)`, `forecast(range, scenario)`, `goal_status()`,
- `explain_payout_difference(workplace, period)` (deterministyczny rozkład różnicy na przyczyny),
- `find_data_issues()` (to samo, co Centrum kontroli danych), `search_entries(filters)`.

**Propozycje (P)** — tworzą obiekt *Proposal* (czytelny podgląd zmian, wynik walidacji, klasa ryzyka, ważność), nic nie zapisują:

- `propose_shift`, `propose_schedule(range)`, `propose_tips_entry`, `propose_expense`,
- `propose_period_closure`, `propose_payout`, `propose_rate_change`, `propose_correction`.

**Klasy ryzyka i zatwierdzanie** (✅ decyzja 20):

| Klasa | Przykład | Zatwierdzenie |
| --- | --- | --- |
| L0 odczyt | podsumowanie, porównanie | brak |
| L1 odwracalne, małe | plan zmiany, wpis napiwków do bieżącej zmiany | jedno dotknięcie; opcjonalne „szybkie zatwierdzanie” z cofnięciem |
| L2 finansowe | wypłata, zaliczka, wydatek, zamknięcie okresu, zmiana stawki | zawsze jawne zatwierdzenie z podglądem |
| L3 zmieniające historię | korekta zamkniętego okresu, usunięcie | zatwierdzenie z uzasadnieniem i wpisem audytu |
| L4 zakazane dla AI | przelewy i płatności, zmiana ustawień bezpieczeństwa i blokady, usuwanie kopii zapasowych, autonomiczne wysyłanie danych poza aplikację | niedostępne dla AI; zmiana tylko ręcznie przez użytkownika w ustawieniach |

**Dostępność narzędzi według etapów ✅ (decyzja 3.1/15):** *M2:* pierwsze narzędzia odczytu (`earnings_summary`, `schedule`) w trybie deterministycznym. *M3:* `compare_periods`, `workplace_performance`, `find_data_issues`, `search_entries` oraz propozycje `propose_shift`, `propose_schedule`, `propose_tips_entry`, `propose_rate_change`. *M4:* `explain_payout_difference`, `propose_period_closure`, `propose_payout`, `propose_correction`. *M6:* propozycje z importu dokumentów. *M7:* `forecast`, `goal_status`, `propose_expense`. Narzędzia zależne od danych, które jeszcze nie istnieją, nie są rejestrowane.

Dodatkowa propozycja od M4: `propose_card_tip_offset` (klasa L2) dla kompensacji napiwków kartowych z utargiem (F.2b). Wpis kompensacji przez użytkownika jest możliwy od M2, a wpływ na saldo pracodawcy i uzgodnienie od M4.

## D.3a. Cztery osie uprawnień: działanie AI, polecenie użytkownika, udostępnianie danych, operacje lokalne

✅ Model poziomów L0–L4 zostaje. Dodajemy rozdzielenie, które usuwa pozorną sprzeczność między „AI nie wysyła danych poza aplikację” a „użytkownik może skorzystać z zewnętrznego dostawcy”:

| Oś | Pytanie | Reguła |
| --- | --- | --- |
| 1. Inicjatywa | kto zaczyna działanie | **działanie autonomiczne AI** ogranicza się do odczytu (L0) i przygotowania propozycji; wszystko inne zaczyna się od **wyraźnego polecenia użytkownika** (tekst, głos, przycisk kontekstowy) |
| 2. Operacje na danych lokalnych | co zmienia się w aplikacji | klasy L0–L3; zapis zawsze przez propozycję i zatwierdzenie człowieka; **L4 jest niedostępne dla AI** |
| 3. Udostępnianie danych dostawcy zewnętrznemu | co opuszcza urządzenie | osobna skala S0–S3 (niżej); decyduje użytkownik, nigdy model |
| 4. Zatwierdzanie | kto przyjmuje skutki | wyłącznie człowiek, przez zdarzenie interfejsu (token zatwierdzenia, D.2); AI nie zatwierdza własnych operacji i nie omija Action Layer ani Policy Engine |

**Skala udostępniania danych dostawcy (S):**

| Poziom | Co wysyłamy | Kiedy |
| --- | --- | --- |
| S0 | nic (tryb deterministyczny lub on-device) | domyślnie, gdy dostawca nie jest włączony |
| S1 | zagregowane i pseudonimizowane wyniki narzędzi (sumy, średnie, nazwy miejsc jako aliasy) | domyślny poziom po włączeniu dostawcy; wystarcza do większości pytań |
| S2 | szczegółowe dane wskazane przez użytkownika (np. wybrane zmiany lub wpisy z okresu) | tylko po jawnym wyborze w podglądzie wysyłki, dla jednego polecenia |
| S3 | dokument lub obraz wskazany przez użytkownika | tylko po jawnym wyborze dla jednego dokumentu |

**Jak L4 współgra z udostępnianiem:** L4 dotyczy *działań AI*. AI nigdy samo nie wysyła danych poza aplikację, nie wybiera zakresu danych dla dostawcy i nie może podnieść poziomu S. Świadome udostępnienie danych przez użytkownika jest *działaniem użytkownika*, realizowanym przez deterministyczny **Data Gate** (część Context Buildera, nie model) według osi 3. Model otrzymuje tylko to, co Data Gate przepuści.

**Zasady obowiązujące ✅:**

1. AI nie decyduje samodzielnie o wysłaniu danych użytkownika do dostawcy zewnętrznego.
2. Użytkownik świadomie wybiera dane przekazywane modelowi (podgląd wysyłki z możliwością odznaczenia pozycji dla S2 i S3).
3. Zgoda na dostawcę obejmuje najwyżej S1 i nie oznacza zgody na wysłanie całej bazy; takiej opcji nie ma. S2 i S3 wymagają decyzji przy każdym poleceniu.
4. Dane są ograniczone do minimum niezbędnego do wykonania polecenia (narzędzia zwracają agregaty, Data Gate odrzuca nadmiar).
5. Domyślnie agregaty i pseudonimizacja, gdy wystarczają do zadania.
6. Każde wysłanie jest widoczne w `SentDataLog` (dostawca, poziom S, liczba i rodzaj pozycji, wątek, czas).
7. AI nie zatwierdza własnych operacji finansowych i nie omija Action Layer ani Policy Engine.
8. Użytkownik zachowuje kontrolę nad zatwierdzaniem operacji finansowych i zmian historycznych (L2, L3).

## D.4. Dostawcy i router

🔷 Interfejs `ModelProvider` z deklaracją możliwości (wywoływanie narzędzi, obraz, strumień, kontekst, lokalizacja: urządzenie lub chmura). Dostawcy:

1. **Brak AI (tryb deterministyczny).** Paleta poleceń, rozpoznawanie intencji regułami dla języka polskiego, analizy z szablonów. **Działa zawsze** i jest pierwszym dostawcą w kolejności prac.
2. **On-device (Gemini Nano przez ML Kit GenAI / AICore).** Opcjonalny akcelerator tam, gdzie dostępny. Ograniczenia: wąska lista urządzeń, wnioskowanie tylko przy aplikacji na pierwszym planie, limity zapytań i tokenów. 🔷 Dobry do prostych zadań (podsumowanie, klasyfikacja intencji), słaby jako jedyny silnik wieloetapowego wywoływania narzędzi. 🔬 Dostępność trzeba sprawdzić na urządzeniach właściciela w czasie PoC.
3. **Dostawca zewnętrzny (chmura) przez adapter.** ✅ BYOK (klucz podaje użytkownik, przechowywany bezpiecznie) może być pierwszym rozwiązaniem technicznym w prywatnej wersji, ale jest jednym z trybów dostępu, a nie jedyną docelową drogą (decyzja 3.1/5). Nigdy nie wbudowujemy klucza w APK. Dostęp zarządzany przez usługę RITMO jest przewidziany w architekturze (D.4a), bez budowania backendu i kont teraz.
4. 🚫 **Lokalne modele otwarte (LiteRT, llama.cpp)** teraz: ciężkie (setki MB–GB), słabszy język polski i wywoływanie narzędzi, bateria. Wracamy po PoC, jeśli pojawi się konkretny model i przypadek użycia.

**Router (domyślnie najpierw prywatność):** deterministyczny → on-device (jeśli dostępny) → chmura tylko po jawnej zgodzie dla danego dostawcy i klasy danych. W interfejsie widoczny znacznik trybu (*Offline*, *Na urządzeniu*, *Chmura*).

**Dane wysyłane do chmury (✅ użytkownik kontroluje):**

- domyślnie **wyniki narzędzi (zagregowane)**, nie surowa baza;
- opcja aliasowania nazw miejsc pracy;
- obrazy dokumentów tylko, gdy użytkownik sam to wybierze dla danego dokumentu;
- ekran „Co zostało wysłane” z historią per rozmowa.

## D.4a. Konfiguracja dostawców, dostęp zarządzany, koszty i zgody

✅ BYOK to pierwszy tryb dostępu, nie ograniczenie architektury (decyzja 3.1/5). Konfiguracja dostawcy jest odrębna od narzędzi domenowych, więc zmiana trybu dostępu nie dotyka Action Layer, rejestru narzędzi ani asystenta.

- **`ModelProvider` (adapter):** tłumaczy wspólny format zapytania i odpowiedzi (wiadomości, definicje narzędzi, wywołania narzędzi, strumień) na konkretne API i deklaruje możliwości. To jedyny kod, który zna szczegóły dostawcy.
- **`ProviderConfig` (konfiguracja):** tryb dostępu (`byok`, `onDevice`, `managed`, `none`), adres, nazwa modelu, limity, referencja do klucza lub tokenu. Przechowywana w bezpiecznym magazynie, poza kopią zapasową, osobno od narzędzi.
- **Orkiestrator, rejestr narzędzi, Policy Engine, Action Layer:** nie znają dostawcy ani trybu dostępu.
- 🔷 **Dostęp zarządzany w przyszłości** to kolejny adapter mówiący tym samym formatem do punktu końcowego RITMO. Zmienia się wyłącznie adapter i konfiguracja (token usługi zamiast klucza użytkownika). Nie projektujemy teraz backendu AI ani systemu kont ✅. Rezerwujemy tylko pole trybu dostępu, wspólny format, miejsce na token i limity oraz wymóg odrębnej zgody (dane opuszczają wtedy urządzenie dwa razy: do usługi RITMO i do dostawcy modelu).
- **Klucze ✅:** w aplikacji mobilnej nie umieszczamy kluczy API dostawcy. BYOK przechowuje klucz użytkownika w magazynie systemowym, poza kopią. Dostęp zarządzany wymaga w przyszłości serwera pośredniczącego, który trzyma klucze dostawcy po swojej stronie.
- **Kontrola kosztów:** miesięczny limit na dostawcę (w tokenach lub w kwocie według ceny podanej przez użytkownika), limit na zapytanie i na rozmowę, widoczne zużycie, twardy stop po przekroczeniu z automatycznym przejściem w tryb deterministyczny. Główna dźwignia kosztu: wysyłamy zagregowane wyniki narzędzi, nie surowe wiersze.
- **Zgoda i dane ✅ (decyzja 3.1/6, osie w D.3a):** domyślnie poziom S1. Zgoda per dostawca obejmuje najwyżej S1, a S2 i S3 wymagają decyzji przy każdym poleceniu. **`SentDataLog`**: dla każdego zapytania dostawca, tryb dostępu, poziom S, nazwy narzędzi, liczba i rodzaj pozycji, rozmiar, czas i wątek; treść zapytania zapisywana tylko, gdy użytkownik to włączy. Użytkownik może przeglądać i czyścić dziennik.
- **Bez dostawcy ✅:** wszystkie funkcje aplikacji i tryb deterministyczny asystenta działają bez dostawcy zewnętrznego; brak klucza, limitu lub sieci blokuje tylko odpowiedzi generatywne.
- **Odroczone do M8 ✅ (decyzja 3.2/16):** ostateczny wybór między BYOK a modelem zarządzanym oraz kolejni dostawcy. Abstrakcja `ModelProvider` zachowuje możliwość wszystkich trzech dróg (BYOK, zarządzany, brak AI).

## D.5. Pamięć asystenta

✅ Użytkownik kontroluje pamięć i dane udostępniane modelom.

Cztery warstwy kontekstu mają różne źródło, czas życia i reguły:

| Warstwa | Co zawiera | Gdzie i jak długo | W kopii zapasowej | Do dostawcy |
| --- | --- | --- | --- | --- |
| Kontekst sesji | bieżące wiadomości i wyniki narzędzi użyte w tej rozmowie, składane przez Context Builder | w pamięci i w wątku do końca rozmowy | nie | tylko wybrane agregaty, za zgodą |
| Historia rozmów | wątki i wiadomości (odpowiedzi tak, jak widział je użytkownik, ze znacznikiem „stan na DATA”) | lokalnie; do usunięcia pojedynczo, zbiorczo lub automatycznie | domyślnie nie | tylko bieżący wątek jako kontekst |
| Pamięć profilu | krótkie fakty i preferencje, bez kwot | lokalnie, widoczna i edytowalna | domyślnie nie | tylko włączone wpisy i tylko za zgodą |
| Dane bieżące | kwoty, godziny, terminy z Action Layer | nie są przechowywane przez AI; pobierane przy każdym pytaniu | nie dotyczy | tylko zagregowane wyniki narzędzi, za zgodą |

- **Historia rozmów jest odrębnym elementem AI Workspace ✅:** lista wątków, otwieranie, wyszukiwanie, usuwanie jednego wątku, wszystkich albo automatyczne po N dniach (✅ domyślnie 90 dni, z możliwością wyłączenia historii; decyzja 3.2/8), tryb „bez zapisywania historii”. Wiadomość zapisuje odpowiedź tak, jak ją widział użytkownik, ze znacznikiem „stan na DATA”, więc stare kwoty nie udają aktualnych.
- **Pamięć profilu ✅:** krótkie fakty i preferencje (np. format godzin, w jakich miejscach pracuje). Każdy wpis ma treść, kategorię, źródło (wpisany przez użytkownika albo zaproponowany i zatwierdzony), datę i przełącznik. Asystent może tylko *zaproponować* zapamiętanie, nigdy nie zapisuje po cichu.
- **Pamięć nie zawiera kwot finansowych ✅.** Kwoty zawsze pochodzą z Action Layer, więc nie mogą się zestarzeć; zapis wpisu z kwotą jest odrzucany.
- **Niezależna kontrola ✅:** przeglądanie, edycja i usuwanie historii rozmów oraz zarządzanie pamięcią to odrębne widoki i operacje; usunięcie jednego nie usuwa drugiego. Osobno „wyczyść wszystko” z potwierdzeniem.
- **Domyślnie poza kopią zapasową i poza chmurą ✅.** Włączenie w kopii wymaga jawnego wyboru; do dostawcy trafia tylko to, co opisuje D.4a.
- 🚫 Wyszukiwanie semantyczne (embeddingi) po wszystkich wpisach w v1. Dodaje złożoność i ryzyko prywatności, a narzędzia filtrujące wystarczają na realne pytania.

## D.6. Głos

1. **Rozpoznawanie mowy:** Android SpeechRecognizer, tryb lokalny, gdy dostępny na urządzeniu.
2. **Polecenia zamknięte** (start/koniec zmiany, przerwa, dodaj napiwki, dodaj wydatek, zapytania) obsługuje **deterministyczny parser** z polskimi liczbami i datami. Działa offline i jest przewidywalny.
3. Gdy parser nie rozpozna intencji, a użytkownik zezwoli, przekazujemy tekst do modelu.
4. Wynik zawsze trafia do **podglądu z odczytem** („Dodać 120 zł napiwków kartą do dzisiejszej zmiany w X?”). Zatwierdzenie dotknięciem lub głosowym „tak” tylko dla klasy L1. Klasy L2 i wyższe wymagają dotknięcia po odblokowaniu telefonu.
5. Odpowiedzi mogą być czytane na głos (opcjonalnie).

## D.7. OCR i analiza dokumentów

Potok wspólny dla grafików, pasków wynagrodzeń i paragonów:

1. **Przechwycenie:** aparat, galeria, udostępnianie z innej aplikacji.
2. **OCR na urządzeniu** (ML Kit, tekst i układ bloków).
3. **Parser dokumentu:** reguły i szablony dla znanych formatów, wyszukiwanie dat i kwot.
4. Opcjonalnie **ekstrakcja przez model** (on-device lub chmura za zgodą), która zwraca kandydatów pól z poziomem pewności.
5. **Walidacja domenowa:** daty w sensownym zakresie, brutto minus potrącenia równa się netto, godziny wiarygodne, konflikty z grafikiem.
6. **Ekran weryfikacji:** obraz obok pól, niepewne pola wyróżnione, ręczna korekta.
7. **Propozycje** zatwierdzane jak każde inne (lista z przełącznikami per pozycja).
8. **ImportRecord** z hashem dokumentu: ponowny import nie tworzy duplikatów.

Kolejność i realizm:

- **Kolejność ✅ (decyzja 3.1/16):** (1) import grafiku z udostępnionego tekstu (wiadomość z komunikatora), (2) OCR jednego ustalonego formatu grafiku, (3) pasek wynagrodzenia, (4) paragony na końcu. Wszystko w M6, z wyjątkiem paragonów (M7).
- **Grafik:** użytkownik raz wskazuje swoje imię lub wiersz, a układ jest zapamiętywany per miejsce pracy. Ogólny OCR dowolnych tabel to najtrudniejszy przypadek i nie jest celem v1.
- **Pasek wynagrodzenia:** służy do uzgodnienia należnego z wypłaconym (wymaga M4). RITMO nie ocenia prawidłowości podatków ✅.
- Dokumenty to **dane, nie polecenia**: tekst z OCR nie może wydawać instrukcji asystentowi (ochrona przed *prompt injection*).
- Zachowanie: opcja usunięcia obrazu po imporcie, domyślnie prywatny katalog aplikacji, brak w kopii, chyba że użytkownik wybierze.

## D.8. Zatwierdzanie operacji

- **Karta propozycji:** co się zmieni (przed → po), źródło (głos, dokument, pytanie), ostrzeżenia z walidacji, klasa ryzyka.
- Przyciski: **Zatwierdź**, **Edytuj**, **Odrzuć**. To przykład przycisków w pełni uzasadnionych zasadą z A.5.
- Pakiety (np. 12 zmian grafiku): przełączniki per pozycja i jedno zatwierdzenie.
- Po zatwierdzeniu: okno cofnięcia, wpis audytu z aktorem „AI” lub „głos”.
- **Skrzynka zatwierdzeń** w AI Workspace zbiera oczekujące propozycje (mają ważność czasową).

## D.9. Ograniczenia, fallback i ochrona przed błędami

- 🔷 **Liczby związane ze źródłem:** model pisze tekst z tokenami odwołań (np. `{{earnings.total}}`), a aplikacja podstawia wartości z wyniku narzędzia. Model nie może „wymyślić” kwoty. To najskuteczniejsze zabezpieczenie przed halucynacjami liczbowymi i niedrogie.
- Odpowiedzi oznaczone: **Fakt**, **Szacunek**, **Prognoza**. Gdy danych jest za mało, asystent mówi to wprost („masz 3 zmiany, za mało na prognozę”).
- Brak dostawcy lub internetu: asystent przechodzi w tryb deterministyczny i pokazuje to w interfejsie. Wszystkie funkcje aplikacji nadal działają.
- Limity kosztów i liczby wywołań dla chmury, widoczne zużycie.
- Testy jakości: **zestaw pytań kontrolnych na bazie testowej** uruchamiany przy zmianie dostawcy lub promptu (poprawność użycia narzędzi i brak zmyślonych liczb).

## D.10. Co AI robi w praktyce

| Zastosowanie | Jak działa |
| --- | --- |
| Analiza zarobków i napiwków | `earnings_summary` + wyjaśnienie z liczbami z odwołań |
| Porównanie miejsc pracy | `workplace_performance`, ranking na godzinę |
| Wyjaśnienie różnic w wypłatach | `explain_payout_difference` (deterministyczne), model opowiada |
| Planowanie grafiku | propozycja pakietu zmian z szablonów i dotychczasowych wzorców |
| Przygotowanie rozliczeń | `propose_period_closure` po sprawdzeniu danych |
| Dodawanie wydatków i napiwków | głos lub tekst → propozycja → zatwierdzenie |
| Dokumenty | OCR → walidacja → propozycje |
| Nieprawidłowości | wykrywanie deterministyczne, AI tłumaczy i proponuje poprawkę |
| Pytania naturalne | dobór narzędzi i odpowiedź ze źródłami |

**Dostępność według etapów ✅ (decyzja 3.1/15):** wiersze „Wyjaśnienie różnic w wypłatach” i „Przygotowanie rozliczeń” (zamknięcia okresu) działają dopiero od M4. M3 obejmuje pozostałe: analizę grafiku, zarobków, napiwków i jakości danych oraz propozycje działań.

## D.11. Kolejność wdrażania AI

🔷 Zakładka asystenta i **paleta poleceń działają od pierwszego etapu (M1)**, bo opierają się na Action Layer i nie wymagają modelu. Model językowy dołącza w **M3** ✅ (decyzja 3.1/15) i obejmuje analizę grafiku, zarobków, napiwków i jakości danych oraz propozycje działań. **M4** rozszerza asystenta o uzgadnianie wypłat, wyjaśnianie różnic i zamknięcia okresów, bo dopiero wtedy istnieją wypłaty i migawki. Każdy etap dodaje narzędzia razem z funkcją, którą obsługują.

---

# E. UX/UI

## E.1. Nawigacja

✅ Pięć pozycji (decyzja 3.1/4), bo AI jest centralne:

1. **Dziś** (Dashboard)
2. **Grafik**
3. **Pieniądze** (Zarobki, Wypłaty, Okresy; później Cele i Money lite)
4. **Asystent**
5. **Więcej** (Miejsca pracy, Centrum kontroli danych, Analityka, Dokumenty, Ustawienia)

**Work Mode i Life Mode:** ✅ nie wprowadzamy globalnego przełącznika trybów (decyzja 3.1/4). Podwaja liczbę stanów nawigacji, a Safe-to-Spend z natury łączy oba światy. Zamiast tego Money lite jest **modułem włączanym w ustawieniach** i dokłada sekcje w zakładce Pieniądze i karty na Dashboardzie. Alternatywa (przełącznik trybu) wraca tylko wtedy, gdy Money lite urośnie do pełnej aplikacji i będzie to osobna decyzja.

**Akcja główna zależna od stanu:** jeden wyraźny przycisk w miejscu stycznym do kciuka: przed zmianą „Zaczynam”, w trakcie „Przerwa” i „Koniec”, po zmianie „Wpisz napiwki”.

**Wejście do AI wszędzie:** jedna stała ikona asystenta w pasku górnym głównych ekranów (przycisk uzasadniony, bo to funkcja centralna i niemożliwa do odkrycia gestem).

## E.2. Dashboard adaptacyjny z personalizacją ✅

Układ ma trzy poziomy:

1. **Slot główny (automatyczny, zawsze jeden)** wybierany przez maszynę stanów:
   - *Przed zmianą:* odliczanie, miejsce, notatki, przypomnienia.
   - *Podczas zmiany:* timer, przerwa, przewidywany zarobek za czas do tej pory (oznaczony jako szacunek).
   - *Po zmianie:* szybkie rozliczenie (kwota i potwierdzenie „wszystko wpisane”).
   - *Przed wypłatą:* nadal należne od pracodawcy, otrzymane od pracodawcy, termin.
   - *Spokojny dzień:* podsumowanie okresu i cel.
2. **Pas „Wymaga uwagi” (automatyczny, maks. 3)** z Centrum kontroli danych: niewpisane zmiany, brak stawki, stara kopia. Nie można go ukryć w całości (zasada 24: ważne rzeczy nie znikają).
3. **Karty personalizowane przez użytkownika:** kolejność, ukrywanie, przypinanie. Katalog: okres, napiwki na godzinę, cel, Safe-to-Spend, najbliższe zmiany, wypłata za X dni, jeden wgląd dnia, porównanie, miejsca pracy. Przycisk „Przywróć układ automatyczny”.

Personalizacja jest dostêpna w trybie edycji z widocznym przyciskiem, a nie tylko przez przytrzymanie karty.

## E.3. Ekran zmiany („Szczegóły zmiany”)

Arkusz dolny rozwijany do pełnego ekranu. Jeden ekran zamiast „edytuj zmianę” i „edytuj wpis”:

- **Czas:** oś czasu z planem, faktem i wieloma przerwami (lista: początek, koniec, płatna lub nie); oznaczenia nocy i zmiany czasu (powtórzona i brakująca godzina opisane jawnie); strefa miejsca pracy widoczna, gdy różni się od strefy telefonu.
- **Zarobek:** rozbicie na bieżąco (stawka × godziny, dodatki, napiwki gotówką i kartą, tip-out, razem) z oznaczeniem fakt/szacunek i przyciskiem „Skąd ta kwota”.
- **Rozliczenie:** utarg i gotówka do rozliczenia z pracodawcą, kontrola kasy, osobna linia „Kompensacja napiwków kartowych” (gdy miejsce pracy tak rozlicza), potwierdzenie „wszystko wpisane”.
- **Notatki i historia.**
- Przycisk główny: **Zapisz**. Rzadkie akcje (duplikuj, anuluj zmianę, usuń) w menu z etykietą. Przesunięcie do usunięcia zostaje jako skrót, nigdy jedyna droga.
- **Szybkie rozliczenie:** klawiatura numeryczna z trzema polami (gotówka, karta, utarg), domyślny tip-out z reguł miejsca pracy, jedno dotknięcie do potwierdzenia. Cel: 10 sekund.

## E.4. Rozliczenia i zarobki

- **Pieniądze → Okres:** cztery liczby ze znacznikami fakt/szacunek: *Zarobione*, *Otrzymane bezpośrednio od klienta*, *Otrzymane od pracodawcy*, *Nadal należne od pracodawcy*. Pasek postępu dotyczy tylko należności od pracodawcy, więc gotówkowe napiwki go nie wydłużają. Przegląd per miejsce pracy. Składniki przez inny kanał (other) są pokazane osobno jako „przez inny kanał” i nie wchodzą do żadnej z czterech liczb salda.
- **Zamknij okres:** kreator (kontrola danych → podgląd migawki → zatwierdzenie). Zamknięty okres ma znacznik z kłódką i **nie można go ponownie otworzyć** ✅ (decyzja 3.1/2); zmiany wewnątrz niego prowadzą do **Korekty**. Pierwotna migawka i korekty są pokazane osobno.
- **Wypłaty:** lista z szybkim dodawaniem (arkusz dolny), zaliczki oznaczone, podpowiedź przypisania FIFO do ręcznej edycji, przypisanie jednej wypłaty do kilku okresów; niealokowana część wypłaty jest zawsze widoczna.
- **Uzgodnienie (od M4):** należne od pracodawcy kontra otrzymane od pracodawcy i skompensowane z utargiem, z wyjaśnieniem różnicy (np. „brakuje 4 godzin z 12.11”) i eksportem dowodu godzin.
- **Zarobki/Analityka:** trend dochodu, napiwki na godzinę, miejsca i stanowiska; później mapa dzień × rodzaj zmiany. Fakty i szacunki wizualnie różne.

## E.5. AI Workspace

Nie jest samym czatem:

- **Pasek kontekstu** (zakres: ten okres, miejsce) i **dynamiczne podpowiedzi** („Dlaczego wypłata jest niższa?”).
- **Rozmowa z wynikami bogatymi:** wykresy, tabele i **karty propozycji** wewnątrz odpowiedzi.
- **Pole wpisu:** tekst, mikrofon, załącznik (dokument, zdjęcie).
- **Paleta poleceń** jako pierwszy tryb: wpisanie „start” lub „napiwki” pokazuje akcje bez modelu.
- **Skrzynka zatwierdzeń** z oczekującymi propozycjami.
- **Prywatność i pamięć:** aktywny dostawca i tryb dostępu, dziennik wysłanych danych, limit kosztów; osobno Historia rozmów (przeglądanie i usuwanie) oraz Pamięć asystenta (przeglądanie, edycja, usuwanie), niezależnie od siebie.
- Znacznik trybu (Offline / Na urządzeniu / Chmura).

## E.6. Kontekstowe AI

Jedno wspólne wejście „Zapytaj o to” z wstępnie wypełnionym kontekstem i zakresem, dostêpne na:

- **Grafik:** „Zaplanuj tydzień” (pakiet propozycji).
- **Szczegóły zmiany:** „Sprawdź” (anomalie i braki).
- **Wypłaty:** „Wyjaśnij różnicę”.
- **Analityka:** „Co się zmieniło?”.
- **Dokumenty:** „Odczytaj”.
- **Centrum kontroli danych:** „Napraw z pomocą asystenta”.

## E.7. Personalizacja

Dashboard (E.2), motyw jasny/ciemny/systemowy, pierwszy dzień tygodnia, włączane moduły (Money lite, dokumenty, AI), profile miejsc pracy, gotowe przypomnienia z parametrami, zasady prywatności AI.

## E.8. Design system

✅ Zachowujemy turkus i mosiądz (`kTeal`, `kBrass`). 🔷 Premium budujemy dyscypliną i jakością detalu, nie nową paletą.

- **Tokeny:** kolor marki, kolory semantyczne (*fakt, szacunek, prognoza, ostrzeżenie, błąd*), warstwy powierzchni w trybie jasnym i ciemnym, skala typografii, odstępy 4/8, promienie (istniejące 14/18), minimalne cienie.
- **Typografia:** cyfry tabelaryczne, wyraźna hierarchia dla kwot i godzin, przy dużym tekście nic się nie ucina.
- **Oznaczanie pochodzenia liczb:** *fakt* = pełny kolor; *szacunek* = znak „≈” i przerywane podkreślenie; *prognoza* = kontur i etykieta. Nigdy tylko kolor.
- **Komponenty:** `MoneyText`, `TimeRangeText`, `StatCard`, `StatusChip`, `ProvenanceBadge`, `ProposalCard`, arkusze dolne, stany puste, nakładka wykresów na `fl_chart`.
- **Ruch:** 150–250 ms, haptyka tylko przy starcie/końcu zmiany i zatwierdzeniu operacji.
- **Dostępność:** cele dotykowe 48 dp, skalowanie tekstu do 200%, kontrast AA, akcje TalkBack dla gestów, stany nigdy tylko kolorem.
- 🚫 Dynamiczny kolor systemowy jako tożsamość aplikacji: rozmywa rozpoznawalność marki. Opcjonalnie może być ustawieniem, ale nie domyślnym wyglądem.

---

# F. Model finansowy

## F.1. Słownik pojęć

- **Zarobione:** suma wszystkich składników ze znakiem z potwierdzonych zmian, niezależnie od kanału (wynagrodzenie, dodatki, napiwki, premie minus tip-out i potrącenia) (fakt). Zarobione = bezpośrednie wpływy − oddane bezpośrednio + składniki `employer` + składniki `other`.
- **Otrzymane bezpośrednio od klienta:** składniki o kanale `direct`, np. gotówka z napiwków. Osobno pokazujemy to, co pracownik oddał bezpośrednio (tip-out z gotówki lub przekazany współpracownikowi).
- **Przez inny kanał (`other`):** inny sposób wypłaty niż pracodawca lub bezpośrednio (np. agencja pracy, pośrednik płatności, pula zarządzana przez osobę trzecią). Składnik `other` **jest częścią zarobku** (rodzaj i znak jak zwykle), **nie tworzy należności wobec pracodawcy**, **nie jest przepływem bezpośrednim** i nie wchodzi do żadnego salda z tej listy. Wymaga podmiotu (`party`) i jest pokazywany użytkownikowi osobno jako „przez inny kanał”. W Safe-to-Spend nie jest liczony jako potwierdzony wpływ, dopóki użytkownik nie doda go jako pewnego.
- **Otrzymane od pracodawcy:** suma zarejestrowanych wypłat i zaliczek (`Payout`) w pełnej kwocie, niezależnie od alokacji (F.6).
- **Nadal należne od pracodawcy (saldo pracodawcy):** suma należności okresów (składniki `employer` po korektach) minus suma wypłat w pełnej kwocie i minus kompensacje napiwków kartowych z utargiem (F.2b). Może być ujemne (zaliczka lub nadpłata). Saldo pojedynczego okresu to jego należność minus alokacje do tego okresu i minus kompensacje tego okresu (F.6, F.2b).
- **Szacowane:** zmiany zaplanowane lub trwające, wpisy niepotwierdzone (szacunek).
- **Prognoza:** model oparty na planie i historii (F.8), nigdy nie jest faktem.

**Skompensowane z utargiem (`Offset`, F.2b):** napiwki kartowe rozliczone przez pomniejszenie gotówki przekazywanej pracodawcy. To operacja rozliczenia, **nie wypłata i nie składnik zarobku**: nie zmienia „zarobione”, pomniejsza „nadal należne od pracodawcy” dokładnie raz i nie wchodzi do „otrzymane od pracodawcy”. Pokazywana osobno.

🔷 **Model składnika: cztery niezależne informacje (zastępuje `paidBy` z v1.0).** `paidBy` mieszało kilka znaczeń naraz: kto płaci, którędy płyną pieniądze i czym jest tip-out. W v1.1 każdy składnik ma osobno:

1. **Rodzaj i znak:** zarobek (+), potrącenie (−) albo korekta (±). Rodzaj nazywa ekonomiczny sens (wynagrodzenie, napiwek gotówkowy, napiwek kartą, tip-out, premia, potrącenie). Decyduje o „zarobione”.
2. **Kanał (`channel`):** `employer` (pieniądze przychodzą w wypłacie albo są z niej potrącane), `direct` (pracownik odbiera lub oddaje bezpośrednio, np. gotówka od klienta albo dla współpracownika), `other` (inny kanał, np. wypłata przez pośrednika). Decyduje o saldach: tylko kanał `employer` wchodzi do „nadal należne od pracodawcy”.
3. **Podmiot (`party`):** opcjonalna etykieta drugiej strony przepływu: klient, współpracownik lub stanowisko (np. bar, kuchnia), pracodawca (domyślny dla kanału `employer`), inny. Służy raportom i uzgodnieniom, nie saldom.
4. **Sposób rozliczenia tip-outu (tylko tip-out):** `from_cash` (potrącany z gotówki), `direct_transfer` (przekazywany współpracownikowi), `via_employer` (potrącany i przekazywany przez pracodawcę). **Kanał tip-outu wynika z tego pola** (`from_cash` i `direct_transfer` dają `direct`, `via_employer` daje `employer`), więc nie da się ustawić sprzecznej pary.

Zasada: **zarobek, przepływ gotówki i należność od pracodawcy to trzy różne rzeczy**, liczone z różnych pól: zarobek z rodzaju i znaku, przepływ bezpośredni z kanału `direct`, należność z kanału `employer`. Nie budujemy ogólnej księgi podwójnego zapisu.

| Przykład | Rodzaj i znak | Kanał | Sposób tip-outu | Zarobione | Bezpośrednio | Nadal należne od pracodawcy |
| --- | --- | --- | --- | --- | --- | --- |
| Napiwek gotówkowy otrzymany bezpośrednio | napiwek gotówkowy, + | `direct` (klient) | – | + | wpływ + | bez zmiany |
| Napiwek kartą przekazywany przez pracodawcę | napiwek kartą, + | `employer` | – | + | bez zmiany | + |
| Tip-out potrącany z gotówki | tip-out, − | `direct` | `from_cash` | − | oddane − | bez zmiany |
| Tip-out przekazywany współpracownikowi | tip-out, − | `direct` (współpracownik) | `direct_transfer` | − | oddane − | bez zmiany |
| Tip-out rozliczany przez pracodawcę | tip-out, − | `employer` | `via_employer` | − | bez zmiany | − |
| Potrącenie z wynagrodzenia | potrącenie, − | `employer` | – | − | bez zmiany | − |

**Niezmienniki:** (1) składnik o kanale `direct` nigdy nie zmienia salda należnego od pracodawcy, więc gotówkowe napiwki go nie zawyżają; (2) składnik o kanale `other` nie zmienia ani salda pracodawcy, ani sumy przepływów bezpośrednich; (3) saldo pracodawcy = suma należności okresów minus suma wypłat w pełnej kwocie, a kompensacje napiwków kartowych pomniejszają je osobno (F.2b); każda wypłata i każda kompensacja jest odejmowana dokładnie raz (F.6); (4) zarobione = bezpośrednie wpływy − oddane bezpośrednio + składniki `employer` + składniki `other`.

🔬 **Mapowanie istniejących danych na składniki nie jest jeszcze ustalone.** Zamiar: `Tip.cash` jako napiwek gotówkowy o kanale `direct`, `Tip.card` jako napiwek kartą o kanale `employer` (zmienialne per miejsce pracy, bo część lokali wypłaca napiwki kartą gotówką). Migracja `Tip.tipOut` nie jest ustalana bez wcześniejszego audytu znaczenia i znaku tego pola ✅ (decyzja 3.2/5). Domyślne ustawienia dla istniejących miejsc pracy powstaną dopiero po audycie (C.10).

## F.2. Katalog składników

✅ Rozliczenia elastyczne, ale oparte na kontrolowanych składnikach i regułach (decyzja 15). 🔷 Każdy składnik ma: rodzaj i znak, kanał, podmiot, sposób obliczenia i parametry z walidacją (tip-out ma dodatkowo sposób rozliczenia; zob. F.1). **Sposoby obliczenia ograniczone do czterech:** kwota stała, kwota za godzinę, procent wskazanej podstawy, progi (np. nadgodziny po X godzinach). 🚫 Dowolne wzory i skrypty użytkownika: otwierają drogę do błędów nie do wyłapania i nie dadzą się sensownie testować.

- **Wynagrodzenie bazowe** (godzinowe, za zmianę; miesięczne później): zarobek, kanał `employer`.
- **Dodatki:** noc, weekend, święta, nadgodziny (okna czasowe i mnożniki albo kwoty; liczone na segmentach czasu, C.6a): zarobek, `employer`.
- **Napiwki gotówkowe:** zarobek, `direct`. **Napiwki kartowe:** zarobek, domyślnie `employer` (konfigurowalne per miejsce pracy). **Napiwki zespołowe** (pula z podziałem według godzin lub punktów): kanał zależny od ustawień puli.
- **Tip-out:** potrącenie z podstawą (procent napiwków, procent utargu, kwota), odbiorcą i sposobem rozliczenia (F.1).
- **Potrącenia deklarowane przez użytkownika** (np. opcjonalny „podatek od napiwków kartą”): potrącenie, kanał `employer`, wartość podana przez użytkownika; RITMO nie ocenia jej poprawności ✅ (decyzja 3.1/14). **Utarg i kontrola kasy nie są składnikami**: to raport zmiany (`ShiftReport`), który nie wchodzi do zarobku.
- **Premie i inne wpływy:** zarobek, kanał wybierany (domyślnie `employer`).
- **Potrącenia jednorazowe i cykliczne:** potrącenie, `employer`.
- **Korekty:** ±, kanał dziedziczony z korygowanego składnika.

## F.2a. Tip-out a dostępna gotówka

Tip-out o sposobie `from_cash` nie może przekroczyć gotówki, którą pracownik faktycznie ma do dyspozycji. 🔷 Reguły:

1. **Wykrywanie:** kalkulator porównuje wyliczony tip-out `from_cash` z gotówką dostępną dla tego rozliczenia. Domyślnie są to gotówkowe napiwki tej zmiany; reguła miejsca pracy może wskazać inną podstawę (np. pulę zespołową; 🔬 zależy od lokali).
2. **Ostrzeżenie i brak cichego zapisu:** gdy tip-out jest większy niż gotówka (`cash_shortfall`), polecenie zwraca błąd walidacji z wyliczeniem braku. Zapis takiego rozliczenia bez jawnej decyzji jest niemożliwy.
3. **Jawne wybory użytkownika:** (a) inny sposób rozliczenia dozwolony w konfiguracji stanowiska (`direct_transfer` albo `via_employer`; lista dozwolonych sposobów należy do reguły tip-outu, a interfejs oferuje tylko je); (b) ręczne wpisanie rzeczywistej kwoty tip-outu z notatką; (c) pozostawienie zmiany niepotwierdzonej (`earnings_confirmed_at` puste), co zgłasza ją w Centrum kontroli danych.
4. **Brak założenia:** nie zakładamy, że każda wartość tip-outu da się pobrać z gotówki; sposób rozliczenia zapisany na linii jest decyzją, nie domysłem.
5. **Testy:** tip-out równy gotówce (poprawny), większy o 1 grosz (ostrzeżenie), zmiana na dozwolony sposób, próba wyboru niedozwolonego, podstawa „procent utargu” bez utargu.

## F.2b. Kompensacja napiwków kartowych z utargiem gotówkowym

✅ Wymaganie właściciela (Etap 3.2, pkt 3.4): w niektórych lokalach napiwki kartowe nie są wypłacane pracownikowi, tylko odliczane od utargu gotówkowego, który pracownik przekazuje pracodawcy. Metoda jest **jedną z konfigurowalnych metod** rozliczania napiwków kartowych, obok pozostałych; nie zakładamy, że stosują ją wszystkie lokale.

**Czy obecny model wystarcza?**

| Dotychczasowy element | Czy odwzorowuje operację? | Dlaczego |
| --- | --- | --- |
| `channel` = `employer` dla napiwku kartowego | częściowo | poprawnie mówi, że to pracodawca jest winien napiwek (należność), ale nie pokazuje, że rozlicza się go z gotówką |
| `channel` = `direct` | nie | napiwek kartowy nie przychodzi bezpośrednio od klienta; ukryłby należność wobec pracodawcy i kontrolę kasy |
| `party` | nie | etykieta podmiotu, bez wpływu na salda |
| tip-out i sposoby jego rozliczenia | nie | tip-out to dzielenie napiwków ze współpracownikami, nie rozliczenie z pracodawcą |
| `Payout` i `PayoutAllocation` | nie | wypłata to rzeczywisty przepływ pieniędzy od pracodawcy; kompensacja nim nie jest, więc użycie `Payout` zawyżyłoby „otrzymane od pracodawcy” i mieszałoby FIFO z operacją przypisaną do konkretnej zmiany |
| ujemna linia `employer` plus dodatnia `direct` | nie | zniekształca „zarobione” i dubluje dane |

**Minimalne rozszerzenie 🔷 (bez nakładających się źródeł prawdy):**

1. **Ustawienie miejsca pracy `card_tips_settlement`:** `employer_payout` (domyślne: napiwek kartowy wypłaca pracodawca w wypłacie), `direct_cash` (pracodawca wypłaca od ręki gotówką; kanał `direct`) albo `offset_against_takings` (kompensacja z utargiem). Parametry trzeciej metody: `offset_partial_allowed` (domyślnie tak) i `offset_across_shifts` (domyślnie nie; dopuszcza kompensację z utargiem innej zmiany tego miejsca; 🔬 zależy od lokali). Ustawienie jest wersjonowane od daty (F.3).
2. **Pole raportu zmiany `ShiftReport.cash_due`:** utarg gotówkowy do rozliczenia z pracodawcą, przed kompensacją. To dana wejściowa (kontrola kasy), nie zarobek.
3. **Nowa operacja `Offset` (kompensacja):** zmiana źródłowa (`source_shift_id`, z której pochodzą napiwki kartowe), zmiana z utargiem (`takings_shift_id`, domyślnie ta sama), kwota, data, powód. To **widoczna, osobna operacja rozliczenia z pracodawcą**, a nie ukryta korekta utargu. Nie jest wypłatą.
4. **Wartość pochodna, niezapisywana:** gotówka do przekazania pracodawcy = `cash_due` minus kompensacje. Nie ma drugiego pola z tą samą wartością.

**Cztery rozróżniane wielkości:**

| Wielkość | Skąd | Typ |
| --- | --- | --- |
| Całkowity utarg gotówkowy do rozliczenia | `ShiftReport.cash_due` | dana wejściowa (raport zmiany) |
| Kwota skompensowana z utargiem | `Offset.amount` | operacja rozliczenia |
| Gotówka przekazywana pracodawcy | `cash_due` minus kompensacje | wartość pochodna |
| Napiwki gotówkowe zatrzymywane przez pracownika | `Tip.cash` (kanał `direct`) | składnik zarobku |

**Zasady:**

1. **Napiwki kartowe pozostają zarobkiem** (kanał `employer`) i wchodzą do należności okresu R(P) niezależnie od metody. Kompensacja **nie zmienia „zarobione”**, tylko rozlicza należność.
2. **Brak podwójnego pomniejszenia:** kompensacja pomniejsza saldo pracodawcy raz (jako `Offset`) i nie jest `Payout`: nie trafia do „otrzymane od pracodawcy”, nie przechodzi przez `PayoutAllocation` ani FIFO.
3. **Limity:** kompensacja nie przekroczy (a) dostępnego utargu, czyli `cash_due` zmiany z utargiem minus kompensacje już na nim zapisane, (b) niezałatwionej części napiwków kartowych zmiany źródłowej, czyli napiwków kartowych minus kompensacje już zapisane, ani (c) należności okresu: łączne pomniejszenia okresu (alokacje i kompensacje) nie przekraczają R(P) bez jawnego potwierdzenia nadpłaty. Polecenie zapisu odrzuca przekroczenie.
4. **Propozycja, nie cicha korekta:** kalkulator proponuje kwotę równą mniejszej z (a) i (b), a użytkownik zatwierdza `Offset` (dla asystenta `propose_card_tip_offset`, klasa L2). Gdy `cash_due` nie jest znany, kompensacji nie zakładamy (ani zera, ani domysłu): aplikacja prosi o wpisanie utargu albo zostawia napiwki jako należność.
5. **Kompensacja częściowa:** użytkownik może zatwierdzić kwotę mniejszą niż propozycja (gdy `offset_partial_allowed`); reszta napiwków kartowych zostaje należnością od pracodawcy.
6. **Niewystarczający utarg:** kompensacja jest ograniczona do dostępnego utargu, a pozostała kwota napiwków kartowych zostaje **nierozliczona i widoczna jako należność od pracodawcy** (w R(P) bez pomniejszenia) do czasu wypłaty albo późniejszej kompensacji (tylko gdy `offset_across_shifts`).
7. **Zmiana metody w czasie:** ustawienie jest wersjonowane od daty; istniejące `Offset` nie zmieniają się po zmianie ustawienia.
8. **Gotówka w ręku:** zatrzymana kwota kompensacji jest wpływem gotówkowym w dniu rozliczenia zmiany (Safe-to-Spend, wariant rozszerzony, F.9).

**Wpływ na wzory salda (F.6):** `B(W)` = suma R(P) minus suma kompensacji minus suma pełnych kwot wypłat; `B(P)` = R(P) minus alokacje minus kompensacje okresu P. Kompensacja należy do okresu zmiany źródłowej, więc nie ma części niealokowanej, a zależność kontrolna `B(W)` = suma `B(P)` minus niealokowane pozostaje prawdziwa.

**PeriodClosure, korekty i raporty:** `ClosureItem` kopiuje `cash_due` i zatwierdzone `Offset` jako dane wejściowe (zatwierdzona kwota jest wejściem, nie wynikiem obliczenia), a `ClosureRules` kopiuje `card_tips_settlement` i jego parametry. Wynik zamknięcia pokazuje osobne linie „kompensacja napiwków kartowych” i „gotówka do przekazania”. Zmiana kompensacji po zamknięciu okresu to `Adjustment` powiązany z `Offset` (nie edycja), z wpisem audytu. Raporty okresu i dowód godzin pokazują napiwki kartowe, kompensację i resztę należności w osobnych liniach.

**Przykłady liczbowe (zł).** W każdym przykładzie wynagrodzenie 200 (kanał `employer`), napiwki gotówkowe 100 (kanał `direct`), metoda `offset_against_takings`:

| Przykład | Utarg gotówkowy | Napiwki kartowe | Kompensacja | Gotówka do przekazania | Zarobione | R(P) | Saldo pracodawcy po kompensacji |
| --- | --- | --- | --- | --- | --- | --- | --- |
| A. Pełna | 800 | 150 | 150 | 650 | 100 + 200 + 150 = 450 | 200 + 150 = 350 | 350 − 150 = 200 (wynagrodzenie) |
| B. Częściowa (użytkownik zatwierdza 100) | 800 | 150 | 100 | 700 | 450 | 350 | 350 − 100 = 250 (wynagrodzenie 200 + napiwki kartowe 50) |
| C. Niewystarczający utarg | 120 | 150 | 120 (limit utargu) | 0 | 450 | 350 | 350 − 120 = 230 (wynagrodzenie 200 + napiwki kartowe 30) |

**Przykład C dalej, bez podwójnego pomniejszenia:** pracodawca wypłaca później 230 (`Payout`, alokacja do okresu). `B(P)` = 350 − 120 (kompensacja) − 230 (alokacja) = 0 i `B(W)` = 350 − 120 − 230 = 0. „Otrzymane od pracodawcy” to 230 (tylko wypłata), a „skompensowane z utargiem” to osobno 120. Gdyby 120 zapisano dodatkowo jako wypłatę, `B(W)` wyniosłoby −120, a kontrola z punktu 3(c) zgłosiłaby nadpłatę.

🔬 **Wymaga audytu przed M2:** czy `Tip.sales` oznacza sprzedaż ogółem, utarg gotówkowy czy coś innego (do czasu audytu nie mapujemy go do `cash_due`) oraz jakie zasady (limit kompensacji częściowej, kompensacja z innej zmiany, kolejność) stosują lokale właściciela (sekcja I).

## F.3. Ustawienia rozliczeń per miejsce pracy ✅

Prościej: **profil rozliczeń miejsca** = typ okresu i dzień zakotwiczenia, zasada terminu wypłaty, tabela stawek, włączone składniki (z domyślnym kanałem i metodą rozliczenia napiwków kartowych: wypłata przez pracodawcę, bezpośrednio albo kompensacja z utargiem (F.2b)), reguły tip-outu wraz ze sposobem rozliczenia, strefa czasu IANA, kalendarz świąt kraju i reguły nadgodzin. Wersjonowany od daty: zmiana obowiązuje od wybranego dnia i nie zmienia przeszłości. "Kopiuj z innego miejsca" skraca konfigurację. Podgląd na przykładowej zmianie pokazuje skutek ustawień przed zapisem.

## F.4. Czas pracy

Plan i fakt, przerwy płatne i niepłatne (każda osobno, C.6b), nadgodziny jako reguła wpisana przez użytkownika (próg dzienny lub tygodniowy), liczone na rzeczywistych przedziałach czasu (C.6a). 🔷 RITMO liczy według reguł podanych przez użytkownika i **nie twierdzi, że są zgodne z prawem pracy** ✅ (decyzja 3.1/13). **Kalendarz świąt ✅:** wbudowany zestaw danych dla kraju, konfigurowany według kraju i miejsca pracy; miejsce może mieć własną, edytowalną listę dni. Święto rozpoznaje data lokalna w strefie zmiany. ✅ Na początek polski kalendarz świąt, z architekturą pozwalającą dodać kolejne kraje (decyzja 3.2/7).

## F.5. Zamknięcie okresu i korekty ✅

1. **Kontrola:** Centrum kontroli danych wskazuje braki (niepotwierdzone zmiany, brak stawki, kolizje).
2. **Podgląd migawki:** sumy per składnik i lista zmian z danymi wejściowymi (minuty, stawka, reguła).
3. **Zamknięcie:** zapis `PeriodClosure` z `ClosureItem` dla każdej zmiany oraz ClosureRules (kopia reguł) z pełnym zestawem danych wejściowych, wersją kalkulatora i skrótami danych (F.5a).
4. **Korekty:** zmiana danych w zamkniętym okresie jest blokowana na poziomie danych i prowadzi do **Adjustment** (kwota, powód, powiązanie z pozycją). Migawka nigdy nie jest edytowana; wynik efektywny to migawka plus korekty. Każda korekta ma wpis audytu.

**Zasady korekt ✅ (decyzja 3.1/2):**

- Zamknięty okres jest **niezmienną migawką**. Nie można go ponownie otworzyć, także w krótkim oknie czasowym. Jedyna droga zmiany to **korekta**.
- Zmiana danych wejściowych (zmiany, przerwy, napiwki, stawki) w zamkniętym okresie jest blokowana na poziomie danych; aplikacja proponuje `Adjustment` z różnicą (nowa wartość minus zamrożona), powodem i powiązaniem z pozycją migawki.
- Wynik efektywny to migawka plus korekty. Pierwotna migawka i pełna historia (`AuditEntry`) są zawsze dostępne; korekta korekty to kolejny `Adjustment`, nigdy edycja.
- 🚫 Ponowne otwarcie okresu (z poprzedniego raportu, także w wersji „w ciągu 7 dni”): odrzucone. Wymaga wersjonowania całych okresów i otwiera drogę do cichej zmiany historii.
- Wypłaty (`Payout`) rejestrują fakt otrzymania pieniędzy, nie wynik obliczeń, więc pozostają edytowalne także po zamknięciu okresu, z pełnym wpisem audytu, bez otwierania zamkniętego okresu ✅ (decyzja 3.2/6).

## F.5a. PeriodClosure: pełna odtwarzalność

✅ Wymaganie: po zamknięciu okresu RITMO musi odtworzyć dokładnie ten sam wynik finansowy, nawet jeśli później zmienią się stawki, ustawienia stanowiska, zasady napiwków lub algorytm kalkulatora. Same sumy nie wystarczają.

**Zasada podziału:** dane są **kopiowane** do niezmiennego snapshotu, a kod jest **wersjonowany**. Samo odwołanie do danych, które mogą się zmienić lub zniknąć (stawki, ustawienia miejsca, stanowiska), nie wystarcza.

| Element | Sposób przechowywania | Uzasadnienie |
| --- | --- | --- |
| Zmiany objęte okresem (miejsce, stanowisko, strefa, `time_model`, plan, fakt) | kopia w `ClosureItem` | edycja lub usunięcie zmiany nie może zmienić historii |
| Przerwy (początek, koniec, płatność) | kopia w `ClosureItem` | wpływają na czas płatny |
| Wyliczone segmenty czasu (noc, weekend, święto, nadgodziny) | kopia | wynik zależy od okien i kalendarza obowiązujących wtedy |
| Stawki obowiązujące w danym momencie (kwota, rodzaj, `valid_from`) | kopia w `ClosureRules` | stawki mogą się zmienić |
| Definicje składników i profil rozliczeń (rodzaj, znak, kanał, podmiot, wzór, parametry) | kopia w `ClosureRules` | ustawienia stanowiska mogą się zmienić |
| Napiwki (gotówka, karta, tip-out) i ich źródła; `EarningLine` | kopia w `ClosureItem` | wpisy można edytować do zamknięcia |
| Reguła tip-outu, sposób rozliczenia, podstawa (w tym użyty utarg) | kopia | zasady napiwków mogą się zmienić |
| Reguła zaokrągleń i jej parametry | kopia w `ClosureRules` | wynik zależy od zaokrągleń |
| Dni świąteczne i reguły nadgodzin użyte w obliczeniu | kopia (tylko użyte daty i progi) | kalendarz i reguły są edytowalne |
| Wersja kalkulatora (`calc_version`) i wersja zestawu reguł | odwołanie do niezmiennego kodu i definicji | kod nie jest kopiowany do bazy |
| Wyniki: każda linia (składnik, kanał, podmiot, kwota, identyfikator reguły) i sumy | kopia | to jest wynik historyczny |
| Korekty (`Adjustment`) | osobne, niezmienne wiersze | wynik efektywny to snapshot plus korekty |
| Wypłaty i alokacje | poza snapshotem (żywy rejestr, F.6) | to fakt otrzymania, nie wynik obliczeń |

**Wersjonowanie kalkulatora i reguł ✅ (wymaganie):** zmiana algorytmu nie zmienia wyniku zamkniętego okresu. Nowa wersja kalkulatora obowiązuje dla przyszłych obliczeń, a historyczne zamknięcia zachowują swoją wersję i reguły. 🔷 Mechanizm: kalkulator to zestaw niezmiennych modułów wersji (`calc_v1`, `calc_v2` itd.) wybieranych przez `calc_version`; wersja nie jest usuwana, dopóki istnieje zamknięcie, które z niej korzysta. Wspólne elementy (`Money`, obsługa czasu) podlegają tej samej zasadzie. Reguły ustawień (stawki, składniki) są wersjonowane od daty i nie są edytowane wstecz, więc obliczenia w okresie otwartym używają wersji obowiązujących w danym dniu, a zamknięcie zamraża ich kopię.

**Odtwarzanie i integralność:**

1. Przy zamknięciu zapisujemy skrót danych wejściowych (`input_hash`, kanoniczna serializacja) i skrót wyników (`output_hash`).
2. `ReplayClosure` liczy wynik ponownie wyłącznie z danych snapshotu wersją `calc_version` i musi dać identyczne linie i sumy. Replay wykonujemy przy zamknięciu (przy różnicy okresu nie zamykamy), na żądanie i w testach.
3. Niezgodność replay lub skrótów oznacza naruszenie integralności: zamknięcie jest oznaczone w Centrum kontroli danych, a zapisane wyniki pozostają obowiązujące i nigdy nie są nadpisywane wynikiem replay.
4. Zestaw **fikstur zamknięć** (wejście i oczekiwane wyjście) dla każdej wersji kalkulatora jest częścią testów blokujących CI; wersja bez fikstur nie może posłużyć do zamknięcia.
5. 🔬 Sposób utrzymywania starych wersji kalkulatora w kodzie oraz rozmiar snapshotu przy dużej liczbie zmian sprawdzą PoC i testy wydajności (Stage 4); ich wyniki nie są jeszcze znane.

**Kompensacja napiwków kartowych w snapshotcie (F.2b):** `cash_due` i zatwierdzone `Offset` są kopiowane do `ClosureItem` jako dane wejściowe, a ustawienie `card_tips_settlement` z parametrami do `ClosureRules`. Replay używa zapisanych kwot kompensacji jako danych, nie przelicza ich na nowo.

## F.6. Wypłaty, zaliczki, wypłaty częściowe

**Definicje i zasada pojedynczego odjęcia:**

- **Payout** reprezentuje rzeczywisty przepływ pieniędzy od pracodawcy i jego **całkowitą wartość** (kwota większa od zera; rodzaj `payout` lub `advance`; miejsce, data, notatka). Gotówkowe napiwki i pieniądze od współpracowników nigdy nie są wypłatą.
- **PayoutAllocation** przypisuje część wypłaty do okresu (opcjonalnie do grupy składników). Alokacja służy do przypisania i uzgodnienia, **nie tworzy drugiego przepływu** i nigdy nie zmienia salda pracodawcy.
- **Ograniczenia:** suma alokacji jednej wypłaty nie przekracza jej kwoty. Różnica to **część niealokowana**, zawsze jawnie widoczna.

**Jak liczymy (dla miejsca pracy):**

1. **Należność okresu R(P):** suma składników `employer` okresu P po korektach (po zamknięciu: snapshot plus `Adjustment`).
2. **Saldo pracodawcy B(W)** (rzeczywiste zobowiązanie): suma R(P) po wszystkich okresach minus suma kompensacji (F.2b) minus suma **pełnych kwot wszystkich wypłat**. Wypłata zmniejsza zobowiązanie w chwili rejestracji, w pełnej kwocie, niezależnie od alokacji. To jedyne miejsce, w którym jest odejmowana.
3. **Saldo okresu B(P):** R(P) minus suma alokacji do okresu P minus kompensacje okresu P (F.2b). Alokacja zmienia wyłącznie to, w którym okresie widzimy resztę, a nie B(W).
4. **Zależność kontrolna:** B(W) = suma B(P) minus suma kwot niealokowanych. Jeśli nie zachodzi, to błąd integralności.
5. **Zaliczka:** wypłata rodzaju `advance` jest zwykłą wypłatą. Od razu zmniejsza B(W) (także poniżej zera) i początkowo jest niealokowana. Późniejsze przypisanie do okresu przenosi część kwoty z niealokowanej do alokacji; B(W) się nie zmienia.
6. **Wypłata obejmująca kilka okresów:** jedna wypłata ma wiele alokacji (po jednej na okres, opcjonalnie na grupę). Każda kwota zmniejsza saldo swojego okresu, a cała wypłata zmniejsza B(W) tylko raz.
7. **FIFO:** przy rejestracji aplikacja *proponuje* alokację do najstarszego okresu z dodatnim saldem, potem do kolejnego; reszta zostaje niealokowana. Propozycja nie zapisuje się sama. **Ręczna zmiana:** użytkownik zmienia kwoty, okresy lub grupy; nowy zestaw alokacji zastępuje poprzedni atomowo, z wpisem audytu, i nie jest nadpisywany przez kolejne propozycje (dotyczą tylko części niealokowanej).
8. **Saldo ujemne:** B(P) lub B(W) poniżej zera to nadpłata lub zaliczka do rozliczenia. **Przeniesienie jest wyliczane, nie zapisywane:** saldo narastające to suma B(P) kolejnych okresów, więc ujemne saldo naturalnie pomniejsza kolejne należności i nie może zostać odjęte drugi raz.
9. **Grupy składników** (np. wynagrodzenie, napiwki kartą) to metadane uzgodnienia, dotyczą wyłącznie składników `employer` i nie zmieniają powyższych wzorów.
10. **Edycje:** wypłatę można edytować i usuwać (miękko) z wpisem audytu także po zamknięciu okresu ✅ (decyzja 3.2/6), bez otwierania okresu. Kwota wypłaty nie może spaść poniżej sumy jej alokacji (najpierw zmieniamy alokacje).
11. **Uzgodnienie (od M4):** `explain_payout_difference` rozkłada różnicę między należnym a otrzymanym na przyczyny (brakujące godziny, inna stawka, napiwki kartą, nieuwzględniona zaliczka, wypłata niealokowana). Eksport PDF z dowodem godzin.

**F.6a. Przykłady liczbowe** (kwoty w zł, B(W) liczone według punktu 2):

| Przykład | Stan | Alokacje i niealokowane | Salda okresów | B(W) i kontrola |
| --- | --- | --- | --- | --- |
| 1. Jedna wypłata na dwa okresy | R(P1) = 1000, R(P2) = 800; wypłata 1500 | FIFO: P1 = 1000, P2 = 500; niealokowane 0 | B(P1) = 0, B(P2) = 300 | B(W) = 1800 − 1500 = 300; suma B(P) = 300, niealokowane 0 ✓ |
| 2a. Zaliczka, początkowo niealokowana | brak należności; zaliczka 400 | brak alokacji; niealokowane 400 | brak okresów | B(W) = 0 − 400 = −400 (zaliczka do rozliczenia) ✓ |
| 2b. Okres zamknięty, zaliczka nadal niealokowana | R(P3) = 900 | niealokowane 400 | B(P3) = 900 | B(W) = 900 − 400 = 500; suma B(P) = 900, minus niealokowane 400 daje 500 ✓ |
| 2c. Przypisanie zaliczki do P3 | alokacja 400 do P3 | niealokowane 0 | B(P3) = 500 | B(W) = 900 − 400 = 500, bez zmiany (zaliczka odjęta raz) ✓ |
| 3a. Ręczna korekta alokacji z przykładu 1 | pracodawca zapłacił 700 za P1 i 800 za P2 | P1 = 700, P2 = 800; niealokowane 0 | B(P1) = 300, B(P2) = 0 | B(W) = 300, bez zmiany; suma B(P) = 300 ✓ |
| 3b. Ta sama wypłata, 100 celowo niealokowane | P1 = 700, P2 = 700 | niealokowane 100 | B(P1) = 300, B(P2) = 100 | B(W) = 300; suma B(P) = 400, minus 100 daje 300 ✓ |

W każdym przykładzie kwota wypłaty wchodzi do B(W) dokładnie jeden raz, a alokacje zmieniają tylko rozkład salda między okresami.

## F.7. Audyt

🔷 Pełny dziennik każdej edycji jest zbędny i uciążliwy. Audyt obejmuje to, co wpływa na pieniądze po fakcie: zamknięcia, korekty, wypłaty, zmiany stawek i profili, operacje wykonane przez asystenta. Pozostałe dane mają `updated_at` i miękkie usuwanie z możliwością cofnięcia.

## F.8. Prognozy

🔷 Prognoza ma dwie części o różnej wiarygodności i pokazuje je osobno: **wynagrodzenie z planu** (planowane godziny × stawka z reguł; wysoka wiarygodność, jeśli stawki są kompletne) oraz **napiwki** (statystyka z historii; wiarygodność zależy od liczby danych). Metoda jest przejrzysta i nie udaje precyzji:

- **Jednostka danych:** kompletne zmiany miejsca pracy (`completed` i `earnings_confirmed_at`), najwyżej ostatnie 12 tygodni lub 60 zmian. Segmentację (dzień tygodnia, rodzaj zmiany) stosujemy tylko, gdy segment ma co najmniej 8 kompletnych zmian; w przeciwnym razie używamy całego miejsca pracy.
- **Progi wiarygodności napiwków** (🔬 wartości domyślne, do kalibracji na prawdziwych danych):
  - poniżej 8 kompletnych zmian: **brak prognozy napiwków** („za mało danych”); pokazujemy tylko to, co potwierdzone, i wynagrodzenie z planu;
  - 8–19 zmian: **tylko szacunek środkowy** (mediana napiwków na godzinę × planowane godziny), „jakość danych: niska”, z widoczną liczbą zmian;
  - 20–39 zmian: **trzy scenariusze** (ostrożny P25, realistyczny mediana, optymistyczny P75), „jakość danych: średnia”;
  - 40 i więcej zmian z co najmniej 8 tygodni: te same scenariusze, „jakość danych: dobra”.
- **Oznaczenie jakości:** każda prognoza pokazuje jakość danych (niska, średnia, dobra), liczbę zmian, okres historii, datę obliczenia i założenia. Osiem zmian to początek zbierania danych, nie podstawa wysokiej wiarygodności.
- **Brak fałszywej precyzji:** kwoty prognozy zaokrąglamy do pełnych 10 zł; zakres pokazujemy jako „od–do”, bez groszy i bez procentów pewności. Gdy dane nie uzasadniają trzech scenariuszy, pokazujemy samą medianę albo komunikat.
- **Odtwarzalność:** zapisujemy skrót danych wejściowych i wersję kalkulatora; ten sam stan danych daje ten sam wynik.
- 🚫 Przedziały ufności i modele szeregów czasowych przy kilkudziesięciu obserwacjach dają fałszywą precyzję (bez zmian względem v1.0).

## F.9. Safe-to-Spend

✅ **Dwa warianty (decyzja 3.1/12).** Definicja jest pokazywana użytkownikowi wprost, z dniem X (następna wypłata lub koniec miesiąca):

- **Wariant podstawowy:** potwierdzone wpływy do dnia X minus znane zobowiązania do dnia X. *Potwierdzone wpływy* to nadal należne od pracodawcy z potwierdzonych zmian i zamkniętych okresów z terminem wypłaty do dnia X oraz wpływy dodane przez użytkownika jako pewne. Wariant nie wie, ile użytkownik ma już w portfelu, i opis mówi to wprost. Opcjonalnie odejmuje wpłaty na cele i bufor.
- **Wariant rozszerzony:** dodatkowo **ręcznie aktualizowane saldo środków** (`BalanceAnchor`: kwota i data). Zdarzenia zarejestrowane po dacie salda (otrzymane wypłaty, wpływy bezpośrednie, gotówka zatrzymana z kompensacji napiwków kartowych, opłacone zobowiązania) korygują je automatycznie, a po każdej ręcznej aktualizacji punkt odniesienia resetuje się do nowej daty, żeby nic nie liczyć podwójnie. Saldo jest opcjonalne, a **data ostatniej aktualizacji jest zawsze widoczna** obok wyniku; po przekroczeniu progu nieaktualności (🔬 propozycja: 7 dni) wynik jest oznaczony jako nieaktualny.
- Domyślnie **tylko potwierdzone wpływy**. Prognoza ostrożna wchodzi wyłącznie po włączeniu przez użytkownika i tylko przy jakości danych co najmniej średniej, z oznaczeniem.
- Bez integracji bankowej ✅ (decyzja 18). To odpowiedź na problem nieregularnych dochodów i główny argument za Money lite.

## F.10. Zasady integralności

1. Kwoty jako `Money` (grosze), czas jako minuty całkowite liczone ze znaczników czasu (C.6a).
2. Jeden kalkulator; test „te same liczby na każdym ekranie” i zestaw scenariuszy złotych: północ, DST (wiosna i jesień), zmiana stawki w trakcie okresu, brak stawki, wiele przerw, wypłata częściowa, zaliczka, wypłata na kilka okresów, korekta po zamknięciu, ponowny import. Do tego **scenariusz integracyjny S1** (sekcja G).
3. Zaokrąglenie według jawnej reguły na poziomie linii; suma okresu zawsze równa sumie pozycji.
4. Migawka zamknięcia jest niezmienna; korekty tylko przez `Adjustment`.
5. Składnik o kanale `direct` nigdy nie zmienia salda należnego od pracodawcy; saldo to suma składników `employer` minus wypłaty.
6. Ograniczenia w bazie (`CHECK`, `UNIQUE`, klucze obce, co najwyżej jedna zmiana `inProgress`).
7. Prognoza i szacunek nigdy nie są mieszane z faktem w jednej sumie bez oznaczenia; prognoza napiwków nie powstaje poniżej progu danych (F.8).
8. Godziny pochodzą ze zmiany; `Tip.hours` służy tylko wpisom bez zmiany.

---

# G. Plan rozwoju

Zasada: **każdy etap kończy się czymś, co użytkownik widzi i czego używa**. Fundamenty techniczne wchodzą razem z funkcją, której służą. Wielkości etapów: S (krótki), M (średni), L (długi). Status każdego pakietu: *In code → Tests passed → Accepted* (nadal Twoja akceptacja).

## M0 — „Pewne liczby” (M)

- **Widoczne:** nazwa i ikona RITMO, poprawny termin wypłaty na Dashboardzie dla każdego cyklu (miesięczny, tygodniowy, dwutygodniowy), spójne godziny wpisu i zmiany, pełny przepływ blokady aplikacji, pierwsza wersja Centrum kontroli danych (niewpisane zmiany, brak stawki, stara kopia). Poprawne godziny w nocy zmiany czasu przechodzą do M1.1, bo wymagają modelu czasu i stref (C.6a).
- **Fundament razem z tym:** `android/` w repozytorium, przypięty Flutter, testy i analiza blokujące CI, rozdzielone workflow debug i release, typ `Money`, jeden kalkulator dla istniejących funkcji **z numerem wersji (`calc_version = 1`) i zestawem fikstur** (F.5a), `await` na zapisach ustawień, atomowy restore (ustawienia w bazie), pierwsze ograniczenia w bazie z testami migracji.
- **Nie zmieniamy:** `applicationId`, nazwy bazy; format backupu v2 nadal się wczytuje (C.10).
- **Zależności wejściowe:** brak (pierwszy etap). 🔬 Audyt użycia `Tip.hours` i `Shift.durationMin` należy zakończyć przed M1.1.
- **Kryteria akceptacji** (każde kończy się wynikiem tak lub nie):
  - K0.1 CI kończy się błędem przy celowo zepsutym teście i przy błędzie analizy.
  - K0.2 Build release bez prawdziwego klucza kończy się błędem; build debug działa.
  - K0.3 Termin wypłaty na Dashboardzie zgadza się z tabelą co najmniej 12 przypadków testowych dla cyklu miesięcznego, tygodniowego i dwutygodniowego (w tym koniec miesiąca i luty).
  - K0.4 Przerwanie restore w każdym kroku (test z wstrzykniętym błędem) zostawia dane identyczne ze stanem sprzed restore.
  - K0.5 Kopia v2 z wersji 1.0 wczytuje się, a sumy zarobków, napiwków i godzin per okres są identyczne.
  - K0.6 Po starcie i po powrocie z tła aplikacja wymaga uwierzytelnienia i nie pokazuje danych przed nim (test widgetowy).
  - K0.7 Błąd zapisu ustawień jest zgłaszany, a nie ignorowany (test).
  - K0.8 Kalkulator ma `calc_version = 1` i fikstury; zmiana wyniku bez nowej wersji kończy test błędem.
- **Testy akceptacyjne:** testy K0.1–K0.8 oraz test migracji z plików baz v1–v4.

## M1 — „Prawdziwy czas pracy” (L)

**Kolejność wewnętrzna** (każdy punkt jest wydawalny osobno; bez nowego etapu):

1. **M1.1 Model czasu i zmiany:** `timezone_id`, `actual_start/end`, `Break`, migracja addytywna, kalkulator czasu na znacznikach, `Money`. *Widoczne:* poprawne godziny przez noc i zmianę czasu dla nowych zmian, wiele przerw w formularzu zmiany; historyczne zmiany zachowują wartości i dostają status do weryfikacji (C.6c). *Zależność:* biblioteka stref zatwierdzona (decyzja 3.2/1); 🔬 PoC biblioteki i testów DST w tym kroku (C.6a).
2. **M1.2 Action Layer v0:** `StartShift`, `StartBreak`, `ResumeShift`, `EndShift`, `AddTips`, szkielet propozycji i `AuditEntry`; zapis natychmiastowy i odtwarzanie po awarii.
3. **M1.3 Timer i slot główny Dashboardu:** Zaczynam / Przerwa / Wznów / Koniec, stany przed, podczas i po zmianie, trwałe powiadomienie z chronometrem odtwarzane po restarcie, pytanie o zapomnianą zmianę.
4. **M1.4 Szybkie rozliczenie:** klawiatura numeryczna, `earnings_confirmed_at`, przypomnienie „wpisz napiwki”, lista braków w Centrum kontroli danych.
5. **M1.5 Asystent v0 i szybkie akcje:** zakładka z paletą poleceń i odpowiedziami z szablonów (bez modelu), kafelek i skróty aplikacji.
6. **M1.6 Bramka Drift:** PoC na końcu etapu (C.4), z kryterium przejęcia schematu z M1.1.

- **Zależności wejściowe:** M0 zakończone; 🔬 audyt `Tip.hours` i `Shift.durationMin`; PoC biblioteki stref w M1.1.
- **Kryteria akceptacji M1** (każde kończy się wynikiem tak lub nie):
  - K1.1 Czas zmian z `time_model = instants` jest liczony wyłącznie ze znaczników; testy z C.6a przechodzą przy wymuszonej strefie testowej.
  - K1.2 Aktywna zmiana i przerwa są odtwarzane po zabiciu procesu (test automatyczny) oraz po restarcie telefonu (🔬 test ręczny na urządzeniu; wynik nie jest jeszcze znany).
  - K1.3 Przerwy płatne i niepłatne wchodzą do czasu płatnego zgodnie z S1 (kroki 2–3).
  - K1.4 Każde polecenie Action Layer ma test poprawnego wejścia i test odrzucenia błędnego wejścia.
  - K1.5 Migracja kopii bazy z wersji 1.0: sumy zarobków, napiwków i godzin per okres identyczne, bez wyjątków; rekordy `needs_review` mają niezmienione wartości (C.6c).
  - K1.6 Druga aktywna zmiana jest odrzucona.
  - K1.7 Raport PoC Drift odpowiada na kryteria (a)–(e) z C.4 (wynik jeszcze nieznany).
- **Testy akceptacyjne M1:** komplet testów z C.6a, C.6b i C.6c, scenariusz S1 kroki 1–5 na bazie w pamięci, test migracji z kopii wersji 1.0.

## M2 — „Moje miejsca, moje zasady” (L)

- **Zależności wejściowe:** M1; 🔬 audyty `Tip.tipOut` i `Tip.sales`; specyfikacja kontroli kasy i zasad kompensacji napiwków kartowych w lokalach właściciela (sekcja I); wynik PoC Drift.
- **Widoczne:** profile miejsc pracy (Gastronomia, Ogólny, Własny), historia stawek, stanowiska, dodatki, reguły tip-outu ze sposobem rozliczenia i kontrolą gotówki, **metoda rozliczania napiwków kartowych per miejsce pracy** (wypłata przez pracodawcę, bezpośrednio, kompensacja z utargiem) z osobną linią kompensacji w rozliczeniu zmiany, święta i nadgodziny per miejsce, „skąd ta kwota”, utarg i kontrola kasy jako raport zmiany, pełne Centrum kontroli danych.
- **Fundament:** katalog składników z polami rodzaj i znak, kanał (w tym `other`), podmiot i sposób rozliczenia tip-outu (F.1), `WageRate`, `EarningLine`, **`ShiftReport` jako kanoniczne źródło z migracją `Tip.sales` (C.5a)**, **`Offset` i `cash_due` (F.2b)**, kontrola tip-outu względem gotówki (F.2a), drzewo wyjaśnień kalkulatora, migracje z testami.
- **AI:** pierwsze narzędzia odczytu i wyjaśnienia deterministyczne.
- **Test uniwersalności ✅ (decyzja 3.1/11):** profil „Handel detaliczny” skonfigurowany wyłącznie z istniejących składników, bez zmian w kodzie domenowym.
- **Bramka decyzji:** Riverpod 🔬, tylko jeśli konkretny moduł rzeczywiście tego wymaga.
- **Kryteria akceptacji M2:**
  - K2.1 Dwa miejsca pracy z różnymi stawkami, zasadami, strefami i metodami napiwków kartowych liczą się niezależnie.
  - K2.2 Sześć przykładów z F.1 daje opisane skutki (testy tabelaryczne).
  - K2.3 Składnik `other` wymaga podmiotu i nie wchodzi do żadnego salda (test).
  - K2.4 `cash_shortfall` blokuje ciche zapisy (testy z F.2a).
  - K2.5 Po migracji każdy `Tip` z niepustym `sales` ma `ShiftReport` o tej samej wartości; żadna ścieżka zapisu nie dotyka `Tip.sales` (test architektury).
  - K2.6 Przykłady A–C z F.2b dają wartości z tabeli; limity (a)–(c) działają; brak `cash_due` nie tworzy kompensacji.
  - K2.7 Zmiana stawki od daty nie zmienia przeszłości.
  - K2.8 Profil handlu działa bez zmian w kodzie domenowym.
- **Testy akceptacyjne:** K2.1–K2.8 jako testy automatyczne oraz dodatek nocny na segmentach w nocy zmiany czasu i niezmienniki z F.10.

## M3 — „RITMO AI” (L)

**Kolejność wewnętrzna** (nic z zaplanowanych funkcji nie jest usuwane; elementy AI nie powstają jednocześnie, a każdy punkt jest wydawalny osobno):

1. **M3.1 Podstawowy interfejs tekstowy AI:** AI Workspace (rozmowa, paleta poleceń z M1), Historia rozmów (lokalna), znacznik trybu; działa w trybie deterministycznym.
2. **M3.2 Jeden dostawca i `ModelProvider`:** `ProviderConfig`, router, adapter BYOK ✅ (prywatna wersja), kontrola kosztów, zgody, `SentDataLog` i Data Gate (D.3a, D.4a).
3. **M3.3 Deterministyczne narzędzia odczytu:** `earnings_summary`, `schedule`, `compare_periods`, `workplace_performance`, `find_data_issues`, `search_entries`; liczby związane ze źródłem (D.9).
4. **M3.4 Propozycje operacji wymagające zatwierdzenia:** `Proposal`, token zatwierdzenia, Policy Engine, karty propozycji i skrzynka zatwierdzeń; `propose_shift`, `propose_schedule`, `propose_tips_entry`, `propose_rate_change`; test architektury (`ai/` zależy tylko od `application/`).
5. **M3.5 Pamięć profilu i oddzielenie jej od historii czatu:** `AiMemory`, ekran pamięci, niezależne usuwanie, domyślnie 90 dni historii ✅ (decyzja 3.2/8).
6. **M3.6 Obsługa głosu v1:** polecenia zamknięte (parser deterministyczny), podgląd z odczytem, potwierdzenie.
7. **M3.7 Kolejne rozszerzenia:** kontekstowe wejścia „Zapytaj o to” na ekranach, drugi dostawca i on-device tylko wtedy, gdy PoC to uzasadni.

- **Zakres ✅ (decyzja 3.1/15):** analiza grafiku, zarobków, napiwków i jakości danych oraz propozycje działań. M3 **nie obejmuje** uzgadniania wypłat, różnic ani zamknięć okresów; narzędzia `explain_payout_difference`, `propose_period_closure`, `propose_payout`, `propose_correction` i `propose_card_tip_offset` powstają w M4.
- **Zależności wejściowe:** M1 (Action Layer) i M2 (składniki, kanały, narzędzia odczytu).
- **Kryteria akceptacji M3:**
  - K3.1 Asystent odpowiada wyłącznie liczbami pochodzącymi z narzędzi (test zestawem pytań kontrolnych).
  - K3.2 Żaden zapis bez zatwierdzenia; w module `ai/` nie istnieje ścieżka zatwierdzenia (test architektury).
  - K3.3 Bez sieci i dostawcy aplikacja działa w trybie deterministycznym.
  - K3.4 Usunięcie historii rozmów nie usuwa pamięci i odwrotnie.
  - K3.5 Każde zapytanie do dostawcy jest w `SentDataLog`; poziomy S2 i S3 wymagają decyzji przy każdym poleceniu (D.3a).
  - K3.6 Limit kosztów zatrzymuje wywołania i przełącza w tryb deterministyczny.
  - K3.7 Instrukcja ukryta w tekście importu nie wywołuje żadnej operacji (test).
- **Testy akceptacyjne:** K3.1–K3.7 oraz zestaw pytań kontrolnych na bazie testowej.

## M4 — „Wypłata się zgadza” (L)

- **Zależności wejściowe:** M2 (składniki, kanały, `ShiftReport`, `Offset`), M1 (zmiana, Action Layer), M3 (infrastruktura narzędzi i propozycji).
- **Widoczne:** wypłaty, zaliczki, wypłaty częściowe, przypisanie jednej wypłaty do kilku okresów z widoczną częścią niealokowaną, wpływ kompensacji napiwków kartowych na saldo i uzgodnienie, zamknięcie okresu z odtwarzalną migawką, korekty, raport PDF i dowód godzin.
- **Fundament:** `Payout`, `PayoutAllocation`, `PeriodClosure`, `ClosureItem`, `ClosureRules`, `Adjustment`, `ReplayClosure` i skróty danych (F.5a), audyt, blokada edycji zamkniętych danych (bez ponownego otwierania okresów).
- **AI ✅ (rozszerzenie M3):** `explain_payout_difference`, `propose_period_closure`, `propose_payout`, `propose_correction`, `propose_card_tip_offset`.
- **Bezpieczeństwo:** szyfrowany backup hasłem. 🔬 Szyfrowanie bazy po analizie zagrożeń.
- **Kryteria akceptacji M4:**
  - K4.1 Replay każdego zamknięcia daje identyczne linie i sumy; zmiana stawki, ustawień, reguły tip-outu i wersji kalkulatora po zamknięciu nie zmienia odtworzonego wyniku (fikstury wszystkich wersji).
  - K4.2 Przykłady F.6a i przykład C z F.2b dają podane salda; zależność `B(W)` = suma `B(P)` minus niealokowane jest spełniona we wszystkich testach.
  - K4.3 Edycja zamkniętej zmiany bez `Adjustment` jest niemożliwa; okres nie ma operacji ponownego otwarcia.
  - K4.4 Kompensacja nie pojawia się w „otrzymane od pracodawcy” i nie przechodzi przez alokacje ani FIFO.
  - K4.5 Edycja lub usunięcie wypłaty po zamknięciu tworzy wpis audytu i nie zmienia snapshotu.
  - K4.6 Zaliczka niealokowana, a potem przypisana: `B(W)` bez zmiany.
  - K4.7 Scenariusz S1 w całości oraz jego warianty przechodzą.
- **Testy akceptacyjne:** K4.1–K4.7, odmowa edycji zamkniętej zmiany (prowadzi do `Adjustment`), eksport PDF zgodny z liczbami na ekranie.

## M5 — „Dashboard premium” (M)

- **Widoczne:** pełna personalizacja kart, widget „Dziś”, analityka z porównaniami miejsc i dni, dopracowany design system (wykresy, dostępność).
- **Kryteria ukończenia:** personalizacja nie ukrywa pasa „Wymaga uwagi”; widget odzwierciedla stan aktywnej zmiany także po restarcie; przycisk „Przywróć układ automatyczny” działa.
- **Testy akceptacyjne:** przywracanie układu automatycznego, widget przy zmianie w toku, dostępność (TalkBack, tekst 200%).

## M6 — „Przechwytywanie” (L)

- **Widoczne ✅ (decyzja 3.1/16):** import grafiku z udostępnionego tekstu, potem OCR ustalonego formatu grafiku, potem OCR paska wynagrodzenia (wymaga M4), eksport do kalendarza, głos v2 z intencjami przez model. Paragony w M7.
- **Fundament:** potok OCR, `ImportRecord`, deduplikacja, ekran weryfikacji.
- **Kryteria ukończenia:** żaden import nie zapisuje bez zatwierdzenia; ponowny import tego samego dokumentu nie tworzy duplikatów; użytkownik może usunąć obraz źródłowy.
- **Testy akceptacyjne:** idempotencja importu; niejednoznaczna data lub kwota daje ostrzeżenie; kolizja z istniejącym grafikiem; odmowa uprawnień do kalendarza nie psuje aplikacji.

## M7 — „Prognozy, cele i Money lite” (L)

- **Widoczne:** prognoza w zakresie zależnym od jakości danych (brak, sama mediana albo trzy scenariusze, F.8), cele, Safe-to-Spend w dwóch wariantach (F.9), rachunki i proste wydatki, OCR paragonów.
- **Wymagania jakości danych:** prognoza napiwków nie jest pokazywana poniżej progu danych; progi i długość historii są kalibrowane na danych zebranych w M1–M6 (🔬); Safe-to-Spend podstawowy działa bez salda i bez prognozy. Etap zależy od M4 (należności) i od `earnings_confirmed_at` z M1.
- **Kryteria ukończenia:** każda prognoza ma oznaczenie jakości, liczbę zmian i założenia; wariant rozszerzony oznacza nieaktualne saldo.
- **Testy akceptacyjne:** próbki 7, 8, 19, 20 i 40 zmian dają kolejno brak prognozy, medianę, medianę, trzy scenariusze, trzy scenariusze z jakością „dobra” (przy co najmniej 8 tygodniach); Safe-to-Spend nie liczy podwójnie po aktualizacji salda.

## M8 — „Gotowość produktowa” (L)

- **Widoczne:** kolejne profile branżowe zweryfikowane z prawdziwymi użytkownikami (handel detaliczny jako pierwszy), onboarding, język polski; angielski później ✅ (decyzja 3.1/17).
- **Brama decyzji przed M8 ✅ (decyzja 3.1/17):** publikacja, model płatności, nazwa i marka, monetyzacja i ewentualny dostęp zarządzany do AI wracają dopiero przed M8. Do tego czasu nie ponosimy kosztów publikacji.
- **Kryteria i testy:** pełna regresja na prawdziwych telefonach, scenariusz S1 zielony dla każdego profilu, walidacja profilu handlu z realnym użytkownikiem.

**Zależności etapów (sprawdzone w v1.2):**

| Etap | Wymaga | Warunki wejścia (audyt, PoC, decyzja) | Dostarcza |
| --- | --- | --- | --- |
| M0 | brak | 🔬 audyt `Tip.hours`, `Shift.durationMin` przed M1.1 | CI blokujące, `calc_version = 1`, blokada, atomowy restore |
| M1 | M0 | PoC biblioteki stref (M1.1); PoC Drift na końcu | model czasu, zmiana i przerwy, Action Layer v0, timer, Asystent v0 |
| M2 | M1 | 🔬 audyty `Tip.tipOut`, `Tip.sales`; specyfikacja kontroli kasy i kompensacji; wynik PoC Drift | składniki z kanałami, `ShiftReport`, `Offset`, profile, historia stawek |
| M3 | M1, M2 | brak | AI Workspace (M3.1–M3.7), dostawca, narzędzia odczytu i propozycje |
| M4 | M2, M3 | brak | wypłaty, alokacje, zamknięcia z replay, korekty, uzgodnienie |
| M5 | M1, M4 | brak | personalizacja Dashboardu, widget, analityka |
| M6 | M3, M4 | brak | import grafiku i OCR (pasek wymaga M4), kalendarz, głos v2 |
| M7 | M4 i dane z M1–M6 | 🔬 kalibracja progów | prognozy, cele, Safe-to-Spend, paragony |
| M8 | M1–M7 | decyzje komercyjne ✅ (3.2/15) | profile branżowe, onboarding, publikacja |

## G.1. Scenariusz integracyjny S1 (test kluczowy)

🔷 S1 jest jednym z najważniejszych testów integracyjnych projektu. Dane: miejsce pracy w strefie Europe/Warsaw, stawka 30,00 zł/h, profil Gastronomia (napiwki kartą: kanał `employer`; tip-out 10% napiwków, sposób `from_cash`), okres miesięczny.

| Krok | Akcja | Oczekiwany wynik |
| --- | --- | --- |
| 1 | Zaplanowanie zmiany 16:00–23:00 | status `planned`; wynagrodzenie z planu 210,00 zł jako szacunek |
| 2 | Rejestracja rzeczywistego czasu: start 16:10, koniec 23:20 | `completed`; czas 7 h 10 min (430 min) |
| 3 | Przerwy: niepłatna 30 min, płatna 15 min | czas płatny 400 min (6 h 40 min); wynagrodzenie 200,00 zł |
| 4 | Napiwki: gotówka 120,00 zł, karta 80,00 zł; potwierdzenie „wszystko wpisane” | `earnings_confirmed_at` ustawione |
| 5 | Obliczenie zarobku i tip-outu | tip-out 20,00 zł (`from_cash`; dostępna gotówka 120,00 ≥ 20,00, brak ostrzeżenia); zarobione 380,00 zł; bezpośrednio: wpływ 120,00, oddane 20,00; składniki `employer` 280,00 zł, więc R(P) = 280,00 |
| 6 | Zamknięcie okresu | snapshot: kopie zmiany, przerw, stawki 30,00 zł/h, składników, reguły tip-outu, zaokrągleń; `calc_version = 1`; skróty danych; replay daje identyczne linie i sumę 380,00 zł; edycja zmiany bez korekty zablokowana |
| 7 | Częściowa wypłata od pracodawcy 150,00 zł, alokacja FIFO do okresu | otrzymane od pracodawcy 150,00; niealokowane 0,00; B(P) = B(W) = 280,00 − 150,00 = 130,00; gotówka bez wpływu na saldo |
| 8 | Uzgodnienie należności i otrzymanych pieniędzy | 280,00 minus 150,00 = 130,00 zł; rozbicie różnicy bez udziału 120,00 zł gotówki |
| 9 | Korekta: przerwa 30 min była płatna | `Adjustment` +15,00 zł (30 zł/h × 0,5 h), kanał `employer`, zapisany powód |
| 10 | Migawka, odtwarzalność i historia | pierwotna migawka nadal 380,00 zł; wynik efektywny 395,00 zł; B(P) = B(W) = 295,00 − 150,00 = 145,00 zł; zmiana stawki na 32,00 zł/h i nowa wersja kalkulatora po zamknięciu nie zmieniają odtworzonego wyniku 380,00 zł; wpisy audytu dla zamknięcia, wypłaty, alokacji i korekty; wszystkie ekrany pokazują te same liczby |

**Warianty obowiązkowe:**

- **S1-DST:** ta sama zmiana planowana 22:00–06:00 w nocy zmiany czasu daje 7 h wiosną i 9 h jesienią.
- **S1-OFFSET (pełna kompensacja):** miejsce pracy z metodą `offset_against_takings`, utarg gotówkowy do rozliczenia 800,00 zł. Napiwki kartowe 80,00 zł są w pełni skompensowane: gotówka do przekazania 720,00 zł; zarobione nadal 380,00 zł; R(P) = 280,00; B(P) = 280,00 − 80,00 = 200,00; po wypłacie 150,00 zł B(P) = B(W) = 50,00; „otrzymane od pracodawcy” 150,00, „skompensowane z utargiem” 80,00 (osobno).
- **S1-SHORT (niewystarczający utarg):** utarg gotówkowy 50,00 zł: kompensacja 50,00, gotówka do przekazania 0,00, pozostałe 30,00 zł napiwków kartowych zostaje należnością; B(P) = 280,00 − 50,00 = 230,00.

**Warunki:** test działa w CI bez sieci, na bazie w pamięci, ze stałą strefą testową; blokuje release i musi przechodzić po każdej zmianie modelu.

---

# H. Ryzyka

**Techniczne**

- Migracja danych przy przebudowie modelu (*mitygacja:* tylko zmiany addytywne, kopia pliku przed migracją, testy na prawdziwych bazach, zachowanie importu backupu v2).
- Natywny Android w CI i dryf zależności (*mitygacja:* `android/` w repo, przypięte wersje, aktualizacje pojedynczo).
- Zbyt wiele równoległych zmian stosu (*mitygacja:* bramki decyzji, jeden mechanizm na moduł).
- Błędy czasu i DST (*mitygacja:* jedno miejsce obliczania, testy graniczne).
- Wolna pętla przez CI (*mitygacja:* szybkie testy jednostkowe, integracyjne nocnie lub ręcznie).

**Produktowe**

- Rozmycie zakresu (*mitygacja:* rdzeń najpierw, Money lite jako moduł).
- Przedwczesne uogólnianie profili (*mitygacja:* reguła trzech, najpierw Gastronomia i Ogólny).
- Niejasna grupa docelowa po publikacji (*mitygacja:* weryfikacja z kilkoma użytkownikami z innych branż przed M8).
- Złożoność ustawień rozliczeń dla zwykłego użytkownika (*mitygacja:* gotowe profile i podgląd na przykładzie).

**Finansowe**

- Błędne liczby niszczą zaufanie (*mitygacja:* jeden kalkulator, scenariusze złote, wyjaśnienia, zamrożone migawki).
- Błędna konfiguracja reguł przez użytkownika (*mitygacja:* podgląd, walidacja, Centrum kontroli danych).
- Odbiór aplikacji jako doradztwa podatkowego (*mitygacja:* brak obliczeń netto, jasne oznaczenia).
- Nieporozumienie co do „nadal należne od pracodawcy” i błędnie ustawiony kanał składnika, np. napiwki kartą wypłacane gotówką (*mitygacja:* kanał i podmiot z F.1, niezmienniki F.10, domyślne ustawienia profilu, przykłady w ustawieniach).

**AI**

- Halucynacje liczbowe (*mitygacja:* liczby związane ze źródłem).
- *Prompt injection* z dokumentów (*mitygacja:* dokumenty jako dane, zapis tylko przez propozycje, brak narzędzia „zapisz”).
- Zmiany jakości po aktualizacji modelu (*mitygacja:* zestaw pytań kontrolnych, przypięta wersja modelu).
- Koszty i limity (*mitygacja:* limity, widoczne zużycie, BYOK).
- Zbyt duże zaufanie do odpowiedzi (*mitygacja:* oznaczenia fakt/szacunek/prognoza, widoczne źródła).
- Ograniczenia on-device (dostępność, praca tylko na pierwszym planie), jakość języka polskiego (*mitygacja:* tryb deterministyczny jako baza).

**Prywatność**

- Wysłanie danych finansowych do chmury (*mitygacja:* zgody per dostawca, agregaty, dziennik wysłanych danych, aliasowanie).
- Przechowywanie klucza BYOK (*mitygacja:* bezpieczne przechowywanie, brak klucza w kodzie).
- Pamięć asystenta i skany dokumentów (*mitygacja:* pamięć bez liczb, kontrola usuwania, prywatny katalog).
- Kopie systemowe i powiadomienia na ekranie blokady (*mitygacja:* ustawienia Androida, powiadomienia bez kwot).
- Po publikacji: jeśli powstanie serwer pośredniiczący AI, zmienia się rola prawna wobec danych (*mitygacja:* decyzja przed M8).

**Utrzymanie**

- Jeden programista i długi harmonogram (*mitygacja:* etapy z wartością użytkową, mniej technologii).
- Coroczne wymagania Androida (`targetSdk`) i zmiany wtyczek (*mitygacja:* przypięte wersje, kalendarz przeglądów).
- Utrzymanie dostawców AI i promptów (*mitygacja:* interfejs dostawcy, zestaw kontrolny).
- Dokumentacja i testy jako warunek każdego pakietu.

**Ryzyka dodane w v1.1**

- **Techniczne:** nowa zależność bazy stref (koszt utrzymania, rozmiar; *mitygacja:* izolacja za jedną funkcją `resolveLocal`, decyzja do zatwierdzenia). PoC Drift po M1 oznacza, że migracje M1 powstają w sqflite (*mitygacja:* przejęcie schematu jako kryterium PoC). Zmiana modelu czasu zmienia wynik dla nocy zmiany czasu (*mitygacja:* C.10). Testy czasu w CI działają w UTC (*mitygacja:* wymuszona strefa testowa).
- **Produktowe:** semantyka kanałów jest dla użytkownika nowa i trudniejsza niż „napiwki” (*mitygacja:* domyślne wartości profilu, przykłady, podgląd skutków). Zakres rośnie o `PayoutAllocation`, `ShiftReport`, historię rozmów, kontrolę kosztów i `BalanceAnchor` (*mitygacja:* każdy element wynika z decyzji 3.1, przegląd zakresu na końcu M2).
- **Finansowe:** edytowalność wypłat po zamknięciu okresu może podważyć zaufanie (*mitygacja:* audyt, rozdzielenie „zarobione” od „otrzymane”). Progi prognoz ustawione bez danych (*mitygacja:* kalibracja po M6, oznaczenia jakości).
- **AI:** historia rozmów może zawierać kwoty (*mitygacja:* lokalnie, poza kopią i chmurą domyślnie, znacznik „stan na DATA”, usuwanie, tryb bez zapisu). Przejście na dostęp zarządzany bez przebudowy (*mitygacja:* adapter i konfiguracja odrębne od narzędzi, test zależności `ai/`). Koszty BYOK ponosi użytkownik (*mitygacja:* limity i widoczne zużycie).
- **Prywatność:** klucze dostawców (magazyn systemowy, poza kopią); dziennik wysłanych danych sam jest wrażliwy (lokalny, kasowalny).
- **Utrzymanie:** przypomnienia wymagają zgody na powiadomienia i na Androidzie mogą nie być dokładne co do minuty (*mitygacja:* tolerancja kilku minut).

**Ryzyka dodane w v1.2**

- **Techniczne:** utrzymanie starych wersji kalkulatora (koszt, regresje); rozmiar snapshotu i czas replay przy dużej liczbie zmian 🔬; migracja `ShiftReport` zależy od audytu `Tip.sales`.
- **Produktowe:** kompensacja z utargiem to kolejna metoda do skonfigurowania (*mitygacja:* wartości domyślne, podgląd skutków, przykłady w ustawieniach). Wiele rekordów `needs_review` mogłoby przytłoczyć użytkownika (*mitygacja:* grupowanie, praca nie jest blokowana, zbiorcze zastosowanie wyłącznie po podglądzie).
- **Finansowe:** błędnie skonfigurowana metoda napiwków kartowych (wypłata zamiast kompensacji lub odwrotnie) zniekształci saldo (*mitygacja:* podgląd skutków, kontrola limitów F.2b 3(c), Centrum kontroli danych). Pomylenie `Offset` z `Payout` (*mitygacja:* osobne pozycje, niezmienniki F.6).
- **AI i prywatność:** Data Gate to nowy element do utrzymania; pseudonimizacja nie jest anonimizacją, więc S1 ogranicza się do agregatów (*mitygacja:* przegląd treści wysyłanych do dostawcy w zestawie pytań kontrolnych).
- **Utrzymanie:** zestaw fikstur zamknięć rośnie z każdą wersją kalkulatora (*mitygacja:* fikstury małe i generowane z kodu testów).

---

# I. Otwarte decyzje (potrzebuję Twojej decyzji)

Sekcja jest uporządkowana według kategorii: **rozstrzygnięte koncepcyjnie**, **wymagające audytu obecnego kodu**, **wymagające PoC lub testów** (wyniki nie są jeszcze znane i nie są tu przedstawiane jako znane), **odłożone do M8** oraz **wymagające Twojej decyzji jako właściciela**. Zatwierdzone wcześniej decyzje (24 z Etapu 3 i 18 z Etapu 3.1) nie są powtarzane.

**1. Rozstrzygnięte koncepcyjnie ✅ (domyślne rozstrzygnięcia z Etapu 3.2)**

1. (3.2/1) Biblioteka stref IANA z testami DST (C.6a).
2. (3.2/2) Jedna aktywna zmiana na użytkownika (C.6b).
3. (3.2/3) Obsługa godzin niejednoznacznych i nieistniejących z ostrzeżeniem (C.6a).
4. (3.2/4) Brak automatycznego przeliczania historycznych danych finansowych (C.6c, C.10).
5. (3.2/5) Migracja `Tip.tipOut` nie jest ustalana bez audytu (F.1).
6. (3.2/6) Wypłaty po zamknięciu okresu: rejestracja i edycja z pełnym audytem, bez otwierania okresu (F.5, F.6).
7. (3.2/7) Polski kalendarz świąt na początek, architektura rozszerzalna (F.4).
8. (3.2/8) Historia AI przechowywana domyślnie 90 dni, z możliwością wyłączenia (D.5).
9. (3.2/9) Test profilu handlu z użytkownikiem spoza gastronomii przed M8 (B.3, M8).
10. (3.2/10) Drift: PoC po M1, zanim zapadnie decyzja o migracji (C.4).
11. (3.2/11) Riverpod: bez automatycznej migracji; decyzja zależy od PoC i rzeczywistej potrzeby (C.3).
12. (3.2/12) Szyfrowanie bazy: decyzja po analizie zagrożeń (C.8).
13. (3.2/13) API 26 jako propozycja wymagająca testów na urządzeniach (C.9).
14. (3.2/14) Progi prognoz z F.8 jako wartości początkowe do kalibracji.
15. (3.2/15) Publikacja i monetyzacja pozostają w M8.
16. (3.2/16) Abstrakcja `ModelProvider` zachowana; bez ostatecznego wyboru między BYOK a modelem zarządzanym; bez kluczy dostawcy w aplikacji (D.4a).

**2. Wymagają audytu obecnego kodu 🔬 (wyniki nieznane)**

- Audyt `Tip.tipOut`: znaczenie, znak, relacja do sumy napiwków. Warunek migracji pola. Przed M2.
- Audyt `Tip.sales`: czy to sprzedaż ogółem, czy utarg gotówkowy; wartość pusta a 0; miejsca użycia; mapowanie do `ShiftReport` (C.5a) i `cash_due` (F.2b). Przed M2.
- Audyt `Tip.hours` i `Shift.durationMin`: źródła godzin, przejścia przez północ. Przed M1.1.

**3. Wymagają PoC lub testów 🔬 (wyniki nieznane)**

- PoC Drift i migracji z obecnego sqflite (koniec M1).
- PoC biblioteki stref i testy DST (M1.1).
- Testy odzyskiwania aktywnego timera po awarii i po restarcie telefonu (M1).
- Testy minimalnej wersji Androida (API 26+) na urządzeniach.
- Testy wydajności i niezawodności: replay i zamknięcie okresu przy dużej liczbie zmian, restore, migracje, start z dużą bazą. Budżety ustalane w Stage 4.
- Utrzymanie starych wersji kalkulatora i rozmiar snapshotu (F.5a).
- Kalibracja progów prognoz i nieaktualności salda (F.8, F.9) na danych z M1–M6.
- Dostępność AI on-device na urządzeniach właściciela.
- Analiza zagrożeń przed decyzją o szyfrowaniu bazy.

**4. Odłożone do M8 ✅**

- Monetyzacja, model publikacji, nazwa i marka, strategia komercyjna.
- Ostateczny wybór między BYOK a modelem zarządzanym i kolejni dostawcy. Architektura ma umożliwiać BYOK, zarządzany dostęp, kolejnych dostawców i działanie bez AI; w aplikacji mobilnej nie ma kluczy dostawcy.
- Wersja angielska.

**5. Wymagają Twojej decyzji jako właściciela**

1. **Specyfikacja kontroli kasy i `ShiftReport`:** jakie dane (np. gotówka policzona, oczekiwana, różnica) i jak mają działać w Twoich lokalach. Przed M2.
2. **Zasady kompensacji napiwków kartowych w lokalach, które ją stosują (F.2b):** czy kompensacja częściowa jest dozwolona, czy dopuszczamy kompensację z utargu innej zmiany (`offset_across_shifts`) i jaka jest kolejność przy kilku zmianach. Domyślnie przyjmuję: częściowa tak, z innej zmiany nie, reszta jako należność. Przed M2.
3. **Dozwolone sposoby rozliczenia tip-outu per stanowisko (F.2a):** które są realne w Twoich lokalach (domyślnie wszystkie trzy konfigurowalne). Przed M2.
4. **Użytkownik testowy z handlu detalicznego (3.2/9):** kto i kiedy. Test konfiguracji w M2 nie wymaga osoby, walidacja z człowiekiem przed M8.
5. **Zatwierdzenie wersji 1.2 i przejścia do Stage 4.**

---

# Rekomendowana wersja RITMO Professional

**Produkt:** osobisty system pracy i pieniędzy dla osób zmianowych, zbudowany na jednej pętli **Zmiana → Zarobek → Wypłata**. Gastronomia jest pełnym profilem początkowym, reszta branż korzysta ze wspólnego rdzenia i składników.

**Co czyni go innym:**

1. Uzgodnienie wypłaty z rozbiciem „skąd ta różnica” i dowodem godzin.
2. Rozliczenia składane z kontrolowanych składników per miejsce pracy, z wyjaśnieniem każdej kwoty.
3. Asystent RITMO AI, który naprawdę obsługuje aplikację (tekst, głos, dokumenty), ale zapisuje tylko to, co zatwierdzisz, i nie wymyśla liczb.
4. Szybkość codziennej obsługi: Zaczynam → Koniec → 10 sekund na rozliczenie.
5. Local-first i prywatność jako cecha produktu.

**Jak jest zbudowany:** istniejący Flutter, czysty rdzeń domenowy, **Action Layer** jako jedyne API dla UI, głosu, powiadomień i AI, `sqflite` (Drift po PoC), natywne moduły w trwałym `android/`, minimalne nowe zależności.

**Jak go budujemy:** dziewięć etapów, z których każdy dostarcza widoczną wartość. Najpierw pewne liczby (M0), potem prawdziwy czas pracy (M1), moje zasady (M2), AI (M3), wypłaty i zamknięcia (M4), Dashboard premium (M5), przechwytywanie dokumentów (M6), prognozy i Money lite (M7), gotowość produktowa (M8).

**Czego nie robimy:** AIS, edytora reguł, geofencingu, obliczeń netto, pełnego budżetu kopertowego, synchronizacji w chmurze, lokalnych modeli otwartych, agenta działającego w tle bez zgody.

**Moja największa zmiana względem poprzednich propozycji:** AI przestaje być późnym dodatkiem i staje się centralną warstwą interfejsu, ale właśnie dlatego musi opierać się na Action Layer i jednym kalkulatorze. To one, a nie wybór modelu, decydują o tym, czy asystent będzie użyteczny i bezpieczny.

---

# Podsumowanie zmian względem v1.0

- **Decyzje:** 18 decyzji z Etapu 3.1 uwzględniono (tabela niżej). Sekcja I skrócona z 18 do 16 punktów, w tym 5 rozstrzygalnych dopiero po PoC lub testach.
- **Czas (C.5, C.6, C.6a, C.6b, F.4):** strefa IANA, jedna funkcja `resolveLocal`, reguły dla godzin niejednoznacznych i nieistniejących, segmentacja okien czasowych, testy niezależne od strefy maszyny. Cykl życia zmiany z wieloma przerwami, timerem opartym na zapisanym `actual_start` i odtwarzaniem po awarii.
- **Model składnika (F.1, F.2):** `paidBy` zastąpione czterema niezależnymi informacjami (rodzaj i znak, kanał, podmiot, sposób rozliczenia tip-outu); sześć przykładów, niezmienniki, domyślne ustawienia dla istniejących danych.
- **Dane (C.5, C.10):** opcja C potwierdzona; dodano `Break`, `ShiftReport`, `PayoutAllocation`, `AiThread`/`AiMessage`/`AiMemory`, `BalanceAnchor`; nowa sekcja ochrony istniejących danych i backupu v2.
- **Wypłaty i zamknięcia (F.5, F.6):** bez ponownego otwierania okresów; cztery rozdzielone liczby; przypisanie wypłat do wielu okresów, FIFO z ręczną korektą, zaliczki, ujemne saldo.
- **Prognozy i Safe-to-Spend (F.8, F.9):** progi danych, oznaczenie jakości, sama mediana przy małej próbce; dwa warianty Safe-to-Spend.
- **AI (D.2–D.5, D.4a, D.7, D.10, D.11):** egzekwowanie braku obejścia Action Layer, tryby dostępu i konfiguracja odrębna od narzędzi, kontrola kosztów i zgody, cztery warstwy kontekstu, historia rozmów odrębna od pamięci, dostępność narzędzi według etapów.
- **UX (E.1, E.3, E.4, E.5):** nawigacja potwierdzona, cztery liczby w widoku okresu, wiele przerw, osobne widoki historii i pamięci.
- **Plan (G):** M1 rozpisany na M1.1–M1.6; poprawne godziny w nocy zmiany czasu przeniesione z M0 do M1.1; M3 bez uzgadniania wypłat; M7 z wymaganiami jakości danych; kryteria ukończenia i testy dla każdego etapu; scenariusz S1; zależności.
- **Ryzyka i decyzje (H, I):** ryzyka dodane w v1.1; sekcja I tylko z kwestiami nierozstrzygniętymi.
- **Bez zmian:** wizja, zakres produktu, zasady z A.5, warstwy architektury, Action Layer, jeden kalkulator, „AI proponuje, użytkownik zatwierdza”, tożsamość wizualna, brak AIS, geofencingu, edytora reguł i synchronizacji w chmurze.

# Decyzje właściciela uwzględnione w v1.1

| Nr | Decyzja (Etap 3.1) | Gdzie w dokumencie |
| --- | --- | --- |
| 1 | Opcja C, bez `WorkSession` | C.5, C.6b |
| 2 | Niezmienna migawka i korekty, bez ponownego otwierania | F.5, E.4, G (M4) |
| 3 | `Tip` zostaje, `EarningLine` dla nowych składników | C.5, F.1, F.2 |
| 4 | Pięć zakładek; Money lite modułem w ustawieniach; bez przełącznika trybów | E.1, B.2 |
| 5 | BYOK nie jedyną drogą; dostęp zarządzany bez przebudowy | D.4, D.4a |
| 6 | Do chmury domyślnie tylko agregaty, zgoda, historia wysłanych danych | D.4a, D.5 |
| 7 | Pamięć lokalna, bez kwot, poza kopią; pamięć odrębna od historii rozmów | D.5, C.5 |
| 8 | Drift po PoC, Riverpod tylko przy uzasadnieniu | C.3, C.4, G (M1.6, M2) |
| 9 | Uwierzytelnianie urządzenia, backup z hasłem, szyfrowanie bazy po analizie | C.8, G (M0, M4) |
| 10 | API 26+ roboczo | C.9 |
| 11 | Gastronomia i Ogólny; Handel jako test uniwersalności | B.3, G (M2, M8) |
| 12 | Safe-to-Spend w dwóch wariantach | F.9, G (M7) |
| 13 | Kalendarz świąt per kraj i miejsce; reguły nadgodzin użytkownika | F.4, F.3 |
| 14 | Podatek jako składnik, kontrola kasy i utarg jako raport zmiany | B.3, F.2, C.5 |
| 15 | AI przed wypłatami (M3), uzgadnianie w M4 | D.10, D.11, G (M3, M4) |
| 16 | Kolejność OCR: tekst grafiku, OCR grafiku, pasek, paragony | D.7, G (M6, M7) |
| 17 | Publikacja i monetyzacja odroczone; polski pierwszy | G (M8), I |
| 18 | Backup jako pliki użytkownika, bez synchronizacji RITMO | B.5, C.8, C.10 |

# Kwestie, które nadal wymagają Twojej akceptacji (stan v1.1; aktualnie: sekcja I i QA v1.2)

- **Stan v1.1 (historyczny):** ta część pochodzi z v1.1. Aktualne kwestie są w sekcji I i w QA v1.2.
- **Elementy dodane z inicjatywy w v1.1 i ich status w v1.2:** biblioteka stref ✅ (3.2/1); `PayoutAllocation` z grupami doprecyzowany w F.6; `ShiftReport` kanoniczny w C.5a (pola kontroli kasy czekają na Twoją specyfikację); logika `BalanceAnchor` bez zmian; `SentDataLog` rozszerzony w D.3a i D.4a; token zatwierdzenia i test architektury bez zmian; progi prognoz jako wartości początkowe do kalibracji ✅ (3.2/14); próg „zapomnianej zmiany” 16 h 🔬; historia rozmów 90 dni ✅ (3.2/8).

# Ocena kompletności i ryzyk przed kolejnym etapem (stan v1.1; aktualnie: QA v1.2)

## Kontrola jakości

| Pytanie | Wynik | Uwagi |
| --- | --- | --- |
| Czy uwzględniono 18 decyzji? | tak | tabela wyżej; punkty zależne od PoC zostały jako bramki |
| Czy pojęcia są spójne? | tak, z zastrzeżeniem | `paidBy` i „do otrzymania” zastąpiono wszędzie (także w E.2 i H); odwołania „decyzja N” do Etapu 3 w A–F zostają i wyjaśnia je nota o numeracji |
| Czy `channel`, tip-out, Payout i PeriodClosure tworzą spójny model? | tak | zarobek liczy rodzaj i znak, saldo tylko kanał `employer`, wypłaty żyją, migawka zamraża „zarobione”; do akceptacji tylko edytowalność wypłat |
| Czy AI może ominąć Action Layer lub zatwierdzić zapis? | nie | brak narzędzia zapisu, token zatwierdzenia z UI, test zależności; głosowe „tak” tylko dla klasy L1 |
| Czy plan odpowiada zależnościom? | tak, po korektach | DST przeniesione do M1.1, kanały w M2 przed wypłatami w M4, narzędzia M4 poza M3, PoC Drift po M1 z kryterium schematu |
| Czy dane i backup v2 są chronione? | tak, z testami do napisania | C.10; import v2 do nowych tabel wymaga testów na zapisanych kopiach |
| Czy zakres nie urósł niekontrolowanie? | częściowo | dodano C.6a, C.6b, C.10, D.4a, G.1 i kilka encji; żadnego nowego produktu ani modułu; przegląd zakresu na końcu M2 |
| Czy nowe elementy mają uzasadnienie? | tak | każdy wynika z decyzji 3.1 lub z opisanego problemu (lista niżej) |

## Dodatkowe problemy wykryte w przeglądzie

1. **CI działa w UTC**, więc testy DST oparte na lokalnym `DateTime` byłyby niedeterministyczne. *Rozwiązanie:* biblioteka stref i wymuszona strefa testowa (C.6a).
2. **PoC Drift po M1** następuje po migracjach w sqflite. *Rozwiązanie:* przejęcie schematu z M1 jako kryterium PoC (C.4).
3. **Numeracja decyzji dwóch etapów kolidowała** (np. „decyzja 12”). *Rozwiązanie:* nota o numeracji na początku dokumentu.
4. **Znaczenie `Tip.tipOut` i `Tip.sales` w istniejących danych jest do potwierdzenia.** *Rozwiązanie:* weryfikacja przed M2 (C.5, F.1).
5. **Wypłaty a niezmienność okresu.** *Rozwiązanie:* zamrożone „zarobione”, żywe „otrzymane” z audytem (F.5).
6. **Historia rozmów zawiera kwoty, choć pamięć nie może.** *Rozwiązanie:* znacznik „stan na DATA”, lokalnie, poza kopią, usuwanie (D.5).
7. **Dwa źródła godzin** (`Tip.hours` i czas zmiany). *Rozwiązanie:* jedno źródło prawdy (C.10, F.10).
8. **Przypomnienia na Androidzie** nie zawsze działają co do minuty. *Rozwiązanie:* tolerancja kilku minut (H).
9. **Zegar urządzenia** może się przesunąć. *Rozwiązanie:* ręczna korekta czasów i zgłaszanie wartości nietypowych (C.6b).

## Ocena kompletności

Dokument jest kompletny jako koncepcja produktu, modelu finansowego i architektury. Nie jest jeszcze specyfikacją implementacyjną. Przed implementacją brakuje (świadomie, bo to kolejne etapy):

- makiet kluczowych ekranów (Dashboard w czterech stanach, ekran zmiany, kreator zamknięcia okresu, ustawienia składników);
- szczegółowego schematu bazy dla M0–M1 (typy, indeksy, migracje);
- reguł składników opisanych na przykładach z realnych lokali (potrzebne Twoje dane);
- zestawu pytań kontrolnych AI i danych testowych S1;
- przeglądu prywatności i prawnego przed publikacją.

**Największe ryzyka przed kolejnym etapem (w kolejności):** (1) czytelność semantyki kanałów dla zwykłego użytkownika, (2) migracja czasu i danych istniejących, (3) dryf zakresu przy M2–M3, (4) moment PoC Drift, (5) koszty i prywatność AI.

🔷 **Rekomendacja:** przejść do etapu szczegółowej specyfikacji M0–M1 (schemat, makiety, plan testów), a dopiero potem do implementacji. Nie rozpoczynać M2 i M3 przed zamknięciem M1. Decyzje produktowe z sekcji I zostają po Twojej stronie.

---

# Historia zmian v1.1 → v1.2

- **Nagłówek i numeracja:** wersja 1.2, data aktualizacji, zakres zmian; oznaczenie „decyzja 3.2/N” dla domyślnych rozstrzygnięć z Etapu 3.2.
- **Dane (C.5, C.5a):** `ShiftReport` jedynym kanonicznym miejscem danych raportowych, `Tip.sales` lustrem legacy z migracją i weryfikacją; nowe elementy modelu: `Offset`, `ClosureRules`, `time_model`, `review_status`.
- **Dane historyczne i czas (C.6c, C.10, C.6a, C.6b):** cztery rozdzielone obszary (interpretacja, migracja techniczna, przyszłe obliczenia, ręczna korekta); historyczne zmiany nie są przeliczane; bramka migracji bez wyjątków; statusy decyzji.
- **Składniki i kanały (F.1, F.2a):** doprecyzowany kanał `other`; saldo z kompensacjami; niezmienniki; kontrola tip-outu względem dostępnej gotówki; mapowanie `Tip.tipOut` odłożone do audytu.
- **Kompensacja napiwków kartowych z utargiem gotówkowym (F.2b, nowa; wymaganie 3.4):** analiza, czy obecny model wystarcza (nie wystarcza), minimalne rozszerzenie (`card_tips_settlement`, `cash_due`, `Offset`), limity, kompensacja częściowa i niewystarczający utarg, wpływ na wzory salda, snapshot, korekty, raporty, trzy przykłady liczbowe i przykład z wypłatą.
- **PeriodClosure (F.5, F.5a):** pełna odtwarzalność: podział na kopie danych i wersjonowany kod, `ClosureRules`, skróty danych, `ReplayClosure`, fikstury wersji kalkulatora.
- **Wypłaty (F.6, F.6a):** `Payout` jako rzeczywisty przepływ, `PayoutAllocation` jako przypisanie, wzory B(W) i B(P), zaliczki, FIFO i ręczna zmiana, saldo ujemne, sześć przykładów liczbowych.
- **AI i prywatność (D.3, D.3a, D.4a):** cztery osie uprawnień, skala S0–S3, Data Gate, osiem zasad, klucze dostawcy poza aplikacją; L4 doprecyzowane jako zakaz działań AI.
- **UX (E.3, E.4):** linia kompensacji w rozliczeniu zmiany, składniki `other` i niealokowana część wypłaty w widoku okresu.
- **Plan (G):** kryteria akceptacji K0–K4 dla M0, M1, M2, M3 i M4; M3 rozpisane na M3.1–M3.7; tabela zależności etapów; `calc_version` od M0; audyty jako warunki wejścia; S1 zaktualizowany o snapshot, replay i alokacje, z wariantami DST, OFFSET i SHORT.
- **Ryzyka i decyzje (H, I):** ryzyka v1.2; sekcja I w pięciu kategoriach.
- **Bez zmian:** wizja, zakres produktu, zasady z A.5, warstwy architektury, Action Layer, jeden kalkulator, „AI proponuje, użytkownik zatwierdza”, tożsamość wizualna, brak AIS, geofencingu, edytora reguł i synchronizacji w chmurze.

# QA v1.2: wyniki kontroli spójności

*Kontrola polegała na przeglądzie całego dokumentu i przeliczeniu przykładów. Nie uruchamiano kodu ani testów, a kod i repozytorium nie były modyfikowane.*

| Kontrola | Wynik | Uwagi |
| --- | --- | --- |
| Sprzeczności między C, F, G i I | tak, po poprawkach | usunięto: „przeliczanie nocy zmiany czasu” z v1.1 (C.10, I, M1), mapowanie `Tip.tipOut` przed audytem (F.1), bramki migracji „poza wyjątkami” (C.10, M1); stare sekcje końcowe v1.1 oznaczono jako historyczne |
| Jednoznaczna odpowiedzialność encji | tak | `Shift` czas; `Break` przerwy; `Tip` i `EarningLine` składniki; `ShiftReport` dane raportowe i `cash_due`; `Offset` kompensacja; `Payout` przepływ; `PayoutAllocation` przypisanie; `PeriodClosure`, `ClosureItem`, `ClosureRules`, `Adjustment` snapshot i korekty; `AuditEntry` ślad |
| Przepływy matematycznie spójne | tak | wzory B(W), B(P) i zależność kontrolna sprawdzone na F.6a, F.2b i S1 |
| Brak podwójnego odejmowania wypłat i kompensacji | tak | wypłata odejmowana raz w B(W); alokacja zmienia rozkład; kompensacja pomniejsza raz i nie jest wypłatą (F.2b, przykład C) |
| Odtwarzalność zamknięć | opisana, 🔬 niezweryfikowana | F.5a: kopie danych, wersjonowany kod, skróty, replay; utrzymanie wersji i wydajność do sprawdzenia w Stage 4 |
| Migracje zachowują dane | tak, 🔬 audyty | C.6c, C.10; bramka identycznych sum (K0.5, K1.5); audyty `Tip.tipOut`, `Tip.sales`, `Tip.hours` przed migracjami |
| AI nie omija zabezpieczeń | tak | brak narzędzia zapisu, token zatwierdzenia, Data Gate, osie D.3a, test architektury |
| Decyzje koncepcyjne oddzielone od testów | tak | sekcja I: kategorie 1–5; wyniki PoC i testów nie są przedstawiane jako znane |
| Ukryte zależności w roadmapie | naprawione | `calc_version` od M0, audyty jako warunki wejścia M1 i M2, M4 zależy od infrastruktury M3, PoC Drift po migracjach M1 z kryterium przejęcia schematu |
| Spójność nazewnictwa | tak, z zastrzeżeniem | ujednolicono „nadal należne od pracodawcy”, `channel`/`party`, `Offset`, `ClosureRules`; „rozliczenie” bywa używane potocznie, a `Settlement` nie jest używane |

**Weryfikacja przykładów liczbowych:**

- **S1:** 7 h × 30 zł = 210 zł (plan); 16:10–23:20 = 430 min; minus 30 min przerwy niepłatnej = 400 min = 200 zł; napiwki 120 + 80 = 200; tip-out 10% = 20; zarobione 200 + 120 + 80 − 20 = 380; składniki `employer` 200 + 80 = 280; wypłata 150 daje 130; korekta 15 daje 295 − 150 = 145; efektywnie 380 + 15 = 395 ✓.
- **F.6a:** przykład 1: 1800 − 1500 = 300; 2: −400, 500, 500; 3a i 3b: 300 ✓ (zależność kontrolna zachowana).
- **F.2b:** A: 800 − 150 = 650, saldo 200; B: 700, saldo 250; C: 0, saldo 230; po wypłacie 230: 350 − 120 − 230 = 0 ✓.
- **S1-OFFSET i S1-SHORT:** 280 − 80 − 150 = 50; 280 − 50 = 230 ✓.

**Status kwestii (szczegóły w sekcji I):**

- **Rozstrzygnięte koncepcyjnie:** 16 rozstrzygnięć 3.2 oraz wymaganie 3.4 (modelowane w F.2b; konfiguracja lokali czeka na Twoją specyfikację).
- **Wymagają audytu kodu:** `Tip.tipOut`, `Tip.sales`, `Tip.hours` i `Shift.durationMin`.
- **Wymagają PoC lub testów:** Drift, biblioteka stref i DST, odzyskiwanie timera, API 26+, wydajność, utrzymanie wersji kalkulatora, progi prognoz, AI on-device, analiza zagrożeń.
- **Odłożone do M8:** monetyzacja i publikacja, wybór BYOK lub modelu zarządzanego, język angielski.
- **Wymagają Twojej decyzji:** specyfikacja kontroli kasy i `ShiftReport`; zasady kompensacji napiwków kartowych; dozwolone sposoby tip-outu; użytkownik testowy z handlu; zatwierdzenie v1.2 i przejścia do Stage 4.

**Ocena przed Stage 4:** koncepcja jest spójna i wystarczająco precyzyjna jako podstawa. Największe ryzyka: czytelność semantyki kanałów, kompensacji i wypłat dla zwykłego użytkownika, migracja danych historycznych, utrzymanie wersji kalkulatora oraz dryf zakresu w M2–M3. Warunek wejścia do implementacji M2 to zakończone audyty i Twoja specyfikacja kontroli kasy.
