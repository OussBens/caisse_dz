import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/Services/RoleDetail.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/role.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<int> _DeleteRoles({required BuildContext context, required List<Role> roles}) async {
  final db = await DbCreator.openDb();
  final services  = RoleServices(db);
  final serviced  = RoleDetailServices(db);
  int i = 0;
  final l10n = AppLocalizations.of(context)!;
  final tousLesUtilisateurs = await UtilisateurServices.getAllUtilisateurs();

  for (var role in roles) {
    // ✅ Le rôle Admin ne peut pas être supprimé.
    if (RoleServices.estRoleAdmin(role.rolenom)) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.deletionImpossible,
        kind: DialogKind.refuser,
        titre_concerne: l10n.role,
        message: l10n.cannotDeleteAdminRole,
      );
      continue;
    }

    final utilisateursDuRole = tousLesUtilisateurs.where((u) => u.role_code == role.code);
    if (utilisateursDuRole.isEmpty) {
      await services.deleteRole(role.id);
      await serviced.deleteRoleDetail(role.code);
      i++;
    } else {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.deletionImpossible,
        kind: DialogKind.refuser,
        titre_concerne: l10n.role,
        message: l10n.roleHasUsers(role.rolenom ?? ''),
      );
    }
  }

  return i;
}

Future<void> AnnulerRole(
    BuildContext context, List<Role> rolesSelectionnes) async {
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
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
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
                  imagePath: 'assets/icons/role_icon.png',
                  text: l10n.deactivateRoles,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedRoles,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: rolesSelectionnes.length,
                        itemBuilder: (context, index) {
                          final r = rolesSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.roleHash} #${r.code ?? '-'} - ${l10n.name}: ${r.rolenom ?? '-'}",
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
                      l10n.confirmDeactivateRoles,
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
                      text: l10n.deleteRole,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          kind: DialogKind.danger,
                          titre: l10n.role,
                          message: l10n.confirmDeleteRoles,
                          onConfirmer: () async {
                            final i = await _DeleteRoles(context: context, roles: rolesSelectionnes);

                            if (i > 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.green,
                                  content: Text(l10n.rolesDeletedCount(i)),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  backgroundColor: Colors.red,
                                  content: Text(l10n.noRolesDeleted),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }

                            Navigator.pop(context);
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