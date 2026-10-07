import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../base_table_data_source.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Une ligne du tableau "Mouvement Caisse" : un versement (entrée ou sortie
/// de caisse) rattaché à une opération (pannier, retour client/fournisseur
/// ou smart scan), numéroté et enrichi des noms client/fournisseur.
class LigneMouvementCaisse {
  final int numero;
  final DateTime date;
  final String codeVersement;
  final String type;
  final String codeOperation;
  final String nomClient;
  final String nomFournisseur;
  final double montantEntree;
  final double montantSortie;

  const LigneMouvementCaisse({
    required this.numero,
    required this.date,
    required this.codeVersement,
    required this.type,
    required this.codeOperation,
    required this.nomClient,
    required this.nomFournisseur,
    required this.montantEntree,
    required this.montantSortie,
  });

  LigneMouvementCaisse copyWith({int? numero}) {
    return LigneMouvementCaisse(
      numero: numero ?? this.numero,
      date: date,
      codeVersement: codeVersement,
      type: type,
      codeOperation: codeOperation,
      nomClient: nomClient,
      nomFournisseur: nomFournisseur,
      montantEntree: montantEntree,
      montantSortie: montantSortie,
    );
  }
}

class MouvementCaisseDataSource extends BaseTableDataSource<LigneMouvementCaisse> {
  final AppLocalizations l10n;

  MouvementCaisseDataSource({
    required List<LigneMouvementCaisse> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  @override
  dynamic cellValue(LigneMouvementCaisse l, String field) {
    switch (field) {
      case 'numero':
        return l.numero;
      case 'date':
        return formatDate(l.date);
      case 'codeVersement':
        return l.codeVersement;
      case 'type':
        return l.type;
      case 'codeOperation':
        return l.codeOperation;
      case 'nomClient':
        return l.nomClient;
      case 'nomFournisseur':
        return l.nomFournisseur;
      case 'montantEntree':
        return l.montantEntree;
      case 'montantSortie':
        return l.montantSortie;
      default:
        return '';
    }
  }

  // Montants : déjà des double bruts dans cellValue. Date : triée sur le
  // DateTime (le texte "jj/mm/aaaa" se triait d'abord par jour).
  @override
  dynamic sortValue(LigneMouvementCaisse l, String field) =>
      field == 'date' ? l.date : cellValue(l, field);

  String _montant(double v) => v > 0 ? "${NumberFormatUtil.formatMontant(v, decimales: 2)} ${l10n.currency}" : '-';

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneMouvementCaisse item) {
    if (columnName == 'montantEntree') {
      return Center(
        child: Text(
          _montant(item.montantEntree),
          style: item.montantEntree > 0
              ? const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
              : null,
        ),
      );
    }

    if (columnName == 'montantSortie') {
      return Center(
        child: Text(
          _montant(item.montantSortie),
          style: item.montantSortie > 0
              ? const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)
              : null,
        ),
      );
    }

    return null;
  }

  void updateLignes(List<LigneMouvementCaisse> newLignes) => updateItems(newLignes);
}