import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../data/constant.dart';
import '../../data/models/utilisateur.dart';

/// Shared base for the per-module Syncfusion [DataGridSource] implementations
/// under lib/core/tableau/**/*_source.dart.
///
/// Every module previously hand-duplicated the same selection map, "select"
/// checkbox column, default text-cell rendering, and column-visibility /
/// data-update plumbing. This base class factors that out; subclasses only
/// need to describe how to turn one [T] item + a column `field` name into a
/// cell value ([cellValue]), and optionally how to render special columns
/// such as status badges ([buildCustomCell]).
///
/// `rows` exposes the FULL [items] list to Syncfusion (not sliced to a
/// page): this lets its built-in column-header filter (`allowFiltering`)
/// search across the whole dataset instead of only whatever page happened
/// to be on screen, while keeping the exact same filter UI (funnel icon,
/// popup, checkbox list). On-screen pagination is delegated to
/// [SfDataPager] (wired per-table in each `tableau_*.dart`), which paginates
/// Syncfusion's own post-filter/sort result — something a hand-rolled
/// "slice `items` before Syncfusion sees it" pagination can never do
/// correctly once a filter is active. See `pannier_source.dart` for the
/// first table this was proven on, and the reasoning in that file's header
/// comment.
abstract class BaseTableDataSource<T> extends DataGridSource {
  /// Liste COMPLÈTE (déjà filtrée par la recherche de l'écran parent, avant
  /// tout filtre de colonne Syncfusion) — le tri par en-tête de colonne
  /// s'applique dessus, et `rows` l'expose intégralement à Syncfusion.
  List<T> items;
  final Map<String, Map<String, dynamic>> columnConfig;
  final Map<int, bool> selectedMap = {}; // clé = index dans `items`

  /// Utilisateurs de l'app, pour résoudre les codes d'audit (créé/modifié/
  /// annulé par) en nom d'utilisateur affichable via [nomUtilisateur] —
  /// optionnel, retombe sur le code si non fourni.
  List<Utilisateur> utilisateurs;

  /// Appelé au double-clic sur une ligne (n'importe quelle colonne, pas
  /// juste une colonne précise) — capture l'item directement par fermeture
  /// au moment du rendu de la cellule (voir [buildRow]), donc reste correct
  /// quel que soit le filtre/tri Syncfusion actuellement appliqué : une fois
  /// le filtre natif en jeu, l'index visuel d'une ligne ne correspond plus à
  /// un index direct dans [items] (Syncfusion réordonne/masque en interne,
  /// sans API publique pour lire ce sous-ensemble depuis l'extérieur).
  void Function(T item)? onRowDoubleTap;

  final List<DataGridRow> _rows = [];

  BaseTableDataSource({
    required this.items,
    required this.columnConfig,
    this.utilisateurs = const [],
    this.onRowDoubleTap,
  }) {
    buildDataGridRows();
  }

  /// Résout un code utilisateur (creeParCode/modifParCode/annulParCode) en
  /// nom d'utilisateur pour les colonnes d'audit — retombe sur le code tel
  /// quel si [utilisateurs] n'est pas fourni ou que le code est introuvable.
  String? nomUtilisateur(String? code) {
    if (code == null) return null;
    return utilisateurs.firstWhereOrNull((u) => u.code == code)?.username ?? code;
  }

  /// Value to display for [field] on [item]. Implemented per module
  /// (typically a `switch (field) { ... }` mirroring the model's columns).
  /// Also reused to compare values when sorting a column.
  dynamic cellValue(T item, String field);

  /// Optional custom cell widget for special columns (e.g. status/credit
  /// badges). Return null to fall back to the default centered text cell.
  Widget? buildCustomCell(String columnName, DataGridCell cell, T item) => null;

