# RITMO

### Planificateur personnel de travail et suivi des clôtures de service

**RITMO** est un planificateur personnel destiné aux professionnels de l’hôtellerie-restauration. Il réunit la planification des horaires, le suivi des services et leurs clôtures dans une application Android.

**État du projet :** 0.0.1 en développement  
**Plateforme :** téléphones et tablettes Android  
**Modèle :** application personnelle, locale et hors ligne

**Autres langues :** [English](README.md) · [Polski](README.pl.md) · [Español](README.es.md) · [Deutsch](README.de.md) · [Русский](README.ru.md) · [Italiano](README.it.md) · [Português](README.pt-BR.md)

---

## Vision du projet

Le travail dans l’hôtellerie-restauration implique des plannings variables, différents établissements et postes, des heures de travail, des pourboires, des espèces et des paiements par carte. RITMO vise à offrir un espace pratique unique pour enregistrer et organiser ces informations.

RITMO est conçu comme un outil personnel destiné à un professionnel de la restauration. Ce n’est ni un système de gestion de restaurant, ni une plateforme de gestion du personnel, ni un produit SaaS.

## Principes fondamentaux

- **Personnel :** initialement destiné à une seule personne.
- **Hors ligne :** les fonctions essentielles et les données sont stockées localement sur l’appareil.
- **Privé :** aucun compte, backend, service cloud ou synchronisation dans le périmètre initial.
- **Évolutif :** les fonctionnalités sont ajoutées progressivement.
- **Fiable :** l’intégrité des données, les migrations de base testées et la sauvegarde/restauration sont des exigences importantes.
- **Adaptatif :** une seule application pour téléphones et tablettes Android.
- **Données séparées :** le salaire versé par l’employeur et les clôtures de service restent indépendants.

## Version 0.0.1

La première version se concentre sur les fondations de l’application et le flux essentiel de gestion du travail.

### Établissements et postes
- Créer et modifier des établissements.
- Définir leur nom, couleur, devise et note.
- Créer des postes associés à un établissement.
- Archiver et restaurer les établissements et les postes.

### Services et planning
- Créer, modifier et supprimer des services.
- Associer un établissement et, facultativement, un poste.
- Saisir manuellement les heures de début et de fin.
- Marquer les services comme planifiés ou effectués.
- Ajouter des notes.
- Consulter les services par jour et naviguer entre les mois.

Le pointage d’entrée/sortie (punch in/out), les pauses, l’arrondi du temps et le calcul automatique du salaire ne font pas partie de la version 0.0.1.

### Clôtures de service

Chaque clôture est associée à un service précis. La version 0.0.1 prévoit une clôture par service et les catégories suivantes :

1. Pourboires en espèces — total des pourboires en espèces.
2. Pourboires par carte — total des pourboires par carte.
3. Taxe sur les pourboires par carte.
4. Reversement des pourboires — paiements à la cuisine et au bar.
5. Ventes et paiements — données de vente et rapprochement des paiements.
6. Contrôle des espèces — contrôle de caisse.

Les utilisateurs peuvent ajouter des éléments avec un libellé, un montant et une note facultatifs. Des éléments personnalisés sont également prévus.

**Aucun calcul de clôture n’est effectué.** Dans cette version, RITMO n’additionne, ne soustrait, n’interprète ni ne répartit automatiquement les montants, ne calcule pas les taxes et n’impose aucune procédure de clôture.

### Paramètres et interface
- Thèmes clair, sombre et système.
- Navigation et mises en page adaptatives pour téléphones et tablettes.
- Conservation locale des données et paramètres.
- Sections prévues : Aujourd’hui, Planning, Clôtures, Finances et Plus.

Certaines sections seront volontairement limitées dans la première version.

### Sauvegarde et restauration
La version 0.0.1 comprend la sauvegarde et la restauration manuelles de la base de données :
- Exporter une copie vers un fichier choisi par l’utilisateur.
- Valider la sauvegarde avant restauration.
- Vérifier l’intégrité de la base et la compatibilité du schéma avant de remplacer les données actuelles.

La sauvegarde cloud système d’Android est désactivée par décision du projet. Les fichiers de sauvegarde doivent être conservés dans un endroit sûr. La désinstallation de l’application peut supprimer la base locale.

## Confidentialité et propriété des données

L’application initiale est conçue pour fonctionner sans compte en ligne ni backend distant. Chaque appareil conserve sa propre base locale. La synchronisation entre appareils n’est pas incluse.

Le projet ne prévoit pas de transmettre les données personnelles de travail ou de clôture à des serveurs externes.

## Technologies

La pile Android envisagée comprend :
- Kotlin
- Jetpack Compose
- Material 3
- Room / SQLite
- DataStore
- Navigation Compose

Les versions définitives des bibliothèques et les détails d’implémentation seront déterminés pendant le développement.

## Intégrité des données et gestion du temps

L’implémentation doit respecter les principes suivants :
- Migrations explicites de la base, testées sur des bases contenant déjà des données.
- Aucun mécanisme de migration destructive de secours.
- Intégrité référentielle et contraintes adaptées dans la base.
- Montants stockés sous forme d’entiers dans les unités monétaires minimales.
- Horodatages stockés en UTC avec l’identifiant du fuseau horaire d’origine.
- Gestion correcte des services passant minuit et des changements d’heure saisonniers, y compris les heures locales inexistantes ou répétées.
- Validation des sauvegardes avant restauration ou remplacement de la base active.

## Feuille de route

| Version | Orientation prévue |
|---|---|
| 0.0.1 | Fondations de l’application, établissements, postes, services, clôtures de base et sauvegarde/restauration manuelle |
| 0.0.2 | Punch in/out et autres fonctions de suivi du temps |
| Versions futures | Gestion des salaires, outils financiers étendus et fonctions de clôture supplémentaires |

Les futures fonctionnalités seront spécifiées et approuvées séparément.

## Hors périmètre de la version 0.0.1

- Comptes et fonctions multi-utilisateurs.
- Backend, services cloud et synchronisation.
- Intégrations POS et systèmes de restauration.
- Calcul automatique des taxes ou répartition des pourboires.
- Moteur de règles et calculs automatiques de clôture.
- Calcul des salaires.
- Analyses financières avancées et prévisions.
- Punch in/out, pauses et arrondi du temps.
- Géorepérage, Wear OS et widgets.
- Notifications avancées.
- Export avancé PDF ou tableur.
- Partage des données avec d’autres personnes.

## Documentation du dépôt

Les spécifications et décisions de développement sont conservées dans des documents séparés :

- `RITMO_0.0.1_SCOPE.md` — périmètre de la première version.
- `RITMO_0.0.1_ROADMAP.md` — étapes d’implémentation.
- `RITMO_0.0.1_DATA_MODEL.md` — modèle de données proposé.
- `RITMO_0.0.1_ACCEPTANCE.md` — critères d’acceptation et tests.
- `RITMO_DECISIONS.md` — décisions approuvées, propositions et questions ouvertes.

## État du développement

RITMO 0.0.1 est en cours de développement. Ce README décrit les objectifs et le périmètre prévu ; il ne prétend pas que toutes les fonctionnalités listées sont déjà implémentées ou vérifiées.

La compilation, les tests automatisés, les migrations, la sauvegarde/restauration et le comportement sur téléphones et tablettes doivent être vérifiés avant de considérer la version comme terminée.

---

**RITMO — Organisez votre travail. Gardez le contrôle de vos données.**
