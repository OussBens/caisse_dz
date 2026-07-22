import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de Bord'**
  String get dashboard;

  /// No description provided for @salesToday.
  ///
  /// In fr, this message translates to:
  /// **'Vente Aujourd\'hui'**
  String get salesToday;

  /// No description provided for @purchaseToday.
  ///
  /// In fr, this message translates to:
  /// **'Achat Aujourd\'hui'**
  String get purchaseToday;

  /// No description provided for @netToday.
  ///
  /// In fr, this message translates to:
  /// **'Net Aujourd\'hui'**
  String get netToday;

  /// No description provided for @supplierDebt.
  ///
  /// In fr, this message translates to:
  /// **'Créance Fournisseur'**
  String get supplierDebt;

  /// No description provided for @clientCredit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit Client'**
  String get clientCredit;

  /// No description provided for @selectPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez une période'**
  String get selectPeriod;

  /// No description provided for @salesByHour.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par heure'**
  String get salesByHour;

  /// No description provided for @salesByDay.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par jour'**
  String get salesByDay;

  /// No description provided for @salesByWeek.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par semaine'**
  String get salesByWeek;

  /// No description provided for @revenueByCashier.
  ///
  /// In fr, this message translates to:
  /// **'CA par Caissier'**
  String get revenueByCashier;

  /// No description provided for @salesByProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par Produit'**
  String get salesByProduct;

  /// No description provided for @salesByPaymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par mode de paiement'**
  String get salesByPaymentMethod;

  /// No description provided for @revenueDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Répartition CA'**
  String get revenueDistribution;

  /// No description provided for @collected.
  ///
  /// In fr, this message translates to:
  /// **'Encaissé'**
  String get collected;

  /// No description provided for @credit.
  ///
  /// In fr, this message translates to:
  /// **'Crédit'**
  String get credit;

  /// No description provided for @bestClients.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs Clients'**
  String get bestClients;

  /// No description provided for @bestSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Meilleurs Fournisseurs'**
  String get bestSuppliers;

  /// No description provided for @topCredits.
  ///
  /// In fr, this message translates to:
  /// **'Top Crédits'**
  String get topCredits;

  /// No description provided for @bestSellingProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits Plus Vendus'**
  String get bestSellingProducts;

  /// No description provided for @outOfStockProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits en Rupture'**
  String get outOfStockProducts;

  /// No description provided for @from.
  ///
  /// In fr, this message translates to:
  /// **'Du'**
  String get from;

  /// No description provided for @to.
  ///
  /// In fr, this message translates to:
  /// **'Au'**
  String get to;

  /// No description provided for @quickPeriod.
  ///
  /// In fr, this message translates to:
  /// **'Période rapide'**
  String get quickPeriod;

  /// No description provided for @export.
  ///
  /// In fr, this message translates to:
  /// **'Exporter'**
  String get export;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @today.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In fr, this message translates to:
  /// **'Hier'**
  String get yesterday;

  /// No description provided for @thisWeek.
  ///
  /// In fr, this message translates to:
  /// **'Cette semaine'**
  String get thisWeek;

  /// No description provided for @lastWeek.
  ///
  /// In fr, this message translates to:
  /// **'Semaine dernière'**
  String get lastWeek;

  /// No description provided for @thisMonth.
  ///
  /// In fr, this message translates to:
  /// **'Ce mois'**
  String get thisMonth;

  /// No description provided for @lastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get lastMonth;

  /// No description provided for @last7Days.
  ///
  /// In fr, this message translates to:
  /// **'7 derniers jours'**
  String get last7Days;

  /// No description provided for @last30Days.
  ///
  /// In fr, this message translates to:
  /// **'30 derniers jours'**
  String get last30Days;

  /// No description provided for @thisYear.
  ///
  /// In fr, this message translates to:
  /// **'Cette année'**
  String get thisYear;

  /// No description provided for @lastYear.
  ///
  /// In fr, this message translates to:
  /// **'Année dernière'**
  String get lastYear;

  /// No description provided for @caisse.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get caisse;

  /// No description provided for @produit.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get produit;

  /// No description provided for @panier.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get panier;

  /// No description provided for @client.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get client;

  /// No description provided for @fournisseur.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get fournisseur;

  /// No description provided for @entree.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get entree;

  /// No description provided for @sortie.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get sortie;

  /// No description provided for @retour.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get retour;

  /// No description provided for @stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @besoin.
  ///
  /// In fr, this message translates to:
  /// **'Besoin'**
  String get besoin;

  /// No description provided for @utilisateur.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get utilisateur;

  /// No description provided for @magasin.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get magasin;

  /// No description provided for @gestionCaisse.
  ///
  /// In fr, this message translates to:
  /// **'Gestion Caisse'**
  String get gestionCaisse;

  /// No description provided for @zakat.
  ///
  /// In fr, this message translates to:
  /// **'Zakat'**
  String get zakat;

  /// No description provided for @parametre.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre'**
  String get parametre;

  /// No description provided for @historique.
  ///
  /// In fr, this message translates to:
  /// **'Historique'**
  String get historique;

  /// No description provided for @pinSidebar.
  ///
  /// In fr, this message translates to:
  /// **'Épingler la barre'**
  String get pinSidebar;

  /// No description provided for @unpinSidebar.
  ///
  /// In fr, this message translates to:
  /// **'Désépingler la barre'**
  String get unpinSidebar;

  /// No description provided for @payment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get payment;

  /// No description provided for @remise.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get remise;

  /// No description provided for @sousCategorie.
  ///
  /// In fr, this message translates to:
  /// **'Sous catégorie'**
  String get sousCategorie;

  /// No description provided for @hideProduct.
  ///
  /// In fr, this message translates to:
  /// **'Masquer produit'**
  String get hideProduct;

  /// No description provided for @showProduct.
  ///
  /// In fr, this message translates to:
  /// **'Afficher produit'**
  String get showProduct;

  /// No description provided for @noProductSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit sélectionné'**
  String get noProductSelected;

  /// No description provided for @cannotDeleteLastCaisse.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer la dernière caisse'**
  String get cannotDeleteLastCaisse;

  /// No description provided for @deleteCaisseTitle.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la caisse'**
  String get deleteCaisseTitle;

  /// No description provided for @deleteCaisseMessage.
  ///
  /// In fr, this message translates to:
  /// **'Merci de confirmer la suppression de {caisseName}. Tous les paniers seront perdus.'**
  String deleteCaisseMessage(Object caisseName);

  /// No description provided for @clearCartTitle.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get clearCartTitle;

  /// No description provided for @clearCartMessage.
  ///
  /// In fr, this message translates to:
  /// **'Merci de confirmer la suppression de tous les produits du panier'**
  String get clearCartMessage;

  /// No description provided for @emptyCartError.
  ///
  /// In fr, this message translates to:
  /// **'❌ Panier vide'**
  String get emptyCartError;

  /// No description provided for @emptyCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier vide'**
  String get emptyCart;

  /// No description provided for @addProductsToStart.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez des produits pour commencer'**
  String get addProductsToStart;

  /// No description provided for @maxCaissesReached.
  ///
  /// In fr, this message translates to:
  /// **'Maximum 10 caisses actives'**
  String get maxCaissesReached;

  /// No description provided for @loadingParams.
  ///
  /// In fr, this message translates to:
  /// **'Chargement des paramètres...'**
  String get loadingParams;

  /// No description provided for @settingsSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres enregistrés avec succès'**
  String get settingsSavedSuccess;

  /// No description provided for @encaisserTicket.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser Ticket'**
  String get encaisserTicket;

  /// No description provided for @enregistrer.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get enregistrer;

  /// No description provided for @encaisserBLSC.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser BL/SC'**
  String get encaisserBLSC;

  /// No description provided for @annuler.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get annuler;

  /// No description provided for @serverError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur du serveur !'**
  String get serverError;

  /// No description provided for @noResultsFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun résultat trouvé.'**
  String get noResultsFound;

  /// No description provided for @besoinList.
  ///
  /// In fr, this message translates to:
  /// **'BesoinList'**
  String get besoinList;

  /// No description provided for @categorie.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get categorie;

  /// No description provided for @dash.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de Bord'**
  String get dash;

  /// No description provided for @pack.
  ///
  /// In fr, this message translates to:
  /// **'Pack'**
  String get pack;

  /// No description provided for @parametreProduit.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre produit'**
  String get parametreProduit;

  /// No description provided for @parametreCaisse.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre caisse'**
  String get parametreCaisse;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @sCategorie.
  ///
  /// In fr, this message translates to:
  /// **'S_Catégorie'**
  String get sCategorie;

  /// No description provided for @transfert.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get transfert;

  /// No description provided for @versement.
  ///
  /// In fr, this message translates to:
  /// **'Versement'**
  String get versement;

  /// No description provided for @achat.
  ///
  /// In fr, this message translates to:
  /// **'achat'**
  String get achat;

  /// No description provided for @vente.
  ///
  /// In fr, this message translates to:
  /// **'vente'**
  String get vente;

  /// No description provided for @insertion.
  ///
  /// In fr, this message translates to:
  /// **'insertion'**
  String get insertion;

  /// No description provided for @modification.
  ///
  /// In fr, this message translates to:
  /// **'modification'**
  String get modification;

  /// No description provided for @suppression.
  ///
  /// In fr, this message translates to:
  /// **'suppression'**
  String get suppression;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In fr, this message translates to:
  /// **'logout'**
  String get logout;

  /// No description provided for @actif.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get actif;

  /// No description provided for @inactif.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactif;

  /// No description provided for @valide.
  ///
  /// In fr, this message translates to:
  /// **'Validé'**
  String get valide;

  /// No description provided for @annule.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get annule;

  /// No description provided for @parMontant.
  ///
  /// In fr, this message translates to:
  /// **'Par Montant'**
  String get parMontant;

  /// No description provided for @parProduit.
  ///
  /// In fr, this message translates to:
  /// **'Par Produit'**
  String get parProduit;

  /// No description provided for @enAttente.
  ///
  /// In fr, this message translates to:
  /// **'En Attente'**
  String get enAttente;

  /// No description provided for @commande.
  ///
  /// In fr, this message translates to:
  /// **'Commande'**
  String get commande;

  /// No description provided for @disponible.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get disponible;

  /// No description provided for @expiration.
  ///
  /// In fr, this message translates to:
  /// **'Expiration'**
  String get expiration;

  /// No description provided for @don.
  ///
  /// In fr, this message translates to:
  /// **'Don'**
  String get don;

  /// No description provided for @montant.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get montant;

  /// No description provided for @pourcentage.
  ///
  /// In fr, this message translates to:
  /// **'Pourcentage'**
  String get pourcentage;

  /// No description provided for @bl.
  ///
  /// In fr, this message translates to:
  /// **'BL'**
  String get bl;

  /// No description provided for @blSc.
  ///
  /// In fr, this message translates to:
  /// **'BL_SC'**
  String get blSc;

  /// No description provided for @physique.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get physique;

  /// No description provided for @compte.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get compte;

  /// No description provided for @piece.
  ///
  /// In fr, this message translates to:
  /// **'Pièce'**
  String get piece;

  /// No description provided for @litre.
  ///
  /// In fr, this message translates to:
  /// **'Litre'**
  String get litre;

  /// No description provided for @metre.
  ///
  /// In fr, this message translates to:
  /// **'Mètre'**
  String get metre;

  /// No description provided for @avancement.
  ///
  /// In fr, this message translates to:
  /// **'Avancement'**
  String get avancement;

  /// No description provided for @complementFacture.
  ///
  /// In fr, this message translates to:
  /// **'Complément de facture'**
  String get complementFacture;

  /// No description provided for @dette.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get dette;

  /// No description provided for @paiement.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paiement;

  /// No description provided for @remboursement.
  ///
  /// In fr, this message translates to:
  /// **'Remboursement'**
  String get remboursement;

  /// No description provided for @acompte.
  ///
  /// In fr, this message translates to:
  /// **'Acompte'**
  String get acompte;

  /// No description provided for @remiseVersement.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get remiseVersement;

  /// No description provided for @especes.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get especes;

  /// No description provided for @carte.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get carte;

  /// No description provided for @cheque.
  ///
  /// In fr, this message translates to:
  /// **'Chèque'**
  String get cheque;

  /// No description provided for @usine.
  ///
  /// In fr, this message translates to:
  /// **'Usine'**
  String get usine;

  /// No description provided for @societe.
  ///
  /// In fr, this message translates to:
  /// **'Société'**
  String get societe;

  /// No description provided for @importateur.
  ///
  /// In fr, this message translates to:
  /// **'Importateur'**
  String get importateur;

  /// No description provided for @grossiste.
  ///
  /// In fr, this message translates to:
  /// **'Grossiste'**
  String get grossiste;

  /// No description provided for @semiGrossiste.
  ///
  /// In fr, this message translates to:
  /// **'Semi-Grossiste'**
  String get semiGrossiste;

  /// No description provided for @detailant.
  ///
  /// In fr, this message translates to:
  /// **'Détaillant'**
  String get detailant;

  /// No description provided for @consommateur.
  ///
  /// In fr, this message translates to:
  /// **'Consommateur'**
  String get consommateur;

  /// No description provided for @destockage.
  ///
  /// In fr, this message translates to:
  /// **'Déstockage'**
  String get destockage;

  /// No description provided for @cosmetique.
  ///
  /// In fr, this message translates to:
  /// **'Cosmétique'**
  String get cosmetique;

  /// No description provided for @alimentation.
  ///
  /// In fr, this message translates to:
  /// **'Alimentation'**
  String get alimentation;

  /// No description provided for @quincaillerie.
  ///
  /// In fr, this message translates to:
  /// **'Quincaillerie'**
  String get quincaillerie;

  /// No description provided for @electromenager.
  ///
  /// In fr, this message translates to:
  /// **'Électroménager'**
  String get electromenager;

  /// No description provided for @hygieneNettoyage.
  ///
  /// In fr, this message translates to:
  /// **'Hygiène & Nettoyage'**
  String get hygieneNettoyage;

  /// No description provided for @textileHabillement.
  ///
  /// In fr, this message translates to:
  /// **'Textile & Habillement'**
  String get textileHabillement;

  /// No description provided for @materiauxConstruction.
  ///
  /// In fr, this message translates to:
  /// **'Matériaux de construction'**
  String get materiauxConstruction;

  /// No description provided for @papeterieFournitures.
  ///
  /// In fr, this message translates to:
  /// **'Papeterie & Fournitures'**
  String get papeterieFournitures;

  /// No description provided for @piecesAutomobiles.
  ///
  /// In fr, this message translates to:
  /// **'Pièces automobiles'**
  String get piecesAutomobiles;

  /// No description provided for @informatiqueAccessoires.
  ///
  /// In fr, this message translates to:
  /// **'Informatique & Accessoires'**
  String get informatiqueAccessoires;

  /// No description provided for @telephonie.
  ///
  /// In fr, this message translates to:
  /// **'Téléphonie'**
  String get telephonie;

  /// No description provided for @meublesDecoration.
  ///
  /// In fr, this message translates to:
  /// **'Meubles & Décoration'**
  String get meublesDecoration;

  /// No description provided for @produitsAgricoles.
  ///
  /// In fr, this message translates to:
  /// **'Produits agricoles'**
  String get produitsAgricoles;

  /// No description provided for @produitsMenagers.
  ///
  /// In fr, this message translates to:
  /// **'Produits ménagers'**
  String get produitsMenagers;

  /// No description provided for @boulangeriePatisserie.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie / Pâtisserie'**
  String get boulangeriePatisserie;

  /// No description provided for @bazar.
  ///
  /// In fr, this message translates to:
  /// **'Bazar'**
  String get bazar;

  /// No description provided for @jouets.
  ///
  /// In fr, this message translates to:
  /// **'Jouets'**
  String get jouets;

  /// No description provided for @produitsMedicaux.
  ///
  /// In fr, this message translates to:
  /// **'Produits médicaux non pharmaceutiques'**
  String get produitsMedicaux;

  /// No description provided for @particulier.
  ///
  /// In fr, this message translates to:
  /// **'Particulier'**
  String get particulier;

  /// No description provided for @epicerie.
  ///
  /// In fr, this message translates to:
  /// **'Épicerie'**
  String get epicerie;

  /// No description provided for @superette.
  ///
  /// In fr, this message translates to:
  /// **'Superette'**
  String get superette;

  /// No description provided for @salonCoiffure.
  ///
  /// In fr, this message translates to:
  /// **'Salon de coiffure'**
  String get salonCoiffure;

  /// No description provided for @institutBeaute.
  ///
  /// In fr, this message translates to:
  /// **'Institut de beauté'**
  String get institutBeaute;

  /// No description provided for @boutiqueVetements.
  ///
  /// In fr, this message translates to:
  /// **'Boutique de vêtements'**
  String get boutiqueVetements;

  /// No description provided for @boulangerie.
  ///
  /// In fr, this message translates to:
  /// **'Boulangerie'**
  String get boulangerie;

  /// No description provided for @cafeteriaFastFood.
  ///
  /// In fr, this message translates to:
  /// **'Cafétéria / Fast-food'**
  String get cafeteriaFastFood;

  /// No description provided for @restaurant.
  ///
  /// In fr, this message translates to:
  /// **'Restaurant'**
  String get restaurant;

  /// No description provided for @cafe.
  ///
  /// In fr, this message translates to:
  /// **'Café'**
  String get cafe;

  /// No description provided for @magasinElectromenager.
  ///
  /// In fr, this message translates to:
  /// **'Magasin électroménager'**
  String get magasinElectromenager;

  /// No description provided for @pharmacie.
  ///
  /// In fr, this message translates to:
  /// **'Pharmacie'**
  String get pharmacie;

  /// No description provided for @magasinJouets.
  ///
  /// In fr, this message translates to:
  /// **'Magasin de jouets'**
  String get magasinJouets;

  /// No description provided for @boutiqueTelephonie.
  ///
  /// In fr, this message translates to:
  /// **'Boutique téléphonie'**
  String get boutiqueTelephonie;

  /// No description provided for @garagePiecesAuto.
  ///
  /// In fr, this message translates to:
  /// **'Garage / Pièces auto'**
  String get garagePiecesAuto;

  /// No description provided for @magasinInformatique.
  ///
  /// In fr, this message translates to:
  /// **'Magasin informatique'**
  String get magasinInformatique;

  /// No description provided for @admin.
  ///
  /// In fr, this message translates to:
  /// **'Admin'**
  String get admin;

  /// No description provided for @caissier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get caissier;

  /// No description provided for @magasinier.
  ///
  /// In fr, this message translates to:
  /// **'Magasinier'**
  String get magasinier;

  /// No description provided for @autre.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get autre;

  /// No description provided for @ticket.
  ///
  /// In fr, this message translates to:
  /// **'Ticket'**
  String get ticket;

  /// No description provided for @virement.
  ///
  /// In fr, this message translates to:
  /// **'virement'**
  String get virement;

  /// No description provided for @parfumerie.
  ///
  /// In fr, this message translates to:
  /// **'parfumerie'**
  String get parfumerie;

  /// No description provided for @information.
  ///
  /// In fr, this message translates to:
  /// **'Information'**
  String get information;

  /// No description provided for @noCategorySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune catégorie sélectionnée'**
  String get noCategorySelected;

  /// No description provided for @selectSingleCategoryForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule catégorie pour afficher le détail'**
  String get selectSingleCategoryForDetail;

  /// No description provided for @cannotDeleteSystemCategory.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer cette catégorie (Système)'**
  String get cannotDeleteSystemCategory;

  /// No description provided for @cannotModifySystemCategory.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier cette catégorie (Système)'**
  String get cannotModifySystemCategory;

  /// No description provided for @selectSingleCategoryToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule catégorie pour modifier'**
  String get selectSingleCategoryToModify;

  /// No description provided for @noDiscountSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune remise sélectionnée'**
  String get noDiscountSelected;

  /// No description provided for @selectSingleDiscountForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule remise pour afficher le détail'**
  String get selectSingleDiscountForDetail;

  /// No description provided for @selectSingleDiscountToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule remise pour modifier'**
  String get selectSingleDiscountToModify;

  /// No description provided for @noPackSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun pack sélectionné'**
  String get noPackSelected;

  /// No description provided for @selectSinglePackForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul pack pour afficher le détail'**
  String get selectSinglePackForDetail;

  /// No description provided for @selectSinglePackToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul pack pour modifier'**
  String get selectSinglePackToModify;

  /// No description provided for @noSubCategorySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune sous-catégorie sélectionnée'**
  String get noSubCategorySelected;

  /// No description provided for @selectSingleSubCategoryForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule sous-catégorie pour afficher le détail'**
  String get selectSingleSubCategoryForDetail;

  /// No description provided for @cannotDeleteSystemSubCategory.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer cette sous-catégorie (Système)'**
  String get cannotDeleteSystemSubCategory;

  /// No description provided for @cannotModifySystemSubCategory.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier cette sous-catégorie (Système)'**
  String get cannotModifySystemSubCategory;

  /// No description provided for @selectSingleSubCategoryToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule sous-catégorie pour modifier'**
  String get selectSingleSubCategoryToModify;

  /// No description provided for @filter.
  ///
  /// In fr, this message translates to:
  /// **'Filtre'**
  String get filter;

  /// No description provided for @newWord.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newWord;

  /// No description provided for @margin.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get margin;

  /// No description provided for @typeCalcul.
  ///
  /// In fr, this message translates to:
  /// **'Type Calcul'**
  String get typeCalcul;

  /// No description provided for @marginRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de Marge'**
  String get marginRate;

  /// No description provided for @threshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil'**
  String get threshold;

  /// No description provided for @minimum.
  ///
  /// In fr, this message translates to:
  /// **'Minimum'**
  String get minimum;

  /// No description provided for @maximum.
  ///
  /// In fr, this message translates to:
  /// **'Maximum'**
  String get maximum;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarder'**
  String get save;

  /// No description provided for @by.
  ///
  /// In fr, this message translates to:
  /// **'par'**
  String get by;

  /// No description provided for @purchasePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Achat'**
  String get purchasePrice;

  /// No description provided for @salePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Vente'**
  String get salePrice;

  /// No description provided for @etat.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get etat;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Recherche'**
  String get search;

  /// No description provided for @marque.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get marque;

  /// No description provided for @currency.
  ///
  /// In fr, this message translates to:
  /// **'DA'**
  String get currency;

  /// No description provided for @needCategoryToCreateSubCategory.
  ///
  /// In fr, this message translates to:
  /// **'Pour créer une sous-catégorie vous devez avoir au moins une catégorie (Sans catégorie n\'est pas inclus)'**
  String get needCategoryToCreateSubCategory;

  /// No description provided for @selectSingleProductForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul produit pour afficher le détail'**
  String get selectSingleProductForDetail;

  /// No description provided for @selectSingleProductToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul produit pour modifier'**
  String get selectSingleProductToModify;

  /// No description provided for @typePannier.
  ///
  /// In fr, this message translates to:
  /// **'Type Panier'**
  String get typePannier;

  /// No description provided for @amount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get amount;

  /// No description provided for @remaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get remaining;

  /// No description provided for @startDate.
  ///
  /// In fr, this message translates to:
  /// **'Date début'**
  String get startDate;

  /// No description provided for @endDate.
  ///
  /// In fr, this message translates to:
  /// **'Date fin'**
  String get endDate;

  /// No description provided for @choosePeriod.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une période'**
  String get choosePeriod;

  /// No description provided for @noCartSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun panier sélectionné'**
  String get noCartSelected;

  /// No description provided for @selectSingleCartForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul panier pour afficher le détail'**
  String get selectSingleCartForDetail;

  /// No description provided for @selectSingleCartToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul panier pour modifier'**
  String get selectSingleCartToModify;

  /// No description provided for @typeClient.
  ///
  /// In fr, this message translates to:
  /// **'Type Client'**
  String get typeClient;

  /// No description provided for @activite.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get activite;

  /// No description provided for @totalAchat.
  ///
  /// In fr, this message translates to:
  /// **'Total Achat'**
  String get totalAchat;

  /// No description provided for @noClientSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun client sélectionné'**
  String get noClientSelected;

  /// No description provided for @selectSingleClientForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul client pour afficher le détail'**
  String get selectSingleClientForDetail;

  /// No description provided for @cannotDeleteSystemClient.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer ce client système'**
  String get cannotDeleteSystemClient;

  /// No description provided for @cannotModifySystemClient.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier ce client système'**
  String get cannotModifySystemClient;

  /// No description provided for @selectSingleClientToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul client pour modifier'**
  String get selectSingleClientToModify;

  /// No description provided for @selectSingleClientForOperations.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul client pour afficher ses opérations'**
  String get selectSingleClientForOperations;

  /// No description provided for @noPaymentSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun versement sélectionné'**
  String get noPaymentSelected;

  /// No description provided for @selectSinglePaymentToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul versement pour modifier'**
  String get selectSinglePaymentToModify;

  /// No description provided for @exit.
  ///
  /// In fr, this message translates to:
  /// **'Sortie'**
  String get exit;

  /// No description provided for @type.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @noListSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune liste sélectionnée'**
  String get noListSelected;

  /// No description provided for @selectSingleListForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule liste pour afficher le détail'**
  String get selectSingleListForDetail;

  /// No description provided for @selectSingleListToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule liste pour modifier'**
  String get selectSingleListToModify;

  /// No description provided for @noUserSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun utilisateur sélectionné'**
  String get noUserSelected;

  /// No description provided for @selectSingleUserForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul utilisateur pour afficher le détail'**
  String get selectSingleUserForDetail;

  /// No description provided for @selectSingleUserToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul utilisateur pour modifier'**
  String get selectSingleUserToModify;

  /// No description provided for @noRoleSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rôle sélectionné'**
  String get noRoleSelected;

  /// No description provided for @selectSingleRoleForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul rôle pour afficher le détail'**
  String get selectSingleRoleForDetail;

  /// No description provided for @selectSingleRoleToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul rôle pour modifier'**
  String get selectSingleRoleToModify;

  /// No description provided for @error.
  ///
  /// In fr, this message translates to:
  /// **'Erreur'**
  String get error;

  /// No description provided for @loadingError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de chargement des données'**
  String get loadingError;

  /// No description provided for @sourceCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Caisse Src'**
  String get sourceCashRegister;

  /// No description provided for @destinationCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Caisse Dest'**
  String get destinationCashRegister;

  /// No description provided for @newCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Caisse'**
  String get newCashRegister;

  /// No description provided for @newTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Transfert'**
  String get newTransfer;

  /// No description provided for @noCashRegisterSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune caisse sélectionnée'**
  String get noCashRegisterSelected;

  /// No description provided for @selectSingleCashRegisterForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule caisse pour afficher le détail'**
  String get selectSingleCashRegisterForDetail;

  /// No description provided for @selectSingleCashRegisterToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule caisse pour modifier'**
  String get selectSingleCashRegisterToModify;

  /// No description provided for @cannotDeleteSystemCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer cette caisse (système)'**
  String get cannotDeleteSystemCashRegister;

  /// No description provided for @cannotModifySystemCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier cette caisse (système)'**
  String get cannotModifySystemCashRegister;

  /// No description provided for @noTransferSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun transfert sélectionné'**
  String get noTransferSelected;

  /// No description provided for @selectSingleTransferForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul transfert pour afficher le détail'**
  String get selectSingleTransferForDetail;

  /// No description provided for @selectSingleTransferToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul transfert pour modifier'**
  String get selectSingleTransferToModify;

  /// No description provided for @productCount.
  ///
  /// In fr, this message translates to:
  /// **'Nb Produit'**
  String get productCount;

  /// No description provided for @noStoreSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin sélectionné'**
  String get noStoreSelected;

  /// No description provided for @selectSingleStoreForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul magasin pour afficher le détail'**
  String get selectSingleStoreForDetail;

  /// No description provided for @selectSingleStoreToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul magasin pour modifier'**
  String get selectSingleStoreToModify;

  /// No description provided for @cannotDeleteSystemStore.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer ce magasin (Système)'**
  String get cannotDeleteSystemStore;

  /// No description provided for @cannotModifySystemStore.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de modifier ce magasin (Système)'**
  String get cannotModifySystemStore;

  /// No description provided for @zakatParameter.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre Zakat'**
  String get zakatParameter;

  /// No description provided for @nissab.
  ///
  /// In fr, this message translates to:
  /// **'Nissab'**
  String get nissab;

  /// No description provided for @zakatRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux Zakat'**
  String get zakatRate;

  /// No description provided for @zakatPaid.
  ///
  /// In fr, this message translates to:
  /// **'Zakat Payée'**
  String get zakatPaid;

  /// No description provided for @zakatUnpaid.
  ///
  /// In fr, this message translates to:
  /// **'Zakat Non Payée'**
  String get zakatUnpaid;

  /// No description provided for @totalZakat.
  ///
  /// In fr, this message translates to:
  /// **'Total Zakat'**
  String get totalZakat;

  /// No description provided for @state.
  ///
  /// In fr, this message translates to:
  /// **'État'**
  String get state;

  /// No description provided for @settingsNotSaved.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres non sauvegardés'**
  String get settingsNotSaved;

  /// No description provided for @noZakatSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun zakat sélectionné'**
  String get noZakatSelected;

  /// No description provided for @selectSingleZakatForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul zakat pour afficher le détail'**
  String get selectSingleZakatForDetail;

  /// No description provided for @selectSingleZakatToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul zakat pour modifier'**
  String get selectSingleZakatToModify;

  /// No description provided for @period.
  ///
  /// In fr, this message translates to:
  /// **'Période'**
  String get period;

  /// No description provided for @zakatDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Zakat'**
  String get zakatDetail;

  /// No description provided for @zakatModify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Zakat'**
  String get zakatModify;

  /// No description provided for @zakatNew.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Zakat'**
  String get zakatNew;

  /// No description provided for @zakatCancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler Zakat'**
  String get zakatCancel;

  /// No description provided for @modificationOf.
  ///
  /// In fr, this message translates to:
  /// **'Modification de'**
  String get modificationOf;

  /// No description provided for @parameter.
  ///
  /// In fr, this message translates to:
  /// **'Paramètre'**
  String get parameter;

  /// No description provided for @date.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @status.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get status;

  /// No description provided for @paid.
  ///
  /// In fr, this message translates to:
  /// **'Payée'**
  String get paid;

  /// No description provided for @unpaid.
  ///
  /// In fr, this message translates to:
  /// **'Non Payée'**
  String get unpaid;

  /// No description provided for @creances.
  ///
  /// In fr, this message translates to:
  /// **'Créances'**
  String get creances;

  /// No description provided for @montantZakat.
  ///
  /// In fr, this message translates to:
  /// **'Montant Zakat'**
  String get montantZakat;

  /// No description provided for @dateDebutHawl.
  ///
  /// In fr, this message translates to:
  /// **'Date Début Hawl'**
  String get dateDebutHawl;

  /// No description provided for @typeOperation.
  ///
  /// In fr, this message translates to:
  /// **'Type opération'**
  String get typeOperation;

  /// No description provided for @operationOn.
  ///
  /// In fr, this message translates to:
  /// **'Opération sur'**
  String get operationOn;

  /// No description provided for @noHistoriqueSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun historique sélectionné'**
  String get noHistoriqueSelected;

  /// No description provided for @selectSingleHistoriqueForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un seul historique pour afficher le détail'**
  String get selectSingleHistoriqueForDetail;

  /// No description provided for @historiqueDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Historique'**
  String get historiqueDetail;

  /// No description provided for @operation.
  ///
  /// In fr, this message translates to:
  /// **'Opération'**
  String get operation;

  /// No description provided for @description.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @createdBy.
  ///
  /// In fr, this message translates to:
  /// **'Créé par'**
  String get createdBy;

  /// No description provided for @dateCreated.
  ///
  /// In fr, this message translates to:
  /// **'Date création'**
  String get dateCreated;

  /// No description provided for @profile.
  ///
  /// In fr, this message translates to:
  /// **'Profil'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @myAccount.
  ///
  /// In fr, this message translates to:
  /// **'Mon Compte'**
  String get myAccount;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @clear.
  ///
  /// In fr, this message translates to:
  /// **'CL'**
  String get clear;

  /// No description provided for @newClient.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Client'**
  String get newClient;

  /// No description provided for @newProduct.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Produit'**
  String get newProduct;

  /// No description provided for @discount.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get discount;

  /// No description provided for @cashTicket.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser Ticket'**
  String get cashTicket;

  /// No description provided for @cashBLSC.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser BL/SC'**
  String get cashBLSC;

  /// No description provided for @saveTicket.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer Ticket'**
  String get saveTicket;

  /// No description provided for @cancelCart.
  ///
  /// In fr, this message translates to:
  /// **'Annuler Panier'**
  String get cancelCart;

  /// No description provided for @clearEntry.
  ///
  /// In fr, this message translates to:
  /// **'Effacer'**
  String get clearEntry;

  /// No description provided for @deleteCart.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Caisse'**
  String get deleteCart;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @chooseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Choisir une catégorie'**
  String get chooseCategory;

  /// No description provided for @product.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get product;

  /// No description provided for @all.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get all;

  /// No description provided for @exampleRange.
  ///
  /// In fr, this message translates to:
  /// **'Ex:100->200'**
  String get exampleRange;

  /// No description provided for @min.
  ///
  /// In fr, this message translates to:
  /// **'Min'**
  String get min;

  /// No description provided for @max.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get max;

  /// No description provided for @validate.
  ///
  /// In fr, this message translates to:
  /// **'Valider'**
  String get validate;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @code.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Qt'**
  String get quantity;

  /// No description provided for @showHideColumns.
  ///
  /// In fr, this message translates to:
  /// **'Afficher / Masquer les colonnes'**
  String get showHideColumns;

  /// No description provided for @none.
  ///
  /// In fr, this message translates to:
  /// **'Aucun'**
  String get none;

  /// No description provided for @keepSelection.
  ///
  /// In fr, this message translates to:
  /// **'Garder la sélection'**
  String get keepSelection;

  /// No description provided for @apply.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer'**
  String get apply;

  /// No description provided for @page.
  ///
  /// In fr, this message translates to:
  /// **'Page'**
  String get page;

  /// No description provided for @rowsPerPage.
  ///
  /// In fr, this message translates to:
  /// **'lignes / page'**
  String get rowsPerPage;

  /// No description provided for @selectDate.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner {date}'**
  String selectDate(Object date);

  /// No description provided for @selectDatew.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner date'**
  String get selectDatew;

  /// No description provided for @select.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner'**
  String get select;

  /// No description provided for @auto.
  ///
  /// In fr, this message translates to:
  /// **'Auto'**
  String get auto;

  /// No description provided for @requiredField.
  ///
  /// In fr, this message translates to:
  /// **'Champ obligatoire'**
  String get requiredField;

  /// No description provided for @maValue.
  ///
  /// In fr, this message translates to:
  /// **'Max'**
  String get maValue;

  /// No description provided for @inStock.
  ///
  /// In fr, this message translates to:
  /// **'Qnt'**
  String get inStock;

  /// No description provided for @addManually.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter manuellement'**
  String get addManually;

  /// No description provided for @number.
  ///
  /// In fr, this message translates to:
  /// **'N°'**
  String get number;

  /// No description provided for @articles.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get articles;

  /// No description provided for @supplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get supplier;

  /// No description provided for @details.
  ///
  /// In fr, this message translates to:
  /// **'Détails'**
  String get details;

  /// No description provided for @products.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get products;

  /// No description provided for @totalPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Total achats'**
  String get totalPurchases;

  /// No description provided for @payments.
  ///
  /// In fr, this message translates to:
  /// **'Versements'**
  String get payments;

  /// No description provided for @totalCredit.
  ///
  /// In fr, this message translates to:
  /// **'Total crédit'**
  String get totalCredit;

  /// No description provided for @creditOf.
  ///
  /// In fr, this message translates to:
  /// **'Crédit {amount} de client {client}'**
  String creditOf(Object amount, Object client);

  /// No description provided for @best.
  ///
  /// In fr, this message translates to:
  /// **'Meilleur'**
  String get best;

  /// No description provided for @averagePurchase.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne d\'achat'**
  String get averagePurchase;

  /// No description provided for @ofClient.
  ///
  /// In fr, this message translates to:
  /// **'de client'**
  String get ofClient;

  /// No description provided for @store.
  ///
  /// In fr, this message translates to:
  /// **'Magasin'**
  String get store;

  /// No description provided for @initialBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde initial'**
  String get initialBalance;

  /// No description provided for @obs.
  ///
  /// In fr, this message translates to:
  /// **'Obs'**
  String get obs;

  /// No description provided for @operations.
  ///
  /// In fr, this message translates to:
  /// **'Opérations'**
  String get operations;

  /// No description provided for @creations.
  ///
  /// In fr, this message translates to:
  /// **'Créations'**
  String get creations;

  /// No description provided for @adds.
  ///
  /// In fr, this message translates to:
  /// **'Ajouts'**
  String get adds;

  /// No description provided for @modifications.
  ///
  /// In fr, this message translates to:
  /// **'Modifications'**
  String get modifications;

  /// No description provided for @updates.
  ///
  /// In fr, this message translates to:
  /// **'Mises à jour'**
  String get updates;

  /// No description provided for @deletions.
  ///
  /// In fr, this message translates to:
  /// **'Suppressions'**
  String get deletions;

  /// No description provided for @deletedItems.
  ///
  /// In fr, this message translates to:
  /// **'Éléments supprimés'**
  String get deletedItems;

  /// No description provided for @todayOperations.
  ///
  /// In fr, this message translates to:
  /// **'Opérations du jour'**
  String get todayOperations;

  /// No description provided for @lastUser.
  ///
  /// In fr, this message translates to:
  /// **'Dernier User'**
  String get lastUser;

  /// No description provided for @lastAction.
  ///
  /// In fr, this message translates to:
  /// **'Dernière action'**
  String get lastAction;

  /// No description provided for @stockRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux stockage'**
  String get stockRate;

  /// No description provided for @time.
  ///
  /// In fr, this message translates to:
  /// **'Heure'**
  String get time;

  /// No description provided for @totalPaniers.
  ///
  /// In fr, this message translates to:
  /// **'Total paniers'**
  String get totalPaniers;

  /// No description provided for @allCarts.
  ///
  /// In fr, this message translates to:
  /// **'Tous les paniers'**
  String get allCarts;

  /// No description provided for @totalCartAmount.
  ///
  /// In fr, this message translates to:
  /// **'Total panier'**
  String get totalCartAmount;

  /// No description provided for @sumOfAllCarts.
  ///
  /// In fr, this message translates to:
  /// **'Somme de tous les paniers'**
  String get sumOfAllCarts;

  /// No description provided for @starProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit star'**
  String get starProduct;

  /// No description provided for @times.
  ///
  /// In fr, this message translates to:
  /// **'fois'**
  String get times;

  /// No description provided for @averagePerCart.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne par panier'**
  String get averagePerCart;

  /// No description provided for @averageValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur moyenne'**
  String get averageValue;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'RUPTURE'**
  String get outOfStock;

  /// No description provided for @unit.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get unit;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @subcategories.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégories'**
  String get subcategories;

  /// No description provided for @packs.
  ///
  /// In fr, this message translates to:
  /// **'Packs'**
  String get packs;

  /// No description provided for @discounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises'**
  String get discounts;

  /// No description provided for @registeredProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits enregistrés'**
  String get registeredProducts;

  /// No description provided for @productTypes.
  ///
  /// In fr, this message translates to:
  /// **'Types de produits'**
  String get productTypes;

  /// No description provided for @secondaryLevels.
  ///
  /// In fr, this message translates to:
  /// **'Niveaux secondaires'**
  String get secondaryLevels;

  /// No description provided for @bundledOffers.
  ///
  /// In fr, this message translates to:
  /// **'Offres groupées'**
  String get bundledOffers;

  /// No description provided for @activeDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises actives'**
  String get activeDiscounts;

  /// No description provided for @actualStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock réel'**
  String get actualStock;

  /// No description provided for @theoreticalStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock théorique'**
  String get theoreticalStock;

  /// No description provided for @totalPurchased.
  ///
  /// In fr, this message translates to:
  /// **'Total acheté'**
  String get totalPurchased;

  /// No description provided for @totalSold.
  ///
  /// In fr, this message translates to:
  /// **'Total vendu'**
  String get totalSold;

  /// No description provided for @returns.
  ///
  /// In fr, this message translates to:
  /// **'Retours'**
  String get returns;

  /// No description provided for @lastPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Dernier achat'**
  String get lastPurchase;

  /// No description provided for @validated.
  ///
  /// In fr, this message translates to:
  /// **'VALIDÉ'**
  String get validated;

  /// No description provided for @pending.
  ///
  /// In fr, this message translates to:
  /// **'EN ATTENTE'**
  String get pending;

  /// No description provided for @waiting.
  ///
  /// In fr, this message translates to:
  /// **'ATTENTE'**
  String get waiting;

  /// No description provided for @yes.
  ///
  /// In fr, this message translates to:
  /// **'Oui'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In fr, this message translates to:
  /// **'Non'**
  String get no;

  /// No description provided for @rate.
  ///
  /// In fr, this message translates to:
  /// **'Taux'**
  String get rate;

  /// No description provided for @source.
  ///
  /// In fr, this message translates to:
  /// **'Source'**
  String get source;

  /// No description provided for @destination.
  ///
  /// In fr, this message translates to:
  /// **'Destination'**
  String get destination;

  /// No description provided for @observations.
  ///
  /// In fr, this message translates to:
  /// **'Observations'**
  String get observations;

  /// No description provided for @noObservation.
  ///
  /// In fr, this message translates to:
  /// **'Aucune observation'**
  String get noObservation;

  /// No description provided for @createdAt.
  ///
  /// In fr, this message translates to:
  /// **'Créé le'**
  String get createdAt;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @sales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get sales;

  /// No description provided for @lastAccess.
  ///
  /// In fr, this message translates to:
  /// **'Dernier accès'**
  String get lastAccess;

  /// No description provided for @phone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get phone;

  /// No description provided for @year.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get year;

  /// No description provided for @cash.
  ///
  /// In fr, this message translates to:
  /// **'Liquidités'**
  String get cash;

  /// No description provided for @receivables.
  ///
  /// In fr, this message translates to:
  /// **'Créances'**
  String get receivables;

  /// No description provided for @debts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes'**
  String get debts;

  /// No description provided for @mandatory.
  ///
  /// In fr, this message translates to:
  /// **'Obligatoire'**
  String get mandatory;

  /// No description provided for @zakatAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Zakat'**
  String get zakatAmount;

  /// No description provided for @appliedRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux appliqué'**
  String get appliedRate;

  /// No description provided for @smartScan.
  ///
  /// In fr, this message translates to:
  /// **'SmartScan'**
  String get smartScan;

  /// No description provided for @scannedItems.
  ///
  /// In fr, this message translates to:
  /// **'Articles scannés'**
  String get scannedItems;

  /// No description provided for @carts.
  ///
  /// In fr, this message translates to:
  /// **'Paniers'**
  String get carts;

  /// No description provided for @activeCarts.
  ///
  /// In fr, this message translates to:
  /// **'Paniers actifs'**
  String get activeCarts;

  /// No description provided for @returnedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits retournés'**
  String get returnedProducts;

  /// No description provided for @needs.
  ///
  /// In fr, this message translates to:
  /// **'Besoins'**
  String get needs;

  /// No description provided for @stockRequests.
  ///
  /// In fr, this message translates to:
  /// **'Demandes de stock'**
  String get stockRequests;

  /// No description provided for @exits.
  ///
  /// In fr, this message translates to:
  /// **'Sorties'**
  String get exits;

  /// No description provided for @exitedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits sortis'**
  String get exitedProducts;

  /// No description provided for @availableProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits disponibles'**
  String get availableProducts;

  /// No description provided for @elements.
  ///
  /// In fr, this message translates to:
  /// **'Éléments'**
  String get elements;

  /// No description provided for @items.
  ///
  /// In fr, this message translates to:
  /// **'Articles'**
  String get items;

  /// No description provided for @modifiedAt.
  ///
  /// In fr, this message translates to:
  /// **'Modifié le'**
  String get modifiedAt;

  /// No description provided for @modifiedBy.
  ///
  /// In fr, this message translates to:
  /// **'Modifié par'**
  String get modifiedBy;

  /// No description provided for @cancelledAt.
  ///
  /// In fr, this message translates to:
  /// **'Annulé le'**
  String get cancelledAt;

  /// No description provided for @cancelledBy.
  ///
  /// In fr, this message translates to:
  /// **'Annulé par'**
  String get cancelledBy;

  /// No description provided for @cancellationReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif annulation'**
  String get cancellationReason;

  /// No description provided for @otherwiseDefaultColumns.
  ///
  /// In fr, this message translates to:
  /// **'Sinon les colonnes par défaut seront utilisées'**
  String get otherwiseDefaultColumns;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @brand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get brand;

  /// No description provided for @model.
  ///
  /// In fr, this message translates to:
  /// **'Modèle'**
  String get model;

  /// No description provided for @qty.
  ///
  /// In fr, this message translates to:
  /// **'Qt'**
  String get qty;

  /// No description provided for @name.
  ///
  /// In fr, this message translates to:
  /// **'Nom'**
  String get name;

  /// No description provided for @observation.
  ///
  /// In fr, this message translates to:
  /// **'Observation'**
  String get observation;

  /// No description provided for @wilaya.
  ///
  /// In fr, this message translates to:
  /// **'Wilaya'**
  String get wilaya;

  /// No description provided for @activity.
  ///
  /// In fr, this message translates to:
  /// **'Activité'**
  String get activity;

  /// No description provided for @advance.
  ///
  /// In fr, this message translates to:
  /// **'Avance'**
  String get advance;

  /// No description provided for @totalInvoiced.
  ///
  /// In fr, this message translates to:
  /// **'Total Facturé'**
  String get totalInvoiced;

  /// No description provided for @nbInvoiced.
  ///
  /// In fr, this message translates to:
  /// **'Nb Facturé'**
  String get nbInvoiced;

  /// No description provided for @totalPayment.
  ///
  /// In fr, this message translates to:
  /// **'Total Versement'**
  String get totalPayment;

  /// No description provided for @nbPayment.
  ///
  /// In fr, this message translates to:
  /// **'Nb Versement'**
  String get nbPayment;

  /// No description provided for @nbReturn.
  ///
  /// In fr, this message translates to:
  /// **'Nb Retour'**
  String get nbReturn;

  /// No description provided for @email.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @fax.
  ///
  /// In fr, this message translates to:
  /// **'Fax'**
  String get fax;

  /// No description provided for @nif.
  ///
  /// In fr, this message translates to:
  /// **'NIF'**
  String get nif;

  /// No description provided for @nis.
  ///
  /// In fr, this message translates to:
  /// **'NIS'**
  String get nis;

  /// No description provided for @nrc.
  ///
  /// In fr, this message translates to:
  /// **'NRC'**
  String get nrc;

  /// No description provided for @rib.
  ///
  /// In fr, this message translates to:
  /// **'RIB'**
  String get rib;

  /// No description provided for @bank.
  ///
  /// In fr, this message translates to:
  /// **'Banque'**
  String get bank;

  /// No description provided for @creditWithAmount.
  ///
  /// In fr, this message translates to:
  /// **'Crédit: {amount}'**
  String creditWithAmount(Object amount);

  /// No description provided for @upToDate.
  ///
  /// In fr, this message translates to:
  /// **'À jour'**
  String get upToDate;

  /// No description provided for @address.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get address;

  /// No description provided for @totalPaid.
  ///
  /// In fr, this message translates to:
  /// **'Total Versé'**
  String get totalPaid;

  /// No description provided for @nbPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Nb achats'**
  String get nbPurchases;

  /// No description provided for @debt.
  ///
  /// In fr, this message translates to:
  /// **'Dette'**
  String get debt;

  /// No description provided for @settled.
  ///
  /// In fr, this message translates to:
  /// **'Soldé'**
  String get settled;

  /// No description provided for @id.
  ///
  /// In fr, this message translates to:
  /// **'ID'**
  String get id;

  /// No description provided for @storageRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux Stockage'**
  String get storageRate;

  /// No description provided for @cashRegisterName.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la caisse'**
  String get cashRegisterName;

  /// No description provided for @creatorCode.
  ///
  /// In fr, this message translates to:
  /// **'Code créateur'**
  String get creatorCode;

  /// No description provided for @deletion.
  ///
  /// In fr, this message translates to:
  /// **'Suppression'**
  String get deletion;

  /// No description provided for @user.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get user;

  /// No description provided for @need.
  ///
  /// In fr, this message translates to:
  /// **'Besoin'**
  String get need;

  /// No description provided for @sale.
  ///
  /// In fr, this message translates to:
  /// **'Vente'**
  String get sale;

  /// No description provided for @purchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get purchase;

  /// No description provided for @return_.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get return_;

  /// No description provided for @destocking.
  ///
  /// In fr, this message translates to:
  /// **'Déstockage'**
  String get destocking;

  /// No description provided for @reference.
  ///
  /// In fr, this message translates to:
  /// **'Référence'**
  String get reference;

  /// No description provided for @ref.
  ///
  /// In fr, this message translates to:
  /// **'Réf'**
  String get ref;

  /// No description provided for @debit.
  ///
  /// In fr, this message translates to:
  /// **'Débit'**
  String get debit;

  /// No description provided for @balance.
  ///
  /// In fr, this message translates to:
  /// **'Solde'**
  String get balance;

  /// No description provided for @cashier.
  ///
  /// In fr, this message translates to:
  /// **'Caissier'**
  String get cashier;

  /// No description provided for @size.
  ///
  /// In fr, this message translates to:
  /// **'Taille'**
  String get size;

  /// No description provided for @color.
  ///
  /// In fr, this message translates to:
  /// **'Couleur'**
  String get color;

  /// No description provided for @subcategory.
  ///
  /// In fr, this message translates to:
  /// **'Sous-Catégorie'**
  String get subcategory;

  /// No description provided for @service.
  ///
  /// In fr, this message translates to:
  /// **'Service'**
  String get service;

  /// No description provided for @packaging1.
  ///
  /// In fr, this message translates to:
  /// **'Emballage 1'**
  String get packaging1;

  /// No description provided for @packaging2.
  ///
  /// In fr, this message translates to:
  /// **'Emballage 2'**
  String get packaging2;

  /// No description provided for @minThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil Min'**
  String get minThreshold;

  /// No description provided for @maxThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil Max'**
  String get maxThreshold;

  /// No description provided for @needStatus.
  ///
  /// In fr, this message translates to:
  /// **'Besoin Status'**
  String get needStatus;

  /// No description provided for @barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code Barre'**
  String get barcode;

  /// No description provided for @serialNumber.
  ///
  /// In fr, this message translates to:
  /// **'Numéro Série'**
  String get serialNumber;

  /// No description provided for @multicode.
  ///
  /// In fr, this message translates to:
  /// **'Multicode'**
  String get multicode;

  /// No description provided for @photos.
  ///
  /// In fr, this message translates to:
  /// **'Photos'**
  String get photos;

  /// No description provided for @marginBool.
  ///
  /// In fr, this message translates to:
  /// **'Marge Bool'**
  String get marginBool;

  /// No description provided for @marginRatePercent.
  ///
  /// In fr, this message translates to:
  /// **'Marge Taux %'**
  String get marginRatePercent;

  /// No description provided for @vat.
  ///
  /// In fr, this message translates to:
  /// **'TVA'**
  String get vat;

  /// No description provided for @dateBorrowed.
  ///
  /// In fr, this message translates to:
  /// **'Date Empreint'**
  String get dateBorrowed;

  /// No description provided for @thresholdBool.
  ///
  /// In fr, this message translates to:
  /// **'Seuil Bool'**
  String get thresholdBool;

  /// No description provided for @rateType.
  ///
  /// In fr, this message translates to:
  /// **'Type Taux'**
  String get rateType;

  /// No description provided for @start.
  ///
  /// In fr, this message translates to:
  /// **'Début'**
  String get start;

  /// No description provided for @end.
  ///
  /// In fr, this message translates to:
  /// **'Fin'**
  String get end;

  /// No description provided for @percentage.
  ///
  /// In fr, this message translates to:
  /// **'%'**
  String get percentage;

  /// No description provided for @clientType.
  ///
  /// In fr, this message translates to:
  /// **'Client'**
  String get clientType;

  /// No description provided for @supplierType.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get supplierType;

  /// No description provided for @userCount.
  ///
  /// In fr, this message translates to:
  /// **'Nb utilisateurs'**
  String get userCount;

  /// No description provided for @calculatedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits Calcul'**
  String get calculatedProducts;

  /// No description provided for @calculatedQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité Calcul'**
  String get calculatedQuantity;

  /// No description provided for @calculatedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Calcul'**
  String get calculatedAmount;

  /// No description provided for @gap.
  ///
  /// In fr, this message translates to:
  /// **'Écart'**
  String get gap;

  /// No description provided for @categoryId.
  ///
  /// In fr, this message translates to:
  /// **'ID Catégorie'**
  String get categoryId;

  /// No description provided for @totalPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Total Achat'**
  String get totalPurchase;

  /// No description provided for @totalSale.
  ///
  /// In fr, this message translates to:
  /// **'Total Vente'**
  String get totalSale;

  /// No description provided for @totalReturn.
  ///
  /// In fr, this message translates to:
  /// **'Total Retour'**
  String get totalReturn;

  /// No description provided for @lastPurchaseQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité Dernier Achat'**
  String get lastPurchaseQuantity;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get username;

  /// No description provided for @salesCount.
  ///
  /// In fr, this message translates to:
  /// **'Nb ventes'**
  String get salesCount;

  /// No description provided for @beneficiaryType.
  ///
  /// In fr, this message translates to:
  /// **'Type Bénéficiaire'**
  String get beneficiaryType;

  /// No description provided for @cashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get cashRegister;

  /// No description provided for @beneficiary.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire'**
  String get beneficiary;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode Paiement'**
  String get paymentMethod;

  /// No description provided for @incoming.
  ///
  /// In fr, this message translates to:
  /// **'Entrant'**
  String get incoming;

  /// No description provided for @outgoing.
  ///
  /// In fr, this message translates to:
  /// **'Sortant'**
  String get outgoing;

  /// No description provided for @entry.
  ///
  /// In fr, this message translates to:
  /// **'Entrée'**
  String get entry;

  /// No description provided for @cancelled.
  ///
  /// In fr, this message translates to:
  /// **'Annulé'**
  String get cancelled;

  /// No description provided for @totalCapital.
  ///
  /// In fr, this message translates to:
  /// **'Capital Total'**
  String get totalCapital;

  /// No description provided for @statusField.
  ///
  /// In fr, this message translates to:
  /// **'Statut'**
  String get statusField;

  /// No description provided for @hawlStart.
  ///
  /// In fr, this message translates to:
  /// **'Début Hawl'**
  String get hawlStart;

  /// No description provided for @dueDate.
  ///
  /// In fr, this message translates to:
  /// **'Échéance'**
  String get dueDate;

  /// No description provided for @paymentDate.
  ///
  /// In fr, this message translates to:
  /// **'Paiement'**
  String get paymentDate;

  /// No description provided for @confirmation.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmation;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @insertionCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Caisse'**
  String get insertionCashRegister;

  /// No description provided for @insertionCategory.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Catégorie'**
  String get insertionCategory;

  /// No description provided for @newM.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau'**
  String get newM;

  /// No description provided for @add.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter'**
  String get add;

  /// No description provided for @pleaseSelect.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner'**
  String get pleaseSelect;

  /// No description provided for @pleaseSelectCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une caisse'**
  String get pleaseSelectCashRegister;

  /// No description provided for @pleaseSelectCategory.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une catégorie'**
  String get pleaseSelectCategory;

  /// No description provided for @insertionClient.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Client'**
  String get insertionClient;

  /// No description provided for @insertionSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Fournisseur'**
  String get insertionSupplier;

  /// No description provided for @insertionStore.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Magasin'**
  String get insertionStore;

  /// No description provided for @multipleSelection.
  ///
  /// In fr, this message translates to:
  /// **'Sélection multiple'**
  String get multipleSelection;

  /// No description provided for @pleaseSelectClient.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un client'**
  String get pleaseSelectClient;

  /// No description provided for @pleaseSelectSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un fournisseur'**
  String get pleaseSelectSupplier;

  /// No description provided for @pleaseSelectStore.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un magasin'**
  String get pleaseSelectStore;

  /// No description provided for @insertionPack.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Pack'**
  String get insertionPack;

  /// No description provided for @insertionProduct.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Produit'**
  String get insertionProduct;

  /// No description provided for @insertionDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Remise'**
  String get insertionDiscount;

  /// No description provided for @insertionSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Insertion Sous-Catégorie'**
  String get insertionSubcategory;

  /// No description provided for @pleaseSelectPack.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un pack'**
  String get pleaseSelectPack;

  /// No description provided for @pleaseSelectProduct.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un produit'**
  String get pleaseSelectProduct;

  /// No description provided for @pleaseSelectDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une remise'**
  String get pleaseSelectDiscount;

  /// No description provided for @pleaseSelectSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une sous-catégorie'**
  String get pleaseSelectSubcategory;

  /// No description provided for @newNeedList.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Besoin List'**
  String get newNeedList;

  /// No description provided for @modifyNeedList.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Besoin List'**
  String get modifyNeedList;

  /// No description provided for @deleteNeeds.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Besoins'**
  String get deleteNeeds;

  /// No description provided for @needDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Besoin'**
  String get needDetail;

  /// No description provided for @totalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total'**
  String get totalAmount;

  /// No description provided for @numberOfArticles.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'articles'**
  String get numberOfArticles;

  /// No description provided for @totalQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité totale'**
  String get totalQuantity;

  /// No description provided for @noProduct.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit'**
  String get noProduct;

  /// No description provided for @generalInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations générales'**
  String get generalInformation;

  /// No description provided for @audit.
  ///
  /// In fr, this message translates to:
  /// **'Audit'**
  String get audit;

  /// No description provided for @productsList.
  ///
  /// In fr, this message translates to:
  /// **'Liste des produits'**
  String get productsList;

  /// No description provided for @addObservation.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter une observation...'**
  String get addObservation;

  /// No description provided for @selectedNeeds.
  ///
  /// In fr, this message translates to:
  /// **'Besoins sélectionnés :'**
  String get selectedNeeds;

  /// No description provided for @confirmDeleteNeeds.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer cette liste ?'**
  String get confirmDeleteNeeds;

  /// No description provided for @loginRequired.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour créer une besoin list'**
  String get loginRequired;

  /// No description provided for @fillRequiredFields.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez remplir tous les champs obligatoires.'**
  String get fillRequiredFields;

  /// No description provided for @success.
  ///
  /// In fr, this message translates to:
  /// **'Succès'**
  String get success;

  /// No description provided for @modify.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get modify;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @productsOfNeed.
  ///
  /// In fr, this message translates to:
  /// **'Produits du besoin {code}'**
  String productsOfNeed(Object code);

  /// No description provided for @productCode.
  ///
  /// In fr, this message translates to:
  /// **'Code'**
  String get productCode;

  /// No description provided for @productName.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get productName;

  /// No description provided for @productQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get productQuantity;

  /// No description provided for @productPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get productPrice;

  /// No description provided for @productTotal.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get productTotal;

  /// No description provided for @cashRegisterSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres Caisse'**
  String get cashRegisterSettings;

  /// No description provided for @defaultCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Caisse par défaut'**
  String get defaultCashRegister;

  /// No description provided for @defaultStore.
  ///
  /// In fr, this message translates to:
  /// **'Magasin par défaut'**
  String get defaultStore;

  /// No description provided for @parcel.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get parcel;

  /// No description provided for @alwaysAsked.
  ///
  /// In fr, this message translates to:
  /// **'Toujours demandé'**
  String get alwaysAsked;

  /// No description provided for @uniteParcel.
  ///
  /// In fr, this message translates to:
  /// **'Unité'**
  String get uniteParcel;

  /// No description provided for @smallParcel.
  ///
  /// In fr, this message translates to:
  /// **'Petit colis'**
  String get smallParcel;

  /// No description provided for @largeParcel.
  ///
  /// In fr, this message translates to:
  /// **'Grand colis'**
  String get largeParcel;

  /// No description provided for @allFieldsRequired.
  ///
  /// In fr, this message translates to:
  /// **'Tous les champs doivent être remplis'**
  String get allFieldsRequired;

  /// No description provided for @modifyProductPrice.
  ///
  /// In fr, this message translates to:
  /// **'Modifier prix produit'**
  String get modifyProductPrice;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @invalidPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix invalide'**
  String get invalidPrice;

  /// No description provided for @passwordRequired.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe requis'**
  String get passwordRequired;

  /// No description provided for @ticketRegistration.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement Ticket'**
  String get ticketRegistration;

  /// No description provided for @cartNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° Panier'**
  String get cartNumber;

  /// No description provided for @fullPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement total'**
  String get fullPayment;

  /// No description provided for @cashPrint.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser / Imprimer'**
  String get cashPrint;

  /// No description provided for @cashPrintBLSC.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser / Imprimer BLSC'**
  String get cashPrintBLSC;

  /// No description provided for @cashPrintTicket.
  ///
  /// In fr, this message translates to:
  /// **'Encaisser / Imprimer Ticket'**
  String get cashPrintTicket;

  /// No description provided for @blNumber.
  ///
  /// In fr, this message translates to:
  /// **'N° BL'**
  String get blNumber;

  /// No description provided for @paidAmount.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get paidAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get remainingAmount;

  /// No description provided for @deleteCategory.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer catégorie'**
  String get deleteCategory;

  /// No description provided for @categoryDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Catégorie'**
  String get categoryDetail;

  /// No description provided for @modifyCategory.
  ///
  /// In fr, this message translates to:
  /// **'Modification Catégorie'**
  String get modifyCategory;

  /// No description provided for @newCategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Catégorie'**
  String get newCategory;

  /// No description provided for @selectedCategories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories sélectionnées :'**
  String get selectedCategories;

  /// No description provided for @confirmDeleteCategories.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sûr de Supprimer ces catégories ?'**
  String get confirmDeleteCategories;

  /// No description provided for @confirmDeleteCategory.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer définitivement les catégories sélectionnées ?'**
  String get confirmDeleteCategory;

  /// No description provided for @deleteSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Catégories supprimées avec succès.'**
  String get deleteSuccess;

  /// No description provided for @deleteError.
  ///
  /// In fr, this message translates to:
  /// **'Merci de vider toutes les sous-catégories avant suppression.'**
  String get deleteError;

  /// No description provided for @modifySuccess.
  ///
  /// In fr, this message translates to:
  /// **'Modifiée avec succès.'**
  String get modifySuccess;

  /// No description provided for @createSuccess.
  ///
  /// In fr, this message translates to:
  /// **'L\'opération enregistrée avec succès.'**
  String get createSuccess;

  /// No description provided for @categoryExists.
  ///
  /// In fr, this message translates to:
  /// **'Une catégorie avec ce nom existe déjà.'**
  String get categoryExists;

  /// No description provided for @authentication.
  ///
  /// In fr, this message translates to:
  /// **'Authentification'**
  String get authentication;

  /// No description provided for @categoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la catégorie'**
  String get categoryNameHint;

  /// No description provided for @categoryObservationHint.
  ///
  /// In fr, this message translates to:
  /// **'Observation de la catégorie...'**
  String get categoryObservationHint;

  /// No description provided for @deleteClients.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Clients'**
  String get deleteClients;

  /// No description provided for @clientDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Client'**
  String get clientDetail;

  /// No description provided for @modifyClient.
  ///
  /// In fr, this message translates to:
  /// **'Modification Client'**
  String get modifyClient;

  /// No description provided for @clientSituation.
  ///
  /// In fr, this message translates to:
  /// **'Situation Client : {name}'**
  String clientSituation(Object name);

  /// No description provided for @numberOfPurchases.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'achats'**
  String get numberOfPurchases;

  /// No description provided for @numberOfPayments.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de versement'**
  String get numberOfPayments;

  /// No description provided for @contact.
  ///
  /// In fr, this message translates to:
  /// **'Contact'**
  String get contact;

  /// No description provided for @addressInfo.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get addressInfo;

  /// No description provided for @financialInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations financières'**
  String get financialInformation;

  /// No description provided for @administrativeInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations Administratives'**
  String get administrativeInformation;

  /// No description provided for @bankingInformation.
  ///
  /// In fr, this message translates to:
  /// **'Coordonnées Bancaires'**
  String get bankingInformation;

  /// No description provided for @selectedClients.
  ///
  /// In fr, this message translates to:
  /// **'Clients sélectionnés :'**
  String get selectedClients;

  /// No description provided for @confirmDeleteClients.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces clients ?'**
  String get confirmDeleteClients;

  /// No description provided for @refresh.
  ///
  /// In fr, this message translates to:
  /// **'Actualiser'**
  String get refresh;

  /// No description provided for @clientNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client'**
  String get clientNameHint;

  /// No description provided for @phoneHint.
  ///
  /// In fr, this message translates to:
  /// **'0550 00 00 00'**
  String get phoneHint;

  /// No description provided for @wilayaHint.
  ///
  /// In fr, this message translates to:
  /// **'Biskra'**
  String get wilayaHint;

  /// No description provided for @addressHint.
  ///
  /// In fr, this message translates to:
  /// **'Cité 05 juillet'**
  String get addressHint;

  /// No description provided for @emailHint.
  ///
  /// In fr, this message translates to:
  /// **'client@mail.com'**
  String get emailHint;

  /// No description provided for @faxHint.
  ///
  /// In fr, this message translates to:
  /// **'033 00 00 00'**
  String get faxHint;

  /// No description provided for @nifHint.
  ///
  /// In fr, this message translates to:
  /// **'000000000000000'**
  String get nifHint;

  /// No description provided for @nisHint.
  ///
  /// In fr, this message translates to:
  /// **'0000000000'**
  String get nisHint;

  /// No description provided for @nrcHint.
  ///
  /// In fr, this message translates to:
  /// **'16/00-0000000B00'**
  String get nrcHint;

  /// No description provided for @bankHint.
  ///
  /// In fr, this message translates to:
  /// **'BNA / CPA / BADR ...'**
  String get bankHint;

  /// No description provided for @ribHint.
  ///
  /// In fr, this message translates to:
  /// **'007999990000123456789'**
  String get ribHint;

  /// No description provided for @observationHint.
  ///
  /// In fr, this message translates to:
  /// **'Observation ...'**
  String get observationHint;

  /// No description provided for @versement_ENT.
  ///
  /// In fr, this message translates to:
  /// **'Versement (Entrée)'**
  String get versement_ENT;

  /// No description provided for @versement_SRT.
  ///
  /// In fr, this message translates to:
  /// **'Versement (Sortie)'**
  String get versement_SRT;

  /// No description provided for @clientNumber.
  ///
  /// In fr, this message translates to:
  /// **'Client #{id}'**
  String clientNumber(Object id);

  /// No description provided for @lastPurchaseDate.
  ///
  /// In fr, this message translates to:
  /// **'Dernier achat'**
  String get lastPurchaseDate;

  /// No description provided for @purchasesCount.
  ///
  /// In fr, this message translates to:
  /// **'Achats'**
  String get purchasesCount;

  /// No description provided for @deleteSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Fournisseurs'**
  String get deleteSuppliers;

  /// No description provided for @supplierDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Fournisseur'**
  String get supplierDetail;

  /// No description provided for @modifySupplier.
  ///
  /// In fr, this message translates to:
  /// **'Modification Fournisseur'**
  String get modifySupplier;

  /// No description provided for @newSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Fournisseur'**
  String get newSupplier;

  /// No description provided for @supplierSituation.
  ///
  /// In fr, this message translates to:
  /// **'Situation Fournisseur : {name}'**
  String supplierSituation(Object name);

  /// No description provided for @supplierNumber.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur #{id}'**
  String supplierNumber(Object id);

  /// No description provided for @selectedSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs sélectionnés :'**
  String get selectedSuppliers;

  /// No description provided for @confirmDeleteSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces fournisseurs ?'**
  String get confirmDeleteSuppliers;

  /// No description provided for @supplierNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du fournisseur'**
  String get supplierNameHint;

  /// No description provided for @paymentIn.
  ///
  /// In fr, this message translates to:
  /// **'Versement (Entrée)'**
  String get paymentIn;

  /// No description provided for @paymentOut.
  ///
  /// In fr, this message translates to:
  /// **'Versement (Sortie)'**
  String get paymentOut;

  /// No description provided for @deleteCashRegisters.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les caisses'**
  String get deleteCashRegisters;

  /// No description provided for @cashRegisterDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Caisse'**
  String get cashRegisterDetail;

  /// No description provided for @modifyCashRegister.
  ///
  /// In fr, this message translates to:
  /// **'Modification Caisse'**
  String get modifyCashRegister;

  /// No description provided for @cashRegisterNumber.
  ///
  /// In fr, this message translates to:
  /// **'Caisse #{id}'**
  String cashRegisterNumber(Object id);

  /// No description provided for @selectedCashRegisters.
  ///
  /// In fr, this message translates to:
  /// **'Caisses sélectionnées :'**
  String get selectedCashRegisters;

  /// No description provided for @confirmDeleteCashRegisters.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces caisses ?'**
  String get confirmDeleteCashRegisters;

  /// No description provided for @noStoreAvailable.
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin disponible.'**
  String get noStoreAvailable;

  /// No description provided for @codeAutoGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Généré automatiquement'**
  String get codeAutoGenerated;

  /// No description provided for @cashRegisterNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Caisse principale'**
  String get cashRegisterNameHint;

  /// No description provided for @initialBalanceHint.
  ///
  /// In fr, this message translates to:
  /// **'0.00'**
  String get initialBalanceHint;

  /// No description provided for @storeHint.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionner un magasin'**
  String get storeHint;

  /// No description provided for @physical.
  ///
  /// In fr, this message translates to:
  /// **'Physique'**
  String get physical;

  /// No description provided for @account.
  ///
  /// In fr, this message translates to:
  /// **'Compte'**
  String get account;

  /// No description provided for @deleteStores.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Magasins'**
  String get deleteStores;

  /// No description provided for @cannotDelete.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer'**
  String get cannotDelete;

  /// No description provided for @storeDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Magasin'**
  String get storeDetail;

  /// No description provided for @modifyStore.
  ///
  /// In fr, this message translates to:
  /// **'Modification Magasin'**
  String get modifyStore;

  /// No description provided for @newStore.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Magasin'**
  String get newStore;

  /// No description provided for @storeNumber.
  ///
  /// In fr, this message translates to:
  /// **'Magasin #{id}'**
  String storeNumber(Object id);

  /// No description provided for @stockCapacity.
  ///
  /// In fr, this message translates to:
  /// **'Stock & capacité'**
  String get stockCapacity;

  /// No description provided for @selectedStores.
  ///
  /// In fr, this message translates to:
  /// **'Magasins sélectionnés :'**
  String get selectedStores;

  /// No description provided for @cannotDeleteWithProducts.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas supprimer les magasins suivants car ils contiennent des produits :'**
  String get cannotDeleteWithProducts;

  /// No description provided for @confirmDeleteStores.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces magasins ?\nCette action est irréversible.'**
  String get confirmDeleteStores;

  /// No description provided for @noStoreDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin supprimé.'**
  String get noStoreDeleted;

  /// No description provided for @noProductsAssociated.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit associé à ce magasin'**
  String get noProductsAssociated;

  /// No description provided for @noProductsAdded.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit ajouté'**
  String get noProductsAdded;

  /// No description provided for @storeNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du magasin'**
  String get storeNameHint;

  /// No description provided for @storeAddressHint.
  ///
  /// In fr, this message translates to:
  /// **'Adresse du magasin'**
  String get storeAddressHint;

  /// No description provided for @productsOfStore.
  ///
  /// In fr, this message translates to:
  /// **'Produits du Magasin {code}'**
  String productsOfStore(Object code);

  /// No description provided for @reactivatePack.
  ///
  /// In fr, this message translates to:
  /// **'Réactiver pack'**
  String get reactivatePack;

  /// No description provided for @deletePacks.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Packs'**
  String get deletePacks;

  /// No description provided for @packDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Pack'**
  String get packDetail;

  /// No description provided for @modifyPack.
  ///
  /// In fr, this message translates to:
  /// **'Modification Pack'**
  String get modifyPack;

  /// No description provided for @newPack.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Pack'**
  String get newPack;

  /// No description provided for @numberOfItems.
  ///
  /// In fr, this message translates to:
  /// **'Nombre d\'articles'**
  String get numberOfItems;

  /// No description provided for @selectedPacks.
  ///
  /// In fr, this message translates to:
  /// **'Packs sélectionnés :'**
  String get selectedPacks;

  /// No description provided for @confirmReactivatePacks.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sur de réactiver ces packs ?'**
  String get confirmReactivatePacks;

  /// No description provided for @confirmDeletePacks.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer les packs sélectionnés ?\nCette action est irréversible.'**
  String get confirmDeletePacks;

  /// No description provided for @noChangesDetected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune modification détectée.'**
  String get noChangesDetected;

  /// No description provided for @productAlreadyAdded.
  ///
  /// In fr, this message translates to:
  /// **'Le produit {name} est déjà ajouté au pack.'**
  String productAlreadyAdded(Object name);

  /// No description provided for @packNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du pack'**
  String get packNameHint;

  /// No description provided for @priceHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex: 1500.00'**
  String get priceHint;

  /// No description provided for @productsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} produits'**
  String productsCount(Object count);

  /// No description provided for @productsOfPack.
  ///
  /// In fr, this message translates to:
  /// **'Produits du Pack {code}'**
  String productsOfPack(Object code);

  /// No description provided for @cancelCarts.
  ///
  /// In fr, this message translates to:
  /// **'Annuler Paniers'**
  String get cancelCarts;

  /// No description provided for @cartDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail Panier'**
  String get cartDetail;

  /// No description provided for @modifyCart.
  ///
  /// In fr, this message translates to:
  /// **'Modification Panier'**
  String get modifyCart;

  /// No description provided for @cartType.
  ///
  /// In fr, this message translates to:
  /// **'Type panier'**
  String get cartType;

  /// No description provided for @amountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant versé'**
  String get amountPaid;

  /// No description provided for @cartId.
  ///
  /// In fr, this message translates to:
  /// **'Panier #{code}'**
  String cartId(Object code);

  /// No description provided for @itemsAndQuantities.
  ///
  /// In fr, this message translates to:
  /// **'Articles & Quantités'**
  String get itemsAndQuantities;

  /// No description provided for @selectedCarts.
  ///
  /// In fr, this message translates to:
  /// **'Paniers sélectionnés :'**
  String get selectedCarts;

  /// No description provided for @confirmCancelCarts.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler ces paniers ?'**
  String get confirmCancelCarts;

  /// No description provided for @cartProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits du panier {code}'**
  String cartProducts(Object code);

  /// No description provided for @noProducts.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit'**
  String get noProducts;

  /// No description provided for @cart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cart;

  /// No description provided for @productsOfCart.
  ///
  /// In fr, this message translates to:
  /// **'Produits du panier {code}'**
  String productsOfCart(Object code);

  /// No description provided for @applyCategorySubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer Catégorie / Sous-Catégorie'**
  String get applyCategorySubcategory;

  /// No description provided for @selectedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits sélectionnés :'**
  String get selectedProducts;

  /// No description provided for @confirmModifyCategorySubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous vraiment modifier la catégorie et la sous-catégorie pour {count} produit(s) sélectionné(s) ?'**
  String confirmModifyCategorySubcategory(Object count);

  /// No description provided for @categorySubcategoryModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie et Sous-catégorie modifiées avec succès.'**
  String get categorySubcategoryModifiedSuccess;

  /// No description provided for @errorOccurred.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue.'**
  String get errorOccurred;

  /// No description provided for @priceTaxes.
  ///
  /// In fr, this message translates to:
  /// **'Prix & Taxes'**
  String get priceTaxes;

  /// No description provided for @stockUnit.
  ///
  /// In fr, this message translates to:
  /// **'Stock & Unité'**
  String get stockUnit;

  /// No description provided for @unitOfMeasure.
  ///
  /// In fr, this message translates to:
  /// **'Unité de mesure'**
  String get unitOfMeasure;

  /// No description provided for @locationSpecifications.
  ///
  /// In fr, this message translates to:
  /// **'Emplacement & Spécifications'**
  String get locationSpecifications;

  /// No description provided for @stores.
  ///
  /// In fr, this message translates to:
  /// **'Magasins'**
  String get stores;

  /// No description provided for @active.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get active;

  /// No description provided for @inactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get inactive;

  /// No description provided for @noPacks.
  ///
  /// In fr, this message translates to:
  /// **'Aucun pack'**
  String get noPacks;

  /// No description provided for @noStores.
  ///
  /// In fr, this message translates to:
  /// **'Aucun magasin'**
  String get noStores;

  /// No description provided for @applyPack.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer un pack'**
  String get applyPack;

  /// No description provided for @applyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Appliquer une remise'**
  String get applyDiscount;

  /// No description provided for @confirmApplyPack.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir appliquer le pack \'{packName}\' à {count} produit(s) sélectionné(s) ?'**
  String confirmApplyPack(Object count, Object packName);

  /// No description provided for @confirmApplyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir appliquer la remise \'{discountName}\' à {count} produit(s) sélectionné(s) ?'**
  String confirmApplyDiscount(Object count, Object discountName);

  /// No description provided for @packAppliedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Pack appliqué avec succès.'**
  String get packAppliedSuccess;

  /// No description provided for @discountAppliedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Remise appliquée avec succès.'**
  String get discountAppliedSuccess;

  /// No description provided for @modifyProduct.
  ///
  /// In fr, this message translates to:
  /// **'Modification Produit'**
  String get modifyProduct;

  /// No description provided for @quickMode.
  ///
  /// In fr, this message translates to:
  /// **'Rapide'**
  String get quickMode;

  /// No description provided for @detailedMode.
  ///
  /// In fr, this message translates to:
  /// **'Détaillé'**
  String get detailedMode;

  /// No description provided for @codeReference.
  ///
  /// In fr, this message translates to:
  /// **'Code & Référence'**
  String get codeReference;

  /// No description provided for @categoryDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie & Remise'**
  String get categoryDiscount;

  /// No description provided for @unitPackaging.
  ///
  /// In fr, this message translates to:
  /// **'Unité & Emballage'**
  String get unitPackaging;

  /// No description provided for @storage.
  ///
  /// In fr, this message translates to:
  /// **'Stockage'**
  String get storage;

  /// No description provided for @packStore.
  ///
  /// In fr, this message translates to:
  /// **'Pack & Magasin'**
  String get packStore;

  /// No description provided for @marginAmount.
  ///
  /// In fr, this message translates to:
  /// **'Marge Montant'**
  String get marginAmount;

  /// No description provided for @marginPercentage.
  ///
  /// In fr, this message translates to:
  /// **'Marge Pourcentage'**
  String get marginPercentage;

  /// No description provided for @spec1.
  ///
  /// In fr, this message translates to:
  /// **'Spécification 1'**
  String get spec1;

  /// No description provided for @spec2.
  ///
  /// In fr, this message translates to:
  /// **'Spécification 2'**
  String get spec2;

  /// No description provided for @expiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get expiryDate;

  /// No description provided for @productNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom du produit'**
  String get productNameHint;

  /// No description provided for @descriptionHint.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get descriptionHint;

  /// No description provided for @brandHint.
  ///
  /// In fr, this message translates to:
  /// **'Exemple: LG, Samsung....'**
  String get brandHint;

  /// No description provided for @barcodeHint.
  ///
  /// In fr, this message translates to:
  /// **'949832128151'**
  String get barcodeHint;

  /// No description provided for @serialNumberHint.
  ///
  /// In fr, this message translates to:
  /// **'123456789'**
  String get serialNumberHint;

  /// No description provided for @sizeHint.
  ///
  /// In fr, this message translates to:
  /// **'XL L M S ....'**
  String get sizeHint;

  /// No description provided for @colorHint.
  ///
  /// In fr, this message translates to:
  /// **'Blanc Bleu ....'**
  String get colorHint;

  /// No description provided for @packaging1Hint.
  ///
  /// In fr, this message translates to:
  /// **'15 (boîte)'**
  String get packaging1Hint;

  /// No description provided for @packaging2Hint.
  ///
  /// In fr, this message translates to:
  /// **'150 (carton)'**
  String get packaging2Hint;

  /// No description provided for @spec1Hint.
  ///
  /// In fr, this message translates to:
  /// **'Rayon 1'**
  String get spec1Hint;

  /// No description provided for @spec2Hint.
  ///
  /// In fr, this message translates to:
  /// **'Étagère 1'**
  String get spec2Hint;

  /// No description provided for @loginRequiredModify.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour modifier un produit.'**
  String get loginRequiredModify;

  /// No description provided for @loginRequiredCreate.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour créer un nouveau produit.'**
  String get loginRequiredCreate;

  /// No description provided for @confirmModifyProduct.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier ce produit ?'**
  String get confirmModifyProduct;

  /// No description provided for @salePriceLowerThanPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Prix de vente inférieur au prix d\'achat'**
  String get salePriceLowerThanPurchase;

  /// No description provided for @maxThresholdLowerThanMin.
  ///
  /// In fr, this message translates to:
  /// **'Seuil maximum inférieur au seuil minimum'**
  String get maxThresholdLowerThanMin;

  /// No description provided for @productModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Produit modifié avec succès.'**
  String get productModifiedSuccess;

  /// No description provided for @productSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Produit enregistré avec succès.'**
  String get productSavedSuccess;

  /// No description provided for @deleteProduct.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Produit'**
  String get deleteProduct;

  /// No description provided for @confirmDeleteProducts.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sûr de supprimer ces produits ?'**
  String get confirmDeleteProducts;

  /// No description provided for @confirmPermanentDelete.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer définitivement les produits sélectionnés ?'**
  String get confirmPermanentDelete;

  /// No description provided for @productsDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Produits supprimés avec succès.'**
  String get productsDeletedSuccess;

  /// No description provided for @cannotDeleteWithMovements.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas supprimer ces produits car ils possèdent des mouvements :'**
  String get cannotDeleteWithMovements;

  /// No description provided for @loginRequiredDelete.
  ///
  /// In fr, this message translates to:
  /// **'Vous devez être connecté pour supprimer un produit.'**
  String get loginRequiredDelete;

  /// No description provided for @kg.
  ///
  /// In fr, this message translates to:
  /// **'Kg'**
  String get kg;

  /// No description provided for @deleteDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Remise'**
  String get deleteDiscount;

  /// No description provided for @selectedDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises sélectionnées :'**
  String get selectedDiscounts;

  /// No description provided for @confirmDeleteDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sûr de supprimer ces remises ?'**
  String get confirmDeleteDiscounts;

  /// No description provided for @confirmPermanentDeleteDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer définitivement les remises sélectionnées ?'**
  String get confirmPermanentDeleteDiscounts;

  /// No description provided for @discountsDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Remises supprimées avec succès.'**
  String get discountsDeletedSuccess;

  /// No description provided for @modifyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Modification Remise'**
  String get modifyDiscount;

  /// No description provided for @newDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Remise'**
  String get newDiscount;

  /// No description provided for @productList.
  ///
  /// In fr, this message translates to:
  /// **'Liste produits'**
  String get productList;

  /// No description provided for @productsOfDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Produits de la remise {code}'**
  String productsOfDiscount(Object code);

  /// No description provided for @amountRate.
  ///
  /// In fr, this message translates to:
  /// **'Montant / Taux'**
  String get amountRate;

  /// No description provided for @productsConcerned.
  ///
  /// In fr, this message translates to:
  /// **'Produits concernés'**
  String get productsConcerned;

  /// No description provided for @currentDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Remise Actuelle'**
  String get currentDiscount;

  /// No description provided for @byProduct.
  ///
  /// In fr, this message translates to:
  /// **'Par Produit'**
  String get byProduct;

  /// No description provided for @byAmount.
  ///
  /// In fr, this message translates to:
  /// **'Par Montant'**
  String get byAmount;

  /// No description provided for @discountNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la remise'**
  String get discountNameHint;

  /// No description provided for @discountRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux de remise'**
  String get discountRate;

  /// No description provided for @pleaseSelectStartDateFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez choisir la date de début d\'abord'**
  String get pleaseSelectStartDateFirst;

  /// No description provided for @discountApplicationAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant d\'application de la remise'**
  String get discountApplicationAmount;

  /// No description provided for @discountModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Remise modifiée avec succès.'**
  String get discountModifiedSuccess;

  /// No description provided for @discountSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Remise enregistrée avec succès.'**
  String get discountSavedSuccess;

  /// No description provided for @invalidNumber.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez entrer un nombre valide'**
  String get invalidNumber;

  /// No description provided for @percentageExceeds100.
  ///
  /// In fr, this message translates to:
  /// **'Le pourcentage ne peut pas dépasser 100%'**
  String get percentageExceeds100;

  /// No description provided for @valueMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'La valeur doit être positive'**
  String get valueMustBePositive;

  /// No description provided for @confirmModifyDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier cette remise ?'**
  String get confirmModifyDiscount;

  /// No description provided for @greaterThan.
  ///
  /// In fr, this message translates to:
  /// **'Supérieur à'**
  String get greaterThan;

  /// No description provided for @deleteReturns.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les Retours'**
  String get deleteReturns;

  /// No description provided for @selectedReturns.
  ///
  /// In fr, this message translates to:
  /// **'Retours sélectionnés :'**
  String get selectedReturns;

  /// No description provided for @returnHash.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get returnHash;

  /// No description provided for @confirmDeleteReturns.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces retours ?'**
  String get confirmDeleteReturns;

  /// No description provided for @modifyReturn.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Retour'**
  String get modifyReturn;

  /// No description provided for @newReturn.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Retour'**
  String get newReturn;

  /// No description provided for @confirmModifyReturn.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier ce retour ?'**
  String get confirmModifyReturn;

  /// No description provided for @returnModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Retour modifié avec succès.'**
  String get returnModifiedSuccess;

  /// No description provided for @returnSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Retour enregistré avec succès.'**
  String get returnSavedSuccess;

  /// No description provided for @roles.
  ///
  /// In fr, this message translates to:
  /// **'Rôles'**
  String get roles;

  /// No description provided for @deactivateRoles.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver les Rôles'**
  String get deactivateRoles;

  /// No description provided for @selectedRoles.
  ///
  /// In fr, this message translates to:
  /// **'Rôles sélectionnés :'**
  String get selectedRoles;

  /// No description provided for @roleHash.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get roleHash;

  /// No description provided for @confirmDeactivateRoles.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir désactiver ces rôles ?'**
  String get confirmDeactivateRoles;

  /// No description provided for @deleteRole.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer le Rôle'**
  String get deleteRole;

  /// No description provided for @confirmDeleteRoles.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer les rôles sélectionnés ?'**
  String get confirmDeleteRoles;

  /// No description provided for @rolesDeletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} rôle(s) supprimé(s) avec succès.'**
  String rolesDeletedCount(Object count);

  /// No description provided for @noRolesDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Aucun rôle supprimé.'**
  String get noRolesDeleted;

  /// No description provided for @deletionImpossible.
  ///
  /// In fr, this message translates to:
  /// **'Suppression impossible'**
  String get deletionImpossible;

  /// No description provided for @roleHasUsers.
  ///
  /// In fr, this message translates to:
  /// **'Le rôle \'{roleName}\' contient des utilisateurs et ne peut pas être supprimé.'**
  String roleHasUsers(Object roleName);

  /// No description provided for @roleName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du rôle'**
  String get roleName;

  /// No description provided for @roleNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Ex : Administrateur'**
  String get roleNameHint;

  /// No description provided for @modifyRole.
  ///
  /// In fr, this message translates to:
  /// **'Modification du rôle'**
  String get modifyRole;

  /// No description provided for @newRole.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Rôle'**
  String get newRole;

  /// No description provided for @confirmModifyRole.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier ce rôle ?'**
  String get confirmModifyRole;

  /// No description provided for @roleModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Rôle modifié avec succès.'**
  String get roleModifiedSuccess;

  /// No description provided for @roleSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Rôle enregistré avec succès.'**
  String get roleSavedSuccess;

  /// No description provided for @smartScanHash.
  ///
  /// In fr, this message translates to:
  /// **'SmartScan'**
  String get smartScanHash;

  /// No description provided for @deleteSmartScan.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Smart Scan'**
  String get deleteSmartScan;

  /// No description provided for @selectedSmartScans.
  ///
  /// In fr, this message translates to:
  /// **'SmartScan sélectionnés :'**
  String get selectedSmartScans;

  /// No description provided for @confirmDeleteSmartScans.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces SmartScan ?'**
  String get confirmDeleteSmartScans;

  /// No description provided for @statistics.
  ///
  /// In fr, this message translates to:
  /// **'Statistiques'**
  String get statistics;

  /// No description provided for @scannedProductCount.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de produits scannés'**
  String get scannedProductCount;

  /// No description provided for @scannedTotalQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité totale scannée'**
  String get scannedTotalQuantity;

  /// No description provided for @scannedTotalAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant total scanné'**
  String get scannedTotalAmount;

  /// No description provided for @smartScanProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits du SmartScan {code}'**
  String smartScanProducts(Object code);

  /// No description provided for @smartScanProductsList.
  ///
  /// In fr, this message translates to:
  /// **'Produits du Smart Scan'**
  String get smartScanProductsList;

  /// No description provided for @modifySmartScan.
  ///
  /// In fr, this message translates to:
  /// **'Modification Smart Scan'**
  String get modifySmartScan;

  /// No description provided for @gapDetected.
  ///
  /// In fr, this message translates to:
  /// **'Écart détecté'**
  String get gapDetected;

  /// No description provided for @gapDetectedMessage.
  ///
  /// In fr, this message translates to:
  /// **'Un écart a été détecté entre les valeurs saisies et calculées.\nVoulez-vous continuer ?'**
  String get gapDetectedMessage;

  /// No description provided for @smartScanModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Smart Scan modifié avec succès.'**
  String get smartScanModifiedSuccess;

  /// No description provided for @newSmartScan.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Smart Scan'**
  String get newSmartScan;

  /// No description provided for @smartScanSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Smart Scan enregistré avec succès.'**
  String get smartScanSavedSuccess;

  /// No description provided for @back.
  ///
  /// In fr, this message translates to:
  /// **'Retour'**
  String get back;

  /// No description provided for @next.
  ///
  /// In fr, this message translates to:
  /// **'Suivant'**
  String get next;

  /// No description provided for @supplierCodeRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le code fournisseur est obligatoire.'**
  String get supplierCodeRequired;

  /// No description provided for @supplierNameRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nom du fournisseur est obligatoire.'**
  String get supplierNameRequired;

  /// No description provided for @dateRequired.
  ///
  /// In fr, this message translates to:
  /// **'La date est obligatoire.'**
  String get dateRequired;

  /// No description provided for @amountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le montant est obligatoire.'**
  String get amountRequired;

  /// No description provided for @productCountRequired.
  ///
  /// In fr, this message translates to:
  /// **'Le nombre de produits est obligatoire.'**
  String get productCountRequired;

  /// No description provided for @totalQuantityRequired.
  ///
  /// In fr, this message translates to:
  /// **'La quantité totale est obligatoire.'**
  String get totalQuantityRequired;

  /// No description provided for @atLeastOneProduct.
  ///
  /// In fr, this message translates to:
  /// **'Merci de sélectionner au moins un produit.'**
  String get atLeastOneProduct;

  /// No description provided for @supplierCodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Code fournisseur'**
  String get supplierCodeHint;

  /// No description provided for @scanGlobalQRCode.
  ///
  /// In fr, this message translates to:
  /// **'Merci de scanner le QR code Global'**
  String get scanGlobalQRCode;

  /// No description provided for @enterRequiredInformation.
  ///
  /// In fr, this message translates to:
  /// **'Merci de saisir les informations nécessaires'**
  String get enterRequiredInformation;

  /// No description provided for @manual.
  ///
  /// In fr, this message translates to:
  /// **'Manuel'**
  String get manual;

  /// No description provided for @summary.
  ///
  /// In fr, this message translates to:
  /// **'Récapitulatif'**
  String get summary;

  /// No description provided for @productExistsInSmartScan.
  ///
  /// In fr, this message translates to:
  /// **'Ce produit existe déjà dans le Smart Scan'**
  String get productExistsInSmartScan;

  /// No description provided for @list.
  ///
  /// In fr, this message translates to:
  /// **'Liste'**
  String get list;

  /// No description provided for @noEntrySelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucune entrée sélectionnée !'**
  String get noEntrySelected;

  /// No description provided for @selectSingleEntryForDetail.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule entrée pour afficher le détail !'**
  String get selectSingleEntryForDetail;

  /// No description provided for @selectSingleEntryToModify.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner une seule entrée pour modifier !'**
  String get selectSingleEntryToModify;

  /// No description provided for @deleteExit.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Sortie'**
  String get deleteExit;

  /// No description provided for @deleteExits.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les Sorties'**
  String get deleteExits;

  /// No description provided for @selectedExits.
  ///
  /// In fr, this message translates to:
  /// **'Sorties sélectionnées :'**
  String get selectedExits;

  /// No description provided for @confirmDeleteExits.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces sorties ?'**
  String get confirmDeleteExits;

  /// No description provided for @modifyExit.
  ///
  /// In fr, this message translates to:
  /// **'Modification Sortie'**
  String get modifyExit;

  /// No description provided for @newExit.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Sortie'**
  String get newExit;

  /// No description provided for @exitType.
  ///
  /// In fr, this message translates to:
  /// **'Type sortie'**
  String get exitType;

  /// No description provided for @confirmModifyExit.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier cette sortie ?'**
  String get confirmModifyExit;

  /// No description provided for @exitModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sortie modifiée avec succès.'**
  String get exitModifiedSuccess;

  /// No description provided for @exitSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sortie enregistrée avec succès.'**
  String get exitSavedSuccess;

  /// No description provided for @unitPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix unitaire'**
  String get unitPrice;

  /// No description provided for @dateHint.
  ///
  /// In fr, this message translates to:
  /// **'JJ/MM/AAAA'**
  String get dateHint;

  /// No description provided for @deactivateSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la sous-catégorie'**
  String get deactivateSubcategory;

  /// No description provided for @selectedSubcategories.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégories sélectionnées :'**
  String get selectedSubcategories;

  /// No description provided for @confirmDeactivateSubcategories.
  ///
  /// In fr, this message translates to:
  /// **'Vous êtes sûr de désactiver ces sous-catégories ?'**
  String get confirmDeactivateSubcategories;

  /// No description provided for @deleteSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer la sous-catégorie'**
  String get deleteSubcategory;

  /// No description provided for @confirmDeleteSubcategories.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer définitivement les sous-catégories sélectionnées ?'**
  String get confirmDeleteSubcategories;

  /// No description provided for @subcategoriesDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégories supprimées avec succès.'**
  String get subcategoriesDeletedSuccess;

  /// No description provided for @modifySubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la sous-catégorie'**
  String get modifySubcategory;

  /// No description provided for @newSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle sous-catégorie'**
  String get newSubcategory;

  /// No description provided for @parentCategory.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie parente'**
  String get parentCategory;

  /// No description provided for @subcategoryNameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la sous-catégorie'**
  String get subcategoryNameHint;

  /// No description provided for @confirmModifySubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier cette sous-catégorie ?'**
  String get confirmModifySubcategory;

  /// No description provided for @subcategoryModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie modifiée avec succès.'**
  String get subcategoryModifiedSuccess;

  /// No description provided for @subcategorySavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie enregistrée avec succès.'**
  String get subcategorySavedSuccess;

  /// No description provided for @affectedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits concernés'**
  String get affectedProducts;

  /// No description provided for @currentSubcategory.
  ///
  /// In fr, this message translates to:
  /// **'Sous-catégorie actuelle'**
  String get currentSubcategory;

  /// No description provided for @productDistribution.
  ///
  /// In fr, this message translates to:
  /// **'Distribution du produit'**
  String get productDistribution;

  /// No description provided for @distributionByStore.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par magasin'**
  String get distributionByStore;

  /// No description provided for @totalDistributed.
  ///
  /// In fr, this message translates to:
  /// **'Total distribué'**
  String get totalDistributed;

  /// No description provided for @available.
  ///
  /// In fr, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @distribute.
  ///
  /// In fr, this message translates to:
  /// **'Distribuer'**
  String get distribute;

  /// No description provided for @distributionExceedsStock.
  ///
  /// In fr, this message translates to:
  /// **'La quantité totale distribuée dépasse la quantité disponible'**
  String get distributionExceedsStock;

  /// No description provided for @stockMovements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements Stock'**
  String get stockMovements;

  /// No description provided for @last.
  ///
  /// In fr, this message translates to:
  /// **'Dernier'**
  String get last;

  /// No description provided for @packaging.
  ///
  /// In fr, this message translates to:
  /// **'Emballage'**
  String get packaging;

  /// No description provided for @transfer.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get transfer;

  /// No description provided for @transfers.
  ///
  /// In fr, this message translates to:
  /// **'Transferts'**
  String get transfers;

  /// No description provided for @transferHash.
  ///
  /// In fr, this message translates to:
  /// **'Transfert'**
  String get transferHash;

  /// No description provided for @cancelTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Annuler les transferts'**
  String get cancelTransfers;

  /// No description provided for @selectedTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Transferts sélectionnés :'**
  String get selectedTransfers;

  /// No description provided for @confirmCancelTransfers.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir annuler ces transferts ?'**
  String get confirmCancelTransfers;

  /// No description provided for @irreversibleOperation.
  ///
  /// In fr, this message translates to:
  /// **'Cette opération est irréversible.'**
  String get irreversibleOperation;

  /// No description provided for @transfersCancelledSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Transferts annulés avec succès.'**
  String get transfersCancelledSuccess;

  /// No description provided for @transferDate.
  ///
  /// In fr, this message translates to:
  /// **'Date de transfert'**
  String get transferDate;

  /// No description provided for @modifyTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le transfert'**
  String get modifyTransfer;

  /// No description provided for @confirmModifyTransfer.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier ce transfert ?'**
  String get confirmModifyTransfer;

  /// No description provided for @transferModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Transfert modifié avec succès.'**
  String get transferModifiedSuccess;

  /// No description provided for @observationOptional.
  ///
  /// In fr, this message translates to:
  /// **'Observation (facultatif)'**
  String get observationOptional;

  /// No description provided for @userHash.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur'**
  String get userHash;

  /// No description provided for @deleteUsers.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Utilisateurs'**
  String get deleteUsers;

  /// No description provided for @selectedUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs sélectionnés :'**
  String get selectedUsers;

  /// No description provided for @confirmDeleteUsers.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces utilisateurs ?'**
  String get confirmDeleteUsers;

  /// No description provided for @usersDeletedCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} utilisateur(s) supprimé(s) avec succès.'**
  String usersDeletedCount(Object count);

  /// No description provided for @modifyUser.
  ///
  /// In fr, this message translates to:
  /// **'Modification Utilisateur'**
  String get modifyUser;

  /// No description provided for @newUser.
  ///
  /// In fr, this message translates to:
  /// **'Nouvel Utilisateur'**
  String get newUser;

  /// No description provided for @usernameHint.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'utilisateur'**
  String get usernameHint;

  /// No description provided for @confirmModifyUser.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier cet utilisateur ?'**
  String get confirmModifyUser;

  /// No description provided for @userModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur modifié avec succès.'**
  String get userModifiedSuccess;

  /// No description provided for @userSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur enregistré avec succès.'**
  String get userSavedSuccess;

  /// No description provided for @paymentHash.
  ///
  /// In fr, this message translates to:
  /// **'Versement'**
  String get paymentHash;

  /// No description provided for @activatePayments.
  ///
  /// In fr, this message translates to:
  /// **'Activer les Versements'**
  String get activatePayments;

  /// No description provided for @selectedPayments.
  ///
  /// In fr, this message translates to:
  /// **'Versements sélectionnés :'**
  String get selectedPayments;

  /// No description provided for @confirmActivatePayments.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir activer ces versements ?'**
  String get confirmActivatePayments;

  /// No description provided for @deletePayments.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Versements'**
  String get deletePayments;

  /// No description provided for @confirmDeletePayments.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer les versements sélectionnés ?'**
  String get confirmDeletePayments;

  /// No description provided for @paymentsDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Versements supprimés avec succès.'**
  String get paymentsDeletedSuccess;

  /// No description provided for @paymentType.
  ///
  /// In fr, this message translates to:
  /// **'Type Versement'**
  String get paymentType;

  /// No description provided for @modifyPayment.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Versement'**
  String get modifyPayment;

  /// No description provided for @modifyPaymentExit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier Versement (Sortie)'**
  String get modifyPaymentExit;

  /// No description provided for @newPayment.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Versement'**
  String get newPayment;

  /// No description provided for @newPaymentExit.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau Versement (Sortie)'**
  String get newPaymentExit;

  /// No description provided for @confirmModifyPayment.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier ce versement ?'**
  String get confirmModifyPayment;

  /// No description provided for @paymentModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Versement modifié avec succès.'**
  String get paymentModifiedSuccess;

  /// No description provided for @paymentSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Versement enregistré avec succès.'**
  String get paymentSavedSuccess;

  /// No description provided for @sense.
  ///
  /// In fr, this message translates to:
  /// **'Sens'**
  String get sense;

  /// No description provided for @paymentExit.
  ///
  /// In fr, this message translates to:
  /// **'Versement (Sortie)'**
  String get paymentExit;

  /// No description provided for @zakats.
  ///
  /// In fr, this message translates to:
  /// **'Zakats'**
  String get zakats;

  /// No description provided for @deleteZakat.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Zakat'**
  String get deleteZakat;

  /// No description provided for @selectedZakats.
  ///
  /// In fr, this message translates to:
  /// **'Zakats sélectionnées :'**
  String get selectedZakats;

  /// No description provided for @confirmDeleteZakats.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces Zakats ?'**
  String get confirmDeleteZakats;

  /// No description provided for @zakatsDeletedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Zakats supprimées avec succès.'**
  String get zakatsDeletedSuccess;

  /// No description provided for @alreadyPaid.
  ///
  /// In fr, this message translates to:
  /// **'Déjà payée'**
  String get alreadyPaid;

  /// No description provided for @cannotDeletePaidZakat.
  ///
  /// In fr, this message translates to:
  /// **'Certaines Zakats sont déjà payées et ne peuvent pas être supprimées.'**
  String get cannotDeletePaidZakat;

  /// No description provided for @financialData.
  ///
  /// In fr, this message translates to:
  /// **'Données financières'**
  String get financialData;

  /// No description provided for @liquidities.
  ///
  /// In fr, this message translates to:
  /// **'Liquidités'**
  String get liquidities;

  /// No description provided for @rulesZakat.
  ///
  /// In fr, this message translates to:
  /// **'Règles & Zakat'**
  String get rulesZakat;

  /// No description provided for @hawlDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Hawl & Échéance'**
  String get hawlDueDate;

  /// No description provided for @zakatDueDate.
  ///
  /// In fr, this message translates to:
  /// **'Date Zakat Due'**
  String get zakatDueDate;

  /// No description provided for @autoCalculate.
  ///
  /// In fr, this message translates to:
  /// **'Calcul Auto'**
  String get autoCalculate;

  /// No description provided for @autoCalculateFromProducts.
  ///
  /// In fr, this message translates to:
  /// **'Calcul automatique depuis les produits'**
  String get autoCalculateFromProducts;

  /// No description provided for @stockValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur stock'**
  String get stockValue;

  /// No description provided for @cashBank.
  ///
  /// In fr, this message translates to:
  /// **'Cash + Banque'**
  String get cashBank;

  /// No description provided for @moneyToReceive.
  ///
  /// In fr, this message translates to:
  /// **'Argent à recevoir'**
  String get moneyToReceive;

  /// No description provided for @shortTermDebts.
  ///
  /// In fr, this message translates to:
  /// **'Dettes à court terme'**
  String get shortTermDebts;

  /// No description provided for @rulesStatus.
  ///
  /// In fr, this message translates to:
  /// **'Règles & Statut'**
  String get rulesStatus;

  /// No description provided for @nissabThreshold.
  ///
  /// In fr, this message translates to:
  /// **'Seuil nissab'**
  String get nissabThreshold;

  /// No description provided for @ratePercent.
  ///
  /// In fr, this message translates to:
  /// **'Taux (%)'**
  String get ratePercent;

  /// No description provided for @nissabNotDefined.
  ///
  /// In fr, this message translates to:
  /// **'Nissab non défini ou égal à 0'**
  String get nissabNotDefined;

  /// No description provided for @zakatMandatory.
  ///
  /// In fr, this message translates to:
  /// **'Zakat obligatoire (capital ≥ nissab)'**
  String get zakatMandatory;

  /// No description provided for @zakatNotMandatory.
  ///
  /// In fr, this message translates to:
  /// **'Zakat non obligatoire (capital < nissab)'**
  String get zakatNotMandatory;

  /// No description provided for @modifyZakat.
  ///
  /// In fr, this message translates to:
  /// **'Modification Zakat'**
  String get modifyZakat;

  /// No description provided for @newZakat.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Zakat'**
  String get newZakat;

  /// No description provided for @confirmModifyZakat.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir modifier cette Zakat ?'**
  String get confirmModifyZakat;

  /// No description provided for @zakatModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Zakat modifiée avec succès.'**
  String get zakatModifiedSuccess;

  /// No description provided for @zakatSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Zakat enregistrée avec succès.'**
  String get zakatSavedSuccess;

  /// No description provided for @confirmDeleteEntries.
  ///
  /// In fr, this message translates to:
  /// **'Êtes-vous sûr de vouloir supprimer ces entrées ?'**
  String get confirmDeleteEntries;

  /// No description provided for @entryModifiedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Entrée modifiée avec succès.'**
  String get entryModifiedSuccess;

  /// No description provided for @entrySavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Entrée enregistrée avec succès.'**
  String get entrySavedSuccess;

  /// No description provided for @selectedEntries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées sélectionnées :'**
  String get selectedEntries;

  /// No description provided for @deleteEntries.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer les Entrées'**
  String get deleteEntries;

  /// No description provided for @supplierCode.
  ///
  /// In fr, this message translates to:
  /// **'Code fournisseur'**
  String get supplierCode;

  /// No description provided for @deleteEntry.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer Entrée'**
  String get deleteEntry;

  /// No description provided for @modifyEntry.
  ///
  /// In fr, this message translates to:
  /// **'Modification Entrée'**
  String get modifyEntry;

  /// No description provided for @newEntry.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle Entrée'**
  String get newEntry;

  /// No description provided for @entries.
  ///
  /// In fr, this message translates to:
  /// **'Entrées'**
  String get entries;

  /// No description provided for @cashTicketReceipt.
  ///
  /// In fr, this message translates to:
  /// **'TICKET DE CAISSE'**
  String get cashTicketReceipt;

  /// No description provided for @ticketNumber.
  ///
  /// In fr, this message translates to:
  /// **'Ticket N°'**
  String get ticketNumber;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Rendu'**
  String get change;

  /// No description provided for @thankYou.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre visite!'**
  String get thankYou;

  /// No description provided for @seeYouSoon.
  ///
  /// In fr, this message translates to:
  /// **'À bientôt'**
  String get seeYouSoon;

  /// No description provided for @magaprinc.
  ///
  /// In fr, this message translates to:
  /// **'Magasin Principal'**
  String get magaprinc;

  /// No description provided for @paymentAmountMustBePositive.
  ///
  /// In fr, this message translates to:
  /// **'Le montant payé doit être supérieur à 0'**
  String get paymentAmountMustBePositive;

  /// No description provided for @printTicket.
  ///
  /// In fr, this message translates to:
  /// **'Impression du Ticket'**
  String get printTicket;

  /// No description provided for @printTicketConfirmation.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous imprimer le ticket maintenant ?'**
  String get printTicketConfirmation;

  /// No description provided for @bluetoothDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Bluetooth désactivé'**
  String get bluetoothDisabled;

  /// No description provided for @noPrinterFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune imprimante appairée trouvée'**
  String get noPrinterFound;

  /// No description provided for @selectPrinter.
  ///
  /// In fr, this message translates to:
  /// **'Choisir l\'imprimante'**
  String get selectPrinter;

  /// No description provided for @connectionFailed.
  ///
  /// In fr, this message translates to:
  /// **'Connexion échouée'**
  String get connectionFailed;

  /// No description provided for @printFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impression échouée'**
  String get printFailed;

  /// No description provided for @ticketPrintedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Ticket imprimé avec succès !'**
  String get ticketPrintedSuccess;

  /// No description provided for @printError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'impression'**
  String get printError;

  /// No description provided for @autoPrintDisabled.
  ///
  /// In fr, this message translates to:
  /// **'Impression automatique désactivée'**
  String get autoPrintDisabled;

  /// No description provided for @ticketPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du ticket'**
  String get ticketPreview;

  /// Countdown for auto-print
  ///
  /// In fr, this message translates to:
  /// **'Impression automatique dans {seconds} secondes...'**
  String autoPrintIn(int seconds);

  /// No description provided for @printNow.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer maintenant'**
  String get printNow;

  /// No description provided for @partialPayment.
  ///
  /// In fr, this message translates to:
  /// **'Paiement Partiel'**
  String get partialPayment;

  /// No description provided for @partialPaymentConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Voulez-vous procéder au paiement partiel ?'**
  String get partialPaymentConfirm;

  /// No description provided for @receiptPreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu du Ticket'**
  String get receiptPreview;

  /// No description provided for @print.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer'**
  String get print;

  /// No description provided for @invoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get invoice;

  /// No description provided for @deliveryNote.
  ///
  /// In fr, this message translates to:
  /// **'Bon de Livraison'**
  String get deliveryNote;

  /// No description provided for @salesReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Ticket de Vente'**
  String get salesReceipt;

  /// No description provided for @clientInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations Client'**
  String get clientInformation;

  /// No description provided for @clientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Client'**
  String get clientName;

  /// No description provided for @clientCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Client'**
  String get clientCode;

  /// No description provided for @invoiceDate.
  ///
  /// In fr, this message translates to:
  /// **'Date Facture'**
  String get invoiceDate;

  /// No description provided for @register.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get register;

  /// No description provided for @paymentDetails.
  ///
  /// In fr, this message translates to:
  /// **'Détails de Paiement'**
  String get paymentDetails;

  /// No description provided for @receivedBy.
  ///
  /// In fr, this message translates to:
  /// **'Reçu par'**
  String get receivedBy;

  /// No description provided for @cashierSignature.
  ///
  /// In fr, this message translates to:
  /// **'Signature du Caissier'**
  String get cashierSignature;

  /// No description provided for @clientSignature.
  ///
  /// In fr, this message translates to:
  /// **'Signature du Client'**
  String get clientSignature;

  /// No description provided for @paymentExceedsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Le montant payé ne peut pas dépasser le montant total'**
  String get paymentExceedsTotal;

  /// No description provided for @invoiceGenerated.
  ///
  /// In fr, this message translates to:
  /// **'Facture Générée'**
  String get invoiceGenerated;

  /// No description provided for @whatToDoWithInvoice.
  ///
  /// In fr, this message translates to:
  /// **'Que voulez-vous faire avec la facture ?'**
  String get whatToDoWithInvoice;

  /// No description provided for @preview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu'**
  String get preview;

  /// No description provided for @share.
  ///
  /// In fr, this message translates to:
  /// **'Partager'**
  String get share;

  /// No description provided for @invoiceSaved.
  ///
  /// In fr, this message translates to:
  /// **'Facture enregistrée'**
  String get invoiceSaved;

  /// No description provided for @open.
  ///
  /// In fr, this message translates to:
  /// **'Ouvrir'**
  String get open;

  /// No description provided for @invoiceShared.
  ///
  /// In fr, this message translates to:
  /// **'Facture partagée'**
  String get invoiceShared;

  /// No description provided for @invoiceGenerationError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur de génération de facture'**
  String get invoiceGenerationError;

  /// No description provided for @thankYouForYourPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Merci pour votre achat !'**
  String get thankYouForYourPurchase;

  /// No description provided for @invoicePreview.
  ///
  /// In fr, this message translates to:
  /// **'Aperçu de la Facture'**
  String get invoicePreview;

  /// No description provided for @printSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Imprimé avec succès !'**
  String get printSuccess;

  /// No description provided for @saveError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement'**
  String get saveError;

  /// No description provided for @shareError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors du partage'**
  String get shareError;

  /// No description provided for @extract.
  ///
  /// In fr, this message translates to:
  /// **'Extract'**
  String get extract;

  /// No description provided for @extractSelected.
  ///
  /// In fr, this message translates to:
  /// **'Extract Selected'**
  String get extractSelected;

  /// No description provided for @exportOptions.
  ///
  /// In fr, this message translates to:
  /// **'Export Options'**
  String get exportOptions;

  /// No description provided for @exportCompleted.
  ///
  /// In fr, this message translates to:
  /// **'Export completed!'**
  String get exportCompleted;

  /// No description provided for @exportSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Export successful'**
  String get exportSuccess;

  /// No description provided for @exportError.
  ///
  /// In fr, this message translates to:
  /// **'Export error'**
  String get exportError;

  /// No description provided for @noDataToExport.
  ///
  /// In fr, this message translates to:
  /// **'No data to export'**
  String get noDataToExport;

  /// No description provided for @totalClients.
  ///
  /// In fr, this message translates to:
  /// **'Total Clients'**
  String get totalClients;

  /// No description provided for @generationDate.
  ///
  /// In fr, this message translates to:
  /// **'Generation Date'**
  String get generationDate;

  /// No description provided for @nombreAchats.
  ///
  /// In fr, this message translates to:
  /// **'Number of Purchases'**
  String get nombreAchats;

  /// No description provided for @dernierAchat.
  ///
  /// In fr, this message translates to:
  /// **'Last Purchase'**
  String get dernierAchat;

  /// No description provided for @totalRecords.
  ///
  /// In fr, this message translates to:
  /// **'Total Enregistrements'**
  String get totalRecords;

  /// No description provided for @panierCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Panier'**
  String get panierCode;

  /// No description provided for @totalPanniers.
  ///
  /// In fr, this message translates to:
  /// **'Total Paniers'**
  String get totalPanniers;

  /// No description provided for @totalRemaining.
  ///
  /// In fr, this message translates to:
  /// **'Reste Total'**
  String get totalRemaining;

  /// Montant moyen par panier
  ///
  /// In fr, this message translates to:
  /// **'Moyenne par Panier'**
  String get averageAmount;

  /// No description provided for @selected.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionné(s)'**
  String get selected;

  /// No description provided for @totalProducts.
  ///
  /// In fr, this message translates to:
  /// **'Total Produits'**
  String get totalProducts;

  /// No description provided for @totalStockValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Stock Total'**
  String get totalStockValue;

  /// No description provided for @totalSaleValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Vente Total'**
  String get totalSaleValue;

  /// No description provided for @averagePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Moyen'**
  String get averagePrice;

  /// No description provided for @categoryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Catégorie'**
  String get categoryCode;

  /// No description provided for @categoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Catégorie'**
  String get categoryName;

  /// No description provided for @totalCategories.
  ///
  /// In fr, this message translates to:
  /// **'Total Catégories'**
  String get totalCategories;

  /// No description provided for @discountCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Remise'**
  String get discountCode;

  /// No description provided for @discountName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Remise'**
  String get discountName;

  /// No description provided for @discountType.
  ///
  /// In fr, this message translates to:
  /// **'Type Remise'**
  String get discountType;

  /// No description provided for @discountValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Remise'**
  String get discountValue;

  /// No description provided for @totalDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Total Remises'**
  String get totalDiscounts;

  /// No description provided for @packCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Pack'**
  String get packCode;

  /// No description provided for @packName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Pack'**
  String get packName;

  /// No description provided for @packPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Pack'**
  String get packPrice;

  /// No description provided for @totalPacks.
  ///
  /// In fr, this message translates to:
  /// **'Total Packs'**
  String get totalPacks;

  /// No description provided for @averagePackPrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix Moyen Pack'**
  String get averagePackPrice;

  /// No description provided for @subCategoryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Sous-Catégorie'**
  String get subCategoryCode;

  /// No description provided for @subCategoryName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Sous-Catégorie'**
  String get subCategoryName;

  /// No description provided for @totalSubCategories.
  ///
  /// In fr, this message translates to:
  /// **'Total Sous-Catégories'**
  String get totalSubCategories;

  /// No description provided for @supplierName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Fournisseur'**
  String get supplierName;

  /// No description provided for @totalSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Total Fournisseurs'**
  String get totalSuppliers;

  /// No description provided for @paymentCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Paiement'**
  String get paymentCode;

  /// No description provided for @totalPayments.
  ///
  /// In fr, this message translates to:
  /// **'Total Paiements'**
  String get totalPayments;

  /// No description provided for @noSupplierSelected.
  ///
  /// In fr, this message translates to:
  /// **'Aucun fournisseur sélectionné'**
  String get noSupplierSelected;

  /// No description provided for @entryCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Entrée'**
  String get entryCode;

  /// No description provided for @totalEntries.
  ///
  /// In fr, this message translates to:
  /// **'Total Entrées'**
  String get totalEntries;

  /// No description provided for @scanCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Scan'**
  String get scanCode;

  /// No description provided for @totalScans.
  ///
  /// In fr, this message translates to:
  /// **'Total Scans'**
  String get totalScans;

  /// No description provided for @exitCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Sortie'**
  String get exitCode;

  /// No description provided for @totalExits.
  ///
  /// In fr, this message translates to:
  /// **'Total Sorties'**
  String get totalExits;

  /// No description provided for @returnCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Retour'**
  String get returnCode;

  /// No description provided for @totalReturns.
  ///
  /// In fr, this message translates to:
  /// **'Total Retours'**
  String get totalReturns;

  /// No description provided for @clientReturns.
  ///
  /// In fr, this message translates to:
  /// **'Retours Clients'**
  String get clientReturns;

  /// No description provided for @supplierReturns.
  ///
  /// In fr, this message translates to:
  /// **'Retours Fournisseurs'**
  String get supplierReturns;

  /// No description provided for @movementCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Mouvement'**
  String get movementCode;

  /// No description provided for @totalMovements.
  ///
  /// In fr, this message translates to:
  /// **'Total Mouvements'**
  String get totalMovements;

  /// No description provided for @clientMovements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements Clients'**
  String get clientMovements;

  /// No description provided for @supplierMovements.
  ///
  /// In fr, this message translates to:
  /// **'Mouvements Fournisseurs'**
  String get supplierMovements;

  /// No description provided for @listCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Liste'**
  String get listCode;

  /// No description provided for @totalLists.
  ///
  /// In fr, this message translates to:
  /// **'Total Listes'**
  String get totalLists;

  /// No description provided for @withSuppliers.
  ///
  /// In fr, this message translates to:
  /// **'Avec Fournisseurs'**
  String get withSuppliers;

  /// No description provided for @userCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Utilisateur'**
  String get userCode;

  /// No description provided for @userName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Utilisateur'**
  String get userName;

  /// No description provided for @totalUsers.
  ///
  /// In fr, this message translates to:
  /// **'Total Utilisateurs'**
  String get totalUsers;

  /// No description provided for @adminUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs Admin'**
  String get adminUsers;

  /// No description provided for @cashierUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs Caissier'**
  String get cashierUsers;

  /// No description provided for @storekeeperUsers.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs Magasinier'**
  String get storekeeperUsers;

  /// No description provided for @roleCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Rôle'**
  String get roleCode;

  /// No description provided for @totalRoles.
  ///
  /// In fr, this message translates to:
  /// **'Total Rôles'**
  String get totalRoles;

  /// No description provided for @storeCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Magasin'**
  String get storeCode;

  /// No description provided for @storeName.
  ///
  /// In fr, this message translates to:
  /// **'Nom Magasin'**
  String get storeName;

  /// No description provided for @totalStores.
  ///
  /// In fr, this message translates to:
  /// **'Total Magasins'**
  String get totalStores;

  /// No description provided for @averageStorageRate.
  ///
  /// In fr, this message translates to:
  /// **'Taux Stockage Moyen'**
  String get averageStorageRate;

  /// No description provided for @totalBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde Total'**
  String get totalBalance;

  /// No description provided for @totalArticles.
  ///
  /// In fr, this message translates to:
  /// **'Total Articles'**
  String get totalArticles;

  /// No description provided for @totalProductsInCategories.
  ///
  /// In fr, this message translates to:
  /// **'Total Produits dans les Catégories'**
  String get totalProductsInCategories;

  /// No description provided for @averageProductsPerCategory.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne Produits par Catégorie'**
  String get averageProductsPerCategory;

  /// No description provided for @totalUsage.
  ///
  /// In fr, this message translates to:
  /// **'Utilisation Totale'**
  String get totalUsage;

  /// No description provided for @percentageDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises en Pourcentage'**
  String get percentageDiscounts;

  /// No description provided for @fixedDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises Fixes'**
  String get fixedDiscounts;

  /// No description provided for @averageDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Remise Moyenne'**
  String get averageDiscount;

  /// No description provided for @totalProductsInPacks.
  ///
  /// In fr, this message translates to:
  /// **'Total Produits dans les Packs'**
  String get totalProductsInPacks;

  /// No description provided for @totalValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur Totale'**
  String get totalValue;

  /// No description provided for @totalProductsInSubCategories.
  ///
  /// In fr, this message translates to:
  /// **'Total Produits dans les Sous-Catégories'**
  String get totalProductsInSubCategories;

  /// No description provided for @averageProductsPerSubCategory.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne Produits par Sous-Catégorie'**
  String get averageProductsPerSubCategory;

  /// No description provided for @incomingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Entrant'**
  String get incomingAmount;

  /// No description provided for @outgoingAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Sortant'**
  String get outgoingAmount;

  /// No description provided for @clientPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements Clients'**
  String get clientPayments;

  /// No description provided for @supplierPayments.
  ///
  /// In fr, this message translates to:
  /// **'Paiements Fournisseurs'**
  String get supplierPayments;

  /// No description provided for @averageQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité Moyenne'**
  String get averageQuantity;

  /// No description provided for @createdByCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Créé Par'**
  String get createdByCode;

  /// No description provided for @totalCalculatedAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Total Calculé'**
  String get totalCalculatedAmount;

  /// No description provided for @totalCalculatedProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits Totaux Calculés'**
  String get totalCalculatedProducts;

  /// No description provided for @totalCalculatedQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité Totale Calculée'**
  String get totalCalculatedQuantity;

  /// No description provided for @scansWithGap.
  ///
  /// In fr, this message translates to:
  /// **'Scans avec Écart'**
  String get scansWithGap;

  /// No description provided for @breakdownByType.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par Type'**
  String get breakdownByType;

  /// No description provided for @count.
  ///
  /// In fr, this message translates to:
  /// **'Nombre'**
  String get count;

  /// No description provided for @totalPurchaseValue.
  ///
  /// In fr, this message translates to:
  /// **'Valeur d\'Achat Totale'**
  String get totalPurchaseValue;

  /// No description provided for @totalItems.
  ///
  /// In fr, this message translates to:
  /// **'Total Articles'**
  String get totalItems;

  /// No description provided for @averageItems.
  ///
  /// In fr, this message translates to:
  /// **'Moyenne Articles'**
  String get averageItems;

  /// No description provided for @totalSales.
  ///
  /// In fr, this message translates to:
  /// **'Total des Ventes'**
  String get totalSales;

  /// No description provided for @averageSalesPerUser.
  ///
  /// In fr, this message translates to:
  /// **'Ventes Moyennes par Utilisateur'**
  String get averageSalesPerUser;

  /// No description provided for @averageUsersPerRole.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs Moyens par Rôle'**
  String get averageUsersPerRole;

  /// No description provided for @maxProducts.
  ///
  /// In fr, this message translates to:
  /// **'Max Produits'**
  String get maxProducts;

  /// No description provided for @minProducts.
  ///
  /// In fr, this message translates to:
  /// **'Min Produits'**
  String get minProducts;

  /// No description provided for @cashRegisterCode.
  ///
  /// In fr, this message translates to:
  /// **'Code Caisse'**
  String get cashRegisterCode;

  /// No description provided for @totalCaisses.
  ///
  /// In fr, this message translates to:
  /// **'Total Caisses'**
  String get totalCaisses;

  /// No description provided for @averageBalance.
  ///
  /// In fr, this message translates to:
  /// **'Solde Moyen'**
  String get averageBalance;

  /// No description provided for @storesWithCaisses.
  ///
  /// In fr, this message translates to:
  /// **'Magasins avec Caisses'**
  String get storesWithCaisses;

  /// No description provided for @insertions.
  ///
  /// In fr, this message translates to:
  /// **'Insertions'**
  String get insertions;

  /// No description provided for @logins.
  ///
  /// In fr, this message translates to:
  /// **'Connexions'**
  String get logins;

  /// No description provided for @logouts.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexions'**
  String get logouts;

  /// No description provided for @totalZakatRecords.
  ///
  /// In fr, this message translates to:
  /// **'Total Enregistrements Zakat'**
  String get totalZakatRecords;

  /// No description provided for @totalZakatAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant Total Zakat'**
  String get totalZakatAmount;

  /// No description provided for @paidZakat.
  ///
  /// In fr, this message translates to:
  /// **'Zakat Payée'**
  String get paidZakat;

  /// No description provided for @unpaidZakat.
  ///
  /// In fr, this message translates to:
  /// **'Zakat Non Payée'**
  String get unpaidZakat;

  /// No description provided for @mandatoryZakat.
  ///
  /// In fr, this message translates to:
  /// **'Zakat Obligatoire'**
  String get mandatoryZakat;

  /// No description provided for @userInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations utilisateur'**
  String get userInformation;

  /// No description provided for @shopInformation.
  ///
  /// In fr, this message translates to:
  /// **'Informations magasin'**
  String get shopInformation;

  /// No description provided for @systemSettings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres système'**
  String get systemSettings;

  /// No description provided for @shopName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du magasin'**
  String get shopName;

  /// No description provided for @appId.
  ///
  /// In fr, this message translates to:
  /// **'ID de l\'application'**
  String get appId;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @reset.
  ///
  /// In fr, this message translates to:
  /// **'Réinitialiser'**
  String get reset;

  /// No description provided for @enterUsername.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nom d\'utilisateur'**
  String get enterUsername;

  /// No description provided for @enterShopName.
  ///
  /// In fr, this message translates to:
  /// **'Entrez le nom du magasin'**
  String get enterShopName;

  /// No description provided for @enterAppId.
  ///
  /// In fr, this message translates to:
  /// **'Entrez l\'ID de l\'application'**
  String get enterAppId;

  /// No description provided for @settingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'✅ Paramètres enregistrés'**
  String get settingsSaved;

  /// No description provided for @currencye.
  ///
  /// In fr, this message translates to:
  /// **'Devise'**
  String get currencye;

  /// No description provided for @operationFailed.
  ///
  /// In fr, this message translates to:
  /// **'L\'opération echoué'**
  String get operationFailed;

  /// No description provided for @ticketSavedSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Ticket enregistré'**
  String get ticketSavedSuccess;

  /// No description provided for @addProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter produit'**
  String get addProduct;

  /// No description provided for @mouvement.
  ///
  /// In fr, this message translates to:
  /// **'Mouvement'**
  String get mouvement;

  /// No description provided for @noPhotos.
  ///
  /// In fr, this message translates to:
  /// **'Pad de Photos'**
  String get noPhotos;

  /// No description provided for @attention.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get attention;

  /// No description provided for @salesprevious.
  ///
  /// In fr, this message translates to:
  /// **'Ventes (Précedent periode)'**
  String get salesprevious;

  /// No description provided for @paye.
  ///
  /// In fr, this message translates to:
  /// **'Payé'**
  String get paye;

  /// No description provided for @reste.
  ///
  /// In fr, this message translates to:
  /// **'Reste'**
  String get reste;

  /// No description provided for @packagingPrix1.
  ///
  /// In fr, this message translates to:
  /// **'Prix Emballage 1'**
  String get packagingPrix1;

  /// No description provided for @packagingPrix2.
  ///
  /// In fr, this message translates to:
  /// **'Prix Emballage 2'**
  String get packagingPrix2;

  /// No description provided for @packagingPrice1Hint.
  ///
  /// In fr, this message translates to:
  /// **'Prix de boîte'**
  String get packagingPrice1Hint;

  /// No description provided for @packagingPrice2Hint.
  ///
  /// In fr, this message translates to:
  /// **'Prix de carton'**
  String get packagingPrice2Hint;

  /// No description provided for @lepannierestenregestre.
  ///
  /// In fr, this message translates to:
  /// **'Le pannier est bien enregistré'**
  String get lepannierestenregestre;

  /// No description provided for @lepanniernestpasenregestre.
  ///
  /// In fr, this message translates to:
  /// **'l\'opération est échoué'**
  String get lepanniernestpasenregestre;

  /// No description provided for @marge.
  ///
  /// In fr, this message translates to:
  /// **'Marge'**
  String get marge;

  /// No description provided for @confirmPrint.
  ///
  /// In fr, this message translates to:
  /// **'Confirmation'**
  String get confirmPrint;

  /// No description provided for @aiMode.
  ///
  /// In fr, this message translates to:
  /// **'IA'**
  String get aiMode;

  /// No description provided for @aiModeDescription.
  ///
  /// In fr, this message translates to:
  /// **'Utilisez le bouton \'Nouveau\' pour scanner un reçu avec l\'IA'**
  String get aiModeDescription;

  /// No description provided for @aiReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Reçu IA'**
  String get aiReceipt;

  /// No description provided for @uploadReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Importer un reçu'**
  String get uploadReceipt;

  /// No description provided for @processing.
  ///
  /// In fr, this message translates to:
  /// **'Traitement en cours...'**
  String get processing;

  /// No description provided for @tapToSelectImage.
  ///
  /// In fr, this message translates to:
  /// **'Appuyez pour sélectionner une image'**
  String get tapToSelectImage;

  /// No description provided for @originalName.
  ///
  /// In fr, this message translates to:
  /// **'Nom d\'origine'**
  String get originalName;

  /// No description provided for @mappedProduct.
  ///
  /// In fr, this message translates to:
  /// **'Produit associé'**
  String get mappedProduct;

  /// No description provided for @selectProduct.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez un produit'**
  String get selectProduct;

  /// No description provided for @addManualProduct.
  ///
  /// In fr, this message translates to:
  /// **'+ Ajouter un produit manuellement'**
  String get addManualProduct;

  /// No description provided for @colis.
  ///
  /// In fr, this message translates to:
  /// **'Colis'**
  String get colis;

  /// No description provided for @actualQty.
  ///
  /// In fr, this message translates to:
  /// **'Actuel Quantité'**
  String get actualQty;

  /// No description provided for @quickEntry.
  ///
  /// In fr, this message translates to:
  /// **'Entrée rapide'**
  String get quickEntry;

  /// No description provided for @cashReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Recette caisse'**
  String get cashReceipt;

  /// No description provided for @cashReceiptTitle.
  ///
  /// In fr, this message translates to:
  /// **'Recette de la caisse'**
  String get cashReceiptTitle;

  /// No description provided for @numberOfSales.
  ///
  /// In fr, this message translates to:
  /// **'Nombre de ventes'**
  String get numberOfSales;

  /// No description provided for @recentSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes récentes'**
  String get recentSales;

  /// No description provided for @noSalesFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune vente trouvée pour cette caisse'**
  String get noSalesFound;

  /// No description provided for @clearFilters.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer filtre'**
  String get clearFilters;

  /// No description provided for @selectStoreForProduct.
  ///
  /// In fr, this message translates to:
  /// **'Merci de sélectionner un magasin pour le destockage'**
  String get selectStoreForProduct;

  /// No description provided for @requestedQuantity.
  ///
  /// In fr, this message translates to:
  /// **'Choisir la quantité'**
  String get requestedQuantity;

  /// No description provided for @selectStore.
  ///
  /// In fr, this message translates to:
  /// **'Selectionné magasin'**
  String get selectStore;

  /// No description provided for @discountAmountExceedsTotal.
  ///
  /// In fr, this message translates to:
  /// **'Le montant de la remise ({amount}) dépasse le total du panier ({total}) !'**
  String discountAmountExceedsTotal(Object amount, Object total);

  /// No description provided for @totalFinal.
  ///
  /// In fr, this message translates to:
  /// **'Total Final'**
  String get totalFinal;

  /// No description provided for @totalBeforeDiscount.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get totalBeforeDiscount;

  /// No description provided for @quantityMustBeGreaterThanZero.
  ///
  /// In fr, this message translates to:
  /// **'La quantité doit être supérieure à 0'**
  String get quantityMustBeGreaterThanZero;

  /// No description provided for @priceMustBeGreaterThanZero.
  ///
  /// In fr, this message translates to:
  /// **'Le prix doit être supérieur à 0'**
  String get priceMustBeGreaterThanZero;

  /// No description provided for @supplierRequired.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner un fournisseur'**
  String get supplierRequired;

  /// No description provided for @loading.
  ///
  /// In fr, this message translates to:
  /// **'Chargement...'**
  String get loading;

  /// No description provided for @saving.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement...'**
  String get saving;

  /// No description provided for @errorSavingSettings.
  ///
  /// In fr, this message translates to:
  /// **'Erreur lors de l\'enregistrement des paramètres'**
  String get errorSavingSettings;

  /// No description provided for @settingsReset.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres réinitialisés'**
  String get settingsReset;

  /// No description provided for @userNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur non trouvé'**
  String get userNotFound;

  /// No description provided for @pleaseLoginFirst.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez vous connecter d\'abord'**
  String get pleaseLoginFirst;

  /// No description provided for @rolePermissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions du rôle'**
  String get rolePermissions;

  /// No description provided for @selectAtLeastOnePermission.
  ///
  /// In fr, this message translates to:
  /// **'Veuillez sélectionner au moins une permission'**
  String get selectAtLeastOnePermission;

  /// No description provided for @warning.
  ///
  /// In fr, this message translates to:
  /// **'Attention'**
  String get warning;

  /// No description provided for @permissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions'**
  String get permissions;

  /// No description provided for @permissionsDescription.
  ///
  /// In fr, this message translates to:
  /// **'Configurez les permissions pour ce rôle'**
  String get permissionsDescription;

  /// No description provided for @selectPermissions.
  ///
  /// In fr, this message translates to:
  /// **'Permissions du rôle'**
  String get selectPermissions;

  /// No description provided for @selectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout sélectionner'**
  String get selectAll;

  /// No description provided for @deselectAll.
  ///
  /// In fr, this message translates to:
  /// **'Tout désélectionner'**
  String get deselectAll;

  /// No description provided for @previous.
  ///
  /// In fr, this message translates to:
  /// **'Précédent'**
  String get previous;

  /// No description provided for @roleInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations du rôle'**
  String get roleInfo;

  /// No description provided for @passwordTooShort.
  ///
  /// In fr, this message translates to:
  /// **'Le mot de passe doit contenir au moins 4 caractères'**
  String get passwordTooShort;

  /// No description provided for @valueMustBeGreaterThanZero.
  ///
  /// In fr, this message translates to:
  /// **'La valeur doit être supérieure à 0'**
  String get valueMustBeGreaterThanZero;

  /// No description provided for @sourceAndDestinationMustBeDifferent.
  ///
  /// In fr, this message translates to:
  /// **'La caisse source et la caisse de destination doivent être différentes.'**
  String get sourceAndDestinationMustBeDifferent;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
