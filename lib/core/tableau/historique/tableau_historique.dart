import 'package:caisse_dz/core/dialog/historique/historique_detail.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';
import 'historique_source.dart';

class TableauHistoriqueAdvanced extends StatefulWidget {

  final List<Historique> historiques;
  final List<Utilisateur> utilisateurs;
  final void Function(List<Historique>)? onSelectionChanged;

  const TableauHistoriqueAdvanced({
    super.key,
    required this.historiques,
    this.utilisateurs = const [],
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
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];
  bool selectAll = false;

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
      'creeParCode': {
        'visible': true,
        'label': 'createdBy',
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
      historiques: widget.historiques,
      columnConfig: columnVisibility,
      l10n: l10n,
      utilisateurs: widget.utilisateurs,
    );
    dataSource.onRowDoubleTap = (historique) => HistoriqueDetail(context, historique);

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauHistoriqueAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historiques != widget.historiques) {
      dataSource.update(widget.historiques);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

    return Column(
      children: [
        Expanded(child: _buildTable(l10n)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            boxShadow: const [BoxShadow(color: Appstyle.shadowSoft, blurRadius: 10)],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SfDataPager(
                delegate: dataSource,
                pageCount: pageCount,
                direction: Axis.horizontal,
                itemWidth: 36,
                itemHeight: 36,
              ),
              const SizedBox(width: 20),
              DropdownButton<int>(
                value: _rowsPerPage,
                items: _rowsPerPageOptions
                    .map((e) => DropdownMenuItem(value: e, child: Text("$e ${l10n.rowsPerPage}")))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => _rowsPerPage = v);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ================= TABLE =================
  Widget _buildTable(AppLocalizations l10n) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Largeur de colonne = largeur disponible / nombre de colonnes
        // visibles (hors colonnes fixes réglages + case à cocher), afin que
        // le tableau occupe toute la largeur de l'écran. Une largeur
        // redéfinie manuellement (resize) reste prioritaire.
        final int visibleCount = columnVisibility.values
            .where((c) => c['visible'] == true)
            .length;
        const double fixedWidth = 60 + 55; // settings + select
        const double innerPadding = 16; // Container padding EdgeInsets.all(8)
        final double avail = constraints.maxWidth - fixedWidth - innerPadding;
        final double computed =
            visibleCount > 0 ? avail / visibleCount : 220.0;
        final double dataColWidth = computed < 140 ? 140.0 : computed;

        return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
        boxShadow: const [
          BoxShadow(color: Appstyle.shadowSoft, blurRadius: 12)
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.gris.withOpacity(0.7),
            sortIconColor: Appstyle.Tblanc,
            filterIcon: Builder(builder: (context) => buildFilterIcon(context, dataSource)),
            gridLineColor: Appstyle.neutral200,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            rowsPerPage: _rowsPerPage,
            headerRowHeight: 36,
            rowHeight: 38,
            allowSorting: true,
            allowFiltering: true,
            selectionMode: SelectionMode.single,

            columnWidthMode: ColumnWidthMode.none,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            // Sélection au clic + double-clic pour le détail gérés dans
            // BaseTableDataSource.buildRow.

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
                  width: columnWidths[e.key] ?? dataColWidth,
                  label: _header(_getTranslatedLabel(e.value['label'], l10n)),
                ),
              ),
            ],
          ),
        ),
      ),
        );
      },
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
                borderRadius: BorderRadius.circular(Appstyle.radiusLG),
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