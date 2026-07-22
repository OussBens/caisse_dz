// lib/core/widget/tableau/zakat/zakat_data_source.dart
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/zakat.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class ZakatDataSource extends BaseTableDataSource<Zakat> {
  final AppLocalizations l10n;

  ZakatDataSource({
    required List<Zakat> zakats,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: zakats);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Zakat zakat, String field) {
    switch (field) {
      case 'etat':
        return zakat.etat ? l10n.active : l10n.inactive;
      case 'code':
        return zakat.code;
      case 'annee':
        return zakat.annee;
      case 'stock':
        return "${zakat.stock} ${l10n.currency}";
      case 'liquidites':
        return "${zakat.liquidites} ${l10n.currency}";
      case 'creances':
        return "${zakat.creances} ${l10n.currency}";
      case 'dettes':
        return "${zakat.dettes} ${l10n.currency}";
      case 'capitalTotal':
        return "${zakat.capitalTotal} ${l10n.currency}";
      case 'nissab':
        return "${zakat.nissab} ${l10n.currency}";
      case 'taux':
        return "${zakat.taux}%";
      case 'montantZakat':
        return "${zakat.montantZakat} ${l10n.currency}";
      case 'obligatoire':
        return zakat.obligatoire ? l10n.yes : l10n.no;
      case 'statut':
        return zakat.statut;
      case 'dateDebutHawl':
        return formatDate(zakat.dateDebutHawl);
      case 'dateZakatDue':
        return formatDate(zakat.dateZakatDue);
      case 'datePaiement':
        return formatDate(zakat.datePaiement);
      case 'observation':
        return zakat.observation ?? '';

      // Audit
      case 'dateCree':
        return formatDate(zakat.dateCree);
      case 'creeParCode':
        return zakat.creeParCode ?? '';
      case 'dateModif':
        return formatDate(zakat.dateModif);
      case 'modifPar':
        return zakat.modifPar ?? '';
      case 'dateAnnul':
        return formatDate(zakat.dateAnnul);
      case 'annulPar':
        return zakat.annulPar ?? '';
      case 'motifAnnul':
        return zakat.motifAnnul ?? '';

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Zakat item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'capitalTotal') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${item.capitalTotal} ${l10n.currency}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: AppConst.FontSizeTable,
            ),
          ),
        ),
      );
    }

    if (columnName == 'montantZakat') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green[400],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${item.montantZakat} ${l10n.currency}",
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

  void updateZakats(List<Zakat> newZakats) => updateItems(newZakats);
}
