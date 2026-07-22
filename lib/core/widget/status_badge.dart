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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
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
      color: isActive ? Colors.green : Colors.red,
    );
  }
}