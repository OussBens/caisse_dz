import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/fournisseur.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class FournisseurDataSource extends BaseTableDataSource<Fournisseur> {
  final AppLocalizations l10n;

  FournisseurDataSource({
    required List<Fournisseur> fournisseurs,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: fournisseurs);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Fournisseur fournisseur, String field) {
    switch (field) {
      case 'nom':
        return fournisseur.nom;
      case 'code':
        return fournisseur.code;
      case 'telephone':
        return fournisseur.telephone;
      case 'email':
        return fournisseur.email;
      case 'fax':
        return fournisseur.fax;
      case 'wilaya':
        return fournisseur.wilaya;
      case 'adresse':
        return fournisseur.adresse;
      case 'type':
        return fournisseur.type;
      case 'etat':
        return fournisseur.etat ? l10n.active : l10n.inactive;
      case 'activity':
        return fournisseur.activity;
      case 'observation':
        return fournisseur.observation;

      // Audit
      case 'dateCree':
        return formatDate(fournisseur.dateCree);
      case 'creePar':
        return fournisseur.creePar;
      case 'dateModif':
        return formatDate(fournisseur.dateModif);
      case 'modifPar':
        return fournisseur.modifPar;
      case 'dateAnnul':
        return formatDate(fournisseur.dateAnnul);
      case 'annulPar':
        return fournisseur.annulPar;
      case 'motifAnnul':
        return fournisseur.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Fournisseur item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    return null;
  }

  void update(List<Fournisseur> newFournisseurs) => updateItems(newFournisseurs);
}
