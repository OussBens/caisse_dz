import 'package:collection/collection.dart';

import '../../../data/constant.dart';
import '../../../data/models/caisse_session.dart';
import '../../../data/models/gestion_caisse.dart';
import '../../../l10n/app_localizations.dart';
import '../../utilis/number_format.dart';
import '../base_table_data_source.dart';

class CaisseSessionDataSource extends BaseTableDataSource<CaisseSession> {
  final AppLocalizations l10n;
  final List<CaisseGestion> caisses;

  CaisseSessionDataSource({
    required List<CaisseSession> sessions,
    required super.columnConfig,
    required this.l10n,
    this.caisses = const [],
    super.utilisateurs = const [],
  }) : super(items: sessions);

  String _nomCaisse(String code) =>
      caisses.firstWhereOrNull((c) => c.code == code)?.nomCaisse ?? code;

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year} "
        "${date.hour.toString().padLeft(2, '0')}:"
        "${date.minute.toString().padLeft(2, '0')}";
  }

  String _formatMontant(double? montant) => montant == null
      ? '-'
      : "${NumberFormatUtil.formatMontant(montant, decimales: 2)} ${l10n.currency}";

  @override
  dynamic cellValue(CaisseSession s, String field) {
    switch (field) {
      case 'code':
        return s.code;
      case 'caisseCode':
        return _nomCaisse(s.caisseCode);
      case 'statut':
        return s.statut == CaisseSession.statutOuverte ? l10n.sessionStatutOuverte : l10n.sessionStatutCloturee;
      case 'soldeOuverture':
        return _formatMontant(s.soldeOuverture);
      case 'dateOuverture':
        return _formatDate(s.dateOuverture);
      case 'soldeTheorique':
        return _formatMontant(s.soldeTheorique);
      case 'soldeReel':
        return _formatMontant(s.soldeReel);
      case 'ecart':
        return _formatMontant(s.ecart);
      case 'dateCloture':
        return _formatDate(s.dateCloture);
      case 'creeParCode':
        return nomUtilisateur(s.creeParCode);
      default:
        return '';
    }
  }

  void update(List<CaisseSession> newList) => updateItems(newList);
}
