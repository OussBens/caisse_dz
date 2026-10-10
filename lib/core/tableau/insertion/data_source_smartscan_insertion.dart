import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/smart_scan.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Source de données Syncfusion pour le tableau de sélection d'un SmartScan
/// (dialog [InsertionSmartScanDialog]). Même structure que
/// [ClientInsertionDataSource].
class SmartScanInsertionDataSource extends DataGridSource {
  List<SmartScan> smartScans;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  SmartScanInsertionDataSource({
    required this.smartScans,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  static String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  void update(List<SmartScan> newScans) {
    smartScans = newScans;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(smartScans.length, (index) {
      final s = smartScans[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: s.code),
        DataGridCell(columnName: 'date', value: _formatDate(s.date)),
        DataGridCell(
            columnName: 'montant',
            value: NumberFormatUtil.formatMontant(s.montant, decimales: 2)),
        DataGridCell(
            columnName: 'nbrProduit', value: s.nbrProduit.toString()),
        DataGridCell(
            columnName: 'etat', value: s.etat ? l10n.active : l10n.inactive),
      ]);
    });
  }

  void selectRow(int index) {
    selectedIndex = index;
    _buildRows();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);

    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'select') {
          return Center(
            child: Checkbox(
              value: selectedIndex == rowIndex,
              activeColor: Appstyle.primary,
              onChanged: (_) {
                onSelectRow?.call(rowIndex);
              },
            ),
          );
        }

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            cell.value?.toString() ?? '',
            style: const TextStyle(fontSize: AppConst.FontSizeTable),
          ),
        );
      }).toList(),
    );
  }

  void updateSmartScans(
    List<SmartScan> newScans, {
    SmartScan? selectedScan,
  }) {
    smartScans
      ..clear()
      ..addAll(newScans);

    if (selectedScan != null) {
      selectedIndex = smartScans.indexWhere((s) => s.id == selectedScan.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}
