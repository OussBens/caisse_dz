import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';

import 'package:caisse_dz/core/dialog/retour/retour_detail.dart';

import 'package:caisse_dz/core/dialog/retour/retour_nouveau.dart';
import 'package:caisse_dz/core/dialog/retour/retour_actif.dart';
import 'package:caisse_dz/core/dialog/retour/retour_modif.dart';

import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/tableau/retour/tableau_retour.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';

import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_stock_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_retour.dart';

import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

import 'package:caisse_dz/core/widget/card/card_widget.dart';

import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';

import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';

import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/l10n/app_localizations.dart';

import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';

String? selectedEtatFilterR;

String? selectedTypeFilterRetour;
String? selectedClientFilterRetour;
String? selectedFournisseurFilterRetour;
String? selectedProduitFilterRetour;

List<Produit>           besoinsTest           = [];
List<Retour>            retoursTest           = [];
List<Client>            clientsTest           = [];
List<Fournisseur>       fournisseursTest      = [];
List<Produit>           produitsTest          = [];
List<Utilisateur>       utilisateursTest      = [];

List<Retour>      retoursSelectionnes     = [];

class RetourScreen extends StatefulWidget {
  const RetourScreen({super.key});
  @override
  State<RetourScreen> createState() => _RetourScreenState();
}

