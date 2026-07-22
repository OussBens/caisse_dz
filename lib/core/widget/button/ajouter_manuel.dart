
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class AddManualWidget extends StatelessWidget {
  const AddManualWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const Color violet = Appstyle.violet;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // ---- Ligne violette ----
            Container(
              height: 4,
              width: double.infinity,
              color: violet,
            ),

            // ---- Cercle central ----
            Container(
              width: 50,
              height: 50,
              decoration: const BoxDecoration(
                color: violet,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // ---- Texte en dessous ----
        Text(
          l10n.addManually,  // 🔥 Translated
          style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
        ),
      ],
    );
  }
}