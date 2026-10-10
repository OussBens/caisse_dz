import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/besoinList.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class BesoinListDataSource extends BaseTableDataSource<BesoinList> {
  final AppLocalizations l10n;
  final List<Fournisseur> fournisseurs;

  BesoinListDataSource({
    required List<BesoinList> besoins,
    required super.columnConfig,
    required this.l10n,
    this.fournisseurs = const [],
    super.utilisateurs = const [],
  }) : super(items: besoins);

  String _nomFournisseur(String? code) =>
      fournisseurs.firstWhereOrNull((f) => f.code == code)?.nom ?? code ?? '';

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(BesoinList besoin, String field) {
    switch (field) {
      case 'code':
        return besoin.code;
      case 'numero':
        return besoin.numero;
      case 'date':
        return formatDate(besoin.date);
      case 'montant':
        return besoin.montant;
      case 'nombreArticle':
        return besoin.nombreArticle;
      case 'quantite':
        return besoin.quantite;
      case 'fournisseur':
        return _nomFournisseur(besoin.fournisseurCode);
      case 'etat':
        return besoin.etat ? l10n.actif : l10n.inactif;
      case 'dateCree':
        return formatDate(besoin.dateCree);
      case 'creeParCode':
        return nomUtilisateur(besoin.creeParCode);
      case 'dateModif':
        return formatDate(besoin.dateModif);
      case 'modifParCode':
        return nomUtilisateur(besoin.modifParCode);
      case 'dateAnnul':
        return formatDate(besoin.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(besoin.annulParCode);
      case 'motifAnnul':
        return besoin.motifAnnul;
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, BesoinList item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    if (columnName == 'montant') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Appstyle.info,
            borderRadius: BorderRadius.circular(Appstyle.radiusSM),
          ),
          child: Text(
            item.montant.toString(),
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

  void updateBesoinsList(List<BesoinList> newBesoins) => updateItems(newBesoins);
}
