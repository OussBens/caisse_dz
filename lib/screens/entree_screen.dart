import 'dart:io';
import 'package:caisse_dz/core/dialog/AI/ai_receipt_dialog.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/BesionListDetail.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Entree.dart';
import 'package:caisse_dz/Services/Client.dart';

import 'package:caisse_dz/l10n/app_localizations.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_nouveau.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_detail.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_actif.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_modif.dart';
import 'package:caisse_dz/core/dialog/entree/entree_nouveau.dart';
import 'package:caisse_dz/core/dialog/entree/entree_detail.dart';
import 'package:caisse_dz/core/dialog/entree/entree_actif.dart';
import 'package:caisse_dz/core/dialog/entree/entree_modif.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';

import 'package:caisse_dz/core/tableau/entree/entree_tableau.dart';
import 'package:caisse_dz/core/tableau/smart_scan/tableau_smart_scan.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_entree_rapide.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_stock_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_smart_scan.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/entree.dart';
import 'dart:ui' as ui;

String? selectedEtatFilterS;
String? selectedEtatFilterE;

List<BesoinListDetail> besoinListDetailsTest = [];

// Valeurs sélectionnées dans le filtre
String? selectedProduitFilter;
String? selectedFournisseurFilter;
String? selectedCategorieFilter;
String? selectedMagasinFilter;
String? selectedSousCategorieFilter;
String? selectedMarqueFilter;
String? selectedFournisseurSCFilter;

List<Produit>           besoinsTest           = [];
List<SousCategorie>     sousCategoriesTest    = [];
List<Client>            clientsTest           = [];
List<Fournisseur>       fournisseursTest      = [];
List<Produit>           produitsTest          = [];
List<Categorie>         categoriesTest        = [];
List<Magasin>           magasinsTest          = [];
List<SmartScan>         smartScansTest        = [];
List<Entree>            entreeTest             = [];

List<Entree>     entreesSelectionnes    = [];
List<SmartScan>   smartscansSelectionnes  = [];

class EntreeScreen extends StatefulWidget {
  const EntreeScreen({super.key});
  @override
  State<EntreeScreen> createState() => _EntreeScreenState();
}

