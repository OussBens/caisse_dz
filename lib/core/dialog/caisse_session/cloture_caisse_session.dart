import 'dart:ui';

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
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Clôture [session] : calcule le solde théorique (fond de départ +
/// mouvements actifs de la session), fait saisir le solde réel compté par
/// l'utilisateur et affiche l'écart en direct. Distinct de la clôture
/// fiscale "Clôture Z" (ClotureCaisseServices/cloture_caisse), qui ne porte
/// que sur les ventes — celle-ci porte sur la trésorerie réelle de la
/// session (voir CaisseSessionServices.cloturerSession).
Future<void> ClotureCaisseSessionDialog({
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
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }
  final String userCode = auth.userCode!;

  final soldeTheorique = await CaisseSessionServices.getSoldeCourant(session.code);
  final soldeReelController = TextEditingController(text: soldeTheorique.toStringAsFixed(2));
  final formKey = GlobalKey<FormState>();

  if (!context.mounted) return;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final soldeReel = double.tryParse(soldeReelController.text) ?? soldeTheorique;
          final ecart = soldeReel - soldeTheorique;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 700,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.cloturerCaisse,
                ),
                content: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChampAvecLabel(
                        label: "${l10n.soldeTheorique} (${l10n.currency})",
                        child: TextChampL(
                          controller: TextEditingController(
                            text: NumberFormatUtil.formatMontant(soldeTheorique, decimales: 2),
                          ),
                          hint: '',
                          enabled: false,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: "${l10n.soldeReel} (${l10n.currency})",
                        obligatoire: true,
                        child: TextChampL(
                          obligatoire: true,
                          numeric: true,
                          controller: soldeReelController,
                          hint: '0.00',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: "${l10n.ecartCaisse} (${l10n.currency})",
                        child: Text(
                          NumberFormatUtil.formatMontant(ecart, decimales: 2),
                          style: Appstyle.textSB.copyWith(
                            color: ecart == 0
                                ? Appstyle.Tnoir
                                : (ecart > 0 ? Colors.green : Colors.red),
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!formKey.currentState!.validate()) return;

                        final db = await DbCreator.openDb();
                        final services = CaisseSessionServices(db);
                        final response = await services.cloturerSession(
                          sessionCode: session.code,
                          soldeReel: double.parse(soldeReelController.text),
                          userCode: userCode,
                        );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.cloturerCaisse,
                            message: response.message,
                          );
                          return;
                        }

                        if (context.mounted) Navigator.pop(context);
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.cloturerCaisse,
                          message: l10n.clotureCaisseSuccess,
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
