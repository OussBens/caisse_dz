import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/fournisseur.dart';
import '../../../../data/models/smart_scan.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class SmartScanDataSource extends BaseTableDataSource<SmartScan> {
  final AppLocalizations l10n;
  final List<Fournisseur> fournisseurs;
  Map<String, double> verseParSmartScan;
  Map<String, int> nbrVersementParSmartScan;

  SmartScanDataSource({
    required List<SmartScan> scans,
    required super.columnConfig,
    required this.l10n,
    this.fournisseurs = const [],
    this.verseParSmartScan = const {},
    this.nbrVersementParSmartScan = const {},
    super.utilisateurs = const [],
  }) : super(items: scans);

  double _verse(SmartScan s) => verseParSmartScan[s.code] ?? 0;
  double _reste(SmartScan s) => s.montant - _verse(s);

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
  dynamic cellValue(SmartScan scan, String field) {
    switch (field) {
      case 'code':
        return scan.code;
      case 'date':
        return formatDate(scan.date);
      case 'montant':
        return "${scan.montant} ${l10n.currency}";
      case 'verse':
        return _verse(scan);
      case 'reste':
        return _reste(scan);
      case 'nbrVersement':
        return nbrVersementParSmartScan[scan.code] ?? 0;
      case 'nbrProduit':
        return scan.nbrProduit;
      case 'fournisseur':
        return _nomFournisseur(scan.fournisseurCode);
      case 'etat':
        return scan.etat ? l10n.active : l10n.inactive;
      case 'observation':
        return scan.observation;

      /// Audit
      case 'dateCree':
        return formatDate(scan.dateCree);
      case 'creeParCode':
        return nomUtilisateur(scan.creeParCode);
      case 'dateModif':
        return formatDate(scan.dateModif);
      case 'modifParCode':
        return nomUtilisateur(scan.modifParCode);
      case 'dateAnnul':
        return formatDate(scan.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(scan.annulParCode);
      case 'motifAnnul':
        return scan.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, SmartScan item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'code') {
      return Center(child: pilluleCellule(item.code, Appstyle.violet));
    }

    if (columnName == 'reste') {
      final double resteValue = _reste(item);
      return Center(
        child: Text(
          "$resteValue ${l10n.currency}",
          style: TextStyle(
            fontSize: AppConst.FontSizeTable,
            color: resteValue > 0 ? Appstyle.danger : Colors.black,
            fontWeight: resteValue > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      );
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

  void update(List<SmartScan> newScans) => updateItems(newScans);

  void updateVerseInfo(
    Map<String, double> newVerseParSmartScan,
    Map<String, int> newNbrVersementParSmartScan,
  ) {
    verseParSmartScan = newVerseParSmartScan;
    nbrVersementParSmartScan = newNbrVersementParSmartScan;
    buildDataGridRows();
    notifyListeners();
  }
}
