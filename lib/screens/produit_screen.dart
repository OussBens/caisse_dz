import 'dart:io';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_detail.dart';
import 'package:caisse_dz/core/dialog/pack/pack_detail.dart';
import 'package:caisse_dz/core/dialog/pack/pack_nouveau.dart';
import 'package:caisse_dz/core/dialog/remise/remise_detail.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_detail.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_categorie.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pack.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_remise.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheure_souscateg.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_actif.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_modif.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_nouveau.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/dialog/pack/pack_actif.dart';
import 'package:caisse_dz/core/dialog/pack/pack_modif.dart';
import 'package:caisse_dz/core/dialog/produit/produit_actif.dart';
import 'package:caisse_dz/core/dialog/produit/produit_categorie_sous_categorie.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';
import 'package:caisse_dz/core/dialog/produit/produit_modif.dart';
import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/core/dialog/produit/produit_pack.dart';
import 'package:caisse_dz/core/dialog/produit/produit_remise.dart';
import 'package:caisse_dz/core/dialog/remise/remise_actif.dart';
import 'package:caisse_dz/core/dialog/remise/remise_modif.dart';
import 'package:caisse_dz/core/dialog/remise/remise_nouveau.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_actif.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_modif.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_nouveau.dart';
import 'package:caisse_dz/core/tableau/Produit/tableau_produit.dart';
import 'package:caisse_dz/core/tableau/categorie/categorie_tableau.dart';
import 'package:caisse_dz/core/tableau/pack/tableau_pack.dart';
import 'package:caisse_dz/core/tableau/remise/tableau_remise.dart';
import 'package:caisse_dz/core/tableau/sous_categorie/tableau_sous_categorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit_glolbal.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

final TextEditingController tauxController = TextEditingController();
final TextEditingController minController = TextEditingController();
final TextEditingController maxController = TextEditingController();

// Valeurs sélectionnées dans le filtre
String? selectedEtatFilter;
String? selectedCategorieFilter;
String? selectedSousCategorieFilter;
String? selectedMarqueFilter;
String typeMargecalcul = "Montant";

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

class ProduitScreen extends StatefulWidget {
  const ProduitScreen({super.key});

  @override
  State<ProduitScreen> createState() => _ProduitScreenState();
}

