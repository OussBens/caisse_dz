> **Obsolète — module retiré le 2026-10-06.** L'intégration mobile (serveur
> `BonReceptionServer`, `MobilePairingButton`, `ReceptionConnectionDialog`) a
> été supprimée du desktop. Ce document ne décrit plus le code actuel ; il est
> conservé pour référence. Les colonnes de base liées (`utilisateur.api_token`,
> `device_id_mobile`) sont gardées pour la compatibilité des bases existantes.

# Architecture — Connexion Desktop ↔ Mobile

# Vue d'ensemble

CaisseDZ Desktop expose un serveur HTTP local qui permet à l'app mobile
compagnon ("CaisseDZ Scanner") de s'appairer avec le poste desktop et de
synchroniser des données (produits, ventes, mouvements de stock, retours,
photos de bons de réception) **sur le même réseau WiFi local**, sans aucun
serveur distant/cloud.

Il n'y a pas de dépôt mobile dans ce repo : le mobile est un client HTTP
indépendant qui consomme l'API exposée par le desktop.

Principe général :

```
Téléphone (app compagnon)  <—— WiFi local ——>  PC Desktop (CaisseDZ)
        client HTTP                          HttpServer (dart:io), port 8080
```

Aucune IP n'est jamais codée en dur : le desktop détecte dynamiquement ses
adresses IPv4 locales et laisse le mobile s'y connecter via un QR code
généré à la volée (cf. mémoire [[feedback_no_hardcoded_ips]]).

---

# Fichiers concernés

| Fichier | Rôle |
|---|---|
| `lib/Services/BonReceptionServer.dart` | Cœur du système : serveur HTTP, appairage, auth, endpoints REST, logique de synchronisation (push/pull) |
| `lib/core/dialog/AI/reception_connection_dialog.dart` | Dialog desktop "Connecter l'app mobile" — démarre le serveur, affiche IP/port, QR code + code d'appairage, liste des appareils appairés |
| `lib/core/widget/mobile_pairing_button.dart` | Bouton (icône téléphone) affiché dans l'en-tête des écrans, badge vert si un mobile est actuellement connecté, ouvre le dialog ci-dessus |
| `lib/core/widget/connection_status_bar.dart` | Regroupe `InternetStatusWidget` + `MobilePairingButton` dans l'en-tête de chaque écran |
| `lib/Services/secure_storage_service.dart` | Stockage sécurisé du `desktop_token` durable (chiffré, hors SharedPreferences) |
| `lib/Services/Utilisateur.dart` | `getUtilisateurByApiToken`, gestion du `api_token` de session par utilisateur |
| `lib/Services/BonReceptionPhotos.dart`, `lib/Services/Photos.dart` | Enregistrement disque des photos reçues du mobile |
| `lib/Services/CatalogService.dart` | Cascade de lookup produit par code-barres, réutilisée par l'endpoint mobile `/api/products/barcode/*` |
| `lib/DBCreate.dart` | Colonnes `device_id_mobile` sur `produits`, `panniers`, `retours`, `smart_scan` — traçabilité de l'origine mobile d'une donnée |

---

# Étapes de connexion

## 1. Découverte réseau (desktop)

Au démarrage du dialog `ReceptionConnectionDialog` :

- `BonReceptionServer.localIPv4Addresses()` liste toutes les IPv4 locales
  (`NetworkInterface.list`).
- `_pickBestIp()` choisit automatiquement la meilleure adresse
  (préférence `192.168.x.x` > `10.x.x.x` > `172.16-31.x.x` > la première
  trouvée), pour éviter de proposer une IP d'adaptateur virtuel (VPN,
  hyperviseur) inutilisable par le téléphone.
- Le serveur HTTP démarre **automatiquement** à l'ouverture du dialog
  (`_autoConnect`), sur le port sauvegardé (`SharedPreferences`,
  `bon_reception_server_port`, défaut `8080`).

## 2. Appairage (QR code + code manuel)

- `BonReceptionServer.generatePairingCode()` génère un code aléatoire à 8
  caractères (alphabet sans `0/O/1/I` pour éviter les confusions), valable
  **5 minutes** (`pairingCodeTtl`), à usage unique.
