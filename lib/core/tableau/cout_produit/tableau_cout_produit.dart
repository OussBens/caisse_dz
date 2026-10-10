import 'package:caisse_dz/core/tableau/cout_produit/cout_produit_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauCoutProduit extends StatefulWidget {
  final List<LigneCoutProduit> lignes;
  // Lignes cochées (Extract filtre de l'onglet Situation).
  final void Function(List<LigneCoutProduit>)? onSelectionChanged;

  const TableauCoutProduit({super.key, required this.lignes, this.onSelectionChanged});

  @override
  State<TableauCoutProduit> createState() => _TableauCoutProduitState();
}

class _TableauCoutProduitState extends State<TableauCoutProduit> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  late Map<String, Map<String, dynamic>> columnVisibility;

  late CoutProduitDataSource dataSource;
  bool _dataSourceReady = false;

  final Map<String, double> columnWidths = {};
  bool selectAll = false;
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'codeProduit': {'visible': true, 'label': 'productCode', 'field': 'codeProduit'},
      'nomProduit': {'visible': true, 'label': 'productName', 'field': 'nomProduit'},
      'prixAchatMin': {'visible': true, 'label': 'minPurchasePrice', 'field': 'prixAchatMin'},
      'prixAchatMax': {'visible': true, 'label': 'maxPurchasePrice', 'field': 'prixAchatMax'},
      'prixAchatMoyen': {'visible': true, 'label': 'averagePurchasePrice', 'field': 'prixAchatMoyen'},
      'quantiteAchetee': {'visible': true, 'label': 'totalPurchasedQuantity', 'field': 'quantiteAchetee'},
      'prixVenteMin': {'visible': true, 'label': 'minSalePrice', 'field': 'prixVenteMin'},
      'prixVenteMax': {'visible': true, 'label': 'maxSalePrice', 'field': 'prixVenteMax'},
      'prixVenteMoyen': {'visible': true, 'label': 'averageSalePrice', 'field': 'prixVenteMoyen'},
      'quantiteVendue': {'visible': true, 'label': 'totalSoldQuantity', 'field': 'quantiteVendue'},
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

    dataSource = CoutProduitDataSource(
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
  void didUpdateWidget(covariant TableauCoutProduit oldWidget) {
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
            headerColor: Appstyle.blueF.withOpacity(0.7),
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
      case 'productCode': return l10n.productCode;
      case 'productName': return l10n.productName;
      case 'minPurchasePrice': return l10n.minPurchasePrice;
      case 'maxPurchasePrice': return l10n.maxPurchasePrice;
      case 'averagePurchasePrice': return l10n.averagePurchasePrice;
      case 'totalPurchasedQuantity': return l10n.totalPurchasedQuantity;
      case 'minSalePrice': return l10n.minSalePrice;
      case 'maxSalePrice': return l10n.maxSalePrice;
      case 'averageSalePrice': return l10n.averageSalePrice;
      case 'totalSoldQuantity': return l10n.totalSoldQuantity;
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
                                if (key != 'nomProduit') value['visible'] = false;
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
                            final isLocked = entry.key == 'nomProduit';
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
