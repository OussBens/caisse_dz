import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Une ligne du tableau "Situation inventaire" : valorisation du stock d'un
/// produit (quantité en stock, valeur d'achat, valeur de vente potentielle).
class LigneInventaire {
  final String codeProduit;
  final String nomProduit;
  final String nomCategorie;
  final double quantite;
  final double prixAchat;
  final double prixVente;
  final double prixMoyenAchat;
  final double prixMoyenVente;

  const LigneInventaire({
    required this.codeProduit,
    required this.nomProduit,
    required this.nomCategorie,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
    this.prixMoyenAchat = 0,
    this.prixMoyenVente = 0,
  });

  double get valeurAchat => quantite * prixAchat;
  double get valeurVente => quantite * prixVente;
  double get margePotentielle => valeurVente - valeurAchat;
}

class InventaireDataSource extends BaseTableDataSource<LigneInventaire> {
  final AppLocalizations l10n;

  InventaireDataSource({
    required List<LigneInventaire> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  @override
  dynamic cellValue(LigneInventaire l, String field) {
    switch (field) {
      case 'codeProduit':
        return l.codeProduit;
      case 'nomProduit':
        return l.nomProduit;
      case 'nomCategorie':
        return l.nomCategorie;
      case 'quantite':
        return l.quantite;
      case 'prixAchat':
        return l.prixAchat;
      case 'valeurAchat':
        return l.valeurAchat;
      case 'prixVente':
        return l.prixVente;
      case 'valeurVente':
        return l.valeurVente;
      case 'prixMoyenAchat':
        return l.prixMoyenAchat;
      case 'prixMoyenVente':
        return l.prixMoyenVente;
      case 'margePotentielle':
        return l.margePotentielle;
      case 'statut':
        return l.quantite > 0 ? l10n.available : l10n.outOfStock;
      default:
        return '';
    }
  }

  String _montant(double v) => "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}";

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneInventaire item) {
    if (columnName == 'statut') {
      final enStock = item.quantite > 0;
      return Center(
        child: StatusBadge(
          text: enStock ? l10n.available : l10n.outOfStock,
          color: enStock ? Colors.green : Colors.red,
        ),
      );
    }

    if (columnName == 'prixAchat' ||
        columnName == 'valeurAchat' ||
        columnName == 'prixVente' ||
        columnName == 'valeurVente' ||
        columnName == 'prixMoyenAchat' ||
        columnName == 'prixMoyenVente') {
      final value = columnName == 'prixAchat'
          ? item.prixAchat
          : columnName == 'valeurAchat'
              ? item.valeurAchat
              : columnName == 'prixVente'
                  ? item.prixVente
                  : columnName == 'valeurVente'
                      ? item.valeurVente
                      : columnName == 'prixMoyenAchat'
                          ? item.prixMoyenAchat
                          : item.prixMoyenVente;
      return Center(child: Text(_montant(value)));
    }

    if (columnName == 'margePotentielle') {
      return Center(
        child: Text(
          _montant(item.margePotentielle),
          style: TextStyle(
            color: item.margePotentielle >= 0 ? Colors.green.shade700 : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneInventaire> newLignes) => updateItems(newLignes);
}
