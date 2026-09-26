import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../data/constant.dart';
import '../../../data/models/produit.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_style.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class ProduitCaisseDataSource extends DataGridSource {
  List<Produit> produits;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;
  final double Function(Produit)? getQuantiteVirtuelle;
  // ✅ Repli utilisé uniquement si getQuantiteVirtuelle n'est pas fourni
  // (ne se produit pas en pratique côté caisse_screen.dart, mais évite toute
  // dépendance résiduelle à Produit.quantite).
  final Map<String, double> quantites;
  int? selectedIndex;
  late List<DataGridRow> _rows;

  ProduitCaisseDataSource({
    required this.produits,
    this.onSelectRow,
    required this.l10n,
    this.getQuantiteVirtuelle,
    this.quantites = const {},
  }) {
    _buildRows();
  }

  void refreshQuantites() {
    _buildRows();
    notifyListeners();
  }


  // ------------------------------------------------------------------
  // Construction des lignes
  // ------------------------------------------------------------------
  void _buildRows() {
    _rows = List.generate(produits.length, (index) {
      final p = produits[index];

      // ✅ Utiliser la quantité virtuelle si fournie, sinon la quantité réelle
      final quantiteAffichee = getQuantiteVirtuelle != null
          ? getQuantiteVirtuelle!(p).toInt()
          : (quantites[p.code] ?? 0).toInt();

      return DataGridRow(
        cells: [
          DataGridCell(columnName: 'code', value: p.code),
          DataGridCell(columnName: 'nom', value: p.nom),
          DataGridCell(columnName: 'marque', value: p.marque),
          DataGridCell(
            columnName: 'quantite',
            value: quantiteAffichee.toString(),
          ),
          DataGridCell(
              columnName: 'prixVente',
              value: NumberFormatUtil.formatMontant(p.prixVente, decimales: 0)
          ),
        ],
      );
    });
  }

  // ------------------------------------------------------------------
  // Sélection d'une ligne
  // ------------------------------------------------------------------
  void selectRow(int index) {
    if (index < 0 || index >= _rows.length) return;
    selectedIndex = index;
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  // ------------------------------------------------------------------
  // Rendu des lignes
  // ------------------------------------------------------------------
  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);
    final bool isSelected = rowIndex == selectedIndex;

    return DataGridRowAdapter(
      color: isSelected
          ? Appstyle.violet.withOpacity(0.25)
          : rowIndex.isEven
          ? Colors.grey.withOpacity(0.04)
          : Colors.transparent,
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            cell.value?.toString() ?? '',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: AppConst.FontSizeTable,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Appstyle.violet : Colors.black,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ------------------------------------------------------------------
  // Mise à jour des produits (pagination / recherche)
  // ------------------------------------------------------------------
  void updateProduits(List<Produit> newProduits, {Produit? selectedProduit}) {
    produits
      ..clear()
      ..addAll(newProduits);

    if (selectedProduit != null) {
      selectedIndex = produits.indexWhere((p) => p.id == selectedProduit.id);
      if (selectedIndex == -1) selectedIndex = null;
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }

  void updateCaisseProduit(List<Produit> newProduits) {
    produits = newProduits;
    _buildRows();
    notifyListeners();
  }


}