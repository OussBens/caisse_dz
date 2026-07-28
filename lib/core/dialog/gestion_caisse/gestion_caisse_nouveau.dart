import 'dart:ui';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_magasin.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utilis/api_response.dart';
import '../information_dialog.dart';

final TextEditingController codeControllerC = TextEditingController();
final TextEditingController nomCaisseController = TextEditingController();
final TextEditingController soldeInitialController = TextEditingController();
final TextEditingController observationControllerC = TextEditingController();
List<Magasin> magasinsTest = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await GCServices.getNextCaisseId(txn);
  });
  return id;
}

Future<void> _loadAllData() async {
  final service = await MagasinServices.getAllMagasins();
  magasinsTest  = service;
}

Future<ApiResponse<int>> _SaveData({
  required CaisseGestion caisse,
  required String userName,
  required String userCode
}) async {
  final db        = await DbCreator.openDb();
  final services  = await GCServices(db);
  final Hservices = await HistoriqueServices(db);

  final respons = await services.addCaisse(caisse);
  int id = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id          : id,
    code        : CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: id,
    ), // ✅ Utilisation du générateur
    type        : "caisseGestion",
    desc        : "l'utilisateur ${userName} Ajoutee la Caisse ${caisse.nomCaisse}",
    oper        : ListsConst.typeHisto[0],
    dateCree    : DateTime.now(),
    creeParCode : userCode,
  );
  await Hservices.addHistorique(histo);
  return respons;
}

// ================= DROPDOWN =================
String? selectedMagasinC;
String? selectedTypeC = ListsConst.typeCaisse.first;

void resetCaisseForm() {
  codeControllerC.clear();
  nomCaisseController.clear();
  soldeInitialController.clear();
  observationControllerC.clear();

  // Par défaut, sélectionner le premier magasin si la liste existe
  if (magasinsTest.isNotEmpty) {
    selectedMagasinC = magasinsTest.first.nom;
  } else {
    selectedMagasinC = null;
  }
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> CaisseGestionNouveau(BuildContext context) async {
  await _loadAllData();

  // Si aucun magasin, on peut afficher un message ou ne pas ouvrir le dialog
  if (magasinsTest.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.noStoreAvailable),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  if (magasinsTest.isNotEmpty) {
    selectedMagasinC = magasinsTest.first.nom;
  }

  final auth = Provider.of<AuthState>(context, listen: false);
  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour la caisse
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.caisse,
    id: id,
    digitCount: 6, // "CS000001"
  );

  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.loginRequired),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // Sélectionner le premier magasin par défaut
  selectedMagasinC = magasinsTest.first.nom;
  String magasincode = magasinsTest.first.code;

  resetCaisseForm();
  codeControllerC.text = code; // ✅ Afficher le code généré

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
                height: 400,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.newCashRegister,
                ),

                // ================= CONTENT =================
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ────────────── COLONNE GAUCHE ──────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// CODE (grisé)
                              ChampAvecLabel(
                                label: l10n.code,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: codeControllerC,
                                  hint: l10n.codeAutoGenerated,
                                  enabled: false,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// NOM CAISSE
                              ChampAvecLabel(
                                label: l10n.cashRegisterName,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: nomCaisseController,
                                  hint: l10n.cashRegisterNameHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// MAGASIN
                              ChampAvecLabel(
                                label: l10n.store,
                                buttonAjout: true,
                                obligatoire: true,
                                onAjoutPressed: () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionMagasinDialog(
                                        magasins: magasinsTest,
                                        onMagasinSelected: (magasin) {
                                          setState(() {
                                            selectedMagasinC  = magasin.nom;
                                            magasincode       = magasin.code;
                                          });
                                        },
                                        multiselection: false,
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedMagasinC ?? "",
                                  items: magasinsTest.map((c) => c.nom).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedMagasinC  = v;
                                      magasincode       = magasinsTest.where((c) => c.nom == v).first.code;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.type,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedTypeC == "physique" ? l10n.physical : l10n.account,
                                  items: [l10n.physical, l10n.account],
                                  onChanged: (v) {
                                    setState(() {
                                      selectedTypeC = v == l10n.physical ? "physique" : "compte";
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // ────────────── COLONNE DROITE ──────────────
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              /// SOLDE INITIAL
                              ChampAvecLabel(
                                label: "${l10n.initialBalance} (${l10n.currency})",
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  numeric: true,
                                  controller: soldeInitialController,
                                  hint: l10n.initialBalanceHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// OBSERVATION (facultatif)
                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerC,
                                  hint: l10n.observationHint,
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ================= FOOTER =================
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () {
                        resetCaisseForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        // Validation des champs obligatoires
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.cashRegisterDetail,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // Création du nouvel objet CaisseGestion
                        CaisseGestion NCaisse = CaisseGestion(
                          id: id,
                          etat: true,
                          code: code, // ✅ Code généré automatiquement
                          dateCree: DateTime.now(),
                          nomCaisse: nomCaisseController.text,
                          typecaisse: selectedTypeC == "physique" ? "physique" : "compte",
                          magasinCode: magasincode,
                          creeParCode: userCode,
                          observation: observationControllerC.text,
                          soldeInitial: double.parse(soldeInitialController.text),
                        );

                        // Appel du service pour enregistrer la caisse
                        final response = await _SaveData(
                          caisse: NCaisse,
                          userName: userName,
                          userCode: userCode,
                        );

                        if (!response.success) {
                          // ❌ Erreur
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.cashRegisterDetail,
                            message: response.message ?? "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        // ✅ Succès
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.cashRegisterDetail,
                          message: l10n.createSuccess,
                          onTerminer: () {
                            Navigator.pop(context);
                          },
                        );

                        resetCaisseForm();
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