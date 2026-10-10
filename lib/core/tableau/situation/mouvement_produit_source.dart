import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_style.dart';
import '../../widget/status_badge.dart';
import '../base_table_data_source.dart';
import '../../utilis/quantite_format.dart';

/// Une ligne du tableau "Situation Mouvement Produit" (Dashboard > Situation) :
/// un mouvement de stock (entrée, sortie, pannier, retour...) enrichi de la
/// quantité en stock juste avant et juste après ce mouvement — ni l'une ni
/// l'autre ne sont stockées sur [Mouvement] (voir mouvement_produit_tab.dart,
/// qui les calcule par somme cumulée chronologique par produit).
class LigneMouvementProduit {
  final int numero;
  final DateTime date;
  final String nomProduit;
  final String motif;
  final double qttInitiale;
  // Signée : positive pour une entrée, négative pour une sortie — affiche
  // directement le sens du mouvement dans la cellule.
  final double qttMouvement;
  final double qttApres;
  final bool etat;
  // Nom du magasin du mouvement (multi-magasin) : une vente répartie sur
  // deux magasins donne deux lignes, une par magasin servi.
  final String magasin;

  const LigneMouvementProduit({
    required this.numero,
    required this.date,
    required this.nomProduit,
    required this.motif,
    required this.qttInitiale,
    required this.qttMouvement,
    required this.qttApres,
    required this.etat,
    this.magasin = '',
  });

  LigneMouvementProduit copyWith({int? numero}) {
    return LigneMouvementProduit(
      numero: numero ?? this.numero,
      date: date,
      nomProduit: nomProduit,
      motif: motif,
      qttInitiale: qttInitiale,
      qttMouvement: qttMouvement,
      qttApres: qttApres,
      etat: etat,
      magasin: magasin,
    );
  }
}

class MouvementProduitDataSource extends BaseTableDataSource<LigneMouvementProduit> {
  final AppLocalizations l10n;

  MouvementProduitDataSource({
    required List<LigneMouvementProduit> lignes,
    required super.columnConfig,
    required this.l10n,
  }) : super(items: lignes);

  String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(LigneMouvementProduit l, String field) {
    switch (field) {
      case 'numero':
        return l.numero;
      case 'date':
        return formatDate(l.date);
      case 'nomProduit':
        return l.nomProduit;
      case 'motif':
        return l.motif;
      case 'magasin':
        return l.magasin;
      case 'qttInitiale':
        return l.qttInitiale;
      case 'qttMouvement':
        return l.qttMouvement;
      case 'qttApres':
        return l.qttApres;
      case 'etat':
        return l.etat ? l10n.active : l10n.inactive;
      default:
        return '';
    }
  }

  @override
  dynamic sortValue(LigneMouvementProduit l, String field) => field == 'date' ? l.date : cellValue(l, field);

  @override
  Widget? buildCustomCell(String columnName, DataGridCell cell, LigneMouvementProduit item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'nomProduit') {
      return boldCell(item.nomProduit, align: TextAlign.left);
    }

    if (columnName == 'qttMouvement') {
      final signe = item.qttMouvement > 0 ? '+' : '';
      final color = item.qttMouvement > 0 ? Appstyle.success : (item.qttMouvement < 0 ? Appstyle.danger : Appstyle.gris);
      return Center(
        child: Text(
          "$signe${QuantiteFormat.format(item.qttMouvement)}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      );
    }

    if (columnName == 'qttInitiale' || columnName == 'qttApres') {
      final value = columnName == 'qttInitiale' ? item.qttInitiale : item.qttApres;
      return Center(child: Text(QuantiteFormat.format(value)));
    }

    return null;
  }

  void updateLignes(List<LigneMouvementProduit> newLignes) => updateItems(newLignes);
}
