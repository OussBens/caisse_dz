import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/besoinList.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class BesoinListDataSource extends BaseTableDataSource<BesoinList> {
  final AppLocalizations l10n;

  BesoinListDataSource({
    required List<BesoinList> besoins,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: besoins);

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(BesoinList besoin, String field) {
    switch (field) {
      case 'code':
        return besoin.code;
      case 'numero':
        return besoin.numero;
      case 'date':
        return formatDate(besoin.date);
      case 'montant':
        return besoin.montant;
      case 'nombreArticle':
        return besoin.nombreArticle;
      case 'quantite':
        return besoin.quantite;
      case 'fournisseur':
        return besoin.fournisseur;
      case 'etat':
        return besoin.etat ? l10n.actif : l10n.inactif;
      case 'dateCree':
        return formatDate(besoin.dateCree);
      case 'creeParCode':
        return besoin.creeParCode;
      case 'dateModif':
        return formatDate(besoin.dateModif);
      case 'modifParCode':
        return besoin.modifParCode;
      case 'dateAnnul':
        return formatDate(besoin.dateAnnul);
      case 'annulParCode':
        return besoin.annulParCode;
      case 'motifAnnul':
        return besoin.motifAnnul;
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, BesoinList item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    if (columnName == 'montant') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            item.montant.toString(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: AppConst.FontSizeTable,
            ),
          ),
        ),
      );
    }
    return null;
  }

  void updateBesoinsList(List<BesoinList> newBesoins) => updateItems(newBesoins);
}
