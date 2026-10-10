import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Une ligne du tableau "Recette Caisse par pannier" : un panier de la
/// caisse sélectionnée, enrichi du nom du caissier.
class LigneRecetteCaisse {
  final DateTime dateCree;
  final String codeCaisse;
  final DateTime datePannier;
  final String codePannier;
  final double montant;
  final double paye;
  final double reste;
  final String nomCaissier;
  final bool etat;

  const LigneRecetteCaisse({
    required this.dateCree,
    required this.codeCaisse,
    required this.datePannier,
    required this.codePannier,
    required this.montant,
    required this.paye,
    required this.reste,
    required this.nomCaissier,
    required this.etat,
  });
}

class RecetteCaisseDataSource extends BaseTableDataSource<LigneRecetteCaisse> {
  final AppLocalizations l10n;

  RecetteCaisseDataSource({
    required List<LigneRecetteCaisse> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(LigneRecetteCaisse l, String field) {
    switch (field) {
      case 'date':
        return formatDate(l.dateCree);
      case 'codeCaisse':
        return l.codeCaisse;
      case 'datePannier':
        return formatDate(l.datePannier);
      case 'codePannier':
        return l.codePannier;
      case 'montant':
        return l.montant;
      case 'paye':
        return l.paye;
      case 'reste':
        return l.reste;
      case 'nomCaissier':
        return l.nomCaissier;
      case 'etat':
        return l.etat ? l10n.active : l10n.inactive;
      default:
        return '';
    }
  }

  // sortValue par défaut (= cellValue) suffit désormais : montant/paye/reste
  // sont déjà des double bruts dans cellValue.

  String _montant(double v) => "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}";

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneRecetteCaisse item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'montant') {
      return Center(child: Text(_montant(item.montant)));
    }

    if (columnName == 'paye') {
      return Center(child: Text(_montant(item.paye)));
    }

    if (columnName == 'reste') {
      return Center(
        child: Text(
          _montant(item.reste),
          style: item.reste > 0
              ? const TextStyle(color: Appstyle.danger, fontWeight: FontWeight.bold)
              : null,
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneRecetteCaisse> newLignes) => updateItems(newLignes);
}
