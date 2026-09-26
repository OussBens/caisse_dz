import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

/// Plage de dates résultant d'un préréglage "période rapide".
class PeriodeRapideResult {
  final DateTime debut;
  final DateTime fin;
  const PeriodeRapideResult(this.debut, this.fin);
}

/// Libellés des préréglages, partagés par tous les filtres "période rapide"
/// de l'application (Dashboard, Gestion de caisse, écrans Situation…).
Map<String, String> periodesRapidesLabels(AppLocalizations l10n) => {
  "today": l10n.today,
  "yesterday": l10n.yesterday,
  "week": l10n.thisWeek,
  "lastWeek": l10n.lastWeek,
  "month": l10n.thisMonth,
  "lastMonth": l10n.lastMonth,
  "last7days": l10n.last7Days,
  "last30days": l10n.last30Days,
  "year": l10n.thisYear,
  "lastYear": l10n.lastYear,
};

/// Calcule la plage de dates correspondant à une clé de préréglage.
PeriodeRapideResult calculerPeriodeRapide(String key) {
  final now = DateTime.now();
  switch (key) {
    case "today":
      final d = DateTime(now.year, now.month, now.day);
      return PeriodeRapideResult(d, d);
    case "yesterday":
      final d = DateTime(now.year, now.month, now.day - 1);
      return PeriodeRapideResult(d, d);
    case "week":
      final debut = now.subtract(Duration(days: now.weekday - 1));
      return PeriodeRapideResult(debut, debut.add(const Duration(days: 6)));
    case "lastWeek":
      final debut = now.subtract(Duration(days: now.weekday + 6));
      return PeriodeRapideResult(debut, debut.add(const Duration(days: 6)));
    case "month":
      return PeriodeRapideResult(
          DateTime(now.year, now.month, 1), DateTime(now.year, now.month + 1, 0));
    case "lastMonth":
      return PeriodeRapideResult(
          DateTime(now.year, now.month - 1, 1), DateTime(now.year, now.month, 0));
    case "last7days":
      return PeriodeRapideResult(now.subtract(const Duration(days: 6)), now);
    case "last30days":
      return PeriodeRapideResult(now.subtract(const Duration(days: 29)), now);
    case "year":
      return PeriodeRapideResult(DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
    case "lastYear":
      return PeriodeRapideResult(DateTime(now.year - 1, 1, 1), DateTime(now.year - 1, 12, 31));
    default:
      final d = DateTime(now.year, now.month, now.day);
      return PeriodeRapideResult(d, d);
  }
}

/// Dropdown réutilisable de préréglages "période rapide". Le consommateur
/// applique lui-même [calculerPeriodeRapide] au résultat de [onSelected]
/// (mise à jour de ses propres contrôleurs de date / recharge des données),
/// afin de rester compatible avec la façon dont chaque écran gère déjà ses
/// champs de date.
class PeriodeRapideDropdown extends StatelessWidget {
  final AppLocalizations l10n;
  final String? value;
  final ValueChanged<String> onSelected;
  final double width;

  const PeriodeRapideDropdown({
    super.key,
    required this.l10n,
    required this.value,
    required this.onSelected,
    this.width = 220,
  });

  @override
  Widget build(BuildContext context) {
    final periodes = periodesRapidesLabels(l10n);
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        hint: Text(l10n.quickPeriod),
        isExpanded: true,
        items: periodes.entries
            .map((e) => DropdownMenuItem<String>(value: e.key, child: Text(e.value)))
            .toList(),
        onChanged: (v) {
          if (v != null) onSelected(v);
        },
      ),
    );
  }
}
