# Migration `caisse_dz_scanner` v2 — client "live" sans base de données mobile

Ce document liste **tout ce qui doit changer dans le dépôt mobile `caisse_dz_scanner`** pour
coller au nouveau contrat réseau exposé par le desktop CaisseDZ (voir
`readme_caisse_dz_scanner.md`, qui reste la référence du contrat réseau — ce fichier-ci décrit
uniquement les conséquences côté app mobile). Statut : contrat desktop implémenté et vérifié
(`flutter analyze` OK côté `caisse_dz`) au moment de la rédaction.

---

## 1. Objectif & rupture d'architecture

L'app passe d'un modèle **offline-first** (cache SQLite complet + file d'attente `sync_outbox`
rejouable) à un client **"live" sans base de données locale** : toute lecture/écriture passe par
un appel HTTP direct au desktop pairé, rien n'est mis en cache au-delà de la session en mémoire.
Le périmètre fonctionnel se réduit à **4 modules stricts** : Produit (recherche + création),
Envoi de photos SmartScan, Panier (ventes), Connexion PC. Les modules Bon de réception et Retour
sont retirés — la capture photo de SmartScan reprend le rôle du bon de réception.

## 2. Suppressions

- `services/database_service.dart` (schéma SQLite 10 tables)
- `services/sync_service.dart` (outbox + pull incrémental)
- `product_repository.dart` en tant que **cache local** — remplacé par des appels directs au
  desktop (voir §4)
- `screens/reception_bon_screen.dart`, `screens/reception_history_screen.dart`,
  `screens/return_screen.dart`
- `services/reception_services.dart`, `services/return_service.dart`
- `models/reception_bon.dart`
- Dépendances pubspec : `sqflite`, `bonsoir` (déjà inutilisée dans la v1)

## 3. Ce qui reste en mémoire (pas de DB)

- **Session** (pairing + login) : persistée uniquement via `flutter_secure_storage` (remplace la
  table `app_session`) — `desktopIp`, `desktopPort`, `desktopToken`, `desktopName`, `userToken`,
  `userId`, `userNom`, `userRole`, `userPermissions`, `deviceId`.
- **Panier** (`CartItem`) : en mémoire comme en v1, vidé après validation de la vente.
- Rien d'autre n'est mis en cache localement.

## 4. Nouveau contrat réseau consommé

Référence complète : `readme_caisse_dz_scanner.md` §6. Résumé des routes v2 :

| Route | Usage mobile |
|---|---|
| `GET /api/products/barcode/<code>` | Lookup direct au scan, remplace le cache local. 404 si absent → cascade §6. |
| `GET /api/products/search?q=` | Champ de recherche du module Produit, live, ~30 résultats max. |
| `GET /api/photos/products/<fichier>` | Sert la photo d'un produit — combiner avec `http://{ip}:{port}` + le `photo_url` reçu (chemin relatif, jamais une URL absolue). |
| `GET /api/clients` | Liste des clients actifs (module Panier). |
| `GET /api/auth/session` | Whoami — à appeler au démarrage pour revalider une session persistée avant de sauter le login. |
| `POST /api/sync/push/product` | Création/modification produit — payload étendu `marque`/`prix_achat`/`prix_vente` (voir §5). |
| `POST /api/sync/push/sale` | Finalisation vente (module Panier) — inchangé depuis v1, déjà idempotent via `uuid`. |
| `POST /api/sync/push/stock-movement` puis `POST /api/smartscan/upload` | Séquence SmartScan (voir §7). |

Routes toujours disponibles côté desktop mais **plus appelées par le mobile v2** :
`GET /api/sync/pull`, `POST /api/reception/upload`, `POST /api/sync/push/return`.

## 5. Module Connexion PC

Inchangé par rapport à la v1 : scan QR (`{ip, port, pairing_token, desktop_name}`) →
`POST /api/pairing/confirm` → écran login → `POST /api/auth/login`. Nouveauté v2 : à chaque
démarrage de l'app, avant de sauter l'écran de login, appeler `GET /api/auth/session` avec le
`user_token` persisté (secure storage) :
- 200 → session valide, aller directement au Home.
- 401 → token invalide ou utilisateur désactivé/supprimé entretemps → effacer la session
  utilisateur (garder le pairing desktop) et retourner à l'écran de login.

## 6. Module Produit

**Recherche** : plus de cache local. Utiliser `GET /api/products/search?q=` pour le champ de
recherche et `GET /api/products/barcode/{code}` à chaque scan. Afficher les photos via
`GET /api/photos/products/<fichier>` (préfixer le `photo_url` reçu avec `http://{ip}:{port}`).

