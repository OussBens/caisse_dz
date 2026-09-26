import 'dart:convert';
import 'dart:ui';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../base_dialog.dart';
import '../caisse/parametre_caisse.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

// ✅ Même schéma de hachage que AuthState.hashPassword / utilisateur_nouveau.dart
// (salt fixe historique de l'app, non centralisé ailleurs).
String _hashPassword(String password) {
  const String salt = 'SYSTEM_SALT';
  final bytes = utf8.encode(password + salt);
  return sha256.convert(bytes).toString();
}

String _formatDateHeure(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year} "
      "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}

final TextEditingController _codeController = TextEditingController();
final TextEditingController _dernierAccesController = TextEditingController();
final TextEditingController _usernameController = TextEditingController();
final TextEditingController _oldPasswordController = TextEditingController();
final TextEditingController _newPasswordController = TextEditingController();
final TextEditingController _confirmPasswordController = TextEditingController();
// Caisse/magasin : toujours affichés, jamais éditables directement ici — le
// bouton "Changer" (Admin seulement) ouvre ParametreCaisseDialog, seul
// endroit qui modifie réellement la caisse/le magasin actifs.
final TextEditingController _caisseController = TextEditingController();
final TextEditingController _magasinController = TextEditingController();

final GlobalKey<FormState> _monCompteFormKey = GlobalKey<FormState>();