class _ProduitScreenState extends State<ProduitScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_PRODUIT = 0;
  static const int TAB_CATEGORIE = 1;
  static const int TAB_SOUS_CATEGORIE = 2;
  static const int TAB_REMISE = 3;
  static const int TAB_PACK = 4;
  static const int TAB_PARAMETRE = 5;

  late List<String> categorieFilterOptions = categoriesTest
      .map((c) => c.nom)
      .toSet()
      .toList();
  late List<String> sousCategorieFilterOptions = sousCategoriesTest
      .map((sc) => sc.nom)
      .toSet()
      .toList();

  bool filtresActifs = false;
  // ✅ Plus besoin de selectedCardIndex, on utilise _tabController.index

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchControllerPack = TextEditingController();
  final TextEditingController _searchControllerRemise = TextEditingController();
  final TextEditingController _searchControllerCategorie = TextEditingController();
  final TextEditingController _searchControllerSousCategorie = TextEditingController();

  Color colorbuttonactionicon = Appstyle.violet;
  Color colorbuttonactionicon2 = Appstyle.gris;
  Color colorbuttonactionicon3 = Appstyle.blueC;
  Color colorbuttonactionicon4 = Appstyle.maron;
  Color colorbuttonactionicon5 = Appstyle.indigo;
  Color colorbuttonactionicon6 = Appstyle.jaune;

  double? prixAchatMin;
  double? prixAchatMax;
  double? prixVenteMin;
  double? prixVenteMax;
  String nombre_produit = "4122";
  String nombre_categorie = "20";
  String nombre_sous_categorie = "12";
  String nombre_remise = "5";
  String nombre_pack = "8";

  List<Produit> produitsSelectionnes = [];
  List<Categorie> categoriesSelectionnes = [];
  List<SousCategorie> souscategoriesSelectionnes = [];
  List<Remise> remisesSelectionnes = [];
  List<Pack> packsSelectionnes = [];
  List<Produit> produitsFiltres = [];
  List<Pack> packsFiltres = [];
  List<Categorie> categoriesFiltres = [];
  List<SousCategorie> souscategoriesFiltres = [];
  List<Remise> remiseFiltres = [];
  List<List<Map<String, dynamic>>> actionButtons = [];

  List<Pack> packsTest = [];
  List<Remise> remisesTest = [];
  List<Produit> produitsTest = [];
  List<SousCategorie> sousCategoriesTest = [];
  List<Categorie> categoriesTest = [];
  Paramters ParamtersDB = Paramters(
      id: 0,
      TauxMargePerncetage: 0,
      TauxMargeMontant: 0,
      Maximum: 0,
      Minimum: 0,
      typeMarge: "Montant",
      Datecree: DateTime.now(),
      creeParCode: "IMAD2"
  );
  String selectedtypecacul = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          vider_les_liste_selectionne();
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

  Future<void> _exportCurrentModuleToExcel() async {
    try {
      final l10n = AppLocalizations.of(context);
      final translator = ListsConstTranslator(l10n);

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      List<dynamic> dataToExport = [];
      String moduleName = '';
      String sheetName = '';
      File? excelFile;

      // Determine which module is active based on tab index
      switch (currentTab) {
        case TAB_PRODUIT: // 0 - Produits
          dataToExport = filtresActifs ? produitsFiltres : produitsTest;
          moduleName = l10n.produit;
          sheetName = 'Produits';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateProduitsExcel(
              produits: dataToExport.cast<Produit>(),
              l10n: l10n,
              translator: translator,
            );
          }
          break;
        case TAB_CATEGORIE: // 1 - Categories
          dataToExport = categoriesFiltres;
          moduleName = l10n.categorie;
          sheetName = 'Categories';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateCategoriesExcel(
              categories: dataToExport.cast<Categorie>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_SOUS_CATEGORIE: // 2 - Sous Categories
          dataToExport = souscategoriesFiltres;
          moduleName = l10n.sousCategorie;
          sheetName = 'SousCategories';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateSousCategoriesExcel(
              sousCategories: dataToExport.cast<SousCategorie>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_REMISE: // 3 - Remises
          dataToExport = remiseFiltres;
          moduleName = l10n.remise;
          sheetName = 'Remises';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateRemisesExcel(
              remises: dataToExport.cast<Remise>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_PACK: // 4 - Packs
          dataToExport = packsFiltres;
          moduleName = l10n.pack;
          sheetName = 'Packs';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generatePacksExcel(
              packs: dataToExport.cast<Pack>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_PARAMETRE: // 5 - Paramètre - Pas d'export
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.parametre,
            message: l10n.noDataToExport,
          );
          return;
      }

      if (dataToExport.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: moduleName,
          message: l10n.noDataToExport,
        );
        return;
      }

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      Navigator.pop(context); // Close loading dialog

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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportSelectedToExcel() async {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);

    // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
    final currentTab = _tabController.index;

    List<dynamic> selectedData = [];
    String moduleName = '';
    String sheetName = '';
    File? excelFile;

    // Determine which module is active and get selected items
    switch (currentTab) {
      case TAB_PRODUIT: // 0 - Produits
        if (produitsSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.produit,
            message: l10n.noProductSelected,
          );
          return;
        }
        selectedData = produitsSelectionnes;
        moduleName = l10n.produit;
        sheetName = 'Produits';
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: selectedData.cast<Produit>(),
          l10n: l10n,
          translator: translator,
        );
        break;
      case TAB_CATEGORIE: // 1 - Categories
        if (categoriesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.categorie,
            message: l10n.noCategorySelected,
          );
          return;
        }
        selectedData = categoriesSelectionnes;
        moduleName = l10n.categorie;
        sheetName = 'Categories';
        excelFile = await ExcelGenerator.generateCategoriesExcel(
          categories: selectedData.cast<Categorie>(),
          l10n: l10n,
        );
        break;
      case TAB_SOUS_CATEGORIE: // 2 - Sous Categories
        if (souscategoriesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.sousCategorie,
            message: l10n.noSubCategorySelected,
          );
          return;
        }
        selectedData = souscategoriesSelectionnes;
        moduleName = l10n.sousCategorie;
        sheetName = 'SousCategories';
        excelFile = await ExcelGenerator.generateSousCategoriesExcel(
          sousCategories: selectedData.cast<SousCategorie>(),
          l10n: l10n,
        );
        break;
      case TAB_REMISE: // 3 - Remises
        if (remisesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.remise,
            message: l10n.noDiscountSelected,
          );
          return;
        }
        selectedData = remisesSelectionnes;
        moduleName = l10n.remise;
        sheetName = 'Remises';
        excelFile = await ExcelGenerator.generateRemisesExcel(
          remises: selectedData.cast<Remise>(),
          l10n: l10n,
        );
        break;
      case TAB_PACK: // 4 - Packs
        if (packsSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.pack,
            message: l10n.noPackSelected,
          );
          return;
        }
        selectedData = packsSelectionnes;
        moduleName = l10n.pack;
        sheetName = 'Packs';
        excelFile = await ExcelGenerator.generatePacksExcel(
          packs: selectedData.cast<Pack>(),
          l10n: l10n,
        );
        break;
      case TAB_PARAMETRE: // 5 - Paramètre - Pas d'export de sélection
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.parametre,
          message: l10n.noDataToExport,
        );
        return;
    }

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      Navigator.pop(context); // Close loading dialog

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
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _initActionButtons(AppLocalizations l10n, ListsConstTranslator translator) async {
    actionButtons = [
      // Pour Produit: 6 Boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.length == 1) {
              ProduitDetail(context, produitsSelectionnes.first);
            } else if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.selectSingleProductForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/supprimer_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              await AnnulerProduit(context, produitsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                context: context,
                message: l10n.noProductSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.length == 1) {
              await ProduitModif(context, produitsSelectionnes.first);
              await loadAllData();
            } else if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else {
              await InformationDialog(
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.selectSingleProductToModify,
                context: context,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon4,
          'icon': 'assets/icons/cardwidget/categorie_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              await CategorieSousCategorieProduit(context, produitsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon5,
          'icon': 'assets/icons/cardwidget/remise_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              await RemiseProduit(context, produitsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon6,
          'icon': 'assets/icons/cardwidget/pack_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              await PackProduit(context, produitsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            }
          },
        },
      ],

      // Pour Catégorie: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.length == 1) {
              CategorieDetail(
                context,
                categoriesSelectionnes.first,
                nombreSousCategories: sousCategoriesTest
                    .where((sc) => sc.categorieNom == categoriesSelectionnes.first.nom)
                    .length,
              );
            } else if (categoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.selectSingleCategoryForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.isNotEmpty) {
              bool contientNonSupprimable = categoriesSelectionnes.any(
                    (cate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Categorie" && p.code == cate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.categorie,
                  message: l10n.cannotDeleteSystemCategory,
                );
              } else {
                await AnnulerCategorie(context, categoriesSelectionnes);
                await loadAllData();
              }
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.length == 1) {
              bool contientNonSupprimable = categoriesSelectionnes.any(
                    (cate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Categorie" && p.code == cate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.categorie,
                  message: l10n.cannotModifySystemCategory,
                );
              } else {
                await CategorieModif(context, categoriesSelectionnes.first);
                await loadAllData();
              }
            } else if (categoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.selectSingleCategoryToModify,
              );
            }
          },
        },
      ],

      // Pour Remise: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.length == 1) {
              RemiseDetail(context, remisesSelectionnes.first);
            } else if (remisesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.selectSingleDiscountForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.isNotEmpty) {
              await AnnulerRemise(context, remisesSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.length == 1) {
              await RemiseModif(context, remisesSelectionnes.first);
              await loadAllData();
            } else if (remisesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.selectSingleDiscountToModify,
              );
            }
          },
        },
      ],

      // Pour Pack: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.length == 1) {
              PackDetail(context, packsSelectionnes.first);
            } else if (packsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.selectSinglePackForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.isNotEmpty) {
              await ActiverPack(context, packsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.length == 1) {
              await PackModif(context, packsSelectionnes.first);
              await loadAllData();
            } else if (packsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.selectSinglePackToModify,
              );
            }
          },
        },
      ],

      // Pour Sous Catégorie: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.length == 1) {
              SousCategorieDetail(
                context,
                souscategoriesSelectionnes.first,
                nombreProduits: produitsTest
                    .where((p) => p.sousCategorie == souscategoriesSelectionnes.first.nom)
                    .length,
              );
            } else if (souscategoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.selectSingleSubCategoryForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.isNotEmpty) {
              bool contientNonSupprimable = souscategoriesSelectionnes.any(
                    (scate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Sous Categorie" && p.code == scate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.sousCategorie,
                  message: l10n.cannotDeleteSystemSubCategory,
                );
              } else {
                await AnnulerSousCategorie(context, souscategoriesSelectionnes);
                await loadAllData();
              }
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.length == 1) {
              bool contientNonSupprimable = souscategoriesSelectionnes.any(
                    (scate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Sous Categorie" && p.code == scate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.sousCategorie,
                  message: l10n.cannotModifySystemSubCategory,
                );
              } else {
                await SousCategorieModif(context, souscategoriesSelectionnes.first);
                await loadAllData();
              }
            } else if (souscategoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.selectSingleSubCategoryToModify,
              );
            }
          },
        },
      ],
    ];
    if (mounted) setState(() {});
  }

