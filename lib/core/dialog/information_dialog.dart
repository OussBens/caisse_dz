import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'dialog_kind.dart';
import 'dialog_message.dart';
import '../widget/button/main_button.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

Future<void> InformationDialog({
  required BuildContext context,
  required String titre_type_message,
  required String titre_concerne,
  required String message,
  double width = 500,
  VoidCallback? onTerminer,
  DialogKind kind = DialogKind.confirmer,
}) {
  final l10n = AppLocalizations.of(context)!;

  // Nature déduite de ce que passent déjà les appelants (titre + kind).
  final NatureMessage nature;
  if (kind == DialogKind.refuser ||
      kind == DialogKind.danger ||
      titre_type_message == l10n.error ||
      titre_type_message == l10n.deletionImpossible ||
      titre_type_message == l10n.modificationImpossible) {
    nature = NatureMessage.erreur;
  } else if (titre_type_message == l10n.success) {
    nature = NatureMessage.succes;
  } else {
    nature = NatureMessage.information;
  }

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (dialogContext) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: BaseDialog(
            width: width,
            height: 300,

            header: TitreAvecLigne(
              imagePath: 'assets/icons/info_icon.png',
              text: "$titre_type_message - $titre_concerne",
            ),

            content: MessageAvecIcone(
              nature: nature,
              message: message,
              style: Appstyle.textSB.copyWith(
                color: Appstyle.Tnoir,
                height: 1.4,
              ),
            ),

            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.close,
                  color: kind.couleur,
                  icon: kind.icone,
                  onPressed: () {
                    Navigator.pop(dialogContext);
                    if (onTerminer != null) {
                      onTerminer();
                    }
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