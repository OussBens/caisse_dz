import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Une ligne de la situation "Coût produit" : prix d'achat et de vente
/// constatés sur la période (min / max / moyen pondéré par la quantité) et
/// quantités achetées / vendues.
class LigneCoutProduit {
  final String codeProduit;
  final String nomProduit;
  final double prixAchatMin;
  final double prixAchatMax;
  final double prixAchatMoyen;
  final double quantiteAchetee;
  final double prixVenteMin;
  final double prixVenteMax;
  final double prixVenteMoyen;
  final double quantiteVendue;

  const LigneCoutProduit({
    required this.codeProduit,
    required this.nomProduit,
    required this.prixAchatMin,
    required this.prixAchatMax,
    required this.prixAchatMoyen,
    required this.quantiteAchetee,
    required this.prixVenteMin,
    required this.prixVenteMax,
    required this.prixVenteMoyen,
    required this.quantiteVendue,
  });
}

class CoutProduitDataSource extends BaseTableDataSource<LigneCoutProduit> {
  final AppLocalizations l10n;

  CoutProduitDataSource({
    required List<LigneCoutProduit> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  static const _colonnesPrix = {
    'prixAchatMin', 'prixAchatMax', 'prixAchatMoyen',
    'prixVenteMin', 'prixVenteMax', 'prixVenteMoyen',
  };

  @override
  dynamic cellValue(LigneCoutProduit l, String field) {
    switch (field) {
      case 'codeProduit':
        return l.codeProduit;
      case 'nomProduit':
        return l.nomProduit;
      case 'prixAchatMin':
        return l.prixAchatMin;
      case 'prixAchatMax':
        return l.prixAchatMax;
      case 'prixAchatMoyen':
        return l.prixAchatMoyen;
      case 'quantiteAchetee':
        return l.quantiteAchetee;
      case 'prixVenteMin':
        return l.prixVenteMin;
      case 'prixVenteMax':
        return l.prixVenteMax;
      case 'prixVenteMoyen':
        return l.prixVenteMoyen;
      case 'quantiteVendue':
        return l.quantiteVendue;
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneCoutProduit item) {
    if (_colonnesPrix.contains(columnName)) {
      final v = (cell.value as num?)?.toDouble() ?? 0;
      return Center(
        child: Text(v > 0 ? "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}" : '-'),
      );
    }
    if (columnName == 'quantiteAchetee' || columnName == 'quantiteVendue') {
      final v = (cell.value as num?)?.toDouble() ?? 0;
      return Center(
        child: Text(
          QuantiteFormat.format(v),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: columnName == 'quantiteAchetee' ? Appstyle.primary : Appstyle.successInk,
          ),
        ),
      );
    }
    if (columnName == 'nomProduit') {
      return boldCell(item.nomProduit, align: TextAlign.left);
    }
    return null;
  }

  void updateLignes(List<LigneCoutProduit> newLignes) => updateItems(newLignes);
}