// Modifiez la fonction loadAllData pour être plus robuste
  Future<void> loadAllData() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final Param = await ParamServices.getParam();

      final pack = await PackServices.getAllPacks();
      final remise = await RemiseServices.getAllRemise();
      final produit = await ProduitServices.getAllProduits();
      final categorie = await CategorieServices.getAllCategorie();
      final sous = await SousCategoriesServices.getAllSousCategorie();

      if (!mounted) return;

      // Get translator for current locale
      final translator = ListsConstTranslator(AppLocalizations.of(context)!);

      setState(() {
        ParamtersDB = Param;

        // Store the TRANSLATED value for UI display
        selectedtypecacul = translator.translateTypeCalcul(ParamtersDB.typeMarge);

        // Set the controller text based on the translated value
        tauxController.text = selectedtypecacul == translator.translateTypeCalcul("Pourcentage")
            ? ParamtersDB.TauxMargePerncetage.toString()
            : ParamtersDB.TauxMargeMontant.toString();

        minController.text = ParamtersDB.Minimum.toString();
        maxController.text = ParamtersDB.Maximum.toString();

        // Mettre à jour les listes principales
        packsTest = pack;
        packsFiltres = List.from(pack); // Créer une nouvelle liste

        remisesTest = remise;
        remiseFiltres = List.from(remise); // Créer une nouvelle liste

        sousCategoriesTest = sous;
        souscategoriesFiltres = List.from(sous); // Créer une nouvelle liste

        categoriesTest = categorie;
        categoriesFiltres = List.from(categorie); // Créer une nouvelle liste

        produitsTest = produit;
        produitsFiltres = List.from(produit); // Créer une nouvelle liste

        // Mettre à jour les compteurs
        nombre_produit = produitsTest.length.toString();
        nombre_categorie = categoriesTest.length.toString();
        nombre_sous_categorie = sousCategoriesTest.length.toString();
        nombre_remise = remisesTest.length.toString();
        nombre_pack = packsTest.length.toString();

        // Réappliquer les filtres si nécessaire
        _reapplyFilters();

        produitsSelectionnes.clear();
        categoriesSelectionnes.clear();
        souscategoriesSelectionnes.clear();
        remisesSelectionnes.clear();
        packsSelectionnes.clear();



        // ✅ MISE À JOUR DES CONTRÔLEURS
        // Vérifier si le type traduit correspond à "Montant" ou "Pourcentage"
        if (selectedtypecacul == "Montant" || selectedtypecacul == "المبلغ") {
          tauxController.text = ParamtersDB.TauxMargeMontant.toString();
          print('Taux Montant: ${ParamtersDB.TauxMargeMontant}');
        } else if (selectedtypecacul == "Pourcentage" || selectedtypecacul == "النسبة المئوية") {
          tauxController.text = ParamtersDB.TauxMargePerncetage.toString();
          print('Taux Pourcentage: ${ParamtersDB.TauxMargePerncetage}');
        } else {
          // Fallback
          tauxController.text = "0";
        }

        minController.text = ParamtersDB.Minimum.toString();
        maxController.text = ParamtersDB.Maximum.toString();




        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Erreur chargement : $e");
    }
  }

