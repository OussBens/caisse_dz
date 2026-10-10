import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'data_source_pannier_insertion.dart';

/// Tableau de sélection d'un panier (dialog [InsertionPannierDialog]).
/// Repris à l'identique de [TableauClientInsertion] (pagination, resize
/// colonnes, double-clic = sélection immédiate).
class TableauPannierInsertion extends StatefulWidget {
  final List<Pannier> panniers;
  final void Function(Pannier)? onSelectionChanged;
  final void Function(Pannier)? onDoubleTapPannier;
  final Pannier? selectedPannier;

  const TableauPannierInsertion({
    super.key,
    required this.panniers,
    this.onSelectionChanged,
    this.onDoubleTapPannier,
    this.selectedPannier,
  });

  @override
  State<TableauPannierInsertion> createState() =>
      _TableauPannierInsertionState();
}

class _TableauPannierInsertionState extends State<TableauPannierInsertion> {
  late PannierInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();

  int rowsPerPage = 15;
  int currentPage = 1;

  final Map<String, double> columnWidths = {};

  List<Pannier> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.panniers.length);
    if (start >= widget.panniers.length) return [];
    return widget.panniers.sublist(start, end);
  }

  int get totalPages =>
      (widget.panniers.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = PannierInsertionDataSource(
      panniers: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
    );
  }

  @override
  void didUpdateWidget(covariant TableauPannierInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.panniers != widget.panniers ||
        oldWidget.selectedPannier != widget.selectedPannier) {
      dataSource.updatePanniers(
        paginatedData,
        selectedPannier: widget.selectedPannier,
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
              borderRadius: BorderRadius.circular(Appstyle.radiusCard),
              boxShadow: const [
                BoxShadow(color: Appstyle.shadowSoft, blurRadius: 12)
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Appstyle.radiusLG),
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
                  onCellDoubleTap: (details) {
                    if (details.rowColumnIndex.rowIndex <= 0) return;
                    final index = details.rowColumnIndex.rowIndex - 1;
                    widget.onDoubleTapPannier?.call(paginatedData[index]);
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
                    GridColumn(
                      columnName: 'select',
                      width: 60,
                      allowSorting: false,
                      allowFiltering: false,
                      label: const SizedBox(),
                    ),
                    _col('code', l10n.code),
                    _col('date', l10n.date),
                    _col('montant', l10n.amount),
                    _col('articles', l10n.productCount),
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
        borderRadius: BorderRadius.circular(Appstyle.radiusButton),
        boxShadow: const [BoxShadow(color: Appstyle.shadowSoft, blurRadius: 10)],
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
                .map((e) => DropdownMenuItem(
                    value: e, child: Text("$e ${l10n.rowsPerPage}")))
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
