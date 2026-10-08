# CaisseDZ — Checklist de test

**Légende Statut :** ⬜ À tester · ✅ Réussi · ❌ Échoué · ⚠️ Partiel / à vérifier · ➖ Obsolète

**Comment on travaille :** vous testez un scénario, vous remplacez ⬜ par ✅/❌/⚠️ dans la colonne Statut et notez ce que vous observez dans Notes (surtout si ❌ ou ⚠️ — capture d'écran, message d'erreur exact, étape précise). Je reviens régulièrement lire ce fichier, j'investigue/corrige les ❌, et on avance section par section. Pas besoin de tout finir avant de me montrer le fichier — dites-moi simplement où vous en êtes.

---

## Section 0 — Régression du travail récent (à faire en premier)

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 0.1 | Se connecter avec un rôle ayant beaucoup de permissions (ex. Admin) | Le menu du logo s'ouvre automatiquement une fois, avec **tous** les modules autorisés pour ce rôle (pas seulement magasin) | ✅ | Testé en conditions réelles (login admin/123456 automatisé + capture d'écran) : menu affiche Tableau de Bord, Caisse, Panier, Retour, Produit, Stock, Entrée, Sortie, Magasin, Besoin, Client, Fournisseur (+ suite probable hors cadre visible) |
| 0.2 | Se connecter avec un rôle à permissions limitées (ex. Caissier) | Le menu du logo montre uniquement les modules cochés pour ce rôle + magasin si licence avancée | ⬜ | Nécessite le mot de passe réel du compte "oussama" (rôle Caissier) — à tester par vous |
| 0.3 | Se déconnecter puis se reconnecter (même session d'app) | Le menu du logo se réaffiche à ce 2ème login aussi (plus une seule fois par lancement) | ⬜ | |
| 0.4 | Cliquer successivement sur 5-6 modules différents dans la sidebar | Transition fluide (fondu + léger glissement), pas de flash blanc, sidebar ne se replie pas toute seule | ✅ | Testé Caisse → Produit : sidebar reste affichée sans clignotement, item actif bien mis en surbrillance sur le nouveau module, contenu remplacé proprement |
| 0.5 | Épingler/replier la sidebar puis changer de module plusieurs fois | L'état plié/déplié reste stable, pas de retour à l'état par défaut | ⬜ | |
| 0.6 | Ouvrir chaque dialog d'insertion (produit, client, fournisseur, categorie, pack, pannier, session, smartscan, remise, souscategorie, codebar, caisse) | Une ligne fine apparaît sous le titre+icône, sur toute la largeur (y compris sous le bouton fermer "X") | ⬜ | |
| 0.7 | Créer un nouveau produit complet (nom, prix, code-barre, catégorie...) | Sauvegarde réussie, pas d'erreur SQL, le produit apparaît dans la liste | ✅ | Testé en réel (créé puis supprimé un produit de test) : sauvegarde OK, aucune erreur SQL, apparaît bien dans la liste et le détail. Confirme le bug SQL corrigé en tout début de session. Voir aussi 2 nouveaux bugs notés dans le journal (champs prix avec texte fantôme, message d'erreur incohérent en mode Détaillé) |
| 0.8 | Dans nouveau/modif produit, regarder les boutons "Changer la photo" / "Supprimer" | Icônes de taille réduite, cohérentes avec le reste du dialog | ⚠️ | Vérifié seulement l'état "Ajouter une photo" (aucune photo) : icône compacte, cohérente avec le correctif. Pas testé l'état à deux boutons (Changer/Supprimer) faute de fichier image à joindre — à vérifier par vous en ajoutant une vraie photo |
| 0.9 | Ouvrir "Nouveau rôle" et "Modifier rôle" | Le dialog est plus haut qu'avant, aucun overflow/texte coupé même sur petit écran | ✅ | Testé en réel (créé un rôle test, annulé sans sauvegarder) : dialog nettement plus haut, étapes "Informations", "Permissions" (grille de modules) et "Permission spéciale" toutes bien affichées sans overflow, boutons de pied de page toujours visibles. Pas testé "Modifier rôle" spécifiquement mais utilise le même `BaseDialog` |
| 0.10 | Ouvrir l'écran de login | Le logo glisse de la gauche vers le centre, puis le texte "Connexion à votre compte" apparaît en fondu en montant du bas, juste après | ✅ | Vérifié par capture d'écran — mise en page correcte (logo centré, titre en dessous), rendu final conforme |
| 0.11 | Lancer l'application (raccourci/exe) | L'application démarre directement en plein écran (maximisée) | ✅ | Bug trouvé puis corrigé — voir journal ci-dessous |

