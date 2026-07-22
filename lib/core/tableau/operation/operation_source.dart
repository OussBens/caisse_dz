import 'package:caisse_dz/data/constant.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/operation_client.dart';
import '../../../l10n/app_localizations.dart';

class SituationClientDataSource extends DataGridSource {
  List<OperationClient> operations;
  final AppLocalizations l10n;
  late List<DataGridRow> _rows;

  SituationClientDataSource(this.operations, this.l10n) {
    _buildRows();
  }

  void _buildRows() {
    double solde = 0;

    _rows = operations.map((op) {
      solde += op.credit - op.debit;

      return DataGridRow(cells: [
        DataGridCell(columnName: 'date', value: _formatDate(op.date)),
        DataGridCell(columnName: 'type', value: _getTranslatedOperationType(op.type.name, l10n)),
        DataGridCell(columnName: 'reference', value: op.reference),
        DataGridCell(columnName: 'debit', value: "${op.debit.toStringAsFixed(2)} ${l10n.currency}"),
        DataGridCell(columnName: 'credit', value: "${op.credit.toStringAsFixed(2)} ${l10n.currency}"),
        DataGridCell(columnName: 'solde', value: "${solde.toStringAsFixed(2)} ${l10n.currency}"),
        DataGridCell(columnName: 'description', value: op.description),
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
  void update(List<OperationClient> newOperations) {
    operations = newOperations;
    _buildRows();
    notifyListeners();
  }
}