# RITMO v1.3 — Product Specification

*RITMO v1.3 Documentation Baseline — Frozen · 27.11.2026 · jedyna kanoniczna specyfikacja produktu; v1.2 jest dokumentem historycznym*

**Baza:** gałąź `ritmo-develop`, HEAD `f39ac37`, sprawdzone na GitHubie 27.11.2026. GitHub jest jedynym źródłem prawdy. Analizy kodu odnoszą się do konkretnego SHA, a wyniki testów potwierdzają wyłącznie rzeczywiste uruchomienia GitHub Actions; brak dowodu oznacza status „Niezweryfikowane” lub „Nieuruchomione”.

**Oznaczenia twierdzeń o kodzie:** **\[Zweryfikowane\]** potwierdzone bezpośrednio w kodzie · **\[Niezweryfikowane\]** wymaga dalszej analizy · **\[Rekomendacja\]** proponowana zmiana, nie opis istniejącego zachowania.

**Status:** Documentation Baseline v1.3 — Frozen (zasada w §14). Decyzje D1–D19 mają status Open albo Recommended, żadna nie jest Accepted (§11). Dokument czeka na formalne zatwierdzenie użytkownika. Prace dotyczą wyłącznie dokumentacji: bez zmian w kodzie, schemacie, Git i konfiguracji CI.

**Hierarchia dokumentacji.** v1.3 jest aktualną specyfikacją produktu i podstawą rozwoju. Ten dokument jest jedynym kanonicznym źródłem wymagań produktowych. Architecture & Technical Decisions opisuje podstawy techniczne, „Etapy 1–3” to dokument wykonawczy, a Changelog i Documentation Review Report to historia i kontrola. v1.2 jest dokumentem historycznym i referencją dla funkcji świadomie odłożonych. Funkcji v1.2 nie przenosimy automatycznie do v1.3, a nowe wymaganie wchodzi do zakresu implementacji dopiero po jawnej akceptacji użytkownika.

## 1. Wizja i zasady nadrzędne

RITMO to osobiste narzędzie pracownika zmianowego (pierwszy profil: gastronomia). **Najpierw niezawodny planer pracy i zarobków, potem rozbudowany system finansowy.** Rozwiązuje siedem problemów: planowanie pracy, rejestrowanie rzeczywistego czasu, obliczanie zarobków, rozliczanie napiwków, kontrolę wypłat i salda, czytelne statystyki i prognozy oraz wygodnego asystenta AI.

1. Jeden kalkulator dla wszystkich ekranów; każda liczba ma źródło (fakt, szacunek, prognoza).
2. Podstawowe funkcje działają offline i bez AI. AI nie jest warunkiem żadnej funkcji finansowej.
3. RITMO nie jest systemem kasowym ani POS i nie liczy netto ani podatków.
4. Istniejące dane i funkcje mają pierwszeństwo przed nowościami.
5. Architektura rośnie razem z funkcją, nie przed nią. Tanie furtki zostają, moduły na zapas nie.
6. Realizm: jedna osoba, Flutter, GitHub Actions. GitHub jest źródłem prawdy, Claude analizuje kod i pracuje na repozytorium przez GitHub, analizy odnoszą się do konkretnego SHA, a testy potwierdzają rzeczywiste wyniki GitHub Actions.
7. Interfejs: mało przycisków. Otwarcie elementu pokazuje podsumowanie, przytrzymanie opcje, przesunięcie usuwa; wyjątkiem są „Zapisz” i akcje naprawdę konieczne.

## 2. Stan obecny aplikacji

**\[Zweryfikowane\]** Aplikacja (nazwa wyświetlana „Napiwnik”, Flutter, sqflite, bez konta i chmury) ma cztery zakładki: Dashboard, Grafik, Statystyki, Ustawienia. Obejmuje: miejsca pracy ze stawką godzinową; grafik z szablonami, planowaniem zbiorczym i kopiowaniem tygodnia; wpisy napiwków (gotówka, karta, odliczenie, utarg opcjonalny, godziny, notatka) powiązane ze zmianą; okres rozliczeniowy tygodniowy, dwutygodniowy lub miesięczny; dzień wypłaty; cel napiwków; statystyki; eksport CSV; kopię JSON v2 z walidacją.

