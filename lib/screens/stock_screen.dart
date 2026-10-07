import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/StatistiquesGlobales.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'dart:io';
import 'package:caisse_dz/Services/export_spinner.dart';

import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/remise.dart';

import 'package:caisse_dz/core/dialog/mouvement/mouvement_detail.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';

import 'package:caisse_dz/core/dialog/stock/distribution.dart';
import 'package:caisse_dz/core/dialog/stock/stock_detail.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/tableau/mouvement/tableau_mouvement.dart';
import 'package:caisse_dz/core/tableau/stock/tableau_stock.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/utilis/barcode_scan_listener.dart';

import 'package:caisse_dz/core/widget/account.dart';

import 'package:caisse_dz/core/widget/afficheur/afficheur_produit_stock.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_stock_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_mouvement.dart';

import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';

import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';

import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/client.dart';

import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';

String? selectedEtatFilterS;
String? selectedEtatFilterM;

// Valeurs sélectionnées dans le filtre
String? selectedCategorieFilter;
String? selectedSousCategorieFilter;
String? selectedMarqueFilter;

String? selectedTypeMouvementFilter;
String? selectedClientFilter;
String? selectedFournisseurFilter;
String? selectedProduitFilter;

List<SousCategorie>     sousCategoriesTest    = [];
List<Mouvement>         mouvementsTest        = [];
List<Client>            clientsTest           = [];
List<Fournisseur>       fournisseursTest      = [];
List<Produit>           produitsTest          = [];
List<Categorie>         categoriesTest        = [];
List<Remise>            remisesTest           = [];
List<Utilisateur>       utilisateursTest      = [];

List<Produit>     produitsSelectionnes    = [];
List<Mouvement>   mouvementsSelectionnes  = [];

class StockScreen extends StatefulWidget {
  const StockScreen({super.key});
  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late BarcodeScanListener _barcodeScanListener;
  // Garde anti-double-clic pour l'export Excel (voir client_screen.dart pour
  // le détail du bug évité).
  bool _exportEnCours = false;

  // ✅ Constantes pour les index des tabs
  static const int TAB_STOCK = 0;
  static const int TAB_MOUVEMENT = 1;

  // Period keys for translation lookup

  List<String> sousCategorieFilterOptions = [];
  List<String> TypeMouvementFilterOptions = [];
  List<String> FournisseurFilterOptions   = [];
  List<String> categorieFilterOptions     = [];
  List<String> ProduitFilterOptions       = [];
  List<String> ClientFilterOptions        = [];

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  String nombre_stock           = "1200";
  String nombre_mouvement       = "250";
  double seuilMinimum           = 0;
  double seuilMaximum           = 0;

  // Quantité par produit calculée depuis le journal des mouvements — voir
  // produit_screen.dart, même mécanisme (MouvementsServices.totauxParProduit).
  Map<String, double> quantitesParMagasin = {};
  String? magasinFiltreCode;
  bool _magasinFiltreInitialise = false;
  List<Magasin> magasinsDisponiblesStock = [];

  Future<void> _chargerQuantitesParMagasin() async {
    final totaux = await MouvementsServices.totauxParProduit(magasinCode: magasinFiltreCode);
    if (!mounted) return;
    setState(() => quantitesParMagasin = totaux.quantites);
  }

  // Cards globales (AfficheurStockGlobalWidget) : vrais compteurs, voir
  // StatistiquesGlobalesServices.
  CompteursGlobaux compteursGlobaux = const CompteursGlobaux();

