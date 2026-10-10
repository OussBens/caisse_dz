import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/utilisateur.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<int> _DeleteUser({required BuildContext context, required List<Utilisateur> users}) async {
  final db = await DbCreator.openDb();
  final userServices = UtilisateurServices(db);
  final l10n = AppLocalizations.of(context)!;

  int i = 0;

  for (var user in users) {
    // ✅ L'utilisateur Admin ne peut pas être supprimé.
    if (RoleServices.estRoleAdmin(user.role)) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.deletionImpossible,
        kind: DialogKind.refuser,
        titre_concerne: l10n.user,
        message: l10n.cannotDeleteAdminUser,
      );
      continue;
    }

    // ✅ Un utilisateur ayant déjà une activité en base (créateur/vendeur/
    // caissier... sur au moins un enregistrement) ne peut pas être supprimé
    // définitivement : on le désactive à la place.
    if (await UtilisateurServices.hasActivity(user.code)) {
      await userServices.deactivateUtilisateur(user.id);
      if (context.mounted) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: l10n.user,
          message: l10n.userHasActivityDeactivated(user.username),
        );
      }
      continue;
    }

    await userServices.deleteUtilisateur(user.id);
    i++;
  }

  return i;
}

Future<void> AnnulerUtilisateur(BuildContext context, List<Utilisateur> utilisateursSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredDelete,
    );
    return;
  }

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
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/profile_icon.png',
                  text: l10n.deleteUsers,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedUsers,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: utilisateursSelectionnes.length,
                        itemBuilder: (context, index) {
                          final u = utilisateursSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.userHash} #${u.id} - ${l10n.name}: ${u.username ?? '-'} - ${l10n.role}: ${u.role ?? '-'}",
                                style: Appstyle.textSB.copyWith(
                                  color: Appstyle.Tnoir,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.confirmDeleteUsers,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),

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
                      text: l10n.deleteUsers,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          kind: DialogKind.danger,
                          titre: l10n.users,
                          message: l10n.confirmDeleteUsers,
                          onConfirmer: () async {
                            final i = await _DeleteUser(context: context, users: utilisateursSelectionnes);

                            await InformationDialog(
                              context: context,
                              titre_type_message: i > 0 ? l10n.success : l10n.error,
                              kind: i > 0 ? DialogKind.confirmer : DialogKind.refuser,
                              titre_concerne: l10n.user,
                              message: i > 0
                                  ? l10n.usersDeletedCount(i)
                                  : l10n.errorOccurred,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
                            );
                          },
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
    },
  );
}