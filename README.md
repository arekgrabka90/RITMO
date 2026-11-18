# RITMO

### Personal Work Planner & Shift Settlement

**RITMO** is a personal work planner for hospitality professionals. It brings work scheduling, shift records and shift settlements together in one Android application.

**Project status:** 0.0.1 in development  
**Platform:** Android phones and tablets  
**Operating model:** personal, local-first and offline

**Read this in:** [Polski](README.pl.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md)

---

## Project vision

Hospitality work involves changing schedules, different workplaces and positions, working hours, tips, cash and card payments. RITMO aims to provide one practical place to record and organize this information.

RITMO is designed as a personal tool for an individual hospitality professional. It is not a restaurant-management system, an employee-management platform or a SaaS product.

## Core principles

- **Personal:** initially intended for one user.
- **Offline:** core functionality and data storage work locally on the device.
- **Private:** no accounts, backend, cloud service or synchronization in the initial scope.
- **Flexible:** functionality is introduced incrementally.
- **Reliable:** data integrity, tested database migrations and backup/restore are important design requirements.
- **Adaptive:** one application for Android phones and tablets.
- **Separated records:** employer wages and shift settlements are independent areas.

## Version 0.0.1

The first release focuses on the application foundation and essential work-management workflow.

### Workplaces and positions
- Create and edit workplaces.
- Set a workplace name, color, currency and note.
- Create positions within a workplace.
- Archive and restore workplaces and positions.

### Shifts and schedule
- Create, edit and delete shifts.
- Assign a workplace and optionally a position.
- Enter start and end times manually.
- Mark shifts as planned or worked.
- Add notes.
- Browse shifts by day and navigate between months.

Punch in/out, breaks, time rounding and automatic wage calculations are not part of 0.0.1.

### Shift settlements

A settlement is associated with a specific shift. Version 0.0.1 is planned to support one settlement per shift and the following categories:

1. Cash tips — total cash tips.
2. Card tips — total card tips.
3. Card tips tax — tax associated with card tips.
4. Tip payout — payouts to kitchen and bar.
5. Sales and payments — sales information and payment reconciliation.
6. Cash control — cash register control.

Users can enter individual items with optional labels, amounts and notes. Custom items are also supported.

**No settlement calculations are performed.** RITMO does not automatically add, subtract, interpret or distribute amounts, calculate taxes or impose settlement procedures in this release.

### Settings and interface
- Light, dark and system themes.
- Adaptive navigation and layouts for phones and tablets.
- Local persistence of application data and settings.
- Planned sections: Today, Schedule, Settlements, Finance and More.

Some sections are intentionally limited in the first release.

### Backup and restore
Version 0.0.1 includes manual database backup and restore:
- Export a database copy to a user-selected file.
- Validate a backup before restoring it.
- Check database integrity and schema compatibility before replacing current data.

Android system cloud backup is disabled by project decision. Users should keep backup files in a safe location. Uninstalling the application may remove its local database.

## Privacy and data ownership

The initial application is designed to work without an online account or remote backend. Each device keeps its own local database. Cross-device synchronization is not included.

The project does not plan to transmit personal work or settlement records to external servers.

## Technology

The planned Android stack includes:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

The final dependency versions and implementation details are determined during development.

## Data integrity and time handling

The implementation is expected to follow these principles:
- Explicit database migrations with tests using databases containing existing data.
- No destructive migration fallback.
- Referential integrity and appropriate database constraints.
- Monetary values stored as integer minor units.
- Timestamps stored in UTC together with the originating time-zone identifier.
- Correct handling of shifts crossing midnight and daylight-saving transitions, including nonexistent and repeated local times.
- Backup validation before restoring or replacing the active database.

## Roadmap

| Version | Planned direction |
|---|---|
| 0.0.1 | Application foundation, workplaces, positions, shifts, basic settlements and manual backup/restore |
| 0.0.2 | Punch in/out and further time-management functionality |
| Future versions | Wage management, expanded financial tools and additional settlement capabilities |

Future features will be specified and approved separately.

## Out of scope for 0.0.1

- Accounts and multi-user functionality.
- Backend, cloud services and synchronization.
- POS and restaurant-system integrations.
- Automatic tax calculations or tip distribution.
- Settlement rules engine and automatic settlement calculations.
- Wage and salary calculations.
- Advanced financial analytics and forecasting.
- Punch in/out, breaks and time rounding.
- Geofencing, Wear OS and widgets.
- Advanced notifications.
- Advanced PDF or spreadsheet exports.
- Sharing records with other people.

## Repository documentation

Project specifications and development decisions are maintained separately from this overview:

- `RITMO_0.0.1_SCOPE.md` — initial release scope.
- `RITMO_0.0.1_ROADMAP.md` — implementation stages.
- `RITMO_0.0.1_DATA_MODEL.md` — proposed database model.
- `RITMO_0.0.1_ACCEPTANCE.md` — acceptance criteria and tests.
- `RITMO_DECISIONS.md` — approved decisions, proposals and open questions.

## Development status

RITMO 0.0.1 is under development. This repository README describes the project goals and intended scope; it does not claim that every listed feature has already been implemented or verified.

Builds, automated tests, database migrations, backup/restore and phone/tablet behavior must be verified before the release is considered complete.

---

**RITMO — Organize your work. Keep your records under your control.**
