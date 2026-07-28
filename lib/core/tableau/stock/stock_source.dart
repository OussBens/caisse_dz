// lib/core/widget/tableau/produit/produit_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/produit.dart';
import '../../../../data/models/categorie.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../../data/models/remise.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class ProduitDataSource extends BaseTableDataSource<Produit> {
  final AppLocalizations l10n;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final List<Remise> remises;
  final List<Fournisseur> fournisseurs;

  ProduitDataSource({
    required List<Produit> produits,
    required super.columnConfig,
    required this.l10n,
    required this.categories,
    required this.sousCategories,
    required this.remises,
    required this.fournisseurs,
  }) : super(items: produits);

  String _nomCategorie(int? id) =>
      categories.where((c) => c.id == id).firstOrNull?.nom ?? '';

  String _nomSousCategorie(int? id) =>
      sousCategories.where((sc) => sc.id == id).firstOrNull?.nom ?? '';

  String _nomRemise(int? id) =>
      remises.where((r) => r.id == id).firstOrNull?.nom ?? '';

  String _nomFournisseur(String? code) =>
      fournisseurs.where((f) => f.code == code).firstOrNull?.nom ?? '';

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
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
        return _nomFournisseur(produit.fournisseurCode);

      // --- Catégorie ---
      case 'categorie':
        return _nomCategorie(produit.categorieId);
      case 'sousCategorie':
        return _nomSousCategorie(produit.sousCategorieId);
      case 'remise':
        return _nomRemise(produit.remiseId);

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
        return "${produit.prixAchat.toStringAsFixed(2)} ${l10n.currency}";
      case 'prixVente':
        return "${produit.prixVente.toStringAsFixed(2)} ${l10n.currency}";
      case 'margeTaux':
        return produit.margeTaux.toStringAsFixed(2);
      case 'margeTauxPrct':
        return "${produit.margeTauxPrct?.toStringAsFixed(2) ?? '0.00'}%";
      case 'tva':
        return "${produit.tva.toStringAsFixed(2)}%";

      // --- Stock ---
      case 'quantite':
        return produit.quantite.toStringAsFixed(2);
      case 'seuilMin':
        return produit.seuilMin.toStringAsFixed(2);
      case 'seuilMax':
        return produit.seuilMax.toStringAsFixed(2);
      case 'uniteMesure':
        return produit.uniteMesure;

      // --- Emballage ---
      case 'emballage1':
        return produit.emballage1?.toStringAsFixed(2) ?? '';
      case 'emballage2':
        return produit.emballage2?.toStringAsFixed(2) ?? '';

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
      case 'modifParCode':
        return produit.modifParCode ?? '';
      case 'annulerParCode':
        return produit.annulerParCode ?? '';
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
