import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import '../../../l10n/app_localizations.dart';
import '../base_table_data_source.dart';

class HistoriqueDataSource extends BaseTableDataSource<Historique> {
  final AppLocalizations l10n;

  HistoriqueDataSource({
    required List<Historique> historiques,
    required super.columnConfig,
    required this.l10n,
    super.utilisateurs = const [],
  }) : super(items: historiques);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Historique historique, String field) {
    switch (field) {
      case 'code':
        return historique.code;
      case 'type':
        return _getTranslatedOperation(historique.oper, l10n);
      case 'operation sur':
        return _getTranslatedType(historique.type, l10n);
      case 'description':
        return historique.observation;
      case 'creeParCode':
        return nomUtilisateur(historique.creeParCode);
      case 'dateCree':
        return formatDate(historique.dateCree);

      default:
        return '';
    }
  }

  String _getTranslatedOperation(String oper, AppLocalizations l10n) {
    switch (oper) {
      case 'insertion':
        return l10n.insertion;
      case 'modification':
        return l10n.modification;
      case 'suppression':
        return l10n.deletion;
      case 'login':
        return l10n.login;
      case 'logout':
        return l10n.logout;
      default:
        return oper;
    }
  }

  String _getTranslatedType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'produit':
        return l10n.product;
      case 'client':
        return l10n.client;
      case 'fournisseur':
        return l10n.supplier;
      case 'caisse':
        return l10n.caisse;
      case 'panier':
        return l10n.panier;
      case 'versement':
        return l10n.versement;
      case 'transfert':
        return l10n.transfert;
      case 'zakat':
        return l10n.zakat;
      case 'utilisateur':
        return l10n.user;
      case 'role':
        return l10n.role;
      case 'magasin':
        return l10n.store;
      case 'categorie':
        return l10n.category;
      case 'souscategorie':
        return l10n.sousCategorie;
      case 'pack':
        return l10n.pack;
      case 'remise':
        return l10n.discount;
      case 'besoin':
        return l10n.need;
      default:
        return type;
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Historique item) {
    if (columnName != 'type') return null;

    Color badgeColor;
    switch (item.oper) {
      case 'insertion':
        badgeColor = Colors.green;
        break;
      case 'modification':
        badgeColor = Colors.orange;
        break;
      case 'suppression':
        badgeColor = Colors.red;
        break;
      case 'login':
        badgeColor = Colors.blue;
        break;
      case 'logout':
        badgeColor = Colors.grey;
        break;
      default:
        badgeColor = Colors.black26;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          cell.value?.toString() ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: AppConst.FontSizeTable,
          ),
        ),
      ),
    );
  }

  void update(List<Historique> newHistoriques) => updateItems(newHistoriques);
}
