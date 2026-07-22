
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'data_source_magasin_insertion.dart';

class TableauMagasinInsertion extends StatefulWidget {
  final List<Magasin> magasins;
  final bool multiple;
  final Magasin? selectedMagasin;
  final List<Magasin>? selectedMagasins;
  final void Function(List<Magasin>)? onSelectionMultipleChanged;
  final void Function(Magasin)? onSelectionChanged;
  final void Function(Magasin)? onDoubleTapMagasin;

  const TableauMagasinInsertion({
    Key? key,
    required this.magasins,
    this.multiple = false,
    this.onSelectionChanged,
    this.onDoubleTapMagasin,
    this.selectedMagasin,
    this.onSelectionMultipleChanged,
    this.selectedMagasins,
  }): super(key: key);

  @override
  State<TableauMagasinInsertion> createState() =>
      _TableauMagasinInsertionState();
}

class _TableauMagasinInsertionState extends State<TableauMagasinInsertion> {
  late MagasinInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();

  int rowsPerPage = 15;
  int currentPage = 1;
  final Map<String, double> columnWidths = {};

  List<Magasin> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.magasins.length);
    if (start >= widget.magasins.length) return [];
    return widget.magasins.sublist(start, end);
  }

  int get totalPages =>
      (widget.magasins.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = MagasinInsertionDataSource(
      magasins: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
    );
  }

  @override
  void didUpdateWidget(covariant TableauMagasinInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.magasins != widget.magasins) {
      dataSource.updateMagasins(
        paginatedData,
        selectedMagasins: widget.multiple
            ? widget.selectedMagasins
            : (widget.selectedMagasin != null ? [widget.selectedMagasin!] : null),
      );
    }
  }

  void _selectRow(int index) {
    if (index < 0 || index >= paginatedData.length) return;

    setState(() {
      dataSource.selectRow(index, widget.multiple);
      if (!widget.multiple) _controller.selectedIndex = index;
    });

    if (widget.multiple) {
      final selectedMagasins = dataSource.selectedIndexes
          .map((i) => paginatedData[i])
          .toList();
      widget.onSelectionMultipleChanged?.call(selectedMagasins);
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