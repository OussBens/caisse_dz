// lib/core/widget/tableau/produit/produit_data_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/produit.dart';
import '../../../../data/models/categorie.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../../data/models/remise.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class ProduitDataSource extends BaseTableDataSource<Produit> {
  final AppLocalizations l10n;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final List<Remise> remises;
  final List<Fournisseur> fournisseurs;

  /// Seuil global de stock bas (Paramètres > Minimum), en l'absence d'un
  /// seuil par produit (retiré du modèle Produit) — voir stock_screen.dart.
  final double seuilMinimum;

  /// Quantité calculée à partir du journal des mouvements (voir
  /// MouvementsServices.totauxParProduit), pour le magasin filtré côté écran
  /// — remplace Produit.quantite (compteur en cache, sujet à dérive) comme
  /// source affichée. Absent d'un code = aucun mouvement enregistré = 0.
  Map<String, double> quantites;

  ProduitDataSource({
    required List<Produit> produits,
    required super.columnConfig,
    required this.l10n,
    required this.categories,
    required this.sousCategories,
    required this.remises,
    required this.fournisseurs,
    this.seuilMinimum = 0,
    this.quantites = const {},
    super.utilisateurs = const [],
  }) : super(items: produits);

  double _quantite(Produit produit) => quantites[produit.code] ?? 0;

  void updateQuantites(Map<String, double> newQuantites) {
    quantites = newQuantites;
    buildDataGridRows();
    notifyListeners();
  }

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
        return _quantite(produit);
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
        return nomUtilisateur(produit.creeParcode);
      case 'modifParCode':
        return nomUtilisateur(produit.modifParCode);
      case 'annulerParCode':
        return nomUtilisateur(produit.annulerParCode);
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

    if (columnName == 'nom') {
      return boldCell(item.nom, align: TextAlign.left);
    }

    if (columnName == 'prixAchat') {
      return Center(
        child: pilluleCellule("${item.prixAchat} ${l10n.currency}", Appstyle.violet),
      );
    }

    if (columnName == 'prixVente') {
      return Center(
        child: pilluleCellule("${item.prixVente} ${l10n.currency}", Appstyle.crevete),
      );
    }

    if (columnName == 'quantite') {
      final double quantite = _quantite(item);
      final bool lowStock = quantite <= seuilMinimum;

      return Center(
        child: lowStock
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(quantite.toString()),
                  const SizedBox(width: 6),
                  const StatusBadge(text: "!", color: Colors.red),
                ],
              )
            : Text(quantite.toString()),
      );
    }



    return null;
  }

  void updateProduits(List<Produit> newProduits) => updateItems(newProduits);
}
