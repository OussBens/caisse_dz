import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';
import 'package:caisse_dz/core/tableau/Produit/produit_date_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauProduitAdvanced extends StatefulWidget {
  final List<Produit> produits;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final List<Remise> remises;
  final List<Fournisseur> fournisseurs;
  final List<Utilisateur> utilisateurs;
  final double seuilMinimum;

  /// Quantité par produit calculée depuis le journal des mouvements (voir
  /// ProduitDataSource.quantites) — remplace Produit.quantite à l'affichage.
  final Map<String, double> quantites;

  /// Affiche le bouton de configuration des colonnes (masqué dans la vue
  /// "besoins", plus restreinte — voir besion_screen.dart).
  final bool col;
  final void Function(List<Produit>)? onSelectionChanged;

  const TableauProduitAdvanced({
    super.key,
    required this.produits,
    required this.categories,
    required this.sousCategories,
    required this.remises,
    required this.fournisseurs,
    this.utilisateurs = const [],
    this.seuilMinimum = 0,
    this.quantites = const {},
    this.col = true,
    this.onSelectionChanged,
  });

  @override
  State<TableauProduitAdvanced> createState() => _TableauProduitAdvancedState();
}

class _TableauProduitAdvancedState extends State<TableauProduitAdvanced> {
  late final Map<String, bool> colonnesParDefaut;
  bool garderSelectionColonnes = true;
  late ProduitDataSource dataSource;
  final Map<String, double> columnWidths = {};
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
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
      'service': {'visible': false, 'label': 'service', 'field': 'service'},
      'uniteMesure': {'visible': true, 'label': 'unit', 'field': 'uniteMesure'},
      'emballage1': {'visible': true, 'label': 'packaging1', 'field': 'emballage1'},
      'emballageP1': {'visible': true, 'label': 'Prix packaging1', 'field': 'emballageP1'},
      'emballage2': {'visible': true, 'label': 'packaging2', 'field': 'emballage2'},
      'emballageP2': {'visible': true, 'label': 'Prix packaging2', 'field': 'emballageP2'},

      'besion': {'visible': false, 'label': 'need', 'field': 'besion'},

      'codeBarre': {'visible': false, 'label': 'barcode', 'field': 'codeBarre'},
      'numeroSerie': {'visible': false, 'label': 'serialNumber', 'field': 'numeroSerie'},
      'multicodebar': {'visible': false, 'label': 'multicode', 'field': 'multicodebar'},
      'photos': {'visible': false, 'label': 'photos', 'field': 'photos'},
      'margeBool': {'visible': false, 'label': 'marginBool', 'field': 'margeBool'},
      'margeTaux': {'visible': false, 'label': 'marginRate', 'field': 'margeTaux'},
      'margeTauxPrct': {'visible': false, 'label': 'marginRatePercent', 'field': 'margeTauxPrct'},
      'tva': {'visible': false, 'label': 'vat', 'field': 'tva'},
      'dateEmpreint': {'visible': false, 'label': 'dateBorrowed', 'field': 'dateEmpreint'},

      'dateCree': {'visible': true, 'label': 'createdAt', 'field': 'dateCree'},
      'creeParCode': {'visible': true, 'label': 'createdBy', 'field': 'creeParCode'},
      'annulerParCode': {'visible': false, 'label': 'cancelledBy', 'field': 'annulerParCode'},
      'annulerLe': {'visible': false, 'label': 'cancelledAt', 'field': 'annulerLe'},
      'motifAnnul': {'visible': false, 'label': 'cancellationReason', 'field': 'motifAnnul'},
      'dateModif': {'visible': false, 'label': 'modifiedAt', 'field': 'dateModif'},
      'modifParCode': {'visible': false, 'label': 'modifiedBy', 'field': 'modifParCode'},
    };

    // ✅ Permissions spéciales (voir RoleDetail) : prix d'achat et marge
    // retirés entièrement (pas juste masqués) pour un rôle qui n'a pas la
    // permission — sinon le bouton "Tout" du sélecteur de colonnes les
    // réafficherait quand même.
    final auth = Provider.of<AuthState>(context, listen: false);
    if (!auth.canVoirPrixAchat) {
      columnVisibility.remove('prixAchat');
    }
    if (!auth.canVoirMarge) {
      columnVisibility.remove('margeTaux');
      columnVisibility.remove('margeTauxPrct');
    }

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
      produits: widget.produits,
      columnConfig: columnVisibility.map((k, v) => MapEntry(k, {
        'visible': v['visible'],
        'label': v['label'],
        'field': v['field'],
      })),
      l10n: l10n,
      categories: widget.categories,
      sousCategories: widget.sousCategories,
      remises: widget.remises,
      fournisseurs: widget.fournisseurs,
      seuilMinimum: widget.seuilMinimum,
      utilisateurs: widget.utilisateurs,
      quantites: widget.quantites,
    );
    dataSource.onRowDoubleTap = (produit) => ProduitDetail(context, produit);

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauProduitAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.produits != widget.produits) {
      dataSource.updateProduits(widget.produits);
    }
    if (oldWidget.quantites != widget.quantites) {
      dataSource.updateQuantites(widget.quantites);
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
                )
              ],
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
                  // affichées, pour que les colonnes remplissent toute la
                  // largeur disponible au lieu de laisser un vide (ou de
                  // scroller inutilement) avec la largeur fixe précédente.
                  const reservedColumnsWidth = 60.0 /* settings */ + 60.0 /* select */;
                  final idealColumnWidth = visibleColumns.isEmpty
                      ? 200.0
                      : ((constraints.maxWidth - reservedColumnsWidth) /
                              visibleColumns.length)
                          .clamp(150.0, 420.0);

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 900,
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
                          // Sélection au clic + double-clic pour le détail gérés
                          // dans BaseTableDataSource.buildRow (n'importe quelle colonne).

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
                              width: widget.col ? 60 : 0,
                              allowSorting: false,
                              allowFiltering: false,
                              label: widget.col
                                  ? Center(
                                      child: IconButton(
                                        icon: const Icon(Icons.view_column, color: Colors.white),
                                        tooltip: l10n.showHideColumns,
                                        onPressed: () => _showColumnSettingsPopup(context, l10n),
                                      ),
                                    )
                                  : const SizedBox.shrink(),
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
                            ...visibleColumns.map(
                                  (entry) => GridColumn(
                                columnName: entry.key,
                                width: columnWidths[entry.key] ?? idealColumnWidth,
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
      case 'need': return l10n.need;
      case 'barcode': return l10n.barcode;
      case 'serialNumber': return l10n.serialNumber;
      case 'multicode': return l10n.multicode;
      case 'photos': return l10n.photos;
      case 'marginBool': return l10n.marginBool;
      case 'marginRate': return l10n.marginRate;
      case 'marginRatePercent': return l10n.marginRatePercent;
      case 'vat': return l10n.vat;
      case 'dateBorrowed': return l10n.dateBorrowed;
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