**Luki wobec celu produktu (szczegóły w Architecture §2):** brak czasu rzeczywistego i przerw, brak historii stawek, brak potwierdzenia rozliczenia, dwa źródła godzin, brak wypłat i salda, brak `calc_version`.

## 3. Zakres wersji 1

| Wchodzi | Poza v1 (odłożone, lista w Changelog) |
| --- | --- |
| Grafik, czas rzeczywisty, przerwy, timer | Rozliczanie kasy, `cash_due`, `cash_shortfall`, `Offset` |
| Zarobki ze stawek z historią | Kompensacja napiwków kartowych z utargu |
| Napiwki gotówkowe i kartowe, odliczenie (tip-out) | Składnik `other`, rozbudowany `party` |
| Utarg jako opcjonalna informacja i statystyki | `ReplayClosure`, wiele wersji kalkulatora |
| Potwierdzenie rozliczenia zmiany | FIFO, `PayoutAllocation` |
| Termin wypłaty, prosty `Payout`, saldo | Drift, synchronizacja chmurowa |
| Zamknięcie okresu jako snapshot, korekty | Finansowe narzędzia AI (do czasu stabilnych narzędzi) |
| Kopia JSON, przypomnienie, Share Sheet | Import dokumentów i OCR, prognozy, Money lite (późniejsze etapy) |

## 4. Napiwki, tip-out i utarg

**4.1 Definicje.**

- **Napiwki brutto** = gotówka + karta, przed odliczeniem. **Napiwki netto** = brutto minus odliczenie (tip-out). **\[Zweryfikowane\]** tak liczy `Tip.gross` i `Tip.net`.
- **Odliczenie** to dziś kwota wpisywana ręcznie, nie większa niż napiwki brutto. **\[Zweryfikowane\]**
- **Utarg** to opcjonalna informacja o zmianie, bez wpływu na jakąkolwiek kwotę. Puste pole i zero oznaczają brak utargu. **\[Zweryfikowane\]**

**4.2 Wskaźniki (nigdy nie mieszamy brutto i netto w jednej liczbie).**

| Wskaźnik | Podstawa | Uwagi |
| --- | --- | --- |
| Napiwki na zmianie | brutto i netto, osobno | oba pokazywane z etykietą |
| Napiwki na godzinę | **netto** | godziny z jednego źródła (Etap 2) |
| Napiwek jako % utargu | **brutto** (domyślnie) | **\[Zweryfikowane\]** obecny kod liczy od brutto; wariant „netto” tylko jako osobny, oznaczony wskaźnik |
| Średnie i trendy per miejsce pracy | okres, miesiąc | **\[Rekomendacja\]** nowe na ekranie Statystyki |

Wskaźnik zbiorczy % utargu to suma napiwków brutto z wpisów, które mają utarg, podzielona przez sumę ich utargów (nie średnia procentów). **\[Zweryfikowane\]** tak działa `computePeriodStats`. Wpisy bez utargu nie wchodzą do wskaźnika.

**Stan obecny:** % utargu jest na Dashboardzie, w raporcie tekstowym i w formularzu. Ekran Statystyki go nie pokazuje, a „Średnio na godzinę” liczy tylko z `Tip.hours`. **\[Zweryfikowane\]**

**4.3 Odliczenie (tip-out).** W v1 zostaje kwota wpisywana na zmianie. **\[Rekomendacja\]** Ustawienie miejsca pracy „domyślne odliczenie” (kwota stała albo % napiwków brutto) jako podpowiedź w formularzu, zawsze edytowalna. Czy odliczenie schodzi z gotówki, czy rozlicza je pracodawca, kodem nie da się ustalić (decyzja D5). Do tej decyzji odliczenie pomniejsza tylko napiwki netto i nie wpływa na saldo pracodawcy.

**4.3a Zależności składników (do decyzji D5 obowiązuje obecna semantyka).**