  Future<void> loadAllData() async {
    final test = await ProduitServices.getAllProduits();

    final sousCategories    = await SousCategoriesServices.getAllSousCategorie();
    final fournisseurs      = await FournisseurServices.getAllFournisseurs();
    final clients            = await ClientServices.getAllClients();
    final mouvements        = await MouvementsServices.getAllMouvements();
    final categories        = await CategorieServices.getAllCategorie();
    final produits          = await ProduitServices.getAllProduits();
    final remises           = await RemiseServices.getAllRemise();
    final param              = await ParamServices.getParam();
    final utilisateurs      = await UtilisateurServices.getAllUtilisateurs();
    final magasins           = (await MagasinServices.getAllMagasins()).where((m) => m.etat).toList();

    final auth = Provider.of<AuthState>(context, listen: false);
    // Quantités par magasin :
    // - sans la permission "voir le stock de tous les magasins" (cas des
    //   non-admin) : toujours le magasin de la caisse de l'utilisateur ;
    // - non-admin autorisé : ce magasin par défaut, puis libre ;
    // - admin : "Tous les magasins" par défaut.
    if (!auth.canVoirStockTousMagasins) {
      magasinFiltreCode = await MagasinServices.getMagasinCodeUtilisateur(auth.userCode!);
    } else if (!_magasinFiltreInitialise) {
      _magasinFiltreInitialise = true;
      if (auth.role != 'Admin') {
        magasinFiltreCode = await MagasinServices.getMagasinCodeUtilisateur(auth.userCode!);
      }
    }

    final totaux             = await MouvementsServices.totauxParProduit(magasinCode: magasinFiltreCode);

    final compteurs = await StatistiquesGlobalesServices.getCompteurs();
    if (!mounted) return;
    setState(() {
      compteursGlobaux = compteurs;
      sousCategoriesTest    = sousCategories;
      fournisseursTest      = fournisseurs;
      clientsTest           = clients;
      mouvementsTest        = mouvements;
      categoriesTest        = categories;
      produitsTest          = produits;
      remisesTest           = remises;
      utilisateursTest      = utilisateurs;
      seuilMinimum          = param.Minimum;
      seuilMaximum          = param.Maximum;
      produitsFiltres   = produitsTest;
      mouvementsFiltres = mouvementsTest;
      magasinsDisponiblesStock = magasins;
      quantitesParMagasin = totaux.quantites;

      sousCategorieFilterOptions = sousCategoriesTest.map  ((sc) => sc.nom). toSet().toList();
      TypeMouvementFilterOptions = mouvementsTest.map      ((c)  => c.type). toSet().toList();
      FournisseurFilterOptions   = fournisseursTest.map    ((sc) => sc.nom). toSet().toList();
      categorieFilterOptions     = categoriesTest.map      ((c)  => c.nom).  toSet().toList();
      ProduitFilterOptions       = produitsTest.map        ((c)  => c.nom).  toSet().toList();
      ClientFilterOptions        = clientsTest.map         ((c)  => c.nom).  toSet().toList();

      nombre_stock = produitsTest.length.toString();
      nombre_mouvement = mouvementsTest.length.toString();

      produitsSelectionnes.clear();
      mouvementsSelectionnes.clear();
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

      if (currentTab == TAB_STOCK) {
        // Produits (Stock)
        final produitsToExport = filtresActifs ? produitsFiltres : produitsTest;

        if (produitsToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.stock,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.stock;
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
        // Mouvements
        final mouvementsToExport = filtresActifs ? mouvementsFiltres : mouvementsTest;

        if (mouvementsToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.entree,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.entree;
        excelFile = await ExcelGenerator.generateMouvementsExcel(
          mouvements: mouvementsToExport,
          produits: produitsTest,
          clients: clientsTest,
          fournisseurs: fournisseursTest,
          l10n: l10n,
          translator: translator,
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

      final sheetName = currentTab == TAB_STOCK ? 'Produits' : 'Mouvements';
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

      if (currentTab == TAB_STOCK) {
        // Produits (Stock)
        if (produitsSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.stock,
            message: l10n.noProductSelected,
          );
          return;
        }

        moduleName = l10n.stock;
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: produitsSelectionnes,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: seuilMinimum,
          seuilMax: seuilMaximum,
        );
      } else {
        // Mouvements
        if (mouvementsSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.entree,
            message: l10n.noProductSelected,
          );
          return;
        }

        moduleName = l10n.entree;
        excelFile = await ExcelGenerator.generateMouvementsExcel(
          mouvements: mouvementsSelectionnes,
          produits: produitsTest,
          clients: clientsTest,
          fournisseurs: fournisseursTest,
          l10n: l10n,
          translator: translator,
        );
      }

      fermerSpinner();

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_STOCK ? 'Produits' : 'Mouvements';
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

  DateTime? dateDebut;
  DateTime? dateFin;
  final TextEditingController _dateDebutCtrl  = TextEditingController();
  final TextEditingController _dateFinCtrl    = TextEditingController();

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

  final TextEditingController _searchController           = TextEditingController();
  final TextEditingController _searchControllerMouvement  = TextEditingController();

  List<Mouvement>   mouvementsFiltres = [];
  List<Produit>     produitsFiltres   = [];

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
    _barcodeScanListener = BarcodeScanListener(onScan: _onBarcodeScanned)..start();
    loadAllData();
  }

  @override
  void dispose() {
    _barcodeScanListener.stop();
    _tabController.dispose();
    super.dispose();
  }

  // ✅ Scan lecteur code-barres/QR : bascule sur l'onglet Stock si besoin, ouvre
  // la section filtre et remplit le champ de recherche avec le code scanné.
  // Ignoré si un dialog est ouvert au-dessus de l'écran (route plus "current"),
  // pour que le scan profite au dialog ouvert et non à l'écran stock en arrière-plan.
  void _onBarcodeScanned(String rawCode) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final code = rawCode.trim();
    if (code.isEmpty) return;

    if (_tabController.index != TAB_STOCK) {
      _tabController.animateTo(TAB_STOCK);
    }

    setState(() {
      filtresActifs = true;
      _searchController.text = code;
      appliquerFiltre();
    });
  }

  String _formatDate(DateTime d) {
    return  "${d.day  .toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }


  void appliquerFiltre() {
    produitsFiltres = produitsTest.where((p) {
      final searchText = _searchController.text.toLowerCase();
      final nomCategorieP = categoriesTest.where((c) => c.id == p.categorieId).firstOrNull?.nom ?? '';
      final nomSousCategorieP = sousCategoriesTest.where((sc) => sc.id == p.sousCategorieId).firstOrNull?.nom ?? '';
      final catOk = selectedCategorieFilter == null || selectedCategorieFilter!.isEmpty || nomCategorieP == selectedCategorieFilter;
      final sousCatOk = selectedSousCategorieFilter == null || selectedSousCategorieFilter!.isEmpty || nomSousCategorieP == selectedSousCategorieFilter;
      final marqueOk = selectedMarqueFilter == null || selectedMarqueFilter!.isEmpty || p.marque == selectedMarqueFilter;
      final searchOk = searchText.isEmpty ||
          '${p.searchableText} $nomCategorieP $nomSousCategorieP'.toLowerCase().contains(searchText);

      final prixAchatOk = (prixAchatMin == null || p.prixAchat >= prixAchatMin!) &&
          (prixAchatMax == null || p.prixAchat <= prixAchatMax!);

      final prixVenteOk = (prixVenteMin == null || p.prixVente >= prixVenteMin!) &&
          (prixVenteMax == null || p.prixVente <= prixVenteMax!);

      final quantiteP = quantitesParMagasin[p.code] ?? 0;
      final quantiteOk = (quantiteMin == null || quantiteP >= quantiteMin!) &&
          (quantiteMax == null || quantiteP <= quantiteMax!);

      final etatOk = selectedEtatFilterS == null ||
          selectedEtatFilterS == "" ||
          (selectedEtatFilterS == "Actif" && p.etat) ||
          (selectedEtatFilterS == "Inactif" && !p.etat);

      return catOk && sousCatOk && marqueOk && prixAchatOk && prixVenteOk && etatOk && searchOk && quantiteOk;
    }).toList();

    if ((selectedCategorieFilter      == null || selectedCategorieFilter!.isEmpty) &&
        (selectedSousCategorieFilter  == null || selectedSousCategorieFilter!.isEmpty) &&
        (selectedEtatFilterS == null || selectedEtatFilterS!.isEmpty) &&
        (selectedMarqueFilter         == null || selectedMarqueFilter!.isEmpty) &&
        prixAchatMin  == null && prixAchatMax == null &&
        prixVenteMin  == null && prixVenteMax == null &&
        quantiteMin   == null && quantiteMax == null &&
        _searchController.text.isEmpty) {
      produitsFiltres = produitsTest;
    }
  }

  void appliquerFiltreMouvement() {
    mouvementsFiltres = mouvementsTest.where((p) {
      final searchText      = _searchControllerMouvement.text.toLowerCase();
      final produitNom      = produitsTest.where((pr) => pr.code == p.codeProduit).firstOrNull?.nom ?? '';
      final clientNom       = clientsTest.where((c) => c.code == p.clientCode).firstOrNull?.nom ?? '';
      final fournisseurNom  = fournisseursTest.where((f) => f.code == p.fournisseurCode).firstOrNull?.nom ?? '';
      final typemooveOk     = selectedTypeMouvementFilter == null || selectedTypeMouvementFilter!.isEmpty || p.type == selectedTypeMouvementFilter;
      final clientmoveOk    = selectedClientFilter        == null || selectedClientFilter!.isEmpty || clientNom == selectedClientFilter;
      final fournissemoveOk = selectedFournisseurFilter   == null || selectedFournisseurFilter!.isEmpty || fournisseurNom == selectedFournisseurFilter;
      final produitmoveOk   = selectedProduitFilter       == null || selectedProduitFilter!.isEmpty || produitNom == selectedProduitFilter;

      final searchOk = searchText.isEmpty ||
          '${p.searchableText} $produitNom $clientNom $fournisseurNom'.toLowerCase().contains(searchText);

      final etatOk = selectedEtatFilterM == null ||
          selectedEtatFilterM == "" ||
          (selectedEtatFilterM == "Actif" && p.etat) ||
          (selectedEtatFilterM == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebut == null && dateFin == null) return true;

        final d = p.date;

        final debut = dateDebut != null
            ? DateTime(dateDebut!.year, dateDebut!.month, dateDebut!.day)
            : null;

        final fin = dateFin != null
            ? DateTime(dateFin!.year, dateFin!.month, dateFin!.day, 23, 59, 59)
            : null;

        if (debut != null && d.isBefore(debut)) return false;
        if (fin   != null && d.isAfter(fin))    return false;

        return true;
      }();

      return typemooveOk && clientmoveOk && fournissemoveOk && produitmoveOk && etatOk && searchOk && dateOk;
    }).toList();

    if ((selectedClientFilter         == null || selectedClientFilter!.isEmpty) &&
        (selectedProduitFilter        == null || selectedProduitFilter!.isEmpty) &&
        (selectedFournisseurFilter    == null || selectedFournisseurFilter!.isEmpty) &&
        (selectedTypeMouvementFilter  == null || selectedTypeMouvementFilter!.isEmpty) &&
        (selectedEtatFilterM == null || selectedEtatFilterM!.isEmpty) &&
        dateDebut   == null &&
        dateFin     == null &&
        _searchControllerMouvement.text.isEmpty) {
      mouvementsFiltres = mouvementsTest;
    }
  }

  void _appliquerPeriodeRapide(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebut = DateTime(now.year, now.month, now.day);
        dateFin = dateDebut;
        break;
      case "yesterday":
        dateDebut = DateTime(now.year, now.month, now.day - 1);
        dateFin = dateDebut;
        break;
      case "week":
        dateDebut = now.subtract(Duration(days: now.weekday - 1));
        dateFin = dateDebut!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebut = now.subtract(Duration(days: now.weekday + 6));
        dateFin = dateDebut!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebut = DateTime(now.year, now.month, 1);
        dateFin = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebut = DateTime(now.year, now.month - 1, 1);
        dateFin = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebut = now.subtract(const Duration(days: 6));
        dateFin = now;
        break;
      case "last30days":
        dateDebut = now.subtract(const Duration(days: 29));
        dateFin = now;
        break;
      case "year":
        dateDebut = DateTime(now.year, 1, 1);
        dateFin = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebut = DateTime(now.year - 1, 1, 1);
        dateFin = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);

    appliquerFiltreMouvement();
  }

  void supprimerFilter() {
    selectedCategorieFilter = null;
    selectedSousCategorieFilter = null;
    selectedMarqueFilter=null;
    prixAchatMin = null;
    prixAchatMax = null;
    quantiteMin = null;
    quantiteMax = null;
    prixVenteMin = null;
    prixVenteMax = null;
    selectedEtatFilterS=null;
    _searchController.clear();
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  // ✅ Vrai si au moins un champ de filtre stock (produits) est renseigné (pour l'indicateur visuel du bouton Filtre).
  // Note : dateDebut/dateFin/periodeRapide sont partagés avec l'onglet Mouvement mais ne sont pas
  // utilisés par appliquerFiltre() (stock), donc volontairement exclus ici.
  bool get _filtresStockActifs =>
      selectedCategorieFilter != null ||
      selectedSousCategorieFilter != null ||
      selectedMarqueFilter != null ||
      prixAchatMin != null ||
      prixAchatMax != null ||
      prixVenteMin != null ||
      prixVenteMax != null ||
      quantiteMin != null ||
      quantiteMax != null ||
      selectedEtatFilterS != null ||
      _searchController.text.isNotEmpty;

  void supprimerFilterMouvement() {
    selectedFournisseurFilter=null;
    selectedClientFilter = null;
    selectedTypeMouvementFilter=null;
    selectedProduitFilter=null;
    selectedEtatFilterM=null;
    _searchControllerMouvement.clear();
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  // ✅ Vrai si au moins un champ de filtre mouvement est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresMouvementActifs =>
      selectedTypeMouvementFilter != null ||
      selectedClientFilter != null ||
      selectedFournisseurFilter != null ||
      selectedProduitFilter != null ||
      selectedEtatFilterM != null ||
      dateDebut != null ||
      dateFin != null ||
      periodeRapide != null ||
      _searchControllerMouvement.text.isNotEmpty;

  void vider_selectionne() {
    produitsSelectionnes.clear();
    mouvementsSelectionnes.clear();
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebut = picked;
        _dateDebutCtrl.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreMouvement();
      });
    }
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFin = picked;

        if (dateDebut != null && picked.isBefore(dateDebut!)) {
          dateFin = dateDebut;
        }

        _dateFinCtrl.text = _formatDate(dateFin!);
        periodeRapide = null;
        appliquerFiltreMouvement();
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
    final Color headerColor = currentTab == TAB_STOCK ? Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.stock,
      l10n.mouvement,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/produit_icon.png',
      'assets/icons/cardwidget/mouvement_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_stock,
      nombre_mouvement,
    ];

