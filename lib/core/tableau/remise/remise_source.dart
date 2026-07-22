// lib/core/widget/tableau/remise/remise_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/remise.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class RemiseDataSource extends BaseTableDataSource<Remise> {
  final AppLocalizations l10n;

  RemiseDataSource({
    required List<Remise> remises,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: remises);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Remise remise, String field) {
    switch (field) {
      case 'code':
        return remise.code;
      case 'nom':
        return remise.nom;
      case 'observation':
        return remise.observation ?? '';
      case 'etat':
        return remise.etat ? l10n.active : l10n.inactive;
      case 'type':
        return remise.type;
      case 'montant':
        return "${remise.montant} ${l10n.currency}";
      case 'tauxType':
        return remise.tauxType;
      case 'taux':
        return remise.taux;
      case 'debut':
        return formatDate(remise.debut);
      case 'fin':
        return formatDate(remise.fin);
      case 'creeParCode':
        return remise.creeParCode;
      case 'creeLe':
        return formatDate(remise.creeLe);
      case 'modifParCode':
        return remise.modifParCode ?? '';
      case 'modifLe':
        return formatDate(remise.modifLe);
      case 'annulPar':
        return remise.annulPar ?? '';
      case 'annulLe':
        return formatDate(remise.annulLe);
      case 'motifAnnul':
        return remise.motifAnnul ?? '';
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Remise item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'taux') {
      final isPourcentage = item.tauxType == "Pourcentage";
      final String suffix = isPourcentage ? l10n.percentage : l10n.currency;

      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              cell.value?.toString() ?? '',
              style: const TextStyle(
                fontSize: AppConst.FontSizeTable,
              ),
            ),
            const SizedBox(width: 6),
            StatusBadge(
              text: suffix,
              color: isPourcentage ? Appstyle.blueC : Appstyle.jaune,
            ),
          ],
        ),
      );
    }

    return null;
  }

  void update(List<Remise> newRemises) => updateItems(newRemises);
}