| Pojęcie | Definicja | Wpływ |
| --- | --- | --- |
| Napiwki brutto | gotówka + karta | podstawa % utargu |
| Odliczenie (tip-out) | ręcznie wpisana kwota, nie większa niż brutto | pomniejsza napiwki netto; nie wpływa na saldo pracodawcy |
| Napiwki netto | brutto minus odliczenie | podstawa wskaźnika na godzinę i celu napiwków **\[Zweryfikowane\]** (Dashboard liczy cel od netto) |
| Gotówka zatrzymana przez pracownika | napiwki gotówkowe przyjęte od gościa | nie jest należnością pracodawcy; czy odliczenie schodzi z tej gotówki, rozstrzyga D5 |
| Napiwki przekazywane przez pracodawcę | napiwki kartowe wypłacane w wypłacie (profile 1 i 3) **\[Rekomendacja\]** | wchodzą do należności pracodawcy |
| Należność pracodawcy | wynagrodzenie + napiwki przekazywane przez pracodawcę − wypłaty | saldo (§6); odliczenie go nie zmienia do rozstrzygnięcia D5 |

Nie zakładamy, że odliczenie zawsze schodzi z gotówki ani że zawsze rozlicza je pracodawca. Rozbudowany model (kanał per składnik, `Offset`) nie jest częścią specyfikacji, dopóki użytkownik nie zaakceptuje D5. **\[Zweryfikowane\]** W odczytanych plikach kod zna tylko kwoty gotówki, karty i odliczenia oraz stawkę miejsca pracy; flaga „karta wypłacana przez pracodawcę” nie istnieje.

**4.4 Furtka na przyszłość.** Utarg zostaje jednym polem. Gdy pojawi się potwierdzony przypadek kontroli kasy, powstaje osobne rozszerzenie (raport zmiany), bez przebudowy wpisów.

## 5. Profile rozliczeń i kreator pierwszej konfiguracji

**\[Rekomendacja\]** Użytkownik wybiera profil, a nie parametry modelu. Zaproponowane trzy profile (do potwierdzenia na realnych lokalach, decyzja D4):

1. **Karta w wypłacie.** Gotówkę zatrzymujesz od ręki, napiwki kartą wypłaca pracodawca razem z pensją.
2. **Wszystko od ręki.** Gotówkę i napiwki kartą dostajesz na koniec zmiany; pracodawca wypłaca tylko pensję.
3. **Wszystko w wypłacie.** Napiwki trafiają do pracodawcy i wracają w wypłacie.

Kreator (4 kroki): nazwa i stawka; sposób napiwków (profil z przykładem kwot); okres i termin wypłaty; podgląd na przykładowej zmianie. Wszystko da się zmienić później. Zaawansowane ustawienia (kanał per składnik) są ukryte w ustawieniach miejsca. Wewnętrznie model może zachować rodzaj i znak składnika, kanał (`employer`, `direct`) i opcjonalny `party`; użytkownik tych pojęć nie widzi.

**\[Zweryfikowane\]** W `Store` istnieje flaga `onboarded` i warunek pierwszego uruchomienia. **\[Niezweryfikowane\]** Zawartość obecnego kreatora.

## 6. Wypłaty i saldo (uproszczone)

- **Historia stawek.** Nowa stawka obowiązuje od daty i nie zmienia przeszłości. **\[Zweryfikowane\]** Dziś edycja stawki miejsca zmienia obliczenia wstecz, bo każdy okres liczy się z aktualnej stawki.
- **Termin wypłaty dla każdego cyklu.** Logika w `Store` obsługuje miesięczny (dzień miesiąca) oraz tygodniowy i dwutygodniowy (przesunięcie po końcu okresu). **\[Zweryfikowane\]** `settings.dart` ma kontrolkę tylko dla dnia miesiąca. **\[Niezweryfikowane\]** Czy przesunięcie można ustawić gdzie indziej.
- **Payout** to rzeczywisty przepływ pieniędzy od pracodawcy: miejsce pracy, data, kwota większa od zera, rodzaj (`payout` lub `advance`), notatka, miękkie usunięcie, edytowalny. **\[Rekomendacja\]**
- **Saldo „nadal należne od pracodawcy”** = suma należności okresów (składniki wypłacane przez pracodawcę) minus suma wypłat w pełnej kwocie. Zaliczka to zwykła wypłata, saldo może być ujemne. **\[Rekomendacja\]**
- **Powiązanie wypłat z zarobkami:** lista wypłat obok okresów oraz wskaźnik „wypłacono z należnego” liczony narastająco i chronologicznie, bez alokacji.
- **Zasada:** wypłata jest przepływem i jest odejmowana od salda dokładnie raz. Przyszłe `PayoutAllocation` zmienia tylko rozkład salda po okresach, nigdy samo saldo.
- **Furtka:** `Payout` ma stabilne `id`, pełną kwotę i nie ma pola okresu, więc alokacje dodajemy później osobną tabelą bez przebudowy.

