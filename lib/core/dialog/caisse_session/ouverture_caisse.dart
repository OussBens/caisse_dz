import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Ouvre une session de caisse pour [caisse] : saisie du solde d'ouverture
/// (pré-rempli avec `caisse.soldeInitial` comme montant suggéré), bloqué si
/// une session est déjà ouverte pour cette caisse. Voir
/// CaisseSessionServices.ouvrirSession — appelé avant toute vente, achat,
/// versement ou retour (voir la vérification dans EnregistrerTicketDialog).
Future<void> OuvertureCaisseDialog({
  required BuildContext context,
  required CaisseGestion caisse,
  VoidCallback? onSuccess,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final auth = Provider.of<AuthState>(context, listen: false);

  if (!auth.isAuthenticated || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }
  final String userCode = auth.userCode!;

  final soldeController = TextEditingController(
    text: caisse.soldeInitial.toStringAsFixed(2),
  );
  final formKey = GlobalKey<FormState>();
  // Garde anti-double-soumission : sans elle, un double-clic sur "Enregistrer"
  // déclenche deux fois l'appel async ci-dessous — le 1er Navigator.pop ferme
  // bien ce dialog, mais le 2e (dialog déjà fermé) retombe alors sur la PAGE
  // GoRouter sous-jacente et la fait sauter ("You have popped the last page
  // off of the stack"), plantant l'app. Pas de StatefulBuilder ici (pas
  // besoin d'un retour visuel type spinner) : un simple booléen capturé par
  // la closure suffit à bloquer la ré-entrance.
  bool isSubmitting = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (dialogContext) {
      return ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
          child: BaseDialog(
            width: 700,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/sidebar/caisse_icon.png',
              text: l10n.ouvrirCaisse,
            ),
            content: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ChampAvecLabel(
                    label: "${l10n.soldeOuverture} (${l10n.currency})",
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      numeric: true,
                      controller: soldeController,
                      hint: l10n.soldeOuvertureSuggere(
                        caisse.soldeInitial.toStringAsFixed(2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            footer: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                MainButton(
                  text: l10n.cancel,
                  icon: Icons.cancel,
                  color: Appstyle.gris,
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.save,
                  icon: Icons.save,
                  color: Appstyle.violet,
                  onPressed: () async {
                    if (isSubmitting) return;
                    if (!formKey.currentState!.validate()) return;
                    isSubmitting = true;

                    final db = await DbCreator.openDb();
                    final services = CaisseSessionServices(db);
                    final response = await services.ouvrirSession(
                      caisseCode: caisse.code,
                      soldeOuverture: double.parse(soldeController.text),
                      userCode: userCode,
                    );

                    if (!response.success) {
                      isSubmitting = false;
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.ouvrirCaisse,
                        message: response.message,
                      );
                      return;
                    }

                    Navigator.pop(dialogContext);
                    onSuccess?.call();
                    if (!context.mounted) return;
                    await InformationDialog(
                      context: context,
                      titre_type_message: l10n.success,
                      titre_concerne: l10n.ouvrirCaisse,
                      message: l10n.ouvertureCaisseSuccess,
                    );
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
