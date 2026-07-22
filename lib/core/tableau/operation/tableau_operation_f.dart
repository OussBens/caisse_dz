
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/operation_fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'operation_source_f.dart';

class TableauSituationFournisseurAdvanced extends StatefulWidget {
  final List<OperationFournisseur> operations;

  const TableauSituationFournisseurAdvanced({
    super.key,
    required this.operations,
  });

  @override
  State<TableauSituationFournisseurAdvanced> createState() =>
      _TableauSituationFournisseurAdvancedState();
}

class _TableauSituationFournisseurAdvancedState
    extends State<TableauSituationFournisseurAdvanced> {
  late SituationFournisseurDataSource dataSource;

  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;

  @override
  void didUpdateWidget(covariant TableauSituationFournisseurAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.operations != widget.operations) {
      currentPage = 1; // reset pagination
      dataSource.update(paginatedData);
    }
  }

  List<OperationFournisseur> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage).clamp(0, widget.operations.length);
    if (start >= widget.operations.length) return [];
    return widget.operations.sublist(start, end);
  }

  int get totalPages =>
      widget.operations.isEmpty
          ? 1
          : (widget.operations.length / rowsPerPage).ceil();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    dataSource = SituationFournisseurDataSource(paginatedData, l10n);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 10),
        _buildPagination(l10n),
      ],
    );
  }

  // ================= TABLE =================
  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Appstyle.Tblanc,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.violet.withOpacity(0.75),
            gridLineColor: Colors.grey.shade300,
            rowHoverColor: Appstyle.violet.withOpacity(0.08),
            selectionColor: Appstyle.violet.withOpacity(0.15),
            sortIconColor: Colors.white,
            filterIconColor: Colors.white,
          ),
          child: SfDataGrid(
            source: dataSource,
            rowHeight: 38,
            headerRowHeight: 36,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,
            gridLinesVisibility: GridLinesVisibility.horizontal,
            headerGridLinesVisibility: GridLinesVisibility.none,
            columnWidthMode: ColumnWidthMode.fill,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 150) w = 150;
              if (w > 1000) w = 1000;
              setState(() => columnWidths[details.column.columnName] = w);
              return true;
            },
            columns: [
              _col('date', l10n.date),
              _col('type', l10n.type),
              _col('ref', l10n.ref),
              _colMontant('debit', l10n.debit),
              _colMontant('credit', l10n.credit),
              _colMontant('solde', l10n.balance),
              _col('desc', l10n.description, align: Alignment.centerLeft),
            ],
          ),
        ),
      ),
    );
  }

  // ================= PAGINATION =================
  Widget _buildPagination(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10),
        ],
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
          Text(
            '${l10n.page} $currentPage / $totalPages',
            style: Appstyle.textSB,
          ),
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
              value: e,
              child: Text('$e ${l10n.rowsPerPage}'),
            ))
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

  // ================= COLUMNS =================
  GridColumn _col(String name, String label,
      {Alignment align = Alignment.center}) {
    return GridColumn(
      columnName: name,
      width: columnWidths[name] ?? 180,
      label: Container(
        alignment: align,
        padding: const EdgeInsets.all(8),
        child: Text(
          label,
          style: Appstyle.textSB.copyWith(color: Colors.white),
        ),
      ),
    );
  }

  GridColumn _colMontant(String name, String label) {
    return _col(name, label, align: Alignment.centerRight);
  }
}