**Zależność: historia stawek a Etap 3 (decyzja D11).** Etap 3 liczy wynagrodzenie, więc potrzebuje stawki obowiązującej w dniu pracy. **\[Zweryfikowane\]** Dziś stawką jest bieżące `Workplace.hourlyRate`, a każda jej zmiana przelicza przeszłość. Warianty:

| Wariant | Opis | Konsekwencje |
| --- | --- | --- |
| A. Minimalna historia przed Etapem 3 (**rekomendacja**) | tabela stawek „od daty” zasilona obecną stawką; zmiana stawki działa od wskazanego dnia; bez `Payout` i reszty M2 | jedna dodatkowa migracja addytywna po Etapie 2; kalkulator bierze stawkę z daty zmiany; błąd wstecznego przeliczania znika, zanim przybędzie potwierdzonych rozliczeń; `calc_version` bez zmian dla pojedynczej stawki |
| B. Przesunięcie części Etapu 3 do M2 | potwierdzenie obejmuje czas i napiwki, wynagrodzenie zostaje szacunkiem z bieżącej stawki | potwierdzone rozliczenie nie chroni kwoty wynagrodzenia przed zmianą stawki, co łamie zasadę „potwierdzone się nie zmienia”; wymaga ostrzeżenia w interfejsie |
| C. Zamrożenie stawki przy potwierdzeniu | potwierdzenie zapisuje użytą stawkę, bez tabeli historii | chroni tylko potwierdzone; szacunki liczą się dalej z bieżącej stawki; pole do porzucenia po M2 |

Zasada niezależna od wariantu: nowa stawka obowiązuje od określonej daty i nie zmienia historycznych zarobków. Wpływ na roadmapę: §10.

**Minimalne zasady historii stawek (wariant A, M1b; D11 = Recommended).**

- Tabela `wage_rates`: miejsce pracy, data rozpoczęcia obowiązywania (`valid_from`, data lokalna), stawka godzinowa w groszach. Jedna stawka na miejsce i dzień. **\[Rekomendacja\]**
- Zasilenie: dla każdego miejsca jeden wiersz z obecną stawką `Workplace.hourlyRate`, obowiązujący „od początku”, więc wszystkie dotychczasowe wyniki pozostają takie same.
- Stawka dla zmiany: wiersz z najpóźniejszą datą nie późniejszą niż data zmiany (data startu; przy zmianie przez północ data startu).
- Zmiana stawki w trakcie okresu: nowa stawka działa od wskazanej daty (domyślnie dziś). Zmiany sprzed tej daty liczą się starą stawką, od tej daty nową. Data wsteczna wymaga podglądu skutków i ponownej akceptacji dotkniętych potwierdzonych rozliczeń.
- Edycja stawki miejsca dodaje wiersz od daty i nie zmienia wierszy wcześniejszych, więc nie modyfikuje historycznych rozliczeń. `Workplace.hourlyRate` zostaje „stawką bieżącą” (zgodność z kopią JSON v2).
- Poza zakresem: stawki per stanowisko, dodatki, mnożniki, stawki zależne od pory dnia.
- **\[Zweryfikowane\]** Kopia JSON v2 nie zawiera historii stawek. Format kopii nie jest zmieniany bez osobnej decyzji (D18), więc po przywróceniu kopii historia jest odtwarzana z jednej stawki.

## 7. Czas pracy i rozliczenie zmiany

Szczegóły (model czasu, timer, szybkie rozliczenie, potwierdzenie) opisuje dokument „Etapy 1–3”. W skrócie: plan i fakt na jednej zmianie, przerwy jako osobne interwały, jedna aktywna zmiana, stan timera zapisany w bazie, potwierdzenie rozliczenia przez użytkownika. Historycznych danych czasu nie przeliczamy automatycznie.

## 8. Asystent AI

Asystent rozwija się **równolegle**, ale nigdy nie wyprzedza funkcji, na których pracuje.

