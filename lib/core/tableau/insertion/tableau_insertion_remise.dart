
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'data_source_remise_insertion.dart';

class TableauRemiseInsertion extends StatefulWidget {
  final List<Remise> remises;
  final bool multiple;
  final Remise? selectedRemise;
  final List<Remise>? selectedRemises;
  final void Function(Remise)? onSelectionChanged;
  final void Function(List<Remise>)? onSelectionMultipleChanged;
  final void Function(Remise)? onDoubleTapRemise;

  const TableauRemiseInsertion({
    Key? key,
    required this.remises,
    this.multiple = false,
    this.selectedRemise,
    this.selectedRemises,
    this.onSelectionChanged,
    this.onSelectionMultipleChanged,
    this.onDoubleTapRemise,
  }) : super(key: key);

  @override
  State<TableauRemiseInsertion> createState() => _TableauRemiseInsertionState();
}

class _TableauRemiseInsertionState extends State<TableauRemiseInsertion> {
  late RemiseInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();
  int rowsPerPage = 15;
  int currentPage = 1;
  final Map<String, double> columnWidths = {};

  List<Remise> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.remises.length);
    if (start >= widget.remises.length) return [];
    return widget.remises.sublist(start, end);
  }

  int get totalPages =>
      (widget.remises.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = RemiseInsertionDataSource(
      remises: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
    );
  }

  @override
  void didUpdateWidget(covariant TableauRemiseInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.remises != widget.remises) {
      dataSource.updateRemises(
        paginatedData,
        selectedRemises: widget.multiple
            ? widget.selectedRemises
            : (widget.selectedRemise != null ? [widget.selectedRemise!] : null),
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
      final selectedRemises = dataSource.selectedIndexes
          .map((i) => paginatedData[i])
          .toList();
      widget.onSelectionMultipleChanged?.call(selectedRemises);
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
              borderRadius: BorderRadius.circular(Appstyle.radiusCard),
              boxShadow: const [BoxShadow(color: Appstyle.shadowSoft, blurRadius: 12)],
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
                  selectionMode: SelectionMode.none,
                  headerRowHeight: 36,
                  rowHeight: 38,
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
                    GridColumn(columnName: 'select', width: 60, label: const SizedBox()),
                    _col('code', l10n.code),
                    _col('nom', l10n.name),
                    _col('observation', l10n.observation),
                    _col('type', l10n.type),
                    _col('montant', l10n.amount),
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
        child: Text(label, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
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
                : null,),
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
                : null,),
          const SizedBox(width: 20),
          DropdownButton<int>(
            value: rowsPerPage,
            items: [10, 15, 20, 30]
                .map((e) => DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
                .toList(),
            onChanged: (v) {
              setState(() {
                rowsPerPage = v!;
                dataSource.update(paginatedData);
                currentPage = 1;
              });
            },
          ),
        ],
      ),
    );
  }
}