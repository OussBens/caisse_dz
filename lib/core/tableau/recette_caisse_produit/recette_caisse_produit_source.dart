import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Une ligne du tableau "Recette Caisse par produit" : un produit vendu dans
/// un panier de la caisse sélectionnée (un panier de N produits devient N
/// lignes), enrichi du nom du produit et du caissier.
class LigneRecetteCaisseProduit {
  final DateTime dateCree;
  final String codeCaisse;
  final DateTime datePannier;
  final String codePannier;
  final String nomProduit;
  final double quantite;
  final double prixVente;
  final double montant;
  final String nomCaissier;
  final bool etat;

  const LigneRecetteCaisseProduit({
    required this.dateCree,
    required this.codeCaisse,
    required this.datePannier,
    required this.codePannier,
    required this.nomProduit,
    required this.quantite,
    required this.prixVente,
    required this.montant,
    required this.nomCaissier,
    required this.etat,
  });
}

class RecetteCaisseProduitDataSource extends BaseTableDataSource<LigneRecetteCaisseProduit> {
  final AppLocalizations l10n;

  RecetteCaisseProduitDataSource({
    required List<LigneRecetteCaisseProduit> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(LigneRecetteCaisseProduit l, String field) {
    switch (field) {
      case 'date':
        return formatDate(l.dateCree);
      case 'codeCaisse':
        return l.codeCaisse;
      case 'datePannier':
        return formatDate(l.datePannier);
      case 'codePannier':
        return l.codePannier;
      case 'nomProduit':
        return l.nomProduit;
      case 'quantite':
        return l.quantite;
      case 'prixVente':
        return l.prixVente;
      case 'montant':
        return l.montant;
      case 'nomCaissier':
        return l.nomCaissier;
      case 'etat':
        return l.etat ? l10n.active : l10n.inactive;
      default:
        return '';
    }
  }

  // sortValue par défaut (= cellValue) suffit désormais : quantite/prixVente/
  // montant sont déjà des double bruts dans cellValue.

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneRecetteCaisseProduit item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'quantite') {
      return Center(child: Text(NumberFormatUtil.formatMontant(item.quantite, decimales: 0)));
    }

    if (columnName == 'prixVente') {
      return Center(child: Text("${NumberFormatUtil.formatMontant(item.prixVente, decimales: 2)} ${l10n.currency}"));
    }

    if (columnName == 'montant') {
      return Center(
        child: Text(
          "${NumberFormatUtil.formatMontant(item.montant, decimales: 2)} ${l10n.currency}",
          style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneRecetteCaisseProduit> newLignes) => updateItems(newLignes);
}
