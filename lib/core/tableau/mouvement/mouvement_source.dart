// lib/core/widget/tableau/mouvement/mouvement_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/mouvement.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class MouvementDataSource extends BaseTableDataSource<Mouvement> {
  final AppLocalizations l10n;

  MouvementDataSource({
    required List<Mouvement> mouvements,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: mouvements);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  String _getTranslatedType(String type) {
    switch (type) {
      case "Vente":
        return l10n.sale;
      case "Achat":
        return l10n.purchase;
      case "Retour":
        return l10n.return_;
      case "Déstockage":
        return l10n.destocking;
      default:
        return type;
    }
  }

  @override
  dynamic cellValue(Mouvement mouvement, String field) {
    switch (field) {
      case 'id':
        return mouvement.id;
      case 'code':
        return mouvement.code;
      case 'date':
        return formatDate(mouvement.date);
      case 'nomProduit':
        return mouvement.nomProduit;
      case 'quantite':
        return mouvement.quantite;
      case 'prixAchat':
        return mouvement.prixAchat;
      case 'prixVente':
        return mouvement.prixVente;
      case 'client':
        return mouvement.client;
      case 'fournisseur':
        return mouvement.fournisseur;
      case 'type':
        return _getTranslatedType(mouvement.type);
      case 'etat':
        return mouvement.etat ? l10n.active : l10n.inactive;

      // Audit
      case 'dateCree':
        return formatDate(mouvement.dateCree);
      case 'creeParCode':
        return mouvement.creeParCode;
      case 'dateModif':
        return formatDate(mouvement.dateModif);
      case 'modifPar':
        return mouvement.modifPar;
      case 'dateAnnul':
        return formatDate(mouvement.dateAnnul);
      case 'annulPar':
        return mouvement.annulPar;
      case 'motifAnnul':
        return mouvement.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Mouvement item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'type') {
      final type = item.type ?? '';
      Color color;
      IconData icon;

      switch (type) {
        case "Vente":
          color = Colors.green;
          icon = Icons.shopping_cart;
          break;
        case "Achat":
          color = Colors.blue;
          icon = Icons.shopping_bag;
          break;
        case "Retour":
          color = Colors.orange;
          icon = Icons.undo;
          break;
        case "Déstockage":
          color = Colors.red;
          icon = Icons.remove_circle;
          break;
        default:
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
                _getTranslatedType(type),
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

  void update(List<Mouvement> newMouvements) => updateItems(newMouvements);
}
