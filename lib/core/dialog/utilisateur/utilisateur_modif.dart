import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Role.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../data/constant.dart';
import '../../../../data/models/histore.dart';
import '../information_dialog.dart';

List<Role> rolesTest = [];
List<String> roles = [];
List<CaisseGestion> caissesTest = [];
List<String> caisses = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateUser({
  required Utilisateur user,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await UtilisateurServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.updateUtilisateur(user);

  // ✅ Ajouter l'historique de modification
  if (response.success) {
    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "L'utilisateur $userName a modifié l'utilisateur ${user.username}",
      type: "Utilisateur",
      oper: ListsConst.typeHisto[1], // ✅ Type modification
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

Future<void> loadAllData() async {
  // ✅ Le rôle Admin (unique) ne peut pas être assigné depuis cet écran —
  // voir RoleServices.getAssignableRoles(). Sans effet sur l'utilisateur
  // Admin lui-même : sa modification est bloquée plus haut (voir
  // UtilisateurModif) avant même d'atteindre ce chargement.
  rolesTest = await RoleServices.getAssignableRoles();
  roles = rolesTest.map((c) => c.rolenom).toList();
  caissesTest = await GCServices.getAllCaisses();
  caisses = caissesTest.map((c) => c.nomCaisse).toList();
}

final TextEditingController observationController = TextEditingController();
final TextEditingController usernameController = TextEditingController();
final TextEditingController telephoneController = TextEditingController();

String? selectedRole;
String? selectedEtat;
String? selectedCaisse;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> UtilisateurModif(BuildContext context, Utilisateur user) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
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

  // ✅ L'utilisateur Admin ne peut pas être modifié.
  if (user.role.trim().toLowerCase() == 'admin') {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.modificationImpossible,
      titre_concerne: l10n.user,
      message: l10n.cannotModifyAdminUser,
    );
    return;
  }

  await loadAllData();

  observationController.text = user.observation ?? "";
  usernameController.text = user.username;
  telephoneController.text = user.telephone;

  selectedRole = user.role;
  selectedEtat = user.etat ? l10n.active : l10n.inactive;
  // ✅ Champ caisse obligatoire : si l'utilisateur n'en avait pas encore
  // (anciennes données), on retombe sur la caisse système par défaut.
  selectedCaisse = caissesTest.firstWhereOrNull((c) => c.code == user.caisseCode)?.nomCaisse
      ?? (caisses.contains('Caisse System') ? 'Caisse System' : caisses.firstOrNull);

  // ✅ Initialisation du roleCode avec le code du rôle actuel de l'utilisateur
  // Si l'utilisateur a un rôle, on utilise son code, sinon on prend le premier rôle disponible
  String? rolecode = user.role_code;

  // Si le roleCode est null ou vide, on prend le code du premier rôle de la liste
  if (rolecode == null || rolecode.isEmpty) {
    if (rolesTest.isNotEmpty) {
      final firstRole = rolesTest.first;
      rolecode = firstRole.code;
      selectedRole = firstRole.rolenom; // Met à jour le rôle sélectionné
    } else {
      rolecode = "ADMIN"; // Fallback
    }
  }

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 750,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/profile_icon.png',
                  text: l10n.modifyUser,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChampAvecLabel(
                                label: l10n.status,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  value: selectedEtat,
                                  items: translator.etatDisplayList,
                                  onChanged: (value) {
                                    setState(() => selectedEtat = translator.etatToFrench(value!));
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.user,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: usernameController,
                                  obligatoire: true,
                                  enabled: true,
                                  hint: l10n.usernameHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.phone,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: telephoneController,
                                  obligatoire: true,
                                  numeric: true,
                                  hint: l10n.phoneHint,
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
                              ChampAvecLabel(
                                label: l10n.role,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  value: selectedRole,
                                  items: roles,
                                  onChanged: (value) {
                                    // ✅ Mettre à jour le roleCode avec le code du rôle sélectionné
                                    final selectedRoleObj = rolesTest.firstWhere(
                                          (r) => r.rolenom == value,
                                      orElse: () => rolesTest.first,
                                    );
                                    rolecode = selectedRoleObj.code;
                                    setState(() => selectedRole = value);
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.cashRegister,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  value: selectedCaisse,
                                  items: caisses,
                                  clearable: false,
                                  onChanged: (v) => setState(() => selectedCaisse = v),
                                ),
                              ),

                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationController,
                                  enabled: true,
                                  hint: l10n.observationHint,
                                ),
                              ),
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
                      text: l10n.modify,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Vérifier que rolecode n'est pas null
                        if (rolecode == null || rolecode!.isEmpty) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.selectRole,
                          );
                          return;
                        }

                        // ✅ Unicité du nom d'utilisateur, en excluant cet utilisateur lui-même.
                        final utilisateurNomExistant = await UtilisateurServices.findUtilisateurByUsername(
                          usernameController.text.trim(),
                          excludeUtilisateurCode: user.code,
                        );
                        if (utilisateurNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.usernameAlreadyExists,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.user,
                          message: l10n.confirmModifyUser,
                          onConfirmer: () async {
                            final caisseCode = selectedCaisse == null
                                ? null
                                : caissesTest.firstWhereOrNull((c) => c.nomCaisse == selectedCaisse)?.code;

                            Utilisateur userU = Utilisateur(
                              dernierAcces: user.dernierAcces,
                              telephone: telephoneController.text,
                              dateCree: user.dateCree,
                              username: usernameController.text.trim(),
                              password: user.password,
                              credit: user.credit,
                              code: user.code,
                              role: selectedRole ?? user.role,
                              etat: selectedEtat == l10n.active,
                              id: user.id,
                              observation: observationController.text,
                              modifParCode: userCode,
                              dateModif: DateTime.now(),
                              creeParCode: user.creeParCode,
                              role_code: rolecode!, // ✅ Maintenant non-null
                              caisseCode: caisseCode,
                            );

                            final response = await _UpdateUser(
                              user: userU,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.user,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.user,
                                message: response.message ?? l10n.userModifiedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
                            );
                          },
                        );
                      },
                    )
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