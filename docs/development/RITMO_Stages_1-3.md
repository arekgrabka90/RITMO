# RITMO v1.3 — Etapy 1–3: specyfikacja szczegółowa

*RITMO v1.3 Documentation Baseline — Frozen · 27.11.2026 · baza: `ritmo-develop`, HEAD `f39ac37` (GitHub jest jedynym źródłem prawdy)*

**Oznaczenia:** **\[Zweryfikowane\]** potwierdzone w kodzie · **\[Niezweryfikowane\]** wymaga dalszej analizy · **\[Rekomendacja\]** proponowana zmiana. Ten dokument nie zmienia kodu ani Git. Każdy pakiet ma statusy **In code → Tests passed → Accepted**. „Tests passed” wymaga dowodu z rzeczywistego uruchomienia GitHub Actions, a „Accepted” wymaga akceptacji użytkownika (na urządzeniu), nie samego zielonego CI. Kryteria akceptacji mają prefiks etapu: E1-K, E2-K, E3-K.

**Kolejność i zależności.** Etap 1 (audyt) → M0 → Etap 2 (czas) → M1b (minimalna historia stawek, tylko przy D11 = A) → Etap 3 (rozliczenie) → test terenowy → M2 (terminy, `Payout`, saldo) → M3 (profile) → M4 (zamknięcie okresu). Żaden etap nie startuje przed rozstrzygnięciem decyzji, które go blokują (Product Specification §11). Zadania nie zakładają lokalnej kopii projektu: źródłem prawdy jest repozytorium GitHub.

---

# ETAP 1 — Audyt istniejącego modelu danych i obliczeń

**Cel.** Znać prawdziwy stan kodu i danych, zanim cokolwiek się zmieni.

**Zakres.** Przegląd `Tip.tipOut`, `Tip.sales`, `Tip.hours`, `Shift.durationMin`, reprezentacji pieniędzy, sposobu liczenia zarobków, migracji, testów i wersjonowania kalkulatora; wskazanie: co zachować, co poprawić, co wycofać, jak zabezpieczyć dane.

**Poza zakresem.** Jakakolwiek zmiana kodu, schematu, Git i konfiguracji. Brak propozycji migracji bez analizy wpływu na obecne dane.

**Zależności.** Dostęp do zdalnego repozytorium GitHub (jest). Lokalna kopia nie jest potrzebna ani zakładana. Wyniki testów pochodzą z GitHub Actions (np. z ręcznie uruchomionego workflow, co nie wymaga jego zmiany). Naprawa CI (D6) to osobne zadanie poza Etapem 1 i M0.

**Stan wykonania.** Częściowy; wyniki w Architecture §2 i §2.6. **\[Zweryfikowane\]** Pola `tipOut`, `sales`, `hours`, `durationMin`; kwoty w groszach; obliczenia w `computePeriodStats`; migracje wersji 4; ustawienia; kopia JSON; CI; `util.dart`, `period.dart`, `shift_form.dart`, `dashboard.dart`. **\[Niezweryfikowane\]** Pozostałe pliki (`dates.dart`, `buckets.dart`, `export.dart`, `widgets.dart`, `home.dart`, `schedule.dart`, `shift_actions.dart`, `bulk_plan.dart`, `period_details.dart`, `tiles.dart`, `percent.dart`, `theme.dart`, `tool/`), treść testów i wyniki ich uruchomienia.

**Plan implementacji (kroki Etapu 1):**

1. Odczyt pozostałych plików z przypiętego SHA `f39ac37` (lista w „Stan wykonania”).
2. Weryfikacja rzeczywistego kodu: dla każdego twierdzenia o semantyce pola wskazać plik i funkcję.
3. Odczyt treści 16 plików testów i lista tego, co faktycznie pokrywają, oraz zachowań bez testu.
4. GitHub Actions: jeśli wyniki uruchomień są dostępne (z ręcznie uruchomionego workflow; D6 nie jest do tego potrzebne), zapisać je z numerem uruchomienia. Jeśli nie, testy są oznaczone jako nieuruchomione. Bez dowodu nie twierdzimy, że testy przechodzą.
5. `applicationId`: odczyt z artefaktu CI (zbudowany APK), bez udziału lokalnej kopii. Do tego czasu **\[Niezweryfikowane\]**.

**Kryteria akceptacji.**