/// Dialog "Mon Compte" (menu du compte, lib/core/widget/account.dart) :
/// permet à l'utilisateur connecté de consulter son code et sa date de
/// dernier accès (lecture seule), modifier son nom d'utilisateur, et
/// changer son mot de passe (ancien / nouveau / confirmation).
Future<void> MonCompteDialog(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredModify,
    );
    return;
  }

  final currentUser = await UtilisateurServices.getUtilisateurByCode(auth.userCode!);
  if (currentUser == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      titre_concerne: l10n.user,
      message: l10n.errorOccurred,
    );
    return;
  }

  _codeController.text = currentUser.code;
  _dernierAccesController.text = _formatDateHeure(currentUser.dernierAcces);
  _usernameController.text = currentUser.username;
  _oldPasswordController.clear();
  _newPasswordController.clear();
  _confirmPasswordController.clear();

  final db = await DbCreator.openDb();
  CaisseParam? caisseParam = await CaisseParamServices(db).getCaisseParamByUserCode(auth.userCode!);
  _caisseController.text = caisseParam?.selectedCaisse ?? '';
  _magasinController.text = caisseParam?.selectedMagasin ?? '';

  final bool peutChangerCaisseCompte = auth.role == "Admin";

  bool changerMotDePasse = false;

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
                width: 950,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/profile_icon.png',
                  text: l10n.myAccount,
                ),

                content: Form(
                  key: _monCompteFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChampAvecLabel(
                                label: l10n.userCode,
                                distance: 200,
                                child: TextChampL(
                                  controller: _codeController,
                                  enabled: false,
                                  hint: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.lastAccess,
                                distance: 200,
                                child: TextChampL(
                                  controller: _dernierAccesController,
                                  enabled: false,
                                  hint: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.username,
                                distance: 200,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: _usernameController,
                                  obligatoire: true,
                                  enabled: true,
                                  hint: l10n.usernameHint,
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.cashRegister,
                                distance: 200,
                                buttonAjout: peutChangerCaisseCompte,
                                onAjoutPressed: !peutChangerCaisseCompte ? null : () async {
                                  if (caisseParam == null) return;
                                  await ParametreCaisseDialog(
                                    context: context,
                                    Param: caisseParam!,
                                    onValider: ({required CaisseParam Param}) async {
                                      setState(() {
                                        caisseParam = Param;
                                        _caisseController.text = Param.selectedCaisse;
                                        _magasinController.text = Param.selectedMagasin;
                                      });
                                    },
                                  );
                                },
                                child: TextChampL(
                                  controller: _caisseController,
                                  enabled: false,
                                  hint: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.magasin,
                                distance: 200,
                                child: TextChampL(
                                  controller: _magasinController,
                                  enabled: false,
                                  hint: "",
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CheckboxListTile(
                                contentPadding: EdgeInsets.zero,
                                controlAffinity: ListTileControlAffinity.leading,
                                activeColor: Appstyle.violet,
                                title: Text(l10n.changePassword, style: Appstyle.textSB),
                                value: changerMotDePasse,
                                onChanged: (value) {
                                  setState(() {
                                    changerMotDePasse = value ?? false;
                                    if (!changerMotDePasse) {
                                      _oldPasswordController.clear();
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                    }
                                  });
                                },
                              ),
                              if (changerMotDePasse) ...[
                                const SizedBox(height: 4),
                                ChampAvecLabel(
                                  distance: 200,
                                  label: l10n.oldPassword,
                                  obligatoire: true,
                                  child: TextChampL(
                                    controller: _oldPasswordController,
                                    obligatoire: true,
                                    obscureText: true,
                                    hint: "",
                                    validator: (value) {
                                      if (value != null &&
                                          value.trim().isNotEmpty &&
                                          _hashPassword(value.trim()) != currentUser.password) {
                                        return l10n.incorrectOldPassword;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  distance: 200,
                                  label: l10n.newPassword,
                                  obligatoire: true,
                                  child: TextChampL(
                                    controller: _newPasswordController,
                                    obligatoire: true,
                                    obscureText: true,
                                    hint: "",
                                    validator: (value) {
                                      if (value != null && value.trim().isNotEmpty && value.trim().length < 4) {
                                        return l10n.passwordTooShort;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  distance: 200,
                                  label: l10n.confirmPassword,
                                  obligatoire: true,
                                  child: TextChampL(
                                    controller: _confirmPasswordController,
                                    obligatoire: true,
                                    obscureText: true,
                                    hint: "",
                                    validator: (value) {
                                      if (value?.trim() != _newPasswordController.text.trim()) {
                                        return l10n.passwordsDoNotMatch;
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
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
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!_monCompteFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.myAccount,
                          message: changerMotDePasse ? l10n.confirmChangePassword : l10n.confirmModifyUser,
                          onConfirmer: () async {
                            final updatedUser = Utilisateur(
                              id: currentUser.id,
                              code: currentUser.code,
                              role: currentUser.role,
                              role_code: currentUser.role_code,
                              etat: currentUser.etat,
                              credit: currentUser.credit,
                              username: _usernameController.text.trim(),
                              password: changerMotDePasse
                                  ? _hashPassword(_newPasswordController.text.trim())
                                  : currentUser.password,
                              telephone: currentUser.telephone,
                              dernierAcces: currentUser.dernierAcces,
                              observation: currentUser.observation,
                              dateCree: currentUser.dateCree,
                              creeParCode: currentUser.creeParCode,
                              modifParCode: auth.userCode,
                              dateModif: DateTime.now(),
                            );

                            final db = await DbCreator.openDb();
                            final services = UtilisateurServices(db);
                            final response = await services.updateUtilisateur(updatedUser);

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.user,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            final serviceh = HistoriqueServices(db);
                            final idH = await _GetNextHistoriqueId();
                            await serviceh.addHistorique(Historique(
                              id: idH,
                              code: "HS$idH${DateTime.now().microsecondsSinceEpoch}",
                              desc: changerMotDePasse
                                  ? "L'utilisateur ${auth.username} a changé son mot de passe"
                                  : "L'utilisateur ${auth.username} a modifié son compte",
                              type: "Utilisateur",
                              oper: ListsConst.typeHisto[1],
                              dateCree: DateTime.now(),
                              creeParCode: auth.userCode!,
                            ));

                            auth.updateUsername(_usernameController.text.trim());

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.user,
                              message: changerMotDePasse ? l10n.passwordChangedSuccess : l10n.userModifiedSuccess,
                              onTerminer: () => Navigator.pop(context),
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
