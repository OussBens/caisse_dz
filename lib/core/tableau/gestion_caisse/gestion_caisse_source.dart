import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/gestion_caisse.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class CaisseGestionDataSource extends BaseTableDataSource<CaisseGestion> {
  final AppLocalizations l10n;

  CaisseGestionDataSource({
    required List<CaisseGestion> caisses,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: caisses);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(CaisseGestion caisse, String field) {
    switch (field) {
      case 'etat':
        return caisse.etat ? l10n.active : l10n.inactive;
      case 'code':
        return caisse.code;
      case 'nomCaisse':
        return caisse.nomCaisse;
      case 'magasin':
        return caisse.magasin;
      case 'type':
        return caisse.typecaisse;
      case 'soldeInitial':
        return caisse.soldeInitial;
      case 'observation':
        return caisse.observation;

      // Audit
      case 'dateCree':
        return formatDate(caisse.dateCree);
      case 'creeParCode':
        return caisse.creeParCode;
      case 'dateModif':
        return formatDate(caisse.dateModif);
      case 'modifPar':
        return caisse.modifPar;
      case 'dateAnnul':
        return formatDate(caisse.dateAnnul);
      case 'annulPar':
        return caisse.annulPar;
      case 'motifAnnul':
        return caisse.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, CaisseGestion item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<CaisseGestion> newCaisses) => updateItems(newCaisses);
}
