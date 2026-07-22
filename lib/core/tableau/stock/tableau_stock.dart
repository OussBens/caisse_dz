import 'package:caisse_dz/core/dialog/stock/stock_detail.dart';
import 'package:caisse_dz/core/tableau/Produit/produit_date_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:caisse_dz/core/widget/tableau/paginated.dart';

class TableauStockAdvanced extends StatefulWidget {
  final List<Produit> produits;
  final void Function(List<Produit>)? onSelectionChanged;

  const TableauStockAdvanced({
    super.key,
    required this.produits,
    this.onSelectionChanged,
  });

  @override
  State<TableauStockAdvanced> createState() => _TableauStockAdvancedState();
}

class _TableauStockAdvancedState extends State<TableauStockAdvanced> {
  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;

  late ProduitDataSource dataSource;
  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;

  List<Produit> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.produits.length);
    if (start >= widget.produits.length) return [];
    return widget.produits.sublist(start, end);
  }

  int get totalPages =>
      (widget.produits.isEmpty) ? 1 : (widget.produits.length / rowsPerPage).ceil().clamp(1, 9999);

  bool selectAll = false;

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    // Configuration des colonnes visibles
    columnVisibility = {
      // Champs principaux visibles par défaut
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
      'code': {'visible': true, 'label': 'code', 'field': 'code'},
      'nom': {'visible': true, 'label': 'name', 'field': 'nom'},
      'marque': {'visible': true, 'label': 'brand', 'field': 'marque'},
      'description': {'visible': true, 'label': 'description', 'field': 'description'},
      'quantite': {'visible': true, 'label': 'quantity', 'field': 'quantite'},

      'taille': {'visible': true, 'label': 'size', 'field': 'taille'},
      'couleur': {'visible': true, 'label': 'color', 'field': 'couleur'},
      'prixAchat': {'visible': true, 'label': 'purchasePrice', 'field': 'prixAchat'},
      'prixVente': {'visible': true, 'label': 'salePrice', 'field': 'prixVente'},

      'categorie': {'visible': true, 'label': 'category', 'field': 'categorie'},
      'sousCategorie': {'visible': true, 'label': 'subcategory', 'field': 'sousCategorie'},
      'remise': {'visible': true, 'label': 'discount', 'field': 'remise'},
      'service': {'visible': true, 'label': 'service', 'field': 'service'},
      'uniteMesure': {'visible': true, 'label': 'unit', 'field': 'uniteMesure'},
      'emballage1': {'visible': false, 'label': 'packaging1', 'field': 'emballage1'},
      'emballage2': {'visible': false, 'label': 'packaging2', 'field': 'emballage2'},
      'seuilMin': {'visible': false, 'label': 'minThreshold', 'field': 'seuilMin'},
      'seuilMax': {'visible': false, 'label': 'maxThreshold', 'field': 'seuilMax'},

      'codeBarre': {'visible': false, 'label': 'barcode', 'field': 'codeBarre'},
      'numeroSerie': {'visible': false, 'label': 'serialNumber', 'field': 'numeroSerie'},
      'multicodebar': {'visible': false, 'label': 'multicode', 'field': 'multicodebar'},
      'photos': {'visible': false, 'label': 'photos', 'field': 'photos'},
      'margeBool': {'visible': false, 'label': 'marginBool', 'field': 'margeBool'},
      'margeTaux': {'visible': false, 'label': 'marginRate', 'field': 'margeTaux'},
      'margeTauxPrct': {'visible': false, 'label': 'marginRatePercent', 'field': 'margeTauxPrct'},
      'tva': {'visible': false, 'label': 'vat', 'field': 'tva'},
      'dateEmpreint': {'visible': false, 'label': 'dateBorrowed', 'field': 'dateEmpreint'},
      'seuilBool': {'visible': false, 'label': 'thresholdBool', 'field': 'seuilBool'},

      'dateCree': {'visible': true, 'label': 'createdAt', 'field': 'dateCree'},
      'creeParCode': {'visible': true, 'label': 'createdBy', 'field': 'creeParCode'},
      'annulerPar': {'visible': false, 'label': 'cancelledBy', 'field': 'annulerPar'},
      'annulerLe': {'visible': false, 'label': 'cancelledAt', 'field': 'annulerLe'},
      'motifAnnul': {'visible': false, 'label': 'cancellationReason', 'field': 'motifAnnul'},
      'dateModif': {'visible': false, 'label': 'modifiedAt', 'field': 'dateModif'},
      'modifParCode': {'visible': false, 'label': 'modifiedBy', 'field': 'modifParCode'},
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

    dataSource = ProduitDataSource(
      produits: paginatedData,
      columnConfig: columnVisibility.map((k, v) => MapEntry(k, {
        'visible': v['visible'],
        'label': v['label'],
        'field': v['field'],
      })),
      l10n: l10n,
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
                )
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
                          headerColor: Appstyle.blueC.withOpacity(0.8),
                          gridLineColor: Colors.grey.shade300,
                          gridLineStrokeWidth: 0.4,
                          sortIconColor: Appstyle.Tblanc,
                          filterIconColor: Appstyle.Tblanc,
                        ),
                        child: SfDataGrid(
                          headerRowHeight: 36,
                          rowHeight: 38,
                          source: dataSource,
                          selectionMode: SelectionMode.multiple,
                          allowSorting: true,
                          allowFiltering: true,
                          onCellDoubleTap: (details) {
                            if (details.rowColumnIndex.rowIndex <= 0) return;
                            final rowIndex = details.rowColumnIndex.rowIndex - 1;
                            final Produit produit = paginatedData[rowIndex];
                            StockDetail(context, produit);
                          },

                          columnWidthMode: ColumnWidthMode.none,
                          allowColumnsResizing: true,
                          columnResizeMode: ColumnResizeMode.onResize,

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
                                .map(
                                  (entry) => GridColumn(
                                columnName: entry.key,
                                width: columnWidths[entry.key] ?? 180,
                                label: _header(_getTranslatedLabel(entry.value['label'], l10n)),
                              ),
                            ),
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

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'status': return l10n.status;
      case 'code': return l10n.code;
      case 'name': return l10n.name;
      case 'brand': return l10n.brand;
      case 'description': return l10n.description;
      case 'quantity': return l10n.quantity;
      case 'size': return l10n.size;
      case 'color': return l10n.color;
      case 'purchasePrice': return l10n.purchasePrice;
      case 'salePrice': return l10n.salePrice;
      case 'category': return l10n.category;
      case 'subcategory': return l10n.subcategory;
      case 'discount': return l10n.discount;
      case 'service': return l10n.service;
      case 'unit': return l10n.unit;
      case 'packaging1': return l10n.packaging1;
      case 'packaging2': return l10n.packaging2;
      case 'minThreshold': return l10n.minThreshold;
      case 'maxThreshold': return l10n.maxThreshold;
      case 'barcode': return l10n.barcode;
      case 'serialNumber': return l10n.serialNumber;
      case 'multicode': return l10n.multicode;
      case 'photos': return l10n.photos;
      case 'marginBool': return l10n.marginBool;
      case 'marginRate': return l10n.marginRate;
      case 'marginRatePercent': return l10n.marginRatePercent;
      case 'vat': return l10n.vat;
      case 'dateBorrowed': return l10n.dateBorrowed;
      case 'thresholdBool': return l10n.thresholdBool;
      case 'createdAt': return l10n.createdAt;
      case 'createdBy': return l10n.createdBy;
      case 'cancelledBy': return l10n.cancelledBy;
      case 'cancelledAt': return l10n.cancelledAt;
      case 'cancellationReason': return l10n.cancellationReason;
      case 'modifiedAt': return l10n.modifiedAt;
      case 'modifiedBy': return l10n.modifiedBy;
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