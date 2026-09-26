
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/versement/versement_detail.dart';
import 'package:caisse_dz/core/dialog/versement/versement_modif.dart';
import 'package:caisse_dz/core/tableau/versement/versement_tableau.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_client_global.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_versement.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_versement_global.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/dialog/client/client_actif.dart';
import '../core/dialog/client/client_detail.dart';
import '../core/dialog/client/client_modif.dart';
import '../core/dialog/client/client_nouveau.dart';
import '../core/dialog/client/client_situation.dart';
import '../core/dialog/information_dialog.dart';
import '../core/dialog/versement/versement_actif.dart';
import '../core/dialog/versement/versement_nouveau.dart';
import '../core/tableau/client/client_tableau.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/afficheur/afficheur_client&fournisseur.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/date_champ.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/fourchette._widget.dart';
import '../core/widget/header_module.dart';
import '../core/widget/search_bar.dart';
import '../core/widget/side_bar.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/connection_status_bar.dart';
import '../core/widget/account.dart';
import '../data/constant.dart';
import '../data/models/client.dart';

class ClientScreen extends StatefulWidget {
  ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_CLIENT = 0;
  static const int TAB_VERSEMENT = 1;

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

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  int nombreClient = 5;
  int nombreVerssement = 3;

  // ----------- Filtres
  String? typeClientFilter;
  String? activiteClientFilter;
  bool filtresActifs = false;
  List<Client> clientsFiltres = [];
  String? selectedEtatFilter;

  // ---------- Filtres Versement
  String? modepaiementFilter;
  String? clientFilterVersment;
  double? versemntMin;
  double? versemntMax;
  String? selectedEtatVErsementFilter;
  DateTime? dateDebut;
  DateTime? dateFin;
  String? periodeRapide;
  late List<String> clientFilterOptions = [];
  late List<String> modepaiementFilterOptions = [];
  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  List<Client> clientsSelectionnes = [];
  List<Client> clients = [];
  List<Verssement> versements = [];
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchControllerVers = TextEditingController();

  bool isLoading = true;

  List<Verssement> verssementClientsSelectionnes = [];
  List<Verssement> verssementsFiltres = [];
  List<Verssement> verssementsTest = [];
  List<Client> clientsTest = [];
  List<Pannier> paniersTest = [];
  List<Retour> retoursTest = [];
  List<Utilisateur> utilisateursTest = [];
  ClientGlobalStats? clientGlobalStats;

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

    final client = await ClientServices.getAllClients();
    final verssement = await VerssementServices.getAllverssement();
    final pannier = await PannierServices.getAllPanniers();
    final retour = await RetourServices.getAllRetour();
    final globalStats = await ClientServices.getGlobalClientStats();
    final utilisateurs = await UtilisateurServices.getAllUtilisateurs();

    if (!mounted) return;

