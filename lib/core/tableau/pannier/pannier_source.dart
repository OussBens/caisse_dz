import 'dart:collection';
// lib/core/widget/tableau/pannier/pannier_data_source.dart

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/pannier.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/status_badge.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Source de données du tableau Pannier.
///
/// Contrairement aux autres tableaux (voir [BaseTableDataSource]), celui-ci
/// N'implémente PAS sa propre pagination manuelle : `rows` expose
/// l'intégralité de [items] à Syncfusion, pour que son filtre/tri intégré
/// (icône entonnoir, `allowFiltering`) opère sur tout le jeu de données —
/// pas seulement une page — tout en gardant la même UI de recherche que
/// les autres tableaux. La pagination visible à l'écran est déléguée à
/// [SfDataPager] (voir tableau_pannier.dart), qui sait nativement paginer
/// le résultat déjà filtré/trié par Syncfusion (`effectiveRows`), chose que
/// notre `PaginationBar` maison ne peut pas faire (elle ne voit jamais que
/// `items`, avant filtrage).
///
/// Essai ciblé sur ce tableau avant généralisation aux autres — voir la
/// discussion sur le filtre par page dans BaseTableDataSource.
class PannierDataSource extends DataGridSource {
  List<Pannier> items;
  final Map<String, Map<String, dynamic>> columnConfig;
  final AppLocalizations l10n;
  final List<Client> clients;
  Map<String, double> verseParPannier;
  Map<String, int> nbrVersementParPannier;
  List<Utilisateur> utilisateurs;

  final Map<int, bool> selectedMap = {}; // clé = index dans `items`
  final List<DataGridRow> _rows = [];

  /// Appelé au double-clic sur la colonne 'code' d'une ligne (voir
  /// [buildCustomCell]). Avec le filtre/tri Syncfusion natif, l'index visuel
  /// d'une ligne ne correspond plus à un index direct dans [items] (pas
  /// d'API publique pour lire la page actuellement affichée depuis
  /// l'extérieur) — on capture donc l'item directement par fermeture au
  /// moment du rendu de la cellule, ce qui reste correct quel que soit le
  /// filtre/tri/page en cours.
  void Function(Pannier item)? onRowDoubleTap;

  PannierDataSource({
    required this.items,
    required this.columnConfig,
    required this.l10n,
    required this.clients,
    required this.verseParPannier,
    required this.nbrVersementParPannier,
    this.utilisateurs = const [],
    this.onRowDoubleTap,
  }) {
    buildDataGridRows();
  }

  double _verse(Pannier p) => verseParPannier[p.code] ?? 0;
  double _reste(Pannier p) => p.montant - _verse(p);

  String nomClient(String? code) =>
      clients.firstWhereOrNull((c) => c.code == code)?.nom ?? code ?? '';

