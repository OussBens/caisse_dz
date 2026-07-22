// lib/core/tableau/Pack/pack_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/pack.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class PackDataSource extends BaseTableDataSource<Pack> {
  final AppLocalizations l10n;

  PackDataSource({
    required List<Pack> packs,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: packs);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Pack pack, String field) {
    switch (field) {
      case 'code':
        return pack.code;
      case 'nom':
        return pack.nom;
      case 'observation':
        return pack.observation ?? '';
      case 'etat':
        return pack.etat ? l10n.active : l10n.inactive;
      case 'prixVente':
        return "${pack.prixVente} ${l10n.currency}";
      case 'creeParCode':
        return pack.creeParCode;
      case 'creeLe':
        return formatDate(pack.creeLe);
      case 'modifPar':
        return pack.modifPar ?? '';
      case 'modifLe':
        return formatDate(pack.modifLe);
      case 'annulPar':
        return pack.annulPar ?? '';
      case 'annulLe':
        return formatDate(pack.annulLe);
      case 'motifAnnul':
        return pack.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Pack item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    return null;
  }

  void update(List<Pack> newPacks) => updateItems(newPacks);
}
