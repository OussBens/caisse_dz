import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/tableau/pannier/pannier_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:caisse_dz/core/widget/tableau/paginated.dart';

class TableauPannierAdvanced extends StatefulWidget {
  final List<Pannier> panniers;
  final void Function(List<Pannier>)? onSelectionChanged;

  const TableauPannierAdvanced({
    super.key,
    required this.panniers,
    this.onSelectionChanged,
  });

  @override
  State<TableauPannierAdvanced> createState() =>
      _TableauPannierAdvancedState();
}

class _TableauPannierAdvancedState extends State<TableauPannierAdvanced> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;

  late PannierDataSource dataSource;

  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;

  List<Pannier> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.panniers.length);
    if (start >= widget.panniers.length) return [];
    return widget.panniers.sublist(start, end);
  }

  int get totalPages =>
      widget.panniers.isEmpty
          ? 1
          : (widget.panniers.length / rowsPerPage)
          .ceil()
          .clamp(1, 9999);

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    /// 🔹 Colonnes PANNIER
    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'date': {'visible': true, 'label': 'date', 'field': 'date'},
      'client': {'visible': true, 'label': 'client', 'field': 'client'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'nombreArticle': {'visible': true, 'label': 'articles', 'field': 'nombreArticle'},
      'quantiteProduit': {'visible': true, 'label': 'quantity', 'field': 'quantiteProduit'},
      'verse': {'visible': true, 'label': 'paid', 'field': 'verse'},
      'reste': {'visible': true, 'label': 'remaining', 'field': 'reste'},
      'modePaiement': {'visible': true, 'label': 'payment', 'field': 'modePaiement'},
      'montantAchat': {'visible': true, 'label': 'Montntant Achat', 'field': 'montantAchat'},
      'marge': {'visible': true, 'label': 'Marge', 'field': 'marge'},
      'caissier': {'visible': true, 'label': 'cashier', 'field': 'caissier'},
      'observation': {'visible': true, 'label': 'observation', 'field': 'observation'},
      'typepannier': {'visible': false, 'label': 'type', 'field': 'typepannier'},

      // Audit
      'dateCree': {'visible': false, 'label': 'createdAt', 'field': 'dateCree'},
      'creePar': {'visible': false, 'label': 'createdBy', 'field': 'creePar'},
      'dateModif': {'visible': false, 'label': 'modifiedAt', 'field': 'dateModif'},
      'modifPar': {'visible': false, 'label': 'modifiedBy', 'field': 'modifPar'},
      'dateAnnul': {'visible': false, 'label': 'cancelledAt', 'field': 'dateAnnul'},
      'annulPar': {'visible': false, 'label': 'cancelledBy', 'field': 'annulPar'},
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

    dataSource = PannierDataSource(
      panniers: paginatedData,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      widget.onSelectionChanged?.call(dataSource.getSelectedRows());
    });
  }

  @override
  void didUpdateWidget(covariant TableauPannierAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.panniers != widget.panniers) {
      final newPaginatedData = paginatedData;
      dataSource.updateProduits(newPaginatedData);
    }
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
              dataSource.updateProduits(paginatedData);
            });
          },
          onRowsPerPageChanged: (v) {
            setState(() {
              rowsPerPage = v;
              currentPage = 1;
              dataSource.updateProduits(paginatedData);
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
            headerColor: Appstyle.green2.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIconColor: Appstyle.Tblanc,
            gridLineColor: Colors.grey.shade300,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 36,
            rowHeight: 38,
            selectionMode: SelectionMode.single,
            allowSorting: true,
            allowFiltering: true,
            onCellDoubleTap: (details) {
              if (details.rowColumnIndex.rowIndex <= 0) return;
              final rowIndex = details.rowColumnIndex.rowIndex - 1;
              final Pannier pannier = paginatedData[rowIndex];
              PannierDetail(context, pannier);
            },
            columnWidthMode: ColumnWidthMode.none,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,

            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 150) w = 150;
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
      case 'code': return l10n.code;
      case 'date': return l10n.date;
      case 'client': return l10n.client;
      case 'amount': return l10n.amount;
      case 'articles': return l10n.articles;
      case 'quantity': return l10n.quantity;
      case 'paid': return l10n.paid;
      case 'remaining': return l10n.remaining;
      case 'payment': return l10n.payment;
      case 'cashier': return l10n.cashier;
      case 'observation': return l10n.observation;
      case 'type': return l10n.type;
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
                                if (key != 'code' && key != 'client') {
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
                                if (key != 'code' && key != 'client') {
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
                            final isLocked = entry.key == 'code' || entry.key == 'client';

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