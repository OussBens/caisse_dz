import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/verssement.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class VerssementDataSource extends BaseTableDataSource<Verssement> {
  final AppLocalizations l10n;

  VerssementDataSource({
    required List<Verssement> verssements,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: verssements);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  String _getTranslatedSense(String sense) {
    if (sense.toLowerCase() == 'entrant') {
      return l10n.incoming;
    } else if (sense.toLowerCase() == 'sortant') {
      return l10n.outgoing;
    }
    return sense;
  }

  @override
  dynamic cellValue(Verssement v, String field) {
    switch (field) {
      case 'code':
        return v.code;
      case 'date':
        return formatDate(v.date);
      case 'sense':
        return _getTranslatedSense(v.sense);
      case 'typebeneficiare':
        return v.typebeneficiare;
      case 'beneficiare':
        return v.beneficiare;
      case 'montant':
        return "${v.montant} ${l10n.currency}";
      case 'caisse':
        return v.caisse;
      case 'mode_paiement':
        return v.mode_paiement;
      case 'type':
        return v.type;
      case 'etat':
        return v.etat ? l10n.validated : l10n.cancelled;

      // Audit
      case 'dateCree':
        return formatDate(v.dateCree);
      case 'creeParCode':
        return v.creeParCode;
      case 'dateModif':
        return formatDate(v.dateModif);
      case 'modifParCode':
        return v.modifParCode;
      case 'dateAnnul':
        return formatDate(v.dateAnnul);
      case 'annulPar':
        return v.annulPar;
      case 'motifAnnul':
        return v.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Verssement item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'sense') {
      final String sense = item.sense;
      final String translatedSense = _getTranslatedSense(sense);

      Color color;
      if (sense.toLowerCase() == 'entrant') {
        color = Colors.green.shade300;
      } else if (sense.toLowerCase() == 'sortant') {
        color = Colors.red.shade300;
      } else {
        color = Colors.grey.shade300;
      }

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            translatedSense,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppConst.FontSizeTable - 1,
            ),
          ),
        ),
      );
    }

    return null;
  }

  void update(List<Verssement> newVerssements) => updateItems(newVerssements);
}
