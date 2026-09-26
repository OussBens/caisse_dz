import 'package:caisse_dz/core/tableau/insertion/data_source_pack_categorie.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/pack.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class TableauPackInsertion extends StatefulWidget {
  final List<Pack> packs;
  final bool multiple;
  final Pack? selectedPack;
  final List<Pack>? selectedPacks;
  final void Function(List<Pack>)? onSelectionMultipleChanged;
  final void Function(Pack)? onSelectionChanged;
  final void Function(Pack)? onDoubleTapPack;

  const TableauPackInsertion({
    Key? key,
    required this.packs,
    this.multiple = false,
    this.onSelectionChanged,
    this.onDoubleTapPack,
    this.selectedPack,
    this.onSelectionMultipleChanged,
    this.selectedPacks,
  }) : super(key: key);

  @override
  State<TableauPackInsertion> createState() =>
      _TableauPackInsertionState();
}

class _TableauPackInsertionState extends State<TableauPackInsertion> {
  late PackInsertionDataSource dataSource;
  final DataGridController _controller = DataGridController();

  int rowsPerPage = 15;
  int currentPage = 1;
  final Map<String, double> columnWidths = {};

  List<Pack> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.packs.length);
    if (start >= widget.packs.length) return [];
    return widget.packs.sublist(start, end);
  }

  int get totalPages =>
      (widget.packs.length / rowsPerPage).ceil().clamp(1, 9999);

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = PackInsertionDataSource(
      packs: paginatedData,
      onSelectRow: _selectRow,
      l10n: l10n,
    );
  }

  @override
  void didUpdateWidget(covariant TableauPackInsertion oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.packs != widget.packs) {
      dataSource.updatePacks(
        paginatedData,
        selectedPacks: widget.multiple
            ? widget.selectedPacks
            : (widget.selectedPack != null ? [widget.selectedPack!] : null),
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
      final selectedPacks = dataSource.selectedIndexes
          .map((i) => paginatedData[i])
          .toList();
      widget.onSelectionMultipleChanged?.call(selectedPacks);
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
                    GridColumn(columnName: 'select', width: 60, allowSorting: false, allowFiltering: false, label: const SizedBox()),
                    _col('code', l10n.code),
                    _col('nom', l10n.name),
                    _col('observation', l10n.observation),
                    _col('prixVente', l10n.salePrice),
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