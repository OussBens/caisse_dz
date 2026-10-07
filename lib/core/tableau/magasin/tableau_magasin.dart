import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';
import '../../dialog/magasin/magasin_detail.dart';
import 'magasin_source.dart';

class TableauMagasinAdvanced extends StatefulWidget {
  final List<Magasin> magasins;
  final List<Utilisateur> utilisateurs;
  final void Function(List<Magasin>)? onSelectionChanged;

  const TableauMagasinAdvanced({
    super.key,
    required this.magasins,
    this.utilisateurs = const [],
    this.onSelectionChanged,
  });

  @override
  State<TableauMagasinAdvanced> createState() => _TableauMagasinAdvancedState();
}

class _TableauMagasinAdvancedState extends State<TableauMagasinAdvanced> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;

  late MagasinDataSource dataSource;

  final Map<String, double> columnWidths = {};
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
  bool selectAll = false;

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'nom': {'visible': true, 'label': 'name', 'field': 'nom'},
      'adresse': {'visible': true, 'label': 'address', 'field': 'adresse'},
      'observation': {'visible': false, 'label': 'observation', 'field': 'observation'},

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
      for (var e in columnVisibility.entries) e.key: e.value['visible'] as bool,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = MagasinDataSource(
      magasins: widget.magasins,
      columnConfig: columnVisibility,
      l10n: l10n,
      utilisateurs: widget.utilisateurs,
    );
    dataSource.onRowDoubleTap = (magasin) => MagasinDetail(context, magasin);

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauMagasinAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magasins != widget.magasins) {
      dataSource.update(widget.magasins);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
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
            // Largeur de départ = largeur disponible / nombre de colonnes
            // visibles (au lieu de valeurs fixes) — remplie l'écran par
            // défaut, ajustable ensuite via allowColumnsResizing.
            final visibleCount = columnVisibility.values.where((v) => v['visible'] == true).length;
            const fixedColumnsWidth = 60 + 55; // 'settings' + 'select'
            final remaining = constraints.maxWidth - fixedColumnsWidth;
            final defaultColumnWidth = visibleCount > 0
                ? (remaining / visibleCount).clamp(120.0, 400.0)
                : 170.0;

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
                selectionMode: SelectionMode.single,
                allowSorting: true,
                allowFiltering: true,

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
                      width: columnWidths[e.key] ?? defaultColumnWidth,
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
      case 'code': return l10n.code;
      case 'name': return l10n.name;
      case 'address': return l10n.address;
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

  Widget _header(String title) => Center(
    child: Text(
      title,
      style: Appstyle.textSB.copyWith(
        fontWeight: FontWeight.w600,
        color: Appstyle.Tblanc,
      ),
    ),
  );

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
                height: 400,
                child: Column(
                  children: [
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