- E1-K1 Każde twierdzenie o kodzie w raporcie ma etykietę (Zweryfikowane, Niezweryfikowane, Rekomendacja).
- E1-K2 Dla `tipOut`, `sales`, `hours`, `durationMin` jest opis rzeczywistej semantyki i miejsc użycia.
- E1-K3 Dla każdej proponowanej zmiany schematu jest opisany wpływ na istniejące dane.
- E1-K4 Lista zmian bez schematu (M0) jest oddzielona od zmian ze schematem.
- E1-K5 Żadne twierdzenie nie opiera się na lokalnej kopii projektu ani na teście bez dowodu z GitHub Actions.

**Wymagane testy.** Odczyt i opis istniejących testów. Wyniki ich uruchomienia tylko z GitHub Actions; bez dowodu test jest oznaczony „nieuruchomiony”. Dla każdej poprawki M0 test przed zmianą, który pokazuje błąd.

**Ryzyka.** Twierdzenia oparte na nieprzeczytanych plikach. Brak dostępnych wyników CI (testy nieuruchomione). Przeoczone użycie `Tip.sales` w eksporcie lub kopii.

**Warunki zakończenia.** Raport bez pozycji „Niezweryfikowane” w obszarach, które blokują Etap 2 i 3 (godziny, parsowanie, termin wypłaty, zachowanie `shift_actions.dart`), oraz Twoja decyzja w sprawie D1–D15 w zakresie wymaganym przez dany etap. Zakończenie Etapu 1 nie zależy od żadnej lokalnej kopii.

**Pakiet M0 „Pewne liczby” (po audycie, bez zmiany schematu) \[Rekomendacja\]:** jedno źródło godzin we wszystkich wskaźnikach (Statystyki liczą dziś z `Tip.hours`); etykiety brutto i netto; `await` i kontrola wyniku zapisu ustawień; bezpieczna procedura przywracania kopii (Architecture §6a); `calc_version = 1` jako stała dla dzisiejszej logiki, z fiksturami, które muszą dawać identyczne wyniki (Architecture §5a); testy bazy z `sqflite_common_ffi`; „Cofnij” po usunięciu (D15); kontrolka przesunięcia terminu wypłaty, jeśli audyt potwierdzi jej brak w całej aplikacji. **Naprawa CI (D6) nie jest elementem M0:** to osobne zadanie wymagające Twojej zgody i nie blokuje pakietów M0.

---

# ETAP 2 — Prawdziwy model czasu pracy

**Cel.** Zapisywać rzeczywisty czas pracy i przerwy, z timerem odpornym na zamknięcie aplikacji, bez ruszania historycznych danych.

**Stan obecny.** **\[Zweryfikowane\]** `Shift` ma datę oraz minuty startu i końca planu, bez strefy i bez czasu rzeczywistego; czas trwania jest nominalny (koniec ≤ start oznacza następny dzień), bez uwzględnienia zmiany czasu. Brak przerw i statusu zmiany. `Tip.hours` jest oddzielnym polem godzin.

## 2.1 Rekomendowany model

**\[Rekomendacja\]** Rozszerzamy tabelę `shifts` kolumnami addytywnymi i dodajemy tabelę `breaks`. Osobna encja `WorkSession` nie powstaje.

| Element | Propozycja | Uzasadnienie |
| --- | --- | --- |
| `status` | `planned`, `in_progress`, `completed`, `cancelled`; domyślnie `planned` | zastępuje dzisiejszy domysł „zakończona, bo plan minął” |
| `actual_start`, `actual_end` | czas w UTC (milisekundy), puste dla zmian historycznych | różnica dwóch znaczników daje poprawny czas przez północ i zmianę czasu |
| `timezone_id` | identyfikator IANA, puste dla zmian historycznych (decyzja D1) | tylko do zamiany planu na znaczniki i oznaczania niejednoznacznych godzin |
| `time_model` | `legacy` (domyślnie) lub `instants` | historyczne zmiany zachowują dotychczasowe obliczenia |
| `breaks` | `id`, `shift_id`, `start_at`, `end_at` (puste = w toku), `paid`; `start_at` i `end_at` w UTC (milisekundy), ta sama konwencja co `actual_start` i `actual_end` | timer przerwy potrzebuje znaczników czasu |
| Plan | bez zmian (data, minuty) | zgodność wsteczna |

**Alternatywy rozważone.** (A) Jedno pole „minuty przerwy niepłatnej” na zmianie: najprostsze, ale nie obsługuje przycisku „Przerwa” w trakcie i wielu przerw. (B) Tabela `breaks`: obsługuje timer i wiele przerw; wybrana. (C) Strefa przez przesunięcie od UTC zamiast IANA: bez nowej biblioteki, ale nie rozpoznaje niejednoznacznych godzin w nocy zmiany czasu; zostaje jako wariant, jeśli PoC IANA się nie opłaci (D1).

