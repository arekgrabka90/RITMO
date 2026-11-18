# RITMO

### Persönlicher Arbeitsplaner und Schichtabrechnung

**RITMO** ist ein persönlicher Arbeitsplaner für Beschäftigte in der Gastronomie. Die App vereint Dienstplanung, Schichtaufzeichnungen und Schichtabrechnungen in einer Android-Anwendung.

**Projektstatus:** 0.0.1 in Entwicklung  
**Plattform:** Android-Smartphones und -Tablets  
**Betriebsmodell:** persönlich, lokal und offline

**Weitere Sprachen:** [English](README.md) · [Polski](README.pl.md) · [Español](README.es.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md)

---

## Projektvision

Die Arbeit in der Gastronomie umfasst wechselnde Dienstpläne, verschiedene Arbeitsorte und Positionen, Arbeitszeiten, Trinkgelder, Bargeld und Kartenzahlungen. RITMO soll einen praktischen Ort bieten, an dem diese Informationen erfasst und organisiert werden können.

RITMO ist als persönliches Werkzeug für einzelne Beschäftigte in der Gastronomie gedacht. Es ist weder ein Restaurantverwaltungssystem noch eine Personalverwaltungsplattform oder ein SaaS-Produkt.

## Grundprinzipien

- **Persönlich:** zunächst für eine einzelne Person vorgesehen.
- **Offline:** Kernfunktionen und Daten werden lokal auf dem Gerät verarbeitet und gespeichert.
- **Privat:** im anfänglichen Umfang ohne Konten, Backend, Cloud-Dienste oder Synchronisierung.
- **Flexibel:** Funktionen werden schrittweise ergänzt.
- **Zuverlässig:** Datenintegrität, getestete Datenbankmigrationen sowie Sicherung und Wiederherstellung sind wichtige Anforderungen.
- **Adaptiv:** eine Anwendung für Android-Smartphones und -Tablets.
- **Getrennte Datensätze:** Arbeitgeberlohn und Schichtabrechnungen bleiben voneinander getrennte Bereiche.

## Version 0.0.1

Die erste Version konzentriert sich auf das Anwendungsfundament und die grundlegende Arbeitsverwaltung.

### Arbeitsorte und Positionen
- Arbeitsorte erstellen und bearbeiten.
- Name, Farbe, Währung und Notiz festlegen.
- Positionen einem bestimmten Arbeitsort zuordnen.
- Arbeitsorte und Positionen archivieren und wiederherstellen.

### Schichten und Dienstplan
- Schichten erstellen, bearbeiten und löschen.
- Einen Arbeitsort und optional eine Position zuweisen.
- Beginn und Ende manuell eingeben.
- Schichten als geplant oder gearbeitet markieren.
- Notizen hinzufügen.
- Schichten nach Tagen anzeigen und zwischen Monaten wechseln.

Punch in/out, Pausen, Zeitrundung und automatische Lohnberechnung gehören nicht zum Umfang von 0.0.1.

### Schichtabrechnungen

Jede Abrechnung ist einer bestimmten Schicht zugeordnet. Version 0.0.1 ist für eine Abrechnung pro Schicht und folgende Kategorien vorgesehen:

1. Trinkgeld in bar — Gesamtbetrag der Bartrinkgelder.
2. Trinkgeld per Karte — Gesamtbetrag der Kartentrinkgelder.
3. Steuer auf Kartentrinkgeld.
4. Trinkgeld-Auszahlung — Auszahlungen an Küche und Bar.
5. Umsatz und Zahlungen — Umsatzdaten und Zahlungsabgleich.
6. Bargeldkontrolle — Kontrolle der Kasse.

Einzelne Einträge können mit optionalen Bezeichnungen, Beträgen und Notizen angelegt werden. Eigene Einträge sind ebenfalls möglich.

**Es werden keine Abrechnungen berechnet.** RITMO addiert, subtrahiert, interpretiert oder verteilt in dieser Version keine Beträge automatisch, berechnet keine Steuern und schreibt keine Abrechnungsverfahren vor.

### Einstellungen und Benutzeroberfläche
- Helles, dunkles und systemabhängiges Design.
- Adaptive Navigation und Layouts für Smartphones und Tablets.
- Lokale Speicherung von Daten und Einstellungen.
- Geplante Bereiche: Heute, Dienstplan, Abrechnungen, Finanzen und Mehr.

Einige Bereiche sind in der ersten Version bewusst eingeschränkt.