---

## Section 1 — CRUD par module

Pour chaque module : Créer, Modifier, Voir détail/Annuler, Rechercher/Filtrer. Cochez au fur et à mesure — si un module n'a pas telle action (ex. pas de suppression), notez N/A.

| # | Module | Créer | Modifier | Détail / Annuler | Recherche / Filtre | Notes |
|---|---|---|---|---|---|---|
| 1.1 | Dashboard | N/A | N/A | ⬜ (widgets à jour) | N/A | |
| 1.2 | Caisse | N/A | N/A | ⬜ vente, encaissement | ⬜ recherche produit | |
| 1.3 | Client | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.4 | Fournisseur | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.5 | Magasin (licence avancée) | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.6 | Pannier | ⬜ | ⬜ | ⬜ versement/reste | ⬜ | |
| 1.7 | Produit | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.8 | Catégorie / Sous-catégorie | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.9 | Remise | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.10 | Pack | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.11 | Stock | N/A | N/A | ⬜ cohérence quantités | ⬜ | |
| 1.12 | Entrée / SmartScan | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.13 | Sortie | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.14 | Retour | ⬜ | ⬜ | ⬜ annulation | ⬜ | |
| 1.15 | Besoin | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.16 | Utilisateur | ⬜ | ⬜ | ⬜ activer/désactiver | ⬜ | |
| 1.17 | Rôle | ⬜ | ⬜ | ⬜ | ⬜ | |
| 1.18 | Gestion Caisse | ⬜ | ⬜ | ⬜ transfert entre caisses | ⬜ | |
| 1.19 | Zakat | ⬜ | ⬜ | ⬜ calcul | ⬜ | |
| 1.20 | Paramètres | N/A | ⬜ | N/A | N/A | |
| 1.21 | Historique | N/A | N/A | ⬜ traçabilité des actions | ⬜ | |
| 1.22 | Transfert Magasin | ⬜ | ⬜ | ⬜ | ⬜ | |

---

## Section 2 — Flux métier transverses (priorité haute)

| # | Scénario | Étapes | Résultat attendu | Statut | Notes |
|---|---|---|---|---|---|
| 2.1 | Cycle stock complet | Entrée fournisseur d'un produit → vendre en Caisse → faire un Retour client → Transfert vers un autre magasin | Stock correct à chaque étape (Stock screen + fiche produit cohérents) | ⬜ | |
| 2.2 | Versement client | Créer un Pannier, faire 2-3 versements partiels | "Versé"/"Reste" recalculés correctement à chaque versement | ⬜ | |
| 2.3 | Versement fournisseur | Créer une Sortie fournisseur, verser en plusieurs fois | Idem côté fournisseur | ⬜ | |
| 2.4 | Retour client → Versement | Faire un retour sur une vente déjà versée | Montant = prixVente × quantité, versement/mouvement mis à jour, pas modifiable directement après | ⬜ | |
| 2.5 | Retour fournisseur | Faire un retour sur un achat fournisseur | Montant = prixAchat × quantité | ⬜ | |
| 2.6 | Annulation d'opération | Annuler une vente/entrée déjà validée (si permission) | Stock/versement recalculés comme si l'opération n'avait pas eu lieu | ⬜ | |
| 2.7 | SmartScan (ex-Entrée fusionnée) | Tester le mode "1 produit" et le mode "plusieurs produits" | Les deux modes fonctionnent, montant/quantité corrects | ⬜ | |
| 2.8 | Transfert entre caisses | Depuis Gestion Caisse, transférer un montant entre 2 caisses | Solde des deux caisses mis à jour, uniquement si permission `gererTransfertsCaisse` | ⬜ | |
| 2.9 | Seuil de stock minimum | Faire descendre un produit sous son seuil | Alerte/indicateur visible dans Produit et/ou Besoin | ⬜ | |
| 2.10 | Impression / export | Imprimer un ticket de caisse, exporter un rapport | Documents générés sans erreur | ⬜ | |

---

