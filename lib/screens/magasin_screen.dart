import 'dart:io';

import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_magasin.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/dialog/information_dialog.dart';
import '../core/dialog/magasin/magasin_actif.dart' hide MagasinDetail;
import '../core/dialog/magasin/magasin_detail.dart';
import '../core/dialog/magasin/magasin_modif.dart';
import '../core/dialog/magasin/magasin_nouveau.dart';
import '../core/tableau/magasin/tableau_magasin.dart';
import '../core/widget/champ/champ_avec_label.dart';
import '../core/widget/champ/liste_champ.dart';
import '../core/widget/champ/radio_champ.dart';
import '../core/widget/fourchette._widget.dart';
import '../core/widget/header_module.dart';
import '../data/constant.dart';
import '../data/models/magasin.dart';
import '../core/theme/app_style.dart';
import '../core/utilis/constant.dart';
import '../core/widget/side_bar.dart';
import '../core/widget/account.dart';
import '../core/widget/time_date_widget.dart';
import '../core/widget/button/main_button.dart';
import '../core/widget/button/Icon_button.dart';
import '../core/widget/search_bar.dart';
import '../l10n/app_localizations.dart';

String userName = AuthState().username ?? " ";
String userCode = AuthState().userCode ?? " ";

class MagasinScreen extends StatefulWidget {
  const MagasinScreen({super.key});

  @override
  State<MagasinScreen> createState() => _MagasinScreenState();
}

class _MagasinScreenState extends State<MagasinScreen> {
  bool filtresActifs = false;
  final TextEditingController _searchController = TextEditingController();

  String? selectedEtatFilter;
  List<Magasin> magasinFiltres = [];

  List<Magasin> magasinsTest = [];
  List<Magasin> magasins = [];
  List<Magasin> magasinsSelectionnes = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    try {
      final magasine = await MagasinServices.getAllMagasins();

      if (!mounted) return;
      setState(() {
        magasinsTest = magasine;
        magasins = magasinsTest;
        magasinFiltres = magasinsTest;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("${l10n.loadingError}: $e")),
      );
      setState(() {
        magasinsTest = [];
        isLoading = false;
        magasinsSelectionnes.clear();
      });
    }
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

      final magasinsToExport = filtresActifs ? magasinFiltres : magasinsTest;