class _EntreeScreenState extends State<EntreeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_RAPIDE = 0;
  static const int TAB_SMART_SCAN = 1;
  static const int TAB_AI = 2;

  List<String> sousCategorieFilterOptions = sousCategoriesTest.map((sc) => sc .nom).toSet().toList();
  List<String> FournisseurFilterOptions   = fournisseursTest  .map((sc) => sc .nom).toSet().toList();
  List<String> categorieFilterOptions     = categoriesTest    .map((c)  => c  .nom).toSet().toList();
  List<String> magasinFilterOptions       = magasinsTest      .map((sc) => sc .nom).toSet().toList();
  List<String> ProduitFilterOptions       = produitsTest      .map((c)  => c  .nom).toSet().toList();

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  String nombre_entree      = "500";
  String nombre_smart_scan  = "320";
  String nombre_ai          = "0";

  final titles = ["Rapide", "SmartScan", "AI"];

  Future<void> loadAllData() async {
    final test = await ProduitServices.getAllProduits();

    final besoinListDetails = await BesoinListDetailServices.getAllBesoinListDetail();
    final sousCategories    = await SousCategoriesServices.getAllSousCategorie();
    final fournisseurs      = await FournisseurServices.getAllFournisseurs();
    final categories        = await CategorieServices.getAllCategorie();
    final smartScans        = await SmartScanServices.getAllSmartScans();
    final produits          = await ProduitServices.getAllProduits();
    final magasins          = await MagasinServices.getAllMagasins();
    final clients           = await ClientServices.getAllClients();
    final entrees           = await EntreeServices.getAllEntre();

    setState(() {
      besoinListDetailsTest = besoinListDetails;
      sousCategoriesTest    = sousCategories;
      fournisseursTest      = fournisseurs;
      categoriesTest        = categories;
      smartScansTest        = smartScans;
      smartscansFiltres     = smartScans;
      produitsTest          = produits;
      magasinsTest          = magasins;
      clientsTest           = clients;
      entreeTest            = entrees;
      smartscansFiltres = smartScansTest;

      sousCategorieFilterOptions  = sousCategoriesTest  .map((sc) => sc .nom).toSet().toList();
      FournisseurFilterOptions    = fournisseursTest    .map((sc) => sc .nom).toSet().toList();
      categorieFilterOptions      = categoriesTest      .map((c)  => c  .nom).toSet().toList();
      magasinFilterOptions        = magasinsTest        .map((sc) => sc .nom).toSet().toList();
      ProduitFilterOptions        = produitsTest        .map((c)  => c  .nom).toSet().toList();

      besoinsTest = test.where((e) => e.quantite <= e.seuilMin).toList();

      entreesFiltres    = entreeTest;
      smartscansFiltres = smartScansTest;

      nombre_entree = entreesFiltres.length.toString();
      nombre_smart_scan = smartscansFiltres.length.toString();

      entreesSelectionnes   .clear();
      smartscansSelectionnes.clear();
    });
  }

  // ... (gardez vos méthodes d'export _exportCurrentModuleToExcel et _exportSelectedToExcel en les adaptant avec _tabController.index)

  // ✅ Traduire les périodes rapides
  Map<String, String> _getPeriodesRapides(AppLocalizations l10n) {
    return {
      "today": l10n.today,
      "yesterday": l10n.yesterday,
      "week": l10n.thisWeek,
      "lastWeek": l10n.lastWeek,
      "month": l10n.thisMonth,
      "lastMonth": l10n.lastMonth,
      "last7days": l10n.last7Days,
      "last30days": l10n.last30Days,
      "year": l10n.thisYear,
      "lastYear": l10n.lastYear,
    };
  }

  DateTime? dateDebutE;
  DateTime? dateFinE;
  final TextEditingController _dateDebutCtrlE  = TextEditingController();
  final TextEditingController _dateFinCtrlE    = TextEditingController();
  DateTime? dateDebutSC;
  DateTime? dateFinSC;
  final TextEditingController _dateDebutCtrlSC = TextEditingController();
  final TextEditingController _dateFinCtrlSC   = TextEditingController();

  bool filtresActifs = false;
  bool? filtreetat;

  double? prixAchatMin;
  double? prixAchatMax;
  double? prixVenteMin;
  double? prixVenteMax;
  double? quantiteMax;
  double? quantiteMin;
  double? montantMin;
  double? montantMax;

  String? periodeRapide;
  String? periodeRapideE;

  final TextEditingController _searchControllerE = TextEditingController();
  final TextEditingController _searchControllerSC = TextEditingController();

  List<SmartScan> smartscansFiltres = [];
  List<Entree> entreesFiltres = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          vider_selectionne();
        });
      }
    });
    loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void vider_selectionne() {
    entreesSelectionnes.clear();
    smartscansSelectionnes.clear();
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }



  void appliquerFiltre() {
    entreesFiltres = entreeTest.where((p) {
      final searchText = _searchControllerE.text.toLowerCase();
      final ProdOk = selectedProduitFilter == null || selectedProduitFilter!.isEmpty || p.produit == selectedProduitFilter;
      final FournOk = selectedFournisseurFilter == null || selectedFournisseurFilter!.isEmpty || p.fournisseur == selectedFournisseurFilter;
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final prixAchatOk = (prixAchatMin == null || p.prix >= prixAchatMin!) &&
          (prixAchatMax == null || p.prix <= prixAchatMax!);

      final quantiteOk = (quantiteMin == null || p.quantite >= quantiteMin!) &&
          (quantiteMax == null || p.quantite <= quantiteMax!);

      final etatOk = selectedEtatFilterS == null ||
          selectedEtatFilterS == "" ||
          (selectedEtatFilterS == "Actif" && p.etat) ||
          (selectedEtatFilterS == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebutE == null && dateFinE == null) return true;

        final d = p.date;

        final debut = dateDebutE != null
            ? DateTime(dateDebutE!.year, dateDebutE!.month, dateDebutE!.day)
            : null;

        final fin = dateFinE != null
            ? DateTime(dateFinE!.year, dateFinE!.month, dateFinE!.day, 23, 59, 59)
            : null;

        if (debut != null && d.isBefore(debut)) return false;
        if (fin != null && d.isAfter(fin)) return false;

        return true;
      }();

      return ProdOk && FournOk && prixAchatOk && dateOk && etatOk && searchOk && quantiteOk;
    }).toList();

    if ((selectedFournisseurFilter == null || selectedFournisseurFilter!.isEmpty) &&
        (selectedProduitFilter == null || selectedProduitFilter!.isEmpty) &&
        (selectedEtatFilterS == null || selectedEtatFilterS!.isEmpty) &&
        prixAchatMin == null && prixAchatMax == null &&
        prixVenteMin == null && prixVenteMax == null &&
        quantiteMin == null && quantiteMax == null &&
        dateDebutSC == null &&
        dateFinSC == null &&
        _searchControllerE.text.isEmpty) {
      entreesFiltres = entreeTest;
    }
  }

  void appliquerFiltreSmartScan() {
    smartscansFiltres = smartScansTest.where((p) {
      final searchText = _searchControllerSC.text.toLowerCase();
      final fournissemoveOk = selectedFournisseurSCFilter == null || selectedFournisseurSCFilter!.isEmpty || p.fournisseur == selectedFournisseurSCFilter;
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final montantOk = (montantMin == null || p.montant >= montantMin!) &&
          (montantMax == null || p.montant <= montantMax!);

      final etatOk = selectedEtatFilterE == null ||
          selectedEtatFilterE == "" ||
          (selectedEtatFilterE == "Actif" && p.etat) ||
          (selectedEtatFilterE == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebutSC == null && dateFinSC == null) return true;

        final d = p.date;

        final debut = dateDebutSC != null
            ? DateTime(dateDebutSC!.year, dateDebutSC!.month, dateDebutSC!.day)
            : null;

        final fin = dateFinSC != null
            ? DateTime(dateFinSC!.year, dateFinSC!.month, dateFinSC!.day, 23, 59, 59)
            : null;

        if (debut != null && d.isBefore(debut)) return false;
        if (fin != null && d.isAfter(fin)) return false;

        return true;
      }();

      return fournissemoveOk && etatOk && searchOk && dateOk && montantOk;
    }).toList();

    if ((selectedFournisseurSCFilter == null || selectedFournisseurSCFilter!.isEmpty) &&
        montantMin == null &&
        montantMax == null &&
        (selectedEtatFilterE == null || selectedEtatFilterE!.isEmpty) &&
        dateDebutSC == null &&
        dateFinSC == null &&
        _searchControllerSC.text.isEmpty) {
      smartscansFiltres = smartScansTest;
    }
  }

  void _appliquerPeriodeRapideSC(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebutSC = DateTime(now.year, now.month, now.day);
        dateFinSC = dateDebutSC;
        break;
      case "yesterday":
        dateDebutSC = DateTime(now.year, now.month, now.day - 1);
        dateFinSC = dateDebutSC;
        break;
      case "week":
        dateDebutSC = now.subtract(Duration(days: now.weekday - 1));
        dateFinSC = dateDebutSC!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebutSC = now.subtract(Duration(days: now.weekday + 6));
        dateFinSC = dateDebutSC!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebutSC = DateTime(now.year, now.month, 1);
        dateFinSC = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebutSC = DateTime(now.year, now.month - 1, 1);
        dateFinSC = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebutSC = now.subtract(const Duration(days: 6));
        dateFinSC = now;
        break;
      case "last30days":
        dateDebutSC = now.subtract(const Duration(days: 29));
        dateFinSC = now;
        break;
      case "year":
        dateDebutSC = DateTime(now.year, 1, 1);
        dateFinSC = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebutSC = DateTime(now.year - 1, 1, 1);
        dateFinSC = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlSC.text = _formatDate(dateDebutSC!);
    _dateFinCtrlSC.text = _formatDate(dateFinSC!);

    appliquerFiltreSmartScan();
  }

  void _appliquerPeriodeRapideE(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebutE = DateTime(now.year, now.month, now.day);
        dateFinE = dateDebutE;
        break;
      case "yesterday":
        dateDebutE = DateTime(now.year, now.month, now.day - 1);
        dateFinE = dateDebutE;
        break;
      case "week":
        dateDebutE = now.subtract(Duration(days: now.weekday - 1));
        dateFinE = dateDebutE!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebutE = now.subtract(Duration(days: now.weekday + 6));
        dateFinE = dateDebutE!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebutE = DateTime(now.year, now.month, 1);
        dateFinE = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebutE = DateTime(now.year, now.month - 1, 1);
        dateFinE = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebutE = now.subtract(const Duration(days: 6));
        dateFinE = now;
        break;
      case "last30days":
        dateDebutE = now.subtract(const Duration(days: 29));
        dateFinE = now;
        break;
      case "year":
        dateDebutE = DateTime(now.year, 1, 1);
        dateFinE = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebutE = DateTime(now.year - 1, 1, 1);
        dateFinE = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlE.text = _formatDate(dateDebutE!);
    _dateFinCtrlE.text = _formatDate(dateFinE!);

    appliquerFiltre();
  }

  void supprimerFilter() {
    prixAchatMin = null;
    prixAchatMax = null;
    quantiteMin = null;
    quantiteMax = null;
    prixVenteMin = null;
    prixVenteMax = null;
    dateDebutE = null;
    dateFinE = null;
    _dateDebutCtrlE.clear();
    _dateFinCtrlE.clear();
    selectedEtatFilterS = null;
    _searchControllerE.clear();
    selectedFournisseurFilter = null;
    selectedProduitFilter = null;
  }

  void supprimerFilterSmartScan() {
    selectedFournisseurSCFilter = null;
    selectedEtatFilterE = null;
    _searchControllerSC.clear();
    dateDebutSC = null;
    dateFinSC = null;
    _dateDebutCtrlSC.clear();
    _dateFinCtrlSC.clear();
    montantMin = null;
    montantMax = null;
  }


  Future<void> _pickDateDebutE() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutE ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebutE = picked;
        _dateDebutCtrlE.text = _formatDate(picked);
        periodeRapideE = null;
        appliquerFiltre();
      });
    }
  }

  Future<void> _pickDateFinE() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinE ?? dateDebutE ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinE = picked;

        if (dateDebutE != null && picked.isBefore(dateDebutE!)) {
          dateFinE = dateDebutE;
        }

        _dateFinCtrlE.text = _formatDate(dateFinE!);
        periodeRapideE = null;
        appliquerFiltre();
      });
    }
  }

  Future<void> _pickDateDebutSC() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutSC ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebutSC = picked;
        _dateDebutCtrlSC.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreSmartScan();
      });
    }
  }

  Future<void> _pickDateFinSC() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinSC ?? dateDebutSC ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinSC = picked;

        if (dateDebutSC != null && picked.isBefore(dateDebutSC!)) {
          dateFinSC = dateDebutSC;
        }

        _dateFinCtrlSC.text = _formatDate(dateFinSC!);
        periodeRapide = null;
        appliquerFiltreSmartScan();
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    bool isRTL = false;
    final local = context.watch<LocaleProvider>();
    isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? ui.TextDirection.rtl : ui.TextDirection.ltr;
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);

    // ✅ Obtenir les périodes rapides traduites
    final periodesRapides = _getPeriodesRapides(l10n);

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.quickMode,
      l10n.smartScan,
      l10n.aiMode,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/cardwidget/entree_rapide_icon.png',
      'assets/icons/cardwidget/scan_icon.png',
      'assets/icons/ai_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_entree,
      nombre_smart_scan,
      nombre_ai,
    ];

    // ✅ Couleurs des tabs
    final tabColors = [
      Appstyle.blueC,
      Appstyle.violet,
      Appstyle.violetC,
    ];

    return Directionality(
      textDirection: textDirection,
      child: Scaffold(
        backgroundColor: Appstyle.violetC,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final screenHeight  = constraints.maxHeight  ;
            final screenWidth   = constraints.maxWidth   ;
            const minHeight     = Constant.minHeight;
            const minWidth      = Constant.minWidth ;

            final adjustedWidth = screenWidth < minWidth ? minWidth : screenWidth;
            final adjustedHeight = screenHeight < minHeight ? minHeight : screenHeight;

            final paddingV = adjustedHeight * 0.02;
            final paddingH = adjustedWidth * 0.02;

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: minWidth,
                    minHeight: minHeight,
                  ),
                  child: SizedBox(
                    width: adjustedWidth,
                    height: adjustedHeight,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SideBarWidget(),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                HeaderModule(
                                  gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                  child: Row(
                                    children: [
                                      Row(
                                        children: [
                                          Image.asset(
                                            "assets/icons/sidebar/entree_icon.png",
                                            width: 40,
                                            color: Appstyle.violet,
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            children: [
                                              Text(
                                                l10n.entry,
                                                style: Appstyle.textXLB.copyWith(
                                                  color: Appstyle.violet,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Text(
                                                "(${tabNames[currentTab]})",
                                                style: Appstyle.textXLB.copyWith(
                                                  color: Appstyle.violet,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        children: [
                                          TimeDateWidget(
                                            heure: "18:00",
                                            date: "25 Nov 2025",
                                            iconHeure: "assets/icons/hour_icon.png",
                                            iconDate: "assets/icons/agenda_icon.png",
                                          ),
                                          const SizedBox(width: 20),
                                          AccountWidget(
                                            name: userName,
                                            imageUrl: "assets/images/support.png",
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: paddingV / 2),

                                /// ✅ TAB BAR (remplace les CardWidget)
                                Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 10,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    isScrollable: false,
                                    indicator: BoxDecoration(
                                      color: currentTab == TAB_RAPIDE ? Appstyle.violet : Appstyle.indigo,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Appstyle.gris,
                                    dividerColor: Colors.transparent,
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    padding: const EdgeInsets.all(6),
                                    labelStyle: Appstyle.textXS.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    unselectedLabelStyle: Appstyle.textXS.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                    tabs: List.generate(3, (index) {
                                      final isSelected = currentTab == index;
                                      return Tab(
                                        icon: Container(
                                          width: 24,
                                          height: 24,
                                          child: Image.asset(
                                            tabIcons[index],
                                            width: 20,
                                            height: 20,
                                            color: isSelected ? Colors.white : Appstyle.gris,
                                          ),
                                        ),
                                        text: "${tabNames[index]} (${tabCounts[index]})",
                                      );
                                    }),
                                  ),
                                ),

                                SizedBox(height: paddingV / 2),

                                // ═══════════════════════════════════════════════════════════════════════════════
                                // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                // ═══════════════════════════════════════════════════════════════════════════════

                                // ──────────────────────────────────────────────────────────────
                                // 1. CAS RAPIDE (currentTab == TAB_RAPIDE)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_RAPIDE)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (entreesSelectionnes.length == 1)
                                        AfficheurEntreeMouvement(
                                          entree: entreesSelectionnes.first,
                                          onDetails: () {
                                            EntreeDetail(context, entreesSelectionnes.first);
                                          },
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurStockGlobalWidget(
                                            nombreBesoinList: 7,
                                            nombrePanniers: smartScansTest.length,
                                            nombreProduitsStock: 26,
                                            nombreRetours: 15,
                                            nombreSmartScan: 40,
                                            nombreSorties: 10,
                                          ),
                                        ),

                                      if (entreesSelectionnes.length == 1)
                                        SizedBox(height: paddingV / 2),

                                      // Filtres & Actions
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                  iconColor:Appstyle.violet ,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilter();
                                                        appliquerFiltre();
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                if (filtresActifs)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilter();
                                                        appliquerFiltre();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor:Colors.green ,
                                                  iconColor: Colors.green,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.download,
                                                  onPressed: () async {
                                                     },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                  color: Colors.orange,
                                                  onPressed: () async {
                                                   },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (entreesSelectionnes.length == 1) {
                                                      EntreeDetail(context, entreesSelectionnes.first);
                                                    } else if (entreesSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.selectSingleEntryForDetail,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/supprimer_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed: () async {
                                                    if (entreesSelectionnes.isNotEmpty) {
                                                      await AnnulerEntree(
                                                        context,
                                                        entreesSelectionnes,
                                                      );
                                                      await loadAllData();
                                                    } else if (entreesSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async {
                                                    if (entreesSelectionnes.length == 1) {
                                                      await EntreeModif(
                                                        context,
                                                        entreesSelectionnes.first,
                                                      );
                                                      await loadAllData();
                                                    } else if (entreesSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.selectSingleEntryToModify,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await EntreeNouveau(
                                                      context,
                                                      onSuccess: () async {
                                                        await loadAllData();
                                                        if (mounted) {
                                                          setState(() {
                                                            entreesFiltres = List.from(entreeTest);
                                                          });
                                                        }
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!filtresActifs)
                                        SizedBox(height: paddingV / 2),

                                      // Filtres
                                      if (filtresActifs)
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                            child: filtreEntree(setState, adjustedWidth * 1 / 3, l10n, translator, periodesRapides),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauEntreeAdvanced(
                                          key: ValueKey(entreesFiltres),
                                          entrees: entreesFiltres,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              entreesSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 2. CAS SMART SCAN (currentTab == TAB_SMART_SCAN)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_SMART_SCAN)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (smartscansSelectionnes.length == 1)
                                        AfficheurSmartScan(
                                          scan: smartscansSelectionnes.first,
                                          onDetails: () {
                                            SmartScanDetail(context, smartscansSelectionnes.first);
                                          },
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurStockGlobalWidget(
                                            nombreBesoinList: 7,
                                            nombrePanniers: smartScansTest.length,
                                            nombreProduitsStock: 26,
                                            nombreRetours: 15,
                                            nombreSmartScan: 40,
                                            nombreSorties: 10,
                                          ),
                                        ),

                                      if (smartscansSelectionnes.length == 1)
                                        SizedBox(height: paddingV / 2),

                                      // Filtres & Actions
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                  iconColor:Appstyle.violet ,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilterSmartScan();
                                                        appliquerFiltreSmartScan();
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                if (filtresActifs)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilterSmartScan();
                                                        appliquerFiltreSmartScan();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor:Colors.green ,
                                                  iconColor: Colors.green,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.download,
                                                  onPressed: () async {
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                  color: Colors.orange,
                                                  onPressed: () async {
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (smartscansSelectionnes.length == 1) {
                                                      SmartScanDetail(context, smartscansSelectionnes.first);
                                                    } else if (smartscansSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.selectSingleEntryForDetail,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/supprimer_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed: () async {
                                                    if (smartscansSelectionnes.isNotEmpty) {
                                                      await AnnulerSmartScan(
                                                        context,
                                                        smartscansSelectionnes,
                                                      );
                                                      await loadAllData();
                                                    } else if (smartscansSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async {
                                                    if (smartscansSelectionnes.length == 1) {
                                                      await SmartScanModif(
                                                        context,
                                                        smartscansSelectionnes.first,
                                                      );
                                                      await loadAllData();
                                                    } else if (smartscansSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.noEntrySelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entry,
                                                        message: l10n.selectSingleEntryToModify,
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    SmartScanDialog.open(context);
                                                    await loadAllData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!filtresActifs)
                                        SizedBox(height: paddingV / 2),

                                      // Filtres
                                      if (filtresActifs)
                                        Align(
                                          alignment: Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                            child: filtreSC(setState, adjustedWidth * 1 / 3, l10n, translator, periodesRapides),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauSmartScanAdvanced(
                                          key: ValueKey(smartscansFiltres),
                                          scans: smartscansFiltres,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              smartscansSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 3. CAS AI (currentTab == TAB_AI)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_AI)
                                    Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Image.asset(
                                              "assets/icons/ai_icon.png",
                                              width: 100,
                                              height: 100,
                                              color: Appstyle.violet,
                                            ),
                                          ),
                                          const SizedBox(height: 20),
                                          Text(
                                            l10n.aiModeDescription,
                                            style: Appstyle.textXLB.copyWith(
                                              color: Appstyle.violet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          const SizedBox(height: 30),
                                          MainButton(
                                            text: l10n.generalInformation,
                                            color: Appstyle.crevete,
                                            icon: Icons.auto_awesome,
                                            onPressed: () async {
                                              AISmartScanDialog.open(context);
                                              await loadAllData();
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget filtreEntree(
      void Function(VoidCallback fn) setState,
      double width,
      AppLocalizations l10n,
      ListsConstTranslator translator,
      Map<String, String> periodesRapides,
      ) {
    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.product,
                  child: TextListe(
                    value: selectedProduitFilter ?? "",
                    items: ProduitFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedProduitFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.supplier,
                  child: TextListe(
                    value: selectedFournisseurFilter,
                    items: FournisseurFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedFournisseurFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.status,
                  child: TextListe(
                    value: selectedEtatFilterS,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterS = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrlE,
                    onTap: _pickDateDebutE,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebutE != null,
                    controller: _dateFinCtrlE,
                    onTap: _pickDateFinE,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 400,
                child: ChampAvecLabel(
                  label: l10n.quickPeriod,
                  child: DropdownButtonFormField<String>(
                    value: periodeRapideE,
                    decoration: InputDecoration(
                      hintText: l10n.choosePeriod,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    items: periodesRapides.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          periodeRapideE = v;
                          _appliquerPeriodeRapideE(v, l10n);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: width * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: ChampAvecLabel(
                        label: l10n.search,
                        child: SearchField(
                          controller: _searchControllerE,
                          onChanged: (v) {
                            setState(() {
                              appliquerFiltre();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.purchasePrice,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: prixAchatMin,
                    maxValue: prixAchatMax,
                    onChanged: (min, max) {
                      setState(() {
                        prixAchatMin = min;
                        prixAchatMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.quantity,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: quantiteMin,
                    maxValue: quantiteMax,
                    onChanged: (min, max) {
                      setState(() {
                        quantiteMin = min;
                        quantiteMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget filtreSC(
      void Function(VoidCallback fn) setState,
      double width,
      AppLocalizations l10n,
      ListsConstTranslator translator,
      Map<String, String> periodesRapides,
      ) {
    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.supplier,
                  child: TextListe(
                    value: selectedFournisseurSCFilter,
                    items: FournisseurFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedFournisseurSCFilter = v;
                        appliquerFiltreSmartScan();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.amount,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: montantMin,
                    maxValue: montantMax,
                    onChanged: (min, max) {
                      setState(() {
                        montantMin = min;
                        montantMax = max;
                        appliquerFiltreSmartScan();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.status,
                  child: TextListe(
                    value: selectedEtatFilterE,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterE = translator.etatToFrench(v!);
                        appliquerFiltreSmartScan();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrlSC,
                    onTap: _pickDateDebutSC,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebutSC != null,
                    controller: _dateFinCtrlSC,
                    onTap: _pickDateFinSC,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: 400,
                child: ChampAvecLabel(
                  label: l10n.quickPeriod,
                  child: DropdownButtonFormField<String>(
                    value: periodeRapide,
                    decoration: InputDecoration(
                      hintText: l10n.choosePeriod,
                      isDense: true,
                      border: const OutlineInputBorder(),
                    ),
                    items: periodesRapides.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          periodeRapide = v;
                          _appliquerPeriodeRapideSC(v, l10n);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: width * 0.9,
                child: Row(
                  children: [
                    Expanded(
                      child: ChampAvecLabel(
                        label: l10n.search,
                        child: SearchField(
                          controller: _searchControllerSC,
                          onChanged: (v) {
                            setState(() {
                              appliquerFiltreSmartScan();
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getPeriodeDisplayName(String key, AppLocalizations l10n) {
    switch (key) {
      case "today": return l10n.today;
      case "yesterday": return l10n.yesterday;
      case "week": return l10n.thisWeek;
      case "lastWeek": return l10n.lastWeek;
      case "month": return l10n.thisMonth;
      case "lastMonth": return l10n.lastMonth;
      case "last7days": return l10n.last7Days;
      case "last30days": return l10n.last30Days;
      case "year": return l10n.thisYear;
      case "lastYear": return l10n.lastYear;
      default: return key;
    }
  }
}