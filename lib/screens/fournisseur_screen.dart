import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'dart:io';
import 'package:caisse_dz/Services/export_spinner.dart';

import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/fournisseur/fournisseur_situation.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:excel/excel.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/dialog/fournisseur/fournisseur_actif.dart';
import '../core/dialog/fournisseur/fournisseur_detail.dart';
import '../core/dialog/fournisseur/fournisseur_modif.dart';
import '../core/dialog/fournisseur/fournisseur_nouveau.dart';
import '../core/dialog/information_dialog.dart';
import '../core/dialog/versement/versement_actif.dart';
import '../core/dialog/versement/versement_detail.dart';
import '../core/dialog/versement/versement_modif.dart';
import '../core/dialog/versement/versement_modif_retour.dart';
import '../core/dialog/versement/versement_nouveau_retour.dart';
import '../core/tableau/founisseur/tableau_fournisseur.dart';
import '../core/tableau/versement/versement_tableau.dart';
import '../core/widget/afficheur/afficheur_client&fournisseur.dart';
import '../core/widget/afficheur/afficheur_fournisseur_global.dart';
import '../core/widget/afficheur/afficheur_versement.dart';
import '../core/widget/afficheur/afficheur_versement_global.dart';
import '../core/widget/button/Icon_button.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/date_champ.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/fourchette._widget.dart';
import '../core/widget/header_module.dart';
import '../core/widget/search_bar.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/connection_status_bar.dart';
import '../core/widget/account.dart';
import '../data/constant.dart';
import '../data/models/fournisseur.dart';
import '../data/models/verssement.dart';

class FournisseurScreen extends StatefulWidget {
  FournisseurScreen({super.key});

  @override
  State<FournisseurScreen> createState() => _FournisseurScreenState();
}

