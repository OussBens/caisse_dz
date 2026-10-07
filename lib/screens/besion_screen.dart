import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';

import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'dart:io';
import 'package:caisse_dz/Services/export_spinner.dart';

import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/Services/BesionListDetail.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/BesionList.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/remise.dart';

import 'package:caisse_dz/core/dialog/besionlist/besoinlist_nouveau.dart';
import 'package:caisse_dz/core/dialog/besionlist/besoinlist_actif.dart';
import 'package:caisse_dz/core/dialog/besionlist/besoinlist_modif.dart';
import 'package:caisse_dz/core/dialog/mouvement/mouvement_detail.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';
import 'package:caisse_dz/core/dialog/retour/retour_detail.dart';

import 'package:caisse_dz/core/dialog/retour/retour_nouveau.dart';
import 'package:caisse_dz/core/dialog/retour/retour_actif.dart';
import 'package:caisse_dz/core/dialog/retour/retour_modif.dart';
import 'package:caisse_dz/core/dialog/smart_screen/smart_screen_detail.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_detail.dart';

import 'package:caisse_dz/core/dialog/sortie/sortie_nouveau.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_actif.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_modif.dart';

import 'package:caisse_dz/core/dialog/stock/distribution.dart';
import 'package:caisse_dz/core/dialog/stock/stock_detail.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/tableau/smart_scan/tableau_smart_scan.dart';
import 'package:caisse_dz/core/tableau/besoinlist/besoinlist_tableau.dart';
import 'package:caisse_dz/core/tableau/mouvement/tableau_mouvement.dart';
import 'package:caisse_dz/core/tableau/pannier/tableau_pannier.dart';
import 'package:caisse_dz/core/tableau/Produit/tableau_produit.dart';
import 'package:caisse_dz/core/tableau/retour/tableau_retour.dart';
import 'package:caisse_dz/core/tableau/sortie/tableau_sortie.dart';
import 'package:caisse_dz/core/tableau/stock/tableau_stock.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';

import 'package:caisse_dz/core/widget/account.dart';

import 'package:caisse_dz/core/widget/afficheur/afficheur_produit_stock.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_besoin_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_besoin_list.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_smart_scan.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_mouvement.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pannier.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit_expire.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_retour.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_sortie.dart';

import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/radio_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';

import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';

import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/sortie.dart';

import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dialog/besionlist/besoinlist_detail.dart';
import '../core/dialog/information_dialog.dart';
import '../core/dialog/smart_screen/smart_screen_actif.dart';
import '../core/dialog/smart_screen/smart_screen_modif.dart';
import '../core/dialog/smart_screen/smart_screen_nouveau.dart';
import '../core/widget/section_decoration_filtre.dart';

String? selectedEtatFilterB;
String? selectedEtatFilterRp;

String? selectedFournisseurFilterBesoinList;
String? selectedCategorieFilterBesion;
String? selectedSousCategorieFilterBesion;

// Valeurs sélectionnées dans le filtre
String? selectedCategorieFilter;
String? selectedSousCategorieFilter;

String? selectedFournisseurFilter;

List<Produit>           besoinsTest           = [];
// Quantité par produit calculée depuis le journal des mouvements — voir
// produit_screen.dart pour le même mécanisme. Remplace Produit.quantite.
Map<String, double>     quantitesTest         = {};
List<SousCategorie>     sousCategoriesTest    = [];
List<Fournisseur>       fournisseursTest      = [];
List<Categorie>         categoriesTest        = [];
List<Remise>            remisesTest           = [];
List<BesoinList>        BesoinListsTest       = [];
List<BesoinListDetail>  besoinListDetailsTest = [];
List<Utilisateur>       utilisateursTest      = [];

List<Produit>     besionsSelectionnes     = [];
List<BesoinList>  besionListsSelectionnes = [];
List<Produit>     expiresSelectionnes     = [];

class BesionScreen extends StatefulWidget {
  const BesionScreen({super.key});
  @override
  State<BesionScreen> createState() => _BesionScreenState();
}

