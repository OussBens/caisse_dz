# Caisse DZ

Logiciel de caisse (POS) et de gestion de stock **desktop Windows** pour les
commerces algériens : ventes, stock multi-magasin, achats, clients /
fournisseurs, sessions de caisse, Smart Scan IA des bons d'achat, zakat,
rapports. Interface **FR / EN / AR**.

> Version : **1.2.0** · Flutter **3.47** (Dart ≥ 3.9) · Base SQLite locale (DB **v52**)

---

## Sommaire
- [Modules](#modules)
- [Architecture](#architecture)
- [Licences Basic / Avancée](#licences-basic--avancée)
- [Smart Scan (OCR) et serveur BENS](#smart-scan-ocr-et-serveur-bens)
- [Démarrer](#démarrer)
- [Tests](#tests)
- [Exécution dans le cloud](#exécution-dans-le-cloud)
- [Structure du dépôt](#structure-du-dépôt)
- [Travaux en cours](#travaux-en-cours)
- [Documentation](#documentation)

---

## Modules

| Catégorie | Modules |
|---|---|
| Ventes | **Caisse** (tickets, BL, factures, packs, remises, scan code-barres), **Panier**, **Retour** client / fournisseur |
| Stock | **Produit** (tableau ou cards, catégories, packs, remises), **Stock** (+ distribution entre magasins), **Entrée** (+ Smart Scan IA), **Sortie**, **Magasin** (transferts), **Besoin** (ruptures, expirés) |
| Tiers | **Client**, **Fournisseur**, **Utilisateur** (rôles et permissions) |
| Caisse | **Gestion caisse** : caisses, sessions ouverture / clôture, mouvements, transferts, clôtures Z |
| Autres | **Tableau de bord** (situations, marges, coût produit), **Zakat**, **Paramètres**, **Historique**, Alertes (rupture, crédits, sessions non clôturées), modules favoris |

## Architecture

```
lib/
├── screens/           Écrans des modules (un écran = un module)
├── core/
│   ├── dialog/        Dialogs par module (nouveau, modifier, détail, annuler…)
│   ├── tableau/       Tableaux Syncfusion (BaseTableDataSource)
│   ├── widget/        Widgets réutilisables (champs, cards, afficheurs, AppShell…)
│   ├── Auth/          AuthState (session, rôle, licence, magasins, favoris)
│   └── theme/ utilis/ Style, formats (quantités, montants)…
├── Services/          Accès aux données et règles métier — aucun SQL ailleurs
├── data/models/       Modèles (fromMap / toMap)
├── l10n/              Traductions FR (modèle) / EN / AR
├── DBCreate.dart      Schéma SQLite + migrations (version courante : 52)
└── router.dart        go_router (ShellRoute : sidebar + barre de titre intégrée)
```

**Principes** (voir `CLAUDE.md`) : pas de SQL dans les écrans / widgets ;
réutiliser widgets, dialogs et services existants ; compatibilité ascendante ;
tout texte affiché passe par `l10n`.

**Stock** : il n'y a pas de compteur. Le stock est calculé à partir du journal
`mouvements` : 1 mouvement = 1 produit + 1 magasin + 1 sens. Les annulations
sont des *soft-cancel* (`etat = 0`), jamais des suppressions.

**Principales dépendances** : `provider`, `go_router`, `sqflite_common_ffi`,
`syncfusion_flutter_datagrid`, `bitsdojo_window`, `excel`, `pdf` / `printing`,
`fl_chart`, `http` / `dio`, `flutter_secure_storage`, `print_bluetooth_thermal`.

## Licences Basic / Avancée

Activation **hors ligne** : clé = SHA-256 (identifiant machine + secret), voir
`AuthState._generateKey`.

| | Basic | Avancée |
|---|---|---|
| Caisses | 1 | plusieurs |
| Magasins | 1 | plusieurs, avec transferts et distribution |
| Utilisateur | 1 caisse, 1 magasin | 1 caisse + **liste ordonnée de magasins** (le 1er est le principal) |

Règles de stock multi-magasin (vente, retours, sorties, distribution) :
voir [docs/05_multi_magasin.md](docs/05_multi_magasin.md).

## Smart Scan (OCR) et serveur BENS

L'OCR des bons d'achat passe par le serveur BENS
(`catalog-api.bensds.com/smartscan/*`). **Aucune clé Mistral n'est dans
l'application.**

```
Caisse DZ ──HTTPS + licence──▶ serveur PHP BENS ──▶ Mistral OCR
              (quota par client : forfait STANDARD 60 / mois, SMART_SCAN_200…)
```

- Code serveur : `server/` (PHP, sans framework), à déployer à côté de
  `index.php` = `server_index_updated.php`.
- Déploiement, `.env`, tables et administration :
  [server/README_SMARTSCAN.md](server/README_SMARTSCAN.md).
- Côté application : `lib/Services/ai_proxy.dart`, `SmartScanQuota.dart`,
  `CarteQuotaSmartScan`, `QuotaSmartScanAtteintDialog`.

## Démarrer

Prérequis : Flutter 3.47+ (canal stable), Windows 10/11 avec Visual Studio
(charge de travail « Développement Desktop en C++ »).

```bash
flutter pub get
flutter gen-l10n
flutter run -d windows
```

- La base locale est créée dans `%APPDATA%\Caisse DZ\` au premier lancement.
  Sur une installation activée, l'utilisateur par défaut est `admin` / `123456`.
- Serveur Smart Scan de test :
  `flutter run -d windows --dart-define=SMARTSCAN_URL=http://127.0.0.1:8765/smartscan`
- Installateur : `installer/caisse_dz.iss` (Inno Setup). Les `.exe` générés
  ne sont pas versionnés.

## Tests

```bash
flutter analyze lib                      # 0 erreur attendue
flutter test                             # règles multi-magasin + modèle Smart Scan
php server/tests/smartscan_test.php      # 62 tests serveur (SQLite en mémoire, faux Mistral)
```

Recette manuelle : [TESTING_CHECKLIST.md](TESTING_CHECKLIST.md).

## Exécution dans le cloud

L'application cible **Windows** : un environnement cloud (Linux) ne peut pas
lancer l'application ni produire l'exécutable Windows. On peut en revanche y
lancer :

```bash
flutter pub get && flutter gen-l10n
flutter analyze lib
flutter test
php server/tests/smartscan_test.php     # nécessite php + pdo_sqlite
```

La compilation et les tests visuels se font sur un poste Windows.

## Structure du dépôt

| Dossier / fichier | Contenu |
|---|---|
| `lib/` | Application Flutter |
| `test/` | Tests Dart |
| `server/` | Serveur Smart Scan (PHP) + tests + guide de déploiement |
| `server_index_updated.php` | `index.php` du serveur BENS (catalogue + routes Smart Scan) |
| `docs/` | Vision, architecture, charte graphique, workflow illustré, multi-magasin |
| `assets/` | Icônes, images, polices |
| `installer/` | Script Inno Setup et icônes (sans les `.exe`) |
| `windows/`, `macos/`, `linux/`… | Projets plateforme Flutter |
| `TESTING_CHECKLIST.md` | Recette manuelle |

Non versionnés (voir `.gitignore`) : `.env`, bases `*.db`, installateurs
`*.exe`, `build/`, `/flutter` (SDK local), `/vcpkg`, logs, `.claude/`.

## Travaux en cours

### Multi-magasin & multi-caisse — 🟡 étape 8 / 8 (vérification)

Étapes 1 à 7 terminées : fondation DB v52, magasins par utilisateur, caisse
sans magasin, consultation, entrées, ventes / retours / sorties répartis,
distribution. La migration v52 est appliquée et vérifiée sur la base réelle.

**📍 Arrêt :** juste avant le test visuel dans l'application, l'écran de
connexion étant ouvert.

**Reste à faire :**
- Tests réels : Utilisateur (magasins ordonnés), Distribution, vente sur 2 magasins puis annulation, retours, sortie, licence Basic.
- Dashboard / Situations limités aux magasins consultables.
- Harmoniser les tests du rôle `admin` (enregistré en minuscules en base).
- Nettoyages : `synchroniserMagasinDeCaisse` (code mort), compteur « nombre » de `produit_magasin_detail`.

Le détail complet est dans [docs/05_multi_magasin.md](docs/05_multi_magasin.md).

### Smart Scan — 🟡 déploiement

Code serveur et application terminés et testés en local (de bout en bout avec
un faux Mistral). **Reste :**
- activer la facturation du compte Mistral (la clé répond encore `429`) ;
- déployer `index.php`, `smartscan_core/` et `admin_smartscan.php` ;
- générer un nouvel installateur, puis révoquer l'ancienne clé Mistral.

## Documentation

1. [docs/01_project_overview.md](docs/01_project_overview.md) — vision et périmètre
2. [docs/02_architecture.md](docs/02_architecture.md) — architecture
3. [docs/03_architecture_connection.md](docs/03_architecture_connection.md) — connexion / activation
4. [docs/04_charte_graphique.md](docs/04_charte_graphique.md) — charte graphique
5. [docs/05_multi_magasin.md](docs/05_multi_magasin.md) — multi-magasin : règles, avancement, reste à faire
6. [server/README_SMARTSCAN.md](server/README_SMARTSCAN.md) — serveur Smart Scan
