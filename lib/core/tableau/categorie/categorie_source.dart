// lib/core/widget/tableau/categorie/categorie_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/categorie.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class CategorieDataSource extends BaseTableDataSource<Categorie> {
  final AppLocalizations l10n;

  CategorieDataSource({
    required List<Categorie> categories,
    required super.columnConfig,
    required this.l10n,
    super.utilisateurs = const [],
  }) : super(items: categories);

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Categorie cat, String field) {
    switch (field) {
      case 'code':
        return cat.code;
      case 'nom':
        return cat.nom;
      case 'observation':
        return cat.observation ?? '';
      case 'etat':
        return cat.etat ? l10n.active : l10n.inactive;
      case 'dateCree':
        return formatDate(cat.dateCree);
      case 'creeParCode':
        return nomUtilisateur(cat.creeParCode);
      case 'dateModif':
        return formatDate(cat.dateModif);
      case 'modifParCode':
        return nomUtilisateur(cat.modifParCode);
      case 'dateAnnul':
        return formatDate(cat.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(cat.annulParCode);
      case 'motifAnnul':
        return cat.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Categorie item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void updateCategories(List<Categorie> newCategories) => updateItems(newCategories);
}
