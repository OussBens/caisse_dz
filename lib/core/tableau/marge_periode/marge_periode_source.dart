import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Une ligne du tableau "Bénéfice par période" : total du jour (montant +
/// marge) pour la caisse sélectionnée, agrégé sur tous les panniers de ce
/// jour compris dans la période et les fourchettes filtrées.
class LigneMargePeriode {
  final String codeCaisse;
  final DateTime date;
  final double montantJour;
  final double margeJour;

  const LigneMargePeriode({
    required this.codeCaisse,
    required this.date,
    required this.montantJour,
    required this.margeJour,
  });
}

class MargePeriodeDataSource extends BaseTableDataSource<LigneMargePeriode> {
  final AppLocalizations l10n;

  MargePeriodeDataSource({
    required List<LigneMargePeriode> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(LigneMargePeriode l, String field) {
    switch (field) {
      case 'codeCaisse':
        return l.codeCaisse;
      case 'date':
        return formatDate(l.date);
      case 'montantJour':
        return l.montantJour;
      case 'margeJour':
        return l.margeJour;
      default:
        return '';
    }
  }

  @override
  dynamic sortValue(LigneMargePeriode item, String field) {
    if (field == 'date') return item.date;
    return cellValue(item, field);
  }

  String _montant(double v) => "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}";

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneMargePeriode item) {
    if (columnName == 'montantJour') {
      return Center(child: Text(_montant(item.montantJour)));
    }

    if (columnName == 'margeJour') {
      return Center(
        child: Text(
          _montant(item.margeJour),
          style: TextStyle(
            color: item.margeJour >= 0 ? Appstyle.successInk : Appstyle.danger,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneMargePeriode> newLignes) => updateItems(newLignes);
}
