// lib/core/widget/tableau/pannier/pannier_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/pannier.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class PannierDataSource extends BaseTableDataSource<Pannier> {
  final AppLocalizations l10n;

  PannierDataSource({
    required List<Pannier> panniers,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: panniers);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Pannier p, String field) {
    switch (field) {
      case 'code':
        return p.code;
      case 'date':
        return formatDate(p.date);
      case 'nombreArticle':
        return p.nombreArticle ?? 0;
      case 'quantiteProduit':
        return p.quantiteProduit ?? 0;
      case 'montant':
        return "${p.montant} ${l10n.currency}";
      case 'verse':
        return "${p.verse} ${l10n.currency}";
      case 'reste':
        return "${p.reste} ${l10n.currency}";
      case 'client':
        return p.client;
      case 'modePaiement':
        return p.modePaiement ?? '';
      case 'montantAchat':
        return "${p.montantAchat} ${l10n.currency}";
      case 'marge':
        return "${p.marge} ${l10n.currency}";

      case 'caissier':
        return p.caissier;
      case 'etat':
        return p.etat ? l10n.active : l10n.inactive;
      case 'observation':
        return p.observation ?? '';
      case 'typepannier':
        return p.typepannier ?? '';
      case 'dateCree':
        return formatDate(p.dateCree);
      case 'creeParCode':
        return p.caissier_code;
      case 'dateModif':
        return formatDate(p.dateModif);
      case 'modifPar':
        return p.modifPar ?? '';
      case 'dateAnnul':
        return formatDate(p.dateAnnul);
      case 'annulPar':
        return p.annulPar ?? '';
      case 'motifAnnul':
        return p.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Pannier item) {
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

    if (columnName == 'reste') {
      final double resteValue = item.reste;

      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          "$resteValue ${l10n.currency}",
          style: TextStyle(
            fontSize: AppConst.FontSizeTable,
            color: resteValue > 0 ? Colors.red : Colors.black,
            fontWeight: resteValue > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
    }

    return null;
  }

  void updateProduits(List<Pannier> newProduits) => updateItems(newProduits);
}
