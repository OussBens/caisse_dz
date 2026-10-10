import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
  });

  // Badge du design system : pastille (pill) teinte « soft », point de la
  // couleur du statut et libellé en teinte « ink » (lisible sur le fond).
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Appstyle.softPour(color),
        borderRadius: BorderRadius.circular(Appstyle.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Appstyle.textXSB.copyWith(fontSize: 11, color: Appstyle.inkPour(color)),
          ),
        ],
      ),
    );
  }
}
class EtatBadge extends StatelessWidget {
  final bool isActive;

  const EtatBadge({super.key, required this.isActive});

  @override
  Widget build(BuildContext context) {

    final l10n = AppLocalizations.of(context)!;
    return StatusBadge(

      text: isActive ? l10n.actif : l10n.inactif,
      color: isActive ? Appstyle.success : Appstyle.danger,
    );
  }
}