import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/gestion_caisse.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';

class CaisseInsertionDataSource extends DataGridSource {
  List<CaisseGestion> caisses;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  CaisseInsertionDataSource({
    required this.caisses,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void update(List<CaisseGestion> newCaisses) {
    caisses = newCaisses;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(caisses.length, (index) {
      final c = caisses[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: c.code),
        DataGridCell(columnName: 'nomCaisse', value: c.nomCaisse),
        DataGridCell(columnName: 'magasin', value: c.magasinCode),
        DataGridCell(columnName: 'typecaisse', value: c.typecaisse),
        DataGridCell(
            columnName: 'soldeInitial', value: "${c.soldeInitial.toStringAsFixed(2)} ${l10n.currency}"),
        DataGridCell(columnName: 'etat', value: c.etat ? l10n.active : l10n.inactive),
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
              activeColor: Colors.deepPurple,
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
            style: const TextStyle(
              fontSize: AppConst.FontSizeTable,
            ),
          ),
        );
      }).toList(),
    );
  }

  void updateCaisses(
      List<CaisseGestion> newCaisses, {
        CaisseGestion? selectedCaisse,
      }) {
    caisses
      ..clear()
      ..addAll(newCaisses);

    if (selectedCaisse != null) {
      selectedIndex = caisses.indexWhere((c) => c.id == selectedCaisse.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}