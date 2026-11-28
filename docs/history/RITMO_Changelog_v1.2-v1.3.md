# RITMO v1.3 — Changelog v1.2 → v1.3

*RITMO v1.3 Documentation Baseline — Frozen · 27.11.2026 · baza: `ritmo-develop`, HEAD `f39ac37`*

**Jak porównano.** Źródłem v1.2 jest plik „RITMO Professional — docelowa koncepcja produktu (Etap 3, wersja 1.2)” (1318 linii) dołączony do rozmowy. **v1.2 jest dokumentem historycznym** i referencją dla funkcji świadomie odłożonych, a aktualną specyfikacją jest v1.3. Bezpośrednio porównano rozdział G (plan rozwoju), „Historię zmian v1.1 → v1.2”, „QA v1.2” i nagłówki całego dokumentu. Rozdziały D (AI szczegółowo), E (UX), H (ryzyka), F.7–F.10 i G.1 (scenariusz S1) **nie były porównywane linia po linii**: v1.3 ich nie przenosi, więc pozostają w v1.2 jako referencja (D16). Wersji v1.0 i v1.1 jako osobnych plików nie ma, więc ich opis pochodzi wyłącznie ze streszczeń w v1.2. Numeracja decyzji D1–D19 jest **nowa w v1.3** i nie odpowiada numeracji „decyzja 3.1/N” ani „3.2/N” z v1.2. **Gdzie szukać wymagań historycznych:** w v1.2 (docelowo `docs/history/RITMO_v1.2_Original_Concept.md`), a odłożone funkcje z odniesieniami do sekcji v1.2 są w §3.

## 1. Zmiany według obszarów

| Obszar | v1.2 | v1.3 | Pewność porównania |
| --- | --- | --- | --- |
| Filozofia produktu | rdzeń Zmiana → Zarobek → Wypłata (nagłówek B.1), plan M0–M8 | najpierw niezawodny planer pracy i zarobków, potem system finansowy; AI rozwija się równolegle i nie jest warunkiem funkcji finansowych | nagłówki, G |
| Utarg i kasa | `ShiftReport` jako kanoniczne źródło, `Tip.sales` jako lustro legacy z migracją, `cash_due`, `Offset`, kontrola kasy (C.5a, F.2a, F.2b, M2, M4) | utarg to opcjonalna informacja o zmianie; rozliczanie kasy i kompensacja odłożone | historia zmian v1.2, G |
| Rozliczanie napiwków | składniki z rodzajem i znakiem, kanałem (w tym `other`), podmiotem i sposobem tip-outu (F.1, M2) | trzy profile i kreator, zaawansowane ustawienia ukryte, `other` odłożony, `party` tylko wewnętrznie; definicje brutto i netto, % utargu liczony od brutto | historia zmian v1.2, G; definicji wskaźników w v1.2: niezweryfikowane |
| Model czasu pracy | `timezone_id`, `actual_start/end`, `Break`, `time_model`, `needs_review` (C.6a–C.6c, M1.1), trwałe powiadomienie z chronometrem (M1.3) | ten sam kierunek w Etapie 2; dodano `status` zmiany, częściowy indeks jednej aktywnej zmiany, przypadki brzegowe (zegar, strefa, anulowanie, start bez planu); powiadomienie z chronometrem poza zakresem; `WorkSession` nie powstaje | G, historia zmian v1.2 |
| Historia stawek | M2, kryterium K2.7 (zmiana stawki od daty nie zmienia przeszłości) | ta sama zasada; termin wdrożenia zależy od D11 (M1b przed Etapem 3 albo M2) | G |
| Wypłaty i saldo | M4: `Payout`, `PayoutAllocation`, FIFO, zaliczki, wypłaty częściowe, jedna wypłata na wiele okresów | M2: prosty `Payout` i saldo; alokacje i FIFO odłożone; zasada „wypłata odjęta dokładnie raz” zachowana | G, historia zmian v1.2 |
| Potwierdzanie rozliczeń | M1.4: `earnings_confirmed_at` | Etap 3: `confirmed_at` przy wpisie napiwków (D2), statusy liczby Szacowane / Obliczone / Potwierdzone, definicja D10 zmieniona na propozycję zgodną z jednym kalkulatorem | G |
| Zamknięcie okresu | F.5a i M4: pełna odtwarzalność (`ReplayClosure`, `ClosureRules`, skróty danych, fikstury wszystkich wersji, K4.1) | niezmienny snapshot z danymi wejściowymi, regułami, `calc_version` i wynikami; korekty przez `Adjustment`; replay odłożony | historia zmian v1.2, G |
| Zasady AI | cztery osie uprawnień, Data Gate, S0–S3, M1.5 Asystent v0, M3.1–M3.7 przed M4 (D.\*, G) | ścieżki A0–A3 równolegle, każda po stabilnych narzędziach; „AI proponuje, użytkownik zatwierdza” zachowane; szczegółowa architektura AI z v1.2 nie jest przeniesiona (D16) | G, historia zmian v1.2; treść D.\*: niezweryfikowane |
| Backup i ochrona danych | K0.4: przerwanie restore nie psuje danych; szyfrowany backup w M4 | procedura przywracania w Architecture §6a (z D14), przypomnienie o kopii i Share Sheet, szyfrowanie po M4; formatu kopii nie zmieniono | G |
| Technologia | M1.6: PoC Drift z kryterium przejęcia schematu | zostaje sqflite; Drift tylko przy udokumentowanym problemie; PoC nie jest etapem | G |
| Audyt kodu | audyty `Tip.tipOut`, `Tip.sales`, `Tip.hours`, `Shift.durationMin` jako warunki wejścia | częściowo wykonane na `f39ac37` (Architecture §2); wynik: `tipOut` to ręczna kwota, `sales` to informacja, godziny mają dwa źródła | G; wyniki: kod |
| Dokumentacja | jeden długi plik z historią v1.0–v1.2 | Product Specification, Architecture & Technical Decisions, Etapy 1–3, Changelog, Documentation Review Report | plik v1.2 |
| Test terenowy | brak | 3–4 tygodnie po M1 jako formalna bramka | G |
| Statusy pakietów | v1.2 wspomina status pakietów, ale zdanie w odczycie jest ucięte | In code → Tests passed → Accepted; zielone CI nie wystarcza do Accepted | v1.2: niezweryfikowane |

