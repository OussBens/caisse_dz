import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/besoinList.dart';
import '../../../data/models/fournisseur.dart';
import '../../../data/models/utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import '../../dialog/besionlist/besoinlist_detail.dart';
import '../filter_icon_builder.dart';
import 'besoinlist_source.dart';

class TableauBesoinListAdvanced extends StatefulWidget {
  final List<BesoinList> besoins;
  final List<Fournisseur> fournisseurs;
  final List<Utilisateur> utilisateurs;
  final void Function(List<BesoinList>)? onSelectionChanged;

  const TableauBesoinListAdvanced({
    super.key,
    required this.besoins,
    this.fournisseurs = const [],
    this.utilisateurs = const [],
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
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
  bool selectAll = false;

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
      besoins: widget.besoins,
      columnConfig: columnVisibility,
      l10n: l10n,
      fournisseurs: widget.fournisseurs,
      utilisateurs: widget.utilisateurs,
    );
    dataSource.onRowDoubleTap = (besoin) => BesoinListDetailDialog(context, besoin);

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauBesoinListAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.besoins != widget.besoins) {
      dataSource.updateBesoinsList(widget.besoins);
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
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final visibleColumns = columnVisibility.entries
                .where((e) => e.value['visible'] as bool)
                .toList();
            // ✅ Largeur idéale = largeur du tableau / nombre de colonnes
            // affichées, pour que les colonnes remplissent toute la largeur
            // disponible au lieu de laisser un vide avec la largeur fixe
            // précédente.
            const reservedColumnsWidth = 60.0 /* settings */ + 55.0 /* select */;
            final idealColumnWidth = visibleColumns.isEmpty
                ? 180.0
                : ((constraints.maxWidth - reservedColumnsWidth) /
                        visibleColumns.length)
                    .clamp(120.0, 400.0);

            return SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.violet.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIcon: Builder(builder: (context) => buildFilterIcon(context, dataSource)),
            gridLineColor: Colors.grey.shade300,
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
            // BaseTableDataSource.buildRow (n'importe quelle colonne).

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
              ...visibleColumns.map(
                    (e) => GridColumn(
                  columnName: e.key,
                  width: columnWidths[e.key] ?? idealColumnWidth,
                  label: _header(_getTranslatedLabel(e.value['label'], l10n)),
                ),
              ),
            ],
          ),
        );
          },
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