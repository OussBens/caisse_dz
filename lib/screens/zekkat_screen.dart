import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/paramZakat.dart';
import 'package:caisse_dz/Services/ParamZakat.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'package:caisse_dz/Services/Zakat.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
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
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/dialog/information_dialog.dart';


class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  // Garde anti-double-clic pour l'export Excel (voir client_screen.dart pour
  // le détail du bug évité).
  bool _exportEnCours = false;

  List<Zakat> zakatTest = [];
  List<Utilisateur> utilisateursTest = [];

  String nombre_zakat = "20";

  Future<void> _loadAllData() async {
    final zakats = await ZakatServices.getAllZakat();
    final utilisateurs = await UtilisateurServices.getAllUtilisateurs();
    ParamZakat? param;
    try {
      param = await ParamZAKATServices.getParamZakat();
    } catch (e) {
      debugPrint('ZakatScreen: paramètres zakat indisponibles: $e');
    }
    if (!mounted) return;

    setState(() {
      nissabParam = param?.Nissab;
      tauxParam = param?.Taux;
      zakatTest = zakats;
      zakatsFiltres = zakats;
      utilisateursTest = utilisateurs;
      nombre_zakat = zakats.length.toString();
      zakatsSelectionnes.clear();
    });
  }

  Future<void> _exportCurrentModuleToExcel({bool enPdf = false}) async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final l10n = AppLocalizations.of(context)!;

      final zakatsToExport = filtresActifs ? zakatsFiltres : zakatTest;

      if (zakatsToExport.isEmpty) {
        fermerSpinner();
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

      fermerSpinner();

      // Decode the Excel file to show preview
      // Extract PDF : même fichier que l'export Excel, mis en page en PDF.
      if (enPdf) {
        fermerSpinner();
        await ouvrirApercuPdfDepuisExcel(context, fichier: excelFile, titre: AppLocalizations.of(context)!.zakat);
        return;
      }

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
            title: l10n.zakat,
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

  Future<void> _exportSelectedToExcel() async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final l10n = AppLocalizations.of(context)!;

    try {
      if (zakatsSelectionnes.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.zakat,
          message: l10n.noZakatSelected,
        );
        return;
      }

      final excelFile = await executerAvecSpinner(context, () => ExcelGenerator.generateZakatExcel(
        zakats: zakatsSelectionnes,
        l10n: l10n,
      ));

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

  DateTime? dateDebut;
  DateTime? dateFin;
  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();
  String? periodeRapide;
  bool filtresActifs = false;
  // Nissab et taux affichés dans les cards : lus depuis Paramètres > Zakat
  // (table zakatParam), comme le dialog Nouvelle Zakat. Null tant que non
  // chargés ou si la lecture échoue (la card affiche alors 0).
  double? nissabParam;
  double? tauxParam;

  List<Zakat> zakatsFiltres = [];
  List<Zakat> zakatsSelectionnes = [];

  double? montantMin;
  double? montantMax;
  String? selectedEtatFilter;
  final TextEditingController _searchController = TextEditingController();

  // Seules les zakats actives (non annulées) comptent. Le statut stocké est
  // la valeur française de ListsConst.statutZakatList ("Non payé" / "Payée").
  double calculTotalZakat(List<Zakat> list) {
    return list.where((z) => z.etat).fold(0.0, (sum, z) => sum + z.montantZakat);
  }

  int calculZakatPayee(List<Zakat> list) {
    return list.where((z) => z.etat && z.statut == ListsConst.statutZakatList[1]).length;
  }

  int calculZakatNonPayee(List<Zakat> list) {
    return list.where((z) => z.etat && z.statut != ListsConst.statutZakatList[1]).length;
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
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

  // ✅ Vrai si au moins un champ de filtre zakat est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresZakatActifs =>
      montantMin != null ||
      montantMax != null ||
      selectedEtatFilter != null ||
      dateDebut != null ||
      dateFin != null ||
      periodeRapide != null ||
      _searchController.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

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
                                            l10n.zakat,
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
                                          nissab: nissabParam ?? 0,
                                          tauxZakat: tauxParam ?? 0,
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
                                                showBadge: _filtresZakatActifs,
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
                                                  color: Appstyle.neutral300,
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
                                                textColor: Appstyle.success,
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
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              zakatsSelectionnes = selection;
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
              ChampAvecLabel(
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
              ChampAvecLabel(
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
            ],
          ),
          SizedBox(height: 15),
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
                    _appliquerPeriodeRapide(v);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
