import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../data/models/magasin.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class MagasinDataSource extends BaseTableDataSource<Magasin> {
  final AppLocalizations l10n;

  MagasinDataSource({
    required List<Magasin> magasins,
    required super.columnConfig,
    required this.l10n,
    super.utilisateurs = const [],
  }) : super(items: magasins);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Magasin magasin, String field) {
    switch (field) {
      case 'code':
        return magasin.code;
      case 'nom':
        return magasin.nom;
      case 'adresse':
        return magasin.adresse;
      case 'etat':
        return magasin.etat ? l10n.active : l10n.inactive;
      case 'observation':
        return magasin.observation;

      // Audit
      case 'dateCree':
        return formatDate(magasin.dateCree);
      case 'creeParCode':
        return nomUtilisateur(magasin.creeParCode);
      case 'dateModif':
        return formatDate(magasin.dateModif);
      case 'modifParCode':
        return nomUtilisateur(magasin.modifParCode);
      case 'dateAnnul':
        return formatDate(magasin.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(magasin.annulParCode);
      case 'motifAnnul':
        return magasin.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Magasin item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    return null;
  }

  void update(List<Magasin> newMagasins) => updateItems(newMagasins);
}