- Le dialog affiche ce code sous deux formes :
  - un **QR code** (`qr_flutter`) encodant `{ip, port, pairing_token,
    desktop_name}` ;
  - le **code en clair** (groupé par 4, ex. `AB3D-9FKQ`), copiable, pour
    saisie manuelle si le téléphone ne peut pas scanner.
- Le mobile appelle `POST /api/pairing/confirm` avec `pairing_token` +
  `device_id` (+ `device_name` optionnel). Le desktop vérifie le code et
  son expiration, enregistre l'appareil dans `pairedDevices` (persisté via
  `SharedPreferences`), puis renvoie un **`desktop_token`** durable (UUID),
  stocké côté desktop dans le secure storage (`SecureStorageService`).
- Ce `desktop_token` doit ensuite être envoyé par le mobile dans le header
  `X-Desktop-Token` sur **toutes** les requêtes suivantes (sauf
  `/api/discovery` et `/api/pairing/confirm`). Il identifie "un mobile déjà
  appairé avec ce desktop", pas un utilisateur.

## 3. Authentification utilisateur

- Une fois appairé, le mobile appelle `POST /api/auth/login` (username +
  password) avec le header `X-Desktop-Token`. Le mot de passe est haché
  avec le **même schéma** que le desktop (`sha256(password + 'SYSTEM_SALT')`,
  voir `AuthState.hashPassword`).
- Succès → un `token` de session (UUID) est généré et stocké dans
  `utilisateur.api_token` (persistant en base, pas de TTL). Le mobile doit
  ensuite envoyer ce token dans `Authorization: Bearer {token}` sur toutes
  les routes protégées par `_requireAuthenticatedUser`.
- `GET /api/auth/session` permet au mobile de revalider un token persisté
  localement (secure storage mobile) au démarrage de l'app, sans forcer un
  nouveau login, tout en détectant un utilisateur désactivé/supprimé
  entre-temps.

Donc deux niveaux d'auth empilés :

```
X-Desktop-Token   → "ce téléphone est appairé avec ce desktop"
Authorization Bearer → "cet utilisateur métier est connecté sur ce téléphone"
```

## 4. Indicateur de connexion active

- Chaque requête `GET /api/discovery` (ping périodique émis par le mobile)
  met à jour `lastPingAt`.
- `MobilePairingButton` affiche un badge vert si `lastPingAt` date de
  moins de 30 secondes — ce n'est qu'un indicateur de présence réseau, pas
  un contrôle d'accès.

---

# Serveur HTTP — détails techniques

- Implémenté avec `dart:io HttpServer` brut (`HttpServer.bind`,
  `InternetAddress.anyIPv4`, `shared: true`) — pas de dépendance `shelf`,
  volontairement minimal (une poignée de routes). Le multipart/form-data
  (upload photo) est parsé avec le paquet `mime` déjà présent dans le
  projet.
- Singleton `BonReceptionServer.instance`, piloté par des `ValueNotifier`
  (`isRunning`, `lastPingAt`, `pairingCode`, `pairedDevices`) écoutés par
  l'UI desktop pour se rafraîchir sans polling manuel.
- `onBonReceived` : callback notifié après chaque upload de bon de
  réception réussi, pour rafraîchir l'écran Réception sans polling.

---

# Endpoints exposés

| Méthode | Route | Auth | Rôle |
|---|---|---|---|
| GET | `/api/discovery` | aucune | Ping de présence, confirme que le desktop répond |
| POST | `/api/pairing/confirm` | code d'appairage | Échange le code éphémère contre un `desktop_token` durable |
| POST | `/api/auth/login` | `X-Desktop-Token` | Authentifie un utilisateur, retourne un `token` de session |
| GET | `/api/auth/session` | Desktop + Bearer | Revalide un token de session existant |
| GET | `/api/fournisseurs` | Desktop + Bearer | Liste des fournisseurs actifs (dropdown mobile) |
| GET | `/api/clients` | Desktop + Bearer | Liste des clients actifs |
| GET | `/api/products/search?q=` | Desktop + Bearer | Recherche produit (nom/code/code-barres) |
| GET | `/api/products/barcode/{code}` | Desktop + Bearer | Lookup produit par code-barres (local puis cascade catalogue distant) |
| GET | `/api/photos/products/{filename}` | Desktop + Bearer | Sert une photo produit (nom de fichier validé par regex anti path-traversal) |
| GET | `/api/sync/pull` | Desktop + Bearer | Catalogue incrémental (marques/catégories/produits), filtré par `since` |
| POST | `/api/sync/push/stock-movement` | Desktop + Bearer | Pousse des entrées de stock (créées comme SmartScan à 1 produit) |
| POST | `/api/sync/push/product` | Desktop + Bearer | Crée/met à jour un produit depuis le mobile |
| POST | `/api/sync/push/return` | Desktop + Bearer | Pousse un retour client/fournisseur |
| POST | `/api/sync/push/sale` | Desktop + Bearer | Pousse une vente (panier + lignes), idempotent sur `uuid` |
| POST | `/api/reception/upload` | `X-Desktop-Token` | Upload photo de bon de réception (multipart) |
| POST | `/api/smartscan/upload` | Desktop + Bearer | Attache une photo à un SmartScan déjà créé |

