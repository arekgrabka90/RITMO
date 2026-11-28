# RITMO v1.3 — Documentation Review Report

*RITMO v1.3 Documentation Baseline — Frozen · 27.11.2026 · baza: `ritmo-develop`, HEAD `f39ac37`*

**Werdykt: READY FOR DEVELOPMENT** dla Etapu 1 (E1-AUDIT) i pierwszego pakietu M0 (M0-A). Żadna decyzja nie blokuje startu tych pakietów, a dokumentacja jest wewnętrznie spójna w zakresie potrzebnym do ich realizacji. Zastrzeżenia: porządkowanie repozytorium nie zostało wykonane (wymaga Twojej zgody na commit), kontrola spójności nie jest pełnym drugim czytaniem wszystkich zdań, a żadnego testu nie uruchomiono.

## 1. Dokumenty (status)

| Dokument | Status |
| --- | --- |
| [Product Specification](../product/RITMO_Product_Specification.md) | Baseline v1.3 — Frozen, czeka na formalne zatwierdzenie |
| [Architecture & Technical Decisions](../architecture/RITMO_Architecture_Technical_Decisions.md) | Baseline v1.3 — Frozen, czeka na formalne zatwierdzenie |
| [Etapy 1–3](../development/RITMO_Stages_1-3.md) | Baseline v1.3 — Frozen, czeka na formalne zatwierdzenie |
| [Changelog v1.2 → v1.3](../history/RITMO_Changelog_v1.2-v1.3.md) | Baseline v1.3 — Frozen, czeka na formalne zatwierdzenie |
| Documentation Review Report (ten dokument) | końcowy raport kontroli |

**Stan i zakres kontroli.** HEAD `f39ac37` na `ritmo-develop` sprawdzony 27.11.2026 (lista gałęzi) przed zmianami i w ich trakcie; bez zmian. GitHub jest jedynym źródłem prawdy, lokalnej kopii nie ma. Przed zmianami przeczytano aktualną treść Product Specification i Etapów w całości oraz strukturę Architecture, Changelogu i raportu; odczytano repozytorium (katalogi, główny `README.md`, `napiwnik/README.md`, workflow), a v1.2 przejrzano w zakresie nagłówków, rozdziału G i historii zmian.

## 2. Poprawione problemy

| Punkt | Co poprawiono | Gdzie |
| --- | --- | --- |
| 4.1 Termux | usunięto odniesienia do Termux i do lokalnej kopii; model pracy: GitHub, SHA, wyniki GitHub Actions, brak dowodu = Niezweryfikowane lub Nieuruchomione (wyszukiwanie „Termux” w Spec, Architecture i Etapach: 0 trafień) | Spec §1 i „Baza”, Architecture (oznaczenia), Etapy (Etap 1) |
| 4.2 Dwa statusy | rozdzielono status rozliczenia (Brak wpisu, Wpisano, Potwierdzono) i status liczby (Szacowane, Obliczone, Potwierdzone), z przykładem | Spec §12, Etapy §3.1, Architecture §12 |
| 4.3 D10 | kalkulator liczy zawsze, potwierdzenie zmienia wyłącznie status, edycja wymaga ponownej akceptacji; dodano test niezmienności kwoty (E3-K8) | Spec §11 i §12, Etapy (Etap 3) |
| 4.4 D12 | D12 dotyczy tylko prezentacji w sumach; brak zbiorczego potwierdzania starych wpisów (E3-K7) | Spec §11 i §12, Etapy §3.2 |
| 4.5 Restore | trwałe zabezpieczenie pliku źródłowego i stanu poprzedniego, flaga, wykrywanie przerwania, dokończenie lub wycofanie; bez deklaracji atomowości | Architecture §6a |
| 4.6 Etap 2 | zmiana anulowana nie generuje wynagrodzenia; przerwy w UTC jak czas zmiany; brak automatycznego kończenia i utraty przerw po restarcie (E2-K8 do E2-K10) | Etapy §2.3 i kryteria |
| 4.7 Wpisy bez zmiany | klasyfikacja „wpis samodzielny, stary model”, zachowanie kwot i semantyki (E3-K9) | Spec §12, Architecture §6b, Etapy §3.2 |
| 4.8 D11 | minimalne zasady historii stawek (data obowiązywania, wybór stawki dla zmiany, zmiana w trakcie okresu, brak zmiany historii) | Spec §6 |
| 4.9 Hierarchia | v1.3 aktualna, v1.2 historyczna, nic nie wraca bez jawnej akceptacji | Spec („Hierarchia dokumentacji”), Changelog, `docs/README.md` |
| 4.10 Nazewnictwo | słownik nazw, kryteria `E1-K`, `E2-K`, `E3-K` | Architecture §12, Etapy |
| Dodatkowo | jedna tabela D1–D19 z kolumną statusu; plan implementacji w Etapach 2 i 3 (w Etapie 1: kroki audytu); NEXT STEP; zamrożenie zakresu; inwentaryzacja dokumentów repozytorium; poprawiona data na 27.11.2026 | Spec §11, §14, Etapy, Architecture §2.7 |

