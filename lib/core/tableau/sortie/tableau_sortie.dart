import 'package:caisse_dz/core/dialog/sortie/sortie_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';
import 'sortie_source.dart';

class TableauSortieAdvanced extends StatefulWidget {
  final List<Sortie> sorties;
  final List<Produit> produits;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final List<Utilisateur> utilisateurs;
  final void Function(List<Sortie>)? onSelectionChanged;

  const TableauSortieAdvanced({
    super.key,
    required this.sorties,
    required this.produits,
    required this.categories,
    required this.sousCategories,
    this.utilisateurs = const [],
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
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
  bool selectAll = false;

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
      'nombre': {'visible': false, 'label': 'number', 'field': 'nombre'},
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
      sorties: widget.sorties,
      columnConfig: columnVisibility,
      l10n: l10n,
      produits: widget.produits,
      categories: widget.categories,
      sousCategories: widget.sousCategories,
      utilisateurs: widget.utilisateurs,
    );
    dataSource.onRowDoubleTap = (sortie) => SortieDetail(
      context,
      sortie,
      produits: widget.produits,
      categories: widget.categories,
      sousCategories: widget.sousCategories,
    );

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauSortieAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.sorties != widget.sorties) {
      dataSource.update(widget.sorties);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            boxShadow: const [BoxShadow(color: Appstyle.shadowSoft, blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SfDataPager(
                delegate: dataSource,
                pageCount: pageCount,
                direction: Axis.horizontal,
                itemWidth: 36,
                itemHeight: 36,
              ),
              const SizedBox(width: 20),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: _rowsPerPageOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _rowsPerPage = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TABLE =================
  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
        boxShadow: const [BoxShadow(color: Appstyle.shadowSoft, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.indigo.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIcon: Builder(builder: (context) => buildFilterIcon(context, dataSource)),
            gridLineColor: Appstyle.neutral200,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            rowsPerPage: _rowsPerPage,
            headerRowHeight: 36,
            rowHeight: 38,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            // Sélection au clic + double-clic pour le détail gérés dans
            // BaseTableDataSource.buildRow.
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
      case 'number': return l10n.numberField;
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
  void _showColumnSettingsPopup(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
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