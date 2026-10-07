import 'package:caisse_dz/Services/StatistiquesGlobales.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'dart:async';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'dart:io';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BonReception.dart';
import 'package:caisse_dz/Services/BonReceptionPhotos.dart';
import 'package:caisse_dz/core/dialog/AI/ai_receipt_dialog.dart';
import 'package:caisse_dz/core/widget/photo/bon_reception_card.dart';
import 'package:caisse_dz/core/widget/ai_smart_icon.dart';
import 'package:caisse_dz/data/models/bon_reception.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/BesionListDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';

import 'package:caisse_dz/l10n/app_localizations.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_nouveau.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_detail.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_actif.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_modif.dart';
import 'package:caisse_dz/core/dialog/entree/entree_nouveau.dart';
import 'package:caisse_dz/core/dialog/entree/entree_detail.dart';
import 'package:caisse_dz/core/dialog/entree/entree_modif.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';

import 'package:caisse_dz/core/tableau/smart_scan/tableau_smart_scan.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_stock_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_smart_scan.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/internet_status_widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'dart:ui' as ui;

String? selectedEtatFilterE;

List<BesoinListDetail> besoinListDetailsTest = [];

// Valeurs sélectionnées dans le filtre
String? selectedCategorieFilter;
String? selectedSousCategorieFilter;
String? selectedMarqueFilter;
String? selectedFournisseurSCFilter;

List<Produit>           besoinsTest           = [];
List<SousCategorie>     sousCategoriesTest    = [];
List<Client>            clientsTest           = [];
List<Fournisseur>       fournisseursTest      = [];
List<Produit>           produitsTest          = [];
List<Categorie>         categoriesTest        = [];
List<SmartScan>         smartScansTest        = [];
List<Utilisateur>       utilisateursTest      = [];

List<SmartScan>   smartscansSelectionnes  = [];

class EntreeScreen extends StatefulWidget {
  const EntreeScreen({super.key});
  @override
  State<EntreeScreen> createState() => _EntreeScreenState();
}