| Ścieżka | Zakres | Warunek |
| --- | --- | --- |
| A0 | paleta poleceń i odpowiedzi z szablonów (bez modelu) | po Etapie 3 |
| A1 | dostawca modelu (BYOK jako tryb prywatny), narzędzia odczytu | po podstawowych finansach |
| A2 | propozycje zmian i wpisów napiwków z zatwierdzeniem | po stabilnym potwierdzaniu rozliczeń |
| A3 | narzędzia finansowe (wypłaty, zamknięcia) | po stabilnych narzędziach finansowych |

Reguły: model nie zapisuje danych, tylko tworzy propozycje, które zatwierdza użytkownik; kwoty pochodzą z kalkulatora; do dostawcy trafiają tylko agregaty za zgodą; bez dostawcy cała aplikacja działa. AI nie zmienia potwierdzonych danych.

## 9. Kopie zapasowe

**\[Zweryfikowane\]** Kopia JSON v2 (wczytuje się też v1) jest walidowana w całości przed jakimkolwiek zapisem. W `Store` jest `lastBackupAt`, a ustawienia wywołują `shareBackup`, w projekcie jest `share_plus`. **\[Niezweryfikowane\]** Implementacja `shareBackup` i ewentualny obecny komunikat o starej kopii na Dashboardzie.

**\[Rekomendacja\]** Przypomnienie jako karta „Wymaga uwagi” po N dniach bez kopii (próg: decyzja D8), przekazanie pliku przez systemowe okno udostępniania na Dysk lub inną usługę wybraną przez użytkownika. Bez własnej synchronizacji RITMO. Szyfrowanie kopii hasłem w późniejszym etapie.

**Przywracanie kopii.** Obecna procedura nie jest atomowa **\[Zweryfikowane\]** (baza w transakcji, ustawienia osobno). Bezpieczna procedura bez zmiany formatu kopii jest w Architecture §6a **\[Rekomendacja\]**. Bez zmian zostają: `napiwnik.db`, istniejące klucze ustawień, marker `napiwnik`, import JSON v1 i v2. **\[Zweryfikowane\]** `dashboard.dart` nie zawiera przypomnienia o kopii. **\[Niezweryfikowane\]** Użycie `lastBackupAt` w pozostałych plikach.

## 10. Roadmapa

Kolejność logiczna: niezawodny czas pracy, poprawne zarobki, weryfikacja terenowa, podstawowe finanse, rozszerzone AI i dodatki. Każdy pakiet ma statusy **In code → Tests passed → Accepted**. Zielone CI nie wystarcza do Accepted.

| Etap | Cel | Wynik widoczny |
| --- | --- | --- |
| **Etap 1: Audyt** (w toku) | stan kodu i danych | raport, decyzje D1–D19 |
| **M0: Pewne liczby** | naprawy bez zmiany schematu | spójne godziny, etykiety brutto i netto, `calc_version = 1` |
| **M1: Prawdziwy czas pracy** (Etap 2 i 3) | start, przerwa, koniec, potwierdzenie | timer, szybkie rozliczenie |
| **Test terenowy 3–4 tygodnie** | bramka | wnioski przed rozszerzaniem finansów |
| **M2: Podstawowe finanse** | historia stawek, terminy, `Payout`, saldo | czy wypłata się zgadza |
| **M3: Profile i kreator** | 3 profile, ustawienia miejsca, % utargu w statystykach | prosty start |
| **M4: Zamknięcie okresu** | snapshot z `calc_version`, korekty | niezmienne okresy |
| **Równolegle: AI A0 do A3** | zgodnie z §8 | asystent |
| **Później** | Dashboard premium, widgety, powiadomienia, import i OCR, prognozy, Money lite, gotowość produktowa | po M4 |

Uzasadnienie kolejności M2 przed M3 (różnica względem listy użytkownika, decyzja D3): historia stawek usuwa potwierdzony błąd integralności, a wypłaty odpowiadają na główny problem użytkownika. Profile zależą od wyników testu terenowego oraz decyzji D4 i D5.

**Wpływ D11.** Tabela wyżej pokazuje wariant bez D11 (historia stawek w M2). Przy zalecanym wariancie A powstaje pakiet **M1b: minimalna historia stawek** między Etapem 2 a Etapem 3, a M2 zawiera już tylko terminy wypłat, `Payout`, saldo i pełny podgląd historii stawek. Przy wariancie B Etap 3 traci część „wynagrodzenie potwierdzone”, przy C zyskuje pole zamrożonej stawki. Test terenowy następuje po M1 (z M1b, jeśli D11 = A). Żadnej z tych zmian jeszcze nie przyjęto, czekają na decyzję.