## Section 3 — Permissions & licence

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 3.1 | Créer un rôle avec 0 module coché | Sidebar quasi vide (dashboard seul si autorisé), menu du logo cohérent | ⬜ | |
| 3.2 | Créer un rôle avec 1 seul module coché | Seul ce module (+ dash si autorisé) apparaît dans sidebar et menu logo | ⬜ | |
| 3.3 | Licence "basic" + tenter d'accéder à `/magasin` par URL/navigation directe | Redirection automatique vers `/caisse` | ⬜ | |
| 3.4 | Licence "avancée" | Module Magasin visible et accessible pour tout utilisateur (indépendant des permissions du rôle) | ⬜ | |
| 3.5 | Permission spéciale `voirPrixAchat` décochée sur un rôle | Le prix d'achat n'est visible nulle part pour ce rôle | ⬜ | |
| 3.6 | Permission spéciale `voirMarge` décochée | Marge non affichée | ⬜ | |
| 3.7 | Permission spéciale `modifierPrixVente` décochée | Impossible de modifier le prix de vente | ⬜ | |
| 3.8 | Permission spéciale `annulerOperations` décochée | Boutons d'annulation masqués/désactivés | ⬜ | |
| 3.9 | Permission spéciale `changerCaisseMagasin` décochée | Impossible de changer de caisse/magasin assigné | ⬜ | |
| 3.10 | Permission spéciale `voirStockTousMagasins` décochée | Stock visible uniquement pour le magasin assigné | ⬜ | |
| 3.11 | Utilisateur Admin | A implicitement toutes les permissions, même si une case spéciale n'est pas cochée dans son RoleDetail | ⬜ | |

---

## Section 4 — Localisation (fr / ar / en)

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 4.1 | Basculer en Arabe (RTL) sur Produit, Caisse, Gestion Caisse | Mise en page inversée correctement, sidebar du bon côté, pas de texte qui déborde | ⬜ | |
| 4.2 | Basculer en Anglais | Tous les textes traduits, aucune clé brute affichée | ⬜ | |
| 4.3 | Revenir en Français | Retour normal, aucune régression | ⬜ | |
| 4.4 | Login/Activation dans les 3 langues | Formulaires et messages d'erreur traduits | ⬜ | |

---

## Section 5 — Migration base de données

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 5.1 | Nouvelle installation (base fraîche) | Création sans erreur, données par défaut (rôle ADMIN, etc.) présentes | ⬜ | |
| 5.2 | Restaurer une ancienne sauvegarde (si disponible) et relancer l'app | Toutes les migrations jusqu'à la version actuelle s'appliquent sans erreur, données existantes intactes | ⬜ | |
| 5.3 | Sauvegarde automatique/manuelle | Fichier de sauvegarde généré et restaurable | ⬜ | |

---

## Section 6 — Multi-magasin & transfert entre magasins (licence Avancée)

Prérequis : licence Avancée, au moins 2 magasins actifs, un produit avec du stock dans le magasin A.

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 6.1 | Magasin › onglet Magasins : créer un 2ᵉ magasin, le modifier, le désactiver | CRUD OK ; le magasin système ne peut être ni modifié ni supprimé | ⬜ | |
| 6.2 | Gestion Caisse : rattacher une caisse au magasin B | La caisse affiche le bon magasin ; les ventes de cette caisse sortent le stock du magasin B | ➖ | Obsolète (DB v52) : une caisse n'a plus de magasin — voir 9.1 / 9.4 |
| 6.3 | Magasin › onglet « Transfert entre magasins » : transférer 5 unités du produit de A vers B | Stock A −5, stock B +5 (Stock et Produit avec filtre Magasin = A puis B) ; le total « Tous les magasins » ne change pas | ⬜ | |
| 6.4 | Annuler ce transfert | Stocks A et B reviennent à leur valeur d'avant | ⬜ | |
| 6.5 | Filtre Transfert : Produit / Source / Destination / Du-Au / Période rapide | La liste se filtre correctement ; « Supprimer filtre » remet tout | ⬜ | |
| 6.6 | Extract (vert) puis Extract filtre (orange, avec 1-2 lignes cochées) | Aperçu Excel : tout le filtré, puis uniquement les lignes cochées ; sans sélection → message « aucun transfert sélectionné » | ⬜ | |
| 6.7 | Cards Magasin | Nombre de transferts et quantité transférée n'incluent pas les transferts annulés | ⬜ | |
| 6.8 | Rôle sans `voirStockTousMagasins` | Filtre Magasin grisé dans Produit/Stock, stock limité au magasin de l'utilisateur | ⬜ | |
| 6.9 | Licence Basic | Module Magasin absent de la sidebar, `/magasin` redirige vers `/caisse` | ⬜ | Doublon volontaire de 3.3 |

---