## 2. Zmiany w roadmapie

| v1.2 | v1.3 | Uwagi |
| --- | --- | --- |
| M0 „Pewne liczby”: widoczne RITMO, termin wypłaty dla każdego cyklu, spójne godziny, blokada aplikacji, `Money`, jeden kalkulator z `calc_version`, `android/` w repo, przypięty Flutter, blokujące CI, rozdzielone workflow | Etap 1 (audyt) i M0 bez zmian schematu: jedno źródło godzin, etykiety brutto i netto, `await` ustawień, procedura restore, `calc_version = 1`, testy bazy, „Cofnij” | blokada aplikacji → D17; poprawki CI → D6; nazwa i ikona → D7 |
| M1 „Prawdziwy czas pracy”: M1.1 model czasu, M1.2 Action Layer v0, M1.3 timer i powiadomienie, M1.4 szybkie rozliczenie, M1.5 Asystent v0, M1.6 bramka Drift | M1 = Etap 2 (czas) i Etap 3 (rozliczenie), M1b (minimalna historia stawek) tylko przy D11 = A | Action Layer wprowadzany stopniowo; Asystent v0 przesunięty do A0; bramka Drift usunięta |
| brak | test terenowy 3–4 tygodnie | nowa bramka |
| M2 „Moje miejsca, moje zasady”: profile, historia stawek, składniki, `ShiftReport`, `Offset`, kontrola gotówki | M2 podstawowe finanse (terminy, `Payout`, saldo, historia stawek jeśli D11 ≠ A); M3 profile i kreator | profile w v1.2 oznaczały branże (Gastronomia, Ogólny, Własny), a w v1.3 sposób rozliczania napiwków; to inne pojęcie |
| M3 „RITMO AI” | A0–A3 równolegle | każda ścieżka po stabilnych narzędziach |
| M4 „Wypłata się zgadza”: `Payout`, alokacje, zamknięcie z replay | wypłaty trafiają do M2, a M4 to zamknięcie okresu jako snapshot z korektami | alokacje i replay odłożone |
| M5–M8: Dashboard premium, przechwytywanie, prognozy i Money lite, gotowość produktowa | „Później”, kolejność po M4 | treść M5–M8 nie była zmieniana ani porównywana szczegółowo |

## 3. Funkcje odłożone poza v1

Nic nie zostało definitywnie wycofane. Wszystkie poniższe pozycje są **odłożone** i ich historia pozostaje w v1.2.

| Element | Pierwotny cel (v1.2) | Powód odłożenia | Ponowne rozpatrzenie | Wraca najwcześniej |
| --- | --- | --- | --- | --- |
| `Offset`, `cash_due`, `cash_shortfall`, kompensacja kartowa z utargu, rozliczanie kasy, `ShiftReport` jako kanoniczne źródło | kontrola kasy i kompensacja napiwków kartowych utargiem | decyzja: RITMO nie jest systemem kasowym, utarg jest informacją | tak, przy potwierdzonym przypadku | po akceptacji D5 i potwierdzonym przypadku w realnym lokalu, jako osobne rozszerzenie |
| `ReplayClosure` | pełna odtwarzalność zamknięć | nadmiar dla jednej osoby, snapshot wystarcza | tak | po M4 i realnej potrzebie audytu |
| Wiele historycznych wersji kalkulatora | replay starych zamknięć | j.w. (zostają `calc_version` i fikstury) | tak | j.w. |
| `PayoutAllocation` i FIFO | przypisanie wypłaty do wielu okresów | prosty `Payout` i saldo wystarczą na start | tak | po M2 i teście terenowym, gdy saldo bez alokacji okaże się za proste |
| Składnik `other` | wpływ spoza sald | brak potwierdzonego przypadku | tak | gdy pojawi się przypadek |
| Rozbudowany `party` | podmiot składnika | użytkownik go nie potrzebuje widzieć | wewnętrznie możliwy | gdy scenariusz tego wymaga |
| Drift i PoC Drift | ewentualna zmiana warstwy danych | brak udokumentowanego problemu | tylko przy problemie | konkretny udokumentowany problem sqflite |
| Powiadomienie z chronometrem (M1.3) | trwały licznik zmiany | zmniejszony zakres Etapu 2 | tak | po Etapie 2 i teście terenowym |
| Asystent v0 w M1.5 | paleta poleceń bez modelu | AI nie wyprzedza funkcji | przesunięte | A0 po Etapie 3 |
| Finansowe narzędzia AI (`explain_payout_difference` i podobne) | wsparcie uzgadniania wypłat | AI po stabilnych narzędziach finansowych | tak | A3 po M4 |
| Blokada aplikacji w M0 (K0.6) | prywatność danych | nieujęta w M0 v1.3 | tak | D17 |
| Poprawki CI (przypięty Flutter, blokujące testy, rozdzielone workflow, `android/` w repo) | pewność buildów | odrębne zadanie wymagające zgody | tak | po D6 |