**Cascade pour un code-barre scanné inconnu du desktop** (mêmes 5 sources, même ordre, que
`CatalogService.lookupByBarcode` côté desktop) :
1. `GET /api/products/barcode/{code}` (desktop pairé)
2. Catalogue DZ cloud (`https://bensds.com/catalog-api`, `GET /products/barcode/{barcode}`)
3. OpenFoodFacts
4. OpenPetFoodFacts
5. OpenBeautyFacts

**Création** — formulaire "rapide" reproduisant exactement `produit_nouveau.dart` (desktop) :

| Champ | Obligatoire | Défaut |
|---|---|---|
| Nom | oui | — |
| Marque | oui | — |
| Catégorie | oui | "Sans Categorie" si non choisie |
| Sous-catégorie | oui | "Sans Sous-Catego" si non choisie |
| Prix d'achat | oui, > 0 | — |
| Prix de vente | oui, ≥ achat | calculable automatiquement (le desktop applique la marge système si omis) |
| Unité de mesure | oui | première valeur de la liste |
| Description, Code-barres, Remise, Taille, Couleur, Photo, Observation | non | — |

Toujours fixés côté desktop, ne pas les envoyer : `service=false`, `etat=true`,
`multicodebar` déduit du nombre de codes-barres envoyés.

Envoi : `POST /api/sync/push/product`, payload item :
```json
{
  "local_id": 1, "operation": "create",
  "nom": "...", "marque": "...", "description": "...",
  "barcode": "...", "barcodes": ["..."],
  "category_id": 1,
  "prix_achat": 0.0, "prix_vente": 0.0,
  "couleur": "...", "taille": "...",
  "photo": "<base64 sans ou avec préfixe data URI>"
}
```
Le mobile **n'appelle plus bensds.com pour créer le produit** — le desktop pousse automatiquement
vers le Catalogue DZ après création (si un code-barres est présent), en réutilisant
`CatalogSyncService`. Le catalogue cloud reste utilisé en **lecture seule** côté mobile, pour la
cascade de recherche (étape 2 ci-dessus).

**Photo** : encoder en base64 (`base64Encode`, avec ou sans préfixe `data:image/...;base64,`,
les deux sont acceptés côté desktop) et l'inclure directement dans le champ `photo` du payload
JSON ci-dessus — **jamais** un chemin de fichier local ni une URL. Le desktop décode, enregistre
le fichier et répond dans le `mapping` habituel (`local_id` → `remote_id`) ; pour ré-afficher la
photo ensuite, refaire un `GET /api/products/barcode/{code}` et lire `photo_url`.

## 7. Module Panier

Scan + saisie quantité, panier en mémoire (`cart_service.dart` inchangé). Bouton "Vendu" →
`POST /api/sync/push/sale` direct (payload inchangé depuis v1, déjà idempotent via `uuid` — un
retry après timeout ne crée pas de doublon). Sélection client optionnelle via `GET /api/clients`
(sinon le desktop résout/crée un client par téléphone, ou retombe sur le client "Comptoire").
Pas de file d'attente durable : en cas d'échec réseau, garder le panier affiché et permettre de
réessayer immédiatement — il n'y a plus d'outbox pour rejouer plus tard.

## 8. Module Envoi photos SmartScan

Remplace le module Bon de réception v1. Séquence en 2 appels :
1. `POST /api/sync/push/stock-movement` (inchangé depuis v1 : `barcode`, `quantite`,
   `prix_achat`, `fournisseur`, `commentaire`, `created_at`) → récupérer `remote_id` dans
   `mapping[]`.
2. `POST /api/smartscan/upload` (multipart) : champs `photo` (fichier binaire réel, pas de
   base64 ici — c'est un upload multipart classique) + `smartscan_remote_id` (le `remote_id` de
   l'étape 1) → réponse `{ "success": true, "chemin_photo": "..." }`.

Si l'étape 2 échoue après succès de l'étape 1, le mouvement de stock est déjà enregistré côté
desktop — proposer un retry dédié de l'upload photo seul (ne pas renvoyer l'étape 1).

## 9. Dépendances pubspec

Retirer : `sqflite`, `bonsoir`. Garder : `dio`/`http`, `barcode_scan2`, `image_picker`,
`permission_handler`, `flutter_secure_storage`.

## 10. UX

Sans garantie de livraison différée (plus d'outbox), chaque action (création produit, vente,
envoi photo) doit afficher un résultat immédiat clair (succès/échec) plutôt qu'un état "en attente
de synchro" qui n'existe plus.
