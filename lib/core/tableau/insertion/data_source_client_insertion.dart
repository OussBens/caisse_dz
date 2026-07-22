import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/client.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';

class ClientInsertionDataSource extends DataGridSource {
  List<Client> clients;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  ClientInsertionDataSource({
    required this.clients,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  void update(List<Client> newClients) {
    clients = newClients;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(clients.length, (index) {
      final c = clients[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: c.code),
        DataGridCell(columnName: 'nom', value: c.nom),
        DataGridCell(columnName: 'telephone', value: c.telephone),
        DataGridCell(columnName: 'wilaya', value: c.wilaya),
        DataGridCell(columnName: 'etat', value: c.etat ? l10n.active : l10n.inactive),
      ]);
    });
  }

  void selectRow(int index) {
    selectedIndex = index;
    _buildRows();
    notifyListeners();
  }

  @override
  List<DataGridRow> get rows => _rows;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final rowIndex = _rows.indexOf(row);

    return DataGridRowAdapter(
      cells: row.getCells().map((cell) {
        if (cell.columnName == 'select') {
          return Center(
            child: Checkbox(
              value: selectedIndex == rowIndex,
              activeColor: Colors.deepPurple,
              onChanged: (_) {
                onSelectRow?.call(rowIndex);
              },
            ),
          );
        }

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(cell.value?.toString() ?? '',
            style: const TextStyle(
              fontSize: AppConst.FontSizeTable,
            ),),
        );
      }).toList(),
    );
  }

  void updateClients(
      List<Client> newClients, {
        Client? selectedClient,
      }) {
    clients
      ..clear()
      ..addAll(newClients);

    if (selectedClient != null) {
      selectedIndex = clients.indexWhere((c) => c.id == selectedClient.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}