## 11. Otwarte decyzje (wymagają Twojej akceptacji)

**Legenda statusów:** Open (brak rekomendacji albo wymagana odpowiedź użytkownika), Recommended (rekomendacja gotowa, czeka na akceptację), Accepted (wyraźnie zatwierdzone przez użytkownika). **Żadna decyzja nie ma statusu Accepted.**

**Co blokuje.** Etapu 1 ani startu M0 nie blokuje żadna decyzja, a zakres M0 nie obejmuje naprawy CI (D6 to osobne zadanie wymagające Twojej zgody). Do domknięcia pakietów M0 potrzebne są D14 (pakiet restore) i D15 (pakiet „Cofnij”). „Tests passed” w M0 opiera się na logu rzeczywistego uruchomienia GitHub Actions (np. ręcznie uruchomionego workflow), co nie wymaga zmiany workflow. Przed Etapem 2: D1, D13. Przed Etapem 3: D2, D10, D11, D12. Przed M2: D3, D11 oraz D5 w części o saldzie. Przed M3: D4, D5. Pozostałe można podjąć później.

| ID | Temat | Rekomendacja | Alternatywy | Wpływ | Blokuje | Status |
| --- | --- | --- | --- | --- | --- | --- |
| D1 | czas i strefy | A: identyfikator IANA (`timezone_id`) i pakiet `timezone`, po krótkim PoC DST (Europe/Warsaw) | B: UTC z przesunięciem, bez biblioteki | A: poprawna podwójna godzina jesienią, nowa zależność; B: prostsze, bez rozpoznania podwójnej godziny | start Etapu 2 | Recommended |
| D2 | miejsce potwierdzenia rozliczenia | A: `confirmed_at` przy wpisie napiwków (`tips`) | B: pole na zmianie | A obejmuje też wpisy bez zmiany; B wymaga dwóch mechanizmów | Etap 3 | Recommended |
| D3 | kolejność po teście terenowym | A: finanse podstawowe przed profilami | B: profile przed finansami | A szybciej odpowiada na „czy wypłata się zgadza” | M2, M3 | Recommended |
| D4 | trzy profile kreatora (§5) | A: profile z §5 jako szkic do potwierdzenia na realnych lokalach | B: inne profile | błędny profil daje niezgodne saldo | M3 | Recommended |
| D5 | odliczenie (tip-out) | brak wyboru; obowiązuje obecna semantyka (pomniejsza napiwki netto, nie wpływa na saldo) | A: z gotówki pracownika; B: rozlicza pracodawca; C: wybór per miejsce | A: saldo bez zmian; B: odliczenie zmniejsza należność; C: ustawienie miejsca | część salda w M2 i M3 (nie blokuje M0 ani Etapów 1–3) | Open |
| D6 | naprawa CI (`napiwnik-build.yml`) | A: osobne zadanie po Twojej zgodzie, poza zakresem M0: wyzwalacz na `ritmo-develop`, testy blokujące, przypięty Flutter | B: bez zmian, budowanie ręczne | A: testy zaczną blokować build; B: APK mimo błędnych testów | nic (opcjonalne ulepszenie wiarygodności testów, nie jest częścią M0) | Recommended |
| D7 | nazwa i `applicationId` | A: nie zmieniać identyfikatorów, nazwę wyświetlaną zmienić osobno | B: zmiana `applicationId` | B: Android widzi inną aplikację, brak aktualizacji, dane tylko przez kopię JSON | nic (przed publikacją) | Recommended |
| D8 | próg przypomnienia o kopii | 14 dni | 7 lub 30 dni | krótszy próg to więcej przypomnień | nic | Recommended |
| D9 | zmiana o identycznym starcie i końcu (24 h) | A: nadal odrzucać | B: dopuścić | B wymaga zmian walidacji w formularzu i imporcie kopii | nic | Recommended |
| D10 | status wynagrodzenia | A: kalkulator liczy zawsze, potwierdzenie zmienia wyłącznie status rozliczenia i nie zmienia kwoty, edycja potwierdzonego wymaga ponownej akceptacji (§12) | B: wynagrodzenie dopiero po potwierdzeniu (odrzucone, sprzeczne z jednym kalkulatorem) | B zerowałoby zarobki na Dashboardzie i podniosło `calc_version` do 2 | Etap 3 | Recommended |
| D11 | historia stawek a Etap 3 | A: minimalna historia przed Etapem 3 (M1b), zasady w §6 | B: przesunięcie części Etapu 3 do M2; C: zamrożenie stawki przy potwierdzeniu | A usuwa błąd wstecznego przeliczania | Etap 3 | Recommended |
| D12 | prezentacja danych historycznych w sumach | A: znacznik „stary model”, dane wliczane do sum jako Szacowane | B: osobna sekcja poza sumami | dotyczy wyłącznie prezentacji; nie wpływa na możliwość potwierdzania starych wpisów | migracja w Etapie 3 | Recommended |
| D13 | zasięg aktywnej zmiany | A: jedna w całej aplikacji | B: jedna na miejsce pracy | B dopuszcza dwie równoległe zmiany, więcej interfejsu | Etap 2 | Recommended |
| D14 | odzyskiwanie po przerwanym przywracaniu kopii | A: klucz `restore_in_progress` oraz trwałe pliki źródła i stanu poprzedniego (Architecture §6a) | B: marker w pliku zamiast klucza | A dodaje jeden klucz, istniejące bez zmian | pakiet restore w M0 | Recommended |
| D15 | cofanie usunięć | A: „Cofnij” w pamięci przez kilka sekund dla usunięć i anulowań | B: miękkie usunięcie z koszem (zmiana schematu) | `napiwnik/README.md` deklaruje „Cofnij” przy przesunięciu; kod niezweryfikowany | pakiet „Cofnij” w M0 | Recommended |
| D16 | hierarchia v1.2 i v1.3 | v1.3 aktualna, v1.2 historyczna, nic nie wraca bez jawnej akceptacji (zasada w „Hierarchii dokumentacji”) | przenieść wybrane obszary v1.2 do v1.3 | v1.2 zostaje w `docs/history` jako referencja | nic | Recommended |
| D17 | blokada aplikacji | B: po M1 | A: w M0 jak w v1.2; C: nie robić | A opóźnia M0; C zostawia nieużywany kod PIN | nic | Recommended |
| D18 | historia stawek w kopii JSON | A: format v2 bez zmian, po restore historia z jednej stawki | B: addytywny format v3 czytający v1 i v2, przy M1b | B wymaga osobnej decyzji o formacie kopii | pełne wdrożenie M1b (nie M0, nie Etapy 1–2) | Recommended |
| D19 | główny README i tłumaczenia | A: minimalna zmiana: wskazać `docs/`, oznaczyć sekcje koncepcji Kotlin i Compose jako archiwalne, treść zachować w `docs/history` | B: przepisać README pod aktualną aplikację (Flutter) | README opisuje konkurencyjny zakres i nieistniejące dokumenty | nic | Recommended |

