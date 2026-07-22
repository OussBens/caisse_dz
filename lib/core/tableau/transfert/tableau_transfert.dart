import 'package:caisse_dz/core/dialog/transfert/transfert_detail.dart';
import 'package:caisse_dz/core/tableau/transfert/transfert_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/transfert.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:caisse_dz/core/widget/tableau/paginated.dart';

class TableauTransfertCaisseAdvanced extends StatefulWidget {
  final List<TransfertCaisse> transferts;
  final void Function(List<TransfertCaisse>)? onSelectionChanged;

  const TableauTransfertCaisseAdvanced({
    super.key,
    required this.transferts,
    this.onSelectionChanged,
  });

  @override
  State<TableauTransfertCaisseAdvanced> createState() =>
      _TableauTransfertCaisseAdvancedState();
}

class _TableauTransfertCaisseAdvancedState
    extends State<TableauTransfertCaisseAdvanced> {
  late TransfertCaisseDataSource dataSource;

  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;
  late final Map<String, bool> colonnesParDefaut;
  bool garderSelectionColonnes = true;

  late Map<String, Map<String, dynamic>> columnVisibility;

  // ================= PAGINATION =================
  List<TransfertCaisse> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.transferts.length);
    if (start >= widget.transferts.length) return [];
    return widget.transferts.sublist(start, end);
  }

  int get totalPages =>
      widget.transferts.isEmpty
          ? 1
          : (widget.transferts.length / rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'dateTransfert': {'visible': true, 'label': 'date', 'field': 'dateTransfert'},
      'caisseExp': {'visible': true, 'label': 'sourceCashRegister', 'field': 'caisseExp'},
      'caisseDest': {'visible': true, 'label': 'destinationCashRegister', 'field': 'caisseDest'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'observation': {'visible': true, 'label': 'observation', 'field': 'observation'},

      // Audit
      'dateCree': {'visible': false, 'label': 'createdAt', 'field': 'dateCree'},
      'creeParCode': {'visible': false, 'label': 'createdBy', 'field': 'creeParCode'},
      'dateAnnul': {'visible': false, 'label': 'cancelledAt', 'field': 'dateAnnul'},
      'annulParCode': {'visible': false, 'label': 'cancelledBy', 'field': 'annulParCode'},
      'motifAnnul': {'visible': false, 'label': 'cancellationReason', 'field': 'motifAnnul'},
    };

    colonnesParDefaut = {
      for (var e in columnVisibility.entries) e.key: e.value['visible'] as bool,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = TransfertCaisseDataSource(
      transferts: paginatedData,
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
              dataSource.update(paginatedData);
            });
          },
          onRowsPerPageChanged: (v) {
            setState(() {
              rowsPerPage = v;
              currentPage = 1;
              dataSource.update(paginatedData);
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
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12)
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.violet.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIconColor: Appstyle.Tblanc,
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 36,
            rowHeight: 38,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,
            columnWidthMode: ColumnWidthMode.none,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            onCellDoubleTap: (details) {
              if (details.rowColumnIndex.rowIndex <= 0) return;
              final rowIndex = details.rowColumnIndex.rowIndex - 1;
              final TransfertCaisse transfertCaisse = paginatedData[rowIndex];
              TransfertCaisseDetail(context, transfertCaisse);
            },
            onColumnResizeUpdate: (details) {
              double w = details.width.clamp(150, 1000);
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
      case 'code': return l10n.code;
      case 'date': return l10n.date;
      case 'sourceCashRegister': return l10n.sourceCashRegister;
      case 'destinationCashRegister': return l10n.destinationCashRegister;
      case 'amount': return l10n.amount;
      case 'observation': return l10n.observation;
      case 'createdAt': return l10n.createdAt;
      case 'createdBy': return l10n.createdBy;
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
        color: Appstyle.Tblanc,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  void _showColumnSettingsPopup(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialog) {
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
                  // Tout / Aucun
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.check_box),
                        label: Text(l10n.all),
                        onPressed: () {
                          setDialog(() {
                            columnVisibility.forEach((key, value) {
                              if (key != 'code') value['visible'] = true;
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
                              if (key != 'code') value['visible'] = false;
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
                  // Garder sélection
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
                      if (value == false) {
                        setDialog(() {
                          columnVisibility.forEach((k, v) {
                            v['visible'] = colonnesParDefaut[k] ?? true;
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: columnVisibility.entries.map((entry) {
                          final isLocked = entry.key == 'code';
                          return CheckboxListTile(
                            title: Text(_getTranslatedLabel(entry.value['label'], l10n)),
                            value: entry.value['visible'],
                            onChanged: isLocked
                                ? null
                                : (value) {
                              setDialog(() {
                                entry.value['visible'] = value ?? false;
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
                  onPressed: () => Navigator.pop(context),
                  child: Text(l10n.close))
            ],
          );
        });
      },
    );
  }
}