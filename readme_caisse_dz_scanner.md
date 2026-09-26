# caisse_dz_scanner

Application mobile Flutter (Android/iOS) faisant office de **compagnon scanner/terrain** pour l'application desktop de caisse **"Caisse DZ"**. Elle permet de scanner des codes-barres, consulter/créer des produits, faire des ventes rapides, des entrées de stock, des bons de réception (photo) et des retours, le tout en se synchronisant avec le poste desktop sur le réseau local.

Ce document sert de référence d'intégration : il décrit l'architecture, les modèles, le stockage local et surtout **le contrat réseau attendu côté application desktop "Caisse DZ"** pour que le pairing, l'authentification et la synchronisation fonctionnent.

---

## 1. Vue d'ensemble

- **Rôle** : client mobile "terrain" qui se pair avec **un seul poste desktop Caisse DZ à la fois** sur le réseau local (LAN/Wi-Fi), s'authentifie avec un compte utilisateur du desktop, puis échange des données via une API HTTP exposée par le desktop.
- **Deux backends distincts** consommés par l'app, à ne pas confondre :
  1. **Le desktop Caisse DZ** (réseau local, `http://<ip>:8080`) — ventes, stock, réceptions, retours, authentification, catalogue synchronisé (produits/marques/catégories).
  2. **Un catalogue cloud partagé** (`https://bensds.com/catalog-api/`) — indépendant de tout desktop, utilisé en fallback pour rechercher un produit par code-barres inconnu localement, et pour créer un nouveau produit "canonique" (avec upload photo) avant de le rattacher au desktop pairé.
- **Fonctionnement offline-first** : toute écriture critique (vente, entrée de stock, retour, réception) est d'abord persistée en local (SQLite) avec `sync_status = 'pending'`, puis poussée vers le desktop via une file d'attente (`sync_outbox`) rejouable.

---

## 2. Stack technique

| Domaine | Librairie |
|---|---|
| HTTP (desktop + sync) | `dio` |
| HTTP (catalogue cloud) | `http` |
| Base locale | `sqflite` (SQLite) |
| Scan code-barres / QR | `barcode_scan2` |
| Sélection photo | `image_picker` |
| Permissions | `permission_handler` |
| État réactif léger | `ChangeNotifier` (pas de vrai arbre `Provider`, malgré la dépendance) |
| Découverte réseau | **implémentée manuellement** (voir §6) — `bonsoir` (mDNS) est présent dans `pubspec.yaml` mais **inutilisé** (mort) |

Android : `applicationId com.example.caisse_dz_scanner`, label `"Catalogue DZ"`, `usesCleartextTraffic="true"` (le trafic HTTP non chiffré vers le desktop est volontairement autorisé).

---

## 3. Architecture du code

```
lib/
  main.dart                     # Splash screen -> routage selon l'état de session
  config/
    api_config.dart             # Config du catalogue cloud (baseUrl, apiKey)
    app_theme.dart               # Thème (violet #755DB3)
  models/
    app_session.dart            # Session unique (pairing + login), persistée en SQLite
    produit.dart                # Product (modèle canonique produit)
    produit_request.dart        # Payload de création produit (catalogue cloud)
    cart_item.dart               # Ligne de panier (en mémoire uniquement)
    reception_bon.dart           # Bon de réception (lecture depuis SQLite)
    stock_movement.dart          # Ligne d'historique de stock (calculée, non persistée)
  services/
    session_service.dart         # Source de vérité de la session (SQLite, singleton)
    desktop_discovery_service.dart # Pairing, ping, découverte réseau, upload réception
    auth_service.dart            # Login/logout auprès du desktop
    sync_service.dart            # Moteur de synchro générique (outbox + pull)
    database_service.dart        # Schéma SQLite complet (10 tables)
    product_repository.dart      # Recherche produit local -> fallback cloud
    catalog_api_service.dart     # Client du catalogue cloud (bensds.com)
    cart_service.dart            # Panier en mémoire (ChangeNotifier)
    sale_service.dart            # Finalisation de vente
    stock_service.dart           # Entrée de stock + historique produit
    return_service.dart          # Retours client/fournisseur
    reception_services.dart      # Bons de réception (photo)
    barcode_scanner_service.dart # Wrapper barcode_scan2
  screens/
    desktop_pairing_screen.dart  # Pairing QR / saisie manuelle
    login_screen.dart            # Login utilisateur
    home_screen.dart             # Landing
    product_search_screen.dart   # Hub principal (scan, drawer, panier)
    product_detail_screen.dart   # Détail produit + historique stock
    product_form_screen.dart     # Création/édition produit
    quick_stock_entry_screen.dart # Entrée de stock rapide ("SmartScan")
    cart_screen.dart             # Panier / validation de vente
    reception_bon_screen.dart    # Photo + envoi bon de réception
    reception_history_screen.dart # Historique des bons envoyés
    return_screen.dart           # Retour client/fournisseur
```

