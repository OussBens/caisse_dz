import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/tableau/caisse/tableau_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> ModifierPrixProduitDialog({
  required BuildContext context,
  required ProduitPanier produit,
  required Function(double nouveauPrix) onValider,
  // ✅ Appelé uniquement lorsque l'utilisateur choisit d'appliquer le nouveau
  // prix au produit complet (mise à jour permanente en base). Si null, seule
  // l'option "ce bon" est proposée.
  Future<void> Function(double nouveauPrix)? onValiderProduit,
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
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  // ✅ Comportement configuré dans Paramètres > Système quand le prix de
  // vente saisi passe sous le prix d'achat du produit — voir
  // Paramters.venteSousAchat. Chargé une fois à l'ouverture du dialog.
  final venteSousAchat = (await ParamServices.getParam()).venteSousAchat;

  if (!context.mounted) return;

  final TextEditingController prixVenteController = TextEditingController(text: produit.prix.toStringAsFixed(2));
  final TextEditingController passwordController = TextEditingController();

  String? erreur;
  // ✅ Portée de la modification : false = ce bon uniquement, true = produit
  // complet (permanent). L'option "produit" n'a de sens que si l'appelant a
  // fourni [onValiderProduit].
  bool appliquerAuProduit = false;

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
                    _readOnlyField(NumberFormatUtil.formatMontant(produit.prixachat, decimales: 2)),

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

                    /// ───── PORTÉE DE LA MODIFICATION ─────
                    // Proposée seulement si l'appelant sait persister le prix
                    // au produit (onValiderProduit fourni).
                    if (onValiderProduit != null) ...[
                      const SizedBox(height: 14),
                      Text(l10n.priceChangeScope, style: Appstyle.textSB),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: Text(l10n.thisTicketOnly),
                            selected: !appliquerAuProduit,
                            selectedColor: Appstyle.violet,
                            labelStyle: TextStyle(
                              color: !appliquerAuProduit ? Colors.white : Appstyle.Tnoir,
                            ),
                            onSelected: (_) => setState(() => appliquerAuProduit = false),
                          ),
                          ChoiceChip(
                            label: Text(l10n.entireProduct),
                            selected: appliquerAuProduit,
                            selectedColor: Appstyle.violet,
                            labelStyle: TextStyle(
                              color: appliquerAuProduit ? Colors.white : Appstyle.Tnoir,
                            ),
                            onSelected: (_) => setState(() => appliquerAuProduit = true),
                          ),
                        ],
                      ),
                    ],

                    if (erreur != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        erreur!,
                        style: Appstyle.textS.copyWith(color: Appstyle.danger),
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
                      onPressed: () async {
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

                        // ✅ Comportement configurable (Paramètres > Système)
                        // quand le prix saisi passe sous le prix d'achat réel
                        // du produit (produit.prixachat — pas produit.prix,
                        // qui est le prix de VENTE dans ProduitPanier).
                        if (venteSousAchat != 'Autoriser' && prix < produit.prixachat) {
                          final prixVenteTxt = NumberFormatUtil.formatMontant(prix, decimales: 2);
                          final prixAchatTxt = NumberFormatUtil.formatMontant(produit.prixachat, decimales: 2);

                          if (venteSousAchat == 'Interdire') {
                            setState(() {
                              erreur = l10n.saleBelowCostBlockedMessage(prixVenteTxt, prixAchatTxt, l10n.currency);
                            });
                            return;
                          }

                          // 'Avertir' : laisse passer seulement si confirmé.
                          final confirme = await ConfirmationDialog(
                            context: context,
                            kind: DialogKind.attention,
                            titre: l10n.saleBelowCostLabel,
                            message: l10n.saleBelowCostWarningMessage(prixVenteTxt, prixAchatTxt, l10n.currency),
                          );
                          if (confirme != true) return;
                        }

                        // Toujours répercuter le nouveau prix sur la ligne du bon.
                        onValider(prix);
                        // Si portée "produit complet" : persister aussi en base.
                        if (appliquerAuProduit && onValiderProduit != null) {
                          await onValiderProduit(prix);
                        }
                        if (context.mounted) Navigator.pop(context);
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
      borderRadius: BorderRadius.circular(Appstyle.radiusSM),
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
      borderRadius: BorderRadius.circular(Appstyle.radiusSM),
    ),
  );
}