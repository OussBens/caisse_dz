import 'package:caisse_dz/core/tableau/marge_pannier/marge_pannier_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauMargePannier extends StatefulWidget {
  final List<LigneMargePannier> lignes;
  // Lignes cochées (Extract filtre de l'onglet Situation).
  final void Function(List<LigneMargePannier>)? onSelectionChanged;

  const TableauMargePannier({super.key, required this.lignes, this.onSelectionChanged});

  @override
  State<TableauMargePannier> createState() => _TableauMargePannierState();
}

class _TableauMargePannierState extends State<TableauMargePannier> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  late Map<String, Map<String, dynamic>> columnVisibility;

  late MargePannierDataSource dataSource;
  bool _dataSourceReady = false;

  final Map<String, double> columnWidths = {};
  bool selectAll = false;
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'codeCaisse': {'visible': true, 'label': 'cashRegisterCode', 'field': 'codeCaisse'},
      'codePannier': {'visible': true, 'label': 'panierCode', 'field': 'codePannier'},
      'nomClient': {'visible': true, 'label': 'client', 'field': 'nomClient'},
      'montant': {'visible': true, 'label': 'amount', 'field': 'montant'},
      'marge': {'visible': true, 'label': 'marge', 'field': 'marge'},
      'nomCaissier': {'visible': true, 'label': 'cashier', 'field': 'nomCaissier'},
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
    };

    colonnesParDefaut = {
      for (var e in columnVisibility.entries) e.key: e.value['visible'] as bool,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataSourceReady) return;
    _dataSourceReady = true;
    final l10n = AppLocalizations.of(context)!;

    dataSource = MargePannierDataSource(
      lignes: widget.lignes,
      columnConfig: columnVisibility,
      l10n: l10n,
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
  void didUpdateWidget(covariant TableauMargePannier oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.lignes != widget.lignes) {
      dataSource.updateLignes(widget.lignes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

    return Column(
      children: [
        _buildTable(l10n),
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

  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      height: 480,
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
            headerColor: Appstyle.violet.withOpacity(0.7),
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
            selectionMode: SelectionMode.single,
            allowSorting: true,
            allowFiltering: true,
            columnWidthMode: ColumnWidthMode.fill,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 90) w = 90;
              if (w > 600) w = 600;
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
                  .where((e) => e.value['visible'] == true)
                  .map(
                    (e) => GridColumn(
                      columnName: e.key,
                      width: columnWidths[e.key] ?? double.nan,
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
      case 'cashRegisterCode': return l10n.cashRegisterCode;
      case 'panierCode': return l10n.panierCode;
      case 'client': return l10n.client;
      case 'amount': return l10n.amount;
      case 'marge': return l10n.marge;
      case 'cashier': return l10n.cashier;
      case 'status': return l10n.status;
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

  void _syncVisibleColumns() {
    dataSource.updateVisibleColumns(
      columnVisibility.map(
        (k, v) => MapEntry(k, {
          'visible': v['visible'],
          'label': v['label'],
          'field': v['field'],
        }),
      ),
    );
  }

  void _showColumnSettingsPopup(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusLG)),
              title: Text(l10n.showHideColumns),
              content: SizedBox(
                width: 350,
                height: 420,
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
                              columnVisibility.forEach((key, value) => value['visible'] = true);
                            });
                            setState(_syncVisibleColumns);
                          },
                        ),
                        TextButton.icon(
                          icon: const Icon(Icons.check_box_outline_blank),
                          label: Text(l10n.none),
                          onPressed: () {
                            setDialog(() {
                              columnVisibility.forEach((key, value) {
                                if (key != 'codePannier') value['visible'] = false;
                              });
                            });
                            setState(_syncVisibleColumns);
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.keepSelection),
                      subtitle: Text(l10n.otherwiseDefaultColumns, style: const TextStyle(fontSize: 12)),
                      value: garderSelectionColonnes,
                      onChanged: (value) {
                        setDialog(() => garderSelectionColonnes = value ?? true);
                        if (value == false) {
                          setDialog(() {
                            columnVisibility.forEach((key, v) => v['visible'] = colonnesParDefaut[key] ?? true);
                          });
                          setState(_syncVisibleColumns);
                        }
                      },
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          children: columnVisibility.entries.map((entry) {
                            final isLocked = entry.key == 'codePannier';
                            return CheckboxListTile(
                              title: Text(_getTranslatedLabel(entry.value['label'], l10n)),
                              value: entry.value['visible'],
                              onChanged: isLocked
                                  ? null
                                  : (value) {
                                      setDialog(() => entry.value['visible'] = value ?? false);
                                      setState(_syncVisibleColumns);
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
