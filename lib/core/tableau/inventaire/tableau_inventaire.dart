import 'package:caisse_dz/core/tableau/inventaire/inventaire_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauInventaire extends StatefulWidget {
  final List<LigneInventaire> lignes;
  // Lignes cochées (Extract filtre de l'onglet Situation).
  final void Function(List<LigneInventaire>)? onSelectionChanged;

  const TableauInventaire({super.key, required this.lignes, this.onSelectionChanged});

  @override
  State<TableauInventaire> createState() => _TableauInventaireState();
}

class _TableauInventaireState extends State<TableauInventaire> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;
  late Map<String, Map<String, dynamic>> columnVisibility;

  late InventaireDataSource dataSource;
  bool _dataSourceReady = false;

  final Map<String, double> columnWidths = {};
  bool selectAll = false;
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();

    columnVisibility = {
      'codeProduit': {'visible': true, 'label': 'code', 'field': 'codeProduit'},
      'nomProduit': {'visible': true, 'label': 'product', 'field': 'nomProduit'},
      'nomCategorie': {'visible': true, 'label': 'category', 'field': 'nomCategorie'},
      'quantite': {'visible': true, 'label': 'quantity', 'field': 'quantite'},
      'prixAchat': {'visible': true, 'label': 'purchasePrice', 'field': 'prixAchat'},
      'valeurAchat': {'visible': true, 'label': 'purchaseValue', 'field': 'valeurAchat'},
      'prixVente': {'visible': true, 'label': 'salePrice', 'field': 'prixVente'},
      'valeurVente': {'visible': true, 'label': 'saleValue', 'field': 'valeurVente'},
      'prixMoyenAchat': {'visible': true, 'label': 'averagePurchasePrice', 'field': 'prixMoyenAchat'},
      'prixMoyenVente': {'visible': true, 'label': 'averageSalePrice', 'field': 'prixMoyenVente'},
      'margePotentielle': {'visible': true, 'label': 'potentialMargin', 'field': 'margePotentielle'},
      'statut': {'visible': true, 'label': 'status', 'field': 'statut'},
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

    dataSource = InventaireDataSource(
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
  void didUpdateWidget(covariant TableauInventaire oldWidget) {
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
            headerColor: Appstyle.blueF.withOpacity(0.7),
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
      case 'code': return l10n.code;
      case 'product': return l10n.products;
      case 'category': return l10n.category;
      case 'quantity': return l10n.quantity;
      case 'purchasePrice': return l10n.purchasePrice;
      case 'purchaseValue': return l10n.purchaseValue;
      case 'salePrice': return l10n.salePrice;
      case 'saleValue': return l10n.saleValue;
      case 'averagePurchasePrice': return l10n.averagePurchasePrice;
      case 'averageSalePrice': return l10n.averageSalePrice;
      case 'potentialMargin': return l10n.potentialMargin;
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
