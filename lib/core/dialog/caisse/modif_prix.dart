import 'dart:ui';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/tableau/caisse/tableau_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../information_dialog.dart';

Future<void> ModifierPrixProduitDialog({
  required BuildContext context,
  required ProduitPanier produit,
  required Function(double nouveauPrix) onValider,
}) async{
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;

  print("Auth State Check:");
  print("isAuthenticated: ${auth.isAuthenticated}");
  print("username: ${auth.username}");
  print("userCode: ${auth.userCode}");

  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  final TextEditingController prixVenteController = TextEditingController(text: produit.prix.toStringAsFixed(2));
  final TextEditingController passwordController = TextEditingController();

  String? erreur;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 600,
                height: 600,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/euro_icon.png',
                  text: l10n.modifyProductPrice,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ───── NOM PRODUIT ─────
                    Text(l10n.product, style: Appstyle.textSB),
                    const SizedBox(height: 6),
                    _readOnlyField(produit.nom),

                    const SizedBox(height: 14),

                    /// ───── PRIX ACHAT ─────
                    Text("${l10n.purchasePrice} (${l10n.currency})", style: Appstyle.textSB),
                    const SizedBox(height: 6),
                    _readOnlyField(produit.prix.toStringAsFixed(2)),

                    const SizedBox(height: 14),

                    /// ───── PRIX VENTE ─────
                    Text("${l10n.salePrice} (${l10n.currency})", style: Appstyle.textSB),
                    const SizedBox(height: 6),
                    TextField(
                      controller: prixVenteController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: _inputDecoration(),
                    ),

                    const SizedBox(height: 14),

                    /// ───── MOT DE PASSE ─────
                    Text(l10n.password, style: Appstyle.textSB),
                    const SizedBox(height: 6),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: _inputDecoration(),
                    ),

                    if (erreur != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        erreur!,
                        style: Appstyle.textS.copyWith(color: Colors.red),
                      ),
                    ],
                  ],
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
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () {
                        final prix = double.tryParse(prixVenteController.text);
                        final password = passwordController.text;

                        if (prix == null || prix <= 0) {
                          setState(() {
                            erreur = l10n.invalidPrice;
                          });
                          return;
                        }

                        if (password.isEmpty) {
                          setState(() {
                            erreur = l10n.passwordRequired;
                          });
                          return;
                        }

                        onValider(prix);
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// ───────── WIDGET CHAMP LECTURE SEULE ─────────
Widget _readOnlyField(String value) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: Appstyle.grisC.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      value,
      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
    ),
  );
}

/// ───────── DECORATION INPUT ─────────
InputDecoration _inputDecoration() {
  return InputDecoration(
    isDense: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );
}