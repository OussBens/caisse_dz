
import 'dart:ui';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/core/dialog/dialog_message.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';


Future<bool?> ConfirmationDialog({
  required BuildContext context,
  required String titre,
  required String message,
  VoidCallback? onConfirmer,
  DialogKind kind = DialogKind.confirmer,
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (dialogContext) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: BaseDialog(
            width: 500,
            height: 320,

            header: TitreAvecLigne(
              imagePath: 'assets/icons/info_icon.png',
              text: "${l10n.confirmation} - $titre",
            ),

            // Action destructive/refusée = croix rouge, sinon point
            // d'exclamation orange (demande de confirmation).
            content: MessageAvecIcone(
              nature: kind == DialogKind.danger || kind == DialogKind.refuser
                  ? NatureMessage.erreur
                  : NatureMessage.information,
              message: message,
            ),

            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () => Navigator.pop(dialogContext, false),
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.confirm,
                  color: kind.couleur,
                  icon: kind == DialogKind.confirmer ? null : kind.icone,
                  noIcon: kind == DialogKind.confirmer,
                  onPressed: () {
                    onConfirmer?.call();
                    Navigator.pop(dialogContext, true);
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