## 3. Wynik kontroli spójności

Metoda: odczyt Product Specification i Etapów przed zmianami, edycje blokowe, wyszukiwanie fraz po zmianach („Termux”, „K3.”, „D1–D17”, „po potwierdzeniu”), porównanie z repozytorium i v1.2. **Nie jest to drugi pełny przegląd każdego zdania po edycjach, więc nie deklaruję pełnej spójności.**

| Obszar | Wynik |
| --- | --- |
| Nazewnictwo i kryteria | spójne (Architecture §12; prefiksy `E1-K`, `E2-K`, `E3-K`; kryteria v1.2 K0–K4 zostają historyczne) |
| Kolejność etapów i zależności | spójne; blokady w Spec §11 zgadzają się z Etapami |
| Statusy rozliczenia i liczby, jeden kalkulator, D10 | spójne; jedyne trafienia „po potwierdzeniu” opisują odrzucony wariant B |
| Brutto, netto, tip-out | spójne; D5 pozostaje otwarta |
| Historia stawek | spójna z jednym zastrzeżeniem: tabela roadmapy w Spec §10 pokazuje wariant bez D11, a wpływ D11 jest opisany pod nią |
| Migracje i dane historyczne | spójne (Spec §12, Etapy §3.2, Architecture §6b) |
| Backup i restore | spójne (Architecture §6a, Spec §9); D14, D18 otwarte jako Recommended |
| AI A0–A3 | spójne (Spec §8, Changelog) |
| Zakres M0–M4 | częściowo: szczegółowo opisane tylko Etapy 1–3 i pierwszy pakiet M0-A; M2–M4 w Spec §6 i §10 |
| Statusy In code, Tests passed, Accepted | spójne w Spec i Etapach |

## 4. Decyzje

- **Open:** D5.
- **Recommended:** D1–D4 i D6–D19. **Accepted:** żadna.
- **Blokujące start Etapu 1 i M0:** żadna. Do domknięcia pakietów M0: D14 (restore) i D15 („Cofnij”). D6 (naprawa CI) nie jest elementem M0 i nie blokuje jego pakietów.
- **Przed Etapem 2:** D1, D13. **Przed Etapem 3:** D2, D10, D11, D12. **Przed M2:** D3, D11, D5 w części salda. **Przed M3:** D4, D5.
- **Można odłożyć:** D7, D8, D9, D16, D17, D19, a D18 do M1b.
- **Nowe w tej rundzie:** D18 (historia stawek w kopii JSON v2, wykryta przy pracy nad D11) i D19 (główny README opisuje konkurencyjny zakres). Obie to Recommended i nie blokują M0.

Pełna tabela: Product Specification §11.

## 5. Zależności i blokery roadmapy

| Etap | Warunki wejścia | Bloker obecnie |
| --- | --- | --- |
| E1-AUDIT | dostęp do GitHub | brak decyzji; nieprzeczytane pliki, brak wyników CI |
| M0 | E1-AUDIT | brak na start; D14 i D15 do domknięcia pakietów (D6 poza zakresem M0) |
| Etap 2 | E1-AUDIT, M0 | D1, D13 |
| M1b | Etap 2 | D11, a pełne wdrożenie D18 |
| Etap 3 | Etap 2, M1b (przy D11 = A) | D2, D10, D11, D12 |
| Test terenowy | M1 | użycie M1 w pracy przez 3–4 tygodnie |
| M2, M3, M4 | po teście terenowym | D3, D5, D11 (M2); D4, D5 (M3); M2 (M4) |

## 6. Czego nie zweryfikowano

