import 'package:caisse_dz/core/tableau/marge_periode/marge_periode_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauMargePeriode extends StatefulWidget {
  final List<LigneMargePeriode> lignes;

  const TableauMargePeriode({super.key, required this.lignes});

  @override
  State<TableauMargePeriode> createState() => _TableauMargePeriodeState();
}

class _TableauMargePeriodeState extends State<TableauMargePeriode> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  late Map<String, Map<String, dynamic>> columnVisibility;

  late MargePeriodeDataSource dataSource;
  bool _dataSourceReady = false;

  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];

  final Map<String, double> columnWidths = {};
  bool selectAll = false;

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'codeCaisse': {'visible': true, 'label': 'cashRegisterCode', 'field': 'codeCaisse'},
      'date': {'visible': true, 'label': 'date', 'field': 'date'},
      'montantJour': {'visible': true, 'label': 'amount', 'field': 'montantJour'},
      'margeJour': {'visible': true, 'label': 'marge', 'field': 'margeJour'},
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

    dataSource = MargePeriodeDataSource(
      lignes: widget.lignes,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauMargePeriode oldWidget) {
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
      height: 480,
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
            headerColor: Appstyle.indigo.withOpacity(0.7),
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
      case 'date': return l10n.date;
      case 'amount': return l10n.amount;
      case 'marge': return l10n.marge;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(l10n.showHideColumns),
              content: SizedBox(
                width: 350,
                height: 320,
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
                                if (key != 'date') value['visible'] = false;
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
                            final isLocked = entry.key == 'date';
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
