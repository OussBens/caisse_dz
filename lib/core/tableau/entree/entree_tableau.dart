import 'package:caisse_dz/core/dialog/entree/entree_detail.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/entree.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/tableau/paginated.dart';
import 'entree_source.dart';

class TableauEntreeAdvanced extends StatefulWidget {
  final List<Entree> entrees;
  final void Function(List<Entree>)? onSelectionChanged;

  const TableauEntreeAdvanced({
    super.key,
    required this.entrees,
    this.onSelectionChanged,
  });

  @override
  State<TableauEntreeAdvanced> createState() => _TableauEntreeAdvancedState();
}

class _TableauEntreeAdvancedState extends State<TableauEntreeAdvanced> {
  late EntreeDataSource dataSource;
  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;
  bool garderSelectionColonnes = true;
  late Map<String, Map<String, dynamic>> columnVisibility;
  late final Map<String, bool> colonnesParDefaut;

  List<Entree> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.entrees.length);
    if (start >= widget.entrees.length) return [];
    return widget.entrees.sublist(start, end);
  }

  int get totalPages =>
      widget.entrees.isEmpty
          ? 1
          : (widget.entrees.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();

    // Configuration des colonnes avec les clés de traduction
    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'date': {'visible': true, 'label': 'date', 'field': 'date'},
      'produit': {'visible': true, 'label': 'product', 'field': 'produit'},
      'produitcode': {'visible': false, 'label': 'productCode', 'field': 'produitcode'},
      'prix': {'visible': true, 'label': 'price', 'field': 'prix'},
      'quantite': {'visible': true, 'label': 'quantity', 'field': 'quantite'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'fournisseur': {'visible': true, 'label': 'supplier', 'field': 'fournisseur'},
      'fournisseurCode': {'visible': false, 'label': 'supplierCode', 'field': 'fournisseurCode'},
      'observation': {'visible': true, 'label': 'observation', 'field': 'observation'},
      'dateCree': {'visible': true, 'label': 'createdAt', 'field': 'dateCree'},
      'creePar': {'visible': true, 'label': 'createdBy', 'field': 'creePar'},
      'dateModif': {'visible': true, 'label': 'modifiedAt', 'field': 'dateModif'},
      'modifPar': {'visible': true, 'label': 'modifiedBy', 'field': 'modifPar'},
      'dateAnnul': {'visible': true, 'label': 'cancelledAt', 'field': 'dateAnnul'},
      'annulPar': {'visible': true, 'label': 'cancelledBy', 'field': 'annulPar'},
      'motifAnnul': {'visible': true, 'label': 'cancellationReason', 'field': 'motifAnnul'},
    };

    colonnesParDefaut = {
      for (var e in columnVisibility.entries) e.key: e.value['visible']
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initDataSource();
  }

  void _initDataSource() {
    final l10n = AppLocalizations.of(context)!;

    dataSource = EntreeDataSource(
      entrees: paginatedData,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      widget.onSelectionChanged?.call(dataSource.getSelectedRows());
    });
  }

  @override
  void didUpdateWidget(covariant TableauEntreeAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entrees != widget.entrees) {
      final newPaginatedData = paginatedData;
      dataSource.update(newPaginatedData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 650,
                        maxWidth: constraints.maxWidth,
                      ),
                      child: SfDataGridTheme(
                        data: SfDataGridThemeData(
                          headerColor: Appstyle.violet.withOpacity(0.7),
                          gridLineColor: Colors.grey.shade300,
                          gridLineStrokeWidth: 0.4,
                          sortIconColor: Appstyle.Tblanc,
                          filterIconColor: Appstyle.Tblanc,
                        ),
                        child: SfDataGrid(
                          source: dataSource,
                          headerRowHeight: 36,
                          rowHeight: 38,
                          selectionMode: SelectionMode.multiple,
                          allowSorting: true,
                          allowFiltering: true,
                          columnWidthMode: ColumnWidthMode.none,
                          allowColumnsResizing: true,
                          columnResizeMode: ColumnResizeMode.onResize,
                          onCellDoubleTap: (details) {
                            if (details.rowColumnIndex.rowIndex <= 0) return;
                            final rowIndex = details.rowColumnIndex.rowIndex - 1;
                            final Entree entree = paginatedData[rowIndex];
                            EntreeDetail(context, entree);
                          },
                          onColumnResizeUpdate: (details) {
                            double newWidth = details.width;
                            if (newWidth < 150) newWidth = 150;
                            if (newWidth > 1000) newWidth = 1000;
                            setState(() {
                              columnWidths[details.column.columnName] = newWidth;
                            });
                            return true;
                          },
                          columns: [
                            /// SETTINGS
                            GridColumn(
                              columnName: 'settings',
                              width: 60,
                              allowFiltering: false,
                              allowSorting: false,
                              label: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.view_column, color: Colors.white),
                                  tooltip: l10n.showHideColumns,
                                  onPressed: _showColumnSettingsPopup,
                                ),
                              ),
                            ),

                            /// SELECT
                            GridColumn(
                              columnName: 'select',
                              width: 55,
                              allowFiltering: false,
                              allowSorting: false,
                              label: Center(
                                child: Checkbox(
                                  value: selectAll,
                                  onChanged: (v) {
                                    setState(() {
                                      selectAll = v!;
                                      dataSource.selectAll(selectAll);
                                    });
                                    widget.onSelectionChanged?.call(dataSource.getSelectedRows());
                                  },
                                ),
                              ),
                            ),

                            /// DYNAMIC COLUMNS
                            ...columnVisibility.entries
                                .where((e) => e.value['visible'])
                                .map((entry) {
                              return GridColumn(
                                columnName: entry.key,
                                width: columnWidths[entry.key] ?? 180,
                                label: _header(_getTranslatedLabel(entry.value['label'], l10n)),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
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

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status': return l10n.status;
      case 'code': return l10n.code;
      case 'date': return l10n.date;
      case 'product': return l10n.product;
      case 'productCode': return l10n.productCode;
      case 'price': return l10n.price;
      case 'quantity': return l10n.quantity;
      case 'amount': return l10n.amount;
      case 'supplier': return l10n.supplier;
      case 'supplierCode': return l10n.supplierCode;
      case 'observation': return l10n.observation;
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

  Widget _header(String title) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        title,
        style: Appstyle.textSB.copyWith(
          color: Appstyle.Tblanc,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showColumnSettingsPopup() {
    final l10n = AppLocalizations.of(context)!;

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

                        if (value == false) {
                          setDialog(() {
                            columnVisibility.forEach((key, v) {
                              v['visible'] = colonnesParDefaut[key] ?? true;
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
                            final isLocked = entry.key == 'code' || entry.key == 'nom';

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