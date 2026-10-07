import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/gestion_caisse.dart';
import '../../../../data/models/transfert.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class TransfertCaisseDataSource extends BaseTableDataSource<TransfertCaisse> {
  final AppLocalizations l10n;
  final List<CaisseGestion> caisses;

  TransfertCaisseDataSource({
    required List<TransfertCaisse> transferts,
    required super.columnConfig,
    required this.l10n,
    this.caisses = const [],
    super.utilisateurs = const [],
  }) : super(items: transferts);

  String _nomCaisse(String? code) =>
      caisses.firstWhereOrNull((c) => c.code == code)?.nomCaisse ?? code ?? '';

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  // Tri sur la valeur brute (DateTime / nombre) et non sur le texte affiché :
  // "jj/mm/aaaa" trié comme du texte classait d'abord par jour, et "1200 DA"
  // par ordre alphabétique.
  @override
  dynamic sortValue(TransfertCaisse t, String field) {
    switch (field) {
      case 'dateTransfert':
        return t.dateTransfert;
      case 'montant':
        return t.montant;
      case 'dateCree':
        return t.dateCree;
      case 'dateModif':
        return t.dateModif;
      case 'dateAnnul':
        return t.dateAnnul;
      default:
        return cellValue(t, field);
    }
  }

  @override
  dynamic cellValue(TransfertCaisse t, String field) {
    switch (field) {
      case 'code':
        return t.code;
      case 'dateTransfert':
        return formatDate(t.dateTransfert);
      case 'caisseExpCode':
        return _nomCaisse(t.caisseExpCode);
      case 'caisseDestCode':
        return _nomCaisse(t.caisseDestCode);
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
        return nomUtilisateur(t.creeParCode);
      case 'dateModif':
        return formatDate(t.dateModif);
      case 'modifParCode':
        return nomUtilisateur(t.modifParCode);
      case 'dateAnnul':
        return formatDate(t.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(t.annulParCode);
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
