import 'package:caisse_dz/core/tableau/situation/mouvement_produit_source.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../filter_icon_builder.dart';

class TableauMouvementProduit extends StatefulWidget {
  final List<LigneMouvementProduit> lignes;
  // Lignes cochées (Extract filtre de l'onglet Situation).
  final void Function(List<LigneMouvementProduit>)? onSelectionChanged;

  const TableauMouvementProduit({super.key, required this.lignes, this.onSelectionChanged});

  @override
  State<TableauMouvementProduit> createState() => _TableauMouvementProduitState();
}

class _TableauMouvementProduitState extends State<TableauMouvementProduit> {
  late Map<String, Map<String, dynamic>> columnVisibility;
  late MouvementProduitDataSource dataSource;

  final Map<String, double> columnWidths = {};
  bool selectAll = false;
  int _rowsPerPage = 15;
  static const List<int> _rowsPerPageOptions = [10, 15, 20, 30, 50];

  @override
  void initState() {
    super.initState();
    columnVisibility = {
      'numero': {'visible': true, 'label': 'number', 'field': 'numero'},
      'date': {'visible': true, 'label': 'date', 'field': 'date'},
      'nomProduit': {'visible': true, 'label': 'product', 'field': 'nomProduit'},
      'motif': {'visible': true, 'label': 'motifMouvement', 'field': 'motif'},
      'magasin': {'visible': true, 'label': 'magasin', 'field': 'magasin'},
      'qttInitiale': {'visible': true, 'label': 'initialQuantity', 'field': 'qttInitiale'},
      'qttMouvement': {'visible': true, 'label': 'movementQuantity', 'field': 'qttMouvement'},
      'qttApres': {'visible': true, 'label': 'quantityAfterMovement', 'field': 'qttApres'},
      'etat': {'visible': true, 'label': 'status', 'field': 'etat'},
    };
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l10n = AppLocalizations.of(context)!;
    dataSource = MouvementProduitDataSource(
      lignes: widget.lignes,
      columnConfig: columnVisibility,
      l10n: l10n,
    );

    dataSource.addListener(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {});
        widget.onSelectionChanged?.call(dataSource.getSelectedRows());
      });
    });
  }

  @override
  void didUpdateWidget(covariant TableauMouvementProduit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lignes != widget.lignes) {
      dataSource.updateLignes(widget.lignes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pageCount = (dataSource.items.length / _rowsPerPage).ceil().clamp(1, 9999).toDouble();

    return Column(
      children: [
        _buildTable(l10n),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
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

  Widget _buildTable(AppLocalizations l10n) {
    return Container(
      height: 480,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)],
      ),
      padding: const EdgeInsets.all(8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SfDataGridTheme(
          data: SfDataGridThemeData(
            headerColor: Appstyle.blueC,
            sortIconColor: Appstyle.Tblanc,
            filterIcon: Builder(builder: (context) => buildFilterIcon(context, dataSource)),
            gridLineColor: Colors.grey.shade300,
            gridLineStrokeWidth: 0.4,
          ),
          child: SfDataGrid(
            source: dataSource,
            rowsPerPage: _rowsPerPage,
            headerRowHeight: 36,
            rowHeight: 38,
            selectionMode: SelectionMode.none,
            allowSorting: true,
            allowFiltering: true,
            columnWidthMode: ColumnWidthMode.fill,
            allowColumnsResizing: true,
            columnResizeMode: ColumnResizeMode.onResize,
            onColumnResizeUpdate: (details) {
              double w = details.width;
              if (w < 90) w = 90;
              if (w > 600) w = 600;
              setState(() => columnWidths[details.column.columnName] = w);
              return true;
            },
            // BaseTableDataSource émet toujours les cellules 'settings' et
            // 'select' en tête de ligne : les colonnes doivent exister.
            columns: [
              GridColumn(
                columnName: 'settings',
                visible: false,
                allowSorting: false,
                allowFiltering: false,
                label: const SizedBox.shrink(),
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
                  .where((e) => e.value['visible'] == true)
                  .map(
                    (e) => GridColumn(
                      columnName: e.key,
                      width: columnWidths[e.key] ?? double.nan,
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
      case 'number': return l10n.number;
      case 'date': return l10n.date;
      case 'product': return l10n.product;
      case 'motifMouvement': return l10n.motifMouvement;
      case 'magasin': return l10n.magasin;
      case 'initialQuantity': return l10n.initialQuantity;
      case 'movementQuantity': return l10n.movementQuantity;
      case 'quantityAfterMovement': return l10n.quantityAfterMovement;
      case 'status': return l10n.status;
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
}
