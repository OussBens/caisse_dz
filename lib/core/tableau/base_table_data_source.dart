import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../data/constant.dart';

/// Shared base for the per-module Syncfusion [DataGridSource] implementations
/// under lib/core/tableau/**/*_source.dart.
///
/// Every module previously hand-duplicated the same selection map, "select"
/// checkbox column, default text-cell rendering, and column-visibility /
/// data-update plumbing. This base class factors that out; subclasses only
/// need to describe how to turn one [T] item + a column `field` name into a
/// cell value ([cellValue]), and optionally how to render special columns
/// such as status badges ([buildCustomCell]).
abstract class BaseTableDataSource<T> extends DataGridSource {
  List<T> items;
  final Map<String, Map<String, dynamic>> columnConfig;
  final Map<int, bool> selectedMap = {};

  List<DataGridRow> _rows = [];

  BaseTableDataSource({
    required this.items,
    required this.columnConfig,
  }) {
    buildDataGridRows();
  }

  /// Value to display for [field] on [item]. Implemented per module
  /// (typically a `switch (field) { ... }` mirroring the model's columns).
  dynamic cellValue(T item, String field);

  /// Optional custom cell widget for special columns (e.g. status/credit
  /// badges). Return null to fall back to the default centered text cell.
  Widget? buildCustomCell(String columnName, DataGridCell cell, T item) => null;

  void buildDataGridRows() {
    _rows = List.generate(items.length, (index) {
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
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = _rows.indexOf(row);
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
        if (custom != null) return custom;

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

  void selectAll(bool select) {
    for (int i = 0; i < items.length; i++) {
      selectedMap[i] = select;
    }
    buildDataGridRows();
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

  void updateItems(List<T> newItems) {
    items = newItems;
    selectedMap.clear();
    buildDataGridRows();
    notifyListeners();
  }
}