**Pas de state management centralisé** : chaque service est un singleton (`Service.instance`) accédé directement depuis les écrans. Pas de routes nommées : navigation via `Navigator.push`/`pushReplacement`/`pushAndRemoveUntil` + `MaterialPageRoute`.

### Flux de démarrage (`main.dart`)
1. `SplashScreen` demande les permissions caméra/stockage.
2. Charge `SessionService.instance.getSession()`.
3. Redirige :
   - pas de pairing desktop → `DesktopPairingScreen`
   - pairé mais pas loggé → `LoginScreen`
   - pairé + loggé → `HomeScreen`

---

## 4. Modèles de données

### `AppSession` (session unique, table `app_session`, une seule ligne `id=1`)
- Pairing desktop : `desktopIp`, `desktopPort` (défaut 8080), `desktopName`, `desktopToken`
- Utilisateur : `userId`, `userNom`, `userToken`, `userRole`, `userPermissions: List<String>` (stockées en TEXT jointes par virgule)
- Sync : `lastFullSyncAt` (curseur ISO8601 pour le pull incrémental)
- `deviceId` (généré une fois : `mobile_<millisecondsSinceEpoch>`, identifie l'appareil auprès du desktop)
- `isPairedWithDesktop` ⇔ `desktopIp != null && desktopToken != null`
- `isLoggedIn` ⇔ `userToken != null`

### `Product` (`produit.dart`)
Modèle canonique utilisé pour le cache local et le catalogue cloud : `id` (id catalogue distant), `localId` (id SQLite local), `codeProduit`, `nom`, `description`, `brandId/brandName`, `categoryId/categoryName`, `couleur`, `taille`, `photo` (URL), `sourceId/sourceName`, `barcodes: List<String>?`, `quantiteStock`, `prixVente`, `createdAt`, `updatedAt`.

### `ProductRequest` (`produit_request.dart`)
Payload dédié à la **création** de produit sur le catalogue cloud (distinct de `Product`). Auto-génère `codeProduit = 'DZ_<millis>'` si non fourni.

### `CartItem`
En mémoire uniquement (pas persisté avant validation de vente) : `product`, `quantite`, `prixUnitaire`, `remiseLigne`, `total` calculé.

### `ReceptionBon`
Lecture depuis la table `reception_bons` : `localId`, `remoteId`, `fournisseur`, `numBon`, `commentaire`, `photoPath`, `dateEnvoi`, `statut`, `syncStatus`.

### `StockMovement`
Ligne d'historique **calculée à la volée** (jamais persistée telle quelle) en fusionnant `stock_movements` + `sale_items` + `returns` pour un produit donné : `type` (`entree`|`vente`|`retour_client`|`retour_fournisseur`), `quantite` signée, `date`, `detail`.

---

## 5. Base de données locale (SQLite — `caissedz_scanner.db`)

Foreign keys activées (`PRAGMA foreign_keys = ON`). 10 tables :

- **`app_session`** — session unique (voir §4)
- **`brands`** (`id`, `nom`, `updated_at`)
- **`categories`** (`id`, `nom`, `updated_at`)
- **`products`** (`local_id` PK auto, `remote_id` UNIQUE, `code_produit`, `nom`, `description`, `brand_id`, `category_id`, `couleur`, `taille`, `photo_url`, `photo_local_path`, `prix_achat`, `prix_vente`, `source`: `mobile`|`catalog`|`desktop`, `sync_status`: `pending`|`synced`, `created_by_device`, `updated_at`)
- **`product_barcodes`** (`product_local_id` → `products`, `barcode` UNIQUE — un code-barres = un produit)
- **`stock`** (`product_local_id` PK, `quantite`, `seuil_alerte`, `updated_at` — quantité en cache, une ligne par produit)
- **`stock_movements`** (mouvements d'entrée : `type='entree'`, `quantite`, `prix_achat`, `fournisseur`, `reference_vente_id`, `reference_bon_id`, `commentaire`, `sync_status`)
- **`sales`** (`uuid` UNIQUE — clé d'idempotence côté desktop, `client_nom`, `client_telephone`, `total`, `remise`, `mode_paiement`: `especes`|`carte`|`autre`, `statut`, `sync_status`)
- **`sale_items`** (lignes de vente, FK `sale_local_id`, `product_local_id`)
- **`reception_bons`** (`fournisseur`, `num_bon`, `commentaire`, `photo_local_path`, `photo_url`, `statut`: `en_attente`|`erreur`|valeur renvoyée par le desktop (défaut `envoyé`), `sync_status`)
- **`returns`** (`type`: `client`|`fournisseur`, `product_local_id`, `quantite`, `reference_sale_id`, `reference_bon_id`, `motif`, `sync_status`)
- **`sync_outbox`** — file d'attente générique : `entity`, `entity_local_id`, `operation` (`create`|`update`), `payload` (JSON texte), `attempts`, `last_error`, `created_at`
- **`sync_log`** — journal : `direction` (`push`|`pull`), `entity`, `status` (`success`|`error`), `detail`, `created_at`

---

## 6. Intégration réseau avec le desktop "Caisse DZ" (contrat à implémenter côté desktop)

C'est la section la plus importante pour un projet "caisse dz" qui doit **exposer une API compatible**.

### 6.1 Transport
- HTTP simple (pas HTTPS), **port fixe `8080`**, base URL `http://<desktopIp>:8080`.
- Pas de WebSocket, pas de mDNS (la dépendance `bonsoir` est présente mais **non utilisée**).

### 6.2 Découverte / pairing (deux mécanismes, toujours à l'initiative du mobile)

**A. Pairing par QR code (mécanisme principal)**
Le desktop doit afficher un QR code contenant :
```json
{ "ip": "192.168.1.10", "port": 8080, "pairing_token": "...", "desktop_name": "..." }
```
Le mobile scanne (ou permet la saisie manuelle du JSON, utile en émulateur) puis appelle :
```
POST /api/pairing/confirm
Body: { "pairing_token": "<du QR>", "device_id": "<deviceId mobile>", "device_name": "CaisseDZ Scanner Mobile" }
Timeout: 5s connect / 5s receive
Réponse attendue: { "success": true, "desktop_token": "...", "error"?: "..." }
```
Si le mobile était déjà pairé avec un **autre** desktop, la session utilisateur précédente est invalidée automatiquement côté mobile après un nouveau pairing réussi.

**B. Scan de sous-réseau (fallback, utilisé notamment pour les réceptions)**
Le mobile détecte son IPv4 locale, dérive le préfixe `/24`, puis tente une connexion TCP brute sur `a.b.c.1` → `a.b.c.254` port `8080` (timeout 500ms/IP). Aucune authentification à ce stade, juste "le port répond".
Cas spécial dev : IP émulateur Android `10.0.2.2:8080` câblée en dur dans l'écran de réception.

**C. Heartbeat / statut de connexion**
```
GET /api/discovery
```
Tout code 200 vaut "vivant". Le mobile ping toutes les 10s ; `isConnected` côté mobile = dernier ping réussi il y a moins de **30 secondes** (pas de détection de présence côté serveur, juste du polling côté client).

### 6.3 Authentification (deux jetons distincts, à gérer côté desktop)

1. **`desktop_token`** (niveau appareil/pairing) — obtenu via `/api/pairing/confirm`, envoyé dans le header `X-Desktop-Token` sur quasiment tous les appels.
2. **`user_token`** (niveau utilisateur) — obtenu via `/api/auth/login`, envoyé dans le header `Authorization: Bearer <user_token>` **uniquement** sur les appels de synchronisation (push/pull). Les appels de `AuthService`/`DesktopDiscoveryService` (login, ping, upload réception, fournisseurs) n'envoient **que** `X-Desktop-Token`.

```
POST /api/auth/login
Headers: X-Desktop-Token: <desktop_token>
Body: { "username": "...", "password": "...", "device_id": "<deviceId>" }
Timeout: 8s/8s
Réponse: { "success": true, "token": "...", "user": { "id":.., "nom":.., "role":.., "permissions": ["..."] } }
```
401 → message "Nom d'utilisateur ou mot de passe incorrect" côté mobile. Le login exige un pairing préalable.

### 6.4 Synchronisation (moteur `sync_service.dart`)

**Push (outbox)** — un POST par lot, par type d'entité, header `X-Desktop-Token` + `Authorization: Bearer <user_token>` :

| Entité | Endpoint |
|---|---|
| vente | `POST /api/sync/push/sale` |
| produit | `POST /api/sync/push/product` |
| mouvement de stock | `POST /api/sync/push/stock-movement` |
| retour | `POST /api/sync/push/return` |

Body :
```json
{ "items": [ { "local_id": 123, "operation": "create", "...champs de l'entité...": "..." } ] }
```
Réponse attendue :
```json
{ "success": true, "mapping": [ { "local_id": 123, "remote_id": 9876 } ] }
```
Le mobile met à jour `remote_id` + `sync_status='synced'` localement et vide l'outbox pour les items confirmés. En cas d'échec, les items restent en attente (retry au prochain cycle, `attempts`/`last_error` incrémentés).

> Note : les **bons de réception n'utilisent pas cet outbox générique** — ils passent par un upload multipart dédié et immédiat (voir §6.5).

Payloads détaillés par entité (contenu du champ `payload` décodé, en plus de `local_id`/`operation`) :

- **`sale`** :
  ```json
  {
    "uuid": "microseconds-deviceId-random", "client_nom": "...", "client_telephone": "...",
    "total": 0.0, "remise": 0.0, "mode_paiement": "especes|carte|autre", "created_at": "...",
    "items": [ { "barcode": "...", "remote_product_id": 1, "quantite": 1, "prix_unitaire": 0.0, "remise_ligne": 0.0 } ]
  }
  ```
  `uuid` sert de clé d'idempotence — le desktop doit la traiter comme unique.
- **`stock_movement`** : `{ "barcode", "remote_product_id", "type": "entree", "quantite", "prix_achat", "fournisseur", "commentaire", "created_at" }`
- **`return`** : `{ "type": "client|fournisseur", "barcode", "remote_product_id", "quantite", "reference_sale_id", "reference_bon_id", "motif", "created_at" }`
- **`product`** : produit créé/modifié depuis le mobile (source `mobile`), à intégrer au catalogue du desktop. Champs additionnels acceptés (v2, voir §6.4bis) : `marque` (texte libre), `prix_achat`, `prix_vente` (tous deux optionnels — si `prix_vente` est omis alors qu'un `prix_achat` > 0 est fourni, le desktop calcule automatiquement le prix de vente avec la marge système, comme le fait le formulaire de création rapide desktop). Le desktop pousse ensuite lui-même le produit créé vers le Catalogue DZ (bensds.com) si un code-barres est présent — le mobile n'a pas besoin d'appeler ce catalogue pour la création (voir §7).
  - **`photo`** (optionnel, v2) : **chaîne base64** de l'image (avec ou sans préfixe data URI type `data:image/jpeg;base64,...`, les deux sont acceptés). Le desktop décode et enregistre le fichier lui-même (`PhotoService`) — ne jamais envoyer un chemin/nom de fichier local ni une URL dans ce champ, ce n'est pas ce qui est attendu. Un `photo` invalide/non décodable est silencieusement ignoré (le produit est quand même créé, sans photo), jamais bloquant.

**Pull (catalogue incrémental)** :
```
GET /api/sync/pull?since=<lastFullSyncAt ISO8601>   (paramètre omis au tout premier sync)
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
```
Réponse attendue :
```json
{
  "success": true,
  "server_time": "2026-08-16T...",
  "brands": [ { "id": 1, "nom": "...", "updated_at": "..." } ],
  "categories": [ { "id": 1, "nom": "...", "updated_at": "..." } ],
  "products": [
    {
      "id": 1, "code_produit": "...", "nom": "...", "description": "...",
      "brand_id": 1, "category_id": 1, "couleur": "...", "taille": "...",
      "photo_url": "/api/photos/products/PRD000123_main.jpg", "prix_achat": 0.0, "prix_vente": 0.0, "source": "...",
      "updated_at": "...",
      "barcodes": ["..."],
      "stock": { "quantite": 0, "seuil_alerte": 0 }
    }
  ]
}
```
- Le mobile met à jour son curseur `lastFullSyncAt` avec `server_time` (à fournir précisément par le desktop, sinon le mobile retombe sur son heure locale UTC).
- **Résolution de conflit last-write-wins sur `updated_at`** : si le produit local a `sync_status='pending'` (édition locale non encore poussée) ET que son `updated_at` est ≥ à celui reçu du serveur, la mise à jour distante est **ignorée** pour protéger l'édition locale. Sinon le distant écrase le local.
- **`photo_url`** : ce n'est PAS une URL absolue — c'est un chemin serveur relatif (`/api/photos/products/<fichier>`, ou `null` si le produit n'a pas de photo) à combiner avec l'ip/port du desktop pairé pour obtenir une URL récupérable, ex. `http://192.168.1.10:8080/api/photos/products/PRD000123_main.jpg`. Voir §6.4bis pour la route qui sert ce fichier.

### 6.4bis Lookups unitaires produit (v2 — client mobile "live" sans DB locale)

Ajoutés pour un mobile qui ne maintient plus de cache catalogue local (voir
`caisse_dz_scanner_migration_v2.md`) : au lieu de tirer tout le catalogue via
`/api/sync/pull`, chaque scan/recherche interroge le desktop en direct.

```
GET /api/products/barcode/<code>
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Réponse (200) : { "success": true, "product": { ...même forme qu'un item de sync/pull... } }
Réponse (404) : { "success": false, "error": "Produit introuvable" }
```

```
GET /api/products/search?q=<texte>
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Réponse : { "success": true, "products": [ {...}, ... ] }   (nom/code/code-barres, limité à ~30 résultats)
```

```
GET /api/photos/products/<nom_de_fichier>
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Réponse (200) : image binaire (Content-Type déduit de l'extension), correspond au `photo_url` renvoyé
                par les routes produit ci-dessus.
Réponse (400) : nom de fichier invalide — Réponse (404) : photo introuvable
```

### 6.4ter Clients et validation de session (v2)

```
GET /api/clients
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Réponse : { "success": true, "clients": [ { "code", "nom", "telephone" }, ... ] }
```

```
GET /api/auth/session
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Réponse (200) : { "success": true, "user": { "id", "nom", "role", "permissions" } }   (même forme que /api/auth/login)
Réponse (401) : token invalide ou utilisateur désactivé
```
Permet au mobile de revalider une session persistée (secure storage) au démarrage plutôt que de forcer un nouveau login à chaque fois.

### 6.5 Upload de bon de réception (multipart, flux dédié, hors outbox)
```
POST /api/reception/upload
Content-Type: multipart/form-data
Headers: Accept: application/json, X-Desktop-Token: <desktop_token>
Champs: photo (fichier, "reception_<millis>.jpg"), fournisseur, num_bon, commentaire (""  si vide),
        device_id, date_reception (ISO8601 UTC)
Timeouts: 30s connect / 5min receive
```
Réponse attendue : objet JSON contenant au minimum `id` (et idéalement `statut`). Le mobile crée d'abord la ligne locale (`statut='en_attente'`), puis met à jour avec `remote_id`/`statut` reçu ; en cas d'échec réseau, `statut='erreur'` (pas de retry automatique implémenté côté mobile — la photo reste sur l'appareil).

### 6.6 Liste des fournisseurs (autocomplétion)
```
GET /api/fournisseurs
Headers: X-Desktop-Token
Réponse: { "success": true, "fournisseurs": [ {...} ] }
```

### 6.6bis Photo attachée à un SmartScan (v2, multipart, en 2 temps)

Remplace, côté mobile, l'usage de `/api/reception/upload` : la photo (bon de livraison/facture) est rattachée à un SmartScan déjà créé via `/api/sync/push/stock-movement`, pas à une entité "bon de réception" séparée.

```
POST /api/smartscan/upload
Content-Type: multipart/form-data
Headers: X-Desktop-Token + Authorization: Bearer <user_token>
Champs: photo (fichier), smartscan_remote_id (l'id renvoyé par push/stock-movement, dans `mapping[].remote_id`)
Réponse (200) : { "success": true, "chemin_photo": "smart_scans/2026/08/19/xxx.jpg" }
Réponse (404) : SmartScan introuvable pour ce remote_id
```

### 6.7 Récapitulatif des endpoints à exposer côté desktop

| Méthode | Endpoint | Auth | Usage |
|---|---|---|---|
| GET | `/api/discovery` | — | heartbeat/ping |
| POST | `/api/pairing/confirm` | `pairing_token` | pairing initial |
| POST | `/api/auth/login` | `X-Desktop-Token` | login utilisateur |
| GET | `/api/auth/session` | `X-Desktop-Token` + `Bearer` | *(v2)* validation d'une session persistée (whoami) |
| GET | `/api/products/barcode/<code>` | `X-Desktop-Token` + `Bearer` | *(v2)* lookup produit unitaire par code-barres, sans cache local |
| GET | `/api/products/search?q=` | `X-Desktop-Token` + `Bearer` | *(v2)* recherche texte produit (nom/code/code-barres) |
| GET | `/api/photos/products/<fichier>` | `X-Desktop-Token` + `Bearer` | *(v2)* sert le fichier photo d'un produit (voir `photo_url`) |
| GET | `/api/clients` | `X-Desktop-Token` + `Bearer` | *(v2)* liste des clients actifs |
| GET | `/api/sync/pull?since=` | `X-Desktop-Token` + `Bearer` | catalogue incrémental (marques, catégories, produits, stock) — toujours dispo, plus utilisé par le mobile v2 (remplacé par les lookups unitaires ci-dessus) |
| POST | `/api/sync/push/sale` | `X-Desktop-Token` + `Bearer` | pousser les ventes (module Panier) |
| POST | `/api/sync/push/product` | `X-Desktop-Token` + `Bearer` | pousser les produits créés/modifiés en mobile (payload étendu v2 : `marque`/`prix_achat`/`prix_vente`, voir §6.4) |
| POST | `/api/sync/push/stock-movement` | `X-Desktop-Token` + `Bearer` | pousser les entrées de stock (module SmartScan) |
| POST | `/api/smartscan/upload` | `X-Desktop-Token` + `Bearer` | *(v2)* attacher une photo à un SmartScan (module SmartScan) |
| POST | `/api/sync/push/return` | `X-Desktop-Token` + `Bearer` | pousser les retours — toujours dispo, plus utilisé par le mobile v2 (module Retour retiré du périmètre mobile) |
| POST | `/api/reception/upload` | `X-Desktop-Token` | upload photo + métadonnées d'un bon de réception — toujours dispo, plus utilisé par le mobile v2 (remplacé par `/api/smartscan/upload`) |
| GET | `/api/fournisseurs` | `X-Desktop-Token` | liste des fournisseurs pour autocomplétion |

> **Périmètre mobile v2** : voir `caisse_dz_scanner_migration_v2.md` pour le détail de la
> nouvelle architecture (client "live" sans DB locale) et des 4 modules mobiles
> (Connexion PC / Produit / Panier / Envoi photos SmartScan). Les endpoints marqués
> "toujours dispo, plus utilisé" ne sont pas supprimés (rétrocompatibilité) mais ne font
> plus partie du contrat consommé par la nouvelle version du mobile.

---

## 7. Catalogue cloud (indépendant du desktop)

Backend séparé, utilisé en fallback quand un code-barres n'est pas trouvé localement, et pour créer un produit "canonique" avant rattachement au desktop pairé.

Config (`lib/config/api_config.dart`) :
```dart
baseUrl = 'https://bensds.com/catalog-api/index.php'
apiKey  = 'import2026'   // header X-API-Key
```

Endpoints utilisés (`catalog_api_service.dart`, via `package:http`) :
- `GET /products/barcode/{barcode}` → `{ success, data: <Product json> }`
- `POST /mobile-products` (body = `ProductRequest.toJson()`) → `{ success, data: {...} }` (inclut `id`, `code_produit`)
- `POST /upload-photo` (multipart, champ `photo`) → `{ success, data: { photo_url } }`
- `GET /brands`, `GET /categories` → `{ success, data: [...] }`

Flux `product_repository.dart` : recherche locale (`product_barcodes` → `products` JOIN `brands`/`categories`/`stock`) → si absent, fallback catalogue cloud → si trouvé, mise en cache locale (`source='catalog'`, `sync_status='synced'`) → sinon `null` (déclenche la création de produit).

---

## 8. Logique métier — services clés

- **`AuthService`** — login/logout contre le desktop pairé (exige un pairing préalable).
- **`SessionService`** — source de vérité unique de la session (pairing + login), persistée SQLite, remplace tout usage de `shared_preferences` pour cet état.
- **`DesktopDiscoveryService`** — pairing, ping/heartbeat, scan de sous-réseau, upload réception, liste fournisseurs.
- **`SyncService`** — outbox générique (push par lot avec mapping `local_id → remote_id`) + pull incrémental avec résolution de conflit.
- **`ProductRepository`** — recherche produit local-first avec fallback cloud et mise en cache.
- **`SaleService`** — validation de vente : transaction locale (vente + lignes + décrément stock) → enqueue `sale` → sync immédiate best-effort.
- **`StockService`** — entrée de stock ("SmartScan") : transaction locale (mouvement + incrément stock + maj prix d'achat) → enqueue `stock_movement`. Fournit aussi l'historique fusionné (`getHistory`) affiché sur la fiche produit.
- **`ReturnService`** — retour client (`+quantite` en stock) ou fournisseur (`-quantite`), référence optionnelle à une vente/bon **déjà synchronisé** (`remote_id` requis pour être proposé en référence).
- **`ReceptionService`** — bon de réception : écriture locale immédiate puis upload photo multipart (flux non rejouable automatiquement en cas d'échec).

**Pattern commun aux écritures critiques** : refuser si offline (`isPairedWithDesktop && isLoggedIn` requis) → écrire en local SQLite en transaction (`sync_status='pending'`) → `SyncService.enqueue(...)` → `unawaited(syncNow())` en best-effort immédiat (la vraie garantie de livraison vient de l'outbox rejouable, pas de cet appel immédiat).

---

## 9. Écrans / parcours utilisateur

1. **Splash** → **Pairing desktop** (QR ou saisie manuelle) → **Login** → **Home**
2. **Home** → **Recherche produit** (hub principal, scan ou saisie code-barres)
   - Produit trouvé → détail, ajout au panier, ou entrée de stock rapide
   - Produit introuvable → proposition de création (formulaire produit, passe par le catalogue cloud puis synchro desktop)
3. **Panier** → validation de vente (mode de paiement, remise, client optionnel)
4. **Bon de réception** → photo + fournisseur/num de bon → historique des envois
5. **Retour** → client ou fournisseur, avec référence optionnelle à une vente/bon déjà synchronisé
6. **Menu (drawer)** : Scanner, Bon de réception, Retour produit, Connecter au desktop, Synchroniser maintenant, Déconnexion (Historique/Paramètres sont des stubs non implémentés)

---

## 10. Points d'attention pour l'implémentation côté "Caisse DZ" (desktop)

- Le desktop doit **générer et afficher un QR code de pairing** contenant `ip`, `port` (8080), `pairing_token`, `desktop_name`.
- Le desktop doit gérer **deux niveaux de token** (`desktop_token` pairing-scope, `user_token` login-scope) et vérifier le bon header selon l'endpoint (voir tableau §6.7).
- Les endpoints de sync push doivent être **idempotents par lot** et renvoyer un mapping complet `local_id → remote_id` pour chaque item accepté, sinon l'item reste bloqué en attente côté mobile indéfiniment.
- `sales.uuid` doit être traité comme clé d'unicité pour éviter les doublons en cas de renvoi réseau.
- Le pull doit renvoyer un `server_time` fiable — c'est le curseur utilisé pour l'incrémental suivant.
- Le port est fixe (`8080`) et non configurable côté mobile sans modification du code — à garder en tête si le desktop change de port par défaut.
- Aucune sécurité TLS : à n'utiliser que sur réseau local de confiance.
