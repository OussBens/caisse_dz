import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/client.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../../data/models/produit.dart';
import '../../../../data/models/retour.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class RetourDataSource extends BaseTableDataSource<Retour> {
  final AppLocalizations l10n;
  final List<Produit> produits;
  final List<Client> clients;
  final List<Fournisseur> fournisseurs;

  RetourDataSource({
    required List<Retour> retours,
    required super.columnConfig,
    required this.l10n,
    this.produits = const [],
    this.clients = const [],
    this.fournisseurs = const [],
    super.utilisateurs = const [],
  }) : super(items: retours);

  String _nomProduit(String code) =>
      produits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  String? _nomClient(String? code) {
    if (code == null) return null;
    return clients.firstWhereOrNull((c) => c.code == code)?.nom ?? code;
  }

  String? _nomFournisseur(String? code) {
    if (code == null) return null;
    return fournisseurs.firstWhereOrNull((f) => f.code == code)?.nom ?? code;
  }

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
        return _nomProduit(retour.codeProduit);
      case 'quantite':
        return retour.quantite;
      case 'nombre':
        return retour.nombre;

      // 💰 Prix
      case 'prixAchat':
        return "${retour.prixAchat} ${l10n.currency}";
      case 'prixVente':
        return "${retour.prixVente} ${l10n.currency}";
      case 'montant':
        return "${retour.quantite * (retour.prixVente ?? 0)} ${l10n.currency}";

      // 👤 Type / Client / Fournisseur
      case 'type':
        return retour.type == "Client" ? l10n.clientType : l10n.supplierType;
      case 'client':
        return _nomClient(retour.client_code);
      case 'fournisseur':
        return _nomFournisseur(retour.fournisseur_code);

      case 'etat':
        return retour.etat ? l10n.active : l10n.inactive;

      case 'observation':
        return retour.observation;

      // 🕒 Audit
      case 'date':
        return _formatDate(retour.date);
      case 'dateCree':
        return _formatDate(retour.dateCree);
      case 'creeParCode':
        return nomUtilisateur(retour.creeParCode);
      case 'dateModif':
        return _formatDate(retour.dateModif);
      case 'modifParCode':
        return nomUtilisateur(retour.modifParCode);
      case 'dateAnnul':
        return _formatDate(retour.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(retour.annulParCode);
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

    if (columnName == 'montant') {
      return Center(
        child: pilluleCellule(
          "${item.quantite * (item.prixVente ?? 0)} ${l10n.currency}",
          Appstyle.crevete,
        ),
      );
    }

    if (columnName == 'quantite') {
      return Center(
        child: pilluleCellule("${item.quantite}", Appstyle.violet),
      );
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