    // ✅ Couleurs des tabs
    final tabColors = [
      Appstyle.blueC,
      Appstyle.violet,
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
                                            "assets/icons/sidebar/stock_icon.png",
                                            width: 40,
                                            color: headerColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              Text(
                                                l10n.stock,
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
                                      color: currentTab == TAB_STOCK
                                          ? Appstyle.violet : Appstyle.indigo,
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
                                // 1. CAS STOCK (currentTab == TAB_STOCK)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_STOCK)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (produitsSelectionnes.length == 1)
                                        AfficheurProduitMouvement(
                                          produit: produitsSelectionnes.first,
                                          onDetails: () {
                                            ProduitDetail(context, produitsSelectionnes.first);
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

                                      if (produitsSelectionnes.length == 1)
                                        SizedBox(height: paddingV/2),

                                      // Filtres & Actions
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
                                                  iconColor:Appstyle.violet ,
                                                  showBadge: _filtresStockActifs,
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
                                                SizedBox(width: paddingH/4),
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
                                                  SizedBox(width: paddingH/4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor:Colors.green ,
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
                                                    if (produitsSelectionnes.length == 1) {
                                                      StockDetail(context, produitsSelectionnes.first);
                                                    } else if (produitsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.stock,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.stock,
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
                                            child: filtreProduit(setState, adjustedWidth, l10n, translator, isRTL),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauStockAdvanced(
                                          key: ValueKey(produitsFiltres),
                                          produits: produitsFiltres,
                                          categories: categoriesTest,
                                          sousCategories: sousCategoriesTest,
                                          remises: remisesTest,
                                          fournisseurs: fournisseursTest,
                                          seuilMinimum: seuilMinimum,
                                          utilisateurs: utilisateursTest,
                                          quantites: quantitesParMagasin,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              produitsSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 2. CAS MOUVEMENT (currentTab == TAB_MOUVEMENT)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_MOUVEMENT)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (mouvementsSelectionnes.length == 1)
                                        AfficheurMouvement(
                                          mouvement: mouvementsSelectionnes.first,
                                          nomProduit: produitsTest.where((pr) => pr.code == mouvementsSelectionnes.first.codeProduit).firstOrNull?.nom ?? mouvementsSelectionnes.first.codeProduit,
                                          nomClient: clientsTest.where((c) => c.code == mouvementsSelectionnes.first.clientCode).firstOrNull?.nom,
                                          nomFournisseur: fournisseursTest.where((f) => f.code == mouvementsSelectionnes.first.fournisseurCode).firstOrNull?.nom,
                                          onDetails: () {
                                            MouvementDetail(
                                              context,
                                              mouvementsSelectionnes.first,
                                              produits: produitsTest,
                                              clients: clientsTest,
                                              fournisseurs: fournisseursTest,
                                            );
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

                                      if (mouvementsSelectionnes.length == 1)
                                        SizedBox(height: paddingV/2),

                                      // Filtres & Actions
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
                                                  iconColor:Appstyle.violet ,
                                                  showBadge: _filtresMouvementActifs,
                                                  onPressed: () {
                                                    setState(() {
                                                      filtresActifs = !filtresActifs;
                                                      if (!filtresActifs) {
                                                        supprimerFilterMouvement();
                                                        appliquerFiltreMouvement();
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
                                                        supprimerFilterMouvement();
                                                        appliquerFiltreMouvement();
                                                      });
                                                    },
                                                  ),
                                                if (filtresActifs)
                                                  SizedBox(width: paddingH/4),
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor:Colors.green ,
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
                                                    if (mouvementsSelectionnes.length == 1) {
                                                      MouvementDetail(
                                                        context,
                                                        mouvementsSelectionnes.first,
                                                        produits: produitsTest,
                                                        clients: clientsTest,
                                                        fournisseurs: fournisseursTest,
                                                      );
                                                    } else if (mouvementsSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entree,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.entree,
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
                                            child: filtreMouvement(setState, adjustedWidth*1/3, l10n, translator, isRTL),
                                          ),
                                        ),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.68,
                                        child: TableauMouvementAdvanced(
                                          key: ValueKey(mouvementsFiltres),
                                          mouvements: mouvementsFiltres,
                                          produits: produitsTest,
                                          clients: clientsTest,
                                          fournisseurs: fournisseursTest,
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              mouvementsSelectionnes = selection;
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
  Widget filtreProduit(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    // ✅ Permission spéciale (voir RoleDetail) : filtre "Tous les magasins".
    final canVoirStockTousMagasins = Provider.of<AuthState>(context, listen: false).canVoirStockTousMagasins;
    List<String> marqueFilterOptions = produitsTest
        .map((p) => p.marque)
        .toSet()
        .toList();

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Ligne catégorie / sous-catégorie / marque
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.categorie,
                    child: TextListe(
                      value: selectedCategorieFilter,
                      items: categorieFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedCategorieFilter = v;
                          selectedSousCategorieFilter = null;
                          appliquerFiltre();
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
                      value: selectedSousCategorieFilter,
                      items: sousCategorieFilterOptions
                          .where((sc) {
                        if (selectedCategorieFilter == null) return true;
                        final categorieCode = sousCategoriesTest
                            .firstWhere((s) => s.nom == sc)
                            .categorieCode;
                        return categoriesTest
                            .where((c) => c.code == categorieCode)
                            .firstOrNull
                            ?.nom == selectedCategorieFilter;
                      })
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedSousCategorieFilter = v;
                          appliquerFiltre();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.marque,
                    child: TextListe(
                      value: selectedMarqueFilter,
                      items: marqueFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedMarqueFilter = v;
                          appliquerFiltre();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Magasin / état. Quantité affichée = calculée depuis le journal
            // des mouvements pour ce magasin (ou tous magasins si "Tous").
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.magasin,
                  child: TextListe(
                    enabled: canVoirStockTousMagasins,
                    value: magasinFiltreCode == null
                        ? null
                        : magasinsDisponiblesStock
                            .firstWhereOrNull((m) => m.code == magasinFiltreCode)
                            ?.nom,
                    hint: "Tous les magasins",
                    items: magasinsDisponiblesStock.map((m) => m.nom).toList(),
                    onChanged: (v) {
                      magasinFiltreCode = (v == null || v.isEmpty)
                          ? null
                          : magasinsDisponiblesStock.firstWhereOrNull((m) => m.nom == v)?.code;
                      _chargerQuantitesParMagasin();
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilterS != null ? translator.translateEtat(selectedEtatFilterS!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterS = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // Ligne prix achat / prix vente / quantité
            Row(
              textDirection: textDirection,
              children: [
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
                    label: l10n.salePrice,
                    child: FourchettePrixWidget(
                      couleur: Appstyle.violet,
                      minValue: prixVenteMin,
                      maxValue: prixVenteMax,
                      onChanged: (min, max) {
                        setState(() {
                          prixVenteMin = min;
                          prixVenteMax = max;
                          appliquerFiltre();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.quantity ?? "Quantité",
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
            const SizedBox(height: 15),
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchController,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltre();
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

  Widget filtreMouvement(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Type / Client / Fournisseur
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.type,
                    child: TextListe(
                      value: selectedTypeMouvementFilter,
                      items: TypeMouvementFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedTypeMouvementFilter = v;
                          appliquerFiltreMouvement();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.client,
                    child: TextListe(
                      value: selectedClientFilter,
                      items: ClientFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedClientFilter = v;
                          appliquerFiltreMouvement();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.fournisseur,
                    child: TextListe(
                      value: selectedFournisseurFilter,
                      items: FournisseurFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedFournisseurFilter = v;
                          appliquerFiltreMouvement();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            LigneFiltreTiers(
              textDirection: textDirection,
              children: [
                ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrl,
                    onTap: _pickDateDebut,
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebut != null,
                    controller: _dateFinCtrl,
                    onTap: _pickDateFin,
                  ),
                ),
                ChampPeriodeRapide(
                  l10n: l10n,
                  value: periodeRapide,
                  onSelected: (v) {
                    setState(() {
                      periodeRapide = v;
                      _appliquerPeriodeRapide(v, l10n);
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
                    controller: _searchControllerMouvement,
                    onChanged: (v) {
                      setState(() {
                        appliquerFiltreMouvement();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.produit,
                  child: TextListe(
                    value: selectedProduitFilter,
                    items: ProduitFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedProduitFilter = v;
                        appliquerFiltreMouvement();
                      });
                    },
                  ),
                ),
                ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilterM != null ? translator.translateEtat(selectedEtatFilterM!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterM = translator.etatToFrench(v!);
                        appliquerFiltreMouvement();
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
