import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
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
}) {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
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

            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.close,
                  color: Appstyle.violet,
                  icon: Icons.check_circle,
                  onPressed: () {
                    Navigator.pop(context);
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