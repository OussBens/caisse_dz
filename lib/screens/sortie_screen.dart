import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/StatistiquesGlobales.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'dart:io';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_detail.dart';

import 'package:caisse_dz/core/dialog/sortie/sortie_nouveau.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_actif.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_modif.dart';

import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/tableau/pannier/tableau_pannier.dart';
import 'package:caisse_dz/core/tableau/sortie/tableau_sortie.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';

import 'package:caisse_dz/core/widget/account.dart';

import 'package:caisse_dz/core/widget/afficheur/afficheur_stock_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pannier.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_sortie.dart';

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

import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/sortie.dart';

import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';

String? selectedEtatFilterP;
String? selectedEtatFilterSrt;

String? selectedTypeSortieFilter;
String? selectedProduitSortieFilter;

String? selectedClientFilterSCsortie;
String? modepaiementFilterSCsortie;
String? typepannierFilterSCsortie;

String? selectedClientFilter;
String? selectedProduitFilter;

List<Client>  clientsTest   = [];
List<Produit> produitsTest  = [];
List<Pannier> paniersTest   = [];
List<Verssement> versementsTest = [];
Map<String, double> verseParPannier = {};
Map<String, int> nbrVersementParPannier = {};
List<Sortie>  sortieTest    = [];
List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];
List<Utilisateur> utilisateursTest = [];

List<Sortie> sortiesSelectionnes    = [];
List<Pannier> panniersSelectionnes  = [];

class SortieScreen extends StatefulWidget {
  const SortieScreen({super.key});
  @override
  State<SortieScreen> createState() => _SortieScreenState();
}

