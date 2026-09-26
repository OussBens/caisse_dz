import 'dart:io';

import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/role/role_detail.dart';
import 'package:caisse_dz/core/dialog/utilisateur/utilisateur_detail.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_role.dart';
import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dialog/information_dialog.dart';
import '../core/dialog/role/role_actif.dart';
import '../core/dialog/role/role_modif.dart';
import '../core/dialog/role/role_nouveau.dart';
import '../core/dialog/utilisateur/utilisateur_actif.dart';
import '../core/dialog/utilisateur/utilisateur_modif.dart';
import '../core/dialog/utilisateur/utilisateur_nouveau.dart';

import '../core/tableau/role/tableau_role.dart';
import '../core/tableau/utilisateur/tableau_utilisateur.dart';

import '../core/theme/app_style.dart';

import '../core/utilis/constant.dart';

import '../core/widget/afficheur/afficheur_utilisateur.dart';
import '../core/widget/afficheur/afficheur_utilisateur_global.dart';
import '../core/widget/button/Icon_button.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/header_module.dart';
import '../core/widget/side_bar.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/connection_status_bar.dart';
import '../core/widget/account.dart';
import '../data/models/gestion_caisse.dart';
import '../data/models/pannier.dart';
import '../data/models/role.dart';
import '../data/models/utilisateur.dart';
import '../l10n/app_localizations.dart';

String userName = AuthState().username ?? " ";
String userCode = AuthState().userCode ?? " ";

class UtilisateurScreen extends StatefulWidget {
  const UtilisateurScreen({super.key});

  @override
  State<UtilisateurScreen> createState() => _UtilisateurScreenState();
}

