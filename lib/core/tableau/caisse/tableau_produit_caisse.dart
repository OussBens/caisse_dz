import 'package:caisse_dz/core/tableau/caisse/produit_caisse_data_source.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

class TableauProduitCaisseAdvanced extends StatefulWidget {
  final Key? key;
  final List<Produit> produits;
  final void Function(Produit)? onSelectionChanged;
  final void Function(Produit)? onDoubleTapProduit;
  final Produit? selectedProduit;
  final double Function(Produit)? getQuantiteVirtuelle; // ✅ Nouveau paramètre


  const TableauProduitCaisseAdvanced({
    this.key,
    required this.produits,
    this.onSelectionChanged,
    this.onDoubleTapProduit,
    this.selectedProduit,
    this.getQuantiteVirtuelle, // ✅ Ajouté
  });

  @override
  State<TableauProduitCaisseAdvanced> createState() =>
      _TableauProduitCaisseAdvancedState();
}

class _TableauProduitCaisseAdvancedState extends State<TableauProduitCaisseAdvanced> {
  late ProduitCaisseDataSource dataSource;
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

  int get totalPages => (widget.produits.length / rowsPerPage).ceil().clamp(1, 9999);
// ✅ Méthode pour rafraîchir les quantités
  void _refreshQuantities() {
    if (dataSource != null) {
      dataSource.refreshQuantites();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initDataSource();
  }

  @override
  void didUpdateWidget(covariant TableauProduitCaisseAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    // ✅ Si les produits changent ou si la fonction de quantité change
    if (oldWidget.produits != widget.produits ||
        oldWidget.getQuantiteVirtuelle != widget.getQuantiteVirtuelle) {
      _initDataSource();
    }
  }

  void _initDataSource() {
    final l10n = AppLocalizations.of(context)!;
    dataSource = ProduitCaisseDataSource(
      produits: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
      getQuantiteVirtuelle: widget.getQuantiteVirtuelle,
    );
  }



  void _selectRow(int index) {
    setState(() {
      dataSource.selectRow(index);
      _controller.selectedIndex = index;
    });
    widget.onSelectionChanged?.call(paginatedData[index]);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 6)),
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
                    if (width < 140) width = 140;
                    if (width > 400) width = 400;
                    setState(() {
                      columnWidths[details.column.columnName] = width;
                    });
                    return true;
                  },
                  onCellDoubleTap: (details) {
                    if (details.rowColumnIndex.rowIndex <= 0) return;
                    final index = details.rowColumnIndex.rowIndex - 1;
                    widget.onDoubleTapProduit?.call(paginatedData[index]);
                  },
                  onSelectionChanged: (added, removed) {
                    if (added.isNotEmpty) {
                      final index = dataSource.rows.indexOf(added.first);
                      if (index >= 0 && index < paginatedData.length) {
                        _selectRow(index);
                      }
                    }
                  },
                  columns: [
                    _col('code', l10n.code),
                    _col('nom', l10n.name),
                    _col('marque', l10n.brand),
                    _col('quantite', l10n.quantity),
                    _col('prixVente', l10n.salePrice),
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
      width: columnWidths[name] ?? 185,
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
                _initDataSource();
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
                _initDataSource();
              });
            }
                : null,
          ),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: rowsPerPage,
            items: [10, 15, 20, 30]
                .map((e) => DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
                .toList(),
            onChanged: (v) {
              setState(() {
                rowsPerPage = v!;
                currentPage = 1;
                _initDataSource();
              });
            },
          ),
        ],
      ),
    );
  }
}