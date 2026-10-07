import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/gestion_caisse.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class CaisseGestionDataSource extends BaseTableDataSource<CaisseGestion> {
  final AppLocalizations l10n;

  CaisseGestionDataSource({
    required List<CaisseGestion> caisses,
    required super.columnConfig,
    required this.l10n,
    super.utilisateurs = const [],
  }) : super(items: caisses);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  // Tri sur la valeur brute (DateTime / nombre) et non sur le texte affiché :
  // "jj/mm/aaaa" trié comme du texte classait d'abord par jour, et "1200 DA"
  // par ordre alphabétique.
  @override
  dynamic sortValue(CaisseGestion caisse, String field) {
    switch (field) {
      case 'dateCree':
        return caisse.dateCree;
      case 'dateModif':
        return caisse.dateModif;
      case 'dateAnnul':
        return caisse.dateAnnul;
      default:
        return cellValue(caisse, field);
    }
  }

  @override
  dynamic cellValue(CaisseGestion caisse, String field) {
    switch (field) {
      case 'etat':
        return caisse.etat ? l10n.active : l10n.inactive;
      case 'code':
        return caisse.code;
      case 'nomCaisse':
        return caisse.nomCaisse;
      case 'magasin':
        return caisse.magasinCode;
      case 'type':
        return caisse.typecaisse;
      case 'soldeInitial':
        return caisse.soldeInitial;
      case 'observation':
        return caisse.observation;

      // Audit
      case 'dateCree':
        return formatDate(caisse.dateCree);
      case 'creeParCode':
        return nomUtilisateur(caisse.creeParCode);
      case 'dateModif':
        return formatDate(caisse.dateModif);
      case 'modifParCode':
        return nomUtilisateur(caisse.modifParCode);
      case 'dateAnnul':
        return formatDate(caisse.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(caisse.annulParCode);
      case 'motifAnnul':
        return caisse.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, CaisseGestion item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    if (columnName == 'nomCaisse') {
      return boldCell(item.nomCaisse, align: TextAlign.left);
    }
    if (columnName == 'soldeInitial') {
      return Center(
        child: pilluleCellule("${item.soldeInitial} ${l10n.currency}", Appstyle.violet),
      );
    }
    return null;
  }

  void update(List<CaisseGestion> newCaisses) => updateItems(newCaisses);
}
