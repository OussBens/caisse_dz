// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get dashboard => 'Dashboard';

  @override
  String get situation => 'Situation';

  @override
  String get salesToday => 'Sales Today';

  @override
  String get purchaseToday => 'Purchase Today';

  @override
  String get netToday => 'Net Today';

  @override
  String get supplierDebt => 'Supplier Debt';

  @override
  String get clientCredit => 'Client Credit';

  @override
  String get selectPeriod => 'Select a period';

  @override
  String get pleaseSelectTwoDates =>
      'Please select two dates to get a detailed dashboard of the statistics for that period';

  @override
  String get salesByHour => 'Sales by Hour';

  @override
  String get salesByDay => 'Sales by Day';

  @override
  String get salesByWeek => 'Sales by Week';

  @override
  String get revenueByCashier => 'Revenue by Cashier';

  @override
  String get salesByProduct => 'Sales by Product';

  @override
  String get salesByPaymentMethod => 'Sales by Payment Method';

  @override
  String get revenueDistribution => 'Revenue Distribution';

  @override
  String get revenueByCart => 'Cash Revenue by Cart';

  @override
  String get revenueByProductCard => 'Cash Revenue by Product';

  @override
  String get cashRegisterMovement => 'Cash Register Movement';

  @override
  String get dailyProfitByCart => 'Daily Profit (margin by cart)';

  @override
  String get profitByPeriod => 'Profit by Period (margin by day)';

  @override
  String get inventory => 'Inventory';

  @override
  String get net => 'Net';

  @override
  String get numberOfDays => 'Number of Days';

  @override
  String get purchaseValue => 'Purchase Value';

  @override
  String get saleValue => 'Sale Value';

  @override
  String get potentialMargin => 'Potential Margin';

  @override
  String get collected => 'Collected';

  @override
  String get credit => 'Credit';

  @override
  String get bestClients => 'Best Clients';

  @override
  String get bestSuppliers => 'Best Suppliers';

  @override
  String get topCredits => 'Top Credits';

  @override
  String get bestSellingProducts => 'Best Selling Products';

  @override
  String get outOfStockProducts => 'Out of Stock Products';

  @override
  String get expiredProducts => 'Expired Products';

  @override
  String get highestQuantityProduct => 'Highest Quantity';

  @override
  String get oldestProduct => 'Oldest Product';

  @override
  String get from => 'From';

  @override
  String get to => 'To';

  @override
  String get quickPeriod => 'Quick Period';

  @override
  String get export => 'Export';

  @override
  String get noData => 'No data';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get thisWeek => 'This Week';

  @override
  String get lastWeek => 'Last Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get lastMonth => 'Last Month';

  @override
  String get last7Days => 'Last 7 Days';

  @override
  String get last30Days => 'Last 30 Days';

  @override
  String get thisYear => 'This Year';

  @override
  String get lastYear => 'Last Year';

  @override
  String get caisse => 'Cash Register';

  @override
  String get produit => 'Product';

  @override
  String get panier => 'Cart';

  @override
  String get client => 'Customer';

  @override
  String get fournisseur => 'Supplier';

  @override
  String get entree => 'Entry';

  @override
  String get sortie => 'Exit';

  @override
  String get retour => 'Return';

  @override
  String get stock => 'Stock';

  @override
  String get besoin => 'Need';

  @override
  String get utilisateur => 'User';

  @override
  String get magasin => 'Store';

  @override
  String get gestionCaisse => 'Cash Management';

  @override
  String get zakat => 'Zakat';

  @override
  String get parametre => 'Settings';

  @override
  String get historique => 'History';

  @override
  String get pinSidebar => 'Pin sidebar';

  @override
  String get unpinSidebar => 'Unpin sidebar';

  @override
  String get payment => 'Payment';

  @override
  String get remise => 'Discount';

  @override
  String get sousCategorie => 'Subcategory';

  @override
  String get hideProduct => 'Hide Product';

  @override
  String get showProduct => 'Show Product';

  @override
  String get noProductSelected => 'No product selected';

  @override
  String get productNotFoundBarcode => 'Product does not exist';

  @override
  String get aiScanInstructions =>
      'Scan a barcode with the reader, or enter it manually, to search for the product online.';

  @override
  String get confirmThisProduct => 'That\'s it';

  @override
  String get createNewProduct => 'Create new';

  @override
  String get cannotDeleteLastCaisse => 'Cannot delete the last cash register';

  @override
  String get deleteCaisseTitle => 'Delete Cash Register';

  @override
  String deleteCaisseMessage(Object caisseName) {
    return 'Please confirm deletion of $caisseName. All carts will be lost.';
  }

  @override
  String get clearCartTitle => 'Clear Cart';

  @override
  String get clearCartMessage =>
      'Please confirm deletion of all products from the cart';

  @override
  String get emptyCartError => '❌ Cart is empty';

  @override
  String get emptyCart => 'Cart is empty';

  @override
  String get addProductsToStart => 'Add products to get started';

  @override
  String get maxCaissesReached => 'Maximum 10 active cash registers';

  @override
  String get loadingParams => 'Loading parameters...';

  @override
  String get settingsSavedSuccess => 'Settings saved successfully';

  @override
  String get encaisserTicket => 'Cash Ticket';

  @override
  String get enregistrer => 'Save';

  @override
  String get encaisserBLSC => 'Cash Invoice';

  @override
  String get annuler => 'Cancel';

  @override
  String get serverError => 'Server error!';

  @override
  String get noResultsFound => 'No results found.';

  @override
  String get besoinList => 'Need List';

  @override
  String get categorie => 'Category';

  @override
  String get dash => 'Dashboard';

  @override
  String get pack => 'Pack';

  @override
  String get parametreProduit => 'Product Settings';

  @override
  String get parametreCaisse => 'Cash Register Settings';

  @override
  String get role => 'Role';

  @override
  String get sCategorie => 'Subcategory';

  @override
  String get transfert => 'Transfer';

  @override
  String get versement => 'Payment';

  @override
  String get achat => 'Purchase';

  @override
  String get vente => 'Sale';

  @override
  String get insertion => 'Insertion';

  @override
  String get modification => 'Modification';

  @override
  String get suppression => 'Deletion';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get loginWelcome => 'WELCOME';

  @override
  String get loginToYourAccount => 'Login to your account';

  @override
  String get loginInstructions => 'Please enter your credentials to sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get rememberMe => 'Remember me';

  @override
  String get initialSetupTitle => 'Initial Setup';

  @override
  String get initialSetupSubtitle =>
      'Set up your shop information before you begin. You can always change it later in Settings.';

  @override
  String get finish => 'Finish';

  @override
  String get invalidCredentials => 'Incorrect username or password';

  @override
  String get signIn => 'Sign in';

  @override
  String get appNotActivatedQuestion => 'Application not activated?';

  @override
  String get activateNow => 'Activate now';

  @override
  String get version => 'Version';

  @override
  String get actif => 'Active';

  @override
  String get inactif => 'Inactive';

  @override
  String get valide => 'Validated';

  @override
  String get annule => 'Cancelled';

  @override
  String get parMontant => 'By Amount';

  @override
  String get parProduit => 'By Product';

  @override
  String get enAttente => 'Pending';

  @override
  String get commande => 'Order';

  @override
  String get disponible => 'Available';

  @override
  String get expiration => 'Expiration';

  @override
  String get don => 'Donation';

  @override
  String get montant => 'Amount';

  @override
  String get pourcentage => 'Percentage';

  @override
  String get bl => 'BL';

  @override
  String get blSc => 'BL/SC';

  @override
  String get facture => 'Invoice';

  @override
  String get physique => 'Physical';

  @override
  String get compte => 'Account';

  @override
  String get piece => 'Piece';

  @override
  String get purchaseMode => 'Purchase Mode';

  @override
  String get perUnitOption => 'Per Unit';

  @override
  String get perBoxOption => 'Per Box';

  @override
  String get perCartonOption => 'Per Carton';

  @override
  String get piecesUnit => 'piece(s)';

  @override
  String get boxesUnit => 'box(es)';

  @override
  String get cartonsUnit => 'carton(s)';

  @override
  String equalToPieces(Object count) {
    return 'Equal to $count piece(s)';
  }

  @override
  String availableStockPieces(Object count) {
    return 'Available stock: $count piece(s)';
  }

  @override
  String insufficientStockDetail(Object demande, Object disponible) {
    return 'Insufficient stock!\nAvailable: $disponible piece(s)\nRequested: $demande piece(s)';
  }

  @override
  String get noPhotoAvailable => 'No photo';

  @override
  String get imageNotFound => 'Image not found';

  @override
  String get litre => 'Liter';

  @override
  String get metre => 'Meter';

  @override
  String get avancement => 'Advance';

  @override
  String get complementFacture => 'Invoice Complement';

  @override
  String get dette => 'Debt';

  @override
  String get paiement => 'Payment';

  @override
  String get remboursement => 'Refund';

  @override
  String get acompte => 'Deposit';

  @override
  String get remiseVersement => 'Discount';

  @override
  String get especes => 'Cash';

  @override
  String get carte => 'Card';

  @override
  String get cheque => 'Check';

  @override
  String get usine => 'Factory';

  @override
  String get societe => 'Company';

  @override
  String get importateur => 'Importer';

  @override
  String get grossiste => 'Wholesaler';

  @override
  String get semiGrossiste => 'Semi-wholesaler';

  @override
  String get detailant => 'Retailer';

  @override
  String get consommateur => 'Consumer';

  @override
  String get destockage => 'Destocking';

  @override
  String get cosmetique => 'Cosmetics';

  @override
  String get alimentation => 'Food';

  @override
  String get quincaillerie => 'Hardware';

  @override
  String get electromenager => 'Home Appliances';

  @override
  String get hygieneNettoyage => 'Hygiene & Cleaning';

  @override
  String get textileHabillement => 'Textile & Clothing';

  @override
  String get materiauxConstruction => 'Construction Materials';

  @override
  String get papeterieFournitures => 'Stationery & Supplies';

  @override
  String get piecesAutomobiles => 'Auto Parts';

  @override
  String get informatiqueAccessoires => 'IT & Accessories';

  @override
  String get telephonie => 'Telephony';

  @override
  String get meublesDecoration => 'Furniture & Decoration';

  @override
  String get produitsAgricoles => 'Agricultural Products';

  @override
  String get produitsMenagers => 'Household Products';

  @override
  String get boulangeriePatisserie => 'Bakery / Pastry';

  @override
  String get bazar => 'Bazaar';

  @override
  String get jouets => 'Toys';

  @override
  String get produitsMedicaux => 'Medical Products';

  @override
  String get particulier => 'Individual';

  @override
  String get epicerie => 'Grocery';

  @override
  String get superette => 'Mini-market';

  @override
  String get salonCoiffure => 'Hair Salon';

  @override
  String get institutBeaute => 'Beauty Institute';

  @override
  String get boutiqueVetements => 'Clothing Store';

  @override
  String get boulangerie => 'Bakery';

  @override
  String get cafeteriaFastFood => 'Cafeteria / Fast-food';

  @override
  String get restaurant => 'Restaurant';

  @override
  String get cafe => 'Coffee Shop';

  @override
  String get magasinElectromenager => 'Appliance Store';

  @override
  String get pharmacie => 'Pharmacy';

  @override
  String get magasinJouets => 'Toy Store';

  @override
  String get boutiqueTelephonie => 'Phone Store';

  @override
  String get garagePiecesAuto => 'Garage / Auto Parts';

  @override
  String get magasinInformatique => 'Computer Store';

  @override
  String get admin => 'Admin';

  @override
  String get caissier => 'Cashier';

  @override
  String get magasinier => 'Storekeeper';

  @override
  String get autre => 'Other';

  @override
  String get ticket => 'Ticket';

  @override
  String get virement => 'Transfer';

  @override
  String get parfumerie => 'Perfumery';

  @override
  String get information => 'Information';

  @override
  String get noCategorySelected => 'No category selected';

  @override
  String get selectSingleCategoryForDetail =>
      'Please select a single category to view details';

  @override
  String get cannotDeleteSystemCategory => 'Cannot delete this system category';

  @override
  String get cannotModifySystemCategory => 'Cannot modify this system category';

  @override
  String get selectSingleCategoryToModify =>
      'Please select a single category to modify';

  @override
  String get noDiscountSelected => 'No discount selected';

  @override
  String get selectSingleDiscountForDetail =>
      'Please select a single discount to view details';

  @override
  String get selectSingleDiscountToModify =>
      'Please select a single discount to modify';

  @override
  String get noDiscountExists =>
      'No discount exists yet. Create one first in the Discount tab.';

  @override
  String get noPackSelected => 'No pack selected';

  @override
  String get selectSinglePackForDetail =>
      'Please select a single pack to view details';

  @override
  String get selectSinglePackToModify =>
      'Please select a single pack to modify';

  @override
  String get noPackExists =>
      'No pack exists yet. Create one first in the Pack tab.';

  @override
  String get noSubCategorySelected => 'No subcategory selected';

  @override
  String get selectSingleSubCategoryForDetail =>
      'Please select a single subcategory to view details';

  @override
  String get cannotDeleteSystemSubCategory =>
      'Cannot delete this system subcategory';

  @override
  String get cannotModifySystemSubCategory =>
      'Cannot modify this system subcategory';

  @override
  String get selectSingleSubCategoryToModify =>
      'Please select a single subcategory to modify';

  @override
  String get filter => 'Filter';

  @override
  String get newWord => 'New';

  @override
  String get margin => 'Margin';

  @override
  String get typeCalcul => 'Calculation Type';

  @override
  String get marginRate => 'Margin Rate';

  @override
  String get threshold => 'Threshold';

  @override
  String get minimum => 'Minimum';

  @override
  String get maximum => 'Maximum';

  @override
  String get save => 'Save';

  @override
  String get by => 'by';

  @override
  String get purchasePrice => 'Purchase Price';

  @override
  String get salePrice => 'Sale Price';

  @override
  String get averagePurchasePrice => 'Average Purchase Price';

  @override
  String get averageSalePrice => 'Average Sale Price';

  @override
  String get operationCode => 'Operation Code';

  @override
  String get etat => 'Status';

  @override
  String get search => 'Search';

  @override
  String get marque => 'Brand';

  @override
  String get currency => 'DZD';

  @override
  String get quantityDecimals => 'Quantity Decimals';

  @override
  String get quantityDecimalsHint =>
      'Number of digits after the decimal point for quantity fields (throughout the app)';

  @override
  String get needCategoryToCreateSubCategory =>
      'To create a subcategory, you need at least one category (Without category is not included)';

  @override
  String get selectSingleProductForDetail =>
      'Please select a single product to view details';

  @override
  String get selectSingleProductToModify =>
      'Please select a single product to modify';

  @override
  String get typePannier => 'Cart Type';

  @override
  String get amount => 'Amount';

  @override
  String get remaining => 'Remaining';

  @override
  String get startDate => 'Start Date';

  @override
  String get endDate => 'End Date';

  @override
  String get choosePeriod => 'Choose a period';

  @override
  String get noCartSelected => 'No cart selected';

  @override
  String get selectSingleCartForDetail =>
      'Please select a single cart to view details';

  @override
  String get selectSingleCartToModify =>
      'Please select a single cart to modify';

  @override
  String get typeClient => 'Client Type';

  @override
  String get activite => 'Activity';

  @override
  String get totalAchat => 'Total Purchase';

  @override
  String get noClientSelected => 'No client selected';

  @override
  String get selectSingleClientForDetail =>
      'Please select a single client to view details';

  @override
  String get cannotDeleteSystemClient => 'Cannot delete this system client';

  @override
  String get cannotModifySystemClient => 'Cannot modify this system client';

  @override
  String get selectSingleClientToModify =>
      'Please select a single client to modify';

  @override
  String get selectSingleClientForOperations =>
      'Please select a single client to view operations';

  @override
  String get noPaymentSelected => 'No payment selected';

  @override
  String get selectSinglePaymentToModify =>
      'Please select a single payment to modify';

  @override
  String get exit => 'Exit';

  @override
  String get type => 'Type';

  @override
  String get noListSelected => 'No list selected';

  @override
  String get selectSingleListForDetail =>
      'Please select a single list to view details';

  @override
  String get selectSingleListToModify =>
      'Please select a single list to modify';

  @override
  String get noUserSelected => 'No user selected';

  @override
  String get selectSingleUserForDetail =>
      'Please select a single user to view details';

  @override
  String get selectSingleUserToModify =>
      'Please select a single user to modify';

  @override
  String get noRoleSelected => 'No role selected';

  @override
  String get selectSingleRoleForDetail =>
      'Please select a single role to view details';

  @override
  String get selectSingleRoleToModify =>
      'Please select a single role to modify';

  @override
  String get error => 'Error';

  @override
  String get loadingError => 'Error loading data';

  @override
  String get sourceCashRegister => 'Source Cash Register';

  @override
  String get destinationCashRegister => 'Destination Cash Register';

  @override
  String get newCashRegister => 'New Cash Register';

  @override
  String get newTransfer => 'New Transfer';

  @override
  String get noCashRegisterSelected => 'No cash register selected';

  @override
  String get selectSingleCashRegisterForDetail =>
      'Please select a single cash register to view details';

  @override
  String get selectSingleCashRegisterToModify =>
      'Please select a single cash register to modify';

  @override
  String get cannotDeleteSystemCashRegister =>
      'Cannot delete this system cash register';

  @override
  String get cannotModifySystemCashRegister =>
      'Cannot modify this system cash register';

  @override
  String get noTransferSelected => 'No transfer selected';

  @override
  String get selectSingleTransferForDetail =>
      'Please select a single transfer to view details';

  @override
  String get selectSingleTransferToModify =>
      'Please select a single transfer to modify';

  @override
  String get productCount => 'Product Count';

  @override
  String get noStoreSelected => 'No store selected';

  @override
  String get selectSingleStoreForDetail =>
      'Please select a single store to view details';

  @override
  String get selectSingleStoreToModify =>
      'Please select a single store to modify';

  @override
  String get cannotDeleteSystemStore => 'Cannot delete this system store';

  @override
  String get cannotModifySystemStore => 'Cannot modify this system store';

  @override
  String get zakatParameter => 'Zakat Parameter';

  @override
  String get nissab => 'Nissab';

  @override
  String get zakatRate => 'Zakat Rate';

  @override
  String get zakatPaid => 'Zakat Paid';

  @override
  String get zakatUnpaid => 'Zakat Unpaid';

  @override
  String get totalZakat => 'Total Zakat';

  @override
  String get state => 'State';

  @override
  String get settingsNotSaved => 'Settings not saved';

  @override
  String get noZakatSelected => 'No zakat selected';

  @override
  String get selectSingleZakatForDetail =>
      'Please select a single zakat to view details';

  @override
  String get selectSingleZakatToModify =>
      'Please select a single zakat to modify';

  @override
  String get period => 'Period';

  @override
  String get zakatDetail => 'Zakat Detail';

  @override
  String get zakatModify => 'Modify Zakat';

  @override
  String get zakatNew => 'New Zakat';

  @override
  String get zakatCancel => 'Cancel Zakat';

  @override
  String get modificationOf => 'Modification of';

  @override
  String get parameter => 'Parameter';

  @override
  String get date => 'Date';

  @override
  String get status => 'Status';

  @override
  String get paid => 'Paid';

  @override
  String get unpaid => 'Unpaid';

  @override
  String get creances => 'Receivables';

  @override
  String get montantZakat => 'Zakat Amount';

  @override
  String get dateDebutHawl => 'Hawl Start Date';

  @override
  String get typeOperation => 'Operation Type';

  @override
  String get operationOn => 'Operation On';

  @override
  String get noHistoriqueSelected => 'No history selected';

  @override
  String get selectSingleHistoriqueForDetail =>
      'Please select a single history to view details';

  @override
  String get historiqueDetail => 'History Detail';

  @override
  String get operation => 'Operation';

  @override
  String get description => 'Description';

  @override
  String get createdBy => 'Created By';

  @override
  String get dateCreated => 'Date Created';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get myAccount => 'My Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get clear => 'Clear';

  @override
  String get viderPanier => 'Clear Cart';

  @override
  String get newClient => 'New Client';

  @override
  String get newProduct => 'New Product';

  @override
  String get discount => 'Discount';

  @override
  String get cashTicket => 'Cash Ticket';

  @override
  String get cashBLSC => 'Cash Invoice';

  @override
  String get saveTicket => 'Save Ticket';

  @override
  String get cancelCart => 'Cancel Cart';

  @override
  String get clearEntry => 'Clear Entry';

  @override
  String get deleteCart => 'Delete Cart';

  @override
  String get category => 'Category';

  @override
  String get chooseCategory => 'Choose a category';

  @override
  String get product => 'Product';

  @override
  String get all => 'All';

  @override
  String get sansCodeBarre => 'No barcode';

  @override
  String get exampleRange => 'Ex:100->200';

  @override
  String get min => 'Min';

  @override
  String get max => 'Max';

  @override
  String get validate => 'Validate';

  @override
  String get total => 'Total';

  @override
  String get code => 'Code';

  @override
  String get price => 'Price';

  @override
  String get quantity => 'Quantity';

  @override
  String get quantityPieces => 'Qty (pcs)';

  @override
  String get showHideColumns => 'Show / Hide Columns';

  @override
  String get none => 'None';

  @override
  String get keepSelection => 'Keep Selection';

  @override
  String get apply => 'Apply';

  @override
  String get page => 'Page';

  @override
  String get rowsPerPage => 'rows / page';

  @override
  String selectDate(Object date) {
    return 'Select $date';
  }

  @override
  String get selectDatew => 'Select date';

  @override
  String get select => 'Select';

  @override
  String get auto => 'Auto';

  @override
  String get requiredField => 'Required field';

  @override
  String get maValue => 'Max';

  @override
  String get inStock => 'Qty';

  @override
  String get addManually => 'Add manually';

  @override
  String get number => 'N°';

  @override
  String get articles => 'Articles';

  @override
  String get supplier => 'Supplier';

  @override
  String get details => 'Details';

  @override
  String get products => 'Products';

  @override
  String get totalPurchases => 'Total Purchases';

  @override
  String get payments => 'Payments';

  @override
  String get totalCredit => 'Total credit';

  @override
  String creditOf(Object amount, Object client) {
    return 'Credit $amount of client $client';
  }

  @override
  String get best => 'Best';

  @override
  String get averagePurchase => 'Average purchase';

  @override
  String get ofClient => 'of client';

  @override
  String get store => 'Store';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get finalBalance => 'Final balance';

  @override
  String get extractPdf => 'Extract PDF';

  @override
  String get obs => 'Obs';

  @override
  String get operations => 'Operations';

  @override
  String get creations => 'Creations';

  @override
  String get adds => 'Adds';

  @override
  String get modifications => 'Modifications';

  @override
  String get updates => 'Updates';

  @override
  String get deletions => 'Deletions';

  @override
  String get deletedItems => 'Deleted items';

  @override
  String get todayOperations => 'Today\'s operations';

  @override
  String get lastUser => 'Last User';

  @override
  String get lastAction => 'Last action';

  @override
  String get stockRate => 'Stock rate';

  @override
  String get time => 'Time';

  @override
  String get totalPaniers => 'Total carts';

  @override
  String get allCarts => 'All carts';

  @override
  String get totalCartAmount => 'Total cart amount';

  @override
  String get sumOfAllCarts => 'Sum of all carts';

  @override
  String get starProduct => 'Star product';

  @override
  String get times => 'times';

  @override
  String get averagePerCart => 'Average per cart';

  @override
  String get averageValue => 'Average value';

  @override
  String get outOfStock => 'OUT OF STOCK';

  @override
  String get unit => 'Unit';

  @override
  String get categories => 'Categories';

  @override
  String get subcategories => 'Subcategories';

  @override
  String get packs => 'Packs';

  @override
  String get discounts => 'Discounts';

  @override
  String get registeredProducts => 'Registered products';

  @override
  String get productTypes => 'Product types';

  @override
  String get secondaryLevels => 'Secondary levels';

  @override
  String get bundledOffers => 'Bundled offers';

  @override
  String get activeDiscounts => 'Active discounts';

  @override
  String get actualStock => 'Actual stock';

  @override
  String get theoreticalStock => 'Theoretical stock';

  @override
  String get totalPurchased => 'Total purchased';

  @override
  String get totalSold => 'Total sold';

  @override
  String get returns => 'Returns';

  @override
  String get lastPurchase => 'Last purchase';

  @override
  String get validated => 'VALIDATED';

  @override
  String get pending => 'PENDING';

  @override
  String get waiting => 'WAITING';

  @override
  String get yes => 'Yes';

  @override
  String get no => 'No';

  @override
  String get rate => 'Rate';

  @override
  String get source => 'Source';

  @override
  String get destination => 'Destination';

  @override
  String get observations => 'Observations';

  @override
  String get noObservation => 'No observation';

  @override
  String get createdAt => 'Created at';

  @override
  String get users => 'Users';

  @override
  String get sales => 'Sales';

  @override
  String get lastAccess => 'Last access';

  @override
  String get phone => 'Phone';

  @override
  String get year => 'Year';

  @override
  String get cash => 'Cash';

  @override
  String get receivables => 'Receivables';

  @override
  String get debts => 'Debts';

  @override
  String get mandatory => 'Mandatory';

  @override
  String get zakatAmount => 'Zakat amount';

  @override
  String get appliedRate => 'Applied rate';

  @override
  String get smartScan => 'Entry';

  @override
  String get scannedItems => 'Scanned items';

  @override
  String get carts => 'Carts';

  @override
  String get activeCarts => 'Active carts';

  @override
  String get returnedProducts => 'Returned products';

  @override
  String get needs => 'Needs';

  @override
  String get stockRequests => 'Stock requests';

  @override
  String get exits => 'Exits';

  @override
  String get exitedProducts => 'Exited products';

  @override
  String get availableProducts => 'Available products';

  @override
  String get elements => 'Elements';

  @override
  String get items => 'Items';

  @override
  String get modifiedAt => 'Modified At';

  @override
  String get modifiedBy => 'Modified By';

  @override
  String get cancelledAt => 'Cancelled at';

  @override
  String get cancelledBy => 'Cancelled By';

  @override
  String get cancellationReason => 'Cancellation Reason';

  @override
  String get fiscalHash => 'Fiscal Seal';

  @override
  String get cashRegisterClosures => 'Cash Register Closures';

  @override
  String get newClosure => 'New Closure';

  @override
  String get totalCancelledAmount => 'Cancelled Amount';

  @override
  String get cancelledTicketsCount => 'Cancelled Tickets';

  @override
  String get paymentMethodBreakdown => 'Payment Method Breakdown';

  @override
  String get zReportTitle => 'Closure Report (Z)';

  @override
  String get confirmClosureMessage =>
      'This will permanently close the period and lock the concerned tickets. Continue?';

  @override
  String get closurePeriod => 'Period to close';

  @override
  String get selectCashRegisterToClose => 'Select the cash register to close';

  @override
  String get loyaltyPoints => 'Points';

  @override
  String get loyaltyProgram => 'Bonus program';

  @override
  String get activateLoyaltyProgram => 'Activate bonus program';

  @override
  String get bonusRate => 'Amount (DA) per point';

  @override
  String get loyaltyBalance => 'Points balance';

  @override
  String get pointsEarned => 'Loyalty points earned';

  @override
  String get numberField => 'Number';

  @override
  String get nombreActifLabel => 'Number field active for this product';

  @override
  String get nombreActifHint =>
      'The number is purely informational; calculations are based on quantity.';

  @override
  String get nombreActifUniteRequiredHint =>
      'Only available when the product\'s unit of measure is Kg or Litre.';

  @override
  String get noClosuresYet => 'No closures yet';

  @override
  String get fiscalControlExport => 'Fiscal Control Export';

  @override
  String get fiscalRegistryIntact => 'Fiscal registry intact';

  @override
  String get fiscalRegistryCompromised =>
      'Fiscal registry compromised — anomaly detected';

  @override
  String get otherwiseDefaultColumns =>
      'Otherwise default columns will be used';

  @override
  String get close => 'Close';

  @override
  String get brand => 'Brand';

  @override
  String get model => 'Model';

  @override
  String get qty => 'Qty';

  @override
  String get name => 'Name';

  @override
  String get observation => 'Observation';

  @override
  String get wilaya => 'Wilaya';

  @override
  String get activity => 'Activity';

  @override
  String get advance => 'Advance';

  @override
  String get totalInvoiced => 'Total Invoiced';

  @override
  String get nbInvoiced => 'Nb Invoiced';

  @override
  String get totalPayment => 'Total Payment';

  @override
  String get nbPayment => 'Nb Payment';

  @override
  String get nbReturn => 'Nb Return';

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
  String get bank => 'Bank';

  @override
  String creditWithAmount(Object amount) {
    return 'Credit: $amount';
  }

  @override
  String get upToDate => 'Up to date';

  @override
  String get address => 'Address';

  @override
  String get totalPaid => 'Total Paid';

  @override
  String get nbPurchases => 'Nb Purchases';

  @override
  String get debt => 'Debt';

  @override
  String get settled => 'Settled';

  @override
  String get id => 'ID';

  @override
  String get storageRate => 'Storage Rate';

  @override
  String get cashRegisterName => 'Cash register name';

  @override
  String get creatorCode => 'Creator code';

  @override
  String get deletion => 'Deletion';

  @override
  String get user => 'User';

  @override
  String get need => 'Need';

  @override
  String get sale => 'Sale';

  @override
  String get purchase => 'Purchase';

  @override
  String get return_ => 'Return';

  @override
  String get destocking => 'Destocking';

  @override
  String get reference => 'Reference';

  @override
  String get ref => 'Ref';

  @override
  String get debit => 'Debit';

  @override
  String get balance => 'Balance';

  @override
  String get cashier => 'Cashier';

  @override
  String get size => 'Size';

  @override
  String get color => 'Color';

  @override
  String get subcategory => 'Subcategory';

  @override
  String get service => 'Service';

  @override
  String get serviceModeInfo =>
      'This product is marked as a service: its quantity will never be changed by stock movements (sales, purchases, returns, exits, etc.).';

  @override
  String get packaging1 => 'Packaging 1';

  @override
  String get packaging2 => 'Packaging 2';

  @override
  String get minThreshold => 'Min Threshold';

  @override
  String get maxThreshold => 'Max Threshold';

  @override
  String get needStatus => 'Need Status';

  @override
  String get barcode => 'Barcode';

  @override
  String get serialNumber => 'Serial Number';

  @override
  String get multicode => 'Multicode';

  @override
  String get multipleBarcodeLabel => 'Multiple Code';

  @override
  String get noBarcodeProduct => 'Product without barcode';

  @override
  String get generateBarcode => 'Generate a barcode';

  @override
  String get photos => 'Photos';

  @override
  String get marginBool => 'Margin';

  @override
  String get marginRatePercent => 'Margin Rate %';

  @override
  String get vat => 'VAT';

  @override
  String get dateBorrowed => 'Date Borrowed';

  @override
  String get thresholdBool => 'Threshold';

  @override
  String get rateType => 'Rate Type';

  @override
  String get start => 'Start';

  @override
  String get end => 'End';

  @override
  String get percentage => '%';

  @override
  String get clientType => 'Client';

  @override
  String get supplierType => 'Supplier';

  @override
  String get hasReturn => 'Has a return';

  @override
  String get userCount => 'User Count';

  @override
  String get calculatedProducts => 'Calculated Products';

  @override
  String get calculatedQuantity => 'Calculated Quantity';

  @override
  String get calculatedAmount => 'Calculated Amount';

  @override
  String get gap => 'Gap';

  @override
  String get categoryId => 'Category ID';

  @override
  String get totalPurchase => 'Total Purchase';

  @override
  String get totalSale => 'Total Sale';

  @override
  String get totalReturn => 'Total Return';

  @override
  String get lastPurchaseQuantity => 'Last Purchase Quantity';

  @override
  String get username => 'Username';

  @override
  String get salesCount => 'Sales Count';

  @override
  String get beneficiaryType => 'Beneficiary Type';

  @override
  String get cashRegister => 'Cash Register';

  @override
  String get beneficiary => 'Beneficiary';

  @override
  String get paymentMethod => 'Payment Method';

  @override
  String get incoming => 'Incoming';

  @override
  String get outgoing => 'Outgoing';

  @override
  String get entry => 'Entry';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get totalCapital => 'Total Capital';

  @override
  String get statusField => 'Status';

  @override
  String get hawlStart => 'Hawl Start';

  @override
  String get dueDate => 'Due Date';

  @override
  String get paymentDate => 'Payment Date';

  @override
  String get confirmation => 'Confirmation';

  @override
  String get confirm => 'Confirm';

  @override
  String get insertionCashRegister => 'Insertion Cash Register';

  @override
  String get insertionCategory => 'Insertion Category';

  @override
  String get newM => 'New';

  @override
  String get add => 'Add';

  @override
  String get pleaseSelect => 'Please select';

  @override
  String get pleaseSelectCashRegister => 'Please select a cash register';

  @override
  String get pleaseSelectCategory => 'Please select a category';

  @override
  String get insertionClient => 'Insertion Client';

  @override
  String get insertionSupplier => 'Insertion Supplier';

  @override
  String get insertionStore => 'Insertion Store';

  @override
  String get multipleSelection => 'Multiple selection';

  @override
  String get pleaseSelectClient => 'Please select a client';

  @override
  String get pleaseSelectSupplier => 'Please select a supplier';

  @override
  String get pleaseSelectStore => 'Please select a store';

  @override
  String get insertionPack => 'Insertion Pack';

  @override
  String get insertionProduct => 'Insertion Product';

  @override
  String get insertionDiscount => 'Insertion Discount';

  @override
  String get insertionSession => 'Insertion Session';

  @override
  String get insertionSubcategory => 'Insertion Subcategory';

  @override
  String get pleaseSelectPack => 'Please select a pack';

  @override
  String get pleaseSelectProduct => 'Please select a product';

  @override
  String get pleaseSelectDiscount => 'Please select a discount';

  @override
  String get pleaseSelectSubcategory => 'Please select a subcategory';

  @override
  String get newNeedList => 'New Need List';

  @override
  String get modifyNeedList => 'Modify Need List';

  @override
  String get menu => 'Menu';

  @override
  String get deleteNeeds => 'Delete Needs';

  @override
  String get needDetail => 'Need Detail';

  @override
  String get totalAmount => 'Total Amount';

  @override
  String get numberOfArticles => 'Number of Articles';

  @override
  String get totalQuantity => 'Total Quantity';

  @override
  String get noProduct => 'No product';

  @override
  String get generalInformation => 'General Information';

  @override
  String get audit => 'Audit';

  @override
  String get productsList => 'Products List';

  @override
  String get addObservation => 'Add an observation...';

  @override
  String get selectedNeeds => 'Selected needs:';

  @override
  String get confirmDeleteNeeds => 'Are you sure you want to delete this list?';

  @override
  String get loginRequired => 'You must be logged in.';

  @override
  String get fillRequiredFields => 'Please fill in all required fields';

  @override
  String get success => 'Success';

  @override
  String get modify => 'Modify';

  @override
  String get delete => 'Delete';

  @override
  String productsOfNeed(Object code) {
    return 'Products of need $code';
  }

  @override
  String get productCode => 'Product Code';

  @override
  String get productName => 'Product';

  @override
  String get productQuantity => 'Quantity';

  @override
  String get productPrice => 'Price';

  @override
  String get productTotal => 'Total';

  @override
  String get cashRegisterSettings => 'Cash Register Settings';

  @override
  String get defaultCashRegister => 'Default cash register';

  @override
  String get cashRegisterLockedToUser =>
      'This cash register is set by your user account. Only an administrator can change it.';

  @override
  String get defaultStore => 'Default store';

  @override
  String get parcel => 'Parcel';

  @override
  String get alwaysAsked => 'Always asked';

  @override
  String get uniteParcel => 'Unite parcel';

  @override
  String get smallParcel => 'Small parcel';

  @override
  String get largeParcel => 'Large parcel';

  @override
  String get allFieldsRequired => 'All fields must be filled';

  @override
  String get modifyProductPrice => 'Modify product price';

  @override
  String get priceChangeScope => 'Apply the change to';

  @override
  String get thisTicketOnly => 'This ticket only';

  @override
  String get entireProduct => 'The product (permanent)';

  @override
  String get password => 'Password';

  @override
  String get invalidPrice => 'Invalid price';

  @override
  String get invalidQuantity => 'Invalid quantity';

  @override
  String packagingPricePerPieceLowerThanPurchase(String price) {
    return 'Price per piece ($price) lower than purchase price';
  }

  @override
  String barcodeAlreadyUsed(String produit) {
    return 'This barcode is already used by product \"$produit\"';
  }

  @override
  String get productNameAlreadyExists => 'This product name already exists';

  @override
  String get clientNameAlreadyExists => 'This client name already exists';

  @override
  String get supplierNameAlreadyExists => 'This supplier name already exists';

  @override
  String get usernameAlreadyExists => 'This username already exists';

  @override
  String get roleNameAlreadyExists => 'This role name already exists';

  @override
  String get passwordRequired => 'Password required';

  @override
  String get ticketRegistration => 'Ticket Registration';

  @override
  String get cartNumber => 'Cart N°';

  @override
  String get fullPayment => 'Full payment';

  @override
  String get cashPrint => 'Cash / Print';

  @override
  String get cashPrintBLSC => 'Cash / Print Invoice';

  @override
  String get cashPrintTicket => 'Cash / Print Ticket';

  @override
  String get blNumber => 'Invoice N°';

  @override
  String get paidAmount => 'Paid amount';

  @override
  String get remainingAmount => 'Remaining amount';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get categoryDetail => 'Category Detail';

  @override
  String get modifyCategory => 'Modify Category';

  @override
  String get newCategory => 'New Category';

  @override
  String get selectedCategories => 'Selected categories:';

  @override
  String get confirmDeleteCategories =>
      'Are you sure you want to delete these categories?';

  @override
  String get confirmDeleteCategory =>
      'Are you sure you want to permanently delete the selected categories?';

  @override
  String get deleteSuccess => 'Categories deleted successfully.';

  @override
  String get deleteError => 'Please empty all subcategories before deletion.';

  @override
  String get modifySuccess => 'Modified successfully.';

  @override
  String get createSuccess => 'Operation saved successfully.';

  @override
  String get categoryExists => 'A category with this name already exists.';

  @override
  String get authentication => 'Authentication';

  @override
  String get categoryNameHint => 'Category name';

  @override
  String get categoryObservationHint => 'Category observation...';

  @override
  String get deleteClients => 'Delete Clients';

  @override
  String get clientDetail => 'Client Detail';

  @override
  String get modifyClient => 'Modify Client';

  @override
  String clientSituation(Object name) {
    return 'Client Situation: $name';
  }

  @override
  String get numberOfPurchases => 'Number of Purchases';

  @override
  String get numberOfPayments => 'Number of Payments';

  @override
  String get contact => 'Contact';

  @override
  String get addressInfo => 'Address';

  @override
  String get financialInformation => 'Financial Information';

  @override
  String get administrativeInformation => 'Administrative Information';

  @override
  String get bankingInformation => 'Banking Information';

  @override
  String get selectedClients => 'Selected clients:';

  @override
  String get confirmDeleteClients =>
      'Are you sure you want to delete these clients?';

  @override
  String get refresh => 'Refresh';

  @override
  String get clientNameHint => 'Client name';

  @override
  String get phoneHint => '0550 00 00 00';

  @override
  String get wilayaHint => 'Biskra';

  @override
  String get addressHint => '05 July City';

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
  String get observationHint => 'Observation...';

  @override
  String get versement_ENT => 'Payment (In)';

  @override
  String get versement_SRT => 'Payment (Out)';

  @override
  String clientNumber(Object id) {
    return 'Client #$id';
  }

  @override
  String get lastPurchaseDate => 'Last purchase';

  @override
  String get purchasesCount => 'Purchases';

  @override
  String get deleteSuppliers => 'Delete Suppliers';

  @override
  String get supplierDetail => 'Supplier Detail';

  @override
  String get modifySupplier => 'Modify Supplier';

  @override
  String get newSupplier => 'New Supplier';

  @override
  String supplierSituation(Object name) {
    return 'Supplier Situation: $name';
  }

  @override
  String supplierNumber(Object id) {
    return 'Supplier #$id';
  }

  @override
  String get selectedSuppliers => 'Selected suppliers:';

  @override
  String get confirmDeleteSuppliers =>
      'Are you sure you want to delete these suppliers?';

  @override
  String get supplierNameHint => 'Supplier name';

  @override
  String get paymentIn => 'Payment (In)';

  @override
  String get paymentOut => 'Payment (Out)';

  @override
  String get deleteCashRegisters => 'Delete Cash Registers';

  @override
  String get cashRegisterDetail => 'Cash Register Detail';

  @override
  String get modifyCashRegister => 'Modify Cash Register';

  @override
  String cashRegisterNumber(Object id) {
    return 'Cash Register #$id';
  }

  @override
  String get selectedCashRegisters => 'Selected cash registers:';

  @override
  String get confirmDeleteCashRegisters =>
      'Are you sure you want to delete these cash registers?';

  @override
  String get noStoreAvailable => 'No store available.';

  @override
  String get codeAutoGenerated => 'Auto-generated';

  @override
  String get cashRegisterNameHint => 'Main cash register';

  @override
  String get initialBalanceHint => '0.00';

  @override
  String get storeHint => 'Select store';

  @override
  String get physical => 'Physical';

  @override
  String get account => 'Account';

  @override
  String get deleteStores => 'Delete Stores';

  @override
  String get cannotDelete => 'Cannot delete';

  @override
  String get storeDetail => 'Store Detail';

  @override
  String get modifyStore => 'Modify Store';

  @override
  String get newStore => 'New Store';

  @override
  String storeNumber(Object id) {
    return 'Store #$id';
  }

  @override
  String get stockCapacity => 'Stock & Capacity';

  @override
  String get selectedStores => 'Selected stores:';

  @override
  String get cannotDeleteWithProducts =>
      'You cannot delete the following stores because they contain products:';

  @override
  String get confirmDeleteStores =>
      'Are you sure you want to delete these stores?\nThis action is irreversible.';

  @override
  String get noStoreDeleted => 'No store deleted.';

  @override
  String get storeDeleteSuccess => 'Store(s) deleted successfully.';

  @override
  String get noProductsAssociated => 'No products associated with this store';

  @override
  String get noProductsAdded => 'No products added';

  @override
  String get storeNameHint => 'Store name';

  @override
  String get storeAddressHint => 'Store address';

  @override
  String productsOfStore(Object code) {
    return 'Products of Store $code';
  }

  @override
  String get reactivatePack => 'Reactivate Pack';

  @override
  String get deletePacks => 'Delete Packs';

  @override
  String get packDetail => 'Pack Detail';

  @override
  String get modifyPack => 'Modify Pack';

  @override
  String get newPack => 'New Pack';

  @override
  String get numberOfItems => 'Number of items';

  @override
  String get selectedPacks => 'Selected packs:';

  @override
  String get confirmReactivatePacks =>
      'Are you sure you want to reactivate these packs?';

  @override
  String get confirmDeletePacks =>
      'Are you sure you want to delete the selected packs?\nThis action is irreversible.';

  @override
  String get noChangesDetected => 'No changes detected.';

  @override
  String productAlreadyAdded(Object name) {
    return 'The product $name is already added to the pack.';
  }

  @override
  String get packNameHint => 'Pack name';

  @override
  String get priceHint => 'Ex: 1500.00';

  @override
  String productsCount(Object count) {
    return '$count products';
  }

  @override
  String productsOfPack(Object code) {
    return 'Products of Pack $code';
  }

  @override
  String productsOfSubCategory(Object code) {
    return 'Products of subcategory $code';
  }

  @override
  String get cancelCarts => 'Cancel Carts';

  @override
  String get cartDetail => 'Cart Detail';

  @override
  String get modifyCart => 'Modify Cart';

  @override
  String insufficientStockAvailable(Object disponible, Object produit) {
    return 'Insufficient stock for $produit (available: $disponible)';
  }

  @override
  String get cartType => 'Cart type';

  @override
  String get amountPaid => 'Amount paid';

  @override
  String cartId(Object code) {
    return 'Cart #$code';
  }

  @override
  String get itemsAndQuantities => 'Items & Quantities';

  @override
  String get selectedCarts => 'Selected carts:';

  @override
  String get confirmCancelCarts =>
      'Are you sure you want to cancel these carts?';

  @override
  String cartProducts(Object code) {
    return 'Products of cart $code';
  }

  @override
  String get noProducts => 'No products';

  @override
  String get cart => 'Cart';

  @override
  String productsOfCart(Object code) {
    return 'Products of cart $code';
  }

  @override
  String get applyCategorySubcategory => 'Apply Category / Subcategory';

  @override
  String get selectedProducts => 'Selected products:';

  @override
  String confirmModifyCategorySubcategory(Object count) {
    return 'Are you sure you want to modify the category and subcategory for $count selected product(s)?';
  }

  @override
  String get categorySubcategoryModifiedSuccess =>
      'Category and subcategory modified successfully.';

  @override
  String get errorOccurred => 'An error occurred.';

  @override
  String get priceTaxes => 'Price & Taxes';

  @override
  String get stockUnit => 'Stock & Unit';

  @override
  String get unitOfMeasure => 'Unit of Measure';

  @override
  String get locationSpecifications => 'Location & Specifications';

  @override
  String get stores => 'Stores';

  @override
  String get active => 'Active';

  @override
  String get inactive => 'Inactive';

  @override
  String get noPacks => 'No packs';

  @override
  String get noStores => 'No stores';

  @override
  String get applyPack => 'Apply Pack';

  @override
  String get applyDiscount => 'Apply Discount';

  @override
  String confirmApplyPack(Object count, Object packName) {
    return 'Are you sure you want to apply the pack \'$packName\' to $count selected product(s)?';
  }

  @override
  String confirmApplyDiscount(Object count, Object discountName) {
    return 'Are you sure you want to apply the discount \'$discountName\' to $count selected product(s)?';
  }

  @override
  String get packAppliedSuccess => 'Pack applied successfully.';

  @override
  String get discountAppliedSuccess => 'Discount applied successfully.';

  @override
  String get modifyProduct => 'Modify Product';

  @override
  String get quickMode => 'Quick';

  @override
  String get detailedMode => 'Detailed';

  @override
  String get codeReference => 'Code & Reference';

  @override
  String get categoryDiscount => 'Category & Discount';

  @override
  String get unitPackaging => 'Unit & Packaging';

  @override
  String get storage => 'Storage';

  @override
  String get packStore => 'Pack & Store';

  @override
  String get marginAmount => 'Margin Amount';

  @override
  String get marginPercentage => 'Margin Percentage';

  @override
  String get spec1 => 'Spec 1';

  @override
  String get spec2 => 'Spec 2';

  @override
  String get expiryDate => 'Expiry Date';

  @override
  String get daysSinceExpiry => 'Days since expiry';

  @override
  String get productNameHint => 'Product name';

  @override
  String get descriptionHint => 'Description';

  @override
  String get brandHint => 'Example: LG, Samsung....';

  @override
  String get barcodeHint => '949832128151';

  @override
  String get serialNumberHint => '123456789';

  @override
  String get sizeHint => 'XL L M S ....';

  @override
  String get colorHint => 'White Blue ....';

  @override
  String get packaging1Hint => '15 (box)';

  @override
  String get packaging2Hint => '150 (carton)';

  @override
  String get spec1Hint => 'Aisle 1';

  @override
  String get spec2Hint => 'Shelf 1';

  @override
  String get loginRequiredModify =>
      'You must be logged in to modify a product.';

  @override
  String get loginRequiredCreate =>
      'You must be logged in to create a new product.';

  @override
  String get confirmModifyProduct =>
      'Are you sure you want to modify this product?';

  @override
  String get salePriceLowerThanPurchase =>
      'Sale price lower than purchase price';

  @override
  String get maxThresholdLowerThanMin =>
      'Max threshold lower than min threshold';

  @override
  String get productModifiedSuccess => 'Product modified successfully.';

  @override
  String get productSavedSuccess => 'Product saved successfully.';

  @override
  String get deleteProduct => 'Delete Product';

  @override
  String get confirmDeleteProducts =>
      'Are you sure you want to delete these products?';

  @override
  String get confirmPermanentDelete =>
      'Are you sure you want to permanently delete the selected products?';

  @override
  String get productsDeletedSuccess => 'Products deleted successfully.';

  @override
  String get cannotDeleteWithMovements =>
      'You cannot delete these products because they have movements:';

  @override
  String get loginRequiredDelete =>
      'You must be logged in to delete a product.';

  @override
  String get kg => 'Kg';

  @override
  String get deleteDiscount => 'Delete Discount';

  @override
  String get selectedDiscounts => 'Selected discounts:';

  @override
  String get confirmDeleteDiscounts =>
      'Are you sure you want to delete these discounts?';

  @override
  String get confirmPermanentDeleteDiscounts =>
      'Are you sure you want to permanently delete the selected discounts?';

  @override
  String get discountsDeletedSuccess => 'Discounts deleted successfully.';

  @override
  String get modifyDiscount => 'Modify Discount';

  @override
  String get newDiscount => 'New Discount';

  @override
  String get productList => 'Product List';

  @override
  String productsOfDiscount(Object code) {
    return 'Products of discount $code';
  }

  @override
  String get amountRate => 'Amount / Rate';

  @override
  String get productsConcerned => 'Products concerned';

  @override
  String get currentDiscount => 'Current Discount';

  @override
  String get byProduct => 'By Product';

  @override
  String get byAmount => 'By Amount';

  @override
  String get discountNameHint => 'Discount name';

  @override
  String get discountRate => 'Discount rate';

  @override
  String get pleaseSelectStartDateFirst => 'Please select the start date first';

  @override
  String get discountApplicationAmount => 'Discount application amount';

  @override
  String get discountModifiedSuccess => 'Discount modified successfully.';

  @override
  String get discountSavedSuccess => 'Discount saved successfully.';

  @override
  String get invalidNumber => 'Please enter a valid number';

  @override
  String get percentageExceeds100 => 'Percentage cannot exceed 100%';

  @override
  String get valueMustBePositive => 'Value must be positive';

  @override
  String get confirmModifyDiscount =>
      'Are you sure you want to modify this discount?';

  @override
  String get greaterThan => 'Greater than';

  @override
  String get deleteReturns => 'Delete Returns';

  @override
  String get selectedReturns => 'Selected returns:';

  @override
  String get returnHash => 'Return';

  @override
  String get confirmDeleteReturns =>
      'Are you sure you want to delete these returns?';

  @override
  String get modifyReturn => 'Modify Return';

  @override
  String get newReturn => 'New Return';

  @override
  String get confirmModifyReturn =>
      'Are you sure you want to modify this return?';

  @override
  String get returnModifiedSuccess => 'Return modified successfully.';

  @override
  String get returnSavedSuccess => 'Return saved successfully.';

  @override
  String get roles => 'Roles';

  @override
  String get deactivateRoles => 'Deactivate Roles';

  @override
  String get selectedRoles => 'Selected roles:';

  @override
  String get roleHash => 'Role';

  @override
  String get confirmDeactivateRoles =>
      'Are you sure you want to deactivate these roles?';

  @override
  String get deleteRole => 'Delete Role';

  @override
  String get confirmDeleteRoles =>
      'Are you sure you want to delete the selected roles?';

  @override
  String rolesDeletedCount(Object count) {
    return '$count role(s) deleted successfully.';
  }

  @override
  String get noRolesDeleted => 'No roles deleted.';

  @override
  String get deletionImpossible => 'Deletion impossible';

  @override
  String get modificationImpossible => 'Modification impossible';

  @override
  String roleHasUsers(Object roleName) {
    return 'The role \'$roleName\' contains users and cannot be deleted.';
  }

  @override
  String get cannotModifyAdminRole => 'The Admin role cannot be modified.';

  @override
  String get cannotDeleteAdminRole => 'The Admin role cannot be deleted.';

  @override
  String get cannotModifyAdminUser => 'The Admin user cannot be modified.';

  @override
  String get cannotDeleteAdminUser => 'The Admin user cannot be deleted.';

  @override
  String userHasActivityDeactivated(Object username) {
    return '$username already has related records in the app and cannot be permanently deleted — it was deactivated instead.';
  }

  @override
  String get roleName => 'Role name';

  @override
  String get roleNameHint => 'Ex: Administrator';

  @override
  String get modifyRole => 'Modify Role';

  @override
  String get newRole => 'New Role';

  @override
  String get confirmModifyRole => 'Are you sure you want to modify this role?';

  @override
  String get roleModifiedSuccess => 'Role modified successfully.';

  @override
  String get roleSavedSuccess => 'Role saved successfully.';

  @override
  String get smartScanHash => 'Entry';

  @override
  String get deleteSmartScan => 'Delete Entry';

  @override
  String get selectedSmartScans => 'Selected entries:';

  @override
  String get confirmDeleteSmartScans =>
      'Are you sure you want to delete these entries?';

  @override
  String get statistics => 'Statistics';

  @override
  String get scannedProductCount => 'Scanned product count';

  @override
  String get scannedTotalQuantity => 'Scanned total quantity';

  @override
  String get scannedTotalAmount => 'Scanned total amount';

  @override
  String smartScanProducts(Object code) {
    return 'Products of entry $code';
  }

  @override
  String get smartScanProductsList => 'Entry Products';

  @override
  String get modifySmartScan => 'Modify Entry';

  @override
  String get gapDetected => 'Gap detected';

  @override
  String get gapDetectedMessage =>
      'A gap has been detected between entered and calculated values.\nDo you want to continue?';

  @override
  String get smartScanModifiedSuccess => 'Entry modified successfully.';

  @override
  String get newSmartScan => 'New Entry';

  @override
  String get smartScanSavedSuccess => 'Entry saved successfully.';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get supplierCodeRequired => 'Supplier code is required.';

  @override
  String get supplierNameRequired => 'Supplier name is required.';

  @override
  String get dateRequired => 'Date is required.';

  @override
  String get amountRequired => 'Amount is required.';

  @override
  String get productCountRequired => 'Product count is required.';

  @override
  String get totalQuantityRequired => 'Total quantity is required.';

  @override
  String get atLeastOneProduct => 'Please select at least one product.';

  @override
  String get cartMustKeepOneProduct =>
      'The cart must contain at least one product. Delete the whole cart instead if needed.';

  @override
  String get supplierCodeHint => 'Supplier code';

  @override
  String get scanGlobalQRCode => 'Please scan the global QR code';

  @override
  String get enterRequiredInformation =>
      'Please enter the required information';

  @override
  String get manual => 'Manual';

  @override
  String get summary => 'Summary';

  @override
  String get productExistsInSmartScan =>
      'This product already exists in this entry';

  @override
  String get list => 'List';

  @override
  String get noEntrySelected => 'No entry selected!';

  @override
  String get selectSingleEntryForDetail =>
      'Please select a single entry to view details!';

  @override
  String get selectSingleEntryToModify =>
      'Please select a single entry to modify!';

  @override
  String get deleteExit => 'Delete Exit';

  @override
  String get deleteExits => 'Delete Exits';

  @override
  String get selectedExits => 'Selected exits:';

  @override
  String get confirmDeleteExits =>
      'Are you sure you want to delete these exits?';

  @override
  String get modifyExit => 'Modify Exit';

  @override
  String get newExit => 'New Exit';

  @override
  String get exitType => 'Exit type';

  @override
  String get confirmModifyExit => 'Are you sure you want to modify this exit?';

  @override
  String get exitModifiedSuccess => 'Exit modified successfully.';

  @override
  String get exitSavedSuccess => 'Exit saved successfully.';

  @override
  String get unitPrice => 'Unit price';

  @override
  String get dateHint => 'DD/MM/YYYY';

  @override
  String get deactivateSubcategory => 'Deactivate Subcategory';

  @override
  String get selectedSubcategories => 'Selected subcategories:';

  @override
  String get confirmDeactivateSubcategories =>
      'Are you sure you want to deactivate these subcategories?';

  @override
  String get deleteSubcategory => 'Delete Subcategory';

  @override
  String get confirmDeleteSubcategories =>
      'Are you sure you want to permanently delete the selected subcategories?';

  @override
  String get subcategoriesDeletedSuccess =>
      'Subcategories deleted successfully.';

  @override
  String get modifySubcategory => 'Modify Subcategory';

  @override
  String get newSubcategory => 'New Subcategory';

  @override
  String get parentCategory => 'Parent category';

  @override
  String get subcategoryNameHint => 'Subcategory name';

  @override
  String get confirmModifySubcategory =>
      'Are you sure you want to modify this subcategory?';

  @override
  String get subcategoryModifiedSuccess => 'Subcategory modified successfully.';

  @override
  String get subcategorySavedSuccess => 'Subcategory saved successfully.';

  @override
  String get affectedProducts => 'Affected products';

  @override
  String get currentSubcategory => 'Current subcategory';

  @override
  String get productDistribution => 'Product Distribution';

  @override
  String get distributionByStore => 'Distribution by store';

  @override
  String get totalDistributed => 'Total distributed';

  @override
  String get available => 'Available';

  @override
  String get distribute => 'Distribute';

  @override
  String get distributionExceedsStock =>
      'Total distributed quantity exceeds available stock';

  @override
  String get stockMovements => 'Stock Movements';

  @override
  String get last => 'Last';

  @override
  String get packaging => 'Packaging';

  @override
  String get transfer => 'Transfer';

  @override
  String get transfers => 'Transfers';

  @override
  String get transferHash => 'Transfer';

  @override
  String get cancelTransfers => 'Cancel transfers';

  @override
  String get selectedTransfers => 'Selected transfers:';

  @override
  String get confirmCancelTransfers =>
      'Are you sure you want to cancel these transfers?';

  @override
  String get irreversibleOperation => 'This operation is irreversible.';

  @override
  String get transfersCancelledSuccess => 'Transfers cancelled successfully.';

  @override
  String get transferDate => 'Transfer date';

  @override
  String get modifyTransfer => 'Modify Transfer';

  @override
  String get confirmModifyTransfer =>
      'Are you sure you want to modify this transfer?';

  @override
  String get transferModifiedSuccess => 'Transfer modified successfully.';

  @override
  String get sourceAndDestinationStoreMustBeDifferent =>
      'The source store and destination store must be different.';

  @override
  String get splitEntryAcrossStores =>
      'Split the receipt across multiple stores';

  @override
  String get splitTotalMustMatchQuantity =>
      'The sum of the split quantities must equal the total quantity.';

  @override
  String get duplicateStoreInSplit =>
      'The same store cannot appear more than once in the split.';

  @override
  String get incompleteStoreSplit =>
      'Please choose a store and a quantity for each split row.';

  @override
  String get observationOptional => 'Observation (optional)';

  @override
  String get userHash => 'User';

  @override
  String get deleteUsers => 'Delete Users';

  @override
  String get selectedUsers => 'Selected users:';

  @override
  String get confirmDeleteUsers =>
      'Are you sure you want to delete these users?';

  @override
  String usersDeletedCount(Object count) {
    return '$count user(s) deleted successfully.';
  }

  @override
  String get modifyUser => 'Modify User';

  @override
  String get newUser => 'New User';

  @override
  String get usernameHint => 'Username';

  @override
  String get confirmModifyUser => 'Are you sure you want to modify this user?';

  @override
  String get userModifiedSuccess => 'User modified successfully.';

  @override
  String get changePassword => 'Change Password';

  @override
  String get oldPassword => 'Old Password';

  @override
  String get newPassword => 'New Password';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get incorrectOldPassword => 'Incorrect old password';

  @override
  String get confirmChangePassword =>
      'Are you sure you want to change the password?';

  @override
  String get passwordChangedSuccess => 'Password changed successfully.';

  @override
  String get userSavedSuccess => 'User saved successfully.';

  @override
  String get paymentHash => 'Payment';

  @override
  String get activatePayments => 'Activate Payments';

  @override
  String get selectedPayments => 'Selected payments:';

  @override
  String get confirmActivatePayments =>
      'Are you sure you want to activate these payments?';

  @override
  String get deletePayments => 'Delete Payments';

  @override
  String get confirmDeletePayments =>
      'Are you sure you want to delete the selected payments?';

  @override
  String get paymentsDeletedSuccess => 'Payments deleted successfully.';

  @override
  String get paymentType => 'Payment type';

  @override
  String get modifyPayment => 'Modify Payment';

  @override
  String get modifyPaymentExit => 'Modify Payment (Exit)';

  @override
  String get newPayment => 'New Payment';

  @override
  String get newPaymentExit => 'New Payment (Exit)';

  @override
  String get confirmModifyPayment =>
      'Are you sure you want to modify this payment?';

  @override
  String get paymentModifiedSuccess => 'Payment modified successfully.';

  @override
  String get paymentSavedSuccess => 'Payment saved successfully.';

  @override
  String get sense => 'Sense';

  @override
  String get paymentExit => 'Payment (Exit)';

  @override
  String get zakats => 'Zakat';

  @override
  String get deleteZakat => 'Delete Zakat';

  @override
  String get selectedZakats => 'Selected Zakats:';

  @override
  String get confirmDeleteZakats =>
      'Are you sure you want to delete these Zakats?';

  @override
  String get zakatsDeletedSuccess => 'Zakats deleted successfully.';

  @override
  String get alreadyPaid => 'Already paid';

  @override
  String get cannotDeletePaidZakat =>
      'Some Zakats are already paid and cannot be deleted.';

  @override
  String get financialData => 'Financial Data';

  @override
  String get liquidities => 'Liquidities';

  @override
  String get rulesZakat => 'Rules & Zakat';

  @override
  String get hawlDueDate => 'Hawl & Due Date';

  @override
  String get zakatDueDate => 'Zakat Due Date';

  @override
  String get autoCalculate => 'Auto Calculate';

  @override
  String get autoCalculateFromProducts => 'Auto-calculated from products';

  @override
  String get stockValue => 'Stock value';

  @override
  String get cashBank => 'Cash + Bank';

  @override
  String get moneyToReceive => 'Money to receive';

  @override
  String get shortTermDebts => 'Short-term debts';

  @override
  String get rulesStatus => 'Rules & Status';

  @override
  String get nissabThreshold => 'Nissab threshold';

  @override
  String get ratePercent => 'Rate (%)';

  @override
  String get nissabNotDefined => 'Nissab not defined or equal to 0';

  @override
  String get zakatMandatory => 'Zakat mandatory (capital ≥ nissab)';

  @override
  String get zakatNotMandatory => 'Zakat not mandatory (capital < nissab)';

  @override
  String get modifyZakat => 'Modify Zakat';

  @override
  String get newZakat => 'New Zakat';

  @override
  String get confirmModifyZakat =>
      'Are you sure you want to modify this Zakat?';

  @override
  String get zakatModifiedSuccess => 'Zakat modified successfully.';

  @override
  String get zakatSavedSuccess => 'Zakat saved successfully.';

  @override
  String get confirmDeleteEntries =>
      'Are you sure you want to delete these entries?';

  @override
  String get entryModifiedSuccess => 'Entry modified successfully.';

  @override
  String get entrySavedSuccess => 'Entry saved successfully.';

  @override
  String get selectedEntries => 'Selected entries:';

  @override
  String get deleteEntries => 'Delete Entries';

  @override
  String get supplierCode => 'Supplier code';

  @override
  String get deleteEntry => 'Delete Entry';

  @override
  String get modifyEntry => 'Modify Entry';

  @override
  String get newEntry => 'New Entry';

  @override
  String get entries => 'Entries';

  @override
  String get cashTicketReceipt => 'CASH TICKET';

  @override
  String get ticketNumber => 'Ticket N°';

  @override
  String get subtotal => 'Subtotal';

  @override
  String get change => 'Change';

  @override
  String get thankYou => 'Thank you for your visit!';

  @override
  String get seeYouSoon => 'See you soon';

  @override
  String get magaprinc => 'Main Shop';

  @override
  String get paymentAmountMustBePositive =>
      'Payment amount must be greater than 0';

  @override
  String get printTicket => 'Print Ticket';

  @override
  String get printTicketConfirmation => 'Do you want to print the ticket now?';

  @override
  String get bluetoothDisabled => 'Bluetooth is disabled';

  @override
  String get noPrinterFound => 'No paired printer found';

  @override
  String get selectPrinter => 'Select printer';

  @override
  String get connectionFailed => 'Connection failed';

  @override
  String get printFailed => 'Print failed';

  @override
  String get ticketPrintedSuccess => 'Ticket printed successfully!';

  @override
  String get printError => 'Print error';

  @override
  String get autoPrintDisabled => 'Auto-print disabled';

  @override
  String get ticketPreview => 'Ticket Preview';

  @override
  String autoPrintIn(int seconds) {
    return 'Auto-print in $seconds seconds...';
  }

  @override
  String get printNow => 'Print Now';

  @override
  String get partialPayment => 'Partial Payment';

  @override
  String get partialPaymentConfirm =>
      'Do you want to proceed with partial payment?';

  @override
  String get receiptPreview => 'Receipt Preview';

  @override
  String get print => 'Print';

  @override
  String get invoice => 'Invoice';

  @override
  String get deliveryNote => 'Delivery Note';

  @override
  String get salesReceipt => 'Sales Receipt';

  @override
  String get clientInformation => 'Client Information';

  @override
  String get clientName => 'Client Name';

  @override
  String get clientCode => 'Client Code';

  @override
  String get invoiceDate => 'Invoice Date';

  @override
  String get register => 'Register';

  @override
  String get paymentDetails => 'Payment Details';

  @override
  String get receivedBy => 'Received by';

  @override
  String get cashierSignature => 'Cashier Signature';

  @override
  String get clientSignature => 'Client Signature';

  @override
  String get paymentExceedsTotal => 'Paid amount cannot exceed total amount';

  @override
  String get invoiceGenerated => 'Invoice Generated';

  @override
  String get whatToDoWithInvoice => 'What do you want to do with the invoice?';

  @override
  String get preview => 'Preview';

  @override
  String get share => 'Share';

  @override
  String get invoiceSaved => 'Invoice saved';

  @override
  String get open => 'Open';

  @override
  String get invoiceShared => 'Invoice shared';

  @override
  String get invoiceGenerationError => 'Invoice generation error';

  @override
  String get thankYouForYourPurchase => 'Thank you for your purchase!';

  @override
  String get invoicePreview => 'Invoice Preview';

  @override
  String get printSuccess => 'Printed successfully!';

  @override
  String get saveError => 'Error saving file';

  @override
  String get shareError => 'Error sharing file';

  @override
  String get extract => 'Extraire';

  @override
  String get extractSelected => 'Extraire sélectionnés';

  @override
  String get exportOptions => 'Options d\'export';

  @override
  String get exportCompleted => 'Export terminé !';

  @override
  String get exportSuccess => 'Export réussi';

  @override
  String get exportError => 'Erreur d\'export';

  @override
  String get noDataToExport => 'Aucune donnée à exporter';

  @override
  String get totalClients => 'Total Clients';

  @override
  String get generationDate => 'Date de génération';

  @override
  String get nombreAchats => 'Nombre d\'achats';

  @override
  String get dernierAchat => 'Dernier achat';

  @override
  String get totalRecords => 'Total Records';

  @override
  String get panierCode => 'Cart Code';

  @override
  String get productRevenue => 'Product Revenue';

  @override
  String get totalPanniers => 'Total Carts';

  @override
  String get totalRemaining => 'Total Remaining';

  @override
  String get averageAmount => 'Average Amount';

  @override
  String get selected => 'Selected';

  @override
  String get totalProducts => 'Total Products';

  @override
  String get totalStockValue => 'Total Stock Value';

  @override
  String get totalSaleValue => 'Total Sale Value';

  @override
  String get averagePrice => 'Average Price';

  @override
  String get categoryCode => 'Category Code';

  @override
  String get categoryName => 'Category Name';

  @override
  String get totalCategories => 'Total Categories';

  @override
  String get discountCode => 'Discount Code';

  @override
  String get discountName => 'Discount Name';

  @override
  String get discountType => 'Discount Type';

  @override
  String get discountValue => 'Discount Value';

  @override
  String get totalDiscounts => 'Total Discounts';

  @override
  String get packCode => 'Pack Code';

  @override
  String get packName => 'Pack Name';

  @override
  String get packPrice => 'Pack Price';

  @override
  String get totalPacks => 'Total Packs';

  @override
  String get averagePackPrice => 'Average Pack Price';

  @override
  String get subCategoryCode => 'Sub-Category Code';

  @override
  String get subCategoryName => 'Sub-Category Name';

  @override
  String get totalSubCategories => 'Total Sub-Categories';

  @override
  String get supplierName => 'Supplier Name';

  @override
  String get totalSuppliers => 'Total Suppliers';

  @override
  String get paymentCode => 'Payment Code';

  @override
  String get totalPayments => 'Total Payments';

  @override
  String get noSupplierSelected => 'No supplier selected';

  @override
  String get entryCode => 'Entry Code';

  @override
  String get totalEntries => 'Total Entries';

  @override
  String get scanCode => 'Scan Code';

  @override
  String get totalScans => 'Total Scans';

  @override
  String get exitCode => 'Exit Code';

  @override
  String get totalExits => 'Total Exits';

  @override
  String get returnCode => 'Return Code';

  @override
  String get totalReturns => 'Total Returns';

  @override
  String get clientReturns => 'Client Returns';

  @override
  String get supplierReturns => 'Supplier Returns';

  @override
  String get clientReturn => 'Client Return';

  @override
  String get supplierReturn => 'Supplier Return';

  @override
  String get movementCode => 'Movement Code';

  @override
  String get totalMovements => 'Total Movements';

  @override
  String get clientMovements => 'Client Movements';

  @override
  String get supplierMovements => 'Supplier Movements';

  @override
  String get listCode => 'List Code';

  @override
  String get totalLists => 'Total Lists';

  @override
  String get withSuppliers => 'With Suppliers';

  @override
  String get userCode => 'User Code';

  @override
  String get userName => 'User Name';

  @override
  String get totalUsers => 'Total Users';

  @override
  String get adminUsers => 'Admin Users';

  @override
  String get cashierUsers => 'Cashier Users';

  @override
  String get storekeeperUsers => 'Storekeeper Users';

  @override
  String get roleCode => 'Role Code';

  @override
  String get totalRoles => 'Total Roles';

  @override
  String get storeCode => 'Store Code';

  @override
  String get storeName => 'Store Name';

  @override
  String get totalStores => 'Total Stores';

  @override
  String get averageStorageRate => 'Average Storage Rate';

  @override
  String get totalBalance => 'Total Balance';

  @override
  String get totalArticles => 'Total Articles';

  @override
  String get totalProductsInCategories => 'Total Products in Categories';

  @override
  String get averageProductsPerCategory => 'Average Products per Category';

  @override
  String get totalUsage => 'Total Usage';

  @override
  String get percentageDiscounts => 'Percentage Discounts';

  @override
  String get fixedDiscounts => 'Fixed Discounts';

  @override
  String get averageDiscount => 'Average Discount';

  @override
  String get totalProductsInPacks => 'Total Products in Packs';

  @override
  String get totalValue => 'Total Value';

  @override
  String get totalProductsInSubCategories => 'Total Products in Sub-Categories';

  @override
  String get averageProductsPerSubCategory =>
      'Average Products per Sub-Category';

  @override
  String get incomingAmount => 'Incoming Amount';

  @override
  String get outgoingAmount => 'Outgoing Amount';

  @override
  String get clientPayments => 'Client Payments';

  @override
  String get supplierPayments => 'Supplier Payments';

  @override
  String get averageQuantity => 'Average Quantity';

  @override
  String get createdByCode => 'Created By Code';

  @override
  String get totalCalculatedAmount => 'Total Calculated Amount';

  @override
  String get totalCalculatedProducts => 'Total Calculated Products';

  @override
  String get totalCalculatedQuantity => 'Total Calculated Quantity';

  @override
  String get scansWithGap => 'Scans with Gap';

  @override
  String get breakdownByType => 'Breakdown by Type';

  @override
  String get count => 'Count';

  @override
  String get totalPurchaseValue => 'Total Purchase Value';

  @override
  String get totalItems => 'Total Items';

  @override
  String get averageItems => 'Average Items';

  @override
  String get totalSales => 'Total Sales';

  @override
  String get averageSalesPerUser => 'Average Sales per User';

  @override
  String get averageUsersPerRole => 'Average Users per Role';

  @override
  String get maxProducts => 'Max Products';

  @override
  String get minProducts => 'Min Products';

  @override
  String get cashRegisterCode => 'Cash Register Code';

  @override
  String get totalCaisses => 'Total Cash Registers';

  @override
  String get averageBalance => 'Average Balance';

  @override
  String get storesWithCaisses => 'Stores with Cash Registers';

  @override
  String get insertions => 'Insertions';

  @override
  String get logins => 'Logins';

  @override
  String get logouts => 'Logouts';

  @override
  String get totalZakatRecords => 'Total Zakat Records';

  @override
  String get totalZakatAmount => 'Total Zakat Amount';

  @override
  String get paidZakat => 'Paid Zakat';

  @override
  String get unpaidZakat => 'Unpaid Zakat';

  @override
  String get mandatoryZakat => 'Mandatory Zakat';

  @override
  String get userInformation => 'User Information';

  @override
  String get lastName => 'Last name';

  @override
  String get firstName => 'First name';

  @override
  String get shopInformation => 'Shop Information';

  @override
  String get systemSettings => 'System Settings';

  @override
  String get shopName => 'Shop Name';

  @override
  String get appId => 'App ID';

  @override
  String get language => 'Language';

  @override
  String get reset => 'Reset';

  @override
  String get enterUsername => 'Enter username';

  @override
  String get enterShopName => 'Enter shop name';

  @override
  String get enterAppId => 'Enter app ID';

  @override
  String get settingsSaved => '✅ Settings saved';

  @override
  String get shopAddress => 'Full address';

  @override
  String get shopAddressHint => 'Shop\'s full address';

  @override
  String get shopLogo => 'Shop logo';

  @override
  String get changeLogo => 'Change logo';

  @override
  String get shopPhone => 'Phone';

  @override
  String get shopEmail => 'Email';

  @override
  String get legalInformation => 'Legal information (RC / NIF / NIS / Article)';

  @override
  String get rcLabel => 'RC';

  @override
  String get nifLabel => 'NIF';

  @override
  String get nisLabel => 'NIS';

  @override
  String get articleLabel => 'Tax article';

  @override
  String get ticketMessage => 'Thank-you message (ticket)';

  @override
  String get ticketMessageHint => 'E.g. Thank you for your visit!';

  @override
  String get paymentMethodsSection => 'Payment methods';

  @override
  String get paymentMethodsHint =>
      'Choose which payment methods are offered at checkout';

  @override
  String get atLeastOnePaymentRequired =>
      'At least one payment method must stay active';

  @override
  String get devicesSection => 'Devices and printing';

  @override
  String get printerType => 'Printer type';

  @override
  String get printerTypeBluetooth => 'Bluetooth thermal';

  @override
  String get printerTypeUsb => 'USB thermal (ESC/POS)';

  @override
  String get printerTypeReseau => 'Network thermal (ESC/POS)';

  @override
  String get printerTypeNormale => 'Regular printer (Windows)';

  @override
  String get selectPrinterLabel => 'Printer';

  @override
  String get ipAddressLabel => 'IP address';

  @override
  String get portLabel => 'Port';

  @override
  String get rollWidthLabel => 'Roll width';

  @override
  String get refreshPrinters => 'Refresh';

  @override
  String get noPrinterConfigured => 'No printer selected';

  @override
  String get backupSection => 'Database backup';

  @override
  String get backupFolder => 'Backup folder';

  @override
  String get documentsFolder =>
      'Storage folder for(Excel, PDF, invoices, receipts)';

  @override
  String get chooseFolder => 'Choose a folder';

  @override
  String get backupNow => 'Back up now';

  @override
  String get restoreBackup => 'Restore a backup';

  @override
  String get autoBackup => 'Automatic backup';

  @override
  String get backupFrequency => 'Frequency';

  @override
  String get frequencyStartup => 'On every startup';

  @override
  String get frequencyDaily => 'Daily';

  @override
  String get frequencyWeekly => 'Weekly';

  @override
  String get lastBackup => 'Last backup';

  @override
  String get neverBackedUp => 'Never';

  @override
  String get backupSuccess => 'Backup created successfully';

  @override
  String get backupError => 'Error while creating backup';

  @override
  String get restoreConfirmTitle => 'Restore the database?';

  @override
  String get restoreConfirmMessage =>
      'This will replace all current data with the selected backup. The application must be restarted afterwards. Continue?';

  @override
  String get restoreSuccess =>
      'Database restored. Please restart the application.';

  @override
  String get restoreError => 'Error while restoring backup';

  @override
  String get currencye => 'Currency';

  @override
  String get operationFailed => 'Operation Failed';

  @override
  String get ticketSavedSuccess => 'Ticket Saved';

  @override
  String get addProduct => 'Add Product';

  @override
  String get mouvement => 'Movement';

  @override
  String get noPhotos => 'No Photos';

  @override
  String get attention => 'Attention';

  @override
  String get salesprevious => 'Sales (Previous periode)';

  @override
  String get paye => 'Payiement';

  @override
  String get reste => 'Reste';

  @override
  String get packagingPrix1 => 'Price Packaging 1';

  @override
  String get packagingPrix2 => 'Price Packaging 2';

  @override
  String get packagingPrice1Hint => 'Price Box';

  @override
  String get packagingPrice2Hint => 'Price BigBox';

  @override
  String get lepannierestenregestre => 'The cart is enregistred';

  @override
  String get lepanniernestpasenregestre => 'Opération failed';

  @override
  String get marge => 'Benefits';

  @override
  String get confirmPrint => 'Confirmation';

  @override
  String get aiMode => 'AI';

  @override
  String get aiModeDescription =>
      'Use the \'New\' button to scan a receipt with AI';

  @override
  String get attachBonFromDisk => 'Attach a photo';

  @override
  String get receiveBonFromPhone => 'Receive from phone';

  @override
  String get connectMobileAppTitle => 'Connect the CaisseDZ Scanner mobile app';

  @override
  String get receptionNoNetwork => 'No local network address detected';

  @override
  String get receptionStartServer => 'Start server';

  @override
  String get receptionStopServer => 'Stop server';

  @override
  String get receptionStatusConnected => 'Phone connected';

  @override
  String get receptionStatusWaiting => 'Waiting for phone connection…';

  @override
  String get receptionPhotoMissing => 'This photo could not be found on disk';

  @override
  String get receptionStatutRecu => 'Received';

  @override
  String get receptionStatutTraite => 'Processed';

  @override
  String get receptionStatutErreur => 'Error';

  @override
  String get receptionAllStatuses => 'All statuses';

  @override
  String get receptionDateRangeLabel => 'Received date';

  @override
  String get pairingCodeLabel => 'Pairing code';

  @override
  String get regeneratePairingCode => 'Regenerate code';

  @override
  String get pairingCodeCopied => 'Code copied to clipboard';

  @override
  String get pairedDevicesSection => 'Paired phones';

  @override
  String get noPairedDevices => 'No paired phone';

  @override
  String get pairingCodeExpiresLabel => 'Expires in';

  @override
  String get pairingCodeExpired => 'Code expired — regenerate it';

  @override
  String get scanOrTypeCode =>
      'Scan the QR code or type the pairing code on the phone';

  @override
  String get mobileConnectTooltip => 'Connect a phone';

  @override
  String get startingServerAutomatically => 'Preparing the connection…';

  @override
  String get advancedConnectionSettings =>
      'Advanced settings (IP address / port)';

  @override
  String get scanDateRangeLabel => 'Scan date';

  @override
  String get aiReceipt => 'AI Receipt';

  @override
  String get uploadReceipt => 'Upload receipt';

  @override
  String get processing => 'Processing...';

  @override
  String get tapToSelectImage => 'Tap to select an image';

  @override
  String get originalName => 'Original name';

  @override
  String get mappedProduct => 'Mapped product';

  @override
  String get selectProduct => 'Select a product';

  @override
  String get addManualProduct => '+ Add manual product';

  @override
  String get colis => 'Colis';

  @override
  String get actualQty => 'Actuel Quantity';

  @override
  String get quickEntry => 'Entry';

  @override
  String get cashReceipt => 'Cash ';

  @override
  String get cashReceiptTitle => 'Cash prdct';

  @override
  String get numberOfSales => 'Number of sales';

  @override
  String get recentSales => 'Recent sales';

  @override
  String get noSalesFound => 'No sales found for this cash register';

  @override
  String get clearFilters => 'Clear filter';

  @override
  String get selectStoreForProduct => 'Plz select a store';

  @override
  String get requestedQuantity => 'Select quantity';

  @override
  String get selectStore => 'Select store';

  @override
  String discountAmountExceedsTotal(Object amount, Object total) {
    return 'The discount amount ($amount) exceeds the cart total ($total) !';
  }

  @override
  String conditionalDiscountToActivate(Object amount, Object currency) {
    return 'Conditional discount: +$amount $currency to activate';
  }

  @override
  String discountAppliedNamed(Object nom) {
    return '✅ Discount \'$nom\' applied!';
  }

  @override
  String packAddedToCart(Object nom, Object quantiteSuffix) {
    return '✅ Pack \'$nom\'$quantiteSuffix added to cart';
  }

  @override
  String get totalFinal => 'Final total';

  @override
  String get totalBeforeDiscount => 'Total';

  @override
  String get quantityMustBeGreaterThanZero =>
      'The quantity must supperoir then 0';

  @override
  String get numberMustBeGreaterThanZero => 'The number must be greater than 0';

  @override
  String get priceMustBeGreaterThanZero => 'The price must be supperior then 0';

  @override
  String get supplierRequired => 'Plz select a supplier';

  @override
  String get loading => 'Loading...';

  @override
  String get saving => 'Saving...';

  @override
  String get errorSavingSettings => 'Error saving settings';

  @override
  String get settingsReset => 'Settings reset';

  @override
  String get userNotFound => 'User not found';

  @override
  String get pleaseLoginFirst => 'Please login first';

  @override
  String get rolePermissions => 'Role Permissions';

  @override
  String get selectAtLeastOnePermission =>
      'Please select at least one permission';

  @override
  String get warning => 'Warning';

  @override
  String get permissions => 'Permissions';

  @override
  String get permissionsDescription =>
      'Configure the permissions for this role';

  @override
  String get selectPermissions => 'Role Permissions';

  @override
  String get selectAll => 'Select All';

  @override
  String get deselectAll => 'Deselect All';

  @override
  String get previous => 'Previous';

  @override
  String get roleInfo => 'Role Information';

  @override
  String get passwordTooShort => 'Password must be at least 4 characters';

  @override
  String get valueMustBeGreaterThanZero => 'Value must be greater than 0';

  @override
  String get sourceAndDestinationMustBeDifferent =>
      'Source and destination must be different';

  @override
  String get reduction => 'Reduction';

  @override
  String get packactuel => 'Current pack';

  @override
  String get remiseactuel => 'Current discount';

  @override
  String get categorieactuel => 'Category';

  @override
  String get souscategorieactuel => 'subcategory';

  @override
  String get entryrapide => 'Quick entry';

  @override
  String get catalog => 'Catalog';

  @override
  String get newCatalogProduct => 'New catalog product';

  @override
  String get editCatalogProduct => 'Edit catalog product';

  @override
  String get deleteCatalogProducts => 'Remove from catalog';

  @override
  String get confirmDeleteCatalogProducts =>
      'This deletion is permanent and affects the catalog shared across all CaisseDZ stores. Continue?';

  @override
  String get catalogPhotoUrl => 'Photo URL';

  @override
  String get catalogPhotoUrlHint => 'https://...';

  @override
  String get catalogSyncFailed =>
      'Product saved locally, but syncing with the remote catalog failed.';

  @override
  String productAlreadyExistsLocally(String produit) {
    return 'This product already exists in your stock: \"$produit\"';
  }

  @override
  String stockGlobalInsuffisant(String disponible, String demande) {
    return 'Insufficient global stock!\nAvailable: $disponible piece(s)\nRequested: $demande piece(s)';
  }

  @override
  String stockInsuffisantMagasin(
    String magasin,
    String disponible,
    String demande,
  ) {
    return 'Insufficient stock in store \'$magasin\'!\nAvailable: $disponible piece(s)\nRequested: $demande piece(s)\n\nDo you want to take only the available quantity?';
  }

  @override
  String get produitAucunMagasin =>
      'This product is not available in any store!';

  @override
  String get packSansProduit => 'This pack contains no product';

  @override
  String produitInexistantBase(String code) {
    return 'Product \'$code\' does not exist in the database';
  }

  @override
  String stockInsuffisantPourProduit(
    String code,
    String disponible,
    String necessaire,
  ) {
    return 'Insufficient stock for product \'$code\'\nAvailable: $disponible piece(s)\nNeeded: $necessaire piece(s)';
  }

  @override
  String produitInexistant(String code) {
    return 'Product \'$code\' does not exist';
  }

  @override
  String get aucunPackDisponible => 'No pack available';

  @override
  String stockInsuffisantDetail(String disponible, String demande) {
    return 'Insufficient stock!\nAvailable: $disponible piece(s)\nRequested: $demande piece(s)';
  }

  @override
  String stockInsuffisantRestant(String disponible) {
    return 'Insufficient stock!\nOnly $disponible piece(s) left available';
  }

  @override
  String stockInsuffisantSupplement(String disponible, String demande) {
    return 'Insufficient stock!\nAvailable: $disponible piece(s)\nAdditional requested: $demande piece(s)';
  }

  @override
  String remiseConditionMessage(String nom, String montant) {
    return 'The discount \'$nom\' will be applied automatically when the total reaches $montant DA.';
  }

  @override
  String aiScanSavedDetails(
    String code,
    String fournisseur,
    String produits,
    String total,
  ) {
    return 'Entry saved successfully!\n\nCode: $code\nSupplier: $fournisseur\nProducts: $produits\nTotal: $total DZD';
  }

  @override
  String saveFailed(String error) {
    return 'Save failed: $error';
  }

  @override
  String get confirmModifyClient =>
      'Are you sure you want to modify this client?';

  @override
  String get selectClientType => 'Please select a client type';

  @override
  String caisseNotFound(String caisse) {
    return 'Cash register \'$caisse\' not found.';
  }

  @override
  String get categoryModifiedCascade =>
      'Category modified successfully.\n\nAll subcategories and products have been updated.';

  @override
  String get confirmModifyCaisse =>
      'Are you sure you want to modify this cash register?';

  @override
  String get confirmModifyFournisseur =>
      'Are you sure you want to modify this supplier?';

  @override
  String get confirmModifyPack => 'Are you sure you want to modify this pack?';

  @override
  String get confirmModifyBesoinListe =>
      'Are you sure you want to modify this need list?';

  @override
  String get modificationError => 'An error occurred during modification.';

  @override
  String get sellPriceMustBePositive => 'The sale price must be greater than 0';

  @override
  String get sellPriceMustExceedBuyPrice =>
      'The sale price must be greater than the purchase price';

  @override
  String get selectStatus => 'Please select a status';

  @override
  String versementLieRetourModif(String code) {
    return 'This payment is linked to return $code. Modify it from that return.';
  }

  @override
  String versementLieRetourSuppr(String code, String codeRetour) {
    return 'Payment $code is linked to return $codeRetour. Delete it from that return.';
  }

  @override
  String get loginRequiredChangeCategory =>
      'You must be logged in to change the category and subcategory.';

  @override
  String get selectRole => 'Please select a role';

  @override
  String qtyAndBuyPriceMustBePositiveFor(String produit) {
    return 'Quantity and purchase price must be greater than 0 for $produit';
  }

  @override
  String sellPriceMustExceedBuyPriceFor(String produit) {
    return 'The sale price must be greater than the purchase price for $produit';
  }

  @override
  String get selectPannierForReturn =>
      'Please choose the cart concerned by this return.';

  @override
  String get selectEntreeOrSmartScanForReturn =>
      'Please choose the entry concerned by this return.';

  @override
  String get internetConnected => 'Connected to internet';

  @override
  String get internetDisconnected => 'No internet connection';

  @override
  String get ouvrirCaisse => 'Open cash register';

  @override
  String get cloturerCaisse => 'Close cash register';

  @override
  String get mouvementManuel => 'Manual movement';

  @override
  String get soldeOuverture => 'Opening balance';

  @override
  String soldeOuvertureSuggere(String montant) {
    return 'Suggested amount: $montant';
  }

  @override
  String get soldeTheorique => 'Expected balance';

  @override
  String get soldeReel => 'Actual balance (counted)';

  @override
  String get ecartCaisse => 'Difference';

  @override
  String get ouvertureCaisseSuccess => 'Cash register opened successfully';

  @override
  String get clotureCaisseSuccess => 'Cash register closed successfully';

  @override
  String sessionDejaOuverte(String caisse) {
    return 'A cash register session is already open for \'$caisse\'.';
  }

  @override
  String get aucuneSessionOuverteACloturer =>
      'No open session to close for this cash register.';

  @override
  String aucuneSessionOuverte(String caisse) {
    return 'No open cash register session for \'$caisse\'. Please open the cash register first.';
  }

  @override
  String get entreeManuelle => 'Manual entry';

  @override
  String get sortieManuelle => 'Manual exit';

  @override
  String get motifMouvement => 'Reason';

  @override
  String get mouvementAjouteSuccess => 'Movement added successfully';

  @override
  String sessionCaisseOuverteDepuis(String date) {
    return 'Session open since $date';
  }

  @override
  String get sessionCaisseFermee => 'Cash register closed';

  @override
  String get cashRegisterRequired => 'Please select a cash register';

  @override
  String get cashSessionsTab => 'Cash sessions';

  @override
  String get cashMovementsTab => 'Cash movements';

  @override
  String get noSessionsYet => 'No sessions yet';

  @override
  String get viewMovements => 'View movements';

  @override
  String get noSessionSelected => 'No session selected';

  @override
  String get selectSingleSessionForMovements =>
      'Please select a single session to view its movements';

  @override
  String get sessionStatutOuverte => 'Open';

  @override
  String get sessionStatutCloturee => 'Closed';

  @override
  String get cancelSmartScan => 'Cancel entry';

  @override
  String get confirmCancelSmartScans =>
      'Are you sure you want to cancel these entries?';

  @override
  String get smartScanContentLocked =>
      'A recorded purchase can no longer have its content modified — use a cancellation';

  @override
  String get smartScanAlreadyCancelled =>
      'Entry not found or already cancelled';

  @override
  String get cancelReturns => 'Cancel returns';

  @override
  String get confirmCancelReturns =>
      'Are you sure you want to cancel these returns?';

  @override
  String get cancelExits => 'Cancel exits';

  @override
  String get confirmCancelExits =>
      'Are you sure you want to cancel these exits?';
}