## Section 7 — Travail récent (octobre 2026 : filtres, exports, cards, retrait mobile)

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 7.1 | Ouvrir le filtre de chaque module (Produit, Stock, Entrée, Sortie, Panier, Retour, Besoin, Client, Fournisseur, Versements, Gestion Caisse, Magasin, Historique, Zakat) | Champ « Rechercher » partout de même largeur (1/3 de la ligne) ; ligne Du / Au / Période rapide alignée sur les colonnes du dessus | ⬜ | |
| 7.2 | Onglets Situation (Dashboard) + Situation client/fournisseur | Période rapide identique aux autres modules (libellé + liste) | ⬜ | |
| 7.3 | Gestion Caisse › Transfert Caisse : Extract et Extract filtre | Aperçu Excel des transferts (avant : boutons sans effet) | ⬜ | |
| 7.4 | Gestion Caisse › Mouvements : filtres Type/Client/Fournisseur, Du/Au/Période, Rechercher/Montant + Extract / Extract filtre | Filtrage correct, export de la liste ou des lignes cochées, choix de session toujours fonctionnel | ⬜ | |
| 7.5 | Cards Entrée/Sortie/Retour/Stock | Plus aucun chiffre fixe : comparer chaque card au nombre réel d'éléments actifs | ⬜ | |
| 7.6 | Cards Besoin (3 onglets) | Produits / Besoin list / Rupture / Expirés = vrais comptes (actifs) | ⬜ | |
| 7.7 | Cards Historique | Créations / Modifications / Suppressions ≠ 0 ; dernier utilisateur = nom | ⬜ | |
| 7.8 | Cards Zakat | Nissab et Taux = valeurs de Paramètres › Zakat (les modifier puis revenir) ; « Payée » compte bien les zakats payées | ⬜ | |
| 7.9 | Cards Utilisateur / Panier / Versement fournisseur / Remise | Inactifs ≠ 0 si utilisateur désactivé ; produit star affiché par nom ; total versé fournisseur = versements Sortie ; remise en % affiche « % » | ⬜ | |
| 7.10 | Catalogue produit (nouveau produit IA par code-barres) | Recherche dans le catalogue `catalog-api.bensds.com` OK ; un nouveau produit est bien poussé au catalogue | ⬜ | |
| 7.11 | Retrait du module mobile | Plus de bouton d'appairage (en-têtes, login) ni « Recevoir depuis le téléphone » ; Entrée › IA › « Joindre depuis le disque » fonctionne toujours | ⬜ | |

---

