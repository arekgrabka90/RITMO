# RITMO: indeks dokumentacji

**RITMO v1.3 Documentation Baseline: Frozen** · 27.11.2026 · baza: gałąź `ritmo-develop`, HEAD `f39ac37`

GitHub jest jedynym źródłem prawdy. Dokumentacja v1.3 czeka na formalne zatwierdzenie użytkownika. Decyzje D1–D19 mają status Open albo Recommended, żadna nie jest Accepted (patrz Product Specification, §11).

## Które dokumenty obowiązują

| Rola | Dokument | Ścieżka |
| --- | --- | --- |
| **Kanoniczny** (jedyne źródło wymagań produktowych) | RITMO v1.3: Product Specification | [`product/RITMO_Product_Specification.md`](product/RITMO_Product_Specification.md) |
| **Techniczny** (stan zweryfikowany, rekomendacje, decyzje techniczne) | RITMO v1.3: Architecture & Technical Decisions | [`architecture/RITMO_Architecture_Technical_Decisions.md`](architecture/RITMO_Architecture_Technical_Decisions.md) |
| **Wykonawczy** (Etapy 1–3: plan, testy, kryteria `E1-K`, `E2-K`, `E3-K`, NEXT STEP) | RITMO v1.3: Etapy 1–3, specyfikacja szczegółowa | [`development/RITMO_Stages_1-3.md`](development/RITMO_Stages_1-3.md) |
| **Historyczny** (zmiany v1.2 → v1.3, funkcje odłożone) | RITMO v1.3: Changelog v1.2 → v1.3 | [`history/RITMO_Changelog_v1.2-v1.3.md`](history/RITMO_Changelog_v1.2-v1.3.md) |
| **Historyczny** (referencja dla funkcji świadomie odłożonych, nie obowiązuje) | RITMO Professional: koncepcja produktu v1.2 | [`history/RITMO_v1.2_Original_Concept.md`](history/RITMO_v1.2_Original_Concept.md) |
| **Historyczny** (poprzedni opis koncepcji 0.0.1: Kotlin, Compose, Room) | README sprzed v1.3 | [`history/RITMO_README_0.0.1_Kotlin_concept.md`](history/RITMO_README_0.0.1_Kotlin_concept.md) |
| **Kontrola** | RITMO v1.3: Documentation Review Report | [`reviews/RITMO_Documentation_Review_Report.md`](reviews/RITMO_Documentation_Review_Report.md) |

## Hierarchia

- v1.3 jest aktualną specyfikacją i podstawą rozwoju.
- v1.2 jest dokumentem historycznym i referencją dla funkcji świadomie odłożonych. Nie przenosimy z niego funkcji automatycznie.
- Nowe wymaganie wchodzi do zakresu implementacji dopiero po jawnej akceptacji użytkownika.
- Zakres v1.3 jest zamrożony: nowe pomysły trafiają do backlogu przyszłych wersji, a dokumentację zmieniamy w trakcie implementacji tylko wtedy, gdy implementacja ujawni błąd albo konieczną decyzję.

## Kod i dokumentacja

Aplikacja znajduje się w katalogu `napiwnik/` (Flutter, sqflite). Jej nazwa wyświetlana, nazwa bazy (`napiwnik.db`), marker kopii i klucze ustawień pozostają bez zmian (patrz Architecture §10 i §12).

## Następny krok

Sekcja „NEXT STEP: START DEVELOPMENT” w dokumencie Etapy 1–3: najpierw E1-AUDIT (dokończenie audytu, tylko odczyt), potem M0-A „Jedno źródło godzin i etykiety”.
