import 'package:caisse_dz/core/dialog/zakat/zakat_detail.dart';
import 'package:caisse_dz/core/tableau/zakat/zakat_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauZakatAdvanced extends StatefulWidget {
  final List<Zakat> zakats;
  final List<Utilisateur> utilisateurs;
  final void Function(List<Zakat>)? onSelectionChanged;

  const TableauZakatAdvanced({
    super.key,
    required this.zakats,
    this.utilisateurs = const [],
    this.onSelectionChanged,
  });

  @override
  State<TableauZakatAdvanced> createState() => _TableauZakatAdvancedState();
}

class _TableauZakatAdvancedState extends State<TableauZakatAdvanced> {
  late ZakatDataSource dataSource;
  late Map<String, Map<String, dynamic>> columnVisibility;
  late final Map<String, bool> colonnesParDefaut;
  bool garderSelectionColonnes = true;
  final Map<String, double> columnWidths = {};
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
  bool selectAll = false;

  @override
  void initState() {
    super.initState();

    // Colonnes visibles par défaut
    columnVisibility = {
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'annee': {'visible': true, 'label': 'year', 'field': 'annee'},
      'capitalTotal': {'visible': true, 'label': 'totalCapital', 'field': 'capitalTotal'},
      'montantZakat': {'visible': true, 'label': 'zakatAmount', 'field': 'montantZakat'},
      'stock': {'visible': true, 'label': 'stock', 'field': 'stock'},
      'liquidites': {'visible': true, 'label': 'cash', 'field': 'liquidites'},
      'creances': {'visible': true, 'label': 'receivables', 'field': 'creances'},
      'dettes': {'visible': true, 'label': 'debts', 'field': 'dettes'},
      'nissab': {'visible': true, 'label': 'nissab', 'field': 'nissab'},
      'taux': {'visible': true, 'label': 'rate', 'field': 'taux'},
      'obligatoire': {'visible': true, 'label': 'mandatory', 'field': 'obligatoire'},
      'statut': {'visible': true, 'label': 'statusField', 'field': 'statut'},
      'dateDebutHawl': {'visible': true, 'label': 'hawlStart', 'field': 'dateDebutHawl'},
      'dateZakatDue': {'visible': true, 'label': 'dueDate', 'field': 'dateZakatDue'},
      'datePaiement': {'visible': true, 'label': 'paymentDate', 'field': 'datePaiement'},
      'observation': {'visible': true, 'label': 'observation', 'field': 'observation'},

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

    dataSource = ZakatDataSource(
      zakats: widget.zakats,
      columnConfig: columnVisibility.map((k, v) => MapEntry(k, {
        'visible': v['visible'],
        'label': v['label'],
        'field': v['field'],
      })),
      l10n: l10n,
      utilisateurs: widget.utilisateurs,
    );
    dataSource.onRowDoubleTap = (zakat) => ZakatDetail(context, zakat);

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauZakatAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.zakats != widget.zakats) {
      dataSource.updateZakats(widget.zakats);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

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
                  spreadRadius: 1,
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
                          filterIcon: Builder(builder: (context) => buildFilterIcon(context, dataSource)),
                        ),
                        child: SfDataGrid(
                          headerRowHeight: 36,
                          rowHeight: 38,
                          source: dataSource,
                          rowsPerPage: _rowsPerPage,
                          selectionMode: SelectionMode.multiple,
                          allowSorting: true,
                          allowFiltering: true,
                          columnWidthMode: ColumnWidthMode.none,
                          allowColumnsResizing: true,
                          columnResizeMode: ColumnResizeMode.onResize,
                          // Sélection au clic + double-clic pour le détail gérés
                          // dans BaseTableDataSource.buildRow.

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
                                  onChanged: (value) {
                                    setState(() {
                                      selectAll = value ?? false;
                                      dataSource.selectAll(selectAll);
                                    });
                                    widget.onSelectionChanged
                                        ?.call(dataSource.getSelectedRows());
                                  },
                                ),
                              ),
                            ),
                            ...columnVisibility.entries
                                .where((e) => e.value['visible'])
                                .map((entry) => GridColumn(
                              columnName: entry.key,
                              width: columnWidths[entry.key] ?? 180,
                              label: _header(_getTranslatedLabel(entry.value['label'], l10n)),
                            ))
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

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status': return l10n.status;
      case 'code': return l10n.code;
      case 'year': return l10n.year;
      case 'totalCapital': return l10n.totalCapital;
      case 'zakatAmount': return l10n.zakatAmount;
      case 'stock': return l10n.stock;
      case 'cash': return l10n.cash;
      case 'receivables': return l10n.receivables;
      case 'debts': return l10n.debts;
      case 'nissab': return l10n.nissab;
      case 'rate': return l10n.rate;
      case 'mandatory': return l10n.mandatory;
      case 'statusField': return l10n.statusField;
      case 'hawlStart': return l10n.hawlStart;
      case 'dueDate': return l10n.dueDate;
      case 'paymentDate': return l10n.paymentDate;
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
          fontWeight: FontWeight.w600,
          color: Appstyle.Tblanc,
        ),
      ),
    );
  }

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