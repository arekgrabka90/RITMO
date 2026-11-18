# RITMO

### Pianificatore personale del lavoro e gestione dei conteggi dei turni

**RITMO** è un pianificatore personale per chi lavora nel settore dell’ospitalità. Riunisce la pianificazione dei turni, la registrazione delle ore e i conteggi dei turni in un’unica applicazione Android.

**Stato del progetto:** 0.0.1 in sviluppo  
**Piattaforma:** telefoni e tablet Android  
**Modello:** applicazione personale, locale e offline

**Altre lingue:** [English](README.md) · [Polski](README.pl.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Français](README.fr.md) · [Русский](README.ru.md) · [Português](README.pt-BR.md)

---

## Visione del progetto

Il lavoro nell’ospitalità comporta orari variabili, diversi luoghi e ruoli di lavoro, ore lavorate, mance, contanti e pagamenti con carta. RITMO vuole offrire un unico spazio pratico in cui registrare e organizzare queste informazioni.

RITMO è progettato come strumento personale per il singolo professionista dell’ospitalità. Non è un sistema di gestione dei ristoranti, una piattaforma per la gestione del personale o un prodotto SaaS.

## Principi fondamentali

- **Personale:** inizialmente destinato a un solo utente.
- **Offline:** le funzioni principali e i dati sono gestiti localmente sul dispositivo.
- **Privato:** nell’ambito iniziale non sono previsti account, backend, servizi cloud o sincronizzazione.
- **Flessibile:** le funzionalità vengono introdotte gradualmente.
- **Affidabile:** integrità dei dati, migrazioni del database testate e backup/ripristino sono requisiti importanti.
- **Adattivo:** un’unica applicazione per telefoni e tablet Android.
- **Registrazioni separate:** la retribuzione del datore di lavoro e i conteggi dei turni restano aree indipendenti.

## Versione 0.0.1

La prima versione si concentra sulle fondamenta dell’applicazione e sul flusso essenziale di gestione del lavoro.

### Luoghi di lavoro e mansioni
- Creare e modificare i luoghi di lavoro.
- Impostare nome, colore, valuta e nota.
- Creare mansioni associate a un luogo di lavoro.
- Archiviare e ripristinare luoghi di lavoro e mansioni.

### Turni e calendario
- Creare, modificare ed eliminare i turni.
- Assegnare un luogo di lavoro e, facoltativamente, una mansione.
- Inserire manualmente gli orari di inizio e fine.
- Contrassegnare i turni come programmati o lavorati.
- Aggiungere note.
- Consultare i turni per giorno e spostarsi tra i mesi.

Punch in/out, pause, arrotondamento del tempo e calcolo automatico della retribuzione non fanno parte della versione 0.0.1.

### Conteggi dei turni

Ogni conteggio è associato a un turno specifico. La versione 0.0.1 è progettata per supportare un conteggio per turno e le seguenti categorie:

1. Mance in contanti — totale delle mance in contanti.
2. Mance con carta — totale delle mance pagate con carta.
3. Imposta sulle mance con carta.
4. Distribuzione delle mance — pagamenti a cucina e bar.
5. Vendite e pagamenti — dati di vendita e riconciliazione dei pagamenti.
6. Controllo del contante — controllo della cassa.

Gli utenti possono aggiungere singole voci con etichette, importi e note facoltativi. Sono supportate anche voci personalizzate.

**Non vengono eseguiti calcoli dei conteggi.** In questa versione RITMO non somma, sottrae, interpreta o distribuisce automaticamente gli importi, non calcola le imposte e non impone procedure di conteggio.

### Impostazioni e interfaccia
- Temi chiaro, scuro e di sistema.
- Navigazione e layout adattivi per telefoni e tablet.
- Salvataggio locale di dati e impostazioni.
- Sezioni previste: Oggi, Turni, Conteggi, Finanze e Altro.