class _RetourScreenState extends State<RetourScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_CLIENT = 0;
  static const int TAB_FOURNISSEUR = 1;

  // Period keys for translation lookup
  final List<String> periodeKeys = [
    "today",
    "yesterday",
    "week",
    "lastWeek",
    "month",
    "lastMonth",
    "last7days",
    "last30days",
    "year",
    "lastYear",
  ];

  List<String> FournisseurFilterOptions   = [];
  List<String> TypeRetourFilterOptions    = [];
  List<String> ProduitFilterOptions       = [];
  List<String> ClientFilterOptions        = [];
  double seuilMinimum                     = 0;

  Future<void> loadAllData() async {
    final test = await ProduitServices.getAllProduits();
    final fournisseurs      = await FournisseurServices.getAllFournisseurs();
    final produits          = await ProduitServices.getAllProduits();
    final retours           = await RetourServices.getAllRetour();
    final clients           = await ClientServices.getAllClients();
    final param              = await ParamServices.getParam();
    final utilisateurs      = await UtilisateurServices.getAllUtilisateurs();
    // ✅ Quantités calculées depuis le journal des mouvements — remplace Produit.quantite.
    final quantitesTest = (await MouvementsServices.totauxParProduit()).quantites;

    setState(() {
      fournisseursTest      = fournisseurs;
      produitsTest          = produits;
      retoursTest           = retours;
      clientsTest           = clients;
      utilisateursTest      = utilisateurs;
      retourFiltres     = retoursTest;
      seuilMinimum          = param.Minimum;

      FournisseurFilterOptions   = fournisseursTest.map    ((sc) => sc.nom). toSet().toList();
      TypeRetourFilterOptions    = retoursTest.map         ((c)  => c.type). toSet().toList();
      ProduitFilterOptions       = produitsTest.map        ((c)  => c.nom).  toSet().toList();
      ClientFilterOptions        = clientsTest.map         ((c)  => c.nom).  toSet().toList();
      besoinsTest = test
          .where((e) => (quantitesTest[e.code] ?? 0) <= param.Minimum)
          .toList();

      retoursSelectionnes.clear();
    });
  }

  // Excel Export Methods
  Future<void> _exportCurrentModuleToExcel() async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      final retoursToExport = filtresActifs ? retourFiltres : retoursTest;

      if (retoursToExport.isEmpty) {
        Navigator.pop(context);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.retour,
          message: l10n.noDataToExport,
        );
        return;
      }

      final excelFile = await ExcelGenerator.generateRetoursExcel(
        retours: retoursToExport,
        l10n: l10n,
        translator: translator,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Retours'];

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
            title: l10n.retour,
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

    try {
      if (retoursSelectionnes.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.retour,
          message: l10n.noProductSelected,
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final excelFile = await ExcelGenerator.generateRetoursExcel(
        retours: retoursSelectionnes,
        l10n: l10n,
        translator: translator,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Retours'];

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
            title: "${l10n.retour} (${l10n.selected})",
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

  DateTime? dateDebutRetour;
  DateTime? dateFinRetour;
  final TextEditingController _dateDebutCtrlRetour  = TextEditingController();
  final TextEditingController _dateFinCtrlRetour    = TextEditingController();

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

  final TextEditingController _searchControllerRetour     = TextEditingController();

  String nombre_retour          = "18";

  List<Retour>      retourFiltres     = [];

  @override
  String _formatDate(DateTime d) {
    return  "${d.day  .toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          vider_selectionne();
          // Le filtre Client/Fournisseur affiché dépend de l'onglet actif :
          // on efface celui de l'onglet qu'on quitte pour éviter qu'il masque
          // silencieusement les résultats de l'onglet qu'on rejoint.
          if (_tabController.index == TAB_CLIENT) {
            selectedFournisseurFilterRetour = null;
          } else {
            selectedClientFilterRetour = null;
          }
          appliquerFiltreRetour();
        });
      }
    });
    loadAllData().then((_) {
      if (mounted) {
        setState(() {
          retourFiltres     = retoursTest;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void appliquerFiltreRetour() {
    retourFiltres = retoursTest.where((p) {
      final searchText      = _searchControllerRetour.text.toLowerCase();
      final clientOk        = selectedClientFilterRetour      == null || selectedClientFilterRetour!.isEmpty      || clientsTest.any((c) => c.code == p.client_code && c.nom == selectedClientFilterRetour);
      final fournissemoveOk = selectedFournisseurFilterRetour == null || selectedFournisseurFilterRetour!.isEmpty || fournisseursTest.any((f) => f.code == p.fournisseur_code && f.nom == selectedFournisseurFilterRetour);
      final typeOk          = selectedTypeFilterRetour        == null || selectedTypeFilterRetour!.isEmpty        || p.type         == selectedTypeFilterRetour;
      final produitmoveOk   = selectedProduitFilterRetour     == null || selectedProduitFilterRetour!.isEmpty     || produitsTest.any((pr) => pr.code == p.codeProduit && pr.nom == selectedProduitFilterRetour);

      final searchOk =
          searchText.isEmpty ||
              p.searchableText.contains(searchText);
      final etatOk =
          selectedEtatFilterR == null ||
              selectedEtatFilterR == "" ||
              (selectedEtatFilterR == "Actif" && p.etat) ||
              (selectedEtatFilterR == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebutRetour == null && dateFinRetour  == null) return true;

        final d = p.dateCree;

        final debut = dateDebutRetour  != null
            ? DateTime(dateDebutRetour !.year, dateDebutRetour !.month, dateDebutRetour !.day)
            : null;

        final fin = dateFinRetour  != null
            ? DateTime(dateFinRetour !.year, dateFinRetour !.month, dateFinRetour !.day, 23, 59, 59)
            : null;

        if (debut != null && d.isBefore(debut)) return false;
        if (fin   != null && d.isAfter(fin)) return false;

        return true;
      }();

      return clientOk && fournissemoveOk && produitmoveOk && etatOk && searchOk && typeOk && dateOk;
    }).toList();

    if ((selectedClientFilterRetour       == null || selectedClientFilterRetour !.isEmpty) &&
        (selectedTypeFilterRetour         == null || selectedTypeFilterRetour!.isEmpty) &&
        (selectedFournisseurFilterRetour  == null || selectedFournisseurFilterRetour !.isEmpty) &&
        (selectedProduitFilterRetour      == null || selectedProduitFilterRetour !.isEmpty) &&
        (selectedEtatFilterR == null || selectedEtatFilterR!.isEmpty) &&
        dateDebutRetour   == null &&
        dateFinRetour     == null &&
        _searchControllerRetour.text.isEmpty) {
      retourFiltres = retoursTest;
    }
  }

  void _appliquerPeriodeRapideRetour(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebutRetour = DateTime(now.year, now.month, now.day);
        dateFinRetour = dateDebutRetour;
        break;
      case "yesterday":
        dateDebutRetour = DateTime(now.year, now.month, now.day - 1);
        dateFinRetour = dateDebutRetour;
        break;
      case "week":
        dateDebutRetour = now.subtract(Duration(days: now.weekday - 1));
        dateFinRetour = dateDebutRetour!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebutRetour = now.subtract(Duration(days: now.weekday + 6));
        dateFinRetour = dateDebutRetour!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebutRetour = DateTime(now.year, now.month, 1);
        dateFinRetour = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebutRetour = DateTime(now.year, now.month - 1, 1);
        dateFinRetour = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebutRetour = now.subtract(const Duration(days: 6));
        dateFinRetour = now;
        break;
      case "last30days":
        dateDebutRetour = now.subtract(const Duration(days: 29));
        dateFinRetour = now;
        break;
      case "year":
        dateDebutRetour = DateTime(now.year, 1, 1);
        dateFinRetour = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebutRetour = DateTime(now.year - 1, 1, 1);
        dateFinRetour = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlRetour.text = _formatDate(dateDebutRetour!);
    _dateFinCtrlRetour.text = _formatDate(dateFinRetour!);

    appliquerFiltreRetour();
  }

  // ✅ Vrai si au moins un champ de filtre retour est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresRetourActifs =>
      (selectedClientFilterRetour != null && selectedClientFilterRetour!.isNotEmpty) ||
      (selectedFournisseurFilterRetour != null && selectedFournisseurFilterRetour!.isNotEmpty) ||
      (selectedProduitFilterRetour != null && selectedProduitFilterRetour!.isNotEmpty) ||
      (selectedEtatFilterR != null && selectedEtatFilterR!.isNotEmpty) ||
      dateDebutRetour != null ||
      dateFinRetour != null ||
      _searchControllerRetour.text.isNotEmpty;

  void supprimerFilterRetour() {
    selectedClientFilterRetour = null;
    selectedTypeFilterRetour= null;
    selectedFournisseurFilterRetour = null;
    selectedProduitFilterRetour = null;
    selectedEtatFilterR=null;
    dateDebutRetour  = null;
    dateFinRetour  = null;
    periodeRapide = null;
    _dateDebutCtrlRetour.clear();
    _dateFinCtrlRetour.clear();
    _searchControllerRetour.clear();
  }

  void vider_selectionne() {
    retoursSelectionnes.clear();
  }

  Future<void> _pickDateDebutRetour() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutRetour  ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebutRetour  = picked;
        _dateDebutCtrlRetour .text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreRetour();
      });
    }
  }

  Future<void> _pickDateFinRetour() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinRetour ?? dateDebutRetour  ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinRetour  = picked;

        if (dateDebutRetour  != null && picked.isBefore(dateDebutRetour !)) {
          dateFinRetour  = dateDebutRetour;
        }

        _dateFinCtrlRetour .text = _formatDate(dateFinRetour !);
        periodeRapide = null;
        appliquerFiltreRetour ();
      });
    }
  }

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

    // ✅ Noms/compteurs/icônes des tabs
    final tabNames = [l10n.client, l10n.fournisseur];
    final tabIcons = [
      "assets/icons/sidebar/client_icon.png",
      "assets/icons/sidebar/fournisseur_icon.png",
    ];
    final tabCounts = [
      retoursTest.where((r) => r.type == 'Client').length,
      retoursTest.where((r) => r.type == 'Fournisseur').length,
    ];

    // ✅ Retours de l'onglet actif (mêmes retours filtrés, restreints au type
    // du tab courant — une seule table sous-jacente, deux vues)
    final retourFiltresOngletActif = retourFiltres
        .where((r) => r.type == (currentTab == TAB_CLIENT ? 'Client' : 'Fournisseur'))
        .toList();

    // ✅ Indigo sur le 2e onglet (Fournisseur), violet sur le 1er (Client) —
    // texte du header, indicateur du TabBar et en-tête du tableau.
    final Color couleurOngletActif = currentTab == TAB_FOURNISSEUR ? Appstyle.indigo : Appstyle.violet;

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
                      child: Row(
                        textDirection: textDirection,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SideBarWidget(),
                          Expanded(
                            child: SingleChildScrollView(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                  children: [
                                    /// HEADER
                                    HeaderModule(
                                      gradientColors: [Appstyle.Tblanc,Appstyle.Tblanc],
                                      child: Row(
                                        textDirection: textDirection,
                                        children: [
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              Image.asset(
                                                "assets/icons/cardwidget/retour_icon.png",
                                                width: 40,
                                                color: Appstyle.violet,
                                              ),
                                              const SizedBox(width: 10),
                                              Row(
                                                textDirection: textDirection,
                                                children: [
                                                  Text(
                                                    l10n.retour,
                                                    style: Appstyle.textXLB.copyWith(
                                                      color       : Appstyle.violet,
                                                      fontWeight  : FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 15),
                                                  Text(
                                                    "(${tabNames[currentTab]})",
                                                    style: Appstyle.textXLB.copyWith(
                                                      color       : couleurOngletActif,
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

                                    /// ✅ TAB BAR (Retour client / Retour fournisseur)
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
                                          color: couleurOngletActif,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        labelColor: Colors.white,
                                        unselectedLabelColor: Appstyle.gris,
                                        dividerColor: Colors.transparent,
                                        indicatorSize: TabBarIndicatorSize.tab,
                                        padding: const EdgeInsets.all(6),
                                        labelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w600),
                                        unselectedLabelStyle: Appstyle.textXS.copyWith(fontWeight: FontWeight.w500),
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

                                    // Afficheur
                                    if (retoursSelectionnes.length==1)
                                      AfficheurRetour(
                                          retour: retoursSelectionnes.first,
                                          onDetails:() {
                                            RetourDetail(context,retoursSelectionnes.first);
                                          }
                                      ),

                                    if (retoursSelectionnes.length == 1)
                                      SizedBox(height: paddingV/2),

                                    if (retoursSelectionnes.length != 1)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16.0),
                                        child: AfficheurStockGlobalWidget(
                                          nombreBesoinList    : 10,
                                          nombrePanniers      : 15,
                                          nombreProduitsStock : produitsTest.length,
                                          nombreRetours       : retoursTest.length,
                                          nombreSmartScan     : 22,
                                          nombreSorties       : 01,
                                        ),
                                      ),

                                    // +ActionButton +SearchField
                                    Align(
                                      alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                      child: Row(
                                        textDirection: textDirection,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          //Button afficher et masquer les filter
                                          Row(
                                            textDirection: textDirection,
                                            children: [
                                              MainButton(
                                                text: l10n.filter,
                                                textColor: Appstyle.violet,
                                                color: Appstyle.Tblanc,
                                                showBadge: _filtresRetourActifs,
                                                icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                iconColor:Appstyle.violet ,
                                                onPressed: () {
                                                  setState(() {
                                                    filtresActifs = !filtresActifs;
                                                    if (!filtresActifs) {
                                                      supprimerFilterRetour();
                                                      appliquerFiltreRetour();
                                                    }
                                                  });
                                                },
                                              ),
                                              SizedBox(width: paddingH/4),
                                              if (filtresActifs) MainIconButton(
                                                color: Colors.grey.shade400,
                                                imagePath: 'assets/icons/action/supprimer_icon.png',
                                                onPressed: () {
                                                  setState(() {
                                                    supprimerFilterRetour();
                                                    appliquerFiltreRetour();
                                                  });
                                                },
                                              ),

                                              if (filtresActifs)
                                                SizedBox(width: paddingH/4),

                                              // EXTRACT ALL Button
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
                                              // EXTRACT SELECTED Button
                                              MainIconButton(
                                                imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                color: Colors.orange,
                                                onPressed: () async {
                                                  await _exportSelectedToExcel();
                                                },
                                              ),

                                            ],
                                          ),

                                          // ---------------------- ACTIONS
                                          Row(
                                            textDirection: textDirection,
                                            mainAxisAlignment: MainAxisAlignment.end,
                                            children: [
                                              // Detail
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async{
                                                    if (retoursSelectionnes.length==1) {
                                                      RetourDetail(context,retoursSelectionnes.first);
                                                    } else if (retoursSelectionnes.isEmpty){
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.retour,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.retour,
                                                        message: l10n.selectSingleProductForDetail,
                                                      );
                                                    }
                                                  },
                                                ),

                                              SizedBox(width: paddingH / 4),

                                              // supprimer button
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/supprimer_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed : () async {
                                                    if (retoursSelectionnes.isNotEmpty) {
                                                      await AnnulerRetour(
                                                        context,
                                                        retoursSelectionnes,
                                                      );
                                                      await loadAllData();
                                                    } else if (retoursSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.retour,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    }
                                                  },
                                                ),

                                                SizedBox(width: paddingH / 4),

                                              // modifier button
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async{
                                                    if (retoursSelectionnes.length == 1) {
                                                      await RetourModif(
                                                        context,
                                                        retoursSelectionnes.first,
                                                      );
                                                      await loadAllData();
                                                    } else if (retoursSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.retour,
                                                        message: l10n.noProductSelected,
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.retour,
                                                        message: l10n.selectSingleProductToModify,
                                                      );
                                                    }
                                                  },
                                                ),

                                              SizedBox(width: paddingH / 4),

                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await RetourNouveau(
                                                      context,
                                                      initialType: currentTab == TAB_CLIENT ? 'Client' : 'Fournisseur',
                                                    );
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

                                    //filters
                                    if (filtresActifs)
                                      Align(
                                        alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                        child: Padding(
                                          padding: EdgeInsets.symmetric(vertical: paddingV/2),
                                          child: Column(
                                            children: [
                                              filtreRetour(setState, adjustedWidth*1/3, l10n, translator, isRTL, currentTab),
                                            ],
                                          ),
                                        ),
                                      ),

                                    // TableauRetour avec callback de sélection — même table sous-jacente,
                                    // restreinte au type (Client/Fournisseur) de l'onglet actif, avec les
                                    // colonnes non pertinentes masquées.
                                    SizedBox(
                                      height: adjustedHeight * 0.68,
                                      child: TableauRetourAdvanced(
                                        key: ValueKey('$currentTab-${retourFiltresOngletActif.length}'),
                                        retours: retourFiltresOngletActif,
                                        produits: produitsTest,
                                        clients: clientsTest,
                                        fournisseurs: fournisseursTest,
                                        utilisateurs: utilisateursTest,
                                        colonnesMasquees: currentTab == TAB_CLIENT
                                            ? const {'type', 'fournisseur'}
                                            : const {'type', 'client'},
                                        headerColor: couleurOngletActif,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            retoursSelectionnes = selection;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                ),
            );
          },
        ),
      ),
    );
  }

  Widget filtreRetour(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL, int currentTab) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;
    final bool estOngletClient = currentTab == TAB_CLIENT;

    return SectionDecorationFiltre(
        padding: EdgeInsets.all(10),
        color: Appstyle.Tblanc,
        child: Column(
          crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Ligne 1 : le filtre Client (onglet Client) ou Fournisseur (onglet
            // Fournisseur) — jamais les deux — avec Produit et État à côté.
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: estOngletClient
                      ? ChampAvecLabel(
                          label: l10n.client,
                          child: TextListe(
                            value: selectedClientFilterRetour,
                            items: ClientFilterOptions,
                            onChanged: (v) {
                              setState(() {
                                selectedClientFilterRetour = v;
                                appliquerFiltreRetour();
                              });
                            },
                          ),
                        )
                      : ChampAvecLabel(
                          label: l10n.fournisseur,
                          child: TextListe(
                            value: selectedFournisseurFilterRetour,
                            items: FournisseurFilterOptions,
                            onChanged: (v) {
                              setState(() {
                                selectedFournisseurFilterRetour = v;
                                appliquerFiltreRetour();
                              });
                            },
                          ),
                        ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.produit,
                    child: TextListe(
                      value: selectedProduitFilterRetour,
                      items: ProduitFilterOptions,
                      onChanged: (v) {
                        setState(() {
                          selectedProduitFilterRetour = v;
                          appliquerFiltreRetour();
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
                      value: selectedEtatFilterR != null ? translator.translateEtat(selectedEtatFilterR!) : null,
                      items: translator.etatDisplayList,
                      onChanged: (v) {
                        setState(() {
                          selectedEtatFilterR = translator.etatToFrench(v!);
                          appliquerFiltreRetour();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              textDirection: textDirection,
              children: [
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.from,
                    child: TextDate(
                      hint: l10n.startDate,
                      controller: _dateDebutCtrlRetour,
                      onTap: _pickDateDebutRetour,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.to,
                    child: TextDate(
                      hint: l10n.endDate,
                      enabled: dateDebutRetour != null,
                      controller: _dateFinCtrlRetour,
                      onTap: _pickDateFinRetour,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                SizedBox(
                  width: width * 0.7,
                  child: ChampAvecLabel(
                    label: l10n.quickPeriod,
                    child: DropdownButtonFormField<String>(
                      value: periodeRapide,
                      decoration: InputDecoration(
                        hintText: l10n.choosePeriod,
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: periodeKeys.map((key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(_getPeriodeDisplayName(key, l10n)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            periodeRapide = v;
                            _appliquerPeriodeRapideRetour(v, l10n);
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
              textDirection: textDirection,
              children: [
                SizedBox(
                  width: width * 0.7,
                  child: ChampAvecLabel(
                    label: l10n.search,
                    child: SearchField(
                      controller: _searchControllerRetour,
                      onChanged: (v) {
                        setState(() {
                          appliquerFiltreRetour();
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        )
    );
  }
}