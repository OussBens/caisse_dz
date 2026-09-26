import 'dart:convert';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Role.dart' hide ApiResponse;
import 'package:caisse_dz/Services/UserParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:caisse_dz/data/models/userparam.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import '../../../Services/Historique.dart';
import '../../../data/models/histore.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import 'package:crypto/crypto.dart';
import '../information_dialog.dart';

List<Role> RoleTest = [];
List<String> roles = [];
List<CaisseGestion> CaisseTestN = [];
List<String> caissesN = [];

Future<void> loadAllData() async {
  // ✅ Un nouvel utilisateur ne peut pas se voir assigner le rôle Admin
  // (unique) : il faut d'abord créer un rôle dédié depuis l'écran Rôles.
  RoleTest = await RoleServices.getAssignableRoles();
  roles = RoleTest.map((c) => c.rolenom).toList();
  CaisseTestN = await GCServices.getAllCaisses();
  caissesN = CaisseTestN.map((c) => c.nomCaisse).toList();
}

// Modifier _SaveUtilisateur
Future<ApiResponse<int>> _SaveUtilisateur({required Utilisateur utilisateur, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final services = await UtilisateurServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.addUtilisateur(utilisateur);

  // Ajouter l'historique
  if (response.success) {
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Utilisateur",
      desc: "L'utilisateur $userName a ajouté l'Utilisateur ${utilisateur.username}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  // Le reste du code pour UserParam...
  // caisse_dz est mono-magasin : tout utilisateur est rattaché au magasin système.
  UserParam userparam = UserParam(
      id: await _GetNextUPOId(),
      nom: utilisateur.username,
      magasin: 'Magasin System',
      magasinid: '1',
      language: 'fr',
      currency: 'DZD',
      creeParCode: utilisateur.creeParCode,
      creeLe: DateTime.now()
  );
  final servicep  = UserParamServices(db);
  await servicep.addUserParam(userparam, utilisateur.creeParCode, utilisateur.creeParCode);

  return response;
}

// Ajouter cette fonction
Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}
Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await UtilisateurServices.getNextUtilisateurId(txn);
  });
  return id;
}

Future<int> _GetNextUPOId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await UserParamServices.getNextUPId(txn);
  });
  return id;
}


final TextEditingController observationControllerN = TextEditingController();
final TextEditingController usernameControllerN = TextEditingController();
final TextEditingController passwordControllerN = TextEditingController();
final TextEditingController telControllerN = TextEditingController();

String? selectedRoleN = roles.firstOrNull;
String? selectedEtatN = "actif";
String? selectedCaisseN;

// Nom de la caisse système, toujours présente en base (seedée dans
// DBCreate.dart), utilisée comme valeur par défaut obligatoire du champ
// caisse pour tout nouvel utilisateur.
const String _caisseSystemNom = 'Caisse System';

void resetUtilisateurForm() {
  usernameControllerN.clear();
  observationControllerN.clear();
  passwordControllerN.clear();
  telControllerN.clear();

  selectedRoleN = roles.firstOrNull;
  selectedEtatN = "actif";
  selectedCaisseN = caissesN.contains(_caisseSystemNom) ? _caisseSystemNom : caissesN.firstOrNull;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

// Hash password using the same method as AuthState
String hashPassword(String password) {
  const String salt = 'SYSTEM_SALT';
  final bytes = utf8.encode(password + salt);
  return sha256.convert(bytes).toString();
}

Future<void> UtilisateurNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  await loadAllData();
  int id = await _GetNextId();
  String rolecode = '';

  // ✅ Champ caisse obligatoire, initialisé avec la caisse système.
  selectedCaisseN = caissesN.contains(_caisseSystemNom) ? _caisseSystemNom : caissesN.firstOrNull;

  // ✅ Initialiser rolecode avec le code du premier rôle
  if (RoleTest.isNotEmpty) {
    final firstRole = RoleTest.first;
    selectedRoleN = firstRole.rolenom;
    rolecode = firstRole.code; // ✅ "ADMIN" ou autre
  } else {
    selectedRoleN = null;
    rolecode = '';
  }

  // ✅ Utilisation du générateur de code pour l'utilisateur
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.utilisateur,
    id: id,
    digitCount: 6, // "USR000001"
  );

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
                width: 850,
                height: 380,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/profile_icon.png',
                  text: l10n.newUser,
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
                                label: l10n.code,
                                child: TextChampL(
                                  enabled: false,
                                  controller: TextEditingController(text: code),
                                  hint: "",
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.user,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: usernameControllerN,
                                  hint: l10n.usernameHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.password,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: passwordControllerN,
                                  hint: "********",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.phone,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  numeric: true,
                                  controller: telControllerN,
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
                                  value: selectedRoleN,
                                  items: roles,
                                  onChanged: (v) => setState(() {
                                    selectedRoleN = v;
                                    rolecode = RoleTest.where((u) => u.rolenom == v).first.code;
                                  }),
                                ),
                              ),

                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.cashRegister,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  value: selectedCaisseN,
                                  items: caissesN,
                                  clearable: false,
                                  onChanged: (v) => setState(() => selectedCaisseN = v),
                                ),
                              ),

                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerN,
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
                      onPressed: () {
                        resetUtilisateurForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
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

                        // ✅ Retirer les espaces superflus : AuthState.login()
                        // trim() le nom d'utilisateur et le mot de passe
                        // avant de les comparer/hasher — un espace en trop
                        // enregistré ici (ex. saisie/collage accidentel)
                        // empêcherait alors définitivement la connexion.
                        final trimmedUsername = usernameControllerN.text.trim();
                        final trimmedPassword = passwordControllerN.text.trim();

                        // Validate password length
                        if (trimmedPassword.length < 4) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.passwordTooShort ?? "Password must be at least 4 characters",
                          );
                          return;
                        }

                        // ✅ Unicité du nom d'utilisateur avant toute création.
                        final utilisateurNomExistant = await UtilisateurServices.findUtilisateurByUsername(trimmedUsername);
                        if (utilisateurNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.user,
                            message: l10n.usernameAlreadyExists,
                          );
                          return;
                        }

                        // Hash password using the same method as AuthState
                        final hashedPassword = hashPassword(trimmedPassword);

                        final caisseCode = selectedCaisseN == null
                            ? null
                            : CaisseTestN.where((c) => c.nomCaisse == selectedCaisseN).firstOrNull?.code;

                        Utilisateur user = Utilisateur(
                          dernierAcces  : DateTime.now(),
                          observation   : observationControllerN.text,
                          telephone     : telControllerN.text,
                          dateCree      : DateTime.now(),
                          username      : trimmedUsername,
                          password      : hashedPassword, // ✅ Using the same hashing as AuthState
                          credit        : 0,
                          code          : code,
                          role          : selectedRoleN!,
                          etat          : true,
                          id            : id,
                          role_code     : rolecode,
                          caisseCode    : caisseCode,
                          creeParCode   : userCode,
                        );

                        final response = await _SaveUtilisateur(utilisateur: user, userName: userName, userCode: userCode);
                        print(response.message);
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
                            message: response.message ?? l10n.userSavedSuccess,
                            onTerminer: () {
                              Navigator.pop(context);
                            }
                        );

                        resetUtilisateurForm();
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