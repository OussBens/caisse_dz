// lib/core/widget/tableau/produit/produit_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/produit.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class ProduitDataSource extends BaseTableDataSource<Produit> {
  final AppLocalizations l10n;

  ProduitDataSource({
    required List<Produit> produits,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: produits);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Produit produit, String field) {
    switch (field) {
      // --- Identification ---
      case 'etat':
        return produit.etat ? l10n.active : l10n.inactive;
      case 'code':
        return produit.code;
      case 'nom':
        return produit.nom;
      case 'marque':
        return produit.marque;

      // --- Texte ---
      case 'description':
        return produit.description ?? '';
      case 'codeBarre':
        return produit.codeBarre ?? '';
      case 'numeroSerie':
        return produit.numeroSerie ?? '';
      case 'fournisseur':
        return produit.fournisseur ?? '';

      // --- Catégorie ---
      case 'categorie':
        return produit.categorie;
      case 'sousCategorie':
        return produit.sousCategorie;
      case 'remise':
        return produit.remise ?? '';

      // --- Bool ---
      case 'service':
        return produit.service ? l10n.yes : l10n.no;
      case 'multicodebar':
        return produit.multicodebar ? l10n.yes : l10n.no;
      case 'margeBool':
        return produit.margeBool ? l10n.yes : l10n.no;
      case 'seuilBool':
        return produit.seuilBool ? l10n.yes : l10n.no;


      // --- Prix ---
      case 'prixAchat':
        return "${produit.prixAchat} ${l10n.currency}";
      case 'prixVente':
        return "${produit.prixVente} ${l10n.currency}";
      case 'margeTaux':
        return produit.margeTaux;
      case 'margeTauxPrct':
        return "${produit.margeTauxPrct}%";
      case 'tva':
        return "${produit.tva}%";

      // --- Stock ---
      case 'quantite':
        return produit.quantite;
      case 'seuilMin':
        return produit.seuilMin;
      case 'seuilMax':
        return produit.seuilMax;
      case 'uniteMesure':
        return produit.uniteMesure;

      // --- Emballage ---
      case 'emballage1':
        return produit.emballage1 ?? '';
      case 'emballage2':
        return produit.emballage2 ?? '';
      case 'emballageP1':
        return produit.emballageP1 ?? '';
      case 'emballageP2':
        return produit.emballageP2 ?? '';

      // --- Dates ---
      case 'dateCree':
        return formatDate(produit.dateCree);
      case 'dateModif':
        return formatDate(produit.dateModif);
      case 'annulerLe':
        return formatDate(produit.annulerLe);
      case 'dateEmpreint':
        return formatDate(produit.dateEmpreint);

      // --- Audit ---
      case 'creeParCode':
        return produit.creeParcode;
      case 'modifPar':
        return produit.modifPar ?? '';
      case 'annulerPar':
        return produit.annulerPar ?? '';
      case 'motifAnnul':
        return produit.motifAnnul ?? '';

      // --- Nouveaux ---
      case 'taille':
        return produit.taille ?? '';
      case 'couleur':
        return produit.couleur ?? '';

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Produit item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'quantite') {
      final bool lowStock = item.quantite < item.seuilMin || item.quantite == 0;

      return Center(
        child: lowStock
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(item.quantite.toString()),
                  const SizedBox(width: 6),
                  StatusBadge(
                    text: "!",
                    color: item.quantite < item.seuilMin
                        ? Colors.red
                        : Colors.deepOrangeAccent,
                  ),
                ],
              )
            : Text(item.quantite.toString()),
      );
    }



    return null;
  }

  void updateProduits(List<Produit> newProduits) => updateItems(newProduits);
}
