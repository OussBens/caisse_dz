import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../../../data/models/client.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';

class ClientDataSource extends BaseTableDataSource<Client> {
  final AppLocalizations l10n;

  ClientDataSource({
    required List<Client> clients,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: clients);

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(Client client, String field) {
    switch (field) {
      case 'code':
        return client.code;
      case 'nom':
        return client.nom;
      case 'telephone':
        return client.telephone;
      case 'email':
        return client.email;
      case 'fax':
        return client.fax;
      case 'wilaya':
        return client.wilaya;
      case 'adresse':
        return client.adresse;
      case 'type':
        return client.type;
      case 'activity':
        return client.activity;
      case 'etat':
        return client.etat ? l10n.active : l10n.inactive;
      case 'nif':
        return client.nif;
      case 'nis':
        return client.nis;
      case 'nrc':
        return client.nrc;
      case 'rib':
        return client.rib;
      case 'banque':
        return client.banque;
      case 'dernierAchat':
        return formatDate(client.dernierAchat);
      case 'observation':
        return client.observation;

      // Audit
      case 'dateCree':
        return formatDate(client.dateCree);
      case 'creeParCode':
        return client.creeParCode;
      case 'dateModif':
        return formatDate(client.dateModif);
      case 'modifPar':
        return client.modifPar;
      case 'dateAnnul':
        return formatDate(client.dateAnnul);
      case 'annulPar':
        return client.annulPar;
      case 'motifAnnul':
        return client.motifAnnul;

      default:
        return '';
    }
  }

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, Client item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    return null;
  }

  void update(List<Client> newClients) => updateItems(newClients);
}