**Reguła czasu płatnego (nowe zmiany).** Minuty od `actual_start` do `actual_end` minus przerwy niepłatne. Dla zmian `legacy` bez zmian: nominalny czas planu.

## 2.2 Timer i cykl życia zmiany

- **Stany:** `planned → in_progress → completed`; `cancelled` z `planned` lub `in_progress`. Przerwa to otwarty wiersz w `breaks`, nie stan zmiany.
- **Akcje:** start zmiany (z planu albo bez planu), przerwa (płatna lub nie), wznów, koniec, anulowanie. Każda akcja to jedna transakcja zapisana od razu.
- **Wyświetlany czas** to „teraz minus `actual_start` minus przerwy”, liczone przy każdym odświeżeniu. Ticker tylko odświeża widok. **\[Rekomendacja\]** Timer nie opiera się na procesie w pamięci.
- **Jedna aktywna zmiana:** **\[Rekomendacja\]** częściowy indeks unikalny SQLite na `status = 'in_progress'` oraz sprawdzenie w kodzie.
- **Korekta godzin:** użytkownik może poprawić start, koniec i przerwy po fakcie.

**Zachowanie w sytuacjach granicznych (wymagane i testowane):**

| Sytuacja | Zachowanie |
| --- | --- |
| Wymuszone zamknięcie aplikacji | Po starcie aplikacja czyta zmianę `in_progress` z bazy i odtwarza ekran. Nic nie kończy się samo |
| Restart telefonu | Jak wyżej (stan jest w bazie). Powiadomienie z chronometrem dopiero w późniejszym etapie |
| Brak internetu | Bez wpływu (aplikacja lokalna) |
| Zmiana strefy telefonu w trakcie lub po zmianie | Zapisane znaczniki UTC i `timezone_id` zmiany się nie zmieniają; wynik zakończonych zmian bez zmian |
| Przejście przez północ | Czas z różnicy znaczników; zmiana należy do dnia startu (jak dziś w `computePeriodStats`) |
| Noc zmiany czasu (planowane 22:00–06:00) | 7 h wiosną i 9 h jesieni dla nowych zmian |
| Zapomniana zmiana | Po przekroczeniu progu (np. 16 h, do kalibracji) aplikacja pyta i proponuje koniec; nie kończy sama |
| Zegar urządzenia przesunięty | Wartości nietypowe (ujemne, powyżej 24 h) zgłaszane do poprawy |

### 2.3 Dodatkowe przypadki brzegowe

1. **Zasięg aktywnej zmiany (D13).** **\[Rekomendacja\]** Jedna aktywna zmiana w całej aplikacji (jedna osoba pracuje w jednym miejscu naraz). Wariant „jedna na miejsce pracy” to otwarta decyzja.
2. **Anulowanie zmiany z otwartą przerwą.** Anulowanie wymaga potwierdzenia i zmienia tylko status na `cancelled`. Otwarta przerwa jest zamykana znacznikiem anulowania, a czas i przerwy pozostają zapisane (żadne dane nie są usuwane). Usunięcie to osobna akcja z „Cofnij”.
3. **Rozliczenie anulowanej zmiany.** Zmiana `cancelled` nigdy nie generuje wynagrodzenia i nie liczy się do godzin w statystykach. Zapisany rzeczywisty czas pozostaje wyłącznie informacją. Jeśli anulowanie było omyłką, użytkownik jawnie przywraca zmianę (status `completed` po potwierdzeniu) i dopiero wtedy jest ona rozliczana. Automatycznego rozliczania anulowanej zmiany nie ma.
4. **Start bez wpisu w grafiku.** „Zacznij zmianę” tworzy zmianę ad hoc. **\[Zweryfikowane\]** `Shift` wymaga dziś minut startu i końca planu, więc plan zapisuje się jako godzina startu i ostatnio używany zakres (`lastRange`), z oznaczeniem „bez planu”. Czy plan może być pusty, to otwarta kwestia projektowa (wymagałaby kolumn dopuszczających pustą wartość).
5. **Zmiana zegara w trakcie zmiany.** Aplikacja nigdy nie poprawia czasu po cichu. Gdy w trakcie pracy aplikacji różnica zegara ściennego i licznika monotonicznego przekroczy próg (np. 2 minuty), pokazuje ostrzeżenie z prośbą o potwierdzenie czasu. Po restarcie telefonu przesunięcia nie da się wykryć, więc zostają kontrole sensowności: czas ujemny (zegar cofnięty) lub powyżej progu (np. 16 h) kończy się pytaniem, nie automatycznym końcem.
6. **Strefa telefonu a prezentacja.** Godziny zmiany pokazujemy w strefie zmiany (`timezone_id`). Gdy strefa telefonu jest inna, widok dodaje dopisek ze strefą zmiany. Zapisany czas UTC i plan (data plus minuty) się nie zmieniają. Zmiany `legacy` bez `timezone_id` wyświetlają się jak dziś.
7. **Poprawianie błędnego czasu.** Start, koniec i przerwy edytuje się na ekranie zmiany także po jej zakończeniu, a start także w trakcie. Walidacja: start przed końcem, przerwy w obrębie zmiany i bez nakładania. Każda korekta pokazuje „przed i po”, a potwierdzone rozliczenie traci potwierdzenie.
8. **Ochrona przed utratą danych.** Anulowanie, usunięcie i korekta pokazują, co zniknie lub się zmieni, zanim zapis stanie się trwały; usunięcie ma „Cofnij”.
9. **Brak automatycznego kończenia i brak utraty danych po restarcie.** Aplikacja nigdy nie kończy aktywnej zmiany sama i nie usuwa danych o przerwach, także po restarcie aplikacji lub telefonu. Otwarta przerwa zostaje otwarta do działania użytkownika; po powrocie aplikacja pokazuje stan i pyta.
10. **Trzy pojęcia czasu.** Czas UTC (znaczniki `actual_start`, `actual_end`, `breaks.start_at`, `breaks.end_at` w tej samej konwencji: milisekundy UTC), identyfikator IANA (strefa zmiany) i czas lokalny pokazywany użytkownikowi (wynik konwersji w strefie zmiany) są trzymane osobno i nigdy nie nadpisują się wzajemnie.

