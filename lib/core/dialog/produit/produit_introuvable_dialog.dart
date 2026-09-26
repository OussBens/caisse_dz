import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../base_dialog.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';

/// Affiché quand un code-barre scanné ne correspond à aucun produit.
/// Propose de créer directement le produit avec ce code-barre pré-rempli.
Future<void> ProduitIntrouvableDialog({
  required BuildContext context,
  required String codeBarre,
  required VoidCallback onCreerNouveau,
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
            width: 500,
            height: 320,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/sidebar/produit_icon.png',
              text: l10n.product,
            ),
            content: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.qr_code_scanner, size: 40, color: Appstyle.gris),
                  const SizedBox(height: 16),
                  Text(
                    l10n.productNotFoundBarcode,
                    style: Appstyle.textMB.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${l10n.barcode}: $codeBarre",
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.close,
                  color: Appstyle.gris,
                  icon: Icons.close,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.createNewProduct,
                  color: Appstyle.violet,
                  icon: Icons.add,
                  onPressed: () {
                    Navigator.pop(context);
                    onCreerNouveau();
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