- Wyniki testów i GitHub Actions (konektor ich nie udostępnia); żaden test nie jest uznany za przechodzący.
- Pliki kodu: `dates.dart`, `buckets.dart`, `export.dart`, `widgets.dart`, `home.dart`, `schedule.dart`, `shift_actions.dart`, `bulk_plan.dart`, `period_details.dart`, `tiles.dart`, `percent.dart`, `theme.dart`, `tool/` oraz treść plików testów.
- Siedem tłumaczeń README (zakładamy podobną treść do `README.md`), `applicationId` i manifest Androida.
- Implementacja „Cofnij” przy usuwaniu (README to deklaruje, kod nie został sprawdzony).
- Rozdziały v1.2: D, E, H, F.7–F.10, G.1 (nie porównywane linia po linii), v1.0 i v1.1 jako osobne wersje.

## 7. Repozytorium

**Inwentaryzacja `f39ac37`:** osiem plików README w katalogu głównym, `napiwnik/README.md`, brak katalogu `docs/`, brak innych dokumentów koncepcyjnych. Główny `README.md` opisuje inną koncepcję (Kotlin, Jetpack Compose, Room, brak obliczeń) i wskazuje pliki, których nie ma w repozytorium (D19). Nie ma starych specyfikacji do przeniesienia.

**Czego nie wykonano i dlaczego:** konektor GitHub zapisuje zmiany tylko jako commity, a commity i pushe wymagają Twojej wyraźnej zgody. Nie symuluję sukcesu: w repozytorium nie zmieniono niczego.

**Aktualizacja (ostatnie dwie korekty).** Zakres M0 został ujednolicony z D6 (naprawa CI to osobne zadanie), a oznaczanie historycznych wpisów napiwków opisano technicznie (`tips.record_model`, E3-K10). Wgranie dokumentacji do repozytorium nie zostało wykonane: konektor GitHub przyjmuje treść plików tylko jako tekst przekazywany w poleceniu, więc wgranie pięciu dokumentów (około 150 KB) i kopii v1.2 (około 144 KB) wymagałoby ręcznego przepisania około 300 KB treści. Przepisywanie takiej ilości tekstu grozi błędami i niepełnym commitem, dlatego pakiet czeka na wgranie przez eksport (instrukcja w `REPO_REORGANIZATION_PLAN.md`) albo na Twoją decyzję o innym sposobie. Kod, baza, zależności i workflow CI pozostają bez zmian.

**Pakiet przygotowany poza repozytorium:** `docs/README.md` (indeks), `docs/history/RITMO_v1.2_Original_Concept.md` (kopia v1.2 bez zmian), `docs/history/RITMO_README_0.0.1_Kotlin_concept.md` (archiwum obecnego README) oraz `REPO_REORGANIZATION_PLAN.md` (drzewo, operacje, proponowane poprawki README i `napiwnik/README.md`). Pięć dokumentów v1.3 trzeba wyeksportować z Claude Docs do Markdown i zapisać pod ścieżkami z planu.

| Kategoria | Pliki |
| --- | --- |
| Dodane w repozytorium | brak (8 plików czeka na zatwierdzenie) |
| Przeniesione do archiwum | brak (nie ma starych dokumentów) |
| Zastąpione | brak |
| Do zmiany po zatwierdzeniu | `README.md`, siedem tłumaczeń README (po D19), sekcja „Testy” w `napiwnik/README.md` |
| Pozostawione bez zmian | cały kod, `pubspec.yaml`, `.github/` |

## 8. Potwierdzenie bezpieczeństwa

- **Kod Dart i Flutter, baza i migracje, `applicationId`, `napiwnik.db`, SharedPreferences, format kopii JSON v1 i v2, zależności, workflow GitHub Actions i inne pliki CI: bez zmian.**
- **Git: brak commitów, pushów, gałęzi i pull requestów.** Operacje na GitHubie ograniczone do odczytu.
- Decyzje D1–D19 pozostają otwarte lub rekomendowane i nie oznaczono ich jako Accepted.

## 9. NEXT STEP — START DEVELOPMENT

Szczegóły: dokument „Etapy 1–3”, sekcja „NEXT STEP — START DEVELOPMENT”. W skrócie: najpierw E1-AUDIT (dokończenie audytu, tylko odczyt), potem **M0-A „Jedno źródło godzin i etykiety”** (`stats.dart`, `overview.dart`, nowe testy), bez zmiany schematu i bez decyzji blokujących. „Tests passed” wymaga dowodu z uruchomienia GitHub Actions, a „Accepted” Twojej akceptacji na telefonie.