## 12. Status danych: szacowane, obliczone, potwierdzone

**\[Rekomendacja\]** Dwa niezależne pojęcia. **Status rozliczenia** (stan wpisu): Brak wpisu, Wpisano, Potwierdzono. **Status liczby** (na czym oparto kwotę): Szacowane, Obliczone, Potwierdzone. Wpisanie danych nie jest statusem obliczeniowym. Przykład: użytkownik wpisał napiwki, wynagrodzenie zostało obliczone z czasu rzeczywistego, rozliczenie nie zostało potwierdzone; status rozliczenia to „Wpisano”, a status liczby „Obliczone”. Kalkulator liczy wynagrodzenie zawsze, gdy ma wystarczające dane. Potwierdzenie nie uruchamia innego wzoru i nie zmienia kwoty, zmienia wyłącznie status rozliczenia. Edycja potwierdzonego rozliczenia wymaga ponownej akceptacji. Tabela niżej opisuje status liczby.

| Status | Kiedy | Czas | Wynagrodzenie |
| --- | --- | --- | --- |
| Szacowane | zmiana zaplanowana albo zakończona bez czasu rzeczywistego; w tym wszystkie dane ze starego modelu | plan | stawka × czas planu |
| Obliczone | zmiana ma czas rzeczywisty (Etap 2), brak potwierdzenia | czas rzeczywisty minus przerwy niepłatne | stawka × czas płatny |
| Potwierdzone | użytkownik zaakceptował rozliczenie (`confirmed_at`) | jak w Obliczone, już niezmienny bez świadomej edycji | ta sama formuła, stawka z historii |