**Dane historyczne.** Zmiany sprzed Etapu 2 dostają `time_model = legacy` i nie są przeliczane. **\[Rekomendacja\]** Skan wskazuje historyczne zmiany obejmujące noc zmiany czasu jako „do weryfikacji” (wartości bez zmian); użytkownik wybiera „zachowaj” albo „popraw”.

**Zakres.** Kolumny i tabela jak w §2.1, polecenia timera, formularz zmiany z przerwami, odtwarzanie po zamknięciu, kalkulator czasu dla `instants`, wyłączenie drugiej aktywnej zmiany.

**Poza zakresem.** `WorkSession`, powiadomienia z chronometrem, widgety, geofencing, automatyczne kończenie zmian, przeliczanie historii.

**Zależności.** Etap 1 zakończony; M0 (testy bazy i fikstury). Decyzje D1, D9, D13. PoC biblioteki stref tylko, jeśli D1 = IANA.

**Plan implementacji.** **\[Rekomendacja\]** (1) Czyste funkcje czasu i testy DST oraz PoC strefy zgodnie z D1, bez zmiany schematu. (2) Migracja addytywna: kolumny `status` (domyślnie `planned`), `actual_start`, `actual_end`, `timezone_id`, `time_model` (domyślnie `legacy`) w `shifts` i tabela `breaks`; kopia pliku bazy przed migracją; test na kopii bazy v4. (3) Warstwa dostępu: polecenia start, przerwa, wznów, koniec i anulowanie jako transakcje, częściowy indeks jednej aktywnej zmiany. (4) Kalkulator czasu dla `instants` obok `computePeriodStats`, z niezmienionymi wynikami `legacy` (fikstury, `calc_version` bez zmiany). (5) Interfejs: karta aktywnej zmiany na Dashboardzie, ekran zmiany z przerwami i korektą, odtwarzanie stanu po starcie. Pliki, których dotyka plan (do potwierdzenia w Etapie 1): `napiwnik/lib/models.dart`, `napiwnik/lib/db.dart`, `napiwnik/lib/store.dart`, `napiwnik/lib/overview.dart`, `napiwnik/lib/screens/dashboard.dart`, `napiwnik/lib/screens/shift_form.dart`, nowe pliki w `napiwnik/test/`.

**Kryteria akceptacji.**

- E2-K1 Zmiana `instants` ma czas z różnicy znaczników, w tym przez północ.
- E2-K2 Testy DST dla Europe/Warsaw (7 h i 9 h) przechodzą przy wymuszonej strefie testowej, niezależnie od strefy maszyny CI.
- E2-K3 Aktywna zmiana i otwarta przerwa są odtwarzane po zabiciu procesu (test automatyczny) i po restarcie telefonu (test ręczny na Twoim urządzeniu).
- E2-K4 Druga aktywna zmiana jest odrzucona.
- E2-K5 Migracja kopii bazy wersji 4: sumy zarobków, napiwków i godzin per okres identyczne przed i po, bez wyjątków.
- E2-K6 Zmiany `legacy` mają niezmienione wartości.
- E2-K7 Przerwy płatne i niepłatne poprawnie wpływają na czas płatny (np. zmiana 16:10–23:20, przerwa niepłatna 30 min i płatna 15 min daje 400 min).
- E2-K8 Zmiana `cancelled` nie generuje wynagrodzenia i nie wchodzi do godzin w statystykach, a jej zapisany czas i przerwy pozostają w bazie.
- E2-K9 `breaks.start_at` i `breaks.end_at` mają tę samą konwencję czasu (milisekundy UTC) co `actual_start` i `actual_end` (test przejścia przez noc zmiany czasu).
- E2-K10 Po restarcie aplikacji aktywna zmiana nie zostaje zakończona, a dane o przerwach nie zostają usunięte (test automatyczny).

