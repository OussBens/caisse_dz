import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/operation_fournisseur.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class SituationFournisseurDataSource extends DataGridSource {
  List<OperationFournisseur> operations;
  final AppLocalizations l10n;
  late List<DataGridRow> _rows;

  SituationFournisseurDataSource(this.operations, this.l10n) {
    _buildRows();
  }

  void _buildRows() {
    double solde = 0;

    _rows = operations.map((op) {
      solde += op.credit - op.debit;

      return DataGridRow(cells: [
        DataGridCell(columnName: 'date', value: _formatDate(op.date)),
        DataGridCell(columnName: 'type', value: _getTranslatedOperationType(op.type.name, l10n)),
        DataGridCell(columnName: 'ref', value: op.reference),
        DataGridCell(columnName: 'debit', value: "${NumberFormatUtil.formatMontant(op.debit, decimales: 2)} ${l10n.currency}"),
        DataGridCell(columnName: 'credit', value: "${NumberFormatUtil.formatMontant(op.credit, decimales: 2)} ${l10n.currency}"),
        DataGridCell(columnName: 'solde', value: "${NumberFormatUtil.formatMontant(solde, decimales: 2)} ${l10n.currency}"),
        DataGridCell(columnName: 'desc', value: op.description),
      ]);
    }).toList();
  }

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }

  String _getTranslatedOperationType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'Vente':
        return l10n.sale;
      case 'Achat':
        return l10n.purchase;
      case 'Retour':
        return l10n.return_;
      case 'Versement':
        return l10n.payment;
      case 'Paiement':
        return l10n.payment;
      default:
        return type;
    }
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(6),
          child: Text(
            cell.value.toString(),
            style: TextStyle(fontSize: AppConst.FontSizeTable),
          ),
        );
      }).toList(),
    );
  }

  /// 🔄 Mise à jour pagination / données
  void update(List<OperationFournisseur> newOperations) {
    operations = newOperations;
    _buildRows();
    notifyListeners();
  }
}