### Datensicherung und Wiederherstellung
Version 0.0.1 umfasst eine manuelle Datenbanksicherung und Wiederherstellung:
- Datenbankkopie in eine vom Benutzer ausgewählte Datei exportieren.
- Sicherung vor der Wiederherstellung validieren.
- Datenbankintegrität und Schema-Kompatibilität vor dem Ersetzen aktueller Daten prüfen.

Die systemweite Android-Cloud-Sicherung ist aufgrund einer Projektentscheidung deaktiviert. Sicherungsdateien sollten an einem sicheren Ort aufbewahrt werden. Durch die Deinstallation der App kann die lokale Datenbank gelöscht werden.

## Datenschutz und Datenhoheit

Die erste Version ist für den Betrieb ohne Online-Konto und ohne Remote-Backend ausgelegt. Jedes Gerät besitzt eine eigene lokale Datenbank. Eine Synchronisierung zwischen Geräten ist nicht vorgesehen.

Das Projekt sieht keine Übertragung persönlicher Arbeits- oder Abrechnungsdaten an externe Server vor.

## Technologie

Der geplante Android-Technologiestack umfasst:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

Die endgültigen Bibliotheksversionen und Implementierungsdetails werden während der Entwicklung festgelegt.

## Datenintegrität und Zeitbehandlung

Die Implementierung soll folgende Grundsätze einhalten:
- Explizite Datenbankmigrationen mit Tests anhand von Datenbanken mit vorhandenen Daten.
- Kein destruktiver Migrations-Fallback.
- Referenzielle Integrität und geeignete Datenbankbedingungen.
- Geldbeträge werden als Ganzzahlen in kleinsten Währungseinheiten gespeichert.
- Zeitstempel werden in UTC zusammen mit der ursprünglichen Zeitzonenkennung gespeichert.
- Korrekte Behandlung von Schichten über Mitternacht sowie Sommerzeitwechseln, einschließlich nicht existierender und doppelt vorkommender Ortszeiten.
- Sicherungen werden vor Wiederherstellung oder Austausch der aktiven Datenbank validiert.

## Entwicklungsfahrplan

| Version | Geplante Ausrichtung |
|---|---|
| 0.0.1 | Anwendungsgrundlage, Arbeitsorte, Positionen, Schichten, einfache Abrechnungen und manuelle Sicherung/Wiederherstellung |
| 0.0.2 | Punch in/out und weitere Zeiterfassungsfunktionen |
| Zukünftige Versionen | Lohnverwaltung, erweiterte Finanzwerkzeuge und zusätzliche Abrechnungsfunktionen |

Zukünftige Funktionen werden separat spezifiziert und freigegeben.

## Nicht im Umfang von 0.0.1

- Konten und Mehrbenutzerfunktionen.
- Backend, Cloud-Dienste und Synchronisierung.
- POS- und Restaurant-Systemintegrationen.
- Automatische Steuerberechnung oder Trinkgeldverteilung.
- Regelwerk und automatische Abrechnungsberechnungen.
- Lohn- und Gehaltsberechnung.
- Erweiterte Finanzanalysen und Prognosen.
- Punch in/out, Pausen und Zeitrundung.
- Geofencing, Wear OS und Widgets.
- Erweiterte Benachrichtigungen.
- Erweiterter PDF- oder Tabellenexport.
- Weitergabe von Einträgen an andere Personen.

## Repository-Dokumentation

Projektspezifikationen und Entwicklungsentscheidungen werden in separaten Dokumenten gepflegt:

- `RITMO_0.0.1_SCOPE.md` — Umfang der ersten Version.
- `RITMO_0.0.1_ROADMAP.md` — Implementierungsphasen.
- `RITMO_0.0.1_DATA_MODEL.md` — vorgeschlagenes Datenmodell.
- `RITMO_0.0.1_ACCEPTANCE.md` — Abnahmekriterien und Tests.
- `RITMO_DECISIONS.md` — bestätigte Entscheidungen, Vorschläge und offene Fragen.

## Entwicklungsstatus

RITMO 0.0.1 befindet sich in Entwicklung. Diese README beschreibt Projektziele und den geplanten Umfang; sie behauptet nicht, dass alle aufgeführten Funktionen bereits implementiert oder geprüft wurden.

Vor Abschluss der Version müssen Build, automatisierte Tests, Datenbankmigrationen, Sicherung/Wiederherstellung und das Verhalten auf Smartphones und Tablets überprüft werden.

---

**RITMO — Organisiere deine Arbeit. Behalte die Kontrolle über deine Daten.**
