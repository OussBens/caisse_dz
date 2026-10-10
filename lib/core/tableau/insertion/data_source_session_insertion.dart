import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';
import '../../../../data/models/caisse_session.dart';
import '../../../../data/models/gestion_caisse.dart';
import '../../../data/constant.dart';
import '../../../l10n/app_localizations.dart';
import '../../utilis/number_format.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Source de données Syncfusion pour le tableau de sélection d'une session
/// de caisse (dialog [InsertionSessionDialog]). Même structure que
/// [PannierInsertionDataSource] : une colonne "select" (checkbox) + colonnes
/// d'affichage, sélection simple par index.
class SessionInsertionDataSource extends DataGridSource {
  List<CaisseSession> sessions;
  final List<CaisseGestion> caisses;
  final void Function(int index)? onSelectRow;
  final AppLocalizations l10n;

  int? selectedIndex;
  late List<DataGridRow> _rows;

  SessionInsertionDataSource({
    required this.sessions,
    required this.caisses,
    this.onSelectRow,
    required this.l10n,
  }) {
    _buildRows();
  }

  static String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  String _nomCaisse(String caisseCode) =>
      caisses.firstWhereOrNull((c) => c.code == caisseCode)?.nomCaisse ?? caisseCode;

  void update(List<CaisseSession> newSessions) {
    sessions = newSessions;
    _buildRows();
    notifyListeners();
  }

  void _buildRows() {
    _rows = List.generate(sessions.length, (index) {
      final s = sessions[index];
      return DataGridRow(cells: [
        DataGridCell<bool>(
          columnName: 'select',
          value: selectedIndex == index,
        ),
        DataGridCell(columnName: 'code', value: s.code),
        DataGridCell(columnName: 'caisse', value: _nomCaisse(s.caisseCode)),
        DataGridCell(
          columnName: 'statut',
          value: s.estOuverte ? l10n.sessionStatutOuverte : l10n.sessionStatutCloturee,
        ),
        DataGridCell(columnName: 'dateOuverture', value: _formatDate(s.dateOuverture)),
        DataGridCell(
          columnName: 'soldeOuverture',
          value: NumberFormatUtil.formatMontant(s.soldeOuverture, decimales: 2),
        ),
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
              activeColor: Appstyle.primary,
              onChanged: (_) {
                onSelectRow?.call(rowIndex);
              },
            ),
          );
        }

        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            cell.value?.toString() ?? '',
            style: const TextStyle(fontSize: AppConst.FontSizeTable),
          ),
        );
      }).toList(),
    );
  }

  void updateSessions(
    List<CaisseSession> newSessions, {
    CaisseSession? selectedSession,
  }) {
    sessions
      ..clear()
      ..addAll(newSessions);

    if (selectedSession != null) {
      selectedIndex = sessions.indexWhere((s) => s.id == selectedSession.id);
    } else {
      selectedIndex = null;
    }

    _buildRows();
    notifyListeners();
  }
}