Zasady: (1) Dashboard, Statystyki, raport, eksport i zamknięcie okresu używają tych samych funkcji i tych samych etykiet obu statusów; (2) sumy zawierają wszystkie statusy liczby z jawnym udziałem szacunku („w tym szacunek …”); (3) potwierdzenie nie zmienia kwoty, a edycja potwierdzonego rozliczenia zdejmuje potwierdzenie i wymaga ponownej akceptacji; (4) D10 (Recommended) jest zgodna z zasadą jednego kalkulatora, a liczenie wynagrodzenia dopiero po potwierdzeniu to odrzucony wariant B; (5) wpis napiwków bez powiązanej zmiany ma status rozliczenia „Wpisano”, a wynagrodzenia się do niego nie dolicza, bo wynagrodzenie liczy się tylko ze zmian. **\[Zweryfikowane\]** Dashboard „Zarobki w okresie” liczy dziś wynagrodzenie z planu bez oznaczenia, że to szacunek.

**Dane historyczne (D12 dotyczy wyłącznie prezentacji w sumach).** Migracja nie zmienia żadnej kwoty ani nie przelicza starych okresów. Stare wpisy i zmiany są oznaczone jako dane starego modelu, nie są automatycznie potwierdzane i zachowują możliwość indywidualnej weryfikacji. Stare zaplanowane zmiany nie są dowodem przepracowanych godzin (status liczby Szacowane). **Zbiorczego potwierdzania starych wpisów w v1 nie wprowadzamy**, niezależnie od wariantu D12. **Wpisy napiwków bez powiązanej zmiany** są pełnoprawnym rodzajem wpisu (**\[Zweryfikowane\]** kod liczy ich `Tip.hours` osobno), a nie błędem i nie są usuwane; zachowują kwoty i dotychczasową semantykę, mają znacznik „stary model” i status rozliczenia „Wpisano”. Procedura: „Etapy 1–3”, §3.2. Techniczne oznaczenie: kolumna tips.record\_model, wartość legacy dla wpisów sprzed migracji (Architecture §6b).

## 13. Ochrona przed utratą danych

Filozofia interfejsu zostaje: mało przycisków, otwarcie elementu pokazuje podsumowanie, przytrzymanie daje opcje, przesunięcie usuwa, widoczne zostają akcje konieczne („Zapisz”). **\[Zweryfikowane\]** Dashboard używa dotknięcia (`openShiftDefault`), przytrzymania (`showShiftOptions`) i przesunięcia (`ShiftDismissible`), a `napiwnik/README.md` deklaruje, że przesunięcie usuwa „z Cofnij”. **\[Niezweryfikowane\]** Implementacja cofania (`shift_actions.dart` nieczytany).

**\[Rekomendacja\]** Każde usunięcie przez przesunięcie daje krótkie „Cofnij” (decyzja D15). Anulowanie aktywnej zmiany i korekta godzin pokazują, co zniknie lub się zmieni (przed i po), zanim zapis stanie się trwały. Edycja potwierdzonego rozliczenia pokazuje poprzednie wartości.

## 14. Zamrożenie zakresu: RITMO v1.3 Documentation Baseline — Frozen

- Specyfikacja v1.3 jest bazą rozwoju.
- Nie zmieniamy ponownie filozofii produktu.
- Nie dodajemy nowych funkcji do zakresu v1 bez osobnej decyzji.
- Nie przebudowujemy architektury bez wykazanego problemu.
- Drobne poprawki dokumentacji są dozwolone, ale nie mogą prowadzić do ponownego projektowania.
- Nowe pomysły trafiają do backlogu przyszłych wersji (funkcje odłożone: Changelog §3).
- W czasie implementacji aktualizujemy dokumentację tylko wtedy, gdy implementacja ujawni błąd albo konieczną decyzję.

Zamrożenie dotyczy zakresu i podstawowych decyzji projektowych, nie rozwoju aplikacji.

## 15. Następny krok

Konkretny pakiet startowy opisuje sekcja „NEXT STEP — START DEVELOPMENT” w dokumencie „Etapy 1–3”.