**Wymagane testy.** Jednostkowe: czas ze znaczników, przerwy, konwencja czasu przerw, DST wiosna i jesień, północ, zmiana `cancelled` bez wynagrodzenia. Integracyjne (baza w pamięci): cykl zmiany, jeden aktywny rekord, odtwarzanie, brak końca zmiany i brak utraty przerw po „restarcie”. Migracyjne: baza v4 po migracji. Test ręczny: restart telefonu.

**Ryzyka.** Nowa zależność stref (rozmiar, utrzymanie). Mylenie planu z faktem w interfejsie. Duża liczba zmian „do weryfikacji”. Rozjazd z `Tip.hours` (rozwiązanie: jedno źródło godzin ze zmiany, `Tip.hours` tylko dla wpisów bez zmiany; **\[Zweryfikowane\]** tak liczy `computePeriodStats`, Statystyki dziś nie).

**Warunki zakończenia.** E2-K1 do E2-K10 spełnione, pakiet *Tests passed* (dowód: uruchomienie GitHub Actions) oraz Accepted po użyciu na prawdziwych zmianach.

---

# ETAP 3 — Szybkie rozliczenie zmiany i potwierdzenie zarobków

**Cel.** Po zakończeniu pracy sprawdzić czas, dopisać przerwy, napiwki i opcjonalnie utarg, zobaczyć zarobek i potwierdzić go w kilku sekundach.

**Stan obecny.** **\[Zweryfikowane\]** Napiwki ze zmiany wpisuje formularz powiązany z zakończoną zmianą (blokada przed końcem zmiany i przed datą przyszłą); zmiana jest „zrobiona”, gdy ma wpis napiwków. Nie ma potwierdzenia: wynagrodzenie z minionych zaplanowanych zmian liczy się automatycznie.

## 3.1 Model potwierdzenia

**\[Rekomendacja\]** Kolumna `confirmed_at` przy wpisie napiwków (`tips`), bo to on jest dziś rekordem rozliczenia zmiany i występuje też dla wpisów bez zmiany (decyzja D2; alternatywa: pole na zmianie). Potwierdzenie oznacza „sprawdziłem i akceptuję rozliczenie”, nie gwarancję otrzymania pieniędzy.

| Status rozliczenia (wyliczany) | Znaczenie |
| --- | --- |
| Brak wpisu | zakończona zmiana bez wpisu rozliczenia |
| Wpisano | rozliczenie zapisane, niepotwierdzone |
| Potwierdzono | `confirmed_at` ustawione |

Zamknięcie okresu (M4) nie jest statusem rozliczenia: to właściwość okresu, która chroni jego wpisy snapshotem.

**Dwa niezależne statusy.** Status rozliczenia (tabela wyżej) mówi, w jakim stanie jest wpis. Status liczby mówi, na czym oparto kwotę: **Szacowane** (plan albo dane starego modelu), **Obliczone** (czas rzeczywisty, bez potwierdzenia), **Potwierdzone** (`confirmed_at`). Wpisanie danych nie jest statusem obliczeniowym. Przykład: użytkownik wpisał napiwki, wynagrodzenie obliczono z czasu rzeczywistego, rozliczenie nie jest potwierdzone; status rozliczenia to „Wpisano”, a status liczby „Obliczone”. Kalkulator liczy zawsze, gdy ma wystarczające dane, a potwierdzenie nie uruchamia innego wzoru ani nie zmienia kwoty, tylko status rozliczenia. Wszystkie ekrany, raporty i statystyki używają tych samych funkcji i etykiet (Product Specification §12).

**Przepływ jednego ekranu (bez dodatkowych przycisków):** czas rzeczywisty i przerwy; stawka z historii; napiwki gotówka, karta i odliczenie; utarg (opcjonalny); obliczony zarobek ze wskaźnikami; przełącznik „Wszystko wpisane” i jedno „Zapisz”. Domyślnie przełącznik jest włączony tylko wtedy, gdy dane są kompletne.

