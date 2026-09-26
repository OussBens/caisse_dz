import 'package:collection/collection.dart';

import '../../../data/models/cloture_caisse.dart';
import '../../../data/models/gestion_caisse.dart';
import '../../../l10n/app_localizations.dart';
import '../../utilis/number_format.dart';
import '../base_table_data_source.dart';

class ClotureCaisseDataSource extends BaseTableDataSource<ClotureCaisse> {
  final AppLocalizations l10n;
  final List<CaisseGestion> caisses;

  ClotureCaisseDataSource({
    required List<ClotureCaisse> clotures,
    required super.columnConfig,
    required this.l10n,
    this.caisses = const [],
    super.utilisateurs = const [],
  }) : super(items: clotures);

  String _nomCaisse(String code) =>
      caisses.firstWhereOrNull((c) => c.code == code)?.nomCaisse ?? code;

  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  @override
  dynamic cellValue(ClotureCaisse c, String field) {
    switch (field) {
      case 'code':
        return c.code;
      case 'caisseCode':
        return _nomCaisse(c.caisseCode);
      case 'dateDebut':
        return _formatDate(c.dateDebut);
      case 'dateFin':
        return _formatDate(c.dateFin);
      case 'totalVentes':
        return "${NumberFormatUtil.formatMontant(c.totalVentes, decimales: 2)} ${l10n.currency}";
      case 'totalAnnule':
        return "${NumberFormatUtil.formatMontant(c.totalAnnule, decimales: 2)} ${l10n.currency}";
      case 'nombreTickets':
        return c.nombreTickets;
      case 'nombreTicketsAnnules':
        return c.nombreTicketsAnnules;
      case 'utilisateurCode':
        return nomUtilisateur(c.utilisateurCode);
      case 'dateCree':
        return _formatDate(c.dateCree);
      case 'hash':
        return c.hash;
      default:
        return '';
    }
  }

  void update(List<ClotureCaisse> newList) => updateItems(newList);
}