Synchronizacja RITMO Cloud nie jest nowym odłożeniem: v1.2 już ją wykluczało („bez zmian”). Szyfrowanie kopii zostaje po M4, bez zmian.

## 4. Zmiany semantyczne wprowadzone w v1.3

- **Dane z kodu zastąpiły założenia z v1.2:** `Tip.tipOut` to kwota wpisywana ręcznie, `Tip.sales` to opcjonalna informacja, zero zapisuje się jako brak, stawka jest bieżąca (bez historii), Statystyki i Dashboard mają dwa źródła godzin.
- **D10 zmieniona:** dawna treść („wynagrodzenie liczone dopiero po potwierdzeniu”) łamała zasadę jednego kalkulatora, więc jest teraz wariantem B, a propozycją jest wariant A (kalkulator liczy zawsze, status się zmienia).
- **`calc_version = 1`** oznacza dzisiejszą logikę z `f39ac37`, nie kalkulator po M0 (Architecture §5a).
- **Korekta wcześniejszego raportu audytu:** zmiana z identycznym startem i końcem daje 1440 minut tylko w modelu; walidacja formularza i import ją odrzucają.
- **Wynik audytu zmienił ryzyko** niezgodności `parseHours` z importem: zero godzin jest w formularzu niemożliwe.

**Dalsze zmiany semantyczne (finalizacja):**

- **Dwa niezależne statusy:** status rozliczenia (Brak wpisu, Wpisano, Potwierdzono) i status liczby (Szacowane, Obliczone, Potwierdzone). Potwierdzenie nie zmienia kwoty ani wzoru.
- **Migracja danych historycznych:** brak zbiorczego potwierdzania starych wpisów w v1; D12 dotyczy wyłącznie prezentacji w sumach; wpisy napiwków bez powiązanej zmiany są pełnoprawne.
- **Przywracanie kopii:** procedura z trwałymi plikami źródła i stanu poprzedniego oraz flagą; całość nie jest deklarowana jako atomowa.
- **Model czasu:** zmiana anulowana nie generuje wynagrodzenia; przerwy w tej samej konwencji UTC co czas zmiany; brak automatycznego kończenia zmian i utraty przerw po restarcie.
- **Historia stawek (D11, Recommended):** minimalne zasady w Product Specification §6; kopia JSON v2 nie zawiera historii stawek (D18).
- **Nazewnictwo:** `confirmed_at` (historycznie `earnings_confirmed_at`), `wage_rates` i `WageRate`, kryteria `E1-K`, `E2-K`, `E3-K` (Architecture §12); kryteria K0–K4 z v1.2 zostają historyczne.
- **Hierarchia dokumentów:** v1.3 aktualna, v1.2 historyczna, nic z v1.2 nie wraca bez jawnej akceptacji.
- **Dokumentacja w repozytorium:** główny `README.md` opisuje inną koncepcję (Kotlin, Compose, Room, brak obliczeń) i wskazuje nieistniejące dokumenty (Architecture §2.7, D19).

## 5. Otwarte decyzje

Lista D1–D19 z rekomendacjami, alternatywami, wpływem i blokadami jest w Product Specification §11. Statusy to Open albo Recommended; żadna decyzja nie jest Accepted.

## 6. Czego nie da się rzetelnie porównać

- Szczegóły AI (D.2–D.9 w v1.2), UX (E), ryzyka (H), prognozy i Safe-to-Spend (F.8–F.9), scenariusz S1 (G.1): v1.3 ich nie przenosi i nie porównano ich linia po linii (D16).
- Zawartość v1.0 i v1.1: tylko według streszczeń w v1.2.
- Dokładne brzmienie statusów pakietów w v1.2: zdanie jest ucięte w odczycie.
- Czy v1.2 definiowało wskaźnik napiwków jako % utargu przed czy po tip-out: nie sprawdzono.
