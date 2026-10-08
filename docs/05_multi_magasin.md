# Multi-magasin & multi-caisse (licence Avancée)

> État au **08/10/2026** — code terminé (étapes 1 à 9). Il reste la **recette
> manuelle sur Windows** (TESTING_CHECKLIST.md, section 9). Ce document dit
> ce qui est fait et ce qu'il reste à vérifier.

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
| Dashboard / Situations | Stock (valeur, ruptures, inventaire, mouvement produit) limité aux magasins **consultables** |
| Listes de mouvements | Limitées aux magasins consultables ; chaque ligne affiche **son magasin** (tableau, détail, exports) |
| Ventes / marges | Non filtrées par magasin : une vente appartient à une caisse et peut être servie par plusieurs magasins |
| Rôle Admin | Toujours testé via `AuthState.estAdmin` / `AuthState.estRoleAdmin(role)` (« admin » est en minuscules en base) |

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
| Stock par magasin | `lib/Services/Mouvement.dart` | `quantitesParMagasin`, `totauxParProduitPourMagasins`, `totauxPourFiltre`, `getMouvementsPourMagasins`, `repartirSortie`, `repartirRetourClient` |
| Session | `lib/core/Auth/auth_state.dart` | `magasins`, `magasinPrincipal`, `magasinsConsultation`, `peutConsulterMagasin`, `chargerMagasins()` (à la connexion et à `signalerChangementCaisseMagasin`), `estAdmin` / `estRoleAdmin` |
| Statistiques magasin | `lib/Services/Magasin.dart` | `getStatistiquesMagasin` : produits en stock, valeur, **utilisateurs** du magasin, transferts |
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
| 8. Vérification | Migration v52 appliquée et vérifiée sur la base réelle (sauvegarde faite avant) ; `flutter analyze` 0 erreur ; tests OK | 🟡 Recette manuelle à faire (section 9 de la checklist) |
| 9. Finitions | Dashboard / Situations / listes de mouvements limités aux magasins consultables ; colonne Magasin (Stock › Mouvements, détail, export Excel, Situation Mouvement produit) ; rôle Admin harmonisé ; code mort supprimé ; détail Magasin : card Utilisateurs ; scénarios ajoutés à `TESTING_CHECKLIST.md` (section 9) ; 24 tests OK | ✅ Fait |

### 📍 Où le travail s'est arrêté

Tout le code du chantier est fait. La migration v52 a tourné sur la base
réelle (sauvegarde : `%APPDATA%\Caisse DZ\caisse_real_avant_v52_20261008_1501.db`)
et a été vérifiée :

```
ADMIN      MAG0000 > MAG000002
USR000002  MAG0000
USR000003  MAG000002
USR000004  MAG000002
mouvements sans magasin : 0
```

Prochaine étape : dérouler la **section 9 de `TESTING_CHECKLIST.md`** sur un
poste Windows (l'environnement cloud ne lance pas l'application).

## 4. Reste à faire

### Recette manuelle (Windows) — `TESTING_CHECKLIST.md`, section 9
- [ ] Utilisateur › Modifier : champ « Magasins » ordonné (9.1).
- [ ] Consultation : somme des magasins, permission « tous les magasins » (9.2, 9.3).
- [ ] Vente sur 2 magasins, annulation, retours client partiel puis total (9.4 → 9.6).
- [ ] Sortie et retour fournisseur quand aucun magasin seul n'a la quantité (9.7, 9.8).
- [ ] Distribution, Entrée / Smart Scan (9.9, 9.10).
- [ ] Dashboard / Situations, détail Magasin, colonne Magasin et exports (9.11 → 9.13).
- [ ] Compte `admin` (9.14) et licence Basic (9.15).

### Points tranchés
- [x] **Dashboard / Situations** : valeur du stock, ruptures, Inventaire et Mouvement produit limités aux magasins consultables. Les marges / recettes restent par caisse (une vente peut être servie par plusieurs magasins).
- [x] **Rôle « admin » en minuscules** : `AuthState.estRoleAdmin` / `estAdmin` partout (permissions `can…`, Alertes, Transfert, Entrée, Smart Scan, Caisse, AppShell, Utilisateur, export Excel). Test : `test/auth_role_admin_test.dart`.
- [x] Code mort supprimé : `CaisseParamServices.synchroniserMagasinDeCaisse` et `MagasinServices.getMagasinCodeUtilisateur` (magasin lu sur la caisse). Le détail Magasin compte désormais les **utilisateurs** du magasin au lieu des caisses.
- [x] Rapports / exports : colonne **Magasin** dans Stock › Mouvements (tableau, détail, Excel — ajoutée en dernière colonne pour ne pas décaler les autres) et dans Situation › Mouvement produit (tableau + export).
- [x] Modification d'un panier (`pannier_modif`) : sans objet — le contenu d'un panier encaissé est verrouillé (conformité fiscale, `PannierServices.updatePannier`) ; l'annulation, elle, passe par les mouvements de tous les magasins servis.
- [x] `produit_magasin_detail` : **conservé** pour le second compteur « nombre » (encore utilisé par une quinzaine de dialogs). Le stock en quantité vient exclusivement du journal `mouvements`. Basculer « nombre » sur les mouvements (`totauxParProduit` calcule déjà `nombres`) reste une évolution possible, hors chantier.
