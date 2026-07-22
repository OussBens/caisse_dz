import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

import '../../../../data/models/entree.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class EntreeDataSource extends BaseTableDataSource<Entree> {
  final AppLocalizations l10n;

  EntreeDataSource({
    required List<Entree> entrees,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: entrees);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Entree entree, String field) {
    switch (field) {
      case 'code':
        return entree.code;
      case 'date':
        return formatDate(entree.date);
      case 'produit':
        return entree.produit;
      case 'produitcode':
        return entree.produitcode;
      case 'prix':
        return "${entree.prix.toStringAsFixed(2)} ${l10n.currency}";
      case 'quantite':
        return entree.quantite;
      case 'montant':
        return "${entree.montant.toStringAsFixed(2)} ${l10n.currency}";
      case 'fournisseur':
        return entree.fournisseur;
      case 'fournisseurcode':
        return entree.fournisseurCode;
      case 'etat':
        return entree.etat ? l10n.active : l10n.cancelled;
      case 'observation':
        return entree.observation ?? '';
      case 'dateCree':
        return formatDate(entree.dateCree);
      case 'creeparcode':
        return entree.creeParCode;
      case 'creeParCode':
        return entree.creeParCode;
      case 'dateModif':
        return formatDate(entree.dateModif);
      case 'modifParCode':
        return entree.modifParCode ?? '';
      case 'dateAnnul':
        return formatDate(entree.dateAnnul);
      case 'annulPar':
        return entree.annulPar ?? '';
      case 'motifAnnul':
        return entree.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Entree item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<Entree> newEntrees) => updateItems(newEntrees);
}