**Dane niekompletne.** Brak stawki: pokazujemy godziny i napiwki bez wynagrodzenia z jawnym oznaczeniem. Brak godzin: ostrzeżenie i brak potwierdzenia. Zero napiwków można potwierdzić jawnie (zmiana bez napiwków). **\[Zweryfikowane\]** obecny formularz wymaga wtedy godzin.

**Ochrona przed przypadkowym zatwierdzeniem \[Rekomendacja\].** Potwierdzenie jest zablokowane przy wartościach nietypowych: czas powyżej 16 h, ujemny czas, odliczenie większe niż napiwki, brak godzin, przyszła data. Zamiast osobnego przycisku ostrzeżenie pojawia się w podsumowaniu nad „Zapisz”.

**Edycja i korekty.** Potwierdzone rozliczenie można edytować do zamknięcia okresu; edycja zdejmuje potwierdzenie i wymaga ponownego zatwierdzenia. **\[Rekomendacja\]** Zmiana wpływająca na kwoty zapisuje poprzednią wartość w lekkiej historii (data, pole, przed, po). Po zamknięciu okresu (M4) edycje przechodzą przez `Adjustment`.

**Zasada źródła prawdy.** Wynik kalkulatora jest jedynym źródłem kwot. AI może tylko zaproponować zmianę i nie zmienia potwierdzonych danych.

**Zakres.** `confirmed_at`, ekran szybkiego rozliczenia, statusy rozliczenia i statusy liczby (Szacowane, Obliczone, Potwierdzone) widoczne wszędzie tak samo, ostrzeżenia, karta „Wymaga uwagi” z przypomnieniem „wpisz napiwki”, wskaźnik % utargu brutto i netto z etykietami, migracja danych historycznych według procedury z §3.2. Wynagrodzenie jest liczone zawsze, a potwierdzenie zmienia tylko status (D10 w postaci A).

**Poza zakresem.** Kontrola kasy, `cash_due`, `Offset`, alokacje wypłat, import dokumentów, powiadomienia systemowe, AI zmieniające dane.

**Zależności.** Etap 2 (czas rzeczywisty i przerwy); decyzje D2, D10, D11, D12. **Historia stawek:** przy D11 = A minimalna historia stawek (M1b) musi być gotowa przed Etapem 3; przy D11 = B część „wynagrodzenie potwierdzone” przesuwa się do M2; przy D11 = C potwierdzenie zapisuje użytą stawkę. Etap 3 nie startuje przed rozstrzygnięciem D11. Zasada niezależna od wariantu: nowa stawka obowiązuje od określonej daty i nie zmienia historycznych zarobków.

**Plan implementacji.** **\[Rekomendacja\]** (1) Przy D11 = A najpierw pakiet M1b (tabela `wage_rates`, zasady w Product Specification §6) z testami. (2) Migracja addytywna: `tips.confirmed_at` (domyślnie puste) oraz tips.record\_model (domyślnie legacy, patrz §3.2); kopia pliku bazy przed migracją; test na bazie v4. (3) Kalkulator: statusy liczby jako dodatkowy wynik tych samych funkcji (`computePeriodStats` i ścieżka dla czasu rzeczywistego), bez drugiego wzoru. (4) Jedno źródło godzin w Statystykach, jeśli nie zrobiono tego w M0. (5) Ekran szybkiego rozliczenia (rozbudowa `entry_form.dart`). (6) Etykiety obu statusów na Dashboardzie, w Grafiku, Statystykach, raporcie i eksporcie CSV. (7) Znacznik „stary model” bez zmiany kwot. Pliki, których dotyka plan (do potwierdzenia w Etapie 1): `napiwnik/lib/screens/entry_form.dart`, `napiwnik/lib/overview.dart`, `napiwnik/lib/screens/dashboard.dart`, `napiwnik/lib/screens/stats.dart`, `napiwnik/lib/models.dart`, `napiwnik/lib/db.dart`, `napiwnik/lib/export.dart` (nieczytany), nowe pliki w `napiwnik/test/`.

### 3.2 Migracja i prezentacja danych historycznych

**\[Rekomendacja\]**