class _UtilisateurScreenState extends State<UtilisateurScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_UTILISATEUR = 0;
  static const int TAB_ROLE = 1;

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  int nombreUtilisateur = 5;
  int nombreRole = 0;

  List<Role>        rolesTest                 = [];
  List<Role>        rolesSelectionnes         = [];
  List<Utilisateur> utilisateurs              = [];
  List<Utilisateur> utilisateursSelectionnes  = [];
  List<Pannier>     panniersTest              = [];
  List<CaisseGestion> caissesTest             = [];

  final TextEditingController _searchController = TextEditingController();

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          rolesSelectionnes.clear();
          utilisateursSelectionnes.clear();
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
    try {
      final utilisateursd = await UtilisateurServices.getAllUtilisateurs();
      final roles         = await RoleServices.getAllRoles();
      final panniers      = await PannierServices.getAllPanniers();
      final caisses       = await GCServices.getAllCaisses();

      if (!mounted) return;
      setState(() {
        rolesTest         = roles;
        utilisateurs      = utilisateursd;
        panniersTest      = panniers;
        caissesTest       = caisses;
        nombreUtilisateur = utilisateursd.length;
        nombreRole        = roles.length;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error ?? "Erreur",
        titre_concerne: l10n.utilisateur,
        message: l10n.loadingError ?? "Erreur de chargement les données !",
      );
      setState(() {
        utilisateurs  = [];
        rolesTest     = [];
        panniersTest  = [];
        caissesTest   = [];
        isLoading     = false;
        utilisateursSelectionnes.clear();
        rolesSelectionnes.clear();
      });
    }
  }

  // Excel Export Methods (adaptées avec _tabController.index)
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

      // ✅ Utilisation de _tabController.index
      final currentTab = _tabController.index;

      File? excelFile;
      String moduleName = '';

      if (currentTab == TAB_UTILISATEUR) {
        // Utilisateurs
        if (utilisateurs.isEmpty) {
          Navigator.pop(context);
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.utilisateur,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.utilisateur;
        excelFile = await ExcelGenerator.generateUtilisateursExcel(
          utilisateurs: utilisateurs,
          l10n: l10n,
        );
      } else {
        // Roles
        if (rolesTest.isEmpty) {
          Navigator.pop(context);
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.role,
            message: l10n.noDataToExport,
          );
          return;
        }

        moduleName = l10n.role;
        excelFile = await ExcelGenerator.generateRolesExcel(
          roles: rolesTest,
          l10n: l10n,
        );
      }

      Navigator.pop(context);

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_UTILISATEUR ? 'Utilisateurs' : 'Roles';
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

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // ✅ Utilisation de _tabController.index
      final currentTab = _tabController.index;

      File? excelFile;
      String moduleName = '';

      if (currentTab == TAB_UTILISATEUR) {
        // Utilisateurs
        if (utilisateursSelectionnes.isEmpty) {
          Navigator.pop(context);
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.utilisateur,
            message: l10n.noUserSelected ?? "No user selected",
          );
          return;
        }

        moduleName = l10n.utilisateur;
        excelFile = await ExcelGenerator.generateUtilisateursExcel(
          utilisateurs: utilisateursSelectionnes,
          l10n: l10n,
        );
      } else {
        // Roles
        if (rolesSelectionnes.isEmpty) {
          Navigator.pop(context);
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.role,
            message: l10n.noRoleSelected ?? "No role selected",
          );
          return;
        }

        moduleName = l10n.role;
        excelFile = await ExcelGenerator.generateRolesExcel(
          roles: rolesSelectionnes,
          l10n: l10n,
        );
      }

      Navigator.pop(context);

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      final sheetName = currentTab == TAB_UTILISATEUR ? 'Utilisateurs' : 'Roles';
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

  // --------------------------------- STATISTIQUES
  int getTotalUtilisateurs() => utilisateurs.length;
  int getUtilisateursActifs() =>
      utilisateurs.where((u) => u.etat == "actif").length;
  int getUtilisateursInactifs() =>
      utilisateurs.where((u) => u.etat == "inactif").length;
  int getUtilisateursAdmin() =>
      utilisateurs.where((u) => u.role == "Admin").length;
  int getUtilisateursCaissier() =>
      utilisateurs.where((u) => u.role == "Caissier").length;
  int getUtilisateursMagasinier() =>
      utilisateurs.where((u) => u.role == "Magasinier").length;

  // Montant total vendu (paniers actifs) par caissier, utilisé pour repérer
  // le meilleur et le plus faible vendeur.
  Map<String, double> _totalVentesParCaissier() {
    final Map<String, double> totaux = {};
    for (final p in panniersTest.where((p) => p.etat)) {
      totaux[p.caissier_code] = (totaux[p.caissier_code] ?? 0) + p.montant;
    }
    return totaux;
  }

  String? _nomUtilisateurParCode(String code) =>
      utilisateurs.firstWhereOrNull((u) => u.code == code)?.username;

  String? getNomTopVendeur() {
    final totaux = _totalVentesParCaissier();
    if (totaux.isEmpty) return null;
    final code = totaux.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return _nomUtilisateurParCode(code);
  }

  double? getMontantTopVendeur() {
    final totaux = _totalVentesParCaissier();
    if (totaux.isEmpty) return null;
    return totaux.values.reduce((a, b) => a >= b ? a : b);
  }

  String? getNomFaibleVendeur() {
    final totaux = _totalVentesParCaissier();
    if (totaux.isEmpty) return null;
    final code = totaux.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
    return _nomUtilisateurParCode(code);
  }

  double? getMontantFaibleVendeur() {
    final totaux = _totalVentesParCaissier();
    if (totaux.isEmpty) return null;
    return totaux.values.reduce((a, b) => a <= b ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
    final Color headerColor = currentTab == TAB_UTILISATEUR ? Appstyle.violet : Appstyle.indigo;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.utilisateur,
      l10n.role,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/profile_icon.png',
      'assets/icons/role_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombreUtilisateur.toString(),
      nombreRole.toString(),
    ];

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Directionality(
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
                      child: Row(
                        textDirection: textDirection,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // -------------------------------- Sidebar
                          SideBarWidget(),

                          // -------------------------------- CONTENT
                          Expanded(
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
                                        /// -------- LEFT (Icon + Title)
                                        Row(
                                          textDirection: textDirection,
                                          children: [
                                            Image.asset(
                                              "assets/icons/sidebar/profile_icon.png",
                                              width: 40,
                                              color: headerColor,
                                            ),
                                            const SizedBox(width: 10),
                                            Row(
                                              textDirection: textDirection,
                                              children: [
                                                Text(
                                                  l10n.utilisateur,
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
                                            ),
                                          ],
                                        ),

                                        const Spacer(),

                                        /// -------- RIGHT (Time + Account)
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
                                        color: currentTab == TAB_UTILISATEUR
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

                                  SizedBox(height: paddingV / 2),

                                  // ═══════════════════════════════════════════════════════════════════════════════
                                  // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                  // ═══════════════════════════════════════════════════════════════════════════════

                                  // ──────────────────────────────────────────────────────────────
                                  // 1. CAS UTILISATEUR (currentTab == TAB_UTILISATEUR)
                                  // ──────────────────────────────────────────────────────────────
                                  if (currentTab == TAB_UTILISATEUR)
                                    Column(
                                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // Afficheur
                                        if (utilisateursSelectionnes.length == 1)
                                          AfficheurUtilisateur(
                                            utilisateur: utilisateursSelectionnes.first,
                                            onDetails: () {
                                              UtilisateurDetail(context, utilisateursSelectionnes.first);
                                            },
                                          )
                                        else
                                          AfficheurUtilisateurGlobalWidget(
                                            nombreUtilisateurs: getTotalUtilisateurs(),
                                            nombreInactifs: getUtilisateursInactifs(),
                                            nombreRoles: rolesTest.length,
                                            nomTopVendeur: getNomTopVendeur(),
                                            montantTopVendeur: getMontantTopVendeur(),
                                            nomFaibleVendeur: getNomFaibleVendeur(),
                                            montantFaibleVendeur: getMontantFaibleVendeur(),
                                          ),

                                        SizedBox(height: paddingV / 2),

                                        // Actions - Style FournisseurScreen
                                        Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // EXTRACT ALL Button
                                            Row(
                                              children: [
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor: Colors.green,
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
                                            Row(
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (utilisateursSelectionnes.length == 1) {
                                                      UtilisateurDetail(context, utilisateursSelectionnes.first);
                                                    } else if (utilisateursSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.utilisateur,
                                                        message: l10n.noUserSelected ?? "Aucun utilisateur sélectionné !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.utilisateur,
                                                        message: l10n.selectSingleUserForDetail ?? "Veuillez sélectionner un seul utilisateur pour afficher le détail !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/supprimer_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed: () async {
                                                    if (utilisateursSelectionnes.isNotEmpty) {
                                                      await AnnulerUtilisateur(context, utilisateursSelectionnes);
                                                      await loadAllData();
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.utilisateur,
                                                        message: l10n.noUserSelected ?? "Aucun utilisateur sélectionné !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async {
                                                    if (utilisateursSelectionnes.length == 1) {
                                                      await UtilisateurModif(context, utilisateursSelectionnes.first);
                                                      await loadAllData();
                                                    } else if (utilisateursSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.utilisateur,
                                                        message: l10n.noUserSelected ?? "Aucun utilisateur sélectionné !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.utilisateur,
                                                        message: l10n.selectSingleUserToModify ?? "Veuillez sélectionner un seul utilisateur pour modifier !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await UtilisateurNouveau(context);
                                                    await loadAllData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: paddingV / 4),

                                        // Tableau
                                        SizedBox(
                                          height: adjustedHeight * 0.7,
                                          child: TableauUtilisateurAdvanced(
                                            utilisateurs: utilisateurs,
                                            caisses: caissesTest,
                                            key: ValueKey(utilisateurs),
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                utilisateursSelectionnes = selection;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )

                                  // ──────────────────────────────────────────────────────────────
                                  // 2. CAS ROLE (currentTab == TAB_ROLE)
                                  // ──────────────────────────────────────────────────────────────
                                  else if (currentTab == TAB_ROLE)
                                    Column(
                                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        // Afficheur
                                        if (rolesSelectionnes.length == 1)
                                          AfficheurRole(
                                            role: rolesSelectionnes.first,
                                            onDetails: () {
                                              RoleDetail(context, rolesSelectionnes.first);
                                            },
                                          )
                                        else
                                          AfficheurUtilisateurGlobalWidget(
                                            nombreUtilisateurs: getTotalUtilisateurs(),
                                            nombreInactifs: getUtilisateursInactifs(),
                                            nombreRoles: rolesTest.length,
                                            nomTopVendeur: getNomTopVendeur(),
                                            montantTopVendeur: getMontantTopVendeur(),
                                            nomFaibleVendeur: getNomFaibleVendeur(),
                                            montantFaibleVendeur: getMontantFaibleVendeur(),
                                          ),

                                        SizedBox(height: paddingV / 2),

                                        // Actions - Style FournisseurScreen
                                        Row(
                                          textDirection: textDirection,
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // EXTRACT ALL Button
                                            Row(
                                              children: [
                                                MainButton(
                                                  text: l10n.extract,
                                                  textColor: Colors.green,
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
                                            Row(
                                              children: [
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/detail_icon.png",
                                                  color: Appstyle.violet,
                                                  onPressed: () async {
                                                    if (rolesSelectionnes.length == 1) {
                                                      RoleDetail(context, rolesSelectionnes.first);
                                                    } else if (rolesSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.role,
                                                        message: l10n.noRoleSelected ?? "Aucun rôle sélectionné !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.role,
                                                        message: l10n.selectSingleRoleForDetail ?? "Veuillez sélectionner un seul rôle pour afficher le détail !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/annuler_icon.png",
                                                  color: Appstyle.gris,
                                                  onPressed: () async {
                                                    if (rolesSelectionnes.isNotEmpty) {
                                                      await AnnulerRole(context, rolesSelectionnes);
                                                      await loadAllData();
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.role,
                                                        message: l10n.noRoleSelected ?? "Aucun rôle sélectionné !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainIconButton(
                                                  imagePath: "assets/icons/action/edit_icon.png",
                                                  color: Appstyle.blueC,
                                                  onPressed: () async {
                                                    if (rolesSelectionnes.length == 1) {
                                                      await RoleModif(context, rolesSelectionnes.first);
                                                      await loadAllData();
                                                    } else if (rolesSelectionnes.isEmpty) {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.role,
                                                        message: l10n.noRoleSelected ?? "Aucun rôle sélectionné !",
                                                      );
                                                    } else {
                                                      await InformationDialog(
                                                        context: context,
                                                        titre_type_message: l10n.information,
                                                        titre_concerne: l10n.role,
                                                        message: l10n.selectSingleRoleToModify ?? "Veuillez sélectionner un seul rôle pour modifier !",
                                                      );
                                                    }
                                                  },
                                                ),
                                                SizedBox(width: paddingH / 4),
                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await RoleNouveau(context);
                                                    await loadAllData();
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: paddingV / 4),

                                        // Tableau
                                        SizedBox(
                                          height: adjustedHeight * 0.7,
                                          child: TableauRoleAdvanced(
                                            roles: rolesTest,
                                            key: ValueKey(rolesTest),
                                            utilisateurs: utilisateurs,
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                rolesSelectionnes = selection;
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
              ),
            );
          },
        ),
      ),
    );
  }
}