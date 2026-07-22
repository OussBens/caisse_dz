// lib/core/widget/tableau/sortie/sortie_source.dart

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/sortie.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class SortieDataSource extends BaseTableDataSource<Sortie> {
  final AppLocalizations l10n;
  late final ListsConstTranslator _translator = ListsConstTranslator(l10n);

  SortieDataSource({
    required List<Sortie> sorties,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: sorties);

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
        return sortie.produit;
      case 'categorie':
        return sortie.categorie;
      case 'souscategorie':
        return sortie.souscategorie;
      case 'quantite':
        return sortie.quantite;
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
      case 'creePar':
        return sortie.creePar;
      case 'dateModif':
        return formatDate(sortie.dateModif);
      case 'modifPar':
        return sortie.modifPar;
      case 'dateAnnul':
        return formatDate(sortie.dateAnnul);
      case 'annulPar':
        return sortie.annulPar;
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