1. **Nic nie zmienia kwot.** Migracja dodaje tylko kolumny z wartościami domyślnymi; żadna istniejąca kwota, godzina ani suma okresu się nie zmienia, a stare okresy nie są przeliczane (Architecture §6b).
2. **Pochodzenie danych.** Wszystkie istniejące zmiany i wpisy dostają znacznik „stary model” (brak czasu rzeczywistego, `time_model = legacy`), nigdy status Potwierdzono.
3. **Stare zaplanowane zmiany to szacunek**, nie dowód przepracowanych godzin. Mają status liczby Szacowane.
4. **Wpisy napiwków bez powiązanej zmiany** są pełnoprawnym rodzajem wpisu, a nie błędem: zostają, zachowują kwoty i dotychczasową semantykę (ich `Tip.hours` jest liczone osobno) i mają status rozliczenia „Wpisano”. Wynagrodzenia się do nich nie dolicza. **Techniczne oznaczenie (wpisy sprzed migracji i nowe wpisy samodzielne):** migracja dodaje kolumnę `tips.record_model TEXT NOT NULL DEFAULT 'legacy'`, więc wszystkie istniejące wiersze (powiązane i niepowiązane ze zmianą) dostają `legacy` bez zmiany jakiejkolwiek kwoty. Kod zapisuje `current` jawnie w każdym nowym wpisie utworzonym po migracji, także samodzielnym. Znacznik „stary model” w interfejsie pokazuje się dla `record_model = 'legacy'`. Wpis samodzielny to wiersz `tips` bez wskazującego na niego `shifts.tip_id`; historyczny ma `legacy`, nowy `current`, więc da się je odróżnić. Przywrócenie kopii JSON v1 lub v2 (format bez zmian, bez tego pola) oznacza wszystkie przywrócone wpisy jako `legacy`: ostrożnie i bez utraty danych (ograniczenie opisane w Architecture §6b, rozszerzenie formatu: D18).
5. **Prezentacja (D12, wyłącznie prezentacja).** Znacznik „stary model” pojawia się przy zmianie lub wpisie i w podsumowaniu okresu („w tym N zmian ze starego modelu, szacunek”). Czy takie dane wchodzą do sum, rozstrzyga D12 (zalecane: tak, jako Szacowane).
6. **Potwierdzanie dawnych danych tylko indywidualnie i z inicjatywy użytkownika** (otwarcie wpisu i „Wszystko wpisane”). Zbiorczego potwierdzania starych wpisów w v1 nie wprowadzamy, niezależnie od wariantu D12. Kto nic nie potwierdzi, ma dane takie jak dziś, z etykietą.
7. **Bramka migracji:** sumy napiwków, godzin i wynagrodzenia dla każdego okresu identyczne przed i po na kopii bazy v4 (E3-K6).
8. **Zamknięcie okresu (M4)** z danymi starego modelu zapisuje w snapshocie flagę „zawiera dane starego modelu”.

**Kryteria akceptacji.**

- E3-K1 Rozliczenie po zakończonej zmianie zajmuje do 10 sekund (pomiar ręczny, 5 prawdziwych zmian).
- E3-K2 Status rozliczenia (Brak wpisu, Wpisano, Potwierdzono) i status liczby (Szacowane, Obliczone, Potwierdzone) są rozróżniane na Dashboardzie, w Grafiku, w Statystykach i w raporcie.
- E3-K3 Potwierdzenie jest zablokowane przy każdej wartości nietypowej z listy.
- E3-K4 Edycja potwierdzonego rozliczenia zdejmuje potwierdzenie, pokazuje wartości przed i po i wymaga ponownej akceptacji.
- E3-K5 Te same liczby i te same etykiety statusu na Dashboardzie, w Statystykach, w raporcie i w eksporcie (test „jeden kalkulator”).
- E3-K6 Migracja: żadna istniejąca kwota, godzina ani suma okresu się nie zmienia (porównanie na kopii bazy v4); wszystkie istniejące wpisy startują jako niepotwierdzone i oznaczone „stary model”; żadne dane nie stają się potwierdzone bez działania użytkownika.
- E3-K7 Brak mechanizmu zbiorczego potwierdzania starych wpisów; stare wpisy da się potwierdzić pojedynczo.
- E3-K8 Kwota wynagrodzenia i napiwków jest identyczna przed i po potwierdzeniu (test niezmienności), a zmieniają się wyłącznie status rozliczenia i status liczby.
- E3-K9 Wpis napiwków bez powiązanej zmiany zachowuje kwoty i semantykę po migracji, nie jest usuwany ani zgłaszany jako błąd.
- E3-K10 Migracja dodaje `tips.record_model` z wartością `legacy` dla wszystkich istniejących wpisów (powiązanych i niepowiązanych ze zmianą) bez zmiany żadnej kwoty, godziny, utargu ani odliczenia; nowe wpisy, także samodzielne, mają `current`; przywrócenie kopii JSON v1 lub v2 oznacza wpisy jako `legacy`. Test migracyjny: baza v4 z wpisami powiązanymi i samodzielnymi; po migracji wszystkie wiersze `legacy`, wartości pól identyczne wiersz po wierszu, sumy okresów identyczne; nowy wpis samodzielny ma `current`; po przywróceniu kopii JSON v2 wszystkie wpisy są `legacy`.

