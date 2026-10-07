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
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Enregistre un mouvement de caisse manuel (entrée ou sortie hors
/// vente/achat/versement/retour — ex. dépôt de fond, prélèvement, frais
/// divers) dans [session]. Aucune catégorisation dédiée (pas de table
/// "Dépense") : motif/référence en texte libre, voir
/// CaisseSessionServices.ajouterMouvement.
Future<void> MouvementManuelDialog({
  required BuildContext context,
  required CaisseSession session,
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
  // Contexte stable de l'écran appelant, capturé avant le StatefulBuilder
  // ci-dessous qui masque `context` par ombrage de nom — voir la même
  // remarque dans cloture_caisse_session.dart (Navigator.pop suivi d'une
  // réutilisation du contexte qu'on vient de faire disparaître).
  final BuildContext callerContext = context;

  final montantController = TextEditingController();
  final motifController = TextEditingController();
  final referenceController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  String sens = 'Entrée';
  String modePaiement = ListsConst.modePaiementList.first;
  // Garde anti-double-soumission : voir la même remarque dans
  // cloture_caisse_session.dart (double Navigator.pop -> assertion GoRouter).
  bool isSubmitting = false;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 700,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.mouvementManuel,
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChampAvecLabel(
                        label: l10n.type,
                        obligatoire: true,
                        child: TextListe(
                          obligatoire: true,
                          clearable: false,
                          value: sens == 'Entrée' ? l10n.entreeManuelle : l10n.sortieManuelle,
                          items: [l10n.entreeManuelle, l10n.sortieManuelle],
                          onChanged: (v) {
                            setState(() {
                              sens = v == l10n.entreeManuelle ? 'Entrée' : 'Sortie';
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: "${l10n.montant} (${l10n.currency})",
                        obligatoire: true,
                        child: TextChampL(
                          obligatoire: true,
                          numeric: true,
                          controller: montantController,
                          hint: '0.00',
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.paymentMethod,
                        obligatoire: true,
                        child: TextListe(
                          obligatoire: true,
                          clearable: false,
                          value: modePaiement,
                          items: ListsConst.modePaiementList,
                          onChanged: (v) {
                            setState(() => modePaiement = v ?? modePaiement);
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.motifMouvement,
                        obligatoire: true,
                        child: TextChampL(
                          obligatoire: true,
                          controller: motifController,
                          hint: l10n.motifMouvement,
                          maxLines: 2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.reference,
                        child: TextChampL(
                          controller: referenceController,
                          hint: l10n.reference,
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
                      onPressed: () => Navigator.pop(context),
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
                        final now = DateTime.now();
                        final nextId = await CaisseSessionServices.getNextMouvementId(db);

                        final mouvement = CaisseMouvement(
                          id: nextId,
                          code: CodeGenerator.generateCode(
                            prefix: CodePrefix.caisseMouvement,
                            id: nextId,
                            digitCount: 8,
                          ),
                          sessionCode: session.code,
                          caisseCode: session.caisseCode,
                          type: sens == 'Entrée' ? 'entree_manuelle' : 'sortie_manuelle',
                          sens: sens,
                          montant: double.parse(montantController.text),
                          modePaiement: modePaiement,
                          motif: motifController.text,
                          reference: referenceController.text.isEmpty ? null : referenceController.text,
                          date: now,
                          etat: true,
                          dateCree: now,
                          creeParCode: userCode,
                        );

                        final response = await services.ajouterMouvement(mouvement);

                        if (!response.success) {
                          isSubmitting = false;
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.mouvementManuel,
                            message: response.message,
                          );
                          return;
                        }

                        if (!callerContext.mounted) return;
                        Navigator.pop(context);
                        await InformationDialog(
                          context: callerContext,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.mouvementManuel,
                          message: l10n.mouvementAjouteSuccess,
                        );
                        onSuccess?.call();
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