---

# Synchronisation des données

## Pull (mobile ← desktop)

`GET /api/sync/pull?since=ISO8601` renvoie catégories, sous-catégories et
produits modifiés depuis le dernier pull réussi (comparaison sur
`date_modif`/`date_cree`). Chaque produit inclut ses codes-barres
(principal + secondaires), son stock agrégé et l'URL relative de sa photo.
`brands` est toujours vide : il n'existe pas de table Marque côté desktop
(`marque` est un champ texte libre sur `produits`).

## Push (mobile → desktop)

Chaque endpoint `push/*` reçoit un batch `items[]` + `device_id` optionnel
et traite chaque item indépendamment (un item en échec est loggé et ignoré
sans bloquer les autres, réponse `mapping` associant `local_id` mobile →
`remote_id` desktop) :

- **stock-movement** : crée un SmartScan à 1 produit par item (même
  logique que "Entrée rapide" desktop), **sans** versement fournisseur
  automatique (le mobile n'envoie pas d'info de paiement).
- **product** : crée ou (si `remote_id` fourni + `operation: "update"`)
  met à jour un produit ; auto-push vers le catalogue partagé DZ
  (`CatalogSyncService`) si le produit a un code-barres.
- **return** : crée un retour client/fournisseur, ajuste stock et
  mouvement, résout le client/fournisseur via la vente/le bon référencé
  quand disponible.
- **sale** : crée un panier + lignes, résout ou crée le client par
  téléphone (repli sur le client système "Comptoire"), décrémente le
  stock, **crée un versement "Paiement" intégral** (contrairement aux
  autres push, la vente porte réellement un `total` + `mode_paiement`).
  Idempotent via `uuid` : un retry réseau ne duplique pas la vente.

Résolution produit commune (`_resolveProduitCodeForSync`) : priorité au
`remote_product_id` (id desktop connu d'un pull/push précédent), repli sur
le `barcode` scanné.

---

# Sécurité

- **Deux tokens empilés** : `X-Desktop-Token` (appareil appairé) et
  `Authorization: Bearer` (session utilisateur métier) — voir §3.
- Hash de mot de passe identique desktop/mobile (`sha256 + SYSTEM_SALT`) :
  aucun mot de passe en clair ne transite ni n'est stocké différemment.
- `desktop_token` stocké chiffré via `SecureStorageService` (pas en
  `SharedPreferences` en clair).
- Code d'appairage à usage unique, expirant après 5 minutes, alphabet sans
  caractères ambigus.
- Endpoint photo (`/api/photos/products/{filename}`) : nom de fichier
  validé par regex `^[\w.\-]+$` pour bloquer toute traversée de répertoire
  (`../..`).
- Limite de taille upload : 20 Mo par photo (`maxPhotoBytes`).
- `PairedDevice` (liste des appareils appairés) est **informatif**
  uniquement, affiché dans le dialog de connexion — ce n'est pas un
  contrôle d'accès par appareil (le `desktop_token` seul fait foi).

---

# Limites connues

- Fonctionne uniquement sur le même réseau local (pas de relai
  cloud/Internet) : le mobile doit être sur le même WiFi que le desktop.
- Pas de HTTPS (HTTP simple sur réseau local supposé de confiance).
- `desktop_token` n'expire jamais tant qu'il n'est pas régénéré
  manuellement (pas de révocation individuelle par appareil appairé).
