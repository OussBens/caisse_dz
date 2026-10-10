import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/catalog_product.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../widget/tableau/paginated.dart';
import 'catalog_source.dart';

/// DataGrid de l'écran d'administration du catalogue distant. Contrairement
/// aux autres tableaux `*Advanced` de l'app (qui paginent une liste locale
/// déjà entièrement chargée), la pagination ici est pilotée par l'appelant
/// (lib/screens/catalog_screen.dart) puisque les données viennent de l'API
/// distante page par page — le widget est donc "contrôlé" plutôt que
/// propriétaire de son état de pagination.
class TableauCatalogAdvanced extends StatefulWidget {
  final List<CatalogProduct> products;
  final int currentPage;
  final int totalPages;
  final int rowsPerPage;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onRowsPerPageChanged;
  final void Function(List<CatalogProduct>)? onSelectionChanged;
  final void Function(CatalogProduct)? onDetail;

  const TableauCatalogAdvanced({
    super.key,
    required this.products,
    required this.currentPage,
    required this.totalPages,
    required this.rowsPerPage,
    required this.onPageChanged,
    required this.onRowsPerPageChanged,
    this.onSelectionChanged,
    this.onDetail,
  });

  @override
  State<TableauCatalogAdvanced> createState() => _TableauCatalogAdvancedState();
}

class _TableauCatalogAdvancedState extends State<TableauCatalogAdvanced> {
  late CatalogDataSource dataSource;
  static const double _columnWidth = 170;

  final Map<String, Map<String, dynamic>> columnConfig = {
    'codeProduit': {'visible': true, 'field': 'codeProduit'},
    'nom': {'visible': true, 'field': 'nom'},
    'marque': {'visible': true, 'field': 'marque'},
    'categorie': {'visible': true, 'field': 'categorie'},
    'couleur': {'visible': true, 'field': 'couleur'},
    'taille': {'visible': true, 'field': 'taille'},
    'barcode': {'visible': true, 'field': 'barcode'},
  };

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dataSource = CatalogDataSource(products: widget.products, columnConfig: columnConfig);
    dataSource.addListener(() {
      // Resynchronise la barre de pagination (page/nb pages) quand
      // notifyListeners() vient d'une source interne (ex: tri par en-tête
      // de colonne, qui revient à la page 1) sans passer par un setState()
      // englobant — sinon elle reste figée sur l'ancienne page tant que
      // l'utilisateur ne clique pas dessus.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauCatalogAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.products != widget.products) {
      dataSource.update(widget.products);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 12),
        PaginationBar(
          currentPage: widget.currentPage,
          totalPages: widget.totalPages,
          rowsPerPage: widget.rowsPerPage,
          onPageChanged: widget.onPageChanged,
          onRowsPerPageChanged: widget.onRowsPerPageChanged,
        ),
      ],
    );
  }

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
            headerColor: Appstyle.successInk.withOpacity(0.7),
            gridLineColor: Appstyle.neutral200,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 36,
            rowHeight: 38,
            selectionMode: SelectionMode.single,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            onCellDoubleTap: (details) {
              if (details.rowColumnIndex.rowIndex <= 0) return;
              final rowIndex = details.rowColumnIndex.rowIndex - 1;
              if (rowIndex < widget.products.length) {
                widget.onDetail?.call(widget.products[rowIndex]);
              }
            },
            columns: [
              GridColumn(
                columnName: 'settings',
                width: 40,
                allowSorting: false,
                allowFiltering: false,
                label: const SizedBox.shrink(),
              ),
              GridColumn(
                columnName: 'select',
                width: 40,
                allowSorting: false,
                allowFiltering: false,
                label: const SizedBox.shrink(),
              ),
              GridColumn(columnName: 'codeProduit', width: _columnWidth, label: _header(l10n.reference)),
              GridColumn(columnName: 'nom', width: _columnWidth, label: _header(l10n.name)),
              GridColumn(columnName: 'marque', width: _columnWidth, label: _header(l10n.brand)),
              GridColumn(columnName: 'categorie', width: _columnWidth, label: _header(l10n.category)),
              GridColumn(columnName: 'couleur', width: _columnWidth, label: _header(l10n.color)),
              GridColumn(columnName: 'taille', width: _columnWidth, label: _header(l10n.size)),
              GridColumn(columnName: 'barcode', width: _columnWidth, label: _header(l10n.barcode)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String title) => Center(
        child: Text(
          title,
          style: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600, color: Appstyle.Tblanc),
          overflow: TextOverflow.ellipsis,
        ),
      );
}
