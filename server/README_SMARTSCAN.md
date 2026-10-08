# Smart Scan — déploiement serveur BENS

Le Smart Scan (OCR des bons d'achat) passe par le serveur BENS : l'application
Caisse DZ n'a **aucune clé Mistral**. Le serveur vérifie la licence, applique
le quota mensuel du client, appelle Mistral et ne décompte un scan **que s'il
a réussi**.

```
Caisse DZ ──HTTPS──▶ catalog-api.bensds.com/smartscan/* ──▶ Mistral OCR
          (licence)    (quota, journal, clé Mistral)
```

## 1. Fichiers à envoyer (à côté de `index.php`)

| Fichier du projet | Sur le serveur |
|---|---|
| `server_index_updated.php` | `index.php` (garder une copie de l'ancien) |
| `server/smartscan_core/` (dossier entier, avec `.htaccess`) | `smartscan_core/` |
| `server/admin_smartscan.php` | `admin_smartscan.php` |

Le `.htaccess` de `smartscan_core/` interdit l'accès direct à ces fichiers par le web.

⚠️ Ne pas nommer ce dossier `smartscan` : il masquerait les routes `/smartscan/...` (Apache sert le dossier au lieu de passer par `index.php` → 403).

## 2. Fichier `.env` du serveur

```
MISTRAL_API_KEY="ta-clé-mistral"
LICENSE_SECRET="(même secret que l'application — voir AuthState._secretKey)"
ADMIN_PASSWORD="un-mot-de-passe-long"
SMARTSCAN_CONTACT="WhatsApp 0555 .. .. .."

# Protection (valeurs par défaut si absentes)
SMARTSCAN_RATE_PAR_MINUTE="6"         # scans max par minute et par client
SMARTSCAN_MAX_SIMULTANES="1"          # scans en cours en même temps par client
SMARTSCAN_TAILLE_MAX_MO="8"           # taille max d'une image
SMARTSCAN_EXTRACTIONS_PAR_SCAN="6"    # analyses IA max par scan
SMARTSCAN_PLAFOND_GLOBAL_MENSUEL="0"  # sécurité : total mensuel tous clients (0 = aucun)
SMARTSCAN_HTTPS_OBLIGATOIRE="1"
```

Les anciennes lignes `AI_DAILY_…` / `AI_MONTHLY_…` ne servent plus.

## 3. Installer les tables

Ouvrir `https://catalog-api.bensds.com/admin_smartscan.php` et se connecter avec
`ADMIN_PASSWORD` : les tables sont installées automatiquement au premier accès
(bouton **« Installer / mettre à jour les tables »** pour les mises à jour).
Cela crée (dans la base existante du catalogue) :

| Table | Rôle |
|---|---|
| `ss_forfaits` | Produits : `STANDARD` (60/mois, gratuit), `SMART_SCAN_200` (200/mois, 3 000 DA, 12 mois) |
| `ss_clients` | Un compteur mensuel par client |
| `ss_postes` | Installations Caisse DZ (licence) rattachées à un client |
| `ss_abonnements` | Offres payantes : début, fin, statut active / expired / cancelled |
| `ss_scans` | Journal de chaque scan (statut, durée, modèle, erreur) — sert au décompte |
| `ss_demandes` | Demandes d'offre envoyées depuis l'application |

Les anciennes tables `ai_device` et `ai_usage` peuvent être supprimées.

## 4. Fonctionnement

- **Nouveau poste** : enregistré au premier appel et rattaché à un nouveau
  client (nom de la boutique). Pour partager le compteur entre plusieurs
  postes d'un même client : fiche client → *Postes* → *Rattacher à*.
- **Quota** = scans réussis du mois civil. Remise à zéro automatique le 1er,
  rien n'est reporté. Limite = forfait actif (Smart Scan 200 → 200, sinon 60).
- **Échec** (réseau, timeout, erreur Mistral, image invalide, texte vide) :
  journalisé, **non décompté**.
- **Activation de Smart Scan 200** : admin → client → *Offre* → *Activer*
  (12 mois à partir de la date choisie). Prolonger / Désactiver au même endroit.
  Les demandes envoyées depuis l'application apparaissent dans *Demandes*.
- **Nouveaux forfaits** (Smart Scan 500, packs…) : admin → *Forfaits* → ajouter.
  Rien à modifier dans l'application (quotas, noms et prix viennent de l'API).
- **Paiement en ligne plus tard** : appeler `SmartScanService::activerForfait()`
  à la confirmation du paiement (même point d'entrée que l'admin).
- **Aucune photo n'est conservée** : seule une empreinte SHA-256 de l'image
  sert à refuser un même bon renvoyé deux fois en 5 minutes.

## 5. API (utilisée par Caisse DZ)

En-têtes : `X-Device-Id`, `X-License-Key`, `X-Entreprise` (facultatif, encodé URL).

| Route | Rôle |
|---|---|
| `GET /smartscan/quota` | forfait, `monthly_limit`, `used`, `remaining`, `renewal_date`, `subscription_end`, offres |
| `POST /smartscan/scan` `{image}` | OCR → `{scan_id, text, quota}` |
| `POST /smartscan/extract` `{scan_id, model, messages}` | analyse des lignes (ne consomme pas de quota) |
| `POST /smartscan/demande` `{offre}` | demande d'offre |

Refus structurés : `{"success": false, "error": "SCAN_QUOTA_EXCEEDED", "message": …, "used", "limit", "remaining", "upgrade_available"}`.
Autres codes : `LICENSE_INVALID`, `DEVICE_BLOCKED`, `CLIENT_SUSPENDED`,
`RATE_LIMITED`, `SCAN_IN_PROGRESS`, `DUPLICATE_SCAN`, `INVALID_IMAGE`,
`IMAGE_TOO_LARGE`, `OCR_FAILED`, `OCR_EMPTY`, `SERVICE_BUSY`, `HTTPS_REQUIRED`.

## 6. Tests

```
php server/tests/smartscan_test.php      # 62 tests (SQLite en mémoire, faux Mistral)
flutter test test/smart_scan_quota_test.dart
```

Pour tester l'application contre un serveur de préproduction :
`flutter run --dart-define=SMARTSCAN_URL=https://…/smartscan`
(et côté serveur, `SMARTSCAN_MISTRAL_URL` pour un faux Mistral).
