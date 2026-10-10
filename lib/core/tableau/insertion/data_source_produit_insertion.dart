import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/produit.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class ProduitInsertionDataSource extends DataGridSource {
  List<Produit> produits;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  /// Quantité par produit calculée depuis le journal des mouvements — voir
  /// produit_screen.dart pour le même mécanisme. Remplace Produit.quantite.
  Map<String, double> quantites;

  final Set<int> selectedIndexes = {}; // indices sélectionnés
  late List<DataGridRow> _rows;

  ProduitInsertionDataSource({
    required this.produits,
    this.onSelectRow,
    required this.l10n,
    this.quantites = const {},
  }) {
    _buildRows();
  }

  void update(List<Produit> newProduits) {
    produits = newProduits;
    _buildRows();
    notifyListeners();
  }

  void updateQuantites(Map<String, double> newQuantites) {
    quantites = newQuantites;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(produits.length, (index) {
      final p = produits[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(columnName: 'select', value: selectedIndexes.contains(index)),
        DataGridCell(columnName: 'code', value: p.code),
        DataGridCell(columnName: 'nom', value: p.nom),
        DataGridCell(columnName: 'marque', value: p.marque),
        DataGridCell(columnName: 'description', value: p.description),
        DataGridCell(columnName: 'prixVente', value: p.prixVente),
        DataGridCell(columnName: 'quantite', value: quantites[p.code] ?? 0),
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
              activeColor: Appstyle.primary,
              onChanged: (_) {
                onSelectRow?.call(rowIndex); // 🔥 clé
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

  void updateProduits(List<Produit> newProduits, {List<Produit>? selectedProduits,}) {
    produits
      ..clear()
      ..addAll(newProduits);

    selectedIndexes.clear();

    if (selectedProduits != null) {
      for (var r in selectedProduits) {
        final index = produits.indexWhere((e) => e.id == r.id);
        if (index != -1) selectedIndexes.add(index);
      }
    }

    _buildRows();
    notifyListeners();
  }
}