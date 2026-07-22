
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TeteRecap extends StatelessWidget {
  final Color couleur;

  const TeteRecap({
    super.key,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    // Get localization
    final l10n = AppLocalizations.of(context)!;

    return Opacity(
      opacity: 1.0, // inactive -> opacity 50%
      child: Container(
        color: couleur,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.code,        // 🔥 Translated
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  Text(
                    l10n.product,     // 🔥 Translated
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  Text(
                    l10n.price,       // 🔥 Translated
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  Text(
                    l10n.quantity,    // 🔥 Translated
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  Text(
                    l10n.amount,      // 🔥 Translated
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}