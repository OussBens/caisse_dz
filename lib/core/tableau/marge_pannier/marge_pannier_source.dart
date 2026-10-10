import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Une ligne du tableau "Bénéfice par pannier" : un panier de la caisse
/// sélectionnée, enrichi du nom du client et du caissier.
class LigneMargePannier {
  final String codeCaisse;
  final String codePannier;
  final DateTime datePannier;
  final String nomClient;
  final double montant;
  final double marge;
  final String nomCaissier;
  final bool etat;

  const LigneMargePannier({
    required this.codeCaisse,
    required this.codePannier,
    required this.datePannier,
    required this.nomClient,
    required this.montant,
    required this.marge,
    required this.nomCaissier,
    required this.etat,
  });
}

class MargePannierDataSource extends BaseTableDataSource<LigneMargePannier> {
  final AppLocalizations l10n;

  MargePannierDataSource({
    required List<LigneMargePannier> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(LigneMargePannier l, String field) {
    switch (field) {
      case 'codeCaisse':
        return l.codeCaisse;
      case 'codePannier':
        return l.codePannier;
      case 'datePannier':
        return formatDate(l.datePannier);
      case 'nomClient':
        return l.nomClient;
      case 'montant':
        return l.montant;
      case 'marge':
        return l.marge;
      case 'nomCaissier':
        return l.nomCaissier;
      case 'etat':
        return l.etat ? l10n.active : l10n.inactive;
      default:
        return '';
    }
  }

  String _montant(double v) => "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}";

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneMargePannier item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'montant') {
      return Center(child: Text(_montant(item.montant)));
    }

    if (columnName == 'marge') {
      return Center(
        child: Text(
          _montant(item.marge),
          style: TextStyle(
            color: item.marge >= 0 ? Appstyle.successInk : Appstyle.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneMargePannier> newLignes) => updateItems(newLignes);
}
