// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get dashboard => 'Tableau de Bord';

  @override
  String get salesToday => 'Vente Aujourd\'hui';

  @override
  String get purchaseToday => 'Achat Aujourd\'hui';

  @override
  String get netToday => 'Net Aujourd\'hui';

  @override
  String get supplierDebt => 'Créance Fournisseur';

  @override
  String get clientCredit => 'Crédit Client';

  @override
  String get selectPeriod => 'Sélectionnez une période';

  @override
  String get salesByHour => 'Ventes par heure';

  @override
  String get salesByDay => 'Ventes par jour';

  @override
  String get salesByWeek => 'Ventes par semaine';

  @override
  String get revenueByCashier => 'CA par Caissier';

  @override
  String get salesByProduct => 'Ventes par Produit';

  @override
  String get salesByPaymentMethod => 'Ventes par mode de paiement';

  @override
  String get revenueDistribution => 'Répartition CA';

  @override
  String get collected => 'Encaissé';

  @override
  String get credit => 'Crédit';

  @override
  String get bestClients => 'Meilleurs Clients';

  @override
  String get bestSuppliers => 'Meilleurs Fournisseurs';

  @override
  String get topCredits => 'Top Crédits';

  @override
  String get bestSellingProducts => 'Produits Plus Vendus';

  @override
  String get outOfStockProducts => 'Produits en Rupture';

  @override
  String get from => 'Du';

  @override
  String get to => 'Au';

  @override
  String get quickPeriod => 'Période rapide';

  @override
  String get export => 'Exporter';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get yesterday => 'Hier';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get lastWeek => 'Semaine dernière';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get lastMonth => 'Mois dernier';

  @override
  String get last7Days => '7 derniers jours';

  @override
  String get last30Days => '30 derniers jours';

  @override
  String get thisYear => 'Cette année';

  @override
  String get lastYear => 'Année dernière';

  @override
  String get caisse => 'Caisse';

  @override
  String get produit => 'Produit';

  @override
  String get panier => 'Panier';

  @override
  String get client => 'Client';

  @override
  String get fournisseur => 'Fournisseur';

  @override
  String get entree => 'Entrée';

  @override
  String get sortie => 'Sortie';

  @override
  String get retour => 'Retour';

  @override
  String get stock => 'Stock';

  @override
  String get besoin => 'Besoin';

  @override
  String get utilisateur => 'Utilisateur';

  @override
  String get magasin => 'Magasin';

  @override
  String get gestionCaisse => 'Gestion Caisse';

  @override
  String get zakat => 'Zakat';

  @override
  String get parametre => 'Paramètre';

  @override
  String get historique => 'Historique';

  @override
  String get pinSidebar => 'Épingler la barre';

  @override
  String get unpinSidebar => 'Désépingler la barre';

  @override
  String get payment => 'Paiement';

  @override
  String get remise => 'Remise';

  @override
  String get sousCategorie => 'Sous catégorie';

  @override
  String get hideProduct => 'Masquer produit';

  @override
  String get showProduct => 'Afficher produit';

  @override
  String get noProductSelected => 'Aucun produit sélectionné';

  @override
  String get cannotDeleteLastCaisse =>
      'Impossible de supprimer la dernière caisse';

  @override
  String get deleteCaisseTitle => 'Supprimer la caisse';

  @override
  String deleteCaisseMessage(Object caisseName) {
    return 'Merci de confirmer la suppression de $caisseName. Tous les paniers seront perdus.';
  }

  @override
  String get clearCartTitle => 'Vider le panier';

  @override
  String get clearCartMessage =>
      'Merci de confirmer la suppression de tous les produits du panier';

  @override
  String get emptyCartError => '❌ Panier vide';

  @override
  String get emptyCart => 'Panier vide';

  @override
  String get addProductsToStart => 'Ajoutez des produits pour commencer';

  @override
  String get maxCaissesReached => 'Maximum 10 caisses actives';

  @override
  String get loadingParams => 'Chargement des paramètres...';

  @override
  String get settingsSavedSuccess => 'Paramètres enregistrés avec succès';

  @override
  String get encaisserTicket => 'Encaisser Ticket';

  @override
  String get enregistrer => 'Enregistrer';

  @override
  String get encaisserBLSC => 'Encaisser BL/SC';

  @override
  String get annuler => 'Annuler';

  @override
  String get serverError => 'Erreur du serveur !';

  @override
  String get noResultsFound => 'Aucun résultat trouvé.';

  @override
  String get besoinList => 'BesoinList';

  @override
  String get categorie => 'Catégorie';

  @override
  String get dash => 'Tableau de Bord';

  @override
  String get pack => 'Pack';

  @override
  String get parametreProduit => 'Paramètre produit';

  @override
  String get parametreCaisse => 'Paramètre caisse';

  @override
  String get role => 'Rôle';

  @override
  String get sCategorie => 'S_Catégorie';

  @override
  String get transfert => 'Transfert';

  @override
  String get versement => 'Versement';

  @override
  String get achat => 'achat';

  @override
  String get vente => 'vente';

  @override
  String get insertion => 'insertion';

  @override
  String get modification => 'modification';

  @override
  String get suppression => 'suppression';

  @override
  String get login => 'login';

  @override
  String get logout => 'logout';

  @override
  String get actif => 'Actif';

  @override
  String get inactif => 'Inactif';

  @override
  String get valide => 'Validé';

  @override
  String get annule => 'Annulé';

  @override
  String get parMontant => 'Par Montant';

  @override
  String get parProduit => 'Par Produit';

  @override
  String get enAttente => 'En Attente';

  @override
  String get commande => 'Commande';

  @override
  String get disponible => 'Disponible';

  @override
  String get expiration => 'Expiration';

  @override
  String get don => 'Don';

  @override
  String get montant => 'Montant';

  @override
  String get pourcentage => 'Pourcentage';

  @override
  String get bl => 'BL';

  @override
  String get blSc => 'BL_SC';

  @override
  String get physique => 'Physique';

  @override
  String get compte => 'Compte';

  @override
  String get piece => 'Pièce';

  @override
  String get litre => 'Litre';

  @override
  String get metre => 'Mètre';

  @override
  String get avancement => 'Avancement';

  @override
  String get complementFacture => 'Complément de facture';

  @override
  String get dette => 'Dette';

  @override
  String get paiement => 'Paiement';

  @override
  String get remboursement => 'Remboursement';

  @override
  String get acompte => 'Acompte';

  @override
  String get remiseVersement => 'Remise';

  @override
  String get especes => 'Espèces';

  @override
  String get carte => 'Carte';

  @override
  String get cheque => 'Chèque';

  @override
  String get usine => 'Usine';

  @override
  String get societe => 'Société';

  @override
  String get importateur => 'Importateur';

  @override
  String get grossiste => 'Grossiste';

  @override
  String get semiGrossiste => 'Semi-Grossiste';

  @override
  String get detailant => 'Détaillant';

  @override
  String get consommateur => 'Consommateur';

  @override
  String get destockage => 'Déstockage';

  @override
  String get cosmetique => 'Cosmétique';

  @override
  String get alimentation => 'Alimentation';

  @override
  String get quincaillerie => 'Quincaillerie';

  @override
  String get electromenager => 'Électroménager';

  @override
  String get hygieneNettoyage => 'Hygiène & Nettoyage';

  @override
  String get textileHabillement => 'Textile & Habillement';

  @override
  String get materiauxConstruction => 'Matériaux de construction';

  @override
  String get papeterieFournitures => 'Papeterie & Fournitures';

  @override
  String get piecesAutomobiles => 'Pièces automobiles';

  @override
  String get informatiqueAccessoires => 'Informatique & Accessoires';

  @override
  String get telephonie => 'Téléphonie';

  @override
  String get meublesDecoration => 'Meubles & Décoration';

  @override
  String get produitsAgricoles => 'Produits agricoles';

  @override
  String get produitsMenagers => 'Produits ménagers';

  @override
  String get boulangeriePatisserie => 'Boulangerie / Pâtisserie';

  @override
  String get bazar => 'Bazar';

  @override
  String get jouets => 'Jouets';

  @override
  String get produitsMedicaux => 'Produits médicaux non pharmaceutiques';

  @override
  String get particulier => 'Particulier';

  @override
  String get epicerie => 'Épicerie';

  @override
  String get superette => 'Superette';

  @override
  String get salonCoiffure => 'Salon de coiffure';

  @override
  String get institutBeaute => 'Institut de beauté';

  @override
  String get boutiqueVetements => 'Boutique de vêtements';

  @override
  String get boulangerie => 'Boulangerie';

  @override
  String get cafeteriaFastFood => 'Cafétéria / Fast-food';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get cafe => 'Café';

  @override
  String get magasinElectromenager => 'Magasin électroménager';

  @override
  String get pharmacie => 'Pharmacie';

  @override
  String get magasinJouets => 'Magasin de jouets';

  @override
  String get boutiqueTelephonie => 'Boutique téléphonie';

  @override
  String get garagePiecesAuto => 'Garage / Pièces auto';

  @override
  String get magasinInformatique => 'Magasin informatique';

  @override
  String get admin => 'Admin';

  @override
  String get caissier => 'Caissier';

  @override
  String get magasinier => 'Magasinier';

  @override
  String get autre => 'Autre';

  @override
  String get ticket => 'Ticket';

  @override
  String get virement => 'virement';

  @override
  String get parfumerie => 'parfumerie';

  @override
  String get information => 'Information';

  @override
  String get noCategorySelected => 'Aucune catégorie sélectionnée';

  @override
  String get selectSingleCategoryForDetail =>
      'Veuillez sélectionner une seule catégorie pour afficher le détail';

  @override
  String get cannotDeleteSystemCategory =>
      'Impossible de supprimer cette catégorie (Système)';

  @override
  String get cannotModifySystemCategory =>
      'Impossible de modifier cette catégorie (Système)';

  @override
  String get selectSingleCategoryToModify =>
      'Veuillez sélectionner une seule catégorie pour modifier';

  @override
  String get noDiscountSelected => 'Aucune remise sélectionnée';

  @override
  String get selectSingleDiscountForDetail =>
      'Veuillez sélectionner une seule remise pour afficher le détail';

  @override
  String get selectSingleDiscountToModify =>
      'Veuillez sélectionner une seule remise pour modifier';

  @override
  String get noPackSelected => 'Aucun pack sélectionné';

  @override
  String get selectSinglePackForDetail =>
      'Veuillez sélectionner un seul pack pour afficher le détail';

  @override
  String get selectSinglePackToModify =>
      'Veuillez sélectionner un seul pack pour modifier';

  @override
  String get noSubCategorySelected => 'Aucune sous-catégorie sélectionnée';

  @override
  String get selectSingleSubCategoryForDetail =>
      'Veuillez sélectionner une seule sous-catégorie pour afficher le détail';

  @override
  String get cannotDeleteSystemSubCategory =>
      'Impossible de supprimer cette sous-catégorie (Système)';

  @override
  String get cannotModifySystemSubCategory =>
      'Impossible de modifier cette sous-catégorie (Système)';

  @override
  String get selectSingleSubCategoryToModify =>
      'Veuillez sélectionner une seule sous-catégorie pour modifier';

  @override
  String get filter => 'Filtre';

  @override
  String get newWord => 'Nouveau';

  @override
  String get margin => 'Marge';

  @override
  String get typeCalcul => 'Type Calcul';

  @override
  String get marginRate => 'Taux de Marge';

  @override
  String get threshold => 'Seuil';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get save => 'Sauvegarder';

  @override
  String get by => 'par';

  @override
  String get purchasePrice => 'Prix Achat';

  @override
  String get salePrice => 'Prix Vente';

  @override
  String get etat => 'État';

  @override
  String get search => 'Recherche';

  @override
  String get marque => 'Marque';

  @override
  String get currency => 'DA';

  @override
  String get needCategoryToCreateSubCategory =>
      'Pour créer une sous-catégorie vous devez avoir au moins une catégorie (Sans catégorie n\'est pas inclus)';

  @override
  String get selectSingleProductForDetail =>
      'Veuillez sélectionner un seul produit pour afficher le détail';

  @override
  String get selectSingleProductToModify =>
      'Veuillez sélectionner un seul produit pour modifier';

  @override
  String get typePannier => 'Type Panier';

  @override
  String get amount => 'Montant';

  @override
  String get remaining => 'Reste';

  @override
  String get startDate => 'Date début';

  @override
  String get endDate => 'Date fin';

  @override
  String get choosePeriod => 'Choisir une période';

  @override
  String get noCartSelected => 'Aucun panier sélectionné';

  @override
  String get selectSingleCartForDetail =>
      'Veuillez sélectionner un seul panier pour afficher le détail';

  @override
  String get selectSingleCartToModify =>
      'Veuillez sélectionner un seul panier pour modifier';

  @override
  String get typeClient => 'Type Client';

  @override
  String get activite => 'Activité';

  @override
  String get totalAchat => 'Total Achat';

  @override
  String get noClientSelected => 'Aucun client sélectionné';

  @override
  String get selectSingleClientForDetail =>
      'Veuillez sélectionner un seul client pour afficher le détail';

  @override
  String get cannotDeleteSystemClient =>
      'Impossible de supprimer ce client système';

  @override
  String get cannotModifySystemClient =>
      'Impossible de modifier ce client système';

  @override
  String get selectSingleClientToModify =>
      'Veuillez sélectionner un seul client pour modifier';

  @override
  String get selectSingleClientForOperations =>
      'Veuillez sélectionner un seul client pour afficher ses opérations';

  @override
  String get noPaymentSelected => 'Aucun versement sélectionné';

  @override
  String get selectSinglePaymentToModify =>
      'Veuillez sélectionner un seul versement pour modifier';

  @override
  String get exit => 'Sortie';

  @override
  String get type => 'Type';

  @override
  String get noListSelected => 'Aucune liste sélectionnée';

  @override
  String get selectSingleListForDetail =>
      'Veuillez sélectionner une seule liste pour afficher le détail';

  @override
  String get selectSingleListToModify =>
      'Veuillez sélectionner une seule liste pour modifier';

  @override
  String get noUserSelected => 'Aucun utilisateur sélectionné';

  @override
  String get selectSingleUserForDetail =>
      'Veuillez sélectionner un seul utilisateur pour afficher le détail';

  @override
  String get selectSingleUserToModify =>
      'Veuillez sélectionner un seul utilisateur pour modifier';

  @override
  String get noRoleSelected => 'Aucun rôle sélectionné';

  @override
  String get selectSingleRoleForDetail =>
      'Veuillez sélectionner un seul rôle pour afficher le détail';

  @override
  String get selectSingleRoleToModify =>
      'Veuillez sélectionner un seul rôle pour modifier';

  @override
  String get error => 'Erreur';

  @override
  String get loadingError => 'Erreur de chargement des données';

  @override
  String get sourceCashRegister => 'Caisse Src';

  @override
  String get destinationCashRegister => 'Caisse Dest';

  @override
  String get newCashRegister => 'Nouvelle Caisse';

  @override
  String get newTransfer => 'Nouveau Transfert';

  @override
  String get noCashRegisterSelected => 'Aucune caisse sélectionnée';

  @override
  String get selectSingleCashRegisterForDetail =>
      'Veuillez sélectionner une seule caisse pour afficher le détail';

  @override
  String get selectSingleCashRegisterToModify =>
      'Veuillez sélectionner une seule caisse pour modifier';

  @override
  String get cannotDeleteSystemCashRegister =>
      'Impossible de supprimer cette caisse (système)';

  @override
  String get cannotModifySystemCashRegister =>
      'Impossible de modifier cette caisse (système)';

  @override
  String get noTransferSelected => 'Aucun transfert sélectionné';

  @override
  String get selectSingleTransferForDetail =>
      'Veuillez sélectionner un seul transfert pour afficher le détail';

  @override
  String get selectSingleTransferToModify =>
      'Veuillez sélectionner un seul transfert pour modifier';

  @override
  String get productCount => 'Nb Produit';

  @override
  String get noStoreSelected => 'Aucun magasin sélectionné';

  @override
  String get selectSingleStoreForDetail =>
      'Veuillez sélectionner un seul magasin pour afficher le détail';

  @override
  String get selectSingleStoreToModify =>
      'Veuillez sélectionner un seul magasin pour modifier';

  @override
  String get cannotDeleteSystemStore =>
      'Impossible de supprimer ce magasin (Système)';

  @override
  String get cannotModifySystemStore =>
      'Impossible de modifier ce magasin (Système)';

  @override
  String get zakatParameter => 'Paramètre Zakat';

  @override
  String get nissab => 'Nissab';

  @override
  String get zakatRate => 'Taux Zakat';

  @override
  String get zakatPaid => 'Zakat Payée';

  @override
  String get zakatUnpaid => 'Zakat Non Payée';

  @override
  String get totalZakat => 'Total Zakat';

  @override
  String get state => 'État';

  @override
  String get settingsNotSaved => 'Paramètres non sauvegardés';

  @override
  String get noZakatSelected => 'Aucun zakat sélectionné';

  @override
  String get selectSingleZakatForDetail =>
      'Veuillez sélectionner un seul zakat pour afficher le détail';

  @override
  String get selectSingleZakatToModify =>
      'Veuillez sélectionner un seul zakat pour modifier';

  @override
  String get period => 'Période';

  @override
  String get zakatDetail => 'Détail Zakat';

  @override
  String get zakatModify => 'Modifier Zakat';

  @override
  String get zakatNew => 'Nouveau Zakat';

  @override
  String get zakatCancel => 'Annuler Zakat';

  @override
  String get modificationOf => 'Modification de';

  @override
  String get parameter => 'Paramètre';

  @override
  String get date => 'Date';

  @override
  String get status => 'Statut';

  @override
  String get paid => 'Payée';

  @override
  String get unpaid => 'Non Payée';

  @override
  String get creances => 'Créances';

  @override
  String get montantZakat => 'Montant Zakat';

  @override
  String get dateDebutHawl => 'Date Début Hawl';

  @override
  String get typeOperation => 'Type opération';

  @override
  String get operationOn => 'Opération sur';

  @override
  String get noHistoriqueSelected => 'Aucun historique sélectionné';

  @override
  String get selectSingleHistoriqueForDetail =>
      'Veuillez sélectionner un seul historique pour afficher le détail';

  @override
  String get historiqueDetail => 'Détail Historique';

  @override
  String get operation => 'Opération';

  @override
  String get description => 'Description';

  @override
  String get createdBy => 'Créé par';

  @override
  String get dateCreated => 'Date création';

  @override
  String get profile => 'Profil';

  @override
  String get settings => 'Paramètres';

  @override
  String get myAccount => 'Mon Compte';

  @override
  String get cancel => 'Annuler';

  @override
  String get clear => 'CL';

  @override
  String get newClient => 'Nouveau Client';

  @override
  String get newProduct => 'Nouveau Produit';

  @override
  String get discount => 'Remise';

  @override
  String get cashTicket => 'Encaisser Ticket';

  @override
  String get cashBLSC => 'Encaisser BL/SC';

  @override
  String get saveTicket => 'Enregistrer Ticket';

  @override
  String get cancelCart => 'Annuler Panier';

  @override
  String get clearEntry => 'Effacer';

  @override
  String get deleteCart => 'Supprimer Caisse';

  @override
  String get category => 'Catégorie';

  @override
  String get chooseCategory => 'Choisir une catégorie';

  @override
  String get product => 'Produit';

  @override
  String get all => 'Tous';

  @override
  String get exampleRange => 'Ex:100->200';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get validate => 'Valider';

  @override
  String get total => 'Total';

  @override
  String get code => 'Code';

  @override
  String get price => 'Prix';

  @override
  String get quantity => 'Qt';

  @override
  String get showHideColumns => 'Afficher / Masquer les colonnes';

  @override
  String get none => 'Aucun';

  @override
  String get keepSelection => 'Garder la sélection';

  @override
  String get apply => 'Appliquer';

  @override
  String get page => 'Page';

  @override
  String get rowsPerPage => 'lignes / page';

  @override
  String selectDate(Object date) {
    return 'Sélectionner $date';
  }

  @override
  String get selectDatew => 'Sélectionner date';

  @override
  String get select => 'Sélectionner';

  @override
  String get auto => 'Auto';

  @override
  String get requiredField => 'Champ obligatoire';

  @override
  String get maValue => 'Max';

  @override
  String get inStock => 'Qnt';

  @override
  String get addManually => 'Ajouter manuellement';

  @override
  String get number => 'N°';

  @override
  String get articles => 'Articles';

  @override
  String get supplier => 'Fournisseur';

  @override
  String get details => 'Détails';

  @override
  String get products => 'Produits';

  @override
  String get totalPurchases => 'Total achats';

  @override
  String get payments => 'Versements';

  @override
  String get totalCredit => 'Total crédit';

  @override
  String creditOf(Object amount, Object client) {
    return 'Crédit $amount de client $client';
  }

  @override
  String get best => 'Meilleur';

  @override
  String get averagePurchase => 'Moyenne d\'achat';

  @override
  String get ofClient => 'de client';

  @override
  String get store => 'Magasin';

  @override
  String get initialBalance => 'Solde initial';

  @override
  String get obs => 'Obs';

  @override
  String get operations => 'Opérations';

  @override
  String get creations => 'Créations';

  @override
  String get adds => 'Ajouts';

  @override
  String get modifications => 'Modifications';

  @override
  String get updates => 'Mises à jour';

  @override
  String get deletions => 'Suppressions';

  @override
  String get deletedItems => 'Éléments supprimés';

  @override
  String get todayOperations => 'Opérations du jour';

  @override
  String get lastUser => 'Dernier User';

  @override
  String get lastAction => 'Dernière action';

  @override
  String get stockRate => 'Taux stockage';

  @override
  String get time => 'Heure';

  @override
  String get totalPaniers => 'Total paniers';

  @override
  String get allCarts => 'Tous les paniers';

  @override
  String get totalCartAmount => 'Total panier';

  @override
  String get sumOfAllCarts => 'Somme de tous les paniers';

  @override
  String get starProduct => 'Produit star';

  @override
  String get times => 'fois';

  @override
  String get averagePerCart => 'Moyenne par panier';

  @override
  String get averageValue => 'Valeur moyenne';

  @override
  String get outOfStock => 'RUPTURE';

  @override
  String get unit => 'Unité';

  @override
  String get categories => 'Catégories';

  @override
  String get subcategories => 'Sous-catégories';

  @override
  String get packs => 'Packs';

  @override
  String get discounts => 'Remises';

  @override
  String get registeredProducts => 'Produits enregistrés';

  @override
  String get productTypes => 'Types de produits';

  @override
  String get secondaryLevels => 'Niveaux secondaires';

  @override
  String get bundledOffers => 'Offres groupées';

  @override
  String get activeDiscounts => 'Remises actives';

  @override
  String get actualStock => 'Stock réel';

  @override
  String get theoreticalStock => 'Stock théorique';

  @override
  String get totalPurchased => 'Total acheté';

  @override
  String get totalSold => 'Total vendu';

  @override
  String get returns => 'Retours';

  @override
  String get lastPurchase => 'Dernier achat';

  @override
  String get validated => 'VALIDÉ';

  @override
  String get pending => 'EN ATTENTE';

  @override
  String get waiting => 'ATTENTE';

  @override
  String get yes => 'Oui';

  @override
  String get no => 'Non';

  @override
  String get rate => 'Taux';

  @override
  String get source => 'Source';

  @override
  String get destination => 'Destination';

  @override
  String get observations => 'Observations';

  @override
  String get noObservation => 'Aucune observation';

  @override
  String get createdAt => 'Créé le';

  @override
  String get users => 'Utilisateurs';

  @override
  String get sales => 'Ventes';

  @override
  String get lastAccess => 'Dernier accès';

  @override
  String get phone => 'Téléphone';

  @override
  String get year => 'Année';

  @override
  String get cash => 'Liquidités';

  @override
  String get receivables => 'Créances';

  @override
  String get debts => 'Dettes';

  @override
  String get mandatory => 'Obligatoire';

  @override
  String get zakatAmount => 'Montant Zakat';

  @override
  String get appliedRate => 'Taux appliqué';

  @override
  String get smartScan => 'SmartScan';

  @override
  String get scannedItems => 'Articles scannés';

  @override
  String get carts => 'Paniers';

  @override
  String get activeCarts => 'Paniers actifs';

  @override
  String get returnedProducts => 'Produits retournés';

  @override
  String get needs => 'Besoins';

  @override
  String get stockRequests => 'Demandes de stock';

  @override
  String get exits => 'Sorties';

  @override
  String get exitedProducts => 'Produits sortis';

  @override
  String get availableProducts => 'Produits disponibles';

  @override
  String get elements => 'Éléments';

  @override
  String get items => 'Articles';

  @override
  String get modifiedAt => 'Modifié le';

  @override
  String get modifiedBy => 'Modifié par';

  @override
  String get cancelledAt => 'Annulé le';

  @override
  String get cancelledBy => 'Annulé par';

  @override
  String get cancellationReason => 'Motif annulation';

  @override
  String get otherwiseDefaultColumns =>
      'Sinon les colonnes par défaut seront utilisées';

  @override
  String get close => 'Fermer';

  @override
  String get brand => 'Marque';

  @override
  String get model => 'Modèle';

  @override
  String get qty => 'Qt';

  @override
  String get name => 'Nom';

  @override
  String get observation => 'Observation';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get activity => 'Activité';

  @override
  String get advance => 'Avance';

  @override
  String get totalInvoiced => 'Total Facturé';

  @override
  String get nbInvoiced => 'Nb Facturé';

  @override
  String get totalPayment => 'Total Versement';

  @override
  String get nbPayment => 'Nb Versement';

  @override
  String get nbReturn => 'Nb Retour';

  @override
  String get email => 'Email';

  @override
  String get fax => 'Fax';

  @override
  String get nif => 'NIF';

  @override
  String get nis => 'NIS';

  @override
  String get nrc => 'NRC';

  @override
  String get rib => 'RIB';

  @override
  String get bank => 'Banque';

  @override
  String creditWithAmount(Object amount) {
    return 'Crédit: $amount';
  }

  @override
  String get upToDate => 'À jour';

  @override
  String get address => 'Adresse';

  @override
  String get totalPaid => 'Total Versé';

  @override
  String get nbPurchases => 'Nb achats';

  @override
  String get debt => 'Dette';

  @override
  String get settled => 'Soldé';

  @override
  String get id => 'ID';

  @override
  String get storageRate => 'Taux Stockage';

  @override
  String get cashRegisterName => 'Nom de la caisse';

  @override
  String get creatorCode => 'Code créateur';

  @override
  String get deletion => 'Suppression';

  @override
  String get user => 'Utilisateur';

  @override
  String get need => 'Besoin';

  @override
  String get sale => 'Vente';

  @override
  String get purchase => 'Achat';

  @override
  String get return_ => 'Retour';

  @override
  String get destocking => 'Déstockage';

  @override
  String get reference => 'Référence';

  @override
  String get ref => 'Réf';

  @override
  String get debit => 'Débit';

  @override
  String get balance => 'Solde';

  @override
  String get cashier => 'Caissier';

  @override
  String get size => 'Taille';

  @override
  String get color => 'Couleur';

  @override
  String get subcategory => 'Sous-Catégorie';

  @override
  String get service => 'Service';

  @override
  String get packaging1 => 'Emballage 1';

  @override
  String get packaging2 => 'Emballage 2';

  @override
  String get minThreshold => 'Seuil Min';

  @override
  String get maxThreshold => 'Seuil Max';

  @override
  String get needStatus => 'Besoin Status';

  @override
  String get barcode => 'Code Barre';

  @override
  String get serialNumber => 'Numéro Série';

  @override
  String get multicode => 'Multicode';

  @override
  String get photos => 'Photos';

  @override
  String get marginBool => 'Marge Bool';

  @override
  String get marginRatePercent => 'Marge Taux %';

  @override
  String get vat => 'TVA';

  @override
  String get dateBorrowed => 'Date Empreint';

  @override
  String get thresholdBool => 'Seuil Bool';

  @override
  String get rateType => 'Type Taux';

  @override
  String get start => 'Début';

  @override
  String get end => 'Fin';

  @override
  String get percentage => '%';

  @override
  String get clientType => 'Client';

  @override
  String get supplierType => 'Fournisseur';

  @override
  String get userCount => 'Nb utilisateurs';

  @override
  String get calculatedProducts => 'Produits Calcul';

  @override
  String get calculatedQuantity => 'Quantité Calcul';

  @override
  String get calculatedAmount => 'Montant Calcul';

  @override
  String get gap => 'Écart';

  @override
  String get categoryId => 'ID Catégorie';

  @override
  String get totalPurchase => 'Total Achat';

  @override
  String get totalSale => 'Total Vente';

  @override
  String get totalReturn => 'Total Retour';

  @override
  String get lastPurchaseQuantity => 'Quantité Dernier Achat';

  @override
  String get username => 'Nom d\'utilisateur';

  @override
  String get salesCount => 'Nb ventes';

  @override
  String get beneficiaryType => 'Type Bénéficiaire';

  @override
  String get cashRegister => 'Caisse';

  @override
  String get beneficiary => 'Bénéficiaire';

  @override
  String get paymentMethod => 'Mode Paiement';

  @override
  String get incoming => 'Entrant';

  @override
  String get outgoing => 'Sortant';

  @override
  String get entry => 'Entrée';

  @override
  String get cancelled => 'Annulé';

  @override
  String get totalCapital => 'Capital Total';

  @override
  String get statusField => 'Statut';

  @override
  String get hawlStart => 'Début Hawl';

  @override
  String get dueDate => 'Échéance';

  @override
  String get paymentDate => 'Paiement';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get confirm => 'Confirmer';

  @override
  String get insertionCashRegister => 'Insertion Caisse';

  @override
  String get insertionCategory => 'Insertion Catégorie';

  @override
  String get newM => 'Nouveau';

  @override
  String get add => 'Ajouter';

  @override
  String get pleaseSelect => 'Veuillez sélectionner';

  @override
  String get pleaseSelectCashRegister => 'Veuillez sélectionner une caisse';

  @override
  String get pleaseSelectCategory => 'Veuillez sélectionner une catégorie';

  @override
  String get insertionClient => 'Insertion Client';

  @override
  String get insertionSupplier => 'Insertion Fournisseur';

  @override
  String get insertionStore => 'Insertion Magasin';

  @override
  String get multipleSelection => 'Sélection multiple';

  @override
  String get pleaseSelectClient => 'Veuillez sélectionner un client';

  @override
  String get pleaseSelectSupplier => 'Veuillez sélectionner un fournisseur';

  @override
  String get pleaseSelectStore => 'Veuillez sélectionner un magasin';

  @override
  String get insertionPack => 'Insertion Pack';

  @override
  String get insertionProduct => 'Insertion Produit';

  @override
  String get insertionDiscount => 'Insertion Remise';

  @override
  String get insertionSubcategory => 'Insertion Sous-Catégorie';

  @override
  String get pleaseSelectPack => 'Veuillez sélectionner un pack';

  @override
  String get pleaseSelectProduct => 'Veuillez sélectionner un produit';

  @override
  String get pleaseSelectDiscount => 'Veuillez sélectionner une remise';

  @override
  String get pleaseSelectSubcategory =>
      'Veuillez sélectionner une sous-catégorie';

  @override
  String get newNeedList => 'Nouvelle Besoin List';

  @override
  String get modifyNeedList => 'Modifier Besoin List';

  @override
  String get deleteNeeds => 'Supprimer Besoins';

  @override
  String get needDetail => 'Détail Besoin';

  @override
  String get totalAmount => 'Montant total';

  @override
  String get numberOfArticles => 'Nombre d\'articles';

  @override
  String get totalQuantity => 'Quantité totale';

  @override
  String get noProduct => 'Aucun produit';

  @override
  String get generalInformation => 'Informations générales';

  @override
  String get audit => 'Audit';

  @override
  String get productsList => 'Liste des produits';

  @override
  String get addObservation => 'Ajouter une observation...';

  @override
  String get selectedNeeds => 'Besoins sélectionnés :';

  @override
  String get confirmDeleteNeeds =>
      'Êtes-vous sûr de vouloir supprimer cette liste ?';

  @override
  String get loginRequired =>
      'Vous devez être connecté pour créer une besoin list';

  @override
  String get fillRequiredFields =>
      'Veuillez remplir tous les champs obligatoires.';

  @override
  String get success => 'Succès';

  @override
  String get modify => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String productsOfNeed(Object code) {
    return 'Produits du besoin $code';
  }

  @override
  String get productCode => 'Code';

  @override
  String get productName => 'Produit';

  @override
  String get productQuantity => 'Quantité';

  @override
  String get productPrice => 'Prix';

  @override
  String get productTotal => 'Total';

  @override
  String get cashRegisterSettings => 'Paramètres Caisse';

  @override
  String get defaultCashRegister => 'Caisse par défaut';

  @override
  String get defaultStore => 'Magasin par défaut';

  @override
  String get parcel => 'Colis';

  @override
  String get alwaysAsked => 'Toujours demandé';

  @override
  String get uniteParcel => 'Unité';

  @override
  String get smallParcel => 'Petit colis';

  @override
  String get largeParcel => 'Grand colis';

  @override
  String get allFieldsRequired => 'Tous les champs doivent être remplis';

  @override
  String get modifyProductPrice => 'Modifier prix produit';

  @override
  String get password => 'Mot de passe';

  @override
  String get invalidPrice => 'Prix invalide';

  @override
  String get passwordRequired => 'Mot de passe requis';

  @override
  String get ticketRegistration => 'Enregistrement Ticket';

  @override
  String get cartNumber => 'N° Panier';

  @override
  String get fullPayment => 'Paiement total';

  @override
  String get cashPrint => 'Encaisser / Imprimer';

  @override
  String get cashPrintBLSC => 'Encaisser / Imprimer BLSC';

  @override
  String get cashPrintTicket => 'Encaisser / Imprimer Ticket';

  @override
  String get blNumber => 'N° BL';

  @override
  String get paidAmount => 'Payé';

  @override
  String get remainingAmount => 'Reste';

  @override
  String get deleteCategory => 'Supprimer catégorie';

  @override
  String get categoryDetail => 'Détail Catégorie';

  @override
  String get modifyCategory => 'Modification Catégorie';

  @override
  String get newCategory => 'Nouvelle Catégorie';

  @override
  String get selectedCategories => 'Catégories sélectionnées :';

  @override
  String get confirmDeleteCategories =>
      'Vous êtes sûr de Supprimer ces catégories ?';

  @override
  String get confirmDeleteCategory =>
      'Êtes-vous sûr de vouloir supprimer définitivement les catégories sélectionnées ?';

  @override
  String get deleteSuccess => 'Catégories supprimées avec succès.';

  @override
  String get deleteError =>
      'Merci de vider toutes les sous-catégories avant suppression.';

  @override
  String get modifySuccess => 'Modifiée avec succès.';

  @override
  String get createSuccess => 'L\'opération enregistrée avec succès.';

  @override
  String get categoryExists => 'Une catégorie avec ce nom existe déjà.';

  @override
  String get authentication => 'Authentification';

  @override
  String get categoryNameHint => 'Nom de la catégorie';

  @override
  String get categoryObservationHint => 'Observation de la catégorie...';

  @override
  String get deleteClients => 'Supprimer Clients';

  @override
  String get clientDetail => 'Détail Client';

  @override
  String get modifyClient => 'Modification Client';

  @override
  String clientSituation(Object name) {
    return 'Situation Client : $name';
  }

  @override
  String get numberOfPurchases => 'Nombre d\'achats';

  @override
  String get numberOfPayments => 'Nombre de versement';

  @override
  String get contact => 'Contact';

  @override
  String get addressInfo => 'Adresse';

  @override
  String get financialInformation => 'Informations financières';

  @override
  String get administrativeInformation => 'Informations Administratives';

  @override
  String get bankingInformation => 'Coordonnées Bancaires';

  @override
  String get selectedClients => 'Clients sélectionnés :';

  @override
  String get confirmDeleteClients =>
      'Êtes-vous sûr de vouloir supprimer ces clients ?';

  @override
  String get refresh => 'Actualiser';

  @override
  String get clientNameHint => 'Nom du client';

  @override
  String get phoneHint => '0550 00 00 00';

  @override
  String get wilayaHint => 'Biskra';

  @override
  String get addressHint => 'Cité 05 juillet';

  @override
  String get emailHint => 'client@mail.com';

  @override
  String get faxHint => '033 00 00 00';

  @override
  String get nifHint => '000000000000000';

  @override
  String get nisHint => '0000000000';

  @override
  String get nrcHint => '16/00-0000000B00';

  @override
  String get bankHint => 'BNA / CPA / BADR ...';

  @override
  String get ribHint => '007999990000123456789';

  @override
  String get observationHint => 'Observation ...';

  @override
  String get versement_ENT => 'Versement (Entrée)';

  @override
  String get versement_SRT => 'Versement (Sortie)';

  @override
  String clientNumber(Object id) {
    return 'Client #$id';
  }

  @override
  String get lastPurchaseDate => 'Dernier achat';

  @override
  String get purchasesCount => 'Achats';

  @override
  String get deleteSuppliers => 'Supprimer Fournisseurs';

  @override
  String get supplierDetail => 'Détail Fournisseur';

  @override
  String get modifySupplier => 'Modification Fournisseur';

  @override
  String get newSupplier => 'Nouveau Fournisseur';

  @override
  String supplierSituation(Object name) {
    return 'Situation Fournisseur : $name';
  }

  @override
  String supplierNumber(Object id) {
    return 'Fournisseur #$id';
  }

  @override
  String get selectedSuppliers => 'Fournisseurs sélectionnés :';

  @override
  String get confirmDeleteSuppliers =>
      'Êtes-vous sûr de vouloir supprimer ces fournisseurs ?';

  @override
  String get supplierNameHint => 'Nom du fournisseur';

  @override
  String get paymentIn => 'Versement (Entrée)';

  @override
  String get paymentOut => 'Versement (Sortie)';

  @override
  String get deleteCashRegisters => 'Supprimer les caisses';

  @override
  String get cashRegisterDetail => 'Détail Caisse';

  @override
  String get modifyCashRegister => 'Modification Caisse';

  @override
  String cashRegisterNumber(Object id) {
    return 'Caisse #$id';
  }

  @override
  String get selectedCashRegisters => 'Caisses sélectionnées :';

  @override
  String get confirmDeleteCashRegisters =>
      'Êtes-vous sûr de vouloir supprimer ces caisses ?';

  @override
  String get noStoreAvailable => 'Aucun magasin disponible.';

  @override
  String get codeAutoGenerated => 'Généré automatiquement';

  @override
  String get cashRegisterNameHint => 'Caisse principale';

  @override
  String get initialBalanceHint => '0.00';

  @override
  String get storeHint => 'Sélectionner un magasin';

  @override
  String get physical => 'Physique';

  @override
  String get account => 'Compte';

  @override
  String get deleteStores => 'Supprimer Magasins';

  @override
  String get cannotDelete => 'Impossible de supprimer';

  @override
  String get storeDetail => 'Détail Magasin';

  @override
  String get modifyStore => 'Modification Magasin';

  @override
  String get newStore => 'Nouveau Magasin';

  @override
  String storeNumber(Object id) {
    return 'Magasin #$id';
  }

  @override
  String get stockCapacity => 'Stock & capacité';

  @override
  String get selectedStores => 'Magasins sélectionnés :';

  @override
  String get cannotDeleteWithProducts =>
      'Vous ne pouvez pas supprimer les magasins suivants car ils contiennent des produits :';

  @override
  String get confirmDeleteStores =>
      'Êtes-vous sûr de vouloir supprimer ces magasins ?\nCette action est irréversible.';

  @override
  String get noStoreDeleted => 'Aucun magasin supprimé.';

  @override
  String get noProductsAssociated => 'Aucun produit associé à ce magasin';

  @override
  String get noProductsAdded => 'Aucun produit ajouté';

  @override
  String get storeNameHint => 'Nom du magasin';

  @override
  String get storeAddressHint => 'Adresse du magasin';

  @override
  String productsOfStore(Object code) {
    return 'Produits du Magasin $code';
  }

  @override
  String get reactivatePack => 'Réactiver pack';

  @override
  String get deletePacks => 'Supprimer Packs';

  @override
  String get packDetail => 'Détail Pack';

  @override
  String get modifyPack => 'Modification Pack';

  @override
  String get newPack => 'Nouveau Pack';

  @override
  String get numberOfItems => 'Nombre d\'articles';

  @override
  String get selectedPacks => 'Packs sélectionnés :';

  @override
  String get confirmReactivatePacks => 'Vous êtes sur de réactiver ces packs ?';

  @override
  String get confirmDeletePacks =>
      'Êtes-vous sûr de vouloir supprimer les packs sélectionnés ?\nCette action est irréversible.';

  @override
  String get noChangesDetected => 'Aucune modification détectée.';

  @override
  String productAlreadyAdded(Object name) {
    return 'Le produit $name est déjà ajouté au pack.';
  }

  @override
  String get packNameHint => 'Nom du pack';

  @override
  String get priceHint => 'Ex: 1500.00';

  @override
  String productsCount(Object count) {
    return '$count produits';
  }

  @override
  String productsOfPack(Object code) {
    return 'Produits du Pack $code';
  }

  @override
  String get cancelCarts => 'Annuler Paniers';

  @override
  String get cartDetail => 'Détail Panier';

  @override
  String get modifyCart => 'Modification Panier';

  @override
  String get cartType => 'Type panier';

  @override
  String get amountPaid => 'Montant versé';

  @override
  String cartId(Object code) {
    return 'Panier #$code';
  }

  @override
  String get itemsAndQuantities => 'Articles & Quantités';

  @override
  String get selectedCarts => 'Paniers sélectionnés :';

  @override
  String get confirmCancelCarts =>
      'Êtes-vous sûr de vouloir annuler ces paniers ?';

  @override
  String cartProducts(Object code) {
    return 'Produits du panier $code';
  }

  @override
  String get noProducts => 'Aucun produit';

  @override
  String get cart => 'Panier';

  @override
  String productsOfCart(Object code) {
    return 'Produits du panier $code';
  }

  @override
  String get applyCategorySubcategory => 'Appliquer Catégorie / Sous-Catégorie';

  @override
  String get selectedProducts => 'Produits sélectionnés :';

  @override
  String confirmModifyCategorySubcategory(Object count) {
    return 'Voulez-vous vraiment modifier la catégorie et la sous-catégorie pour $count produit(s) sélectionné(s) ?';
  }

  @override
  String get categorySubcategoryModifiedSuccess =>
      'Catégorie et Sous-catégorie modifiées avec succès.';

  @override
  String get errorOccurred => 'Une erreur est survenue.';

  @override
  String get priceTaxes => 'Prix & Taxes';

  @override
  String get stockUnit => 'Stock & Unité';

  @override
  String get unitOfMeasure => 'Unité de mesure';

  @override
  String get locationSpecifications => 'Emplacement & Spécifications';

  @override
  String get stores => 'Magasins';

  @override
  String get active => 'Actif';

  @override
  String get inactive => 'Inactif';

  @override
  String get noPacks => 'Aucun pack';

  @override
  String get noStores => 'Aucun magasin';

  @override
  String get applyPack => 'Appliquer un pack';

  @override
  String get applyDiscount => 'Appliquer une remise';

  @override
  String confirmApplyPack(Object count, Object packName) {
    return 'Êtes-vous sûr de vouloir appliquer le pack \'$packName\' à $count produit(s) sélectionné(s) ?';
  }

  @override
  String confirmApplyDiscount(Object count, Object discountName) {
    return 'Êtes-vous sûr de vouloir appliquer la remise \'$discountName\' à $count produit(s) sélectionné(s) ?';
  }

  @override
  String get packAppliedSuccess => 'Pack appliqué avec succès.';

  @override
  String get discountAppliedSuccess => 'Remise appliquée avec succès.';

  @override
  String get modifyProduct => 'Modification Produit';

  @override
  String get quickMode => 'Rapide';

  @override
  String get detailedMode => 'Détaillé';

  @override
  String get codeReference => 'Code & Référence';

  @override
  String get categoryDiscount => 'Catégorie & Remise';

  @override
  String get unitPackaging => 'Unité & Emballage';

  @override
  String get storage => 'Stockage';

  @override
  String get packStore => 'Pack & Magasin';

  @override
  String get marginAmount => 'Marge Montant';

  @override
  String get marginPercentage => 'Marge Pourcentage';

  @override
  String get spec1 => 'Spécification 1';

  @override
  String get spec2 => 'Spécification 2';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get productNameHint => 'Nom du produit';

  @override
  String get descriptionHint => 'Description';

  @override
  String get brandHint => 'Exemple: LG, Samsung....';

  @override
  String get barcodeHint => '949832128151';

  @override
  String get serialNumberHint => '123456789';

  @override
  String get sizeHint => 'XL L M S ....';

  @override
  String get colorHint => 'Blanc Bleu ....';

  @override
  String get packaging1Hint => '15 (boîte)';

  @override
  String get packaging2Hint => '150 (carton)';

  @override
  String get spec1Hint => 'Rayon 1';

  @override
  String get spec2Hint => 'Étagère 1';

  @override
  String get loginRequiredModify =>
      'Vous devez être connecté pour modifier un produit.';

  @override
  String get loginRequiredCreate =>
      'Vous devez être connecté pour créer un nouveau produit.';

  @override
  String get confirmModifyProduct =>
      'Êtes-vous sûr de vouloir modifier ce produit ?';

  @override
  String get salePriceLowerThanPurchase =>
      'Prix de vente inférieur au prix d\'achat';

  @override
  String get maxThresholdLowerThanMin =>
      'Seuil maximum inférieur au seuil minimum';

  @override
  String get productModifiedSuccess => 'Produit modifié avec succès.';

  @override
  String get productSavedSuccess => 'Produit enregistré avec succès.';

  @override
  String get deleteProduct => 'Supprimer Produit';

  @override
  String get confirmDeleteProducts =>
      'Vous êtes sûr de supprimer ces produits ?';

  @override
  String get confirmPermanentDelete =>
      'Êtes-vous sûr de vouloir supprimer définitivement les produits sélectionnés ?';

  @override
  String get productsDeletedSuccess => 'Produits supprimés avec succès.';

  @override
  String get cannotDeleteWithMovements =>
      'Vous ne pouvez pas supprimer ces produits car ils possèdent des mouvements :';

  @override
  String get loginRequiredDelete =>
      'Vous devez être connecté pour supprimer un produit.';

  @override
  String get kg => 'Kg';

  @override
  String get deleteDiscount => 'Supprimer Remise';

  @override
  String get selectedDiscounts => 'Remises sélectionnées :';

  @override
  String get confirmDeleteDiscounts =>
      'Vous êtes sûr de supprimer ces remises ?';

  @override
  String get confirmPermanentDeleteDiscounts =>
      'Êtes-vous sûr de vouloir supprimer définitivement les remises sélectionnées ?';

  @override
  String get discountsDeletedSuccess => 'Remises supprimées avec succès.';

  @override
  String get modifyDiscount => 'Modification Remise';

  @override
  String get newDiscount => 'Nouvelle Remise';

  @override
  String get productList => 'Liste produits';

  @override
  String productsOfDiscount(Object code) {
    return 'Produits de la remise $code';
  }

  @override
  String get amountRate => 'Montant / Taux';

  @override
  String get productsConcerned => 'Produits concernés';

  @override
  String get currentDiscount => 'Remise Actuelle';

  @override
  String get byProduct => 'Par Produit';

  @override
  String get byAmount => 'Par Montant';

  @override
  String get discountNameHint => 'Nom de la remise';

  @override
  String get discountRate => 'Taux de remise';

  @override
  String get pleaseSelectStartDateFirst =>
      'Veuillez choisir la date de début d\'abord';

  @override
  String get discountApplicationAmount => 'Montant d\'application de la remise';

  @override
  String get discountModifiedSuccess => 'Remise modifiée avec succès.';

  @override
  String get discountSavedSuccess => 'Remise enregistrée avec succès.';

  @override
  String get invalidNumber => 'Veuillez entrer un nombre valide';

  @override
  String get percentageExceeds100 => 'Le pourcentage ne peut pas dépasser 100%';

  @override
  String get valueMustBePositive => 'La valeur doit être positive';

  @override
  String get confirmModifyDiscount =>
      'Êtes-vous sûr de vouloir modifier cette remise ?';

  @override
  String get greaterThan => 'Supérieur à';

  @override
  String get deleteReturns => 'Supprimer les Retours';

  @override
  String get selectedReturns => 'Retours sélectionnés :';

  @override
  String get returnHash => 'Retour';

  @override
  String get confirmDeleteReturns =>
      'Êtes-vous sûr de vouloir supprimer ces retours ?';

  @override
  String get modifyReturn => 'Modifier Retour';

  @override
  String get newReturn => 'Nouveau Retour';

  @override
  String get confirmModifyReturn =>
      'Êtes-vous sûr de vouloir modifier ce retour ?';

  @override
  String get returnModifiedSuccess => 'Retour modifié avec succès.';

  @override
  String get returnSavedSuccess => 'Retour enregistré avec succès.';

  @override
  String get roles => 'Rôles';

  @override
  String get deactivateRoles => 'Désactiver les Rôles';

  @override
  String get selectedRoles => 'Rôles sélectionnés :';

  @override
  String get roleHash => 'Rôle';

  @override
  String get confirmDeactivateRoles =>
      'Êtes-vous sûr de vouloir désactiver ces rôles ?';

  @override
  String get deleteRole => 'Supprimer le Rôle';

  @override
  String get confirmDeleteRoles =>
      'Êtes-vous sûr de vouloir supprimer les rôles sélectionnés ?';

  @override
  String rolesDeletedCount(Object count) {
    return '$count rôle(s) supprimé(s) avec succès.';
  }

  @override
  String get noRolesDeleted => 'Aucun rôle supprimé.';

  @override
  String get deletionImpossible => 'Suppression impossible';

  @override
  String roleHasUsers(Object roleName) {
    return 'Le rôle \'$roleName\' contient des utilisateurs et ne peut pas être supprimé.';
  }

  @override
  String get roleName => 'Nom du rôle';

  @override
  String get roleNameHint => 'Ex : Administrateur';

  @override
  String get modifyRole => 'Modification du rôle';

  @override
  String get newRole => 'Nouveau Rôle';

  @override
  String get confirmModifyRole => 'Êtes-vous sûr de vouloir modifier ce rôle ?';

  @override
  String get roleModifiedSuccess => 'Rôle modifié avec succès.';

  @override
  String get roleSavedSuccess => 'Rôle enregistré avec succès.';

  @override
  String get smartScanHash => 'SmartScan';

  @override
  String get deleteSmartScan => 'Supprimer Smart Scan';

  @override
  String get selectedSmartScans => 'SmartScan sélectionnés :';

  @override
  String get confirmDeleteSmartScans =>
      'Êtes-vous sûr de vouloir supprimer ces SmartScan ?';

  @override
  String get statistics => 'Statistiques';

  @override
  String get scannedProductCount => 'Nombre de produits scannés';

  @override
  String get scannedTotalQuantity => 'Quantité totale scannée';

  @override
  String get scannedTotalAmount => 'Montant total scanné';

  @override
  String smartScanProducts(Object code) {
    return 'Produits du SmartScan $code';
  }

  @override
  String get smartScanProductsList => 'Produits du Smart Scan';

  @override
  String get modifySmartScan => 'Modification Smart Scan';

  @override
  String get gapDetected => 'Écart détecté';

  @override
  String get gapDetectedMessage =>
      'Un écart a été détecté entre les valeurs saisies et calculées.\nVoulez-vous continuer ?';

  @override
  String get smartScanModifiedSuccess => 'Smart Scan modifié avec succès.';

  @override
  String get newSmartScan => 'Nouveau Smart Scan';

  @override
  String get smartScanSavedSuccess => 'Smart Scan enregistré avec succès.';

  @override
  String get back => 'Retour';

  @override
  String get next => 'Suivant';

  @override
  String get supplierCodeRequired => 'Le code fournisseur est obligatoire.';

  @override
  String get supplierNameRequired => 'Le nom du fournisseur est obligatoire.';

  @override
  String get dateRequired => 'La date est obligatoire.';

  @override
  String get amountRequired => 'Le montant est obligatoire.';

  @override
  String get productCountRequired => 'Le nombre de produits est obligatoire.';

  @override
  String get totalQuantityRequired => 'La quantité totale est obligatoire.';

  @override
  String get atLeastOneProduct => 'Merci de sélectionner au moins un produit.';

  @override
  String get supplierCodeHint => 'Code fournisseur';

  @override
  String get scanGlobalQRCode => 'Merci de scanner le QR code Global';

  @override
  String get enterRequiredInformation =>
      'Merci de saisir les informations nécessaires';

  @override
  String get manual => 'Manuel';

  @override
  String get summary => 'Récapitulatif';

  @override
  String get productExistsInSmartScan =>
      'Ce produit existe déjà dans le Smart Scan';

  @override
  String get list => 'Liste';

  @override
  String get noEntrySelected => 'Aucune entrée sélectionnée !';

  @override
  String get selectSingleEntryForDetail =>
      'Veuillez sélectionner une seule entrée pour afficher le détail !';

  @override
  String get selectSingleEntryToModify =>
      'Veuillez sélectionner une seule entrée pour modifier !';

  @override
  String get deleteExit => 'Supprimer Sortie';

  @override
  String get deleteExits => 'Supprimer les Sorties';

  @override
  String get selectedExits => 'Sorties sélectionnées :';

  @override
  String get confirmDeleteExits =>
      'Êtes-vous sûr de vouloir supprimer ces sorties ?';

  @override
  String get modifyExit => 'Modification Sortie';

  @override
  String get newExit => 'Nouvelle Sortie';

  @override
  String get exitType => 'Type sortie';

  @override
  String get confirmModifyExit =>
      'Êtes-vous sûr de vouloir modifier cette sortie ?';

  @override
  String get exitModifiedSuccess => 'Sortie modifiée avec succès.';

  @override
  String get exitSavedSuccess => 'Sortie enregistrée avec succès.';

  @override
  String get unitPrice => 'Prix unitaire';

  @override
  String get dateHint => 'JJ/MM/AAAA';

  @override
  String get deactivateSubcategory => 'Désactiver la sous-catégorie';

  @override
  String get selectedSubcategories => 'Sous-catégories sélectionnées :';

  @override
  String get confirmDeactivateSubcategories =>
      'Vous êtes sûr de désactiver ces sous-catégories ?';

  @override
  String get deleteSubcategory => 'Supprimer la sous-catégorie';

  @override
  String get confirmDeleteSubcategories =>
      'Êtes-vous sûr de vouloir supprimer définitivement les sous-catégories sélectionnées ?';

  @override
  String get subcategoriesDeletedSuccess =>
      'Sous-catégories supprimées avec succès.';

  @override
  String get modifySubcategory => 'Modifier la sous-catégorie';

  @override
  String get newSubcategory => 'Nouvelle sous-catégorie';

  @override
  String get parentCategory => 'Catégorie parente';

  @override
  String get subcategoryNameHint => 'Nom de la sous-catégorie';

  @override
  String get confirmModifySubcategory =>
      'Êtes-vous sûr de vouloir modifier cette sous-catégorie ?';

  @override
  String get subcategoryModifiedSuccess =>
      'Sous-catégorie modifiée avec succès.';

  @override
  String get subcategorySavedSuccess =>
      'Sous-catégorie enregistrée avec succès.';

  @override
  String get affectedProducts => 'Produits concernés';

  @override
  String get currentSubcategory => 'Sous-catégorie actuelle';

  @override
  String get productDistribution => 'Distribution du produit';

  @override
  String get distributionByStore => 'Répartition par magasin';

  @override
  String get totalDistributed => 'Total distribué';

  @override
  String get available => 'Disponible';

  @override
  String get distribute => 'Distribuer';

  @override
  String get distributionExceedsStock =>
      'La quantité totale distribuée dépasse la quantité disponible';

  @override
  String get stockMovements => 'Mouvements Stock';

  @override
  String get last => 'Dernier';

  @override
  String get packaging => 'Emballage';

  @override
  String get transfer => 'Transfert';

  @override
  String get transfers => 'Transferts';

  @override
  String get transferHash => 'Transfert';

  @override
  String get cancelTransfers => 'Annuler les transferts';

  @override
  String get selectedTransfers => 'Transferts sélectionnés :';

  @override
  String get confirmCancelTransfers =>
      'Êtes-vous sûr de vouloir annuler ces transferts ?';

  @override
  String get irreversibleOperation => 'Cette opération est irréversible.';

  @override
  String get transfersCancelledSuccess => 'Transferts annulés avec succès.';

  @override
  String get transferDate => 'Date de transfert';

  @override
  String get modifyTransfer => 'Modifier le transfert';

  @override
  String get confirmModifyTransfer =>
      'Êtes-vous sûr de vouloir modifier ce transfert ?';

  @override
  String get transferModifiedSuccess => 'Transfert modifié avec succès.';

  @override
  String get observationOptional => 'Observation (facultatif)';

  @override
  String get userHash => 'Utilisateur';

  @override
  String get deleteUsers => 'Supprimer Utilisateurs';

  @override
  String get selectedUsers => 'Utilisateurs sélectionnés :';

  @override
  String get confirmDeleteUsers =>
      'Êtes-vous sûr de vouloir supprimer ces utilisateurs ?';

  @override
  String usersDeletedCount(Object count) {
    return '$count utilisateur(s) supprimé(s) avec succès.';
  }

  @override
  String get modifyUser => 'Modification Utilisateur';

  @override
  String get newUser => 'Nouvel Utilisateur';

  @override
  String get usernameHint => 'Nom d\'utilisateur';

  @override
  String get confirmModifyUser =>
      'Êtes-vous sûr de vouloir modifier cet utilisateur ?';

  @override
  String get userModifiedSuccess => 'Utilisateur modifié avec succès.';

  @override
  String get userSavedSuccess => 'Utilisateur enregistré avec succès.';

  @override
  String get paymentHash => 'Versement';

  @override
  String get activatePayments => 'Activer les Versements';

  @override
  String get selectedPayments => 'Versements sélectionnés :';

  @override
  String get confirmActivatePayments =>
      'Êtes-vous sûr de vouloir activer ces versements ?';

  @override
  String get deletePayments => 'Supprimer Versements';

  @override
  String get confirmDeletePayments =>
      'Êtes-vous sûr de vouloir supprimer les versements sélectionnés ?';

  @override
  String get paymentsDeletedSuccess => 'Versements supprimés avec succès.';

  @override
  String get paymentType => 'Type Versement';

  @override
  String get modifyPayment => 'Modifier Versement';

  @override
  String get modifyPaymentExit => 'Modifier Versement (Sortie)';

  @override
  String get newPayment => 'Nouveau Versement';

  @override
  String get newPaymentExit => 'Nouveau Versement (Sortie)';

  @override
  String get confirmModifyPayment =>
      'Êtes-vous sûr de vouloir modifier ce versement ?';

  @override
  String get paymentModifiedSuccess => 'Versement modifié avec succès.';

  @override
  String get paymentSavedSuccess => 'Versement enregistré avec succès.';

  @override
  String get sense => 'Sens';

  @override
  String get paymentExit => 'Versement (Sortie)';

  @override
  String get zakats => 'Zakats';

  @override
  String get deleteZakat => 'Supprimer Zakat';

  @override
  String get selectedZakats => 'Zakats sélectionnées :';

  @override
  String get confirmDeleteZakats =>
      'Êtes-vous sûr de vouloir supprimer ces Zakats ?';

  @override
  String get zakatsDeletedSuccess => 'Zakats supprimées avec succès.';

  @override
  String get alreadyPaid => 'Déjà payée';

  @override
  String get cannotDeletePaidZakat =>
      'Certaines Zakats sont déjà payées et ne peuvent pas être supprimées.';

  @override
  String get financialData => 'Données financières';

  @override
  String get liquidities => 'Liquidités';

  @override
  String get rulesZakat => 'Règles & Zakat';

  @override
  String get hawlDueDate => 'Hawl & Échéance';

  @override
  String get zakatDueDate => 'Date Zakat Due';

  @override
  String get autoCalculate => 'Calcul Auto';

  @override
  String get autoCalculateFromProducts =>
      'Calcul automatique depuis les produits';

  @override
  String get stockValue => 'Valeur stock';

  @override
  String get cashBank => 'Cash + Banque';

  @override
  String get moneyToReceive => 'Argent à recevoir';

  @override
  String get shortTermDebts => 'Dettes à court terme';

  @override
  String get rulesStatus => 'Règles & Statut';

  @override
  String get nissabThreshold => 'Seuil nissab';

  @override
  String get ratePercent => 'Taux (%)';

  @override
  String get nissabNotDefined => 'Nissab non défini ou égal à 0';

  @override
  String get zakatMandatory => 'Zakat obligatoire (capital ≥ nissab)';

  @override
  String get zakatNotMandatory => 'Zakat non obligatoire (capital < nissab)';

  @override
  String get modifyZakat => 'Modification Zakat';

  @override
  String get newZakat => 'Nouvelle Zakat';

  @override
  String get confirmModifyZakat =>
      'Êtes-vous sûr de vouloir modifier cette Zakat ?';

  @override
  String get zakatModifiedSuccess => 'Zakat modifiée avec succès.';

  @override
  String get zakatSavedSuccess => 'Zakat enregistrée avec succès.';

  @override
  String get confirmDeleteEntries =>
      'Êtes-vous sûr de vouloir supprimer ces entrées ?';

  @override
  String get entryModifiedSuccess => 'Entrée modifiée avec succès.';

  @override
  String get entrySavedSuccess => 'Entrée enregistrée avec succès.';

  @override
  String get selectedEntries => 'Entrées sélectionnées :';

  @override
  String get deleteEntries => 'Supprimer les Entrées';

  @override
  String get supplierCode => 'Code fournisseur';

  @override
  String get deleteEntry => 'Supprimer Entrée';

  @override
  String get modifyEntry => 'Modification Entrée';

  @override
  String get newEntry => 'Nouvelle Entrée';

  @override
  String get entries => 'Entrées';

  @override
  String get cashTicketReceipt => 'TICKET DE CAISSE';

  @override
  String get ticketNumber => 'Ticket N°';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get change => 'Rendu';

  @override
  String get thankYou => 'Merci pour votre visite!';

  @override
  String get seeYouSoon => 'À bientôt';

  @override
  String get magaprinc => 'Magasin Principal';

  @override
  String get paymentAmountMustBePositive =>
      'Le montant payé doit être supérieur à 0';

  @override
  String get printTicket => 'Impression du Ticket';

  @override
  String get printTicketConfirmation =>
      'Voulez-vous imprimer le ticket maintenant ?';

  @override
  String get bluetoothDisabled => 'Bluetooth désactivé';

  @override
  String get noPrinterFound => 'Aucune imprimante appairée trouvée';

  @override
  String get selectPrinter => 'Choisir l\'imprimante';

  @override
  String get connectionFailed => 'Connexion échouée';

  @override
  String get printFailed => 'Impression échouée';

  @override
  String get ticketPrintedSuccess => 'Ticket imprimé avec succès !';

  @override
  String get printError => 'Erreur d\'impression';

  @override
  String get autoPrintDisabled => 'Impression automatique désactivée';

  @override
  String get ticketPreview => 'Aperçu du ticket';

  @override
  String autoPrintIn(int seconds) {
    return 'Impression automatique dans $seconds secondes...';
  }

  @override
  String get printNow => 'Imprimer maintenant';

  @override
  String get partialPayment => 'Paiement Partiel';

  @override
  String get partialPaymentConfirm =>
      'Voulez-vous procéder au paiement partiel ?';

  @override
  String get receiptPreview => 'Aperçu du Ticket';

  @override
  String get print => 'Imprimer';

  @override
  String get invoice => 'Facture';

  @override
  String get deliveryNote => 'Bon de Livraison';

  @override
  String get salesReceipt => 'Ticket de Vente';

  @override
  String get clientInformation => 'Informations Client';

  @override
  String get clientName => 'Nom Client';

  @override
  String get clientCode => 'Code Client';

  @override
  String get invoiceDate => 'Date Facture';

  @override
  String get register => 'Caisse';

  @override
  String get paymentDetails => 'Détails de Paiement';

  @override
  String get receivedBy => 'Reçu par';

  @override
  String get cashierSignature => 'Signature du Caissier';

  @override
  String get clientSignature => 'Signature du Client';

  @override
  String get paymentExceedsTotal =>
      'Le montant payé ne peut pas dépasser le montant total';

  @override
  String get invoiceGenerated => 'Facture Générée';

  @override
  String get whatToDoWithInvoice => 'Que voulez-vous faire avec la facture ?';

  @override
  String get preview => 'Aperçu';

  @override
  String get share => 'Partager';

  @override
  String get invoiceSaved => 'Facture enregistrée';

  @override
  String get open => 'Ouvrir';

  @override
  String get invoiceShared => 'Facture partagée';

  @override
  String get invoiceGenerationError => 'Erreur de génération de facture';

  @override
  String get thankYouForYourPurchase => 'Merci pour votre achat !';

  @override
  String get invoicePreview => 'Aperçu de la Facture';

  @override
  String get printSuccess => 'Imprimé avec succès !';

  @override
  String get saveError => 'Erreur lors de l\'enregistrement';

  @override
  String get shareError => 'Erreur lors du partage';

  @override
  String get extract => 'Extract';

  @override
  String get extractSelected => 'Extract Selected';

  @override
  String get exportOptions => 'Export Options';

  @override
  String get exportCompleted => 'Export completed!';

  @override
  String get exportSuccess => 'Export successful';

  @override
  String get exportError => 'Export error';

  @override
  String get noDataToExport => 'No data to export';

  @override
  String get totalClients => 'Total Clients';

  @override
  String get generationDate => 'Generation Date';

  @override
  String get nombreAchats => 'Number of Purchases';

  @override
  String get dernierAchat => 'Last Purchase';

  @override
  String get totalRecords => 'Total Enregistrements';

  @override
  String get panierCode => 'Code Panier';

  @override
  String get totalPanniers => 'Total Paniers';

  @override
  String get totalRemaining => 'Reste Total';

  @override
  String get averageAmount => 'Moyenne par Panier';

  @override
  String get selected => 'Sélectionné(s)';

  @override
  String get totalProducts => 'Total Produits';

  @override
  String get totalStockValue => 'Valeur Stock Total';

  @override
  String get totalSaleValue => 'Valeur Vente Total';

  @override
  String get averagePrice => 'Prix Moyen';

  @override
  String get categoryCode => 'Code Catégorie';

  @override
  String get categoryName => 'Nom Catégorie';

  @override
  String get totalCategories => 'Total Catégories';

  @override
  String get discountCode => 'Code Remise';

  @override
  String get discountName => 'Nom Remise';

  @override
  String get discountType => 'Type Remise';

  @override
  String get discountValue => 'Valeur Remise';

  @override
  String get totalDiscounts => 'Total Remises';

  @override
  String get packCode => 'Code Pack';

  @override
  String get packName => 'Nom Pack';

  @override
  String get packPrice => 'Prix Pack';

  @override
  String get totalPacks => 'Total Packs';

  @override
  String get averagePackPrice => 'Prix Moyen Pack';

  @override
  String get subCategoryCode => 'Code Sous-Catégorie';

  @override
  String get subCategoryName => 'Nom Sous-Catégorie';

  @override
  String get totalSubCategories => 'Total Sous-Catégories';

  @override
  String get supplierName => 'Nom Fournisseur';

  @override
  String get totalSuppliers => 'Total Fournisseurs';

  @override
  String get paymentCode => 'Code Paiement';

  @override
  String get totalPayments => 'Total Paiements';

  @override
  String get noSupplierSelected => 'Aucun fournisseur sélectionné';

  @override
  String get entryCode => 'Code Entrée';

  @override
  String get totalEntries => 'Total Entrées';

  @override
  String get scanCode => 'Code Scan';

  @override
  String get totalScans => 'Total Scans';

  @override
  String get exitCode => 'Code Sortie';

  @override
  String get totalExits => 'Total Sorties';

  @override
  String get returnCode => 'Code Retour';

  @override
  String get totalReturns => 'Total Retours';

  @override
  String get clientReturns => 'Retours Clients';

  @override
  String get supplierReturns => 'Retours Fournisseurs';

  @override
  String get movementCode => 'Code Mouvement';

  @override
  String get totalMovements => 'Total Mouvements';

  @override
  String get clientMovements => 'Mouvements Clients';

  @override
  String get supplierMovements => 'Mouvements Fournisseurs';

  @override
  String get listCode => 'Code Liste';

  @override
  String get totalLists => 'Total Listes';

  @override
  String get withSuppliers => 'Avec Fournisseurs';

  @override
  String get userCode => 'Code Utilisateur';

  @override
  String get userName => 'Nom Utilisateur';

  @override
  String get totalUsers => 'Total Utilisateurs';

  @override
  String get adminUsers => 'Utilisateurs Admin';

  @override
  String get cashierUsers => 'Utilisateurs Caissier';

  @override
  String get storekeeperUsers => 'Utilisateurs Magasinier';

  @override
  String get roleCode => 'Code Rôle';

  @override
  String get totalRoles => 'Total Rôles';

  @override
  String get storeCode => 'Code Magasin';

  @override
  String get storeName => 'Nom Magasin';

  @override
  String get totalStores => 'Total Magasins';

  @override
  String get averageStorageRate => 'Taux Stockage Moyen';

  @override
  String get totalBalance => 'Solde Total';

  @override
  String get totalArticles => 'Total Articles';

  @override
  String get totalProductsInCategories => 'Total Produits dans les Catégories';

  @override
  String get averageProductsPerCategory => 'Moyenne Produits par Catégorie';

  @override
  String get totalUsage => 'Utilisation Totale';

  @override
  String get percentageDiscounts => 'Remises en Pourcentage';

  @override
  String get fixedDiscounts => 'Remises Fixes';

  @override
  String get averageDiscount => 'Remise Moyenne';

  @override
  String get totalProductsInPacks => 'Total Produits dans les Packs';

  @override
  String get totalValue => 'Valeur Totale';

  @override
  String get totalProductsInSubCategories =>
      'Total Produits dans les Sous-Catégories';

  @override
  String get averageProductsPerSubCategory =>
      'Moyenne Produits par Sous-Catégorie';

  @override
  String get incomingAmount => 'Montant Entrant';

  @override
  String get outgoingAmount => 'Montant Sortant';

  @override
  String get clientPayments => 'Paiements Clients';

  @override
  String get supplierPayments => 'Paiements Fournisseurs';

  @override
  String get averageQuantity => 'Quantité Moyenne';

  @override
  String get createdByCode => 'Code Créé Par';

  @override
  String get totalCalculatedAmount => 'Montant Total Calculé';

  @override
  String get totalCalculatedProducts => 'Produits Totaux Calculés';

  @override
  String get totalCalculatedQuantity => 'Quantité Totale Calculée';

  @override
  String get scansWithGap => 'Scans avec Écart';

  @override
  String get breakdownByType => 'Répartition par Type';

  @override
  String get count => 'Nombre';

  @override
  String get totalPurchaseValue => 'Valeur d\'Achat Totale';

  @override
  String get totalItems => 'Total Articles';

  @override
  String get averageItems => 'Moyenne Articles';

  @override
  String get totalSales => 'Total des Ventes';

  @override
  String get averageSalesPerUser => 'Ventes Moyennes par Utilisateur';

  @override
  String get averageUsersPerRole => 'Utilisateurs Moyens par Rôle';

  @override
  String get maxProducts => 'Max Produits';

  @override
  String get minProducts => 'Min Produits';

  @override
  String get cashRegisterCode => 'Code Caisse';

  @override
  String get totalCaisses => 'Total Caisses';

  @override
  String get averageBalance => 'Solde Moyen';

  @override
  String get storesWithCaisses => 'Magasins avec Caisses';

  @override
  String get insertions => 'Insertions';

  @override
  String get logins => 'Connexions';

  @override
  String get logouts => 'Déconnexions';

  @override
  String get totalZakatRecords => 'Total Enregistrements Zakat';

  @override
  String get totalZakatAmount => 'Montant Total Zakat';

  @override
  String get paidZakat => 'Zakat Payée';

  @override
  String get unpaidZakat => 'Zakat Non Payée';

  @override
  String get mandatoryZakat => 'Zakat Obligatoire';

  @override
  String get userInformation => 'Informations utilisateur';

  @override
  String get shopInformation => 'Informations magasin';

  @override
  String get systemSettings => 'Paramètres système';

  @override
  String get shopName => 'Nom du magasin';

  @override
  String get appId => 'ID de l\'application';

  @override
  String get language => 'Langue';

  @override
  String get reset => 'Réinitialiser';

  @override
  String get enterUsername => 'Entrez le nom d\'utilisateur';

  @override
  String get enterShopName => 'Entrez le nom du magasin';

  @override
  String get enterAppId => 'Entrez l\'ID de l\'application';

  @override
  String get settingsSaved => '✅ Paramètres enregistrés';

  @override
  String get currencye => 'Devise';

  @override
  String get operationFailed => 'L\'opération echoué';

  @override
  String get ticketSavedSuccess => 'Ticket enregistré';

  @override
  String get addProduct => 'Ajouter produit';

  @override
  String get mouvement => 'Mouvement';

  @override
  String get noPhotos => 'Pad de Photos';

  @override
  String get attention => 'Attention';

  @override
  String get salesprevious => 'Ventes (Précedent periode)';

  @override
  String get paye => 'Payé';

  @override
  String get reste => 'Reste';

  @override
  String get packagingPrix1 => 'Prix Emballage 1';

  @override
  String get packagingPrix2 => 'Prix Emballage 2';

  @override
  String get packagingPrice1Hint => 'Prix de boîte';

  @override
  String get packagingPrice2Hint => 'Prix de carton';

  @override
  String get lepannierestenregestre => 'Le pannier est bien enregistré';

  @override
  String get lepanniernestpasenregestre => 'l\'opération est échoué';

  @override
  String get marge => 'Marge';

  @override
  String get confirmPrint => 'Confirmation';

  @override
  String get aiMode => 'IA';

  @override
  String get aiModeDescription =>
      'Utilisez le bouton \'Nouveau\' pour scanner un reçu avec l\'IA';

  @override
  String get aiReceipt => 'Reçu IA';

  @override
  String get uploadReceipt => 'Importer un reçu';

  @override
  String get processing => 'Traitement en cours...';

  @override
  String get tapToSelectImage => 'Appuyez pour sélectionner une image';

  @override
  String get originalName => 'Nom d\'origine';

  @override
  String get mappedProduct => 'Produit associé';

  @override
  String get selectProduct => 'Sélectionnez un produit';

  @override
  String get addManualProduct => '+ Ajouter un produit manuellement';

  @override
  String get colis => 'Colis';

  @override
  String get actualQty => 'Actuel Quantité';

  @override
  String get quickEntry => 'Entrée rapide';

  @override
  String get cashReceipt => 'Recette caisse';

  @override
  String get cashReceiptTitle => 'Recette de la caisse';

  @override
  String get numberOfSales => 'Nombre de ventes';

  @override
  String get recentSales => 'Ventes récentes';

  @override
  String get noSalesFound => 'Aucune vente trouvée pour cette caisse';

  @override
  String get clearFilters => 'Supprimer filtre';

  @override
  String get selectStoreForProduct =>
      'Merci de sélectionner un magasin pour le destockage';

  @override
  String get requestedQuantity => 'Choisir la quantité';

  @override
  String get selectStore => 'Selectionné magasin';

  @override
  String discountAmountExceedsTotal(Object amount, Object total) {
    return 'Le montant de la remise ($amount) dépasse le total du panier ($total) !';
  }

  @override
  String get totalFinal => 'Total Final';

  @override
  String get totalBeforeDiscount => 'Total';

  @override
  String get quantityMustBeGreaterThanZero =>
      'La quantité doit être supérieure à 0';

  @override
  String get priceMustBeGreaterThanZero => 'Le prix doit être supérieur à 0';

  @override
  String get supplierRequired => 'Veuillez sélectionner un fournisseur';

  @override
  String get loading => 'Chargement...';

  @override
  String get saving => 'Enregistrement...';

  @override
  String get errorSavingSettings =>
      'Erreur lors de l\'enregistrement des paramètres';

  @override
  String get settingsReset => 'Paramètres réinitialisés';

  @override
  String get userNotFound => 'Utilisateur non trouvé';

  @override
  String get pleaseLoginFirst => 'Veuillez vous connecter d\'abord';

  @override
  String get rolePermissions => 'Permissions du rôle';

  @override
  String get selectAtLeastOnePermission =>
      'Veuillez sélectionner au moins une permission';

  @override
  String get warning => 'Attention';

  @override
  String get permissions => 'Permissions';

  @override
  String get permissionsDescription =>
      'Configurez les permissions pour ce rôle';

  @override
  String get selectPermissions => 'Permissions du rôle';

  @override
  String get selectAll => 'Tout sélectionner';

  @override
  String get deselectAll => 'Tout désélectionner';

  @override
  String get previous => 'Précédent';

  @override
  String get roleInfo => 'Informations du rôle';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit contenir au moins 4 caractères';

  @override
  String get valueMustBeGreaterThanZero => 'La valeur doit être supérieure à 0';

  @override
  String get sourceAndDestinationMustBeDifferent =>
      'La caisse source et la caisse de destination doivent être différentes.';
}
