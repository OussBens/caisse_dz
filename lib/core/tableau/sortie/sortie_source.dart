// lib/core/widget/tableau/sortie/sortie_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/sortie.dart';
import '../../../../data/models/produit.dart';
import '../../../../data/models/categorie.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class SortieDataSource extends BaseTableDataSource<Sortie> {
  final AppLocalizations l10n;
  final List<Produit> produits;
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  late final ListsConstTranslator _translator = ListsConstTranslator(l10n);

  SortieDataSource({
    required List<Sortie> sorties,
    required super.columnConfig,
    required this.l10n,
    required this.produits,
    required this.categories,
    required this.sousCategories,
    super.utilisateurs = const [],
  }) : super(items: sorties);

  String _nomProduit(String code) =>
      produits.where((p) => p.code == code).firstOrNull?.nom ?? code;

  String? _nomCategorie(String? code) {
    if (code == null) return null;
    return categories.where((c) => c.code == code).firstOrNull?.nom ?? code;
  }

  String? _nomSousCategorie(String? code) {
    if (code == null) return null;
    return sousCategories.where((sc) => sc.code == code).firstOrNull?.nom ?? code;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Sortie sortie, String field) {
    switch (field) {
      case 'code':
        return sortie.code;
      case 'produit':
        return _nomProduit(sortie.produitCode);
      case 'categorie':
        return _nomCategorie(sortie.categorieCode);
      case 'souscategorie':
        return _nomSousCategorie(sortie.sousCategorieCode);
      case 'quantite':
        return sortie.quantite;
      case 'nombre':
        return sortie.nombre;
      case 'prix':
        return "${sortie.prix} ${l10n.currency}";
      case 'montant':
        return "${sortie.montant} ${l10n.currency}";
      case 'type':
        return _translator.translateTypeSortie(sortie.type);
      case 'observation':
        return sortie.observation;
      case 'etat':
        return sortie.etat;

      // ===== Audit =====
      case 'dateCree':
        return formatDate(sortie.dateCree);
      case 'creeParCode':
        return nomUtilisateur(sortie.creeParCode);
      case 'dateModif':
        return formatDate(sortie.dateModif);
      case 'modifParCode':
        return nomUtilisateur(sortie.modifParCode);
      case 'dateAnnul':
        return formatDate(sortie.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(sortie.annulParCode);
      case 'motifAnnul':
        return sortie.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Sortie item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'quantite') {
      return Center(
        child: pilluleCellule("${item.quantite}", Appstyle.violet),
      );
    }

    if (columnName == 'montant') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "${item.montant} ${l10n.currency}",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: AppConst.FontSizeTable,
            ),
          ),
        ),
      );
    }

    return null;
  }

  void update(List<Sortie> newSorties) => updateItems(newSorties);
}
