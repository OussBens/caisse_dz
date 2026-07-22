import 'package:caisse_dz/core/dialog/historique/historique_detail.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../widget/tableau/paginated.dart';
import 'historique_source.dart';

class TableauHistoriqueAdvanced extends StatefulWidget {

  final List<Historique> historiques;
  final void Function(List<Historique>)? onSelectionChanged;

  const TableauHistoriqueAdvanced({
    super.key,
    required this.historiques,
    this.onSelectionChanged,
  });

  @override
  State<TableauHistoriqueAdvanced> createState() =>
      _TableauHistoriqueAdvancedState();
}

class _TableauHistoriqueAdvancedState
    extends State<TableauHistoriqueAdvanced> {

  late HistoriqueDataSource dataSource;

  bool garderSelectionColonnes = true;
  late final Map<String, bool> colonnesParDefaut;

  final Map<String, double> columnWidths = {};
  int rowsPerPage = 15;
  int currentPage = 1;
  bool selectAll = false;

  // ================= PAGINATION =================
  List<Historique> get paginatedData {
    final start = (currentPage - 1) * rowsPerPage;
    final end = (start + rowsPerPage)
        .clamp(0, widget.historiques.length);

    if (start >= widget.historiques.length) return [];
    return widget.historiques.sublist(start, end);
  }

  int get totalPages =>
      widget.historiques.isEmpty
          ? 1
          : (widget.historiques.length / rowsPerPage)
          .ceil()
          .clamp(1, 9999);

  late Map<String, Map<String, dynamic>> columnVisibility;

  @override
  void initState() {
    super.initState();

    // 🔹 Colonnes HISTORIQUE
    columnVisibility = {
      'code': {
        'visible': true,
        'label': 'code',
        'field': 'code'
      },
      'operation sur': {
        'visible': true,
        'label': 'operationOn',
        'field': 'operation sur'
      },
      'type': {
        'visible': true,
        'label': 'type',
        'field': 'type'
      },
      'description': {
        'visible': true,
        'label': 'description',
        'field': 'description'
      },
      'creePar': {
        'visible': true,
        'label': 'createdBy',
        'field': 'creePar'
      },
      'creeParCode': {
        'visible': false,
        'label': 'creatorCode',
        'field': 'creeParCode'
      },
      'dateCree': {
        'visible': true,
        'label': 'createdAt',
        'field': 'dateCree'
      },
    };

    colonnesParDefaut = {
      for (var e in columnVisibility.entries)
        e.key: e.value['visible'] as bool,
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;

    dataSource = HistoriqueDataSource(
      historiques: paginatedData,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      widget.onSelectionChanged?.call(dataSource.getSelectedRows());
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 12),
        PaginationBar(
          currentPage: currentPage,
          totalPages: totalPages,
          rowsPerPage: rowsPerPage,
          onPageChanged: (page) {
            setState(() {
              currentPage = page;
              dataSource.update(paginatedData);
            });
          },
          onRowsPerPageChanged: (v) {
            setState(() {
              rowsPerPage = v;
              currentPage = 1;
              dataSource.update(paginatedData);
            });
          },
        ),
      ],
    );
  }

  // ================= TABLE =================
  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 12)
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.gris.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIconColor: Appstyle.Tblanc,
            gridLineColor: Colors.grey.shade300,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            headerRowHeight: 36,
            rowHeight: 38,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,

            columnWidthMode: ColumnWidthMode.none,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,

            onCellDoubleTap: (details) {
              if (details.rowColumnIndex.rowIndex <= 0) return;
              final rowIndex = details.rowColumnIndex.rowIndex - 1;
              final Historique historique = paginatedData[rowIndex];
              HistoriqueDetail(context, historique);
            },

            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 150) w = 150;
              if (w > 1000) w = 1000;
              setState(() => columnWidths[details.column.columnName] = w);
              return true;
            },

            columns: [
              GridColumn(
                columnName: 'settings',
                width: 60,
                allowSorting: false,
                allowFiltering: false,
                label: Center(
                  child: IconButton(
                    icon: const Icon(Icons.view_column, color: Colors.white),
                    tooltip: l10n.showHideColumns,
                    onPressed: () => _showColumnSettingsPopup(context, l10n),
                  ),
                ),
              ),
              GridColumn(
                columnName: 'select',
                width: 55,
                allowSorting: false,
                allowFiltering: false,
                label: Center(
                  child: Checkbox(
                    value: selectAll,
                    onChanged: (v) {
                      setState(() {
                        selectAll = v ?? false;
                        dataSource.selectAll(selectAll);
                      });
                    },
                  ),
                ),
              ),
              ...columnVisibility.entries
                  .where((e) => e.value['visible'])
                  .map(
                    (e) => GridColumn(
                  columnName: e.key,
                  width: columnWidths[e.key] ?? 220,
                  label: _header(_getTranslatedLabel(e.value['label'], l10n)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTranslatedLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'code': return l10n.code;
      case 'operationOn': return l10n.operationOn;
      case 'type': return l10n.type;
      case 'description': return l10n.description;
      case 'createdBy': return l10n.createdBy;
      case 'creatorCode': return l10n.creatorCode;
      case 'createdAt': return l10n.createdAt;
      default: return key;
    }
  }

  Widget _header(String title) => Center(
    child: Text(
      title,
      style: Appstyle.textSB.copyWith(
        fontWeight: FontWeight.w600,
        color: Appstyle.Tblanc,
      ),
    ),
  );

  // ================= COLONNES =================
  void _showColumnSettingsPopup(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(l10n.showHideColumns),
              content: SizedBox(
                width: 350,
                height: 450,
                child: SingleChildScrollView(
                  child: Column(
                    children: columnVisibility.entries.map((entry) {
                      return CheckboxListTile(
                        title: Text(_getTranslatedLabel(entry.value['label'], l10n)),
                        value: entry.value['visible'],
                        onChanged: (value) {
                          setDialog(() {
                            entry.value['visible'] = value ?? false;
                          });

                          setState(() {
                            dataSource.updateVisibleColumns(columnVisibility);
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  child: Text(l10n.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      },
    );
  }
}