import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/pack.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class PackInsertionDataSource extends DataGridSource {
  List<Pack> packs;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  final Set<int> selectedIndexes = {}; // indices sélectionnés
  late List<DataGridRow> _rows;

  PackInsertionDataSource({
    required this.packs,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void update(List<Pack> newPacks) {
    packs = newPacks;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(packs.length, (index) {
      final p = packs[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(columnName: 'select', value: selectedIndexes.contains(index)),
        DataGridCell(columnName: 'code', value: p.code),
        DataGridCell(columnName: 'nom', value: p.nom),
        DataGridCell(columnName: 'observation', value: p.observation),
        DataGridCell(columnName: 'prixVente', value: p.prixVente),
        DataGridCell(columnName: 'etat', value: p.etat ? l10n.active : l10n.inactive),
      ]);
    });
  }

  void selectRow(int index, bool multiple) {
    if (multiple) {
      if (selectedIndexes.contains(index)) {
        selectedIndexes.remove(index);
      } else {
        selectedIndexes.add(index);
      }
    } else {
      selectedIndexes
        ..clear()
        ..add(index);
    }
    _buildRows();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);
    final isSelected = selectedIndexes.contains(rowIndex);

    return DataGridRowAdapter(
      color: isSelected ? Appstyle.violet.withOpacity(0.25) : Colors.transparent,
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'select') {
          return Center(
            child: Checkbox(
              value: isSelected,
              activeColor: Appstyle.violet,
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
            style: const TextStyle(fontSize: AppConst.FontSizeTable,
            ),),
        );
      }).toList(),
    );
  }

  void updatePacks(List<Pack> newPacks, {List<Pack>? selectedPacks,}) {
    packs
      ..clear()
      ..addAll(newPacks);

    selectedIndexes.clear();

    if (selectedPacks != null) {
      for (var r in selectedPacks) {
        final index = packs.indexWhere((e) => e.id == r.id);
        if (index != -1) selectedIndexes.add(index);
      }
    }

    _buildRows();
    notifyListeners();
  }
}