  /// Résout un code utilisateur (creeParCode/modifParCode/annulParCode) en
  /// nom d'utilisateur affichable — retombe sur le code tel quel si
  /// introuvable, comme BaseTableDataSource.nomUtilisateur.
  String? nomUtilisateur(String? code) {
    if (code == null) return null;
    return utilisateurs.firstWhereOrNull((u) => u.code == code)?.username ?? code;
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';

    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  dynamic cellValue(Pannier p, String field) {
    switch (field) {
      case 'code':
        return p.code;
      case 'date':
        return formatDate(p.date);
      case 'nombreArticle':
        return p.nombreArticle ?? 0;
      case 'quantiteProduit':
        return p.quantiteProduit ?? 0;
      case 'montant':
        return p.montant;
      case 'verse':
        return _verse(p);
      case 'reste':
        return _reste(p);
      case 'nbrVersement':
        return nbrVersementParPannier[p.code] ?? 0;
      case 'client':
        return nomClient(p.client_code);
      case 'modePaiement':
        return p.modePaiement ?? '';
      case 'montantAchat':
        return p.montantAchat;
      case 'marge':
        return p.marge;

      case 'caissier':
        return nomUtilisateur(p.caissier_code);
      case 'etat':
        return p.etat ? l10n.active : l10n.inactive;
      case 'observation':
        return p.observation ?? '';
      case 'typepannier':
        return p.typepannier ?? '';
      case 'dateCree':
        return formatDate(p.dateCree);
      case 'creeParCode':
        return nomUtilisateur(p.caissier_code);
      case 'dateModif':
        return formatDate(p.dateModif);
      case 'modifParCode':
        return nomUtilisateur(p.modifParCode) ?? '';
      case 'dateAnnul':
        return formatDate(p.dateAnnul);
      case 'annulParCode':
        return nomUtilisateur(p.annulParCode) ?? '';
      case 'motifAnnul':
        return p.motifAnnul ?? '';
      default:
        return '';
    }
  }

  Widget? buildCustomCell(String columnName, DataGridCell cell, Pannier item) {
    if (columnName == 'etat') {
      return Center(child: EtatBadge(isActive: item.etat));
    }

    if (columnName == 'code') {
      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
        child: Text(
          item.code,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: AppConst.FontSizeTable, fontWeight: FontWeight.bold),
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

    if (columnName == 'reste') {
      final double resteValue = _reste(item);

      return Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(8),
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

    if (columnName == 'verse') {
      return Center(child: Text("${_verse(item)} ${l10n.currency}"));
    }

    if (columnName == 'montantAchat') {
      return Center(child: Text("${item.montantAchat} ${l10n.currency}"));
    }

    if (columnName == 'marge') {
      return Center(child: Text("${item.marge} ${l10n.currency}"));
    }

    return null;
  }

  // ⚠️ Mute `_rows` EN PLACE (clear + addAll) plutôt que de le réassigner —
  // voir le commentaire équivalent dans BaseTableDataSource.buildDataGridRows
  // pour le détail : Syncfusion capture la référence de `rows` dans son
  // cache interne au montage et ne la re-synchronise pas sur un simple
  // `notifyListeners()`, d'où un RangeError -1 dans `buildRow` si `_rows`
  // change d'identité à chaque tri.
  void buildDataGridRows() {
    final newRows = List.generate(items.length, (index) {
      final item = items[index];
      final cells = <DataGridCell>[
        DataGridCell<String>(columnName: 'settings', value: ''),
        DataGridCell<bool>(columnName: 'select', value: selectedMap[index] ?? false),
      ];

      columnConfig.forEach((key, config) {
        if (config['visible'] == true && key != 'select') {
          final field = config['field'];
          cells.add(DataGridCell(columnName: key, value: cellValue(item, field)));
        }
      });

      return DataGridRow(cells: cells);
    });

    _rows
      ..clear()
      ..addAll(newRows);
    _indexParLigne
      ..clear()
      ..addAll({for (int i = 0; i < newRows.length; i++) newRows[i]: i});
  }

  // Ligne de grille -> index dans [items] (identité), pour [compare].
  final Map<DataGridRow, int> _indexParLigne = HashMap<DataGridRow, int>.identity();

  /// Syncfusion re-trie lui-même les lignes sur la valeur AFFICHÉE des
  /// cellules (dates "jj/mm/aaaa" triées comme du texte) : on compare sur
  /// [sortValue] (même correctif que BaseTableDataSource.compare).
  @override
  int compare(DataGridRow? a, DataGridRow? b, SortColumnDetails sortColumn) {
    final field = columnConfig[sortColumn.name]?['field'] as String?;
    final ia = a == null ? null : _indexParLigne[a];
    final ib = b == null ? null : _indexParLigne[b];
    if (field == null || ia == null || ib == null || ia >= items.length || ib >= items.length) {
      return super.compare(a, b, sortColumn);
    }
    final cmp = _compareCellValues(sortValue(items[ia], field), sortValue(items[ib], field));
    return sortColumn.sortDirection == DataGridSortDirection.ascending ? cmp : -cmp;
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);

    // Filet de sécurité contre une DataGridRow d'une génération précédente
    // encore référencée par Syncfusion — voir BaseTableDataSource.buildRow.
    if (index == -1 || index >= items.length) {
      return DataGridRowAdapter(
        cells: row.getCells().map<Widget>((cell) {
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(8),
            child: Text(
              cell.value?.toString() ?? '',
              style: const TextStyle(fontSize: AppConst.FontSizeTable),
            ),
          );
        }).toList(),
      );
    }

    final item = items[index];

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((cell) {
        if (cell.columnName == 'select') {
          return Center(
            child: Checkbox(
              value: selectedMap[index] ?? false,
              onChanged: (value) {
                selectedMap[index] = value!;
                notifyListeners();
              },
            ),
          );
        }

        final custom = buildCustomCell(cell.columnName, cell, item);
        final content = custom ??
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: Text(
                cell.value?.toString() ?? '',
                style: const TextStyle(fontSize: AppConst.FontSizeTable),
              ),
            );

        if (cell.columnName == 'settings') return content;

        // Clic n'importe où sur la ligne : sélectionne/désélectionne (comme
        // la case à cocher). Double-clic : ouvre le détail — voir
        // BaseTableDataSource.buildRow pour la même logique et le
        // commentaire sur le délai de ~300ms induit par la cohabitation
        // onTap/onDoubleTap sur un même GestureDetector.
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            selectedMap[index] = !(selectedMap[index] ?? false);
            notifyListeners();
          },
          onDoubleTap: onRowDoubleTap == null ? null : () => onRowDoubleTap!(item),
          child: content,
        );
      }).toList(),
    );
  }

  /// Valeur utilisée pour TRIER [field] : les dates sur le DateTime (le texte
  /// affiché "jj/mm/aaaa" se triait par jour), le reste comme [cellValue]
  /// (montant/verse/reste/montantAchat/marge y sont déjà des double bruts).
  dynamic sortValue(Pannier item, String field) {
    switch (field) {
      case 'date':
        return item.date;
      case 'dateCree':
        return item.dateCree;
      case 'dateModif':
        return item.dateModif;
      case 'dateAnnul':
        return item.dateAnnul;
      default:
        return cellValue(item, field);
    }
  }

  /// Trie l'intégralité de [items] (même principe que
  /// BaseTableDataSource._applySort) selon la colonne d'en-tête cliquée.
  @override
  Future<void> sort() async {
    if (sortedColumns.isNotEmpty) {
      final sortColumn = sortedColumns.first;
      final field = columnConfig[sortColumn.name]?['field'] as String?;
      if (field != null) {
        items.sort((a, b) {
          final cmp = _compareCellValues(sortValue(a, field), sortValue(b, field));
          return sortColumn.sortDirection == DataGridSortDirection.ascending ? cmp : -cmp;
        });
      }
    }
    // Les index dans selectedMap n'ont plus de sens après réordonnancement.
    selectedMap.clear();
    buildDataGridRows();
    notifyListeners();
  }

  int _compareCellValues(dynamic a, dynamic b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    if (a is num && b is num) return a.compareTo(b);
    if (a is DateTime && b is DateTime) return a.compareTo(b);
    if (a is bool && b is bool) return (a == b) ? 0 : (a ? 1 : -1);
    return a.toString().toLowerCase().compareTo(b.toString().toLowerCase());
  }

  void selectAll(bool select) {
    for (int i = 0; i < items.length; i++) {
      selectedMap[i] = select;
    }
    notifyListeners();
  }

  List<Pannier> getSelectedRows() {
    return selectedMap.entries
        .where((e) => e.value)
        .map((e) => items[e.key])
        .toList();
  }

  void updateVisibleColumns(Map<String, Map<String, dynamic>> newConfig) {
    columnConfig.clear();
    columnConfig.addAll(newConfig);
    buildDataGridRows();
    notifyListeners();
  }

  void updateProduits(List<Pannier> newProduits) {
    items = newProduits;
    selectedMap.clear();
    buildDataGridRows();
    notifyListeners();
  }

  void updateVerseInfo(Map<String, double> newVerseParPannier, Map<String, int> newNbrVersementParPannier) {
    verseParPannier = newVerseParPannier;
    nbrVersementParPannier = newNbrVersementParPannier;
    buildDataGridRows();
    notifyListeners();
  }
}
