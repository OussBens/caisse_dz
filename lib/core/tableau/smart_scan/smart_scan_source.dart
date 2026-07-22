import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/smart_scan.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class SmartScanDataSource extends BaseTableDataSource<SmartScan> {
  final AppLocalizations l10n;

  SmartScanDataSource({
    required List<SmartScan> scans,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: scans);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(SmartScan scan, String field) {
    switch (field) {
      case 'code':
        return scan.code;
      case 'date':
        return formatDate(scan.date);
      case 'montant':
        return "${scan.montant} ${l10n.currency}";
      case 'montantCalcul':
        return "${scan.montantCalcul} ${l10n.currency}";
      case 'nbrProduit':
        return scan.nbrProduit;
      case 'nbrProduitCalcul':
        return scan.nbrProduitCalcul;
      case 'fournisseur':
        return scan.fournisseur;
      case 'quantiteArticle':
        return scan.quantiteArticle;
      case 'quantiteArticleCalcul':
        return scan.quantiteArticleCalcul;
      case 'etat':
        return scan.etat ? l10n.active : l10n.inactive;
      case 'activity':
        return scan.activity;
      case 'observation':
        return scan.observation;

      /// Audit
      case 'dateCree':
        return formatDate(scan.dateCree);
      case 'creeParCode':
        return scan.creeParCode;
      case 'dateModif':
        return formatDate(scan.dateModif);
      case 'modifParCode':
        return scan.modifParCode;
      case 'dateAnnul':
        return formatDate(scan.dateAnnul);
      case 'annulParCode':
        return scan.annulParCode;
      case 'motifAnnul':
        return scan.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, SmartScan item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'ecart') {
      final bool hasGap = item.ecart;

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hasGap ? Colors.red : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            hasGap ? l10n.yes : l10n.no,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: AppConst.FontSizeTable,
            ),
          ),
        ),
      );
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
            "${item.montant} ${l10n.currency}",
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

  void update(List<SmartScan> newScans) => updateItems(newScans);
}
