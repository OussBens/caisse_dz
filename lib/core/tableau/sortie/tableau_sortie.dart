import 'package:caisse_dz/core/dialog/sortie/sortie_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../widget/tableau/paginated.dart';
import 'sortie_source.dart';

class TableauSortieAdvanced extends StatefulWidget {
  final List<Sortie> sorties;
  final List<Produit> produits;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final void Function(List<Sortie>)? onSelectionChanged;

  const TableauSortieAdvanced({
    super.key,
    required this.sorties,
    required this.produits,
    required this.categories,
    required this.sousCategories,
    this.onSelectionChanged,
  });

  @override
  State<TableauSortieAdvanced> createState() => _TableauSortieAdvancedState();
}

class _TableauSortieAdvancedState extends State<TableauSortieAdvanced> {
  late SortieDataSource dataSource;
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;

  // ================= PAGINATION =================
  List<Sortie> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.sorties.length);
    if (start >= widget.sorties.length) return [];
    return widget.sorties.sublist(start, end);
  }

  int get totalPages =>
      widget.sorties.isEmpty
          ? 1
          : (widget.sorties.length / rowsPerPage).ceil();

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    // ================= COLONNES SORTIE =================
    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'produit': {'visible': true, 'label': 'product', 'field': 'produit'},
      'categorie': {'visible': true, 'label': 'category', 'field': 'categorie'},
      'souscategorie': {'visible': true, 'label': 'subcategory', 'field': 'souscategorie'},
      'quantite': {'visible': true, 'label': 'quantity', 'field': 'quantite'},
      'prix': {'visible': true, 'label': 'price', 'field': 'prix'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'type': {'visible': true, 'label': 'type', 'field': 'type'},
      'observation': {'visible': true, 'label': 'OBSERVATION', 'field': 'observation'},

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

    dataSource = SortieDataSource(
      sorties: paginatedData,
      columnConfig: columnVisibility,
      l10n: l10n,
      produits: widget.produits,
      categories: widget.categories,
      sousCategories: widget.sousCategories,
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
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.violet.withOpacity(0.7),
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
              final Sortie sortie = paginatedData[rowIndex];
              SortieDetail(
                context,
                sortie,
                produits: widget.produits,
                categories: widget.categories,
                sousCategories: widget.sousCategories,
              );
            },
            onColumnResizeUpdate: (details) {
              double w = details.width.clamp(120, 800);
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
                  width: columnWidths[e.key] ?? 170,
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
      case 'product': return l10n.product;
      case 'category': return l10n.category;
      case 'subcategory': return l10n.subcategory;
      case 'quantity': return l10n.quantity;
      case 'price': return l10n.price;
      case 'amount': return l10n.amount;
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
        color: Appstyle.Tblanc,
        fontWeight: FontWeight.w600,
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
                                if (key != 'code' && key != 'produit') {
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
                                if (key != 'code' && key != 'produit') {
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
                            final isLocked = entry.key == 'code' || entry.key == 'produit';

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