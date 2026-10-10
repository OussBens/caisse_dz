import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/categorie.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class CategorieInsertionDataSource extends DataGridSource {
  List<Categorie> categories;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  CategorieInsertionDataSource({
    required this.categories,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void _buildRows() {
    _rows = List.generate(categories.length, (index) {
      final c = categories[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: c.code),
        DataGridCell(columnName: 'nom', value: c.nom),
        DataGridCell(columnName: 'observation', value: c.observation),
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
          child: Text(cell.value?.toString() ?? '',
            style: const TextStyle(
              fontSize: AppConst.FontSizeTable,
            ),),
        );
      }).toList(),
    );
  }

  void updateCategories(
      List<Categorie> newCategories, {
        Categorie? selectedCategorie,
      }) {
    categories
      ..clear()
      ..addAll(newCategories);

    if (selectedCategorie != null) {
      selectedIndex = categories.indexWhere((c) => c.id == selectedCategorie.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }

  /// 🔄 Mise à jour pagination / données
  void update(List<Categorie> newCategories) {
    categories = newCategories;
    _buildRows();
    notifyListeners();
  }
}