  /// Value used to SORT [field] on [item] — defaults to [cellValue]. Override
  /// this (not [cellValue]) for columns whose display value is a formatted
  /// string (e.g. "150.00 DZD", "-"): comparing those as text sorts
  /// lexicographically ("100.00" before "20.00") instead of numerically.
  /// Return the raw underlying num/DateTime instead.
  dynamic sortValue(T item, String field) => cellValue(item, field);

  /// Cellule texte en gras, réutilisée par les sous-classes (via
  /// [buildCustomCell]) pour mettre en avant une colonne "identité" (nom,
  /// référence...) — mêmes réglages que la cellule par défaut, en gras,
  /// avec couleur/alignement au choix.
  Widget boldCell(dynamic value, {Color? color, TextAlign align = TextAlign.center}) {
    return Container(
      alignment: align == TextAlign.left ? Alignment.centerLeft : Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        value?.toString() ?? '',
        textAlign: align,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: AppConst.FontSizeTable,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ⚠️ Mute `_rows` EN PLACE (clear + addAll) plutôt que de le réassigner à
  // une nouvelle List — Syncfusion capture la référence de `rows` dans son
  // propre cache interne (`_effectiveRows`) une fois au montage de la grille
  // et ne la re-synchronise PAS sur un simple `notifyListeners()` (seul son
  // `sort()` par défaut, qu'on n'appelle pas ici, le fait). Si `_rows`
  // changeait d'identité à chaque tri/sélection, ce cache interne pointerait
  // vers d'anciens objets `DataGridRow` déjà absents de la nouvelle liste —
  // d'où le RangeError -1 observé dans `buildRow` lors d'un tri. Garder le
  // même objet `List` en mémoire pour toute la durée de vie de la source
  // maintient ce cache à jour "gratuitement".
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
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);

    // Filet de sécurité : malgré la mutation en place ci-dessus, Syncfusion
    // peut transitoirement retenir une référence à une DataGridRow d'une
    // génération précédente (ex. juste après un tri, avant que son propre
    // cache interne ne se resynchronise). Plutôt que de planter
    // (RangeError sur items[-1]), on rend la ligne telle quelle à partir de
    // ses valeurs de cellules déjà calculées — le prochain rebuild corrige
    // l'affichage.
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

        // Clic n'importe où sur la ligne (pas seulement la case à cocher) :
        // sélectionne/désélectionne la ligne. Double-clic : ouvre le détail.
        // Les deux gestes cohabitent sur le même GestureDetector — Flutter
        // attend alors ~300ms après un clic simple pour voir s'il devient un
        // double-clic avant de déclencher onTap ; léger délai accepté pour
        // garder les deux interactions au même endroit.
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

  /// Trie l'intégralité de [items] selon la colonne d'en-tête cliquée, en
  /// réutilisant [cellValue]/[sortValue] pour rester générique quel que soit
  /// le type de colonne (texte, nombre, date...).
  @override
  Future<void> sort() async {
    if (sortedColumns.isNotEmpty) {
      _applySort(sortedColumns.first);
    }
    // Les index dans selectedMap n'ont plus de sens après réordonnancement.
    selectedMap.clear();
    buildDataGridRows();
    notifyListeners();
  }

  void _applySort(SortColumnDetails sortColumn) {
    final field = columnConfig[sortColumn.name]?['field'] as String?;
    if (field == null) return;
    items.sort((a, b) {
      final cmp = _compareCellValues(sortValue(a, field), sortValue(b, field));
      return sortColumn.sortDirection == DataGridSortDirection.ascending ? cmp : -cmp;
    });
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

  List<T> getSelectedRows() {
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

  /// Remplace la liste complète (ex: nouveau résultat de recherche côté
  /// écran parent). Un tri actif est réappliqué pour rester cohérent sur les
  /// nouvelles données.
  void updateItems(List<T> newItems) {
    items = newItems;
    selectedMap.clear();
    if (sortedColumns.isNotEmpty) {
      _applySort(sortedColumns.first);
    }
    buildDataGridRows();
    notifyListeners();
  }
}
