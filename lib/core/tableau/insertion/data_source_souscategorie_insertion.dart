import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';

class SousCategorieInsertionDataSource extends DataGridSource {
  List<SousCategorie> sousCategories;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  SousCategorieInsertionDataSource({
    required this.sousCategories,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void update(List<SousCategorie> newsousCategories) {
    sousCategories = newsousCategories;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(sousCategories.length, (index) {
      final s = sousCategories[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: s.code),
        DataGridCell(columnName: 'nom', value: s.nom),
        DataGridCell(columnName: 'observation', value: s.observation),
        DataGridCell(columnName: 'categorieNom', value: s.categorieCode),
        DataGridCell(columnName: 'etat', value: s.etat ? l10n.active : l10n.inactive),
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
          child: Text(cell.value?.toString() ?? '',
            style: const TextStyle(
              fontSize: AppConst.FontSizeTable,
            ),),
        );
      }).toList(),
    );
  }

  void updateSousCategories(
      List<SousCategorie> newSousCategories, {
        SousCategorie? selectedSousCategorie,
      }) {
    sousCategories
      ..clear()
      ..addAll(newSousCategories);

    if (selectedSousCategorie != null) {
      selectedIndex = sousCategories.indexWhere((s) => s.id == selectedSousCategorie.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}