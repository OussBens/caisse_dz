import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/role.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class RoleDataSource extends BaseTableDataSource<Role> {
  final AppLocalizations l10n;

  RoleDataSource({
    required List<Role> roles,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: roles);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Role role, String field) {
    switch (field) {
      case 'code':
        return role.code;
      case 'rolenom':
        return role.rolenom;
      case 'observation':
        return role.observation;
      case 'etat':
        return role.etat ? l10n.active : l10n.inactive;

      // ===== Audit =====
      case 'dateCree':
        return formatDate(role.dateCree);
      case 'creeParCode':
        return role.creeParCode;
      case 'dateModif':
        return formatDate(role.dateModif);
      case 'modifPar':
        return role.modifPar;
      case 'dateAnnul':
        return formatDate(role.dateAnnul);
      case 'annulPar':
        return role.annulPar;
      case 'motifAnnul':
        return role.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Role item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<Role> newRoles) => updateItems(newRoles);
}
