import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/besoinList.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialog/besionlist/besoinlist_detail.dart';
import '../../widget/button/main_button.dart';
import '../../widget/tableau/paginated.dart';
import 'besoinlist_source.dart';

class TableauBesoinListAdvanced extends StatefulWidget {
  final List<BesoinList> besoins;
  final void Function(List<BesoinList>)? onSelectionChanged;

  const TableauBesoinListAdvanced({
    super.key,
    required this.besoins,
    this.onSelectionChanged,
  });

  @override
  State<TableauBesoinListAdvanced> createState() =>
      _TableauBesoinListAdvancedState();
}

class _TableauBesoinListAdvancedState extends State<TableauBesoinListAdvanced> {
  late BesoinListDataSource dataSource;
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;

  // ================= PAGINATION =================
  List<BesoinList> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.besoins.length);
    if (start >= widget.besoins.length) return [];
    return widget.besoins.sublist(start, end);
  }

  int get totalPages =>
      widget.besoins.isEmpty
          ? 1
          : (widget.besoins.length / rowsPerPage).ceil();

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    // ================= COLONNES BESOIN =================
    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'date': {'visible': true, 'label': 'date', 'field': 'date'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'numero': {'visible': true, 'label': 'number', 'field': 'numero'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'nombreArticle': {'visible': true, 'label': 'items', 'field': 'nombreArticle'},
      'quantite': {'visible': true, 'label': 'quantity', 'field': 'quantite'},
      'fournisseur': {'visible': true, 'label': 'supplier', 'field': 'fournisseur'},

      // Audit
      'dateCree': {'visible': true, 'label': 'createdAt', 'field': 'dateCree'},
      'creeParCode': {'visible': true, 'label': 'createdBy', 'field': 'creeParCode'},
      'dateModif': {'visible': false, 'label': 'modifiedAt', 'field': 'dateModif'},
      'modifParCode': {'visible': false, 'label': 'modifiedBy', 'field': 'modifParCode'},
      'dateAnnul': {'visible': false, 'label': 'cancelledAt', 'field': 'dateAnnul'},
      'annulParCode': {'visible': false, 'label': 'cancelledBy', 'field': 'annulParCode'},
      'motifAnnul': {'visible': false, 'label': 'cancellationReason', 'field': 'motifAnnul'},
    };
    colonnesParDefaut = {
      for (var e in columnVisibility.entries)
        e.key: e.value['visible'] as bool,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    dataSource = BesoinListDataSource(
      besoins: paginatedData,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      widget.onSelectionChanged?.call(dataSource.getSelectedRows());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 12),
        PaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          rowsPerPage: rowsPerPage,
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
              dataSource.updateBesoinsList(paginatedData);
            });
          },
          onRowsPerPageChanged: (v) {
            setState(() {
              rowsPerPage = v;
              currentPage = 1;
              dataSource.updateBesoinsList(paginatedData);
            });
          },
        ),
      ],
    );
  }

  // ================= TABLE =================
  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor:  Appstyle.blueC.withOpacity(0.8),
            sortIconColor: Appstyle.Tblanc,
            filterIconColor: Appstyle.Tblanc,
            gridLineColor: Colors.grey.shade300,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 36,
            rowHeight: 38,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,

            onCellDoubleTap: (details) {
              if (details.rowColumnIndex.rowIndex <= 0) return;
              final rowIndex = details.rowColumnIndex.rowIndex - 1;
              final besoin = paginatedData[rowIndex];
              BesoinListDetailDialog(context, besoin);
            },

            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 140) w = 140;
              if (w > 1000) w = 1000;
              setState(() => columnWidths[details.column.columnName] = w);
              return true;
            },

            columns: [
              GridColumn(
                columnName: 'settings',
                width: 60,
                allowSorting: false,
                allowFiltering: false,
                label: Center(
                  child: IconButton(
                    icon: const Icon(Icons.view_column, color: Colors.white),
                    tooltip: l10n.showHideColumns,
                    onPressed: () => _showColumnSettingsPopup(context, l10n),
                  ),
                ),
              ),
              GridColumn(
                columnName: 'select',
                width: 55,
                allowSorting: false,
                allowFiltering: false,
                label: Center(
                  child: Checkbox(
                    value: selectAll,
                    onChanged: (v) {
                      setState(() {
                        selectAll = v ?? false;
                        dataSource.selectAll(selectAll);
                      });
                    },
                  ),
                ),
              ),
              ...columnVisibility.entries
                  .where((e) => e.value['visible'])
                  .map(
                    (e) => GridColumn(
                  columnName: e.key,
                  width: columnWidths[e.key] ?? 180,
                  label: _header(_getTranslatedLabel(e.value['label'], l10n)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status': return l10n.status;
      case 'date': return l10n.date;
      case 'code': return l10n.code;
      case 'number': return l10n.number;
      case 'amount': return l10n.amount;
      case 'items': return l10n.items;
      case 'quantity': return l10n.quantity;
      case 'supplier': return l10n.supplier;
      case 'createdAt': return l10n.createdAt;
      case 'createdBy': return l10n.createdBy;
      case 'modifiedAt': return l10n.modifiedAt;
      case 'modifiedBy': return l10n.modifiedBy;
      case 'cancelledAt': return l10n.cancelledAt;
      case 'cancelledBy': return l10n.cancelledBy;
      case 'cancellationReason': return l10n.cancellationReason;
      default: return key;
    }
  }

  Widget _header(String title) => Center(
    child: Text(
      title,
      style: Appstyle.textSB.copyWith(
        fontWeight: FontWeight.w600,
        color: Appstyle.Tblanc,
      ),
    ),
  );

  // ================= COLONNES =================
  Widget _buildActiveColumnsBar(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        MainButton(
          text: "",
          color: Appstyle.violet,
          onPressed: () => _showColumnSettingsPopup(context, l10n),
          icon: Icons.view_column,
        )
      ],
    );
  }

  void _showColumnSettingsPopup(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(l10n.showHideColumns),

              content: SizedBox(
                width: 350,
                height: 450,
                child: Column(
                  children: [

                    /// 🔘 Boutons Tout / Aucun
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: const Icon(Icons.check_box),
                          label: Text(l10n.all),
                          onPressed: () {
                            setDialog(() {
                              columnVisibility.forEach((key, value) {
                                if (key != 'code' && key != 'nom') {
                                  value['visible'] = true;
                                }
                              });
                            });

                            setState(() {
                              dataSource.updateVisibleColumns(
                                columnVisibility.map(
                                      (k, v) => MapEntry(k, {
                                    'visible': v['visible'],
                                    'label': v['label'],
                                    'field': v['field'],
                                  }),
                                ),
                              );
                            });
                          },
                        ),

                        TextButton.icon(
                          icon: const Icon(Icons.check_box_outline_blank),
                          label: Text(l10n.none),
                          onPressed: () {
                            setDialog(() {
                              columnVisibility.forEach((key, value) {
                                if (key != 'code' && key != 'nom') {
                                  value['visible'] = false;
                                }
                              });
                            });

                            setState(() {
                              dataSource.updateVisibleColumns(
                                columnVisibility.map(
                                      (k, v) => MapEntry(k, {
                                    'visible': v['visible'],
                                    'label': v['label'],
                                    'field': v['field'],
                                  }),
                                ),
                              );
                            });
                          },
                        ),
                      ],
                    ),

                    const Divider(),

                    /// ☑️ Garder la sélection
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.keepSelection),
                      subtitle: Text(
                        l10n.otherwiseDefaultColumns,
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: garderSelectionColonnes,
                      onChanged: (value) {
                        setDialog(() {
                          garderSelectionColonnes = value ?? true;
                        });

                        // ❌ Si décoché → retour aux colonnes par défaut
                        if (value == false) {
                          setDialog(() {
                            columnVisibility.forEach((key, v) {
                              v['visible'] =
                                  colonnesParDefaut[key] ?? true;
                            });
                          });

                          setState(() {
                            dataSource.updateVisibleColumns(
                              columnVisibility.map(
                                    (k, v) => MapEntry(k, {
                                  'visible': v['visible'],
                                  'label': v['label'],
                                  'field': v['field'],
                                }),
                              ),
                            );
                          });
                        }
                      },
                    ),

                    const Divider(),

                    /// ☑️ Liste des colonnes
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: columnVisibility.entries.map((entry) {
                            final isLocked =
                                entry.key == 'code' || entry.key == 'nom';

                            return CheckboxListTile(
                              title: Text(_getTranslatedLabel(entry.value['label'], l10n)),
                              value: entry.value['visible'],
                              onChanged: isLocked
                                  ? null
                                  : (value) {
                                setDialog(() {
                                  entry.value['visible'] =
                                      value ?? false;
                                });

                                setState(() {
                                  dataSource.updateVisibleColumns(
                                    columnVisibility.map(
                                          (k, v) => MapEntry(k, {
                                        'visible': v['visible'],
                                        'label': v['label'],
                                        'field': v['field'],
                                      }),
                                    ),
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              actions: [
                TextButton(
                  child: Text(l10n.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }
}