## Section 8 — Demandes du 06/10 (à vérifier par vous)

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 8.1 | Caisse : scanner/choisir un produit puis ne rien toucher | La fiche « Ajouter produit » ajoute le produit et se ferme seule après 3 s (si stock suffisant) | ⬜ | Avant : produit ajouté mais fiche jamais fermée |
| 8.2 | Fiche produit ouverte : cliquer « Ajouter », puis refaire en appuyant sur Entrée | Ajout + fermeture | ⬜ | |
| 8.3 | Fiche produit ouverte : scanner un autre produit | Le 1er est ajouté (quantité saisie, pas le code-barres), la fiche se ferme, celle du 2ᵉ s'ouvre | ⬜ | |
| 8.4 | Tableau panier de la caisse | Colonne Code plus large, colonne case à cocher plus étroite | ⬜ | |
| 8.5 | Produit et Stock à l'ouverture | Quantités du magasin associé à l'utilisateur ; « Tous les magasins » reste choisissable si permission | ⬜ | |
| 8.6 | Paramètres caisse : changer de caisse (autre magasin) puis Sauvegarder | Paramètres › Utilisateur affiche le nouveau magasin | ➖ | Obsolète (DB v52) : le magasin vient de l'utilisateur (Utilisateur › Magasins), plus de la caisse — voir 9.1 |
| 8.7 | Gestion Caisse › Modifier une caisse : changer son magasin | Paramètres caisse + utilisateur des comptes de cette caisse suivent le nouveau magasin | ➖ | Obsolète (DB v52) : le magasin a été retiré des dialogs Caisse |
| 8.8 | Caisse › Recette produit (P) | Uniquement les ventes du jour, colonne État ; totaux = ventes actives | ⬜ | |
| 8.9 | Caisse › Recette caisse (R) | Colonne/badge État sur chaque panier ; totaux = paniers actifs | ⬜ | |
| 8.10 | Gestion Caisse : les 5 onglets | Les cards globales apparaissent en haut de chaque onglet | ⬜ | |
| 8.11 | Gestion Caisse › Mouvements › Nouveau | Ouvre le dialog Mouvement manuel (session choisie ou unique session ouverte), tableau rafraîchi après ajout | ⬜ | |
| 8.12 | Gestion Caisse : trier par date (et montant) chaque tableau | Ordre chronologique/numérique correct (avant : trié par jour puis mois) ; « Annulé le » des transferts = vraie date d'annulation | ⬜ | |
| 8.13 | Gestion Caisse › Sessions | Colonne date de clôture (« Au ») visible par défaut | ⬜ | |
| 8.14 | Gestion Caisse : onglets | Icône différente pour Caisse / Transfert / Clôtures / Mouvements / Sessions | ⬜ | |
| 8.15 | Déclencher un message de succès, une information/confirmation et une erreur | Grande icône à gauche du texte : ✓ verte / ! orange / ✕ rouge | ⬜ | |
| 8.16 | Liste verrouillée (ex. Source dans Nouveau transfert magasin) | Texte de la valeur en gris, lisible | ⬜ | Avant : blanc sur fond clair |
| 8.17 | Produit / Stock connecté avec un compte non-admin (ex. moh, caisse « Caisse 2 ») | Quantités = stock du magasin de SA caisse (magasin 2), filtre Magasin verrouillé ; en admin : « Tous les magasins » par défaut | ➖ | Remplacé par 9.2 (DB v52 : somme des magasins de l'utilisateur, plus le magasin de sa caisse) |
| 8.18 | Panier : sélectionner un panier déjà annulé puis Annuler | Message « Panier(s) déjà annulé(s) : … » ; si mélangé, seuls les actifs sont annulés | ⬜ | |
| 8.19 | Client / Fournisseur › Situation | Dialog plus haut (≈ 90 % de la fenêtre) | ⬜ | |
| 8.20 | Client › Versements : supprimer un versement « Sortie » (remboursement de retour) ; Fournisseur : un versement « Entrée » | Refusé avec message « lié au retour… » (à faire via le retour) | ⬜ | |
| 8.21 | Magasin › Transferts : annuler un transfert déjà annulé | Message « Transfert(s) déjà annulé(s) : … » | ⬜ | |
| 8.22 | Magasin › Transferts › Modifier (crayon) | Même dialog que Nouveau, pré-rempli ; changer quantité/destination → stocks des magasins recalculés ; transfert annulé → refusé | ⬜ | |
| 8.24 | Retour : cocher une ou plusieurs lignes | La case reste cochée (avant : se décochait aussitôt) | ⬜ | |
| 8.25 | Dashboard › chaque Situation : cocher des lignes puis Extract filtre (orange) | Excel des seules lignes cochées ; aucune cochée → « Aucune ligne sélectionnée » | ⬜ | Mouvement produit a aussi gagné Extract / Extract PDF |
| 8.26 | Dashboard › Situation › Coût produit | Par produit : prix achat min/max/moyen, qtt achetée, prix vente min/max/moyen, qtt vendue ; filtres Du/Au/Période, Produit, Rechercher ; exports | ⬜ | |
| 8.27 | Trier par date (et montant) dans TOUS les tableaux (Gestion caisse, Panier, Retour, Sortie…) | Ordre chronologique réel (avant : trié par jour comme du texte) | ⬜ | |
| 8.28 | Gestion Caisse › Mouvements › Filtre | Le champ Session est dans le panneau de filtres (ligne 3) ; « Voir les mouvements » depuis Sessions ouvre le filtre avec la session | ⬜ | |
| 8.29 | Caisse › bouton paramètres | Dialog « Paramètres de vente » avec seulement la liste Colis | ⬜ | |
| 8.30 | Produit à l'unité « Pièce » : saisir une quantité (caisse, panier, entrée, sortie, SmartScan, retour, besoin, transfert, emballage produit) | Pas de décimale possible ; « Nombre » toujours entier ; autres unités = réglage système | ⬜ | |
| 8.31 | Ouvrir deux fois la même caisse (double clic rapide) | Une seule session ouverte | ⬜ | Garanti aussi en base (migration v50) |
| 8.32 | Produit sans remise | Plus d'indication « remise » sur la card (anciens remise_id = 0 remis à vide par la migration v50) | ⬜ | |
| 8.33 | Caisse : ajouter 1 boîte de 6 (fiche « Ajouter produit », emballage Boîte) puis encaisser | Qté 1, Qte Pce 6 ; le stock baisse de 6 | ⬜ | Avant : Qte Pce 1 et stock −1 |
| 8.34 | Admin › Mon compte › Caisse (bouton) : choisir une caisse d'un autre magasin, enregistrer | Le module affiché se recharge (Produit/Stock : quantités du nouveau magasin) | ⬜ | |
| 8.35 | Cliquer l'étoile dans l'en-tête de 7 modules | Onglets favoris en haut ; clic = ouvre le module ; croix = retire ; 8ᵉ → message « 7 favoris maximum » ; favoris conservés après déconnexion/reconnexion | ⬜ | Migration v51 |
| 8.35b | Cliquer la croix d'un onglet favori (FR, EN, AR) | Dialog de confirmation orange « Retirer « Module » des favoris ? » ; Annuler → l'onglet reste ; Confirmer → l'onglet disparaît et l'étoile du module se vide | ⬜ | |
| 8.36 | Ouvrir le détail d'un enregistrement dans chaque module (client, fournisseur, produit, stock, pannier, zakat…) | Chiffres en haut sous forme de cards style afficheur global (carte blanche, icône colorée, titre, grande valeur, trait dégradé) ; montants longs réduits, pas coupés | ⬜ | Widget partagé StatsCard |
| 8.37 | Magasin › détail d'un magasin | 4 cards : Nb produits en stock, Valeur stock (qté × prix d'achat), Total caisses actives, Transferts actifs (entrants + sortants) — mêmes quantités que Produit/Stock filtré sur ce magasin | ➖ | 3ᵉ card remplacée (DB v52) : « Utilisateurs » ayant ce magasin, au lieu de « Total caisses » — voir 9.12 |
| 8.38 | Gestion caisse › Clôtures › détail | Même présentation que les autres détails : icône, code + caisse, puce période, 4 cards (total ventes, nb ventes, total annulé, nb annulés) ; largeur 1100 comme tous les dialogs détail | ⬜ | |
| 8.39 | Se connecter (avec au moins 1 produit en rupture ou 1 client en crédit) | Dialog « Alertes » s'ouvre AVANT le menu rapide, puis le menu, puis l'ouverture de caisse si fermée ; aucune alerte → le dialog ne s'ouvre pas | ⬜ | |
| 8.40 | Dialog Alertes : contenu | Cards en haut (rupture, expirés, expirant ≤ 30 j, sessions non clôturées) ; sections : rupture, expirés, expirant bientôt, top 3 clients crédit, top 3 fournisseurs crédit, sessions ouvertes un jour précédent ; max 8 lignes + « + N autres » ; « Ouvrir le module » ferme et navigue | ⬜ | Mêmes règles que Besoin (seuil minimum Paramètres) et que les cards Client/Fournisseur |
| 8.41 | Cloche dans l'en-tête (à gauche de l'étoile favoris) | Badge rouge = nombre d'alertes ; clic ouvre le dialog ; utilisateur sans accès Client/Fournisseur/Gestion caisse/Produit → sections correspondantes masquées | ⬜ | |
| 8.42 | Lancer l'app (login) | Plus de barre de titre séparée ; boutons réduire / agrandir / fermer en haut à droite ; glisser le haut de l'écran déplace la fenêtre | ⬜ | |
| 8.43 | Après connexion (tous modules, FR et AR) | Logo + « Caisse DZ » en haut de la sidebar (glisser = déplacer la fenêtre, clic logo = menu rapide) ; ligne du haut : onglets favoris + boutons fenêtre à droite (même en arabe) ; double-clic sur la zone vide = agrandir/restaurer ; déconnexion → boutons du login réapparaissent | ⬜ | |
| 8.44 | Produit › onglet Produit : bouton grille (à droite d'Extraire filtre) | Bascule tableau ⇄ cards ; filtres appliqués aux cards ; clic card = sélection (afficheur produit en haut si 1), « Tout sélectionner » ; boutons Détail/Supprimer/Modifier/Catégorie/Remise/Pack et Extraire filtre agissent sur la sélection ; double-clic card = détail ; bascule = sélection vidée | ⬜ | Réutilise CardProduct (recherche caisse) |
| 8.45 | Déploiement serveur Smart Scan (voir server/README_SMARTSCAN.md) puis admin → « Installer les tables » | Tables ss_* créées ; forfaits STANDARD (60) et SMART_SCAN_200 (200, 3 000 DA) visibles dans Forfaits | ⬜ | |
| 8.46 | Entrée › onglet IA | Carte « Smart Scan : x / 60, n restants, Renouvellement : 01/MM/AAAA » à côté de « Joindre une photo » | ⬜ | Testé en local 08/10 |
| 8.47 | Scanner un bon | Lignes extraites ; carte passe à 1 / 60 ; admin › client : 1 scan réussi au journal | ⬜ | Testé en local 08/10 |
| 8.48 | Couper internet puis scanner | Message « connexion impossible » ; compteur inchangé | ⬜ | |
| 8.49 | Quota atteint (admin › quota exceptionnel = scans déjà faits) puis scanner | Dialog « Quota Smart Scan atteint » + offre (nom, quota, prix depuis l'API) ; « Demander l'offre » → confirmation + contact ; demande visible dans admin › Demandes | ⬜ | Testé en local 08/10 |
| 8.50 | Admin › activer Smart Scan 200 pour ce client | Carte : « Smart Scan 200 : x / 200 … Offre active jusqu'au : JJ/MM/AAAA+1 » | ⬜ | Testé en local 08/10 |
| 8.51 | 2 postes du même client : rattacher le 2e au client du 1er (admin › Postes) | Scans des 2 postes cumulés sur le même compteur | ⬜ | Couvert par tests serveur |
| 8.23 | Bouton rouge « Extract PDF » : Panier, Retour, Produit (5 onglets), Stock (2), Entrée, Sortie (2), Transfert magasin, Besoin (3), Client (+versements), Fournisseur (+versements), Gestion Caisse (transferts, mouvements), Historique, Zakat, Utilisateur | Aperçu PDF avec les mêmes colonnes que l'Excel, imprimable / enregistrable | ⬜ | |

---

## Section 9 — Multi-magasin v52 : magasins par utilisateur (licence Avancée)

Prérequis : licence Avancée, 2 magasins actifs A et B, un utilisateur non-admin U
avec Magasins = A (principal) puis B, un produit P avec 3 en stock dans A et
10 dans B. Règles : [docs/05_multi_magasin.md](docs/05_multi_magasin.md).

| # | Scénario | Résultat attendu | Statut | Notes |
|---|---|---|---|---|
| 9.1 | Utilisateur › Modifier U : champ « Magasins » (flèches, Principal, ajout / retrait), enregistrer, rouvrir | Ordre conservé, le 1er porte « Principal » ; U reconnecté : Entrée alimente A | ⬜ | |
| 9.2 | Produit / Stock connecté en U | Quantité de P = 13 (A + B) ; filtre Magasin limité à A et B ; en Admin : tous les magasins | ⬜ | |
| 9.3 | Rôle de U avec « Voir le stock de tous les magasins » | Filtre Magasin : tous les magasins ; quantité = somme de tous les magasins | ⬜ | |
| 9.4 | Caisse (U) : vendre 5 P | Encaissement accepté ; Stock › Mouvements : 2 lignes Vente (A : 3, B : 2), colonne Magasin renseignée | ⬜ | |
| 9.5 | Annuler cette vente (Panier) | A et B récupèrent chacun leur quantité (3 et 2) | ⬜ | |
| 9.6 | Refaire la vente de 5, puis Retour client de 1, puis de 4 | Le 1er retour revient dans B (dernier servi), le 2ᵉ : 1 dans B puis 3 dans A | ⬜ | |
| 9.7 | Sortie de 4 P alors que A = 3 et B = 10 | 1 seul mouvement, sur B (seul magasin qui a toute la quantité) | ⬜ | |
| 9.8 | Retour fournisseur de 12 P alors que A = 3 et B = 10 | Réparti : 3 sur A puis 9 sur B | ⬜ | |
| 9.9 | Stock › bouton Distribution sur P | Total inchangé ; un total différent est refusé ; mouvements Distribution Entrée / Sortie créés | ⬜ | |
| 9.10 | Entrée et Smart Scan en U | Le stock entre dans A (magasin principal) | ⬜ | |
| 9.11 | Dashboard (KPI valeur du stock, ruptures) puis Situation › Inventaire et Mouvement produit, connecté en U | Mêmes quantités que Produit / Stock (A + B seulement) ; colonne Magasin dans Mouvement produit et dans son export | ⬜ | |
| 9.12 | Magasin › détail de A | Cards : produits en stock, valeur, Utilisateurs (comptes actifs ayant A dans leurs magasins), transferts | ⬜ | |
| 9.13 | Stock › Mouvements : double-clic sur un mouvement, puis Extract | Le détail affiche le Magasin ; l'Excel a une colonne Magasin (dernière colonne) | ⬜ | |
| 9.14 | Connexion avec le compte `admin` (rôle « admin » en minuscules en base) | Admin reconnu partout : prix d'achat / marges visibles, choix de magasin dans Transfert, éclatement Entrée, caisse non imposée, alertes complètes | ⬜ | |
| 9.15 | Licence Basic | Aucun champ Magasins dans Utilisateur ; colonne Magasin = magasin unique ; tout passe par ce magasin | ⬜ | |

---

## Journal des bugs trouvés

| Date | # Scénario | Description | Statut correction |
|---|---|---|---|
| 2026-09-28 | 0.1 | Menu du logo après login montrait toujours uniquement "Magasin" au lieu de tous les modules autorisés — cause : `notifyListeners()` déclenché par `loadUserParameters()` avant que `roleDetail` soit chargé | ✅ Corrigé |
| 2026-09-28 | 0.11 | L'app ne démarrait pas réellement en plein écran malgré le premier correctif (`ShowWindow(SW_SHOWMAXIMIZED)` seul ne suffisait pas sur une fenêtre jamais affichée — restait à sa taille de création 1280×720). Confirmé par capture d'écran : fenêtre non maximisée. Corrigé en forçant l'état via `SetWindowPlacement` avant `ShowWindow`, revérifié par une 2e capture d'écran montrant la fenêtre remplissant l'écran | ✅ Corrigé |
| 2026-09-28 | 0.7 | ~~Nouveau Produit : champs Prix Achat/Vente/TVA semblaient pré-remplis ("150 DA" etc.)~~ — **Correction après vérification du code** : ce n'est pas un bug, `TextChampL` distingue bien le hint (gris, bordure fine grise) de la vraie valeur (noir, bordure violette épaisse). Simple texte d'exemple standard, pas de defect | N/A — pas un bug |
| 2026-09-28 | 0.7 | Nouveau/Modifier Produit, onglet "Détaillé" → "Prix & Taxes" : après avoir saisi Prix Achat=150 (marge Auto 5%), le Prix Vente auto-calculé affichait "160.00" mais le champ montrait quand même "Prix de vente inférieur au prix d'achat" (160 > 150, message contradictoire). **Cause trouvée** : dans `produit_nouveau.dart` et `produit_modif.dart`, le `onChanged` du champ Prix Achat appelait `produitFormKey.currentState!.validate()` **avant** `calculPrixVenteAuto()` — la validation s'exécutait donc sur l'ancien prix de vente (pas encore recalculé), affichant une erreur déjà obsolète au moment où elle s'affichait. Corrigé en inversant l'ordre (recalcul puis validation) aux 2 endroits de chaque fichier (Prix Achat et Prix Vente) | ✅ Corrigé |
| 2026-09-29 | — | Caisse → "Ouvrir Caisse" (via le dialog "Session fermée") : crash "Looking up a deactivated widget's ancestor is unsafe". **Cause** : `caisse_fermee_dialog.dart` fermait son propre dialog (`Navigator.pop(context)`) puis réutilisait ce même `context` (celui du `StatefulBuilder` de CE dialog, pas celui de l'appelant) pour ouvrir `OuvertureCaisseDialog` — invalide dès que l'appel DB donnait le temps à la fermeture de se terminer. Corrigé en capturant le `context` de l'appelant (`callerContext`) avant les builders imbriqués | ✅ Corrigé |
| 2026-09-29 | — | Caisse → "Clôturer Caisse" : signalé par l'utilisateur, crash identique ("Null check operator used on a null value" dans `Navigator.pop` au clic sur "Fermer" du message de succès) + app figée. **Cause** : même anti-pattern, cette fois auto-infligé — `cloture_caisse_session.dart` et `mouvement_manuel.dart` faisaient `if (context.mounted) Navigator.pop(context);` (ferme LEUR PROPRE dialog) puis appelaient `InformationDialog(context: context, ...)` **sans re-vérifier `context.mounted`** avec ce même contexte maintenant désactivé. Audit complet du pattern `Navigator.pop(context)` + dialog suivant sur tout `lib/core/dialog/` — seuls ces 2 fichiers + le cas ci-dessus étaient concernés (les occurrences dans `lib/screens/*.dart` utilisent le contexte stable de l'écran, pas un contexte de dialog imbriqué — motif sûr, non modifié). Corrigé aux 2 endroits (`if (!context.mounted) return;` avant le pop) | ✅ Corrigé |
| 2026-09-29 | — | `champ_avec_label.dart` : le `Text` du libellé n'était pas dans un `Expanded`/`Flexible`, donc un libellé plus long que la colonne fixe de 140px (ex. "Solde d'ouverture (DA)") provoquait un RenderFlex overflow (trouvé dans le même rapport de bug que ci-dessus) | ✅ Corrigé |