Alcune sezioni saranno intenzionalmente limitate nella prima versione.

### Backup e ripristino
La versione 0.0.1 include il backup e il ripristino manuali del database:
- Esportare una copia del database in un file scelto dall’utente.
- Convalidare il backup prima del ripristino.
- Verificare l’integrità del database e la compatibilità dello schema prima di sostituire i dati correnti.

Il backup cloud di sistema di Android è disattivato per decisione del progetto. I file di backup devono essere conservati in un luogo sicuro. La disinstallazione dell’applicazione può eliminare il database locale.

## Privacy e proprietà dei dati

La versione iniziale è progettata per funzionare senza account online né backend remoto. Ogni dispositivo mantiene il proprio database locale. La sincronizzazione tra dispositivi non è inclusa.

Il progetto non prevede di trasmettere a server esterni i dati personali relativi al lavoro o ai conteggi.

## Tecnologia

Lo stack Android previsto comprende:
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

Le versioni definitive delle librerie e i dettagli di implementazione saranno stabiliti durante lo sviluppo.

## Integrità dei dati e gestione del tempo

L’implementazione deve seguire questi principi:
- Migrazioni esplicite del database, testate su database contenenti dati esistenti.
- Nessun fallback di migrazione distruttivo.
- Integrità referenziale e vincoli adeguati nel database.
- Importi monetari memorizzati come numeri interi nelle unità monetarie minime.
- Timestamp memorizzati in UTC insieme all’identificatore del fuso orario di origine.
- Gestione corretta dei turni che attraversano la mezzanotte e dei cambi dell’ora legale, comprese le ore locali inesistenti o ripetute.
- Convalida dei backup prima del ripristino o della sostituzione del database attivo.

## Tabella di marcia

| Versione | Direzione prevista |
|---|---|
| 0.0.1 | Fondamenta dell’app, luoghi di lavoro, mansioni, turni, conteggi di base e backup/ripristino manuale |
| 0.0.2 | Punch in/out e ulteriori funzioni di rilevazione del tempo |
| Versioni future | Gestione delle retribuzioni, strumenti finanziari ampliati e ulteriori funzioni di conteggio |

Le funzionalità future saranno specificate e approvate separatamente.

## Fuori ambito per la versione 0.0.1

- Account e funzionalità multiutente.
- Backend, servizi cloud e sincronizzazione.
- Integrazioni POS e sistemi di ristorazione.
- Calcolo automatico delle imposte o distribuzione delle mance.
- Motore di regole e calcoli automatici dei conteggi.
- Calcolo di stipendi e retribuzioni.
- Analisi finanziarie avanzate e previsioni.
- Punch in/out, pause e arrotondamento del tempo.
- Geofencing, Wear OS e widget.
- Notifiche avanzate.
- Esportazione avanzata in PDF o fogli di calcolo.
- Condivisione dei dati con altre persone.

## Documentazione del repository

Le specifiche e le decisioni di sviluppo sono mantenute in documenti separati:

- `RITMO_0.0.1_SCOPE.md` — ambito della prima versione.
- `RITMO_0.0.1_ROADMAP.md` — fasi di implementazione.
- `RITMO_0.0.1_DATA_MODEL.md` — modello dati proposto.
- `RITMO_0.0.1_ACCEPTANCE.md` — criteri di accettazione e test.
- `RITMO_DECISIONS.md` — decisioni approvate, proposte e questioni aperte.

## Stato dello sviluppo

RITMO 0.0.1 è in fase di sviluppo. Questo README descrive gli obiettivi e l’ambito previsto del progetto; non afferma che tutte le funzionalità elencate siano già implementate o verificate.

Prima di considerare completata la versione, è necessario verificare build, test automatici, migrazioni del database, backup/ripristino e comportamento su telefoni e tablet.

---

**RITMO — Organizza il tuo lavoro. Mantieni il controllo dei tuoi dati.**
