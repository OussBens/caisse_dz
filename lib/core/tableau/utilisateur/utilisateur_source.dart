import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class UtilisateurDataSource extends BaseTableDataSource<Utilisateur> {
  final AppLocalizations l10n;

  UtilisateurDataSource({
    required List<Utilisateur> utilisateurs,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: utilisateurs);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Utilisateur user, String field) {
    switch (field) {
      case 'code':
        return user.code;
      case 'username':
        return user.username;
      case 'telephone':
        return user.telephone;
      case 'role':
        return user.role;
      case 'credit':
        return "${user.credit} ${l10n.currency}";
      case 'dernierAcces':
        return formatDate(user.dernierAcces);
      case 'etat':
        return user.etat ? l10n.active : l10n.inactive;
      // Audit
      case 'dateCree':
        return formatDate(user.dateCree);
      case 'creeParCode':
        return user.creeParCode;
      case 'dateModif':
        return formatDate(user.dateModif);
      case 'modifParCode':
        return user.modifParCode;
      case 'dateAnnul':
        return formatDate(user.dateAnnul);
      case 'annulPar':
        return user.annulPar;
      case 'motifAnnul':
        return user.motifAnnul;
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Utilisateur item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<Utilisateur> newUtilisateurs) => updateItems(newUtilisateurs);
}
