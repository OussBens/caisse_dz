// lib/core/widget/tableau/mouvement/mouvement_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/mouvement.dart';
import '../../../../data/models/produit.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../../data/models/magasin.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class MouvementDataSource extends BaseTableDataSource<Mouvement> {
  final AppLocalizations l10n;
  final List<Produit> produits;
  final List<Client> clients;
  final List<Fournisseur> fournisseurs;
  // Multi-magasin : nom du magasin de chaque mouvement (une vente répartie
  // sur deux magasins = deux mouvements, chacun avec son magasin).
  final List<Magasin> magasins;

  MouvementDataSource({
    required List<Mouvement> mouvements,
    required super.columnConfig,
    required this.l10n,
    required this.produits,
    required this.clients,
    required this.fournisseurs,
    this.magasins = const [],
    super.utilisateurs = const [],
  }) : super(items: mouvements);

  String _nomProduit(String code) =>
      produits.where((p) => p.code == code).firstOrNull?.nom ?? code;

  String? _nomClient(String? code) {
    if (code == null) return null;
    return clients.where((c) => c.code == code).firstOrNull?.nom ?? code;
  }

  String? _nomFournisseur(String? code) {
    if (code == null) return null;
    return fournisseurs.where((f) => f.code == code).firstOrNull?.nom ?? code;
  }

  String _nomMagasin(String? code) {
    if (code == null) return '-';
    return magasins.where((m) => m.code == code).firstOrNull?.nom ?? code;
  }

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
      case "Sortie":
        return l10n.exit;
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
        return _nomProduit(mouvement.codeProduit);
      case 'quantite':
        return mouvement.quantite;
      case 'prixAchat':
        return mouvement.prixAchat;
      case 'prixVente':
        return mouvement.prixVente;
      case 'client':
        return _nomClient(mouvement.clientCode);
      case 'fournisseur':
        return _nomFournisseur(mouvement.fournisseurCode);
      case 'type':
        return _getTranslatedType(mouvement.type);
      case 'magasin':
        return _nomMagasin(mouvement.magasinCode);
      case 'etat':
        return mouvement.etat ? l10n.active : l10n.inactive;

      // Audit
      case 'dateCree':
        return formatDate(mouvement.dateCree);
      case 'creeParCode':
        return nomUtilisateur(mouvement.creeParCode);
      case 'dateModif':
        return formatDate(mouvement.dateModif);
      case 'modifParCode':
        return nomUtilisateur(mouvement.modifParCode);
      case 'dateAnnul':
        return formatDate(mouvement.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(mouvement.annulParCode);
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

    if (columnName == 'code') {
      return Center(child: pilluleCellule(item.code, Appstyle.violet));
    }

    if (columnName == 'nomProduit') {
      return Center(child: pilluleCellule(_nomProduit(item.codeProduit), Appstyle.indigo));
    }

    if (columnName == 'quantite') {
      return Center(child: pilluleCellule("${item.quantite}", Appstyle.violet));
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
        case "Sortie":
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
