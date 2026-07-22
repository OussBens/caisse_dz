import 'dart:ui';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'base_dialog.dart';

Future<void> ConfirmationDialog({
  required BuildContext context,
  required String titre,
  required String message,
  required VoidCallback onConfirmer,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: BaseDialog(
            width: 500,
            height: 320,

            /// ───── HEADER ─────
            header: TitreAvecLigne(
              imagePath: 'assets/icons/info_icon.png',
              text: "${l10n.confirmation} - $titre",
            ),

            /// ───── CONTENT ─────
            content: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: Appstyle.textSB.copyWith(
                  color: Appstyle.Tnoir,
                  height: 1.4,
                ),
              ),
            ),

            /// ───── FOOTER ─────
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.confirm,
                  color: Appstyle.violet,
                  noIcon: true,
                  onPressed: () {
                    Navigator.pop(context);
                    onConfirmer();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}