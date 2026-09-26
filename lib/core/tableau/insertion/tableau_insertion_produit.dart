
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'data_source_produit_insertion.dart';

class TableauProduitInsertion extends StatefulWidget {
  final List<Produit> produits;
  final bool multiple;
  final Produit? selectedProduit;
  final List<Produit>? selectedProduits;
  final void Function(List<Produit>)? onSelectionMultipleChanged;
  final void Function(Produit)? onSelectionChanged;
  final void Function(Produit)? onDoubleTapProduit;

  /// Quantité par produit calculée depuis le journal des mouvements — voir
  /// ProduitDataSource.quantites pour le même mécanisme.
  final Map<String, double> quantites;

  const TableauProduitInsertion({
    Key? key,
    required this.produits,
    this.multiple = false,
    this.onSelectionChanged,
    this.onDoubleTapProduit,
    this.selectedProduit,
    this.onSelectionMultipleChanged,
    this.selectedProduits,
    this.quantites = const {},
  }) : super(key: key);

  @override
  State<TableauProduitInsertion> createState() =>
      _TableauProduitInsertion();
}

class _TableauProduitInsertion extends State<TableauProduitInsertion> {
  late ProduitInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();

  int rowsPerPage = 15;
  int currentPage = 1;

  final Map<String, double> columnWidths = {};

  List<Produit> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.produits.length);
    if (start >= widget.produits.length) return [];
    return widget.produits.sublist(start, end);
  }

  int get totalPages =>
      (widget.produits.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = ProduitInsertionDataSource(
      produits: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
      quantites: widget.quantites,
    );
  }

  @override
  void didUpdateWidget(covariant TableauProduitInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.produits != widget.produits) {
      dataSource.updateProduits(
        paginatedData,
        selectedProduits: widget.multiple
            ? widget.selectedProduits
            : (widget.selectedProduit != null ? [widget.selectedProduit!] : null),
      );
    }
    if (oldWidget.quantites != widget.quantites) {
      dataSource.updateQuantites(widget.quantites);
    }
  }

  void _selectRow(int index) {
    if (index < 0 || index >= paginatedData.length) return;

    setState(() {
      dataSource.selectRow(index, widget.multiple);
      if (!widget.multiple) _controller.selectedIndex = index;
    });

    if (widget.multiple) {
      final selectedProduits = dataSource.selectedIndexes
          .map((i) => paginatedData[i])
          .toList();
      widget.onSelectionMultipleChanged?.call(selectedProduits);
    } else {
      widget.onSelectionChanged?.call(paginatedData[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SfDataGridTheme(
                data: SfDataGridThemeData(
                  headerColor: Appstyle.violet.withOpacity(0.7),
                  selectionColor: Appstyle.violet.withOpacity(0.2),
                ),
                child: SfDataGrid(
                  controller: _controller,
                  source: dataSource,
                  headerRowHeight: 36,
                  rowHeight: 38,
                  selectionMode: SelectionMode.single,
                  allowSorting: true,
                  allowFiltering: true,
                  columnWidthMode: ColumnWidthMode.none,
                  allowColumnsResizing: true,
                  columnResizeMode: ColumnResizeMode.onResize,
                  onColumnResizeUpdate: (details) {
                    double width = details.width;
                    if (width < 120) width = 120;
                    if (width > 400) width = 400;
                    setState(() {
                      columnWidths[details.column.columnName] = width;
                    });
                    return true;
                  },
                  columns: [
                    GridColumn(
                      columnName: 'select',
                      width: 60,
                      allowSorting: false,
                      allowFiltering: false,
                      label: const SizedBox(),
                    ),
                    _col('code', l10n.code),
                    _col('nom', l10n.name),
                    _col('marque', l10n.brand),
                    _col('description', l10n.description),
                    _col('prixVente', l10n.salePrice),
                    _col('quantite', l10n.quantity),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildPagination(l10n),
      ],
    );
  }

  GridColumn _col(String name, String label) {
    return GridColumn(
      columnName: name,
      width: columnWidths[name] ?? 180,
      label: Center(
        child: Text(
          label,
          style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
        ),
      ),
    );
  }

  Widget _buildPagination(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: currentPage > 1
                ? () {
              setState(() {
                currentPage--;
                dataSource.update(paginatedData);
              });
            }
                : null,
          ),
          Text("${l10n.page} $currentPage / $totalPages"),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: currentPage < totalPages
                ? () {
              setState(() {
                currentPage++;
                dataSource.update(paginatedData);
              });
            }
                : null,
          ),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: rowsPerPage,
            items: [10, 15, 20, 30]
                .map((e) =>
                DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
                .toList(),
            onChanged: (v) {
              setState(() {
                rowsPerPage = v!;
                currentPage = 1;
                dataSource.update(paginatedData);
              });
            },
          ),
        ],
      ),
    );
  }
}