class _FournisseurScreenState extends State<FournisseurScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_FOURNISSEUR = 0;
  static const int TAB_VERSEMENT = 1;

  // Period keys for translation lookup

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  int nombreFournisseur = 5;
  int nombreVerssement = 4;

  // ----------- Filtres
  String? typeFournisseurFilter;
  String? activiteFournisseurFilter;
  String? selectedEtatFilter;
  bool filtresActifs = false;
  // Garde anti-double-clic pour l'export Excel (voir client_screen.dart pour
  // le détail du bug évité : double showDialog/Navigator.pop pouvant laisser
  // un spinner bloquant à l'écran).
  bool _exportEnCours = false;
  List<Fournisseur> fournisseursFiltres = [];

  // ---------- Filtres Versement
  String? modepaiementFilter;
  String? fournisseurFilterVersment;
  String? selectedEtatVersementFilter;
  double? versemntMin;
  double? versemntMax;
  DateTime? dateDebut;
  DateTime? dateFin;
  String? periodeRapide;
  late List<String> fournisseurFilterOptions = [];
  late List<String> modepaiementFilterOptions = [];
  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  List<Fournisseur> fournisseurs = [];
  List<Verssement> versements = [];
  List<Fournisseur> fournisseursSelectionnes = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchControllerVers = TextEditingController();

  List<Verssement> verssementFournisseursSelectionnes = [];
  List<Verssement> verssementsFiltres = [];

  bool isLoading = true;

  List<Fournisseur> fournisseursTest = [];
  List<Verssement> verssementsTest = [];
  List<Retour> retoursTest = [];
  List<SmartScan> smartScansTest = [];
  List<Utilisateur> utilisateursTest = [];
  FournisseurGlobalStats? fournisseurGlobalStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          viderliste();
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


  Future<void> loadAllData() async {
    setState(() => isLoading = true);

    final verssement = await VerssementServices.getAllverssement();
    final fournisseur = await FournisseurServices.getAllFournisseurs();
    final retour = await RetourServices.getAllRetour();
    final SmartScan = await SmartScanServices.getAllSmartScans();
    final globalStats = await FournisseurServices.getGlobalFournisseurStats();
    final utilisateurs = await UtilisateurServices.getAllUtilisateurs();

    if (!mounted) return;

    setState(() {
      fournisseursTest = fournisseur;
      utilisateursTest = utilisateurs;
      fournisseurs = fournisseursTest;
      fournisseursFiltres = fournisseursTest;

      verssementsTest = verssement.where((v) => v.typebeneficiare == "Fournisseur").toList();
      versements = verssementsTest.where((v) => v.typebeneficiare == "Fournisseur").toList();
      verssementsFiltres = verssementsTest;
      verssementsFiltres = versements;

      retoursTest = retour;
      smartScansTest = SmartScan;
      fournisseurGlobalStats = globalStats;

      isLoading = false;

      fournisseursSelectionnes.clear();
      verssementFournisseursSelectionnes.clear();
    });
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

      File? excelFile;
      String moduleName = '';

      // Determine which module is active based on tab index
      switch (currentTab) {
        case TAB_FOURNISSEUR: // 0 - Fournisseurs
          final fournisseursToExport = filtresActifs ? fournisseursFiltres : fournisseursTest;

          if (fournisseursToExport.isEmpty) {
            fermerSpinner();
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.fournisseur,
              message: l10n.noDataToExport,
            );
            return;
          }

          moduleName = l10n.fournisseur;
          excelFile = await ExcelGenerator.generateFournisseursExcel(
            fournisseurs: fournisseursToExport,
            l10n: l10n,
            translator: translator,
          );
          break;

        case TAB_VERSEMENT: // 1 - Versements
          final versementsToExport = filtresActifs ? verssementsFiltres : verssementsTest;

          if (versementsToExport.isEmpty) {
            fermerSpinner();
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.versement,
              message: l10n.noDataToExport,
            );
            return;
          }

          moduleName = l10n.versement;
          excelFile = await ExcelGenerator.generateVersementsExcel(
            versements: versementsToExport,
            l10n: l10n,
            translator: translator,
          );
          break;

        default:
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.fournisseur,
            message: l10n.noDataToExport,
          );
          return;
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

      final sheetName = currentTab == TAB_FOURNISSEUR ? 'Fournisseurs' : 'Versements';
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

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      File? excelFile;
      String moduleName = '';

      // Determine which module is active based on tab index
      switch (currentTab) {
        case TAB_FOURNISSEUR: // 0 - Fournisseurs
          if (fournisseursSelectionnes.isEmpty) {
            fermerSpinner();
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.fournisseur,
              message: l10n.noSupplierSelected,
            );
            return;
          }

          moduleName = l10n.fournisseur;
          excelFile = await ExcelGenerator.generateFournisseursExcel(
            fournisseurs: fournisseursSelectionnes,
            l10n: l10n,
            translator: translator,
          );
          break;

        case TAB_VERSEMENT: // 1 - Versements
          if (verssementFournisseursSelectionnes.isEmpty) {
            fermerSpinner();
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.versement,
              message: l10n.noPaymentSelected,
            );
            return;
          }

          moduleName = l10n.versement;
          excelFile = await ExcelGenerator.generateVersementsExcel(
            versements: verssementFournisseursSelectionnes,
            l10n: l10n,
            translator: translator,
          );
          break;

        default:
          fermerSpinner();
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.fournisseur,
            message: l10n.noDataToExport,
          );
          return;
      }

      fermerSpinner();

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_FOURNISSEUR ? 'Fournisseurs' : 'Versements';
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

  // ✅ Vrai si au moins un champ de filtre fournisseur est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresFournisseurActifs =>
      typeFournisseurFilter != null ||
      activiteFournisseurFilter != null ||
      (selectedEtatFilter != null && selectedEtatFilter!.isNotEmpty) ||
      _searchController.text.isNotEmpty;

  void appliquerFiltre() {
    setState(() {
      fournisseursFiltres = fournisseursTest.where((f) {
        final search = _searchController.text.toLowerCase();

        final searchOk = search.isEmpty || f.searchableText.contains(search);
        final typeOk = typeFournisseurFilter == null || f.type == typeFournisseurFilter;
        final activiteOk = activiteFournisseurFilter == null || f.activity == activiteFournisseurFilter;

        final etatOk = selectedEtatFilter == null ||
            selectedEtatFilter == "" ||
            (selectedEtatFilter == "Actif" && f.etat) ||
            (selectedEtatFilter == "Inactif" && !f.etat);

        return searchOk && typeOk && activiteOk && etatOk;
      }).toList();
    });
  }

  void supprimerFilter() {
    typeFournisseurFilter = null;
    activiteFournisseurFilter = null;
    selectedEtatFilter = null;
    _searchController.clear();
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

    appliquerFiltreVers();
  }

  // ✅ Vrai si au moins un champ de filtre versement est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresVersementActifs =>
      (fournisseurFilterVersment != null && fournisseurFilterVersment!.isNotEmpty) ||
      (modepaiementFilter != null && modepaiementFilter!.isNotEmpty) ||
      selectedEtatVersementFilter != null ||
      versemntMin != null ||
      versemntMax != null ||
      dateDebut != null ||
      dateFin != null ||
      _searchControllerVers.text.isNotEmpty;

  void appliquerFiltreVers() {
    verssementsFiltres = versements.where((c) {
      final search = _searchControllerVers.text.toLowerCase();
      final clientOk = fournisseurFilterVersment == null ||
          fournisseurFilterVersment!.isEmpty ||
          fournisseursTest.any((f) => f.code == c.beneficiareCode && f.nom == fournisseurFilterVersment);
      final modeOk = modepaiementFilter == null ||
          modepaiementFilter!.isEmpty ||
          c.mode_paiement == modepaiementFilter;

      final etatOk = selectedEtatVersementFilter == null ||
          selectedEtatVersementFilter == "" ||
          (selectedEtatVersementFilter == "Validé" && c.etat) ||
          (selectedEtatVersementFilter == "Annulé" && !c.etat);

      final searchOk = search.isEmpty || c.searchableText.contains(search);
      final montantOk = (versemntMin == null || c.montant >= versemntMin!) &&
          (versemntMax == null || c.montant <= versemntMax!);

      final dateOk = () {
        if (dateDebut == null && dateFin == null) return true;
        final d = c.date;
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

      return clientOk && modeOk && etatOk && searchOk && montantOk && dateOk;
    }).toList();

    if ((fournisseurFilterVersment == null || fournisseurFilterVersment!.isEmpty) &&
        (modepaiementFilter == null || modepaiementFilter!.isEmpty) &&
        versemntMin == null &&
        versemntMax == null &&
        selectedEtatVersementFilter == null &&
        dateDebut == null &&
        dateFin == null &&
        _searchController.text.isEmpty) {
      verssementsFiltres = verssementsTest;
    }

    setState(() {});
  }

  void supprimerFilterVerse() {
    fournisseurFilterVersment = null;
    modepaiementFilter = null;
    versemntMax = null;
    versemntMin = null;
    selectedEtatVersementFilter = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
    _searchController.clear();
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
        appliquerFiltre();
      });
    }
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
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
        appliquerFiltre();
      });
    }
  }

  void viderliste() {
    verssementFournisseursSelectionnes.clear();
    fournisseursSelectionnes.clear();
  }

  // ---------------- STATISTIQUES VERSEMENTS ----------------
  String _nomFournisseurVersement(String code) =>
      fournisseursTest.firstWhereOrNull((f) => f.code == code)?.nom ?? code;

  // ✅ Total Versé = total des versements "Entrée" uniquement (paiements
  // effectivement reçus), sans les versements "Sortie" (règlements
  // fournisseur).
  // Cards Versement : versements actifs dans le sens qui compte pour un
  // fournisseur ('Sortie' — même convention que le total de la situation fournisseur).
  List<Verssement> get _versementsComptes => verssementsTest
      .where((v) => v.etat && v.sense == 'Sortie')
      .toList();

  double _totalVerse() => _versementsComptes.fold(0.0, (s, v) => s + v.montant);

  Verssement? _versementMax() {
    final liste = _versementsComptes;
    if (liste.isEmpty) return null;
    return liste.reduce((a, b) => a.montant >= b.montant ? a : b);
  }

  Verssement? _dernierVersement() {
    final liste = _versementsComptes;
    if (liste.isEmpty) return null;
    return liste.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    // Initialize filter options
    fournisseurFilterOptions = fournisseursTest.map((c) => c.nom).toSet().toList();
    modepaiementFilterOptions = translator.modePaiementDisplayList;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Couleur de l'en-tête alignée sur la couleur du tab actif
    final Color headerColor = currentTab == TAB_FOURNISSEUR ? Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.fournisseur,
      l10n.versement,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/fournisseur_icon.png',
      'assets/icons/devise_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombreFournisseur.toString(),
      nombreVerssement.toString(),
    ];

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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              HeaderModule(
                                gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                child: Row(
                                  children: [
                                    Image.asset(
                                      "assets/icons/sidebar/fournisseur_icon.png",
                                      width: 40,
                                      color: headerColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${l10n.fournisseur} (${tabNames[currentTab]})",
                                      style: Appstyle.textXLB.copyWith(
                                        color: headerColor,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                                    color: currentTab == TAB_FOURNISSEUR ? Appstyle.violet : Appstyle.indigo,
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

                              SizedBox(height: paddingV),

                              // ═══════════════════════════════════════════════════════════════════════════════
                              // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                              // ═══════════════════════════════════════════════════════════════════════════════

                              // ──────────────────────────────────────────────────────────────
                              // 1. CAS FOURNISSEUR (currentTab == TAB_FOURNISSEUR)
                              // ──────────────────────────────────────────────────────────────
                              if (currentTab == TAB_FOURNISSEUR)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficheur
                                    if (fournisseursSelectionnes.length == 1)
                                      FutureBuilder<FournisseurStats>(
                                        future: FournisseurServices.getFournisseurStats(fournisseursSelectionnes.first),
                                        builder: (context, snapshot) {
                                          final stats = snapshot.data;
                                          return ClientAfficheurWidget(
                                            nom: fournisseursSelectionnes.first.nom,
                                            code: fournisseursSelectionnes.first.code,
                                            type: translator.translateTypeFournisseur(fournisseursSelectionnes.first.type),
                                            activite: fournisseursSelectionnes.first.activity != null
                                                ? translator.translateActiviteFournisseur(fournisseursSelectionnes.first.activity!)
                                                : "",
                                            etat: fournisseursSelectionnes.first.etat,
                                            totalVersement: stats?.totalVerse ?? 0,
                                            totalAchat: stats?.totalAchat,
                                            totalRetour: stats?.totalRetour,
                                            dateDernierAchat: stats?.dateDernierAchat,
                                            avance: stats?.avance,
                                            credit: stats?.credit,
                                            solde: stats?.solde,
                                            soldePositifFavorable: false,
                                            wilaya: fournisseursSelectionnes.first.wilaya ?? "",
                                            dateCreation: fournisseursSelectionnes.first.dateCree.toString(),
                                            onDetails: () {
                                              FournisseurDetail(context, fournisseursSelectionnes.first);
                                            },
                                          );
                                        },
                                      )
                                    else
                                      AfficheurFournisseurGlobalWidget(
                                        nombreClients: fournisseurs.length,
                                        nombreInactifs: fournisseurs.where((c) => !c.etat).length,
                                        type: l10n.fournisseur,
                                        totalAchat: fournisseurGlobalStats?.totalAchat,
                                        nomFournisseurTopAchat: fournisseurGlobalStats?.fournisseurTopAchat?.nom,
                                        montantTopAchat: fournisseurGlobalStats?.montantTopAchat,
                                        totalCredit: fournisseurGlobalStats?.totalCredit,
                                        nomFournisseurTopCredit: fournisseurGlobalStats?.fournisseurTopCredit?.nom,
                                        montantTopCredit: fournisseurGlobalStats?.montantTopCredit,
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
                                              textColor: Appstyle.violet,
                                              color: Appstyle.Tblanc,
                                              showBadge: _filtresFournisseurActifs,
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
                                          children: [
                                            MainIconButton(
                                              imagePath: "assets/icons/action/detail_icon.png",
                                              color: Appstyle.violet,
                                              onPressed: () async {
                                                if (fournisseursSelectionnes.isNotEmpty) {
                                                  FournisseurDetail(context, fournisseursSelectionnes.first);
                                                } else if (fournisseursSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: l10n.noClientSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: l10n.selectSingleClientForDetail,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/supprimer_icon.png",
                                              color: Appstyle.gris,
                                              onPressed: () async {
                                                if (fournisseursSelectionnes.isNotEmpty) {
                                                  bool contientNonSupprimable = fournisseursSelectionnes.any(
                                                        (fournisseur) => ListsConst.nonSupprimablePacks.any(
                                                          (p) => p.nom == "Fournisseur" && p.code == fournisseur.code,
                                                    ),
                                                  );

                                                  if (contientNonSupprimable) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.fournisseur,
                                                      message: l10n.cannotDeleteSystemClient,
                                                    );
                                                  } else {
                                                    await AnnulerFournisseur(context, fournisseursSelectionnes);
                                                    await loadAllData();
                                                  }
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: l10n.noClientSelected,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/edit_icon.png",
                                              color: Appstyle.blueC,
                                              onPressed: () async {
                                                if (fournisseursSelectionnes.length == 1) {
                                                  bool contientNonSupprimable = fournisseursSelectionnes.any(
                                                        (fournisseur) => ListsConst.nonSupprimablePacks.any(
                                                          (p) => p.nom == "Fournisseur" && p.code == fournisseur.code,
                                                    ),
                                                  );

                                                  if (contientNonSupprimable) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.fournisseur,
                                                      message: l10n.cannotModifySystemClient,
                                                    );
                                                  } else {
                                                    await FournisseurModif(context, fournisseursSelectionnes.first);
                                                    await loadAllData();
                                                  }
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: fournisseursSelectionnes.isEmpty
                                                        ? l10n.noClientSelected
                                                        : l10n.selectSingleClientToModify,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/stat_icon.png",
                                              color: Appstyle.lavande,
                                              onPressed: () async {
                                                if (fournisseursSelectionnes.length == 1) {
                                                  SituationFournisseurDialog(
                                                    context,
                                                    retours: retoursTest,
                                                    versements: verssementsTest,
                                                    fournisseur: fournisseursSelectionnes.first,
                                                    smartScans: smartScansTest,
                                                  );
                                                } else if (fournisseursSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: l10n.noClientSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.fournisseur,
                                                    message: l10n.selectSingleClientForOperations,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await FournisseurNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Filtres fournisseur
                                    if (filtresActifs)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV),
                                        child: filtreFournisseur(setState, l10n, translator),
                                      ),

                                    if (!filtresActifs)
                                      SizedBox(height: paddingV / 2),

                                    // Tableau
                                    SizedBox(
                                      height: adjustedHeight * 0.68,
                                      child: TableauFournisseurAdvanced(
                                        key: ValueKey(fournisseursFiltres),
                                        fournisseurs: fournisseursFiltres,
                                        utilisateurs: utilisateursTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            fournisseursSelectionnes = selection;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )

                              // ──────────────────────────────────────────────────────────────
                              // 2. CAS VERSEMENT (currentTab == TAB_VERSEMENT)
                              // ──────────────────────────────────────────────────────────────
                              else if (currentTab == TAB_VERSEMENT)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficheur
                                    if (verssementFournisseursSelectionnes.length == 1)
                                      AfficheurVersement(
                                        versement: verssementFournisseursSelectionnes.first,
                                        nomBeneficiaire: _nomFournisseurVersement(
                                            verssementFournisseursSelectionnes.first.beneficiareCode),
                                        onDetails: () {
                                          VersementDetail(context, verssementFournisseursSelectionnes.first);
                                        },
                                      )
                                    else
                                      AfficheurVersementGlobalWidget(
                                        nombreVersements: verssementsTest.where((v) => v.etat).length,
                                        totalVerse: _totalVerse(),
                                        montantMax: _versementMax()?.montant ?? 0,
                                        nomBeneficiaireMax: _versementMax() != null
                                            ? _nomFournisseurVersement(_versementMax()!.beneficiareCode)
                                            : null,
                                        montantDernier: _dernierVersement()?.montant ?? 0,
                                        codeDernier: _dernierVersement()?.code,
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
                                              textColor: Appstyle.violet,
                                              color: Appstyle.Tblanc,
                                              showBadge: _filtresVersementActifs,
                                              icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                              iconColor:Appstyle.violet ,
                                              onPressed: () {
                                                setState(() {
                                                  filtresActifs = !filtresActifs;
                                                  if (!filtresActifs) {
                                                    supprimerFilterVerse();
                                                    appliquerFiltreVers();
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
                                                    supprimerFilterVerse();
                                                    appliquerFiltreVers();
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
                                          children: [
                                            MainIconButton(
                                              imagePath: "assets/icons/action/detail_icon.png",
                                              color: Appstyle.violet,
                                              onPressed: () async {
                                                if (verssementFournisseursSelectionnes.isNotEmpty) {
                                                  VersementDetail(context, verssementFournisseursSelectionnes.first);
                                                } else if (verssementFournisseursSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: l10n.noPaymentSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: l10n.selectSinglePaymentToModify,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/supprimer_icon.png",
                                              color: Appstyle.gris,
                                              onPressed: () async {
                                                if (verssementFournisseursSelectionnes.isNotEmpty) {
                                                  await ActiverVersements(context, verssementFournisseursSelectionnes);
                                                  await loadAllData();
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: l10n.noPaymentSelected,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/edit_icon.png",
                                              color: Appstyle.blueC,
                                              onPressed: () async {
                                                if (verssementFournisseursSelectionnes.length == 1) {
                                                  final versement = verssementFournisseursSelectionnes.first;
                                                  if (versement.sense == "Entrée") {
                                                    VersementModif(
                                                      context,
                                                      versement,
                                                      typeInitial: "Fournisseur",
                                                    );
                                                  } else {
                                                    VersementModifRetour(
                                                      context,
                                                      versement,
                                                      typeInitial: "Fournisseur",
                                                    );
                                                  }
                                                } else if (verssementFournisseursSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: l10n.noPaymentSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: l10n.selectSinglePaymentToModify,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.exit,
                                              color: Appstyle.jaune,
                                              onPressed: () async {
                                                await VersementNouveauRetour(context, "Fournisseur");
                                                await loadAllData();
                                              },
                                            ),

                                          ],
                                        ),
                                      ],
                                    ),

                                    // Filtres versement
                                    if (filtresActifs)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV),
                                        child: filtreversement(setState, adjustedWidth, l10n, translator),
                                      ),

                                    if (!filtresActifs)
                                      SizedBox(height: paddingV / 2),

                                    // Tableau
                                    SizedBox(
                                      height: adjustedHeight * 0.68,
                                      child: TableauVerssementAdvanced(
                                        key: ValueKey(verssementsFiltres),
                                        verssements: verssementsFiltres,
                                        fournisseurs: fournisseursTest,
                                        utilisateurs: utilisateursTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            verssementFournisseursSelectionnes = selection;
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
    );
  }

  Widget filtreFournisseur(void Function(VoidCallback fn) setState, AppLocalizations l10n, ListsConstTranslator translator) {
    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        children: [
          // ---------------- LIGNE 1
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.typeClient,
                  child: TextListe(
                    value: typeFournisseurFilter != null
                        ? translator.translateTypeFournisseur(typeFournisseurFilter!)
                        : null,
                    items: translator.typeFournisseurDisplayList,
                    onChanged: (v) {
                      setState(() {
                        typeFournisseurFilter = translator.typeFournisseurToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.activite,
                  child: TextListe(
                    value: activiteFournisseurFilter != null
                        ? translator.translateActiviteFournisseur(activiteFournisseurFilter!)
                        : null,
                    items: translator.activiteFournisseurDisplayList,
                    onChanged: (v) {
                      setState(() {
                        activiteFournisseurFilter = translator.activiteFournisseurToFrench(v!);
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

          // ---------------- LIGNE 2
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.search,
                child: SearchField(
                  controller: _searchController,
                  onChanged: (_) => appliquerFiltre(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget filtreversement(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator) {
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
                  label: l10n.fournisseur,
                  child: TextListe(
                    value: fournisseurFilterVersment ?? "",
                    items: fournisseurFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        fournisseurFilterVersment = v;
                        appliquerFiltreVers();
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
                    value: modepaiementFilter != null
                        ? translator.translateModePaiement(modepaiementFilter!)
                        : null,
                    items: translator.modePaiementDisplayList,
                    onChanged: (v) {
                      setState(() {
                        modepaiementFilter = translator.modePaiementToFrench(v!);
                        appliquerFiltreVers();
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
                    minValue: versemntMin,
                    maxValue: versemntMax,
                    onChanged: (min, max) {
                      setState(() {
                        versemntMin = min;
                        versemntMax = max;
                        appliquerFiltreVers();
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
              // Même largeur que la période rapide du filtre Retour.
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
            children: [
              ChampAvecLabel(
                label: l10n.search,
                child: SearchField(
                  controller: _searchControllerVers,
                  onChanged: (v) {
                    setState(() {
                      appliquerFiltreVers();
                    });
                  },
                ),
              ),
              ChampAvecLabel(
                label: l10n.valide,
                child: TextListe(
                  value: selectedEtatVersementFilter != null
                      ? translator.translateEtatVersement(selectedEtatVersementFilter!)
                      : null,
                  items: translator.etatVersementDisplayList,
                  onChanged: (v) {
                    setState(() {
                      selectedEtatVersementFilter = translator.etatVersementToFrench(v!);
                      appliquerFiltreVers();
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