class _EntreeScreenState extends State<EntreeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_SMART_SCAN = 0;
  static const int TAB_AI = 1;

  List<String> sousCategorieFilterOptions = sousCategoriesTest.map((sc) => sc .nom).toSet().toList();
  List<String> FournisseurFilterOptions   = fournisseursTest  .map((sc) => sc .nom).toSet().toList();
  List<String> categorieFilterOptions     = categoriesTest    .map((c)  => c  .nom).toSet().toList();

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  String nombre_smart_scan  = "320";
  String nombre_ai          = "0";
  double seuilMinimum       = 0;

  final titles = ["SmartScan", "AI"];

  // Cards globales (AfficheurStockGlobalWidget) : vrais compteurs, voir
  // StatistiquesGlobalesServices.
  CompteursGlobaux compteursGlobaux = const CompteursGlobaux();

  Future<void> loadAllData() async {
    final test = await ProduitServices.getAllProduits();

    final besoinListDetails = await BesoinListDetailServices.getAllBesoinListDetail();
    final sousCategories    = await SousCategoriesServices.getAllSousCategorie();
    final fournisseurs      = await FournisseurServices.getAllFournisseurs();
    final categories        = await CategorieServices.getAllCategorie();
    final smartScans        = await SmartScanServices.getAllSmartScans();
    final versements        = await VerssementServices.getAllverssement();
    final produits          = await ProduitServices.getAllProduits();
    final clients           = await ClientServices.getAllClients();
    final param              = await ParamServices.getParam();
    final utilisateurs      = await UtilisateurServices.getAllUtilisateurs();
    final bonsReceptionList = await BonReceptionServices.getAllBonReceptions();
    // ✅ Quantités calculées depuis le journal des mouvements — remplace Produit.quantite.
    final quantitesTest = (await MouvementsServices.totauxParProduit()).quantites;

    final compteurs = await StatistiquesGlobalesServices.getCompteurs();
    if (!mounted) return;
    setState(() {
      compteursGlobaux = compteurs;
      bonsReception         = bonsReceptionList;
      nombre_ai             = bonsReceptionList.length.toString();
      appliquerFiltreAI();
      besoinListDetailsTest = besoinListDetails;
      sousCategoriesTest    = sousCategories;
      fournisseursTest      = fournisseurs;
      categoriesTest        = categories;
      smartScansTest        = smartScans;
      utilisateursTest      = utilisateurs;
      smartscansFiltres     = smartScans;
      versementsTest        = versements;
      verseParSmartScan     = SmartScanServices.verseParSmartScan(versements);
      nbrVersementParSmartScan = SmartScanServices.nbrVersementParSmartScan(versements);
      produitsTest          = produits;
      clientsTest           = clients;
      smartscansFiltres = smartScansTest;

      sousCategorieFilterOptions  = sousCategoriesTest  .map((sc) => sc .nom).toSet().toList();
      FournisseurFilterOptions    = fournisseursTest    .map((sc) => sc .nom).toSet().toList();
      categorieFilterOptions      = categoriesTest      .map((c)  => c  .nom).toSet().toList();

      besoinsTest = test.where((e) => (quantitesTest[e.code] ?? 0) <= param.Minimum).toList();
      seuilMinimum = param.Minimum;

      smartscansFiltres = smartScansTest;

      nombre_smart_scan = smartscansFiltres.length.toString();

      smartscansSelectionnes.clear();
    });
  }

  // ✅ Joindre une photo de bon depuis le disque : rejoint la même file
  // d'attente que les photos reçues depuis le mobile (statut 'recu').
  Future<void> _attachBonFromDisk() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image);
    final pickedPath = result?.files.single.path;
    if (pickedPath == null) return;

    final relativePath = await BonReceptionPhotoService.savePhoto(File(pickedPath));
    final db = await DbCreator.openDb();
    await BonReceptionServices(db).addBonReception(BonReception(
      id: 0,
      cheminPhoto: relativePath,
      dateReception: DateTime.now(),
    ));
    await loadAllData();
  }

  // ✅ Tap sur une vignette de la file : lance l'assistant IA directement à
  // l'étape de validation (photo déjà choisie), puis marque le bon traité.
  Future<void> _openWizardFor(BonReception bon) async {
    if (bon.estTraite) return;

    final file = await BonReceptionPhotoService.getPhotoFile(bon.cheminPhoto);
    if (file == null) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        kind: DialogKind.refuser,
        titre_concerne: '',
        message: l10n.receptionPhotoMissing,
      );
      return;
    }

    // ✅ Le scan IA appelle des API cloud (OCR + extraction) : sans réseau,
    // il échouerait au milieu du dialogue — autant prévenir avant d'ouvrir.
    if (!await hasInternetConnection()) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.attention,
        kind: DialogKind.attention,
        titre_concerne: '',
        message: l10n.internetDisconnected,
      );
      return;
    }

    await AISmartScanDialog.open(
      context,
      initialImage: file,
      receptionPhotoId: bon.id,
      receptionFournisseurCode: bon.fournisseurCode,
    );
    await loadAllData();
  }

  Future<void> _deleteBon(BonReception bon) async {
    final db = await DbCreator.openDb();
    await BonReceptionServices(db).deleteBonReception(bon.id);
    await BonReceptionPhotoService.deletePhoto(bon.cheminPhoto);
    await loadAllData();
  }

  Future<void> _exportSmartScanToExcel({bool enPdf = false}) async {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final scans = smartscansSelectionnes.isNotEmpty
        ? smartscansSelectionnes
        : (filtresActifs ? smartscansFiltres : smartScansTest);

    if (scans.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.smartScan,
        message: l10n.noDataToExport,
      );
      return;
    }

    try {
      final fichier = await executerAvecSpinner(
        context,
        () => ExcelGenerator.generateSmartScansExcel(
          smartScans: scans,
          versements: versementsTest,
          l10n: l10n,
          translator: translator,
        ),
      );
      if (!mounted) return;
      if (enPdf) {
        await ouvrirApercuPdfDepuisExcel(context, fichier: fichier, titre: l10n.smartScan, nomFeuille: 'SmartScans');
        return;
      }
      await ouvrirApercuExcel(
        context,
        fichier: fichier,
        nomFeuille: 'SmartScans',
        titre: l10n.smartScan,
        l10n: l10n,
      );
    } catch (e) {
      print('Excel export error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

  DateTime? dateDebutSC;
  DateTime? dateFinSC;
  final TextEditingController _dateDebutCtrlSC = TextEditingController();
  final TextEditingController _dateFinCtrlSC   = TextEditingController();

  bool filtresActifs = false;
  bool? filtreetat;

  double? montantMin;
  double? montantMax;

  String? periodeRapide;

  final TextEditingController _searchControllerSC = TextEditingController();

  List<SmartScan> smartscansFiltres = [];
  List<Verssement> versementsTest = [];
  Map<String, double> verseParSmartScan = {};
  Map<String, int> nbrVersementParSmartScan = {};

  // ✅ File d'attente des photos de bons de réception (jointes depuis le
  // disque ou reçues depuis le mobile), affichée dans l'onglet IA.
  List<BonReception> bonsReception = [];
  List<BonReception> bonsReceptionFiltres = [];

  // Filtres de l'onglet IA (mêmes principes que filtreSC pour SmartScan).
  bool filtresActifsAI = false;
  String? selectedFournisseurAIFilter;
  String? selectedStatutAIFilter; // 'recu' | 'traite' | 'erreur'
  DateTime? dateDebutAI;
  DateTime? dateFinAI;
  final TextEditingController _dateDebutCtrlAI = TextEditingController();
  final TextEditingController _dateFinCtrlAI = TextEditingController();
  // Filtre sur la date de scan (dateTraitement), distincte de la date de
  // réception ci-dessus.
  DateTime? dateDebutScanAI;
  DateTime? dateFinScanAI;
  final TextEditingController _dateDebutScanCtrlAI = TextEditingController();
  final TextEditingController _dateFinScanCtrlAI = TextEditingController();
  final TextEditingController _searchControllerAI = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    _dateDebutCtrlAI.dispose();
    _dateFinCtrlAI.dispose();
    _dateDebutScanCtrlAI.dispose();
    _dateFinScanCtrlAI.dispose();
    _searchControllerAI.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String? _nomUtilisateur(String? code) {
    if (code == null) return null;
    for (final u in utilisateursTest) {
      if (u.code == code) return u.username;
    }
    return null;
  }

  bool get _filtresAIActifs =>
      (selectedFournisseurAIFilter != null && selectedFournisseurAIFilter!.isNotEmpty) ||
      (selectedStatutAIFilter != null && selectedStatutAIFilter!.isNotEmpty) ||
      dateDebutAI != null ||
      dateFinAI != null ||
      dateDebutScanAI != null ||
      dateFinScanAI != null ||
      _searchControllerAI.text.isNotEmpty;

  // Vrai si [d] tombe dans [debut, fin] (bornes incluses, comparaison sur la
  // date seule). Utilisé pour les deux filtres de date (réception et scan).
  bool _dateDansPlage(DateTime? d, DateTime? debut, DateTime? fin) {
    if (debut == null && fin == null) return true;
    if (d == null) return false;
    final debutJour = debut != null ? DateTime(debut.year, debut.month, debut.day) : null;
    final finJour = fin != null ? DateTime(fin.year, fin.month, fin.day, 23, 59, 59) : null;
    if (debutJour != null && d.isBefore(debutJour)) return false;
    if (finJour != null && d.isAfter(finJour)) return false;
    return true;
  }

  void appliquerFiltreAI() {
    bonsReceptionFiltres = bonsReception.where((b) {
      final searchText = _searchControllerAI.text.toLowerCase();
      final searchOk = searchText.isEmpty || b.searchableText.contains(searchText);

      final fournisseurOk = selectedFournisseurAIFilter == null ||
          selectedFournisseurAIFilter!.isEmpty ||
          (b.fournisseur ?? '').toLowerCase() == selectedFournisseurAIFilter!.toLowerCase();

      final statutOk = selectedStatutAIFilter == null ||
          selectedStatutAIFilter!.isEmpty ||
          b.statut == selectedStatutAIFilter;

      final dateOk = _dateDansPlage(b.dateReception, dateDebutAI, dateFinAI);
      final dateScanOk = _dateDansPlage(b.dateTraitement, dateDebutScanAI, dateFinScanAI);

      return searchOk && fournisseurOk && statutOk && dateOk && dateScanOk;
    }).toList();
  }

  void supprimerFilterAI() {
    selectedFournisseurAIFilter = null;
    selectedStatutAIFilter = null;
    _searchControllerAI.clear();
    dateDebutAI = null;
    dateFinAI = null;
    _dateDebutCtrlAI.clear();
    _dateFinCtrlAI.clear();
    dateDebutScanAI = null;
    dateFinScanAI = null;
    _dateDebutScanCtrlAI.clear();
    _dateFinScanCtrlAI.clear();
  }

  Future<void> _pickDateDebutAI() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutAI ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateDebutAI = picked;
        _dateDebutCtrlAI.text = _formatDate(picked);
        appliquerFiltreAI();
      });
    }
  }

  Future<void> _pickDateFinAI() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinAI ?? dateDebutAI ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateFinAI = picked;
        if (dateDebutAI != null && picked.isBefore(dateDebutAI!)) {
          dateFinAI = dateDebutAI;
        }
        _dateFinCtrlAI.text = _formatDate(dateFinAI!);
        appliquerFiltreAI();
      });
    }
  }

  Future<void> _pickDateDebutScanAI() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutScanAI ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateDebutScanAI = picked;
        _dateDebutScanCtrlAI.text = _formatDate(picked);
        appliquerFiltreAI();
      });
    }
  }

  Future<void> _pickDateFinScanAI() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinScanAI ?? dateDebutScanAI ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateFinScanAI = picked;
        if (dateDebutScanAI != null && picked.isBefore(dateDebutScanAI!)) {
          dateFinScanAI = dateDebutScanAI;
        }
        _dateFinScanCtrlAI.text = _formatDate(dateFinScanAI!);
        appliquerFiltreAI();
      });
    }
  }

  void vider_selectionne() {
    smartscansSelectionnes.clear();
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }



  // ✅ Vrai si au moins un champ de filtre entrée/SmartScan est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresEntreeActifs =>
      (selectedFournisseurSCFilter != null && selectedFournisseurSCFilter!.isNotEmpty) ||
      montantMin != null ||
      montantMax != null ||
      (selectedEtatFilterE != null && selectedEtatFilterE!.isNotEmpty) ||
      dateDebutSC != null ||
      dateFinSC != null ||
      _searchControllerSC.text.isNotEmpty;

  void appliquerFiltreSmartScan() {
    smartscansFiltres = smartScansTest.where((p) {
      final searchText = _searchControllerSC.text.toLowerCase();
      final fournissemoveOk = selectedFournisseurSCFilter == null || selectedFournisseurSCFilter!.isEmpty || fournisseursTest.any((f) => f.code == p.fournisseurCode && f.nom == selectedFournisseurSCFilter);
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

    // ✅ Couleur de l'en-tête alignée sur la couleur du tab actif
    // (même logique binaire que l'indicateur du TabBar : TAB_SMART_SCAN vs le reste)
    final Color headerColor = currentTab == TAB_SMART_SCAN ? Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.smartScan,
      l10n.aiMode,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/cardwidget/scan_icon.png',
      'assets/icons/smart_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_smart_scan,
      nombre_ai,
    ];

    // ✅ Couleurs des tabs
    final tabColors = [
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
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: minWidth,
                  minHeight: minHeight,
                ),
                child: SizedBox(
                  width: adjustedWidth,
                  height: adjustedHeight,
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
                                            color: headerColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            children: [
                                              Text(
                                                l10n.entry,
                                                style: Appstyle.textXLB.copyWith(
                                                  color: headerColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(width: 15),
                                              Text(
                                                "(${tabNames[currentTab]})",
                                                style: Appstyle.textXLB.copyWith(
                                                  color: headerColor,
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
                                          const ConnectionStatusBar(),
                                          const SizedBox(width: 20),
                                          TimeDateWidget(
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
                                      color: currentTab == TAB_SMART_SCAN ? Appstyle.violet : Appstyle.indigo,
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
                                    tabs: List.generate(2, (index) {
                                      final isSelected = currentTab == index;
                                      return Tab(
                                        icon: index == 1
                                            ? AiSmartIcon(
                                                iconPath: tabIcons[index],
                                                width: 100,
                                                height: 40,
                                                active: isSelected,
                                              )
                                            : Container(
                                                width: 100,
                                                height: 40,
                                                child: Image.asset(
                                                  tabIcons[index],
                                                  width: 100,
                                                  height: 40,
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
                                // 1. CAS SMART SCAN (currentTab == TAB_SMART_SCAN)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_SMART_SCAN)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (smartscansSelectionnes.length == 1)
                                        AfficheurSmartScan(
                                          scan: smartscansSelectionnes.first,
                                          verse: verseParSmartScan[smartscansSelectionnes.first.code] ?? 0,
                                          reste: smartscansSelectionnes.first.montant -
                                              (verseParSmartScan[smartscansSelectionnes.first.code] ?? 0),
                                          nbrVersement: nbrVersementParSmartScan[smartscansSelectionnes.first.code] ?? 0,
                                          onDetails: () {
                                            final scan = smartscansSelectionnes.first;
                                            if (scan.nbrProduit == 1) {
                                              EntreeDetail(
                                                context,
                                                scan,
                                                produits: produitsTest,
                                                fournisseurs: fournisseursTest,
                                              );
                                            } else {
                                              SmartScanDetail(context, scan);
                                            }
                                          },
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurStockGlobalWidget(
                                            nombreBesoinList: compteursGlobaux.besoinLists,
                                            nombrePanniers: compteursGlobaux.panniers,
                                            nombreProduitsStock: compteursGlobaux.produitsEnStock,
                                            nombreRetours: compteursGlobaux.retours,
                                            nombreSmartScan: compteursGlobaux.smartScans,
                                            nombreSorties: compteursGlobaux.sorties,
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
                                                  showBadge: _filtresEntreeActifs,
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
                                                  onPressed: _exportSmartScanToExcel,
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extractPdf,
                                                  textColor: Colors.red,
                                                  iconColor: Colors.red,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.picture_as_pdf,
                                                  onPressed: () async {
                                                    await _exportSmartScanToExcel(enPdf: true);
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
                                                      final scan = smartscansSelectionnes.first;
                                                      if (scan.nbrProduit == 1) {
                                                        EntreeDetail(
                                                          context,
                                                          scan,
                                                          produits: produitsTest,
                                                          fournisseurs: fournisseursTest,
                                                        );
                                                      } else {
                                                        SmartScanDetail(context, scan);
                                                      }
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
                                                      final scan = smartscansSelectionnes.first;
                                                      if (scan.nbrProduit == 1) {
                                                        await EntreeModif(context, scan);
                                                      } else {
                                                        await SmartScanModif(context, scan);
                                                      }
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
                                                    await SmartScanDialog.open(context);
                                                    await loadAllData();
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.entryrapide,
                                                  color: Appstyle.jaune,
                                                  onPressed: () async {
                                                    await EntreeNouveau(
                                                      context,
                                                      onSuccess: () async {
                                                        await loadAllData();
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
                                            child: filtreSC(setState, adjustedWidth * 1 / 3, l10n, translator, periodesRapides),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauSmartScanAdvanced(
                                          key: ValueKey(smartscansFiltres),
                                          scans: smartscansFiltres,
                                          verseParSmartScan: verseParSmartScan,
                                          nbrVersementParSmartScan: nbrVersementParSmartScan,
                                          fournisseurs: fournisseursTest,
                                          utilisateurs: utilisateursTest,
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
                                // 2. CAS AI (currentTab == TAB_AI)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_AI)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: MainButton(
                                                text: l10n.attachBonFromDisk,
                                                color: Appstyle.crevete,
                                                icon: Icons.attach_file,
                                                onPressed: _attachBonFromDisk,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        if (bonsReception.isNotEmpty)
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Row(
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  showBadge: _filtresAIActifs,
                                                  icon: filtresActifsAI ? Icons.visibility_off : Icons.visibility,
                                                  iconColor: Appstyle.violet,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifsAI = !filtresActifsAI;
                                                      if (!filtresActifsAI) {
                                                        supprimerFilterAI();
                                                        appliquerFiltreAI();
                                                      }
                                                    });
                                                  },
                                                ),
                                                if (filtresActifsAI) SizedBox(width: paddingH / 4),
                                                if (filtresActifsAI)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilterAI();
                                                        appliquerFiltreAI();
                                                      });
                                                    },
                                                  ),
                                              ],
                                            ),
                                          ),
                                        if (filtresActifsAI)
                                          Align(
                                            alignment: Alignment.topLeft,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                              child: filtreAI(setState, adjustedWidth * 1 / 3, l10n),
                                            ),
                                          ),
                                        if (bonsReception.isNotEmpty) const SizedBox(height: 8),
                                        if (bonsReception.isEmpty)
                                          Center(
                                            child: Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: Image.asset(
                                                    "assets/icons/smart_icon.png",
                                                    width: 100,
                                                    height: 100,
                                                    color: Appstyle.violet,
                                                  ),
                                                ),
                                                Text(
                                                  l10n.aiModeDescription,
                                                  style: Appstyle.textXLB.copyWith(
                                                    color: Appstyle.violet,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          )
                                        else if (bonsReceptionFiltres.isEmpty)
                                          Center(
                                            child: Padding(
                                              padding: const EdgeInsets.all(32.0),
                                              child: Text(
                                                l10n.noResultsFound,
                                                style: Appstyle.textSB.copyWith(color: Appstyle.gris),
                                              ),
                                            ),
                                          )
                                        else
                                          Wrap(
                                            spacing: 16,
                                            runSpacing: 16,
                                            children: bonsReceptionFiltres.map((bon) {
                                              return BonReceptionCard(
                                                key: ValueKey(bon.id),
                                                bon: bon,
                                                traiteParNom: _nomUtilisateur(bon.traiteParCode),
                                                onTap: () => _openWizardFor(bon),
                                                // ✅ Une photo déjà scannée est liée à un Smart Scan :
                                                // la supprimer ici casserait ce lien, donc seules les
                                                // photos non traitées restent supprimables.
                                                onDelete: bon.estTraite ? null : () => _deleteBon(bon),
                                              );
                                            }).toList(),
                                          ),
                                      ],
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
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.from,
                child: TextDate(
                  hint: l10n.startDate,
                  controller: _dateDebutCtrlSC,
                  onTap: _pickDateDebutSC,
                ),
              ),
              ChampAvecLabel(
                label: l10n.to,
                child: TextDate(
                  hint: l10n.endDate,
                  enabled: dateDebutSC != null,
                  controller: _dateFinCtrlSC,
                  onTap: _pickDateFinSC,
                ),
              ),
              ChampPeriodeRapide(
                l10n: l10n,
                value: periodeRapide,
                onSelected: (v) {
                  setState(() {
                    periodeRapide = v;
                    _appliquerPeriodeRapideSC(v, l10n);
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 15),
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
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
            ],
          ),
        ],
      ),
    );
  }

  // Libellé affiché <-> valeur brute stockée en base pour le statut d'un bon.
  String _statutAIDisplay(String statut, AppLocalizations l10n) {
    switch (statut) {
      case 'traite':
        return l10n.receptionStatutTraite;
      case 'erreur':
        return l10n.receptionStatutErreur;
      default:
        return l10n.receptionStatutRecu;
    }
  }

  String _statutAIFromDisplay(String display, AppLocalizations l10n) {
    if (display == l10n.receptionStatutTraite) return 'traite';
    if (display == l10n.receptionStatutErreur) return 'erreur';
    return 'recu';
  }

  Widget filtreAI(
      void Function(VoidCallback fn) setState,
      double width,
      AppLocalizations l10n,
      ) {
    final fournisseurOptionsAI = bonsReception
        .map((b) => b.fournisseur)
        .whereType<String>()
        .where((f) => f.trim().isNotEmpty)
        .toSet()
        .toList();

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
                    value: selectedFournisseurAIFilter,
                    items: fournisseurOptionsAI,
                    onChanged: (v) {
                      setState(() {
                        selectedFournisseurAIFilter = v;
                        appliquerFiltreAI();
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
                    value: selectedStatutAIFilter == null
                        ? null
                        : _statutAIDisplay(selectedStatutAIFilter!, l10n),
                    items: [
                      l10n.receptionStatutRecu,
                      l10n.receptionStatutTraite,
                      l10n.receptionStatutErreur,
                    ],
                    onChanged: (v) {
                      setState(() {
                        selectedStatutAIFilter = v == null ? null : _statutAIFromDisplay(v, l10n);
                        appliquerFiltreAI();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerAI,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltreAI();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(l10n.receptionDateRangeLabel, style: Appstyle.textXSB.copyWith(color: Appstyle.gris)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrlAI,
                    onTap: _pickDateDebutAI,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebutAI != null,
                    controller: _dateFinCtrlAI,
                    onTap: _pickDateFinAI,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(l10n.scanDateRangeLabel, style: Appstyle.textXSB.copyWith(color: Appstyle.gris)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutScanCtrlAI,
                    onTap: _pickDateDebutScanAI,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebutScanAI != null,
                    controller: _dateFinScanCtrlAI,
                    onTap: _pickDateFinScanAI,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

}
