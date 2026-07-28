import 'dart:io';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/ParamZakat.dart';
import 'package:caisse_dz/Services/Zakat.dart' hide ApiResponse;
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/zakat/zakat_actif.dart';
import 'package:caisse_dz/core/dialog/zakat/zakat_detail.dart';
import 'package:caisse_dz/core/dialog/zakat/zakat_modif.dart';
import 'package:caisse_dz/core/dialog/zakat/zakat_nouveau.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/tableau/zakat/tableau_zakat.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_zakat.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_zakat_global.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/side_bar.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/paramZakat.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dialog/information_dialog.dart';
import '../core/utilis/api_response.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  // ✅ Constantes pour les index des tabs
  static const int TAB_ZAKAT = 0;
  static const int TAB_PARAMETRE = 1;

  final Map<String, String> periodesRapides = {
    "today": "today",
    "yesterday": "yesterday",
    "week": "thisWeek",
    "lastWeek": "lastWeek",
    "month": "thisMonth",
    "lastMonth": "lastMonth",
    "last7days": "last7Days",
    "last30days": "last30Days",
    "year": "thisYear",
    "lastYear": "lastYear",
  };

  List<Zakat> zakatTest = [];
  ParamZakat paramZakat = ParamZakat(
      id: 0,
      Nissab: 0,
      Taux: 0,
      creeParCode: 'ADMIN',
      dateCree: DateTime.now(),
  );

  // Plus besoin de selectedCardIndex, on utilise _tabController.index
  String nombre_zakat = "20";

  Future<void> _loadAllData() async {
    final zakats = await ZakatServices.getAllZakat();
    final param = await ParamZAKATServices.getParamZakat();

    setState(() {
      zakatTest = zakats;
      zakatsFiltres = zakats;
      paramZakat = param;
      nisabController.text = param.Nissab.toString();
      tauxZakatController.text = param.Taux.toString();
      nombre_zakat = zakats.length.toString();
      zakatsSelectionnes.clear();
    });
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

      if (currentTab == TAB_PARAMETRE) {
        Navigator.pop(context);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.parametre,
          message: l10n.noDataToExport,
        );
        return;
      }

      final zakatsToExport = filtresActifs ? zakatsFiltres : zakatTest;

      if (zakatsToExport.isEmpty) {
        Navigator.pop(context);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.zakat,
          message: l10n.noDataToExport,
        );
        return;
      }

      final excelFile = await ExcelGenerator.generateZakatExcel(
        zakats: zakatsToExport,
        l10n: l10n,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Zakat'];

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
            title: l10n.zakat,
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
      // ✅ Utilisation de _tabController.index
      final currentTab = _tabController.index;

      if (currentTab == TAB_PARAMETRE) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.parametre,
          message: l10n.noDataToExport,
        );
        return;
      }

      if (zakatsSelectionnes.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.zakat,
          message: l10n.noZakatSelected,
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

      final excelFile = await ExcelGenerator.generateZakatExcel(
        zakats: zakatsSelectionnes,
        l10n: l10n,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Zakat'];

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
            title: "${l10n.zakat} (${l10n.selected})",
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

  Future<ApiResponse<int>> SaveParam({
    required String UserCode,
    required String UserName,
  }) async {
    final db = await DbCreator.openDb();
    final service = await ParamZAKATServices(db);
    final serviceess = await HistoriqueServices(db);
    final l10n = AppLocalizations.of(context)!;

    ParamZakat param = ParamZakat(
      id: paramZakat.id,
      Nissab: double.parse(nisabController.text),
      Taux: double.parse(tauxZakatController.text),
      creeParCode: paramZakat.creeParCode,
      dateCree: paramZakat.dateCree,
      modifParCode: UserCode,
      dateModif: DateTime.now(),
    );

    final response = await service.updateZakat(param);
    final int id = await _GetNextHistoriqueId();

    final Historique histo = Historique(
      id: id,
      code: "HS $id ${DateTime.now().microsecondsSinceEpoch}",
      desc: "${l10n.modificationOf} ${l10n.zakatParameter} ${l10n.by} $UserName",
      oper: ListsConst.typeHisto[2],
      type: 'paramter',
      dateCree: DateTime.now(),
      creeParCode: UserCode,
    );

    await serviceess.addHistorique(histo);
    return response;
  }

  DateTime? dateDebut;
  DateTime? dateFin;
  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();
  String? periodeRapide;
  bool filtresActifs = false;
  static const double NISSAB_ZAKAT = 560000.00;
  static const double TAUX_ZAKAT = 2.5;

  List<Zakat> zakatsFiltres = [];
  List<Zakat> zakatsSelectionnes = [];

  double? montantMin;
  double? montantMax;
  String? selectedEtatFilter;
  final TextEditingController _searchController = TextEditingController();

  late final TextEditingController nisabController = TextEditingController(
      text: paramZakat.Nissab.toString()
  );
  late final TextEditingController tauxZakatController = TextEditingController(
    text: paramZakat.Taux.toString(),
  );

  double calculTotalZakat(List<Zakat> list) {
    return list.fold(0.0, (sum, z) => sum + z.montantZakat);
  }

  int calculZakatPayee(List<Zakat> list) {
    return list.where((z) => z.statut == "PAYEE").length;
  }

  int calculZakatNonPayee(List<Zakat> list) {
    return list.where((z) => z.statut != "PAYEE").length;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          zakatsSelectionnes.clear();
        });
      }
    });
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _getLocalizedPeriod(String key, AppLocalizations l10n) {
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

  void _appliquerPeriodeRapide(String p) {
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
    appliquerFiltre();
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

  void appliquerFiltre() {
    zakatsFiltres = zakatTest.where((z) {
      final searchText = _searchController.text.toLowerCase();
      final searchOk = searchText.isEmpty || z.searchableText.contains(searchText);
      final montantOk = (montantMin == null || z.creances >= montantMin!) &&
          (montantMax == null || z.creances <= montantMax!);
      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && z.etat) ||
          (selectedEtatFilter == "Inactif" && !z.etat);
      final dateOk = () {
        if (dateDebut == null && dateFin == null) return true;
        final d = z.dateDebutHawl;
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

      return searchOk && montantOk && etatOk && dateOk;
    }).toList();

    if (_searchController.text.isEmpty &&
        montantMin == null &&
        montantMax == null &&
        dateDebut == null &&
        dateFin == null &&
        selectedEtatFilter == null) {
      zakatsFiltres = zakatTest;
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
        appliquerFiltre();
      });
    }
  }

  void supprimerFiltre() {
    _searchController.clear();
    montantMin = null;
    montantMax = null;
    selectedEtatFilter = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;

    // ✅ Noms des tabs
    final tabNames = [
      l10n.zakat,
      l10n.parametre,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/zakat_icon.png',
      'assets/icons/sidebar/parametre_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_zakat,
      '',
    ];

    return Scaffold(
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

          return Directionality(
            textDirection: textDirection,
            child: SingleChildScrollView(
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
                                            "assets/icons/sidebar/zakat_icon.png",
                                            width: 40,
                                            color: Appstyle.violet,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            "${l10n.zakat} (${tabNames[currentTab]})",
                                            style: Appstyle.textXLB.copyWith(
                                              color: Appstyle.violet,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Spacer(),
                                      /// -------- RIGHT (Time + Account)
                                      Row(
                                        textDirection: textDirection,
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
                                      color: currentTab == TAB_ZAKAT
                                          ? Appstyle.violet
                                          : Appstyle.crevete,
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
                                        text: index == TAB_PARAMETRE
                                            ? tabNames[index]
                                            : "${tabNames[index]} (${tabCounts[index]})",
                                      );
                                    }),
                                  ),
                                ),

                                SizedBox(height: paddingV / 2),

                                // ═══════════════════════════════════════════════════════════════════════════════
                                // SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
                                // ═══════════════════════════════════════════════════════════════════════════════

                                // ──────────────────────────────────────────────────────────────
                                // 1. CAS ZAKAT (currentTab == TAB_ZAKAT)
                                // ──────────────────────────────────────────────────────────────
                                if (currentTab == TAB_ZAKAT)
                                  Column(
                                    crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                    children: [
                                      // Afficheur
                                      if (zakatsSelectionnes.length == 1)
                                        AfficheurZakat(
                                          zakat: zakatsSelectionnes.first,
                                          onDetails: () {
                                            ZakatDetail(context, zakatsSelectionnes.first);
                                          },
                                        )
                                      else
                                        DashboardZakat(
                                          totalZakat: calculTotalZakat(zakatsFiltres),
                                          nissab: NISSAB_ZAKAT,
                                          tauxZakat: TAUX_ZAKAT,
                                          zakatPayee: calculZakatPayee(zakatsFiltres),
                                          zakatNonPayee: calculZakatNonPayee(zakatsFiltres),
                                        ),

                                      SizedBox(height: paddingV / 2),

                                      // Filtres & Actions - Style FournisseurScreen
                                      Row(
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
                                                icon: filtresActifs
                                                    ? Icons.visibility_off
                                                    : Icons.visibility,
                                                iconColor: Appstyle.violet,
                                                onPressed: () {
                                                  setState(() {
                                                    filtresActifs = !filtresActifs;
                                                    if (!filtresActifs) {
                                                      supprimerFiltre();
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
                                                      supprimerFiltre();
                                                      appliquerFiltre();
                                                    });
                                                  },
                                                ),
                                              if (filtresActifs)
                                                SizedBox(width: paddingH / 4),
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
                                            children: [
                                              MainIconButton(
                                                color: Appstyle.violet,
                                                imagePath: 'assets/icons/action/detail_icon.png',
                                                onPressed: () async {
                                                  if (zakatsSelectionnes.length == 1) {
                                                    ZakatDetail(context, zakatsSelectionnes.first);
                                                  } else if (zakatsSelectionnes.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.zakat,
                                                      message: l10n.noZakatSelected,
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.zakat,
                                                      message: l10n.selectSingleZakatForDetail,
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 5),
                                              MainIconButton(
                                                color: Appstyle.gris,
                                                imagePath: 'assets/icons/action/supprimer_icon.png',
                                                onPressed: () async {
                                                  if (zakatsSelectionnes.length == 1) {
                                                    await AnnulerZakat(context, zakatsSelectionnes);
                                                    await _loadAllData();
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.zakat,
                                                      message: l10n.noZakatSelected,
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 5),
                                              MainIconButton(
                                                color: Appstyle.blueC,
                                                imagePath: 'assets/icons/action/edit_icon.png',
                                                onPressed: () async {
                                                  if (zakatsSelectionnes.length == 1) {
                                                    await ZakatModif(context, zakatsSelectionnes.first);
                                                    await _loadAllData();
                                                  } else if (zakatsSelectionnes.isEmpty) {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.zakat,
                                                      message: l10n.noZakatSelected,
                                                    );
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.zakat,
                                                      message: l10n.selectSingleZakatToModify,
                                                    );
                                                  }
                                                },
                                              ),
                                              SizedBox(width: paddingH / 5),
                                              MainButton(
                                                text: l10n.newWord,
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  await ZakatNouveau(context);
                                                  await _loadAllData();
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Filtres
                                      if (filtresActifs)
                                        Padding(
                                          padding: EdgeInsets.symmetric(vertical: paddingV / 2),
                                          child: filtreZakat(paddingH, adjustedWidth / 3, l10n, isRTL),
                                        ),

                                      SizedBox(height: paddingV),

                                      // Tableau
                                      SizedBox(
                                        height: adjustedHeight * 0.75,
                                        child: TableauZakatAdvanced(
                                          zakats: zakatsFiltres,
                                          key: ValueKey(zakatsFiltres),
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              zakatsSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

                                // ──────────────────────────────────────────────────────────────
                                // 2. CAS PARAMETRE (currentTab == TAB_PARAMETRE)
                                // ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_PARAMETRE)
                                  Container(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          width: adjustedWidth * 0.35,
                                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                                          decoration: BoxDecoration(
                                            color: Appstyle.Tblanc,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: isRTL ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.zakatParameter,
                                                style: Appstyle.textMB.copyWith(color: Appstyle.Tnoir),
                                              ),
                                              SizedBox(height: 20),
                                              ChampAvecLabel(
                                                label: l10n.nissab,
                                                child: TextChampL(
                                                  controller: nisabController,
                                                  hint: '560000.00 DA',
                                                  numeric: true,
                                                ),
                                              ),
                                              SizedBox(height: 20),
                                              ChampAvecLabel(
                                                label: l10n.zakatRate,
                                                child: TextChampL(
                                                  controller: tauxZakatController,
                                                  hint: '2.5',
                                                  numeric: true,
                                                ),
                                              ),
                                              SizedBox(height: 30),
                                              MainButton(
                                                text: l10n.save,
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  final response = await SaveParam(
                                                    UserName: userName,
                                                    UserCode: userCode,
                                                  );
                                                  if (!response.success) {
                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                      SnackBar(
                                                        content: Text(l10n.settingsNotSaved),
                                                        backgroundColor: Colors.red,
                                                      ),
                                                    );
                                                    return;
                                                  }
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text(l10n.settingsSavedSuccess),
                                                      backgroundColor: Colors.green,
                                                    ),
                                                  );
                                                },
                                                iconOnRight: !isRTL,
                                                icon: Icons.save,
                                              ),
                                            ],
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
            ),
          );
        },
      ),
    );
  }

  Widget filtreZakat(double paddingH, double width, AppLocalizations l10n, bool isRTL) {
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
              SizedBox(
                width: width * 0.9,
                child: Row(
                  textDirection: textDirection,
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
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.state,
                  child: TextListe(
                    value: selectedEtatFilter,
                    items: [l10n.active, l10n.inactive],
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          Row(
            textDirection: textDirection,
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
                width: 400,
                child: ChampAvecLabel(
                  label: l10n.quickPeriod,
                  child: DropdownButtonFormField<String>(
                    value: periodeRapide,
                    decoration: InputDecoration(
                      hintText: l10n.choosePeriod,
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    items: periodesRapides.entries.map((e) {
                      return DropdownMenuItem<String>(
                        value: e.key,
                        child: Text(_getLocalizedPeriod(e.key, l10n)),
                      );
                    }).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          periodeRapide = v;
                          _appliquerPeriodeRapide(v);
                        });
                      }
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
}