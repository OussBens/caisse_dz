import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../data/models/transfert_magasin.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/magasin.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class TransfertMagasinDataSource extends BaseTableDataSource<TransfertMagasin> {
  final AppLocalizations l10n;
  final List<Produit> produits;
  final List<Magasin> magasins;

  TransfertMagasinDataSource({
    required List<TransfertMagasin> transferts,
    required super.columnConfig,
    required this.l10n,
    required this.produits,
    required this.magasins,
    super.utilisateurs = const [],
  }) : super(items: transferts);

  String _nomProduit(String code) =>
      produits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  String _nomMagasin(String code) =>
      magasins.firstWhereOrNull((m) => m.code == code)?.nom ?? code;

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(TransfertMagasin transfert, String field) {
    switch (field) {
      case 'code':
        return transfert.code;
      case 'produit':
        return _nomProduit(transfert.produitCode);
      case 'magasinSource':
        return _nomMagasin(transfert.magasinSourceCode);
      case 'magasinDest':
        return _nomMagasin(transfert.magasinDestCode);
      case 'quantite':
        return transfert.quantite;
      case 'nombre':
        return transfert.nombre;
      case 'date':
        return formatDate(transfert.date);
      case 'observation':
        return transfert.observation;
      case 'etat':
        return transfert.etat;

      // ===== Audit =====
      case 'dateCree':
        return formatDate(transfert.dateCree);
      case 'creeParCode':
        return nomUtilisateur(transfert.creeParCode);
      case 'dateModif':
        return formatDate(transfert.dateModif);
      case 'modifParCode':
        return nomUtilisateur(transfert.modifParCode);
      case 'dateAnnul':
        return formatDate(transfert.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(transfert.annulParCode);
      case 'motifAnnul':
        return transfert.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, TransfertMagasin item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'quantite') {
      return Center(
        child: pilluleCellule("${item.quantite}", Appstyle.violet),
      );
    }

    return null;
  }

  void update(List<TransfertMagasin> newTransferts) => updateItems(newTransferts);
}
