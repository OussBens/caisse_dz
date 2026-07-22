import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/retour.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class RetourDataSource extends BaseTableDataSource<Retour> {
  final AppLocalizations l10n;

  RetourDataSource({
    required List<Retour> retours,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: retours);

  String _formatDate(DateTime? d) {
    if (d == null) return "";
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  @override
  dynamic cellValue(Retour retour, String field) {
    switch (field) {
      case 'code':
        return retour.code;
      case 'nomProduit':
        return retour.nomProduit;
      case 'quantite':
        return retour.quantite;

      // 💰 Prix
      case 'prixAchat':
        return "${retour.prixAchat} ${l10n.currency}";
      case 'prixVente':
        return "${retour.prixVente} ${l10n.currency}";

      // 👤 Type / Client / Fournisseur
      case 'type':
        return retour.type == "Client" ? l10n.clientType : l10n.supplierType;
      case 'client':
        return retour.client;
      case 'fournisseur':
        return retour.fournisseur;

      case 'etat':
        return retour.etat ? l10n.active : l10n.inactive;

      case 'observation':
        return retour.observation;

      // 🕒 Audit
      case 'date':
        return _formatDate(retour.date);
      case 'dateCree':
        return _formatDate(retour.dateCree);
      case 'creePar':
        return retour.creePar;
      case 'dateModif':
        return _formatDate(retour.dateModif);
      case 'modifPar':
        return retour.modifPar;
      case 'dateAnnul':
        return _formatDate(retour.dateAnnul);
      case 'annulPar':
        return retour.annulPar;
      case 'motifAnnul':
        return retour.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Retour item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'type') {
      final type = item.type;
      final String translatedType = type == "Client" ? l10n.clientType : l10n.supplierType;

      Color color;
      IconData icon;

      if (type == "Client") {
        color = Colors.blue;
        icon = Icons.person;
      } else if (type == "Fournisseur") {
        color = Colors.orange;
        icon = Icons.store;
      } else {
        color = Colors.grey;
        icon = Icons.help_outline;
      }

      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 5),
              Text(
                translatedType,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return null;
  }

  void update(List<Retour> newRetours) => updateItems(newRetours);
}
