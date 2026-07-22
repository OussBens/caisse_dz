// lib/core/widget/tableau/sous_categorie/sous_categorie_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class SousCategorieDataSource extends BaseTableDataSource<SousCategorie> {
  final AppLocalizations l10n;

  SousCategorieDataSource({
    required List<SousCategorie> sousCategories,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: sousCategories);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(SousCategorie sc, String field) {
    switch (field) {
      case 'code':
        return sc.code;
      case 'nom':
        return sc.nom;
      case 'observation':
        return sc.observation ?? '';
      case 'etat':
        return sc.etat ? l10n.active : l10n.inactive;
      case 'categorieId':
        return sc.categorieId ?? '';
      case 'categorieNom':
        return sc.categorieNom ?? '';
      case 'dateCree':
        return formatDate(sc.dateCree);
      case 'creeParCode':
        return sc.creeParCode ?? '';
      case 'dateModif':
        return formatDate(sc.dateModif);
      case 'modifPar':
        return sc.modifPar ?? '';
      case 'dateAnnul':
        return formatDate(sc.dateAnnul);
      case 'annulPar':
        return sc.annulPar ?? '';
      case 'motifAnnul':
        return sc.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, SousCategorie item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<SousCategorie> newSousCategories) => updateItems(newSousCategories);
}
