import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class FournisseurInsertionDataSource extends DataGridSource {
  List<Fournisseur> fournisseurs;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  FournisseurInsertionDataSource({
    required this.fournisseurs,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void update(List<Fournisseur> newFournisseurs) {
    fournisseurs = newFournisseurs;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(fournisseurs.length, (index) {
      final f = fournisseurs[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: f.code),
        DataGridCell(columnName: 'nom', value: f.nom),
        DataGridCell(columnName: 'telephone', value: f.telephone),
        DataGridCell(columnName: 'wilaya', value: f.wilaya),
        DataGridCell(columnName: 'type', value: f.type),
        DataGridCell(columnName: 'etat', value: f.etat ? l10n.active : l10n.inactive),
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

  void updateFournisseurs(
      List<Fournisseur> newFournisseurs, {
        Fournisseur? selectedFournisseur,
      }) {
    fournisseurs
      ..clear()
      ..addAll(newFournisseurs);

    if (selectedFournisseur != null) {
      selectedIndex = fournisseurs.indexWhere((f) => f.id == selectedFournisseur.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}