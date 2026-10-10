import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/pannier.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Source de données Syncfusion pour le tableau de sélection d'un panier
/// (dialog [InsertionPannierDialog]). Même structure que
/// [ClientInsertionDataSource] : une colonne "select" (checkbox) + colonnes
/// d'affichage, sélection simple par index.
class PannierInsertionDataSource extends DataGridSource {
  List<Pannier> panniers;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  PannierInsertionDataSource({
    required this.panniers,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  static String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  void update(List<Pannier> newPanniers) {
    panniers = newPanniers;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(panniers.length, (index) {
      final p = panniers[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: p.code),
        DataGridCell(columnName: 'date', value: _formatDate(p.date)),
        DataGridCell(
            columnName: 'montant',
            value: NumberFormatUtil.formatMontant(p.montant, decimales: 2)),
        DataGridCell(
            columnName: 'articles',
            value: (p.nombreArticle ?? p.quantiteProduit ?? 0).toString()),
        DataGridCell(
            columnName: 'etat', value: p.etat ? l10n.active : l10n.inactive),
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

  void updatePanniers(
    List<Pannier> newPanniers, {
    Pannier? selectedPannier,
  }) {
    panniers
      ..clear()
      ..addAll(newPanniers);

    if (selectedPannier != null) {
      selectedIndex = panniers.indexWhere((p) => p.id == selectedPannier.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}
