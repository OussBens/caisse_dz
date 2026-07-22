
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'data_source_categorie_insertion.dart';

class TableauCategorieInsertion extends StatefulWidget {
  final List<Categorie> categories;
  final void Function(Categorie)? onSelectionChanged;
  final void Function(Categorie)? onDoubleTapCategorie;
  final Categorie? selectedCategorie;

  const TableauCategorieInsertion({
    super.key,
    required this.categories,
    this.onSelectionChanged,
    this.onDoubleTapCategorie,
    this.selectedCategorie,
  });

  @override
  State<TableauCategorieInsertion> createState() =>
      _TableauCategorieInsertionState();
}

class _TableauCategorieInsertionState extends State<TableauCategorieInsertion> {
  late CategorieInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();

  int rowsPerPage = 15;
  int currentPage = 1;
  final Map<String, double> columnWidths = {};

  List<Categorie> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.categories.length);
    if (start >= widget.categories.length) return [];
    return widget.categories.sublist(start, end);
  }

  int get totalPages =>
      (widget.categories.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = CategorieInsertionDataSource(
      categories: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
    );
  }

  @override
  void didUpdateWidget(covariant TableauCategorieInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categories != widget.categories ||
        oldWidget.selectedCategorie != widget.selectedCategorie) {
      dataSource.updateCategories(
        paginatedData,
        selectedCategorie: widget.selectedCategorie,
      );
    }
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
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
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

                  // Double clic
                  onCellDoubleTap: (details) {
                    if (details.rowColumnIndex.rowIndex <= 0) return;
                    final index = details.rowColumnIndex.rowIndex - 1;
                    widget.onDoubleTapCategorie?.call(paginatedData[index]);
                  },

                  // Sélection simple
                  onSelectionChanged: (added, removed) {
                    if (added.isNotEmpty) {
                      final index = dataSource.rows.indexOf(added.first);
                      if (index >= 0 && index < paginatedData.length) {
                        _selectRow(index);
                      }
                    }
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
                    _col('observation', l10n.observation),
                    _col('etat', l10n.status),
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
      width: columnWidths[name] ?? 160,
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
                .map((e) => DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
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