**Wymagane testy.** Jednostkowe: statusy rozliczenia i liczby, ostrzeżenia, wskaźniki brutto i netto, niezmienność kwoty po potwierdzeniu (obliczenie przed i po daje identyczny wynik), zdjęcie potwierdzenia przy edycji. Integracyjne: pełny przepływ zmiana → rozliczenie → potwierdzenie; etykiety statusów u wszystkich konsumentów kalkulatora. Migracyjne: kopia v4 z wpisami (sumy okresów identyczne przed i po, brak wpisu potwierdzonego bez działania użytkownika, wpis bez zmiany zachowany) oraz test `tips.record_model` zgodny z E3-K10 (`legacy` dla wszystkich istniejących wpisów, `current` dla nowych, `legacy` po przywróceniu kopii JSON). Scenariusz: zmiana 16:10–23:20, przerwy 30 min niepłatna i 15 min płatna, stawka 30,00 zł/h, gotówka 120,00, karta 80,00, odliczenie 20,00 daje wynagrodzenie 200,00 zł, napiwki netto 180,00 zł, razem 380,00 zł; z utargiem 2000,00 zł napiwki brutto to 10%, netto 9%.

**Ryzyka.** Zmiana znaczenia „zrobionej” zmiany (dziś: ma wpis, na tym opiera się „Do uzupełnienia” na Dashboardzie). Duża liczba niepotwierdzonych wpisów po migracji. Zmęczenie dodatkowym krokiem. **\[Zweryfikowane\]** Dashboard liczy „Zarobki w okresie” z planu bez oznaczenia szacunku, więc wymaga oznaczeń statusu.

**Warunki zakończenia.** E3-K1 do E3-K10 spełnione, *Tests passed* (dowód: uruchomienie GitHub Actions) i Accepted po teście terenowym. **Test terenowy (3–4 tygodnie) jest formalną bramką:** do rozszerzania finansów przechodzimy dopiero po Twojej ocenie, czy model czasu odpowiada realnej pracy, czy rejestracja jest wygodna, czy wyniki zgadzają się z rzeczywistymi rozliczeniami, czy obsługa napiwków jest wystarczająco elastyczna i czy rozumiesz pokazywane wartości.

---

# NEXT STEP — START DEVELOPMENT

1. **Pakiet startowy.** E1-AUDIT (dokończenie audytu Etapu 1, tylko odczyt), a następnie **M0-A „Jedno źródło godzin i etykiety”** jako pierwszy pakiet kodowy M0, bez zmiany schematu.
2. **Decyzje niezbędne przed startem.** Żadna. D14 i D15 są potrzebne dopiero do domknięcia pakietów M0 (restore i „Cofnij”). D6 (naprawa CI) nie jest elementem M0 ani warunkiem jego zamknięcia: „Tests passed” opiera się na logu ręcznie uruchomionego workflow.
3. **Pliki objęte pierwszą zmianą (M0-A)** **\[Rekomendacja, do potwierdzenia w E1-AUDIT\]:** `napiwnik/lib/screens/stats.dart` (godziny i „Średnio na godzinę” ze wspólnego źródła), `napiwnik/lib/overview.dart` (ewentualne wydzielenie wspólnej funkcji godzin bez zmiany wyników), `napiwnik/test/` (nowe testy). Bez zmian: `db.dart`, `models.dart`, schemat bazy, `pubspec.yaml`, `.github/`.
4. **Wymagane testy.** Fikstury `computePeriodStats` z wynikiem identycznym jak na `f39ac37`; test zgodności „te same dane, te same godziny i wskaźnik na godzinę” na Dashboardzie, w Statystykach i w raporcie; test wpisu bez powiązanej zmiany; test etykiet brutto i netto.
5. **„Tests passed”, gdy:** (a) nowe i istniejące testy przechodzą w rzeczywistym uruchomieniu GitHub Actions, z logiem i numerem uruchomienia (testy mają dziś `continue-on-error`, więc zielone zadanie nie wystarcza, liczy się wynik `flutter test` w logu); (b) wyniki fikstur są identyczne jak na `f39ac37`; (c) diff nie dotyka plików spoza listy.
6. **„Accepted” wymaga Twojej akceptacji:** na telefonie (APK z CI) widzisz te same godziny i napiwek na godzinę na Dashboardzie i w Statystykach dla kilku prawdziwych wpisów, a etykiety brutto i netto są dla Ciebie zrozumiałe.
