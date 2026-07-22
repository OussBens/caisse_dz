import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/transfert.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class TransfertCaisseDataSource extends BaseTableDataSource<TransfertCaisse> {
  final AppLocalizations l10n;

  TransfertCaisseDataSource({
    required List<TransfertCaisse> transferts,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: transferts);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(TransfertCaisse t, String field) {
    switch (field) {
      case 'code':
        return t.code;
      case 'dateTransfert':
        return formatDate(t.dateTransfert);
      case 'caisseExp':
        return t.caisseExp;
      case 'caisseDest':
        return t.caisseDest;
      case 'montant':
        return "${t.montant} ${l10n.currency}";
      case 'etat':
        return t.etat ? l10n.active : l10n.inactive;
      case 'observation':
        return t.observation;

      // Audit
      case 'dateCree':
        return formatDate(t.dateCree);
      case 'creeParCode':
        return t.creeParCode;
      case 'dateModif':
        return formatDate(t.dateModif);
      case 'modifPar':
        return t.modifPar;
      case 'dateAnnul':
        return formatDate(t.dateTransfert);
      case 'annulPar':
        return t.annulPar;
      case 'motifAnnul':
        return t.motifAnnul;
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, TransfertCaisse item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<TransfertCaisse> newList) => updateItems(newList);
}
