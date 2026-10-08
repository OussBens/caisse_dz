# Multi-magasin & multi-caisse (licence Avancée)

> État au **08/10/2026** — chantier en cours. Ce document dit ce qui est fait,
> où le travail s'est arrêté et ce qu'il reste à faire.

## 1. Règles fonctionnelles (validées)

| Sujet | Règle |
|---|---|
| Utilisateur | **1 caisse** et une **liste ordonnée de magasins**. Le 1er = **magasin principal** |
| Caisse | N'a **plus** de magasin (colonne `caisseGestion.magasin_code` conservée, ignorée) |
| Admin | Tous les magasins (les siens d'abord, dans leur ordre) |
| Licence Basic | 1 caisse, 1 magasin — même logique avec une liste d'un seul magasin, rien n'est affiché |
| Consultation du stock | Somme des magasins **consultables** (les siens ; tous pour Admin ou rôle « Voir le stock de tous les magasins ») |
| Vente (panier) | Prend dans le magasin 1, puis 2… **1 mouvement par magasin servi** |
| Stock total insuffisant à la vente | Comportement conservé : proposer de vendre le disponible |
| Entrée / Smart Scan | Alimente le **magasin principal** |
| Retour client | Revient dans le(s) magasin(s) **d'où le panier est sorti** (dernier servi d'abord) |
| Retour fournisseur / Sortie | Un magasin qui a **toute** la quantité, sinon réparti dans l'ordre |
| Distribution (Stock) | Répartir un produit entre magasins ; **le total ne change pas** |

## 2. Architecture mise en place

```
utilisateur ──1──▶ caisseGestion            (caisse sans magasin)
            ──N──▶ utilisateur_magasin      (utilisateur, magasin, ordre)  ← DB v52
mouvements : 1 mouvement = 1 produit + 1 magasin + 1 sens
```

| Élément | Fichier | Rôle |
|---|---|---|
| Table `utilisateur_magasin` + migration v52 | `lib/DBCreate.dart` | Reprise : magasin de la caisse de chaque utilisateur → principal (Admin : tous). Mouvements sans magasin rattachés au principal de leur créateur |
| Magasins d'un utilisateur | `lib/Services/UtilisateurMagasin.dart` | `magasinsUtilisateur`, `magasinsConfigures`, `definirMagasins` |
| Règles de répartition (pures) | `lib/Services/RepartitionStock.dart` | `sequentielle`, `unMagasinSinonSequentielle`, `retourVersOrigine`, `distributionValide`, `deltasDistribution` — **16 tests** (`test/repartition_stock_test.dart`) |
| Stock par magasin | `lib/Services/Mouvement.dart` | `quantitesParMagasin`, `totauxParProduitPourMagasins`, `totauxPourFiltre`, `repartirSortie`, `repartirRetourClient` |
| Session | `lib/core/Auth/auth_state.dart` | `magasins`, `magasinPrincipal`, `magasinsConsultation`, `peutConsulterMagasin`, `chargerMagasins()` (à la connexion et à `signalerChangementCaisseMagasin`) |
| Saisie des magasins | `lib/core/widget/champ/champ_magasins_ordonnes.dart` | Champ réutilisable : liste ordonnée, flèches, « Principal », ajout/retrait |

## 3. Avancement

| Étape | Contenu | État |
|---|---|---|
| 1. Fondation | Migration v52, services, `AuthState`, règles + tests | ✅ Fait |
| 2. Fiabilisation | Smart Scan IA sans magasin corrigé ; anciens mouvements rattachés (migration) | ✅ Fait |
| 3. Utilisateurs & caisses | Champ magasins dans Utilisateur (nouveau / modifier, licence Avancée) ; magasin retiré des dialogs Caisse ; Paramètres caisse → magasin principal | ✅ Fait |
| 4. Consultation | Produit et Stock : somme des magasins consultables, filtre limité à ces magasins | ✅ Fait |
| 5. Entrées | Entrée et Smart Scan → magasin principal (éclatement Admin conservé) | ✅ Fait |
| 6. Sorties | Vente (3 dialogs d'encaissement) répartie ; contrôle de stock caisse = somme ; Retour fournisseur & Sortie « un magasin sinon réparti » ; Retour client vers l'origine ; annulations / modifications sur **tous** les mouvements | ✅ Fait |
| 7. Distribution | Dialog réécrit (mouvements seuls, total conservé) + bouton dans Stock ; Transfert magasin limité aux magasins de l'utilisateur | ✅ Fait |
| 8. Vérification | Migration v52 appliquée et vérifiée sur la base réelle (sauvegarde faite avant) ; `flutter analyze` 0 erreur ; 22 tests OK | 🟡 **En cours** |

### 📍 Où le travail s'est arrêté

Étape 8 : la migration v52 a tourné sur la base réelle
(sauvegarde : `%APPDATA%\Caisse DZ\caisse_real_avant_v52_20261008_1501.db`) et
a été vérifiée :

```
ADMIN      MAG0000 > MAG000002
USR000002  MAG0000
USR000003  MAG000002
USR000004  MAG000002
mouvements sans magasin : 0
```

L'application était lancée sur l'écran de connexion pour le **test visuel**,
qui n'a pas encore été fait.

## 4. Reste à faire

### À faire en priorité (fin de l'étape 8)
- [ ] Test visuel : Utilisateur › Modifier (champ « Magasins » ordonné) ; Stock › bouton Distribution (ouvrir, répartir, vérifier le total).
- [ ] Test d'une vente sur 2 magasins (stock insuffisant dans le principal) → 2 mouvements ; annulation → les 2 magasins récupèrent leur quantité.
- [ ] Retour client sur cette vente (partiel puis total) → retour dans les bons magasins.
- [ ] Retour fournisseur et Sortie quand aucun magasin seul n'a la quantité.
- [ ] Licence Basic : aucun champ magasin affiché, tout passe par le magasin unique.
- [ ] Ajouter ces cas à `TESTING_CHECKLIST.md`.

### Points ouverts relevés pendant le chantier
- [ ] **Dashboard / Situations** (inventaire, mouvement produit, marges) : pas encore limités aux magasins consultables.
- [ ] **Rôle « admin » en minuscules** en base alors qu'une vingtaine de tests comparent `role == 'Admin'` (corrigé seulement dans le nouveau code) — à harmoniser (`toLowerCase()`).
- [ ] `CaisseParamServices.synchroniserMagasinDeCaisse` n'est plus appelé (code mort) — à supprimer.
- [ ] `produit_magasin_detail` ne sert plus qu'au second compteur « nombre » — à décider : garder ou basculer sur les mouvements.
- [ ] Modification d'un panier (`pannier_modif`) : ne met pas à jour les mouvements de stock (comportement antérieur, hors chantier).
- [ ] Rapports / exports : afficher le magasin de chaque mouvement quand une ligne est répartie.