class _BesionScreenState extends State<BesionScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  double seuilMinimum = 0;
  double seuilMaximum = 0;
  // Garde anti-double-clic pour l'export Excel (voir client_screen.dart pour
  // le détail du bug évité).
  bool _exportEnCours = false;

  // ✅ Constantes pour les index des tabs
  static const int TAB_BESOIN_LIST = 0;
  static const int TAB_OUT_OF_STOCK = 1;
  static const int TAB_EXPIRED_PRODUCT = 2;

  // Period keys for translation lookup

  List<String> sousCategorieFilterOptions = [];
  List<String> FournisseurFilterOptions   = [];
  List<String> categorieFilterOptions     = [];

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  String nombre_besion          = "15";
  String nombre_produit_rupture = "30";
  String nombre_produit_expire  = "0";

  // Cards globales (AfficheurBesoinGlobalWidget) : éléments actifs uniquement.
  int nombreProduitsActifs   = 0;
  int nombreBesoinListActifs = 0;
  int nombreRuptureActifs    = 0;
  int nombreExpiresActifs    = 0;

  Future<void> loadAllData() async {
    final test = await ProduitServices.getAllProduits();
    final besoinListDetails = await BesoinListDetailServices.getAllBesoinListDetail();
    final sousCategories    = await SousCategoriesServices.getAllSousCategorie();
    final fournisseurs      = await FournisseurServices.getAllFournisseurs();
    final besoinLists       = await BesoinListServices.getAllBesoinList();
    final categories        = await CategorieServices.getAllCategorie();
    final remises           = await RemiseServices.getAllRemise();
    final param              = await ParamServices.getParam();
    final utilisateurs      = await UtilisateurServices.getAllUtilisateurs();
    quantitesTest = (await MouvementsServices.totauxParProduit()).quantites;
    besoinsTest = test.where((e) => (quantitesTest[e.code] ?? 0) <= param.Minimum).toList();

    // Produits expirés : date d'expiration renseignée et strictement antérieure
    // à aujourd'hui (un produit qui expire aujourd'hui n'est pas encore expiré).
    final today = DateTime.now();
    final debutAujourdhui = DateTime(today.year, today.month, today.day);
    final expires = test
        .where((e) => e.dateEmpreint != null && e.dateEmpreint!.isBefore(debutAujourdhui))
        .toList();

    setState(() {
      besoinListDetailsTest = besoinListDetails;
      sousCategoriesTest    = sousCategories;
      fournisseursTest      = fournisseurs;
      BesoinListsTest       = besoinLists;
      categoriesTest        = categories;
      remisesTest           = remises;
      utilisateursTest      = utilisateurs;
      seuilMinimum          = param.Minimum;
      seuilMaximum          = param.Maximum;
      besionFiltres     = besoinsTest;
      besionlistFiltres = BesoinListsTest;
      expiresTest       = expires;
      expireFiltres     = expires;

      sousCategorieFilterOptions = sousCategoriesTest.map  ((sc) => sc.nom). toSet().toList();
      FournisseurFilterOptions   = fournisseursTest.map    ((sc) => sc.nom). toSet().toList();
      categorieFilterOptions     = categoriesTest.map      ((c)  => c.nom).  toSet().toList();

      nombre_besion = BesoinListsTest.length.toString();
      nombre_produit_rupture = besoinsTest.length.toString();
      nombre_produit_expire = expiresTest.length.toString();

      nombreProduitsActifs   = test.where((p) => p.etat).length;
      nombreBesoinListActifs = besoinLists.where((b) => b.etat).length;
      nombreRuptureActifs    = besoinsTest.where((p) => p.etat).length;
      nombreExpiresActifs    = expires.where((p) => p.etat).length;

      besionsSelectionnes.clear();
      besionListsSelectionnes.clear();
      expiresSelectionnes.clear();
    });
  }

  // Excel Export Methods (adaptées avec _tabController.index)
  Future<void> _exportCurrentModuleToExcel({bool enPdf = false}) async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      // ✅ Utilisation de _tabController.index
      final currentTab = _tabController.index;

      File? excelFile;
      String moduleName = '';

      if (currentTab == TAB_BESOIN_LIST) {
        // Besoin Lists
        final listsToExport = filtresActifs ? besionlistFiltres : BesoinListsTest;

        if (listsToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.besoinList,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.besoinList;
        excelFile = await ExcelGenerator.generateBesoinListsExcel(
          besoinLists: listsToExport,
          l10n: l10n,
          translator: translator,
        );
      } else if (currentTab == TAB_OUT_OF_STOCK) {
        // Out of Stock Products (Produits)
        final produitsToExport = filtresActifs ? besionFiltres : besoinsTest;

        if (produitsToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.outOfStockProducts,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.outOfStockProducts;
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: produitsToExport,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: seuilMinimum,
          seuilMax: seuilMaximum,
        );
      } else {
        // Expired Products (Produits expirés)
        final produitsToExport = filtresActifs ? expireFiltres : expiresTest;

        if (produitsToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.expiredProducts,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.expiredProducts;
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: produitsToExport,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: seuilMinimum,
          seuilMax: seuilMaximum,
        );
      }

      fermerSpinner();

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      // Extract PDF : même fichier que l'export Excel, mis en page en PDF.
      if (enPdf) {
        fermerSpinner();
        await ouvrirApercuPdfDepuisExcel(context, fichier: excelFile, titre: moduleName);
        return;
      }

      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_BESOIN_LIST ? 'BesoinLists' : 'Produits';
      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No data found in Excel file'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: moduleName,
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      fermerSpinner();

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  Future<void> _exportSelectedToExcel() async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);

    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      // ✅ Utilisation de _tabController.index
      final currentTab = _tabController.index;

      File? excelFile;
      String moduleName = '';

      if (currentTab == TAB_BESOIN_LIST) {
        // Besoin Lists
        if (besionListsSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.besoinList,
            message: l10n.noListSelected ?? "No list selected",
          );
          return;
        }

        moduleName = l10n.besoinList;
        excelFile = await ExcelGenerator.generateBesoinListsExcel(
          besoinLists: besionListsSelectionnes,
          l10n: l10n,
          translator: translator,
        );
      } else if (currentTab == TAB_OUT_OF_STOCK) {
        // Out of Stock Products
        if (besionsSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.outOfStockProducts,
            message: l10n.noProductSelected,
          );
          return;
        }

        moduleName = l10n.outOfStockProducts;
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: besionsSelectionnes,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: seuilMinimum,
          seuilMax: seuilMaximum,
        );
      } else {
        // Expired Products
        if (expiresSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.expiredProducts,
            message: l10n.noProductSelected,
          );
          return;
        }

        moduleName = l10n.expiredProducts;
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: expiresSelectionnes,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: seuilMinimum,
          seuilMax: seuilMaximum,
        );
      }

      fermerSpinner();

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_BESOIN_LIST ? 'BesoinLists' : 'Produits';
      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: "$moduleName (${l10n.selected})",
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      fermerSpinner();

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  DateTime? dateDebutBesoinList;
  DateTime? dateFinBesoinList;
  final TextEditingController _dateDebutCtrlBesoinList  = TextEditingController();
  final TextEditingController _dateFinCtrlBesoinList    = TextEditingController();

  double? quantiteMinBesion;
  double? quantiteMaxBesion;

  bool  filtresActifs = false;
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

  final TextEditingController _searchControllerBesion     = TextEditingController();
  final TextEditingController _searchControllerBesionList = TextEditingController();

  List<BesoinList>  besionlistFiltres = [];
  List<Produit>     besionFiltres     = [];
  List<Produit>     expiresTest       = [];
  List<Produit>     expireFiltres     = [];

  String? selectedCategorieFilterExpire;
  String? selectedSousCategorieFilterExpire;
  String? selectedEtatFilterExpire;
  double? quantiteMinExpire;
  double? quantiteMaxExpire;
  final TextEditingController _searchControllerExpire = TextEditingController();

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

  String _formatDate(DateTime d) {
    return  "${d.day  .toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }


  void appliquerFiltreBesion() {
    besionFiltres = besoinsTest.where((p) {
      final searchText  = _searchControllerBesion.text.toLowerCase();
      final nomCategorieB = categoriesTest.where((c) => c.id == p.categorieId).firstOrNull?.nom ?? '';
      final nomSousCategorieB = sousCategoriesTest.where((sc) => sc.id == p.sousCategorieId).firstOrNull?.nom ?? '';
      final catOk       = selectedCategorieFilterBesion     == null || selectedCategorieFilterBesion!.isEmpty     || nomCategorieB      == selectedCategorieFilterBesion;
      final sousCatOk   = selectedSousCategorieFilterBesion == null || selectedSousCategorieFilterBesion!.isEmpty || nomSousCategorieB  == selectedSousCategorieFilterBesion;
      final searchOk = searchText.isEmpty ||
          '${p.searchableText} $nomCategorieB $nomSousCategorieB'.toLowerCase().contains(searchText);

      final quantiteBesionP = quantitesTest[p.code] ?? 0;
      final quantiteOk = (quantiteMinBesion == null || quantiteBesionP >= quantiteMinBesion!) &&
          (quantiteMaxBesion == null || quantiteBesionP <= quantiteMaxBesion!);

      final etatOk = selectedEtatFilterB == null ||
          selectedEtatFilterB == "" ||
          (selectedEtatFilterB == "Actif" && p.etat) ||
          (selectedEtatFilterB == "Inactif" && !p.etat);

      return catOk && sousCatOk && quantiteOk && etatOk && searchOk;
    }).toList();

    if ((selectedCategorieFilterBesion      == null || selectedCategorieFilterBesion!.isEmpty) &&
        (selectedSousCategorieFilterBesion  == null || selectedSousCategorieFilterBesion!.isEmpty) &&
        (selectedEtatFilterB == null || selectedEtatFilterB!.isEmpty) &&
        quantiteMinBesion == null &&
        quantiteMaxBesion == null &&
        _searchControllerBesion.text.isEmpty) {
      besionFiltres = besoinsTest;
    }
  }

  void appliquerFiltreBesoinList() {
    besionlistFiltres = BesoinListsTest.where((p) {
      final searchText = _searchControllerBesionList.text.toLowerCase();
      final fournissemoveOk = selectedFournisseurFilterBesoinList == null || selectedFournisseurFilterBesoinList!.isEmpty || fournisseursTest.any((f) => f.code == p.fournisseurCode && f.nom == selectedFournisseurFilterBesoinList);
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final etatOk = selectedEtatFilterRp == null ||
          selectedEtatFilterRp == "" ||
          (selectedEtatFilterRp == "Actif" && p.etat) ||
          (selectedEtatFilterRp == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebutBesoinList == null && dateFinBesoinList == null) return true;

        final d = p.date;

        final debut = dateDebutBesoinList != null
            ? DateTime(dateDebutBesoinList!.year, dateDebutBesoinList!.month, dateDebutBesoinList!.day)
            : null;

        final fin = dateFinBesoinList != null
            ? DateTime(dateFinBesoinList!.year, dateFinBesoinList!.month, dateFinBesoinList!.day, 23, 59, 59)
            : null;

        if (debut != null && d.isBefore(debut)) return false;
        if (fin != null && d.isAfter(fin)) return false;

        return true;
      }();

      return fournissemoveOk && etatOk && searchOk && dateOk;
    }).toList();

    if ((selectedFournisseurFilterBesoinList == null || selectedFournisseurFilterBesoinList!.isEmpty) &&
        (selectedEtatFilterRp == null || selectedEtatFilterRp!.isEmpty) &&
        dateDebutBesoinList == null &&
        dateFinBesoinList   == null &&
        _searchControllerBesionList.text.isEmpty) {
      besionlistFiltres = BesoinListsTest;
    }
  }

  void _appliquerPeriodeRapideBesoinList(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebutBesoinList = DateTime(now.year, now.month, now.day);
        dateFinBesoinList = dateDebutBesoinList;
        break;
      case "yesterday":
        dateDebutBesoinList = DateTime(now.year, now.month, now.day - 1);
        dateFinBesoinList = dateDebutBesoinList;
        break;
      case "week":
        dateDebutBesoinList = now.subtract(Duration(days: now.weekday - 1));
        dateFinBesoinList = dateDebutBesoinList!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebutBesoinList = now.subtract(Duration(days: now.weekday + 6));
        dateFinBesoinList = dateDebutBesoinList!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebutBesoinList = DateTime(now.year, now.month, 1);
        dateFinBesoinList = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebutBesoinList = DateTime(now.year, now.month - 1, 1);
        dateFinBesoinList = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebutBesoinList = now.subtract(const Duration(days: 6));
        dateFinBesoinList = now;
        break;
      case "last30days":
        dateDebutBesoinList = now.subtract(const Duration(days: 29));
        dateFinBesoinList = now;
        break;
      case "year":
        dateDebutBesoinList = DateTime(now.year, 1, 1);
        dateFinBesoinList = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebutBesoinList = DateTime(now.year - 1, 1, 1);
        dateFinBesoinList = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlBesoinList.text = _formatDate(dateDebutBesoinList!);
    _dateFinCtrlBesoinList.text = _formatDate(dateFinBesoinList!);

    appliquerFiltreBesoinList();
  }

  void supprimerFilterBesion() {
    selectedCategorieFilterBesion = null;
    selectedSousCategorieFilterBesion = null;
    quantiteMaxBesion = null;
    quantiteMinBesion = null;
    selectedEtatFilterB = null;
    _searchControllerBesion.clear();
  }

  // ✅ Vrai si au moins un champ de filtre "produits en rupture" est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresBesoinActifs =>
      selectedCategorieFilterBesion != null ||
      selectedSousCategorieFilterBesion != null ||
      quantiteMinBesion != null ||
      quantiteMaxBesion != null ||
      selectedEtatFilterB != null ||
      _searchControllerBesion.text.isNotEmpty;

  void appliquerFiltreExpire() {
    expireFiltres = expiresTest.where((p) {
      final searchText = _searchControllerExpire.text.toLowerCase();
      final nomCategorieE = categoriesTest.where((c) => c.id == p.categorieId).firstOrNull?.nom ?? '';
      final nomSousCategorieE = sousCategoriesTest.where((sc) => sc.id == p.sousCategorieId).firstOrNull?.nom ?? '';
      final catOk       = selectedCategorieFilterExpire     == null || selectedCategorieFilterExpire!.isEmpty     || nomCategorieE      == selectedCategorieFilterExpire;
      final sousCatOk   = selectedSousCategorieFilterExpire == null || selectedSousCategorieFilterExpire!.isEmpty || nomSousCategorieE  == selectedSousCategorieFilterExpire;
      final searchOk = searchText.isEmpty ||
          '${p.searchableText} $nomCategorieE $nomSousCategorieE'.toLowerCase().contains(searchText);

      final quantiteExpireP = quantitesTest[p.code] ?? 0;
      final quantiteOk = (quantiteMinExpire == null || quantiteExpireP >= quantiteMinExpire!) &&
          (quantiteMaxExpire == null || quantiteExpireP <= quantiteMaxExpire!);

      final etatOk = selectedEtatFilterExpire == null ||
          selectedEtatFilterExpire == "" ||
          (selectedEtatFilterExpire == "Actif" && p.etat) ||
          (selectedEtatFilterExpire == "Inactif" && !p.etat);

      return catOk && sousCatOk && quantiteOk && etatOk && searchOk;
    }).toList();

    if ((selectedCategorieFilterExpire      == null || selectedCategorieFilterExpire!.isEmpty) &&
        (selectedSousCategorieFilterExpire  == null || selectedSousCategorieFilterExpire!.isEmpty) &&
        (selectedEtatFilterExpire == null || selectedEtatFilterExpire!.isEmpty) &&
        quantiteMinExpire == null &&
        quantiteMaxExpire == null &&
        _searchControllerExpire.text.isEmpty) {
      expireFiltres = expiresTest;
    }
  }

  void supprimerFilterExpire() {
    selectedCategorieFilterExpire = null;
    selectedSousCategorieFilterExpire = null;
    quantiteMaxExpire = null;
    quantiteMinExpire = null;
    selectedEtatFilterExpire = null;
    _searchControllerExpire.clear();
  }

  // ✅ Vrai si au moins un champ de filtre "produits expirés" est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresExpirationActifs =>
      selectedCategorieFilterExpire != null ||
      selectedSousCategorieFilterExpire != null ||
      quantiteMinExpire != null ||
      quantiteMaxExpire != null ||
      selectedEtatFilterExpire != null ||
      _searchControllerExpire.text.isNotEmpty;

  void supprimerFilterBesoinList() {
    selectedFournisseurFilterBesoinList = null;
    selectedEtatFilterRp = null;
    _searchControllerBesionList.clear();
    dateDebutBesoinList = null;
    dateFinBesoinList = null;
    periodeRapide = null;
    _dateDebutCtrlBesoinList.clear();
    _dateFinCtrlBesoinList.clear();
  }

  // ✅ Vrai si au moins un champ de filtre "listes de besoin" est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresBesoinListActifs =>
      selectedFournisseurFilterBesoinList != null ||
      selectedEtatFilterRp != null ||
      dateDebutBesoinList != null ||
      dateFinBesoinList != null ||
      periodeRapide != null ||
      _searchControllerBesionList.text.isNotEmpty;

  void vider_selectionne() {
    besionListsSelectionnes.clear();
    besionsSelectionnes.clear();
    expiresSelectionnes.clear();
  }

  Future<void> _pickDateDebutBesoinList() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutBesoinList  ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebutBesoinList  = picked;
        _dateDebutCtrlBesoinList.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreBesoinList();
      });
    }
  }

  Future<void> _pickDateFinBesoinList() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinBesoinList ?? dateDebutBesoinList ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinBesoinList  = picked;

        if (dateDebutBesoinList  != null && picked.isBefore(dateDebutBesoinList !)) {
          dateFinBesoinList = dateDebutBesoinList;
        }

        _dateFinCtrlBesoinList.text = _formatDate(dateFinBesoinList !);
        periodeRapide = null;
        appliquerFiltreBesoinList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    // Check if RTL (Arabic)
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Couleur de l'en-tête alignée sur la couleur du tab actif
    final Color headerColor = currentTab == TAB_BESOIN_LIST
        ? Appstyle.violet
        : currentTab == TAB_OUT_OF_STOCK
            ? Appstyle.indigo
            : Appstyle.lavande;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.besoinList,
      l10n.outOfStockProducts,
      l10n.expiredProducts,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/cardwidget/liste_icon.png',
      'assets/icons/cardwidget/besion_icon.png',
      'assets/icons/agenda_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_besion,
      nombre_produit_rupture,
      nombre_produit_expire,
    ];

    // ✅ Couleurs des tabs
    final tabColors = [
      Colors.orange.shade500,
      Appstyle.TnoirC,
      Colors.redAccent,
    ];

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: Directionality(
        textDirection: textDirection,
        child: LayoutBuilder(
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
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                /// HEADER
                                HeaderModule(
                                  gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                  child: Row(
                                    textDirection: textDirection,
                                    children: [
                                      Row(
                                        textDirection: textDirection,
                                        children: [
                                          Image.asset(
                                            "assets/icons/cardwidget/besion_icon.png",
                                            width: 40,
                                            color: headerColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              Text(
                                                l10n.besoin,
                                                style: Appstyle.textXLB.copyWith(
                                                  color       : headerColor,
                                                  fontWeight  : FontWeight.bold,
                                                ),
                                              ),
                                              SizedBox(width: 15),
                                              Text(
                                                "(${tabNames[currentTab]})",
                                                style: Appstyle.textXLB.copyWith(
                                                  color       : headerColor,
                                                  fontWeight  : FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          )
                                        ],
                                      ),
                                      const Spacer(),
                                      Row(
                                        textDirection: textDirection,
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

                                SizedBox(height: paddingV/2),

                                /// ✅ TAB BAR (remplace les CardWidget) - Style FournisseurScreen
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
                                      color: headerColor,
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

                                SizedBox(height: paddingV/2),

                                // ═══════════════════════════════════════════════════════════════════════════════
                                // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                // ═══════════════════════════════════════════════════════════════════════════════

                                // ──────────────────────────────────────────────────────────────
                                // 1. CAS BESOIN LIST (currentTab == TAB_BESOIN_LIST)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_BESOIN_LIST)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (besionListsSelectionnes.length == 1)
                                        AfficheurBesoinList(
                                            list: besionListsSelectionnes.first,
                                            onDetails: () {
                                              BesoinListDetailDialog(context, besionListsSelectionnes.first);
                                            }
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurBesoinGlobalWidget(
                                            nombreProduits: nombreProduitsActifs,
                                            nombreBesoinList: nombreBesoinListActifs,
                                            nombreProduitsRupture: nombreRuptureActifs,
                                            nombreProduitsExpires: nombreExpiresActifs,
                                          ),
                                        ),

                                      if (besionListsSelectionnes.length == 1)
                                        SizedBox(height: paddingV/2),

                                      // Filtres & Actions - Style FournisseurScreen
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                  iconColor: Appstyle.violet,
                                                  showBadge: _filtresBesoinListActifs,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilterBesoinList();
                                                        appliquerFiltreBesoinList();
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: paddingH/4),
                                                if (filtresActifs)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilterBesoinList();
                                                        appliquerFiltreBesoinList();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH/4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor: Colors.green,
                                                  iconColor: Colors.green,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.download,
                                                  loading: _exportEnCours,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel();
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extractPdf,
                                                  textColor: Colors.red,
                                                  iconColor: Colors.red,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.picture_as_pdf,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel(enPdf: true);
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                  color: Colors.orange,
                                                  onPressed: () async {
                                                    await _exportSelectedToExcel();
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              textDirection: textDirection,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (besionListsSelectionnes.length == 1) {
                                                      BesoinListDetailDialog(context, besionListsSelectionnes.first);
                                                    } else if (besionListsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.besoinList,
                                                        message: l10n.noListSelected ?? "Aucune liste sélectionnée !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.besoinList,
                                                        message: l10n.selectSingleListForDetail ?? "Veuillez sélectionner une seule liste pour afficher le détail !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/supprimer_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed: () async {
                                                    if (besionListsSelectionnes.isNotEmpty) {
                                                      await BesoinListActifDialog(
                                                        context,
                                                        besionListsSelectionnes,
                                                      );
                                                      await loadAllData();
                                                    } else if (besionListsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.besoinList,
                                                        message: l10n.noListSelected ?? "Aucune liste sélectionnée !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async {
                                                    if (besionListsSelectionnes.length == 1) {
                                                      await BesoinListModifier(
                                                        context,
                                                        besionListsSelectionnes.first,
                                                      );
                                                      await loadAllData();
                                                    } else if (besionListsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.besoinList,
                                                        message: l10n.noListSelected ?? "Aucune liste sélectionnée !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.besoinList,
                                                        message: l10n.selectSingleListToModify ?? "Veuillez sélectionner une seule liste pour modifier !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await BesoinListNouveau(context, fournisseursTest);
                                                    await loadAllData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!filtresActifs)
                                        SizedBox(height: paddingV/2),

                                      // Filtres
                                      if (filtresActifs)
                                        Align(
                                          alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: paddingV/2),
                                            child: filtreBesoinList(setState, adjustedWidth*1/3, l10n, translator, isRTL),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauBesoinListAdvanced(
                                          key: ValueKey(besionlistFiltres),
                                          besoins: besionlistFiltres,
                                          fournisseurs: fournisseursTest,
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              besionListsSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 2. CAS OUT OF STOCK (currentTab == TAB_OUT_OF_STOCK)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_OUT_OF_STOCK)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (besionsSelectionnes.length == 1)
                                        AfficheurProduit(
                                            produit: besionsSelectionnes.first,
                                            onDetails: () {
                                              ProduitDetail(context, besionsSelectionnes.first);
                                            }
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurBesoinGlobalWidget(
                                            nombreProduits: nombreProduitsActifs,
                                            nombreBesoinList: nombreBesoinListActifs,
                                            nombreProduitsRupture: nombreRuptureActifs,
                                            nombreProduitsExpires: nombreExpiresActifs,
                                          ),
                                        ),

                                      if (besionsSelectionnes.length == 1)
                                        SizedBox(height: paddingV/2),

                                      // Filtres & Actions - Style FournisseurScreen
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                  iconColor: Appstyle.violet,
                                                  showBadge: _filtresBesoinActifs,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilterBesion();
                                                        appliquerFiltreBesion();
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: paddingH/4),
                                                if (filtresActifs)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilterBesion();
                                                        appliquerFiltreBesion();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH/4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor: Colors.green,
                                                  iconColor: Colors.green,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.download,
                                                  loading: _exportEnCours,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel();
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extractPdf,
                                                  textColor: Colors.red,
                                                  iconColor: Colors.red,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.picture_as_pdf,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel(enPdf: true);
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                  color: Colors.orange,
                                                  onPressed: () async {
                                                    await _exportSelectedToExcel();
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              textDirection: textDirection,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (besionsSelectionnes.length == 1) {
                                                      ProduitDetail(context, besionsSelectionnes.first);
                                                    } else if (besionsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.outOfStockProducts,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.outOfStockProducts,
                                                        message: l10n.selectSingleProductForDetail,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!filtresActifs)
                                        SizedBox(height: paddingV/2),

                                      // Filtres
                                      if (filtresActifs)
                                        Align(
                                          alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: paddingV/2),
                                            child: filtreBesion(setState, adjustedWidth*1/3, l10n, translator, isRTL),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauProduitAdvanced(
                                          // Clé stable : cf. commentaire dans produit_screen.dart.
                                          key: const ValueKey('besion-produit-table'),
                                          col: false,
                                          produits: besionFiltres,
                                          categories: categoriesTest,
                                          sousCategories: sousCategoriesTest,
                                          remises: remisesTest,
                                          fournisseurs: fournisseursTest,
                                          seuilMinimum: seuilMinimum,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              besionsSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 3. CAS PRODUITS EXPIRÉS (currentTab == TAB_EXPIRED_PRODUCT)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_EXPIRED_PRODUCT)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (expiresSelectionnes.length == 1)
                                        AfficheurProduitExpire(
                                            produit: expiresSelectionnes.first,
                                            onDetails: () {
                                              ProduitDetail(context, expiresSelectionnes.first);
                                            }
                                        )
                                      else
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 16.0),
                                          child: AfficheurBesoinGlobalWidget(
                                            nombreProduits: nombreProduitsActifs,
                                            nombreBesoinList: nombreBesoinListActifs,
                                            nombreProduitsRupture: nombreRuptureActifs,
                                            nombreProduitsExpires: nombreExpiresActifs,
                                          ),
                                        ),

                                      if (expiresSelectionnes.length == 1)
                                        SizedBox(height: paddingV/2),

                                      // Filtres & Actions - Style FournisseurScreen
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                MainButton(
                                                  text: l10n.filter,
                                                  textColor: Appstyle.violet,
                                                  color: Appstyle.Tblanc,
                                                  icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                  iconColor: Appstyle.violet,
                                                  showBadge: _filtresExpirationActifs,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilterExpire();
                                                        appliquerFiltreExpire();
                                                      }
                                                    });
                                                  },
                                                ),
                                                SizedBox(width: paddingH/4),
                                                if (filtresActifs)
                                                  MainIconButton(
                                                    color: Colors.grey.shade400,
                                                    imagePath: 'assets/icons/action/supprimer_icon.png',
                                                    onPressed: () {
                                                      setState(() {
                                                        supprimerFilterExpire();
                                                        appliquerFiltreExpire();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH/4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor: Colors.green,
                                                  iconColor: Colors.green,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.download,
                                                  loading: _exportEnCours,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel();
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.extractPdf,
                                                  textColor: Colors.red,
                                                  iconColor: Colors.red,
                                                  color: Appstyle.Tblanc,
                                                  icon: Icons.picture_as_pdf,
                                                  onPressed: () async {
                                                    await _exportCurrentModuleToExcel(enPdf: true);
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                  color: Colors.orange,
                                                  onPressed: () async {
                                                    await _exportSelectedToExcel();
                                                  },
                                                ),
                                              ],
                                            ),
                                            Row(
                                              textDirection: textDirection,
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (expiresSelectionnes.length == 1) {
                                                      ProduitDetail(context, expiresSelectionnes.first);
                                                    } else if (expiresSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.expiredProducts,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.expiredProducts,
                                                        message: l10n.selectSingleProductForDetail,
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),

                                      if (!filtresActifs)
                                        SizedBox(height: paddingV/2),

                                      // Filtres
                                      if (filtresActifs)
                                        Align(
                                          alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(vertical: paddingV/2),
                                            child: filtreExpire(setState, adjustedWidth*1/3, l10n, translator, isRTL),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauProduitAdvanced(
                                          // Clé stable : cf. commentaire dans produit_screen.dart.
                                          key: const ValueKey('expire-produit-table'),
                                          col: false,
                                          produits: expireFiltres,
                                          categories: categoriesTest,
                                          sousCategories: sousCategoriesTest,
                                          remises: remisesTest,
                                          fournisseurs: fournisseursTest,
                                          seuilMinimum: seuilMinimum,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              expiresSelectionnes = selection;
                                            });
                                          },
                                        ),
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

  Widget filtreBesion(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Ligne catégorie / sous-catégorie / état
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.categorie,
                    child: TextListe(
                      value: selectedCategorieFilterBesion,
                      items: categorieFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedCategorieFilterBesion = v;
                          selectedSousCategorieFilterBesion = null;
                          appliquerFiltreBesion();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.sousCategorie,
                    child: TextListe(
                      value: selectedSousCategorieFilterBesion,
                      items: sousCategorieFilterOptions
                          .where((sc) {
                        if (selectedCategorieFilterBesion == null) return true;
                        final categorieCode = sousCategoriesTest
                            .firstWhere((s) => s.nom == sc)
                            .categorieCode;
                        return categoriesTest
                            .where((c) => c.code == categorieCode)
                            .firstOrNull
                            ?.nom == selectedCategorieFilterBesion;
                      })
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedSousCategorieFilterBesion = v;
                          appliquerFiltreBesion();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.etat,
                    child: TextListe(
                      value: selectedEtatFilterB != null ? translator.translateEtat(selectedEtatFilterB!) : null,
                      items: translator.etatDisplayList,
                      onChanged: (v) {
                        setState(() {
                          selectedEtatFilterB = translator.etatToFrench(v!);
                          appliquerFiltreBesion();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Ligne recherche / quantité
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerBesion,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltreBesion();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.quantity ?? "Quantité",
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: quantiteMinBesion,
                    maxValue: quantiteMaxBesion,
                    onChanged: (min, max) {
                      setState(() {
                        quantiteMinBesion = min;
                        quantiteMaxBesion = max;
                        appliquerFiltreBesion();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }

  Widget filtreExpire(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Ligne catégorie / sous-catégorie / état
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.categorie,
                    child: TextListe(
                      value: selectedCategorieFilterExpire,
                      items: categorieFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedCategorieFilterExpire = v;
                          selectedSousCategorieFilterExpire = null;
                          appliquerFiltreExpire();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.sousCategorie,
                    child: TextListe(
                      value: selectedSousCategorieFilterExpire,
                      items: sousCategorieFilterOptions
                          .where((sc) {
                        if (selectedCategorieFilterExpire == null) return true;
                        final categorieCode = sousCategoriesTest
                            .firstWhere((s) => s.nom == sc)
                            .categorieCode;
                        return categoriesTest
                            .where((c) => c.code == categorieCode)
                            .firstOrNull
                            ?.nom == selectedCategorieFilterExpire;
                      })
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedSousCategorieFilterExpire = v;
                          appliquerFiltreExpire();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.etat,
                    child: TextListe(
                      value: selectedEtatFilterExpire != null ? translator.translateEtat(selectedEtatFilterExpire!) : null,
                      items: translator.etatDisplayList,
                      onChanged: (v) {
                        setState(() {
                          selectedEtatFilterExpire = translator.etatToFrench(v!);
                          appliquerFiltreExpire();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Ligne recherche / quantité
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerExpire,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltreExpire();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.quantity ?? "Quantité",
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: quantiteMinExpire,
                    maxValue: quantiteMaxExpire,
                    onChanged: (min, max) {
                      setState(() {
                        quantiteMinExpire = min;
                        quantiteMaxExpire = max;
                        appliquerFiltreExpire();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }

  Widget filtreBesoinList(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Date row
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrlBesoinList,
                    onTap: _pickDateDebutBesoinList,
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebutBesoinList != null,
                    controller: _dateFinCtrlBesoinList,
                    onTap: _pickDateFinBesoinList,
                  ),
                ),
                ChampPeriodeRapide(
                  l10n: l10n,
                  value: periodeRapide,
                  onSelected: (v) {
                    setState(() {
                      periodeRapide = v;
                      _appliquerPeriodeRapideBesoinList(v, l10n);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerBesionList,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltreBesoinList();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.fournisseur,
                  child: TextListe(
                    value: selectedFournisseurFilterBesoinList,
                    items: FournisseurFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedFournisseurFilterBesoinList = v;
                        appliquerFiltreBesoinList();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilterRp != null ? translator.translateEtat(selectedEtatFilterRp!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterRp = translator.etatToFrench(v!);
                        appliquerFiltreBesoinList();
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }
}
