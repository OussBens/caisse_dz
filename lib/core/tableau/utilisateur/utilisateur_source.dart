import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/gestion_caisse.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class UtilisateurDataSource extends BaseTableDataSource<Utilisateur> {
  final AppLocalizations l10n;
  final List<CaisseGestion> caisses;

  UtilisateurDataSource({
    required List<Utilisateur> utilisateurs,
    required super.columnConfig,
    required this.l10n,
    this.caisses = const [],
    // La table affiche déjà tous les utilisateurs : on réutilise la même
    // liste pour résoudre les codes créé/modifié/annulé par en nom.
  }) : super(items: utilisateurs, utilisateurs: utilisateurs);

  /// Nom de la caisse attachée à l'utilisateur (verrouille l'écran caisse
  /// pour tout rôle autre que Admin, voir utilisateur.caisse_code) — vide
  /// si l'utilisateur n'est verrouillé sur aucune caisse.
  String _nomCaisse(String? code) {
    if (code == null) return '';
    return caisses.where((c) => c.code == code).firstOrNull?.nomCaisse ?? code;
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
  dynamic cellValue(Utilisateur user, String field) {
    switch (field) {
      case 'code':
        return user.code;
      case 'username':
        return user.username;
      case 'telephone':
        return user.telephone;
      case 'role':
        return user.role;
      case 'credit':
        return "${user.credit} ${l10n.currency}";
      case 'caisse':
        return _nomCaisse(user.caisseCode);
      case 'dernierAcces':
        return formatDate(user.dernierAcces);
      case 'etat':
        return user.etat ? l10n.active : l10n.inactive;
      // Audit
      case 'dateCree':
        return formatDate(user.dateCree);
      case 'creeParCode':
        return nomUtilisateur(user.creeParCode);
      case 'dateModif':
        return formatDate(user.dateModif);
      case 'modifParCode':
        return nomUtilisateur(user.modifParCode);
      case 'dateAnnul':
        return formatDate(user.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(user.annulParCode);
      case 'motifAnnul':
        return user.motifAnnul;
      default:
        return '';
    }
  }

  @override
  dynamic sortValue(Utilisateur user, String field) {
    switch (field) {
      case 'credit':
        return user.credit;
      default:
        return cellValue(user, field);
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Utilisateur item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }
    if (columnName == 'username') {
      return boldCell(item.username);
    }
    return null;
  }

  void update(List<Utilisateur> newUtilisateurs) => updateItems(newUtilisateurs);
}