    setState(() {
      utilisateursTest = utilisateurs;
      clientsTest = List.from(client);
      clients = List.from(client);

      if (filtresActifs) {
        appliquerFiltre();
      } else {
        clientsFiltres = List.from(client);
      }

      verssementsTest = verssement.where((v) => v.typebeneficiare == "Client").toList();
      versements = verssementsTest.where((v) => v.typebeneficiare == "Client").toList();
      verssementsFiltres = verssementsTest;
      verssementsFiltres = versements;

      nombreClient = client.length;
      nombreVerssement = verssementsFiltres.length;

      paniersTest = pannier;
      retoursTest = retour;
      clientGlobalStats = globalStats;

      isLoading = false;

      clientsSelectionnes.clear();
      verssementClientsSelectionnes.clear();
    });
  }

  // ✅ Vrai si au moins un champ de filtre client est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresClientActifs =>
      typeClientFilter != null ||
      activiteClientFilter != null ||
      (selectedEtatFilter != null && selectedEtatFilter!.isNotEmpty) ||
      _searchController.text.isNotEmpty;

  void appliquerFiltre() {
    final search = _searchController.text.toLowerCase();

    clientsFiltres = clients.where((c) {
      final typeOk = typeClientFilter == null || c.type == typeClientFilter;
      final activiteOk = activiteClientFilter == null || c.activity == activiteClientFilter;
      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && c.etat) ||
          (selectedEtatFilter == "Inactif" && !c.etat);
      final searchOk = search.isEmpty || c.searchableText.contains(search);

      return typeOk && activiteOk && etatOk && searchOk;
    }).toList();

    setState(() {});
  }

  void supprimerFilter() {
    typeClientFilter = null;
    activiteClientFilter = null;
    selectedEtatFilter = null;
    _searchController.clear();
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
      (clientFilterVersment != null && clientFilterVersment!.isNotEmpty) ||
      (modepaiementFilter != null && modepaiementFilter!.isNotEmpty) ||
      (selectedEtatVErsementFilter != null && selectedEtatVErsementFilter!.isNotEmpty) ||
      versemntMin != null ||
      versemntMax != null ||
      dateDebut != null ||
      dateFin != null ||
      _searchControllerVers.text.isNotEmpty;

  void appliquerFiltreVers() {
    verssementsFiltres = versements.where((c) {
      final search = _searchControllerVers.text.toLowerCase();
      final clientOk = clientFilterVersment == null ||
          clientFilterVersment!.isEmpty ||
          clientsTest.any((cl) => cl.code == c.beneficiareCode && cl.nom == clientFilterVersment);
      final modeOk = modepaiementFilter == null ||
          modepaiementFilter!.isEmpty ||
          c.mode_paiement == modepaiementFilter;
      final etatOk = selectedEtatVErsementFilter == null ||
          selectedEtatVErsementFilter == "" ||
          (selectedEtatVErsementFilter == "Validé" && c.etat) ||
          (selectedEtatVErsementFilter == "Annulé" && !c.etat);
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

    if ((clientFilterVersment == null || clientFilterVersment!.isEmpty) &&
        (modepaiementFilter == null || modepaiementFilter!.isEmpty) &&
        versemntMin == null && versemntMax == null &&
        selectedEtatVErsementFilter == null &&
        dateDebut == null && dateFin == null &&
        _searchController.text.isEmpty) {
      verssementsFiltres = verssementsTest;
    }

    setState(() {});
  }

  void supprimerFilterVerse() {
    clientFilterVersment = null;
    modepaiementFilter = null;
    versemntMax = null;
    versemntMin = null;
    selectedEtatVErsementFilter = null;
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
    verssementClientsSelectionnes.clear();
    clientsSelectionnes.clear();
  }

  // Excel Export Methods
  Future<void> _exportToExcel() async {
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

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      String sheetName = '';
      File? excelFile;
      String moduleName = '';

      // Determine which module is active based on tab index
      switch (currentTab) {
        case TAB_CLIENT: // 0 - Clients
          final clientsToExport = filtresActifs ? clientsFiltres : clients;
          if (clientsToExport.isEmpty) {
            Navigator.pop(context);
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.client,
              message: l10n.noDataToExport,
            );
            return;
          }
          sheetName = 'Clients';
          moduleName = l10n.client;
          excelFile = await ExcelGenerator.generateClientsExcel(
            clients: clientsToExport,
            l10n: l10n,
            translator: translator,
          );
          break;

        case TAB_VERSEMENT: // 1 - Versements
          final versementsToExport = filtresActifs ? verssementsFiltres : versements;
          if (versementsToExport.isEmpty) {
            Navigator.pop(context);
            await InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.versement,
              message: l10n.noDataToExport,
            );
            return;
          }
          sheetName = 'Versements';
          moduleName = l10n.versement;
          excelFile = await ExcelGenerator.generateVersementsExcel(
            versements: versementsToExport,
            l10n: l10n,
            translator: translator,
          );
          break;

        default:
          Navigator.pop(context);
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.client,
            message: l10n.noDataToExport,
          );
          return;
      }

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      Navigator.pop(context);

      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      print('Available sheets: ${excel.tables.keys}');

      var sheet = excel.tables[sheetName];

      if (sheet == null) {
        if (excel.tables.isNotEmpty) {
          sheet = excel.tables.values.first;
          print('Using first sheet: ${excel.tables.keys.first}');
        }
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        print('Sheet max rows: ${sheet.maxRows}');
        print('Sheet max columns: ${sheet.maxColumns}');

        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
            print('Header $col: ${cell.value.toString()}');
          }
        }

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
            print('Row $row: ${rowData.length} columns');
          }
        }

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No data found in Excel file'),
              backgroundColor: Colors.orange,
            ),
          );
          Navigator.pop(context);
          return;
        }

        print('Total headers: ${headers.length}');
        print('Total data rows: ${data.length}');

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
    if (clientsSelectionnes.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.client,
        message: l10n.noClientSelected,
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

      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      // Generate Excel for selected clients only
      final excelFile = await ExcelGenerator.generateClientsExcel(
        clients: clientsSelectionnes, // Use selected clients
        l10n: l10n,
        translator: translator,
      );

      Navigator.pop(context); // Close loading dialog

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Clients'];

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

        // Show preview dialog for selected clients
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: "${l10n.client} (${l10n.selected})",
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




  // ---------------- STATISTIQUES VERSEMENTS ----------------
  String _nomClientVersement(String code) =>
      clientsTest.firstWhereOrNull((c) => c.code == code)?.nom ?? code;

  // ✅ Total Versé = total encaissé (versements "Entrée" uniquement) — un
  // remboursement client ("Sortie") n'est pas un encaissement et ne doit
  // pas gonfler ce total.
  double _totalVerse() => verssementsTest
      .where((v) => v.sense == 'Entrée')
      .fold(0.0, (s, v) => s + v.montant);

  Verssement? _versementMax() {
    if (verssementsTest.isEmpty) return null;
    return verssementsTest.reduce((a, b) => a.montant >= b.montant ? a : b);
  }

  Verssement? _dernierVersement() {
    if (verssementsTest.isEmpty) return null;
    return verssementsTest.reduce((a, b) => a.date.isAfter(b.date) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';
    final userCode = auth.userCode ?? '';

    // Initialize filter options
    clientFilterOptions = clientsTest.map((c) => c.nom).toSet().toList();
    modepaiementFilterOptions = translator.modePaiementDisplayList;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Couleur de l'en-tête alignée sur la couleur du tab actif
    final Color headerColor = currentTab == TAB_CLIENT ? Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.client,
      l10n.versement,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/client_icon.png',
      'assets/icons/devise_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombreClient.toString(),
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SideBarWidget(),
                      Expanded(
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
                                      "assets/icons/sidebar/client_icon.png",
                                      width: 40,
                                      color: headerColor,
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      "${l10n.client} (${tabNames[currentTab]})",
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
                                    color: currentTab == TAB_CLIENT ? Appstyle.violet : Appstyle.indigo,
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
                              // 1. CAS CLIENT (currentTab == TAB_CLIENT)
                              // ──────────────────────────────────────────────────────────────
                              if (currentTab == TAB_CLIENT)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficheur
                                    if (clientsSelectionnes.length == 1)
                                      FutureBuilder<ClientStats>(
                                        future: ClientServices.getClientStats(clientsSelectionnes.first),
                                        builder: (context, snapshot) {
                                          final stats = snapshot.data;
                                          return ClientAfficheurWidget(
                                            nom: clientsSelectionnes.first.nom,
                                            code: clientsSelectionnes.first.code,
                                            type: translator.translateTypeClient(clientsSelectionnes.first.type),
                                            activite: clientsSelectionnes.first.activity != null
                                                ? translator.translateActiviteClient(clientsSelectionnes.first.activity!)
                                                : "",
                                            etat: clientsSelectionnes.first.etat,
                                            totalVersement: stats?.totalVerse ?? 0,
                                            totalAchat: stats?.totalAchat,
                                            totalRetour: stats?.totalRetour,
                                            dateDernierAchat: stats?.dateDernierAchat,
                                            avance: stats?.avance,
                                            credit: stats?.credit,
                                            solde: stats?.solde,
                                            wilaya: clientsSelectionnes.first.wilaya,
                                            dateCreation: clientsSelectionnes.first.dateCree.toString(),
                                            onDetails: () {
                                              ClientDetail(context, clientsSelectionnes.first);
                                            },
                                          );
                                        },
                                      )
                                    else
                                      AfficheurClientGlobalWidget(
                                        nombreClients: clients.length,
                                        nombreInactifs: clients.where((c) => !c.etat).length,
                                        type: l10n.client,
                                        totalAchat: clientGlobalStats?.totalAchat,
                                        nomClientTopAchat: clientGlobalStats?.clientTopAchat?.nom,
                                        montantTopAchat: clientGlobalStats?.montantTopAchat,
                                        totalCredit: clientGlobalStats?.totalCredit,
                                        nomClientTopCredit: clientGlobalStats?.clientTopCredit?.nom,
                                        montantTopCredit: clientGlobalStats?.montantTopCredit,
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
                                              showBadge: _filtresClientActifs,
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
                                                await _exportToExcel();
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
                                                if (clientsSelectionnes.length == 1) {
                                                  ClientDetail(context, clientsSelectionnes.first);
                                                } else if (clientsSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
                                                    message: l10n.noClientSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
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
                                                if (clientsSelectionnes.isNotEmpty) {
                                                  bool contientNonSupprimable = clientsSelectionnes.any(
                                                        (client) => ListsConst.nonSupprimablePacks.any(
                                                          (p) => p.nom == "Client" && p.code == client.code,
                                                    ),
                                                  );

                                                  if (contientNonSupprimable) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.client,
                                                      message: l10n.cannotDeleteSystemClient,
                                                    );
                                                  } else {
                                                    await AnnulerClient(context, clientsSelectionnes);
                                                    await loadAllData();
                                                  }
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
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
                                                if (clientsSelectionnes.length == 1) {
                                                  bool contientNonSupprimable = clientsSelectionnes.any(
                                                        (client) => ListsConst.nonSupprimablePacks.any(
                                                          (p) => p.nom == "Client" && p.code == client.code,
                                                    ),
                                                  );

                                                  if (contientNonSupprimable) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.client,
                                                      message: l10n.cannotModifySystemClient,
                                                    );
                                                  } else {
                                                    await ClientModif(context, clientsSelectionnes.first);
                                                    await loadAllData();
                                                  }
                                                } else if (clientsSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
                                                    message: l10n.noClientSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
                                                    message: l10n.selectSingleClientToModify,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/stat_icon.png",
                                              color: Appstyle.lavande,
                                              onPressed: () async {
                                                if (clientsSelectionnes.length == 1) {
                                                  await SituationClientDialog(
                                                    context,
                                                    client: clientsSelectionnes.first,
                                                    panniers: paniersTest,
                                                    retours: retoursTest,
                                                    versements: verssementsTest,
                                                  );
                                                  await loadAllData();
                                                } else if (clientsSelectionnes.isEmpty) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
                                                    message: l10n.noClientSelected,
                                                  );
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.client,
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
                                                await ClientNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Filtres client
                                    if (filtresActifs)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV),
                                        child: filtreClient(setState,adjustedWidth, l10n, translator),
                                      ),

                                    if (!filtresActifs)
                                      SizedBox(height: paddingV / 2),

                                    // Tableau
                                    SizedBox(
                                      height: adjustedHeight * 0.68,
                                      child: TableauClientAdvanced(
                                        // ⚠️ Clé STABLE (pas basée sur clientsFiltres) : cf.
                                        // commentaire équivalent dans produit_screen.dart —
                                        // une clé qui change à chaque rafraîchissement force
                                        // Flutter à recréer tout l'état du tableau (tri,
                                        // sélection, pagination) au lieu de le préserver via
                                        // didUpdateWidget().
                                        key: const ValueKey('client-table'),
                                        clients: clientsFiltres,
                                        utilisateurs: utilisateursTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            clientsSelectionnes = selection;
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
                                    if (verssementClientsSelectionnes.length == 1)
                                      AfficheurVersement(
                                        versement: verssementClientsSelectionnes.first,
                                        nomBeneficiaire: _nomClientVersement(
                                            verssementClientsSelectionnes.first.beneficiareCode),
                                        onDetails: () {
                                          VersementDetail(context, verssementClientsSelectionnes.first);
                                        },
                                      )
                                    else
                                      AfficheurVersementGlobalWidget(
                                        nombreVersements: verssementsTest.length,
                                        totalVerse: _totalVerse(),
                                        montantMax: _versementMax()?.montant ?? 0,
                                        nomBeneficiaireMax: _versementMax() != null
                                            ? _nomClientVersement(_versementMax()!.beneficiareCode)
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
                                              iconColor:Appstyle.violet ,    onPressed: () {
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
                                              onPressed: () async {
                                                await _exportToExcel();
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
                                                if (verssementClientsSelectionnes.isNotEmpty) {
                                                  VersementDetail(context, verssementClientsSelectionnes.first);
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
                                              imagePath: "assets/icons/action/supprimer_icon.png",
                                              color: Appstyle.gris,
                                              onPressed: () async {
                                                if (verssementClientsSelectionnes.isNotEmpty) {
                                                  await ActiverVersements(context, verssementClientsSelectionnes);
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
                                                if (verssementClientsSelectionnes.length == 1) {
                                                  await VersementModif(
                                                    context,
                                                    verssementClientsSelectionnes.first,
                                                    typeInitial: "Client",
                                                  );
                                                  await loadAllData();
                                                } else {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.versement,
                                                    message: verssementClientsSelectionnes.isEmpty
                                                        ? l10n.noPaymentSelected
                                                        : l10n.selectSinglePaymentToModify,
                                                  );
                                                }
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await VersementNouveau(context, "Client");
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
                                        clients: clientsTest,
                                        utilisateurs: utilisateursTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            verssementClientsSelectionnes = selection;
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
                    ],
                  ),
                ),
              ),
          );
        },
      ),
    );
  }

  Widget filtreClient(void Function(VoidCallback fn) setState,double width, AppLocalizations l10n, ListsConstTranslator translator) {
    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.typeClient,
                  child: TextListe(
                    value: typeClientFilter != null ? translator.translateTypeClient(typeClientFilter!) : null,
                    items: translator.typeClientDisplayList,
                    onChanged: (v) {
                      setState(() {
                        typeClientFilter = translator.typeClientToFrench(v!);
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
                    value: activiteClientFilter != null ? translator.translateActiviteClient(activiteClientFilter!) : null,
                    items: translator.activiteClientDisplayList,
                    onChanged: (v) {
                      setState(() {
                        activiteClientFilter = translator.activiteClientToFrench(v!);
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
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  width: width * 0.75,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchController,
                    onChanged: (_) {
                      setState(() {
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
                  label: l10n.client,
                  child: TextListe(
                    value: clientFilterVersment ?? "",
                    items: clientFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        clientFilterVersment = v;
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
                    value: modepaiementFilter != null ? translator.translateModePaiement(modepaiementFilter!) : null,
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
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.from,
                  child: TextDate(
                    hint: l10n.startDate,
                    controller: _dateDebutCtrl,
                    onTap: _pickDateDebut,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(
                    hint: l10n.endDate,
                    enabled: dateDebut != null,
                    controller: _dateFinCtrl,
                    onTap: _pickDateFin,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              SizedBox(
                width: width * 0.75,
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
                          _appliquerPeriodeRapide(v, l10n);
                        });
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: width * 6 / 12,
            child: Row(
              children: [
                Expanded(
                  child: ChampAvecLabel(
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
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: ChampAvecLabel(
                    label: l10n.valide,
                    child: TextListe(
                      value: selectedEtatVErsementFilter != null
                          ? translator.translateEtatVersement(selectedEtatVErsementFilter!)
                          : null,
                      items: translator.etatVersementDisplayList,
                      onChanged: (v) {
                        setState(() {
                          selectedEtatVErsementFilter = translator.etatVersementToFrench(v!);
                          appliquerFiltreVers();
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
}