      if (magasinsToExport.isEmpty) {
        Navigator.pop(context);
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.magasin,
          message: l10n.noDataToExport,
        );
        return;
      }

      final excelFile = await ExcelGenerator.generateMagasinsExcel(
        magasins: magasinsToExport,
        l10n: l10n,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Magasins'];

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
            title: l10n.magasin,
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
      if (magasinsSelectionnes.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.magasin,
          message: l10n.noStoreSelected ?? "No store selected",
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

      final excelFile = await ExcelGenerator.generateMagasinsExcel(
        magasins: magasinsSelectionnes,
        l10n: l10n,
      );

      Navigator.pop(context);

      // Decode the Excel file to show preview
      final excel = Excel.decodeBytes(await excelFile.readAsBytes());

      var sheet = excel.tables['Magasins'];

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
            title: "${l10n.magasin} (${l10n.selected})",
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

  void appliquerFiltre() {
    magasinFiltres = magasinsTest.where((p) {
      final searchText = _searchController.text.toLowerCase();
      final searchOk = searchText.isEmpty || p.searchableText.contains(searchText);

      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && p.etat) ||
          (selectedEtatFilter == "Inactif" && !p.etat);

      return etatOk && searchOk;
    }).toList();

    if (selectedEtatFilter == null &&
        _searchController.text.isEmpty) {
      magasinFiltres = magasinsTest;
    }
  }

  void supprimerFilter() {
    selectedEtatFilter = null;
    _searchController.clear();
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


            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
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
                                              "assets/icons/sidebar/magasin_icon.png",
                                              width: 40,
                                              color: Appstyle.green2,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(
                                              l10n.magasin,
                                              style: Appstyle.textXLB.copyWith(
                                                color: Appstyle.green2,
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

                                  if (magasinsSelectionnes.length == 1)
                                    AfficheurMagasin(
                                      magasin: magasinsSelectionnes.first,
                                      onDetails: () {
                                        MagasinDetail(context, magasinsSelectionnes.first);
                                      },
                                    ),

                                  SizedBox(height: paddingV),

                                  Row(
                                    textDirection: textDirection,
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Button afficher et masquer les filtres
                                      Row(
                                        textDirection: textDirection,
                                        children: [
                                          MainButton(
                                            text: l10n.filter,
                                            textColor: Appstyle.violet,
                                            color: Appstyle.Tblanc,
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

                                      // Actions
                                      Row(
                                        textDirection: textDirection,
                                        children: [
                                          MainIconButton(
                                            imagePath: "assets/icons/action/detail_icon.png",
                                            color: Appstyle.violet,
                                            onPressed: () async {
                                              if (magasinsSelectionnes.isNotEmpty) {
                                                MagasinDetail(context, magasinsSelectionnes.first);
                                              } else if (magasinsSelectionnes.isEmpty) {
                                                await InformationDialog(
                                                  context: context,
                                                  titre_type_message: l10n.information,
                                                  titre_concerne: l10n.magasin,
                                                  message: l10n.noStoreSelected ?? "Aucun magasin sélectionné !",
                                                );
                                              } else {
                                                await InformationDialog(
                                                  context: context,
                                                  titre_type_message: l10n.information,
                                                  titre_concerne: l10n.magasin,
                                                  message: l10n.selectSingleStoreForDetail ?? "Veuillez sélectionner un seul magasin pour afficher le détail !",
                                                );
                                              }
                                            },
                                          ),

                                          SizedBox(width: paddingH / 4),

                                          MainIconButton(
                                            imagePath: "assets/icons/action/supprimer_icon.png",
                                            color: Appstyle.gris,
                                            onPressed: () async {
                                              if (magasinsSelectionnes.isNotEmpty) {
                                                bool contientNonSupprimable = magasinsSelectionnes.any(
                                                      (mag) => ListsConst.nonSupprimablePacks.any(
                                                        (p) => p.nom == "Magasin" && p.code == mag.code,
                                                  ),
                                                );

                                                if (contientNonSupprimable) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.magasin,
                                                    message: l10n.cannotDeleteSystemStore ?? "Impossible de supprimer ce magasin (Système) !",
                                                  );
                                                } else {
                                                  await AnnulerMagasin(context, magasinsSelectionnes);
                                                  await loadAllData();
                                                }
                                              } else {
                                                await InformationDialog(
                                                  context: context,
                                                  titre_type_message: l10n.information,
                                                  titre_concerne: l10n.magasin,
                                                  message: l10n.noStoreSelected ?? "Aucun magasin sélectionné !",
                                                );
                                              }
                                            },
                                          ),

                                          SizedBox(width: paddingH / 4),

                                          MainIconButton(
                                            imagePath: "assets/icons/action/edit_icon.png",
                                            color: Appstyle.blueC,
                                            onPressed: () async {
                                              if (magasinsSelectionnes.length == 1) {
                                                bool contientNonSupprimable = magasinsSelectionnes.any(
                                                      (mag) => ListsConst.nonSupprimablePacks.any(
                                                        (p) => p.nom == "Magasin" && p.code == mag.code,
                                                  ),
                                                );

                                                if (contientNonSupprimable) {
                                                  await InformationDialog(
                                                    context: context,
                                                    titre_type_message: l10n.information,
                                                    titre_concerne: l10n.magasin,
                                                    message: l10n.cannotModifySystemStore ?? "Impossible de modifier ce magasin (Système) !",
                                                  );
                                                } else {
                                                  await MagasinModif(context, magasinsSelectionnes.first);
                                                  await loadAllData();
                                                }
                                              } else if (magasinsSelectionnes.isEmpty) {
                                                await InformationDialog(
                                                  context: context,
                                                  titre_type_message: l10n.information,
                                                  titre_concerne: l10n.magasin,
                                                  message: l10n.noStoreSelected ?? "Aucun magasin sélectionné !",
                                                );
                                              } else {
                                                await InformationDialog(
                                                  context: context,
                                                  titre_type_message: l10n.information,
                                                  titre_concerne: l10n.magasin,
                                                  message: l10n.selectSingleStoreToModify ?? "Veuillez sélectionner un seul magasin pour modifier !",
                                                );
                                              }
                                            },
                                          ),

                                          SizedBox(width: paddingH / 4),

                                          Align(
                                            alignment: isRTL ? Alignment.topLeft : Alignment.topRight,
                                            child: MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await MagasinNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),

                                  if (filtresActifs)
                                    Align(
                                      alignment: isRTL ? Alignment.topRight : Alignment.topLeft,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV / 4),
                                        child: Column(
                                          children: [
                                            filtreMagasin(setState, adjustedWidth / 3, l10n, translator, isRTL),
                                          ],
                                        ),
                                      ),
                                    ),

                                  SizedBox(height: paddingV / 2),

                                  SizedBox(
                                    height: adjustedHeight * 0.85,
                                    child: TableauMagasinAdvanced(
                                      key: ValueKey(magasinFiltres),
                                      magasins: magasinFiltres,
                                      onSelectionChanged: (selection) {
                                        setState(() {
                                          magasinsSelectionnes = selection;
                                        });
                                      },
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
      ),
    );
  }

  Widget filtreMagasin(void Function(VoidCallback fn) setState, double w, AppLocalizations l10n, ListsConstTranslator translator, bool isRTL) {
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
                width: w * 0.9,
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
        ],
      ),
    );
  }
}