// Ajoutez cette méthode pour réappliquer les filtres après rechargement
  void _reapplyFilters() {
    // Réappliquer le filtre pour les packs
    if (_searchControllerPack.text.isNotEmpty) {
      appliquefiltrePack();
    } else {
      packsFiltres = List.from(packsTest);
    }

    // Réappliquer le filtre pour les remises
    if (_searchControllerRemise.text.isNotEmpty) {
      appliquefiltreRemise();
    } else {
      remiseFiltres = List.from(remisesTest);
    }

    // Réappliquer le filtre pour les catégories
    if (_searchControllerCategorie.text.isNotEmpty) {
      appliquefiltreCatgorie();
    } else {
      categoriesFiltres = List.from(categoriesTest);
    }

    // Réappliquer le filtre pour les sous-catégories
    if (_searchControllerSousCategorie.text.isNotEmpty) {
      appliquefiltreSousCatgorie();
    } else {
      souscategoriesFiltres = List.from(sousCategoriesTest);
    }

    // Réappliquer le filtre pour les produits
    if (filtresActifs) {
      appliquerFiltre();
    } else {
      produitsFiltres = List.from(produitsTest);
    }
  }

  Future<void> _saveParam(AppLocalizations l10n, ListsConstTranslator translator) async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;

    final db = await DbCreator.openDb();
    final paramService = ParamServices(db);

    final double? tauxInput = tauxController.text.trim().isEmpty
        ? null
        : double.tryParse(tauxController.text);
    final double? minInput = minController.text.trim().isEmpty
        ? null
        : double.tryParse(minController.text);
    final double? maxInput = maxController.text.trim().isEmpty
        ? null
        : double.tryParse(maxController.text);

    // Convert display value (translated) back to French for database
    final frenchTypeCalcul = translator.typeCalculToFrench(selectedtypecacul);

    final updatedParam = Paramters(
      id: ParamtersDB.id,
      typeMarge: frenchTypeCalcul,
      TauxMargePerncetage: frenchTypeCalcul == "Pourcentage"
          ? (tauxInput ?? ParamtersDB.TauxMargePerncetage)
          : ParamtersDB.TauxMargePerncetage,
      TauxMargeMontant: frenchTypeCalcul == "Montant"
          ? (tauxInput ?? ParamtersDB.TauxMargeMontant)
          : ParamtersDB.TauxMargeMontant,
      Minimum: minInput ?? ParamtersDB.Minimum,
      Maximum: maxInput ?? ParamtersDB.Maximum,
      Datemodif: DateTime.now(),
      modifPar: userName,
      Datecree: ParamtersDB.Datecree,
      creeParCode: ParamtersDB.creeParCode,
    );

    final int id = await _GetNextHistoriqueId();
    final serviceess = await HistoriqueServices(db);
    final Historique histo = Historique(
      id: id,
      code: "HS $id ${DateTime.now().microsecondsSinceEpoch}",
      desc: "${l10n.modification} ${l10n.parametreProduit} ${l10n.by} $userName",
      oper: 'modification',
      type: 'paramter',
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceess.addHistorique(histo);

    await paramService.updateParam(updatedParam);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.settingsSavedSuccess)),
      );
    }
  }

  void appliquerFiltre() {
    produitsFiltres = produitsTest.where((p) {
      final searchText = _searchController.text.toLowerCase();
      final catOk = selectedCategorieFilter == null || selectedCategorieFilter!.isEmpty || p.categorie == selectedCategorieFilter;
      final sousCatOk = selectedSousCategorieFilter == null || selectedSousCategorieFilter!.isEmpty || p.sousCategorie == selectedSousCategorieFilter;
      final marqueOk = selectedMarqueFilter == null || selectedMarqueFilter!.isEmpty || p.marque == selectedMarqueFilter;
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);
      final prixAchatOk = (prixAchatMin == null || p.prixAchat >= prixAchatMin!) &&
          (prixAchatMax == null || p.prixAchat <= prixAchatMax!);
      final prixVenteOk = (prixVenteMin == null || p.prixVente >= prixVenteMin!) &&
          (prixVenteMax == null || p.prixVente <= prixVenteMax!);
      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && p.etat) ||
          (selectedEtatFilter == "Inactif" && !p.etat);

      return catOk && sousCatOk && marqueOk && prixAchatOk && prixVenteOk && etatOk && searchOk;
    }).toList();

    if ((selectedCategorieFilter == null || selectedCategorieFilter!.isEmpty) &&
        (selectedSousCategorieFilter == null || selectedSousCategorieFilter!.isEmpty) &&
        (selectedEtatFilter == null || selectedEtatFilter!.isEmpty) &&
        (selectedMarqueFilter == null || selectedMarqueFilter!.isEmpty) &&
        prixAchatMin == null &&
        prixAchatMax == null &&
        prixVenteMin == null &&
        prixVenteMax == null &&
        _searchController.text.isEmpty) {
      produitsFiltres = produitsTest;
    }
  }

  void appliquefiltrePack() {
    final searchText = _searchControllerPack.text.toLowerCase();
    if (searchText.isEmpty) {
      packsFiltres = packsTest;
      return;
    }
    packsFiltres = packsTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreRemise() {
    final searchText = _searchControllerRemise.text.toLowerCase();
    if (searchText.isEmpty) {
      remiseFiltres = remisesTest; // Créer une nouvelle liste
      return;
    }
    remiseFiltres = remisesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreCatgorie() {
    final searchText = _searchControllerCategorie.text.toLowerCase();
    if (searchText.isEmpty) {
      categoriesFiltres = categoriesTest;
      return;
    }
    categoriesFiltres = categoriesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreSousCatgorie() {
    final searchText = _searchControllerSousCategorie.text.toLowerCase();
    if (searchText.isEmpty) {
      souscategoriesFiltres = sousCategoriesTest;
      return;
    }
    souscategoriesFiltres = sousCategoriesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void supprimerFilter() {
    selectedCategorieFilter = null;
    selectedSousCategorieFilter = null;
    selectedMarqueFilter = null;
    selectedEtatFilter = null;
    prixAchatMin = null;
    prixAchatMax = null;
    prixVenteMin = null;
    prixVenteMax = null;
    _searchController.clear();
  }

  void vider_les_liste_selectionne() {
    categoriesSelectionnes.clear();
    souscategoriesSelectionnes.clear();
    remisesSelectionnes.clear();
    packsSelectionnes.clear();
    produitsSelectionnes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    if (actionButtons.isEmpty) {
      _initActionButtons(l10n, translator);
    }

    // ✅ Noms des tabs
    final tabNames = [
      l10n.produit,
      l10n.categorie,
      l10n.sousCategorie,
      l10n.remise,
      l10n.pack,
      l10n.parametre,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/produit_icon.png',
      'assets/icons/cardwidget/categorie_icon.png',
      'assets/icons/cardwidget/sous_catego_icon.png',
      'assets/icons/cardwidget/remise_icon.png',
      'assets/icons/cardwidget/pack_icon.png',
      'assets/icons/sidebar/parametre_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_produit,
      nombre_categorie,
      nombre_sous_categorie,
      nombre_remise,
      nombre_pack,
      '', // Pas de compteur pour paramètre
    ];

    // ✅ Map index vers actionButtons
    final Map<int, int> actionIndexMap = {
      TAB_PRODUIT: 0,
      TAB_CATEGORIE: 1,
      TAB_SOUS_CATEGORIE: 4,
      TAB_REMISE: 2,
      TAB_PACK: 3,
      TAB_PARAMETRE: -1,
    };

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;
    final int actionIndex = currentTab == TAB_PARAMETRE ? -1 : actionIndexMap[currentTab]!;

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          const minHeight = Constant.minHeight;
          const minWidth = Constant.minWidth;

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
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              HeaderModule(
                                gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                child: Row(
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/icons/sidebar/produit_icon.png",
                                          width: 40,
                                          color: Appstyle.blueF,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "${l10n.produit} (${tabNames[currentTab]})",
                                          style: Appstyle.textXLB.copyWith(
                                            color: Appstyle.blueF,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
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
                              /// ✅ TAB BAR - Version avec largeur égale sans isScrollable
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
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double tabWidth = constraints.maxWidth / 6; // 6 tabs
                                    return TabBar(
                                      controller: _tabController,
                                      isScrollable: false,
                                      indicator: BoxDecoration(
                                        color: Appstyle.violet,
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
                                      tabs: List.generate(6, (index) {
                                        final isSelected = currentTab == index;
                                        return SizedBox(
                                          width: tabWidth,
                                          child: Tab(
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
                                            text: index == TAB_PARAMETRE
                                                ? tabNames[index]
                                                : "${tabNames[index]} (${tabCounts[index]})",
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: paddingV / 2),

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
// ═══════════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────
// 1. CAS PRODUIT (currentTab == TAB_PRODUIT)
// ──────────────────────────────────────────────────────────────
                              if (currentTab == TAB_PRODUIT)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficheur
                                    if (produitsSelectionnes.length == 1)
                                      AfficheurProduit(
                                        produit: produitsSelectionnes.first,
                                        onDetails: () {
                                          ProduitDetail(context, produitsSelectionnes.first);
                                        },
                                      )
                                    else
                                      AfficheurProduitsGlobalWidget(
                                        nombreProduits: produitsTest.length,
                                        nombreCategories: categoriesTest.length,
                                        nombrePacks: packsTest.length,
                                        nombreRemises: remisesTest.length,
                                        nombreSousCategories: sousCategoriesTest.length,
                                      ),

                                    SizedBox(height: paddingV),

                                    // Filtres & Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            MainButton(
                                              text: l10n.filter,
                                              textColor:Appstyle.violet ,
                                              iconColor: Appstyle.violet,
                                              color: Appstyle.Tblanc,
                                              icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
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
                                                await _exportCurrentModuleToExcel();
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
                                          children: [
                                            ...actionButtons[actionIndex].map(
                                                  (btn) => Padding(
                                                padding: EdgeInsets.only(right: paddingH / 5),
                                                child: MainIconButton(
                                                  color: btn['color'] as Color,
                                                  onPressed: btn['onPressed'] as void Function(),
                                                  imagePath: btn['icon'] as String,
                                                ),
                                              ),
                                            ),
                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await ProduitNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Filtres produit
                                    if (filtresActifs)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV),
                                        child: filtreproduit(setState, adjustedWidth, l10n, translator),
                                      ),

                                    if (!filtresActifs)
                                      SizedBox(height: paddingV / 2),

                                    // Tableau
                                    SizedBox(
                                      height: adjustedHeight * 0.72,
                                      child: TableauProduitAdvanced(
                                        key: ValueKey(produitsFiltres),
                                        produits: produitsFiltres,
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
// 2. CAS CATEGORIE (currentTab == TAB_CATEGORIE)
// ──────────────────────────────────────────────────────────────
                              else if (currentTab == TAB_CATEGORIE)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (categoriesSelectionnes.length == 1)
                                      AfficheurCategorie(
                                        categorie: categoriesSelectionnes.first,
                                        nombreSousCategories: sousCategoriesTest
                                            .where((sc) => sc.categorieNom == categoriesSelectionnes.first.nom)
                                            .length,
                                        onDetails: () {
                                          CategorieDetail(
                                            context,
                                            categoriesSelectionnes.first,
                                            nombreSousCategories: sousCategoriesTest
                                                .where((sc) => sc.categorieNom == categoriesSelectionnes.first.nom)
                                                .length,
                                          );
                                        },
                                      )
                                    else
                                      AfficheurProduitsGlobalWidget(
                                        nombreProduits: produitsTest.length,
                                        nombreCategories: categoriesTest.length,
                                        nombrePacks: packsTest.length,
                                        nombreRemises: remisesTest.length,
                                        nombreSousCategories: sousCategoriesTest.length,
                                      ),

                                    SizedBox(height: paddingV),

                                    Row(
                                      children: [
                                        filtrcategorie(setState, l10n),
                                        SizedBox(width: paddingH / 3),
                                        MainButton(
                                          text: l10n.extract,
                                          textColor:Colors.green ,
                                          iconColor: Colors.green,
                                          color: Appstyle.Tblanc,
                                          icon: Icons.download,
                                          onPressed: () async {
                                            await _exportCurrentModuleToExcel();
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
                                        const Spacer(),
                                        Row(
                                          children: [
                                            ...actionButtons[actionIndex].map(
                                                  (btn) => Padding(
                                                padding: EdgeInsets.only(right: paddingH / 5),
                                                child: MainIconButton(
                                                  color: btn['color'] as Color,
                                                  onPressed: btn['onPressed'] as void Function(),
                                                  imagePath: btn['icon'] as String,
                                                ),
                                              ),
                                            ),
                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await CategorieNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: paddingV / 2),

                                    SizedBox(
                                      height: adjustedHeight * 0.72,
                                      child: TableauCategorieAdvanced(
                                        key: ValueKey(categoriesFiltres),
                                        categories: categoriesFiltres,
                                        sousCategories: sousCategoriesTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            categoriesSelectionnes = selection;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )

// ──────────────────────────────────────────────────────────────
// 3. CAS SOUS CATEGORIE (currentTab == TAB_SOUS_CATEGORIE)
// ──────────────────────────────────────────────────────────────
                              else if (currentTab == TAB_SOUS_CATEGORIE)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (souscategoriesSelectionnes.length == 1)
                                        AfficheurSousCategorie(
                                          sousCategorie: souscategoriesSelectionnes.first,
                                          nombreProduits: produitsTest
                                              .where((p) => p.sousCategorie == souscategoriesSelectionnes.first.nom)
                                              .length,
                                          onDetails: () {
                                            SousCategorieDetail(
                                              context,
                                              souscategoriesSelectionnes.first,
                                              nombreProduits: produitsTest
                                                  .where((p) => p.sousCategorie == souscategoriesSelectionnes.first.nom)
                                                  .length,
                                            );
                                          },
                                        )
                                      else
                                        AfficheurProduitsGlobalWidget(
                                          nombreProduits: produitsTest.length,
                                          nombreCategories: categoriesTest.length,
                                          nombrePacks: packsTest.length,
                                          nombreRemises: remisesTest.length,
                                          nombreSousCategories: sousCategoriesTest.length,
                                        ),

                                      SizedBox(height: paddingV),

                                      Row(
                                        children: [
                                          filtresouscategorie(setState, l10n),
                                          SizedBox(width: paddingH / 3),
                                          MainButton(
                                            text: l10n.extract,
                                            textColor:Colors.green ,
                                            iconColor: Colors.green,
                                            color: Appstyle.Tblanc,
                                            icon: Icons.download,
                                            onPressed: () async {
                                              await _exportCurrentModuleToExcel();
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
                                          const Spacer(),
                                          Row(
                                            children: [
                                              ...actionButtons[actionIndex].map(
                                                    (btn) => Padding(
                                                  padding: EdgeInsets.only(right: paddingH / 5),
                                                  child: MainIconButton(
                                                    color: btn['color'] as Color,
                                                    onPressed: btn['onPressed'] as void Function(),
                                                    imagePath: btn['icon'] as String,
                                                  ),
                                                ),
                                              ),
                                              MainButton(
                                                text: l10n.newWord,
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  if (categoriesTest.length > 1) {
                                                    await SousCategorieNouveau(context);
                                                    await loadAllData();
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.sousCategorie,
                                                      message: l10n.needCategoryToCreateSubCategory,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: paddingV / 2),

                                      SizedBox(
                                        height: adjustedHeight * 0.72,
                                        child: TableauSousCategorieAdvanced(
                                          key: ValueKey(souscategoriesFiltres),
                                          sousCategories: souscategoriesFiltres,
                                          produits: produitsTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              souscategoriesSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

// ──────────────────────────────────────────────────────────────
// 4. CAS REMISE (currentTab == TAB_REMISE)
// ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_REMISE)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (remisesSelectionnes.length == 1)
                                          AfficheurRemise(
                                            remise: remisesSelectionnes.first,
                                            nombreProduits: produitsTest
                                                .where((p) => p.remise == remisesSelectionnes.first.nom)
                                                .length,
                                            onDetails: () {
                                              RemiseDetail(context, remisesSelectionnes.first);
                                            },
                                          )
                                        else
                                          AfficheurProduitsGlobalWidget(
                                            nombreProduits: produitsTest.length,
                                            nombreCategories: categoriesTest.length,
                                            nombrePacks: packsTest.length,
                                            nombreRemises: remisesTest.length,
                                            nombreSousCategories: sousCategoriesTest.length,
                                          ),

                                        SizedBox(height: paddingV),

                                        Row(
                                          children: [
                                            filtrremise(setState, l10n),
                                            SizedBox(width: paddingH / 3),
                                            MainButton(
                                              text: l10n.extract,
                                              textColor:Colors.green ,
                                              iconColor: Colors.green,
                                              color: Appstyle.Tblanc,
                                              icon: Icons.download,
                                              onPressed: () async {
                                                await _exportCurrentModuleToExcel();
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
                                            const Spacer(),
                                            Row(
                                              children: [
                                                ...actionButtons[actionIndex].map(
                                                      (btn) => Padding(
                                                    padding: EdgeInsets.only(right: paddingH / 5),
                                                    child: MainIconButton(
                                                      color: btn['color'] as Color,
                                                      onPressed: btn['onPressed'] as void Function(),
                                                      imagePath: btn['icon'] as String,
                                                    ),
                                                  ),
                                                ),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await RemiseNouveau(
                                                      context,
                                                      onSuccess: () async {
                                                        await loadAllData();
                                                        if (mounted) {
                                                          setState(() {
                                                            remiseFiltres = List.from(remisesTest);
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

                                        SizedBox(height: paddingV / 2),

                                        SizedBox(
                                          height: adjustedHeight * 0.72,
                                          child: TableauRemiseAdvanced(
                                            key: ValueKey(remiseFiltres),
                                            remises: remiseFiltres,
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                remisesSelectionnes = selection;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )

// ──────────────────────────────────────────────────────────────
// 5. CAS PACK (currentTab == TAB_PACK)
// ──────────────────────────────────────────────────────────────
                                  else if (currentTab == TAB_PACK)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (packsSelectionnes.length == 1)
                                            AfficheurPack(
                                              pack: packsSelectionnes.first,
                                              onDetails: () {
                                                PackDetail(context, packsSelectionnes.first);
                                              },
                                            )
                                          else
                                            AfficheurProduitsGlobalWidget(
                                              nombreProduits: produitsTest.length,
                                              nombreCategories: categoriesTest.length,
                                              nombrePacks: packsTest.length,
                                              nombreRemises: remisesTest.length,
                                              nombreSousCategories: sousCategoriesTest.length,
                                            ),

                                          SizedBox(height: paddingV),

                                          Row(
                                            children: [
                                              filtrepack(setState, l10n),
                                              SizedBox(width: paddingH / 3),
                                              MainButton(
                                                text: l10n.extract,
                                                textColor:Colors.green ,
                                                iconColor: Colors.green,
                                                color: Appstyle.Tblanc,
                                                icon: Icons.download,
                                                onPressed: () async {
                                                  await _exportCurrentModuleToExcel();
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
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  ...actionButtons[actionIndex].map(
                                                        (btn) => Padding(
                                                      padding: EdgeInsets.only(right: paddingH / 5),
                                                      child: MainIconButton(
                                                        color: btn['color'] as Color,
                                                        onPressed: btn['onPressed'] as void Function(),
                                                        imagePath: btn['icon'] as String,
                                                      ),
                                                    ),
                                                  ),
                                                  MainButton(
                                                    text: l10n.newWord,
                                                    color: Appstyle.crevete,
                                                    onPressed: () async {
                                                      await PackNouveau(context);
                                                      await loadAllData();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: paddingV / 2),

                                          SizedBox(
                                            height: adjustedHeight * 0.72,
                                            child: TableauPackAdvanced(
                                              key: ValueKey(packsFiltres),
                                              packs: packsFiltres,
                                              onSelectionChanged: (selection) {
                                                setState(() {
                                                  packsSelectionnes = selection;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )

// ──────────────────────────────────────────────────────────────
// 6. CAS PARAMETRE (currentTab == TAB_PARAMETRE)
// ──────────────────────────────────────────────────────────────
                                    else if (currentTab == TAB_PARAMETRE)
                                        Container(
                                          padding: EdgeInsets.all(16),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              // Margin Section
                                              Container(
                                                width: adjustedWidth * 0.35,
                                                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Appstyle.Tblanc,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      l10n.margin,
                                                      style: Appstyle.textMB.copyWith(color: Appstyle.Tnoir),
                                                    ),
                                                    SizedBox(height: 20),
                                                    SizedBox(
                                                      width: 400,
                                                      child: ChampAvecLabel(
                                                        label: l10n.typeCalcul,
                                                        key: ValueKey(selectedtypecacul),  // ✅ Force la reconstruction
                                                        child: TextListe(
                                                          clearable: false,
                                                          value: selectedtypecacul,
                                                          items: translator.typeCalculDisplayList,
                                                          onChanged: (v) {
                                                            setState(() {
                                                              selectedtypecacul = v.toString();
                                                              tauxController.text = selectedtypecacul == translator.translateTypeCalcul("Pourcentage")
                                                                  ? ParamtersDB.TauxMargePerncetage.toString()
                                                                  : ParamtersDB.TauxMargeMontant.toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    Row(
                                                      children: [
                                                        SizedBox(
                                                          width: 400,
                                                          child: ChampAvecLabel(
                                                            label: l10n.marginRate,
                                                            child: TextChampL(
                                                              maxValue: selectedtypecacul == translator.translateTypeCalcul("Pourcentage") ? 100 : null,
                                                              controller: tauxController,
                                                              hint: selectedtypecacul == translator.translateTypeCalcul("Pourcentage")
                                                                  ? ParamtersDB.TauxMargePerncetage.toString()
                                                                  : ParamtersDB.TauxMargeMontant.toString(),
                                                              numeric: true,
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 10),
                                                        Text(
                                                          selectedtypecacul == translator.translateTypeCalcul("Pourcentage") ? "%" : l10n.currency,
                                                          style: Appstyle.textMB.copyWith(
                                                            color: Appstyle.violet,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 20),

                                              // Threshold Section
                                              Container(
                                                width: adjustedWidth * 0.35,
                                                padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                                decoration: BoxDecoration(
                                                  color: Appstyle.Tblanc,
                                                  borderRadius: BorderRadius.circular(14),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(
                                                      l10n.threshold,
                                                      style: Appstyle.textMB.copyWith(color: Appstyle.Tnoir),
                                                    ),
                                                    SizedBox(height: 20),
                                                    SizedBox(
                                                      width: 400,
                                                      child: ChampAvecLabel(
                                                        label: l10n.minimum,
                                                        child: TextChampL(
                                                          controller: minController,
                                                          hint: ParamtersDB.Minimum.toString(),
                                                          numeric: true,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(height: 20),
                                                    SizedBox(
                                                      width: 400,
                                                      child: ChampAvecLabel(
                                                        label: l10n.maximum,
                                                        child: TextChampL(
                                                          controller: maxController,
                                                          hint: ParamtersDB.Maximum.toString(),
                                                          numeric: true,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(height: 20),

                                              // Save Button
                                              Align(
                                                alignment: Alignment.centerLeft,
                                                child: MainButton(
                                                  text: l10n.save,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await _saveParam(l10n, translator);
                                                    await loadAllData();
                                                  },
                                                  iconOnRight: true,
                                                  icon: Icons.save,
                                                ),
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
    );
  }
  Widget filtreproduit(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator) {
    List<String> marqueFilterOptions = produitsTest.map((p) => p.marque).toSet().toList();

    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.categorie,
                  child: TextListe(
                    value: selectedCategorieFilter ?? "",
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
                    items: sousCategorieFilterOptions.where((sc) {
                      if (selectedCategorieFilter == null) return true;
                      return sousCategoriesTest.firstWhere((s) => s.nom == sc).categorieNom == selectedCategorieFilter;
                    }).toList(),
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
          Row(
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
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilter != null ? translator.translateEtat(selectedEtatFilter!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilter = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: width * 0.305,
            child: Row(
              children: [
                Expanded(
                  child: ChampAvecLabel(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget filtrepack(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerPack,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltrePack();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtrremise(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerRemise,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreRemise();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtrcategorie(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(

          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerCategorie,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreCatgorie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtresouscategorie(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerSousCategorie,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreSousCatgorie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}