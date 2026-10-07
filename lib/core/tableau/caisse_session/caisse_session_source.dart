import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../data/models/caisse_session.dart';
import '../../../data/models/gestion_caisse.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../dialog/produits_liste_dialog.dart';
import '../../utilis/number_format.dart';
import '../base_table_data_source.dart';

class CaisseSessionDataSource extends BaseTableDataSource<CaisseSession> {
  final AppLocalizations l10n;
  final List<CaisseGestion> caisses;

  CaisseSessionDataSource({
    required List<CaisseSession> sessions,
    required super.columnConfig,
    required this.l10n,
    this.caisses = const [],
    super.utilisateurs = const [],
  }) : super(items: sessions);

  String _nomCaisse(String code) =>
      caisses.firstWhereOrNull((c) => c.code == code)?.nomCaisse ?? code;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatMontant(double? montant) => montant == null
      ? '-'
      : "${NumberFormatUtil.formatMontant(montant, decimales: 2)} ${l10n.currency}";

  // Tri sur la valeur brute (DateTime / nombre) et non sur le texte affiché :
  // "jj/mm/aaaa" trié comme du texte classait d'abord par jour, et "1200 DA"
  // par ordre alphabétique.
  @override
  dynamic sortValue(CaisseSession s, String field) {
    switch (field) {
      case 'soldeOuverture':
        return s.soldeOuverture;
      case 'dateOuverture':
        return s.dateOuverture;
      case 'soldeTheorique':
        return s.soldeTheorique;
      case 'soldeReel':
        return s.soldeReel;
      case 'ecart':
        return s.ecart;
      case 'dateCloture':
        return s.dateCloture;
      default:
        return cellValue(s, field);
    }
  }

  @override
  dynamic cellValue(CaisseSession s, String field) {
    switch (field) {
      case 'code':
        return s.code;
      case 'caisseCode':
        return _nomCaisse(s.caisseCode);
      case 'statut':
        return s.statut == CaisseSession.statutOuverte ? l10n.sessionStatutOuverte : l10n.sessionStatutCloturee;
      case 'soldeOuverture':
        return _formatMontant(s.soldeOuverture);
      case 'dateOuverture':
        return _formatDate(s.dateOuverture);
      case 'soldeTheorique':
        return _formatMontant(s.soldeTheorique);
      case 'soldeReel':
        return _formatMontant(s.soldeReel);
      case 'ecart':
        return _formatMontant(s.ecart);
      case 'dateCloture':
        return _formatDate(s.dateCloture);
      case 'creeParCode':
        return nomUtilisateur(s.creeParCode);
      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, CaisseSession item) {
    if (columnName == 'caisseCode') {
      return boldCell(_nomCaisse(item.caisseCode), align: TextAlign.left);
    }
    if (columnName == 'soldeOuverture') {
      return Center(
        child: pilluleCellule(_formatMontant(item.soldeOuverture), Appstyle.violet),
      );
    }
    return null;
  }

  void update(List<CaisseSession> newList) => updateItems(newList);
}