class _SortieScreenState extends State<SortieScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_PANIER = 0;
  static const int TAB_SORTIE = 1;

  // Period keys for translation lookup

  List<String> ProduitFilterOptions = [];
  List<String> ClientFilterOptions  = [];
  Set<String> panniersAvecRetour = {};

  // Cards globales (AfficheurStockGlobalWidget) : vrais compteurs, voir
  // StatistiquesGlobalesServices.
  CompteursGlobaux compteursGlobaux = const CompteursGlobaux();

  Future<void> loadAllData() async {
    final magasinsConsultation = Provider.of<AuthState>(context, listen: false).magasinsConsultation;
    final test = await ProduitServices.getAllProduits();

    final produits  = await ProduitServices .getAllProduits();
    final paniers   = await PannierServices .getAllPanniers();
    final versements = await VerssementServices.getAllverssement();
    final clients   = await ClientServices  .getAllClients();
    final sorties   = await SortieServices  .getAllSortie();
    final categories       = await CategorieServices.getAllCategorie();
    final sousCategories   = await SousCategoriesServices.getAllSousCategorie();

    final retours = await RetourServices.getAllRetour();
    final utilisateurs = await UtilisateurServices.getAllUtilisateurs();

    final compteurs = await StatistiquesGlobalesServices.getCompteurs(magasinsConsultation: magasinsConsultation);
    if (!mounted) return;
    setState(() {
      compteursGlobaux = compteurs;
      produitsTest = produits;
      paniersTest = paniers;
      versementsTest = versements;
      utilisateursTest = utilisateurs;
      verseParPannier = PannierServices.verseParPannier(versements);
      nbrVersementParPannier = PannierServices.nbrVersementParPannier(versements);
      panniersAvecRetour = retours
          .where((r) => r.etat && r.type == "Client" && r.retourCorrespondDe != null)
          .map((r) => r.retourCorrespondDe!)
          .toSet();
      clientsTest = clients;
      sortieTest = sorties;
      categoriesTest = categories;
      sousCategoriesTest = sousCategories;
      pannierFiltres = paniersTest;
      sortielistFiltres = sortieTest;

      ProduitFilterOptions = produitsTest.map((c) => c.nom).toSet().toList();
      ClientFilterOptions = clientsTest.map((c) => c.nom).toSet().toList();

      // Mettre à jour les compteurs
      nombre_vente = paniersTest.length.toString();
      nombre_sortie = sortieTest.length.toString();

      sortiesSelectionnes.clear();
      panniersSelectionnes.clear();
    });
  }

  DateTime? dateDebuSortie;
  DateTime? dateFinSortie;
  final TextEditingController _dateDebutCtrlSortie = TextEditingController();
  final TextEditingController _dateFinCtrlSortie = TextEditingController();

  DateTime? dateDebutSCsortie;
  DateTime? dateFinSCsortie;
  final TextEditingController _dateDebutCtrlSCsortie = TextEditingController();
  final TextEditingController _dateFinCtrlSCsortie = TextEditingController();

  DateTime? dateDebut;
  DateTime? dateFin;
  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  late List<String> modepaiementFilterOptions = [];
  late List<String> modepannierFilterOptions = [];
  late List<String> modeSortieFilterOptions = [];

  double? montantMinSCsortie;
  double? montantMaxSCsortie;
  double? resteMinSCsortie;
  double? resteMaxSCsortie;

  double? quantiteMinBesion;
  double? quantiteMaxBesion;

  bool filtresActifs = false;
  // Garde anti-double-clic pour l'export Excel (voir client_screen.dart pour
  // le détail du bug évité).
  bool _exportEnCours = false;
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
  // Plus besoin de selectedCardIndex, on utilise _tabController.index

  final TextEditingController _searchControllerSCSortie = TextEditingController();
  final TextEditingController _searchControllerSortie = TextEditingController();

  String nombre_sortie = "25";
  String nombre_vente = "55";

  List<Sortie> sortielistFiltres = [];
  List<Pannier> pannierFiltres = [];

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
    _tabController.dispose();
    super.dispose();
  }

  void vider_selectionne() {
    sortiesSelectionnes.clear();
    panniersSelectionnes.clear();
  }

  // Excel Export Methods
  Future<void> _exportCurrentModuleToExcel({bool enPdf = false}) async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      // Determine which module is active
      if (currentTab == TAB_PANIER) {
        // Panniers (Sales/Ventes)
        final panniersToExport = filtresActifs ? pannierFiltres : paniersTest;

        if (panniersToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.panier,
            message: l10n.noDataToExport,
          );
          return;
        }

        final excelFile = await ExcelGenerator.generatePanniersExcel(
          panniers: panniersToExport,
          versements: versementsTest,
          l10n: l10n,
          translator: translator,
        );

        fermerSpinner();

        // Decode the Excel file to show preview
        // Extract PDF : même fichier que l'export Excel, mis en page en PDF.
        if (enPdf) {
          fermerSpinner();
          await ouvrirApercuPdfDepuisExcel(context, fichier: excelFile, titre: AppLocalizations.of(context)!.panier);
          return;
        }

        final excel = Excel.decodeBytes(await excelFile.readAsBytes());

        var sheet = excel.tables['Panniers'];

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
                backgroundColor: Appstyle.warning,
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
              title: l10n.panier,
              l10n: l10n,
              excelFile: excelFile,
              onSave: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.exportSuccess),
                    backgroundColor: Appstyle.success,
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
              backgroundColor: Appstyle.danger,
            ),
          );
        }
      } else {
        // Sorties
        final sortiesToExport = filtresActifs ? sortielistFiltres : sortieTest;

        if (sortiesToExport.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.sortie,
            message: l10n.noDataToExport,
          );
          return;
        }

        final excelFile = await ExcelGenerator.generateSortiesExcel(
          sorties: sortiesToExport,
          produits: produitsTest,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          l10n: l10n,
          translator: translator,
        );

        fermerSpinner();

        // Decode the Excel file to show preview
        // Extract PDF : même fichier que l'export Excel, mis en page en PDF.
        if (enPdf) {
          fermerSpinner();
          await ouvrirApercuPdfDepuisExcel(context, fichier: excelFile, titre: AppLocalizations.of(context)!.sortie);
          return;
        }

        final excel = Excel.decodeBytes(await excelFile.readAsBytes());

        var sheet = excel.tables['Sorties'];

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
              title: l10n.sortie,
              l10n: l10n,
              excelFile: excelFile,
              onSave: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.exportSuccess),
                    backgroundColor: Appstyle.success,
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
              backgroundColor: Appstyle.danger,
            ),
          );
        }
      }
    } catch (e) {
      fermerSpinner();

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Appstyle.danger,
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

      File? excelFile;

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      if (currentTab == TAB_PANIER) {
        // Panniers
        if (panniersSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.panier,
            message: l10n.noCartSelected,
          );
          return;
        }

        excelFile = await ExcelGenerator.generatePanniersExcel(
          panniers: panniersSelectionnes,
          versements: versementsTest,
          l10n: l10n,
          translator: translator,
        );
      } else {
        // Sorties
        if (sortiesSelectionnes.isEmpty) {
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.sortie,
            message: l10n.noProductSelected,
          );
          return;
        }

        excelFile = await ExcelGenerator.generateSortiesExcel(
          sorties: sortiesSelectionnes,
          produits: produitsTest,
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
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

      var sheet = excel.tables[currentTab == TAB_PANIER ? 'Panniers' : 'Sorties'];

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

        final moduleName = currentTab == TAB_PANIER ? l10n.panier : l10n.sortie;

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
                  backgroundColor: Appstyle.success,
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
            backgroundColor: Appstyle.danger,
          ),
        );
      }
    } catch (e) {
      fermerSpinner();

      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Appstyle.danger,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  @override
  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }



  // ✅ Vrai si au moins un champ de filtre sortie est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresSortieActifs =>
      (selectedTypeSortieFilter != null && selectedTypeSortieFilter!.isNotEmpty) ||
      (selectedProduitSortieFilter != null && selectedProduitSortieFilter!.isNotEmpty) ||
      (selectedEtatFilterSrt != null && selectedEtatFilterSrt!.isNotEmpty) ||
      dateDebuSortie != null ||
      dateFinSortie != null ||
      _searchControllerSortie.text.isNotEmpty;

  void appliquerFiltreSortie() {
    sortielistFiltres = sortieTest.where((p) {
      final searchText = _searchControllerSortie.text.toLowerCase();
      final nomProduitSortie = produitsTest.where((pr) => pr.code == p.produitCode).firstOrNull?.nom ?? '';
      final typesortieOk = selectedTypeSortieFilter == null || selectedTypeSortieFilter!.isEmpty || p.type == selectedTypeSortieFilter;
      final produitmoveOk = selectedProduitSortieFilter == null || selectedProduitSortieFilter!.isEmpty || nomProduitSortie == selectedProduitSortieFilter;
      final searchOk = searchText.isEmpty || '${p.searchableText} $nomProduitSortie'.toLowerCase().contains(searchText);
      final etatOk = selectedEtatFilterSrt == null ||
          selectedEtatFilterSrt == "" ||
          (selectedEtatFilterSrt == "Actif" && p.etat) ||
          (selectedEtatFilterSrt == "Inactif" && !p.etat);

      final dateOk = () {
        if (dateDebuSortie == null && dateFinSortie == null) return true;
        final d = p.dateCree;
        final debut = dateDebuSortie != null
            ? DateTime(dateDebuSortie!.year, dateDebuSortie!.month, dateDebuSortie!.day)
            : null;
        final fin = dateFinSortie != null
            ? DateTime(dateFinSortie!.year, dateFinSortie!.month, dateFinSortie!.day, 23, 59, 59)
            : null;
        if (debut != null && d.isBefore(debut)) return false;
        if (fin != null && d.isAfter(fin)) return false;
        return true;
      }();

      return typesortieOk && produitmoveOk && etatOk && searchOk && dateOk;
    }).toList();

    if ((selectedProduitSortieFilter == null || selectedProduitSortieFilter!.isEmpty) &&
        (selectedTypeSortieFilter == null || selectedTypeSortieFilter!.isEmpty) &&
        (selectedEtatFilterSrt == null || selectedEtatFilterSrt!.isEmpty) &&
        dateDebuSortie == null && dateFinSortie == null && _searchControllerSortie.text.isEmpty) {
      sortielistFiltres = sortieTest;
    }
  }

  // ✅ Vrai si au moins un champ de filtre panier (onglet SC) est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresSCsortieActifs =>
      (selectedClientFilterSCsortie != null && selectedClientFilterSCsortie!.isNotEmpty) ||
      (modepaiementFilterSCsortie != null && modepaiementFilterSCsortie!.isNotEmpty) ||
      (typepannierFilterSCsortie != null && typepannierFilterSCsortie!.isNotEmpty) ||
      (selectedEtatFilterP != null && selectedEtatFilterP!.isNotEmpty) ||
      montantMinSCsortie != null ||
      montantMaxSCsortie != null ||
      resteMinSCsortie != null ||
      resteMaxSCsortie != null ||
      dateDebut != null ||
      dateFin != null ||
      _searchControllerSCSortie.text.isNotEmpty;

  void appliquerFiltreSCsortie() {
    pannierFiltres = paniersTest.where((p) {
      final searchText = _searchControllerSCSortie.text.toLowerCase();
      final clientOk = selectedClientFilterSCsortie == null || selectedClientFilterSCsortie!.isEmpty || clientsTest.any((c) => c.code == p.client_code && c.nom == selectedClientFilterSCsortie);
      final modeOk = modepaiementFilterSCsortie == null || modepaiementFilterSCsortie!.isEmpty || p.modePaiement == modepaiementFilterSCsortie;
      final typeOk = typepannierFilterSCsortie == null || typepannierFilterSCsortie!.isEmpty || p.typepannier == typepannierFilterSCsortie;
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final montantOk = (montantMinSCsortie == null || p.montant >= montantMinSCsortie!) &&
          (montantMaxSCsortie == null || p.montant <= montantMaxSCsortie!);

      final reste = p.montant - (verseParPannier[p.code] ?? 0);
      final resteOk = (resteMinSCsortie == null || reste >= resteMinSCsortie!) &&
          (resteMaxSCsortie == null || reste <= resteMaxSCsortie!);

      final etatOk = selectedEtatFilterP == null ||
          selectedEtatFilterP == "" ||
          (selectedEtatFilterP == "Actif" && p.etat) ||
          (selectedEtatFilterP == "Inactif" && !p.etat);

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
        if (fin != null && d.isAfter(fin)) return false;
        return true;
      }();

      return clientOk && modeOk && montantOk && resteOk && etatOk && searchOk && typeOk && dateOk;
    }).toList();

    if ((selectedClientFilterSCsortie == null || selectedClientFilterSCsortie!.isEmpty) &&
        (modepaiementFilterSCsortie == null || modepaiementFilterSCsortie!.isEmpty) &&
        (typepannierFilterSCsortie == null || typepannierFilterSCsortie!.isEmpty) &&
        (selectedEtatFilterP == null || selectedEtatFilterP!.isEmpty) &&
        montantMinSCsortie == null &&
        montantMaxSCsortie == null &&
        resteMaxSCsortie == null &&
        resteMinSCsortie == null &&
        dateDebut == null &&
        dateFin == null &&
        _searchControllerSCSortie.text.isEmpty) {
      pannierFiltres = paniersTest;
    }
  }

  void _appliquerPeriodeRapideSCsortie(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebutSCsortie = DateTime(now.year, now.month, now.day);
        dateFinSCsortie = dateDebutSCsortie;
        break;
      case "yesterday":
        dateDebutSCsortie = DateTime(now.year, now.month, now.day - 1);
        dateFinSCsortie = dateDebutSCsortie;
        break;
      case "week":
        dateDebutSCsortie = now.subtract(Duration(days: now.weekday - 1));
        dateFinSCsortie = dateDebutSCsortie!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebutSCsortie = now.subtract(Duration(days: now.weekday + 6));
        dateFinSCsortie = dateDebutSCsortie!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebutSCsortie = DateTime(now.year, now.month, 1);
        dateFinSCsortie = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebutSCsortie = DateTime(now.year, now.month - 1, 1);
        dateFinSCsortie = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebutSCsortie = now.subtract(const Duration(days: 6));
        dateFinSCsortie = now;
        break;
      case "last30days":
        dateDebutSCsortie = now.subtract(const Duration(days: 29));
        dateFinSCsortie = now;
        break;
      case "year":
        dateDebutSCsortie = DateTime(now.year, 1, 1);
        dateFinSCsortie = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebutSCsortie = DateTime(now.year - 1, 1, 1);
        dateFinSCsortie = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlSCsortie.text = _formatDate(dateDebutSCsortie!);
    _dateFinCtrlSCsortie.text = _formatDate(dateFinSCsortie!);

    appliquerFiltreSCsortie();
  }

  void _appliquerPeriodeRapideSortie(String p, AppLocalizations l10n) {
    final now = DateTime.now();

    switch (p) {
      case "today":
        dateDebuSortie = DateTime(now.year, now.month, now.day);
        dateFinSortie = dateDebuSortie;
        break;
      case "yesterday":
        dateDebuSortie = DateTime(now.year, now.month, now.day - 1);
        dateFinSortie = dateDebuSortie;
        break;
      case "week":
        dateDebuSortie = now.subtract(Duration(days: now.weekday - 1));
        dateFinSortie = dateDebuSortie!.add(const Duration(days: 6));
        break;
      case "lastWeek":
        dateDebuSortie = now.subtract(Duration(days: now.weekday + 6));
        dateFinSortie = dateDebuSortie!.add(const Duration(days: 6));
        break;
      case "month":
        dateDebuSortie = DateTime(now.year, now.month, 1);
        dateFinSortie = DateTime(now.year, now.month + 1, 0);
        break;
      case "lastMonth":
        dateDebuSortie = DateTime(now.year, now.month - 1, 1);
        dateFinSortie = DateTime(now.year, now.month, 0);
        break;
      case "last7days":
        dateDebuSortie = now.subtract(const Duration(days: 6));
        dateFinSortie = now;
        break;
      case "last30days":
        dateDebuSortie = now.subtract(const Duration(days: 29));
        dateFinSortie = now;
        break;
      case "year":
        dateDebuSortie = DateTime(now.year, 1, 1);
        dateFinSortie = DateTime(now.year, 12, 31);
        break;
      case "lastYear":
        dateDebuSortie = DateTime(now.year - 1, 1, 1);
        dateFinSortie = DateTime(now.year - 1, 12, 31);
        break;
    }

    _dateDebutCtrlSortie.text = _formatDate(dateDebuSortie!);
    _dateFinCtrlSortie.text = _formatDate(dateFinSortie!);

    appliquerFiltreSortie();
  }

  void supprimerFilterSortie() {
    selectedTypeSortieFilter = null;
    selectedProduitSortieFilter = null;
    selectedEtatFilterSrt = null;
    _searchControllerSortie.clear();
    dateDebuSortie = null;
    dateFinSortie = null;
    _dateDebutCtrlSCsortie.clear();
    _dateFinCtrlSCsortie.clear();
  }

  void supprimerFilterSCsortie() {
    selectedClientFilter = null;
    modepaiementFilterSCsortie = null;
    typepannierFilterSCsortie = null;
    montantMaxSCsortie = null;
    montantMinSCsortie = null;
    resteMaxSCsortie = null;
    resteMinSCsortie = null;
    selectedEtatFilterP = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
    _searchControllerSCSortie.clear();
  }


  Future<void> _pickDateDebutSCsortie() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebutSCsortie ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebutSCsortie = picked;
        _dateDebutCtrlSCsortie.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreSCsortie();
      });
    }
  }

  Future<void> _pickDateFinSCsortie() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinSCsortie ?? dateDebutSCsortie ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinSCsortie = picked;
        if (dateDebutSCsortie != null && picked.isBefore(dateDebutSCsortie!)) {
          dateFinSCsortie = dateDebutSCsortie;
        }
        _dateFinCtrlSCsortie.text = _formatDate(dateFinSCsortie!);
        periodeRapide = null;
        appliquerFiltreSCsortie();
      });
    }
  }

  Future<void> _pickDateDebutSortie() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebuSortie ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateDebuSortie = picked;
        _dateDebutCtrlSortie.text = _formatDate(picked);
        periodeRapide = null;
        appliquerFiltreSortie();
      });
    }
  }

  Future<void> _pickDateFinSortie() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFinSortie ?? dateDebuSortie ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        dateFinSortie = picked;
        if (dateDebuSortie != null && picked.isBefore(dateDebuSortie!)) {
          dateFinSortie = dateDebuSortie;
        }
        _dateFinCtrlSortie.text = _formatDate(dateFinSortie!);
        periodeRapide = null;
        appliquerFiltreSortie();
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

    // Initialize filter options with translator
    modepaiementFilterOptions = translator.modePaiementDisplayList;
    modepannierFilterOptions = translator.typePannierDisplayList;
    modeSortieFilterOptions = translator.typeSortieDisplayList;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Couleur de l'en-tête alignée sur la couleur du tab actif
    final Color headerColor = currentTab == TAB_PANIER ?  Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.panier,   // "Vente" -> Cart/Basket
      l10n.sortie,   // "Exceptionnel" -> Exit/Output
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/cardwidget/scan_out_icon.png',
      'assets/icons/cardwidget/sortie_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_vente,
      nombre_sortie,
    ];

    // ✅ Couleurs des tabs
    final tabColors = [
      Appstyle.green2,
      Appstyle.gris,
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

            return Directionality(
              textDirection: textDirection,
              child: SingleChildScrollView(
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
                                              "assets/icons/sidebar/sortie_icon.png",
                                              width: 40,
                                              color: headerColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                Text(
                                                  l10n.sortie,
                                                  style: Appstyle.textXLB.copyWith(
                                                    color: headerColor,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                SizedBox(width: 15),
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

                                  SizedBox(height: paddingV / 2),

                                  /// ✅ TAB BAR (remplace les CardWidget)
                                  Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(Appstyle.radiusLG),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Appstyle.shadowTint.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TabBar(
                                      controller: _tabController,
                                      isScrollable: false,
                                      indicator: BoxDecoration(
                                        color: currentTab == TAB_PANIER
                                            ? Appstyle.violet : Appstyle.indigo,
                                        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
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

                                  SizedBox(height: paddingV / 2),

                                  // ═══════════════════════════════════════════════════════════════════════════════
                                  // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                  // ═══════════════════════════════════════════════════════════════════════════════

                                  // ──────────────────────────────────────────────────────────────
                                  // 1. CAS PANIER (currentTab == TAB_PANIER)
                                  // ──────────────────────────────────────────────────────────────
                                  if (currentTab == TAB_PANIER)
                                    Column(
                                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // Afficheur
                                        if (panniersSelectionnes.length == 1)
                                          AfficheurPanier(
                                            pannier: panniersSelectionnes.first,
                                            verse: verseParPannier[panniersSelectionnes.first.code] ?? 0,
                                            reste: panniersSelectionnes.first.montant -
                                                (verseParPannier[panniersSelectionnes.first.code] ?? 0),
                                            nbrVersement: nbrVersementParPannier[panniersSelectionnes.first.code] ?? 0,
                                            hasRetour: panniersAvecRetour.contains(panniersSelectionnes.first.code),
                                            onDetails: () {
                                              PannierDetail(context, panniersSelectionnes.first);
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

                                        if (panniersSelectionnes.length == 1)
                                          SizedBox(height: paddingV / 2),

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
                                                    showBadge: _filtresSCsortieActifs,
                                                    icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                    iconColor:Appstyle.violet ,
                                                    onPressed: () {
                                                      setState(() {
                                                        filtresActifs = !filtresActifs;
                                                        if (!filtresActifs) {
                                                          supprimerFilterSCsortie();
                                                          appliquerFiltreSCsortie();
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  if (filtresActifs)
                                                    MainIconButton(
                                                      color: Appstyle.neutral300,
                                                      imagePath: 'assets/icons/action/supprimer_icon.png',
                                                      onPressed: () {
                                                        setState(() {
                                                          supprimerFilterSCsortie();
                                                          appliquerFiltreSCsortie();
                                                        });
                                                      },
                                                    ),
                                                  if (filtresActifs)
                                                    SizedBox(width: paddingH / 4),
                                                  MainButton(
                                                    text: l10n.extract,
                                                    textColor:Appstyle.success ,
                                                    iconColor: Appstyle.success,
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
                                                    textColor: Appstyle.danger,
                                                    iconColor: Appstyle.danger,
                                                    color: Appstyle.Tblanc,
                                                    icon: Icons.picture_as_pdf,
                                                    onPressed: () async {
                                                      await _exportCurrentModuleToExcel(enPdf: true);
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  MainIconButton(
                                                    imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                    color: Appstyle.warning,
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
                                                      if (panniersSelectionnes.length == 1) {
                                                        PannierDetail(context, panniersSelectionnes.first);
                                                      } else if (panniersSelectionnes.isEmpty) {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.panier,
                                                          message: l10n.noCartSelected,
                                                        );
                                                      } else {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.panier,
                                                          message: l10n.selectSingleCartForDetail,
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
                                          SizedBox(height: paddingV / 2),

                                        // Filtres
                                        if (filtresActifs)
                                          Align(
                                            alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                              child: filtreSCsortie(setState, adjustedWidth * 1 / 3, l10n, translator, isRTL),
                                            ),
                                          ),

                                        // Tableau
                                        SizedBox(
                                          height: adjustedHeight * 0.68,
                                          child: TableauPannierAdvanced(
                                            key: ValueKey(pannierFiltres),
                                            panniers: pannierFiltres,
                                            clients: clientsTest,
                                            verseParPannier: verseParPannier,
                                            nbrVersementParPannier: nbrVersementParPannier,
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                panniersSelectionnes = selection;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )

                                  // ──────────────────────────────────────────────────────────────
                                  // 2. CAS SORTIE (currentTab == TAB_SORTIE)
                                  // ──────────────────────────────────────────────────────────────
                                  else if (currentTab == TAB_SORTIE)
                                    Column(
                                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // Afficheur
                                        if (sortiesSelectionnes.length == 1)
                                          AfficheurSortie(
                                            sortie: sortiesSelectionnes.first,
                                            nomProduit: produitsTest.where((pr) => pr.code == sortiesSelectionnes.first.produitCode).firstOrNull?.nom ?? sortiesSelectionnes.first.produitCode,
                                            onDetails: () {
                                              SortieDetail(
                                                context,
                                                sortiesSelectionnes.first,
                                                produits: produitsTest,
                                                categories: categoriesTest,
                                                sousCategories: sousCategoriesTest,
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

                                        if (sortiesSelectionnes.length == 1)
                                          SizedBox(height: paddingV / 2),

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
                                                    showBadge: _filtresSortieActifs,
                                                    icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                                    iconColor:Appstyle.violet ,
                                                       onPressed: () {
                                                      setState(() {
                                                        filtresActifs = !filtresActifs;
                                                        if (!filtresActifs) {
                                                          supprimerFilterSortie();
                                                          appliquerFiltreSortie();
                                                        }
                                                      });
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  if (filtresActifs)
                                                    MainIconButton(
                                                      color: Appstyle.neutral300,
                                                      imagePath: 'assets/icons/action/supprimer_icon.png',
                                                      onPressed: () {
                                                        setState(() {
                                                          supprimerFilterSortie();
                                                          appliquerFiltreSortie();
                                                        });
                                                      },
                                                    ),
                                                  if (filtresActifs)
                                                    SizedBox(width: paddingH / 4),
                                                  MainButton(
                                                    text: l10n.extract,
                                                    textColor:Appstyle.success ,
                                                    iconColor: Appstyle.success,
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
                                                    textColor: Appstyle.danger,
                                                    iconColor: Appstyle.danger,
                                                    color: Appstyle.Tblanc,
                                                    icon: Icons.picture_as_pdf,
                                                    onPressed: () async {
                                                      await _exportCurrentModuleToExcel(enPdf: true);
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  MainIconButton(
                                                    imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                    color: Appstyle.warning,
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
                                                      if (sortiesSelectionnes.length == 1) {
                                                        SortieDetail(
                                                          context,
                                                          sortiesSelectionnes.first,
                                                          produits: produitsTest,
                                                          categories: categoriesTest,
                                                          sousCategories: sousCategoriesTest,
                                                        );
                                                      } else if (sortiesSelectionnes.isEmpty) {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.sortie,
                                                          message: l10n.noProductSelected,
                                                        );
                                                      } else {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.sortie,
                                                          message: l10n.selectSingleProductForDetail,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  MainIconButton(
                                                    imagePath: "assets/icons/action/supprimer_icon.png",
                                                    color: Appstyle.gris,
                                                    onPressed: () async {
                                                      if (sortiesSelectionnes.isNotEmpty) {
                                                        await AnnulerSortie(
                                                          context,
                                                          sortiesSelectionnes,
                                                        );
                                                        await loadAllData();
                                                      } else if (sortiesSelectionnes.isEmpty) {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.sortie,
                                                          message: l10n.noProductSelected,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  MainIconButton(
                                                    imagePath: "assets/icons/action/edit_icon.png",
                                                    color: Appstyle.blueC,
                                                    onPressed: () async {
                                                      if (sortiesSelectionnes.length == 1) {
                                                        await SortieModif(
                                                          context,
                                                          sortiesSelectionnes.first,
                                                        );
                                                        await loadAllData();
                                                      } else if (sortiesSelectionnes.isEmpty) {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.sortie,
                                                          message: l10n.noProductSelected,
                                                        );
                                                      } else {
                                                        await InformationDialog(
                                                          context: context,
                                                          titre_type_message: l10n.information,
                                                          titre_concerne: l10n.sortie,
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
                                                      await SortieNouveau(context);
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
                                            alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                            child: Padding(
                                              padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                              child: filtreSortie(setState, adjustedWidth * 1 / 3, l10n, translator, isRTL),
                                            ),
                                          ),

                                        // Tableau
                                        SizedBox(
                                          height: adjustedHeight * 0.68,
                                          child: TableauSortieAdvanced(
                                            key: ValueKey(sortielistFiltres),
                                            sorties: sortielistFiltres,
                                            produits: produitsTest,
                                            categories: categoriesTest,
                                            sousCategories: sousCategoriesTest,
                                            utilisateurs: utilisateursTest,
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                sortiesSelectionnes = selection;
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
              ),
            );
          },
        ),
      ),
    );
  }
  Widget filtreSortie(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Type / Produit / Etat
          Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.produit,
                  child: TextListe(
                    value: selectedProduitSortieFilter,
                    items: ProduitFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedProduitSortieFilter = v;
                        appliquerFiltreSortie();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.type,
                  child: TextListe(
                    value: selectedTypeSortieFilter != null ? translator.translateTypeSortie(selectedTypeSortieFilter!) : null,
                    items: translator.typeSortieDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedTypeSortieFilter = translator.typeSortieToFrench(v!);
                        appliquerFiltreSortie();
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
                    value: selectedEtatFilterSrt != null ? translator.translateEtat(selectedEtatFilterSrt!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterSrt = translator.etatToFrench(v!);
                        appliquerFiltreSortie();
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
                  controller: _dateDebutCtrlSortie,
                  onTap: _pickDateDebutSortie,
                ),
              ),
              ChampAvecLabel(
                label: l10n.to,
                child: TextDate(
                  hint: l10n.endDate,
                  enabled: dateDebuSortie != null,
                  controller: _dateFinCtrlSortie,
                  onTap: _pickDateFinSortie,
                ),
              ),
              ChampPeriodeRapide(
                l10n: l10n,
                value: periodeRapide,
                onSelected: (v) {
                  setState(() {
                    periodeRapide = v;
                    _appliquerPeriodeRapideSortie(v, l10n);
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
                  controller: _searchControllerSortie,
                  onChanged: (v) {
                    setState(() {
                      appliquerFiltreSortie();
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

  Widget filtreSCsortie(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.client,
                  child: TextListe(
                    value: selectedClientFilterSCsortie,
                    items: ClientFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedClientFilterSCsortie = v;
                        appliquerFiltreSCsortie();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.payment,
                  child: TextListe(
                    value: modepaiementFilterSCsortie != null ? translator.translateModePaiement(modepaiementFilterSCsortie!) : null,
                    items: translator.modePaiementDisplayList,
                    onChanged: (v) {
                      setState(() {
                        modepaiementFilterSCsortie = translator.modePaiementToFrench(v!);
                        appliquerFiltreSCsortie();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.typePannier,
                  child: TextListe(
                    value: typepannierFilterSCsortie != null ? translator.translateTypePannier(typepannierFilterSCsortie!) : null,
                    items: translator.typePannierDisplayList,
                    onChanged: (v) {
                      setState(() {
                        typepannierFilterSCsortie = translator.typePannierToFrench(v!);
                        appliquerFiltreSCsortie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Ligne montant / reste / état
          Row(
            textDirection: textDirection,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.amount,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: montantMinSCsortie,
                    maxValue: montantMaxSCsortie,
                    onChanged: (min, max) {
                      setState(() {
                        montantMinSCsortie = min;
                        montantMaxSCsortie = max;
                        appliquerFiltreSCsortie();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.remaining,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: resteMinSCsortie,
                    maxValue: resteMaxSCsortie,
                    onChanged: (min, max) {
                      setState(() {
                        resteMinSCsortie = min;
                        resteMaxSCsortie = max;
                        appliquerFiltreSCsortie();
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
                    value: selectedEtatFilterP != null ? translator.translateEtat(selectedEtatFilterP!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilterP = translator.etatToFrench(v!);
                        appliquerFiltreSCsortie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // Date
          LigneFiltreTiers(
            textDirection: textDirection,
            children: [
              ChampAvecLabel(
                label: l10n.from,
                child: TextDate(
                  hint: l10n.startDate,
                  controller: _dateDebutCtrlSCsortie,
                  onTap: _pickDateDebutSCsortie,
                ),
              ),
              ChampAvecLabel(
                label: l10n.to,
                child: TextDate(
                  hint: l10n.endDate,
                  enabled: dateDebutSCsortie != null,
                  controller: _dateFinCtrlSCsortie,
                  onTap: _pickDateFinSCsortie,
                ),
              ),
              ChampPeriodeRapide(
                l10n: l10n,
                value: periodeRapide,
                onSelected: (v) {
                  setState(() {
                    periodeRapide = v;
                    _appliquerPeriodeRapideSCsortie(v, l10n);
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
                  controller: _searchControllerSCSortie,
                  onChanged: (v) {
                    setState(() {
                      appliquerFiltreSCsortie();
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
}
