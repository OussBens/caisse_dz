import 'dart:ui';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';

import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/data/models/magasin.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';

import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';

import '../../utilis/api_response.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

// Controllers
final TextEditingController codeControllerM = TextEditingController();
final TextEditingController nomCaisseControllerM = TextEditingController();
final TextEditingController soldeInitialControllerM = TextEditingController();
final TextEditingController observationControllerM = TextEditingController();
String? selectedTypeC ;

// Dropdowns
String? selectedEtatM;
String? selectedMagasinCodeM;
List<Magasin> magasinsDisponiblesM = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveData({
  required CaisseGestion caisse,
  required String userName,
  required String userCode
}) async {
  final db        = await DbCreator.openDb();
  final services  = await GCServices(db);
  final Hservices = await HistoriqueServices(db);

  final respons   = await services.updateCaisse(caisse);
  int   id        = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id          : id,
    dateCree    : DateTime.now(),
    creeParCode : userCode,
    type        : "caisseGestion",
    oper        : ListsConst.typeHisto[1],
    code        : "HS$id${DateTime.now().microsecondsSinceEpoch}",
    desc        : "l'utilisateur ${userName} Modife la Caisse ${caisse.nomCaisse}",
  );
  await Hservices.addHistorique(histo);
  return respons;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> CaisseGestionModif(BuildContext context, CaisseGestion caisse) async {
  final auth = Provider.of<AuthState>(context, listen: false);
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

  // Pré-remplissage
  codeControllerM.text = caisse.code;
  nomCaisseControllerM.text = caisse.nomCaisse;
  soldeInitialControllerM.text = caisse.soldeInitial.toString();
  observationControllerM.text = caisse.observation ?? "";
  selectedEtatM = caisse.etat ? "Actif" : "Inactif";
  selectedTypeC = caisse.typecaisse;

  magasinsDisponiblesM = (await MagasinServices.getAllMagasins()).where((m) => m.etat).toList();
  selectedMagasinCodeM = magasinsDisponiblesM.any((m) => m.code == caisse.magasinCode)
      ? caisse.magasinCode
      : (magasinsDisponiblesM.isNotEmpty ? magasinsDisponiblesM.first.code : caisse.magasinCode);

  if (!context.mounted) return;

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
                height: 450,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.modifyCashRegister,
                ),

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
                                  obligatoire: true,
                                  controller: codeControllerM,
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
                                  controller: nomCaisseControllerM,
                                  hint: l10n.cashRegisterNameHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.type,
                                obligatoire: true,
                                child: TextListe(
                                  clearable: false,
                                  obligatoire: true,
                                  value: selectedTypeC,
                                  items: [l10n.physical, l10n.account],
                                  onChanged: (v) {
                                    setState(() {
                                      selectedTypeC = v == l10n.physical ? "physique" : "compte";
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Magasin de rattachement — modifiable ici
                              // maintenant (auparavant figé à vie sur le
                              // magasin choisi à la création).
                              ChampAvecLabel(
                                label: l10n.magasin,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: magasinsDisponiblesM
                                      .firstWhere(
                                        (m) => m.code == selectedMagasinCodeM,
                                        orElse: () => Magasin(
                                          id: 0, code: '', nom: '', etat: true,
                                          dateCree: DateTime.now(), creeParCode: userCode,
                                        ),
                                      )
                                      .nom,
                                  items: magasinsDisponiblesM.map((m) => m.nom).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedMagasinCodeM = magasinsDisponiblesM
                                          .firstWhere((m) => m.nom == v)
                                          .code;
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
                                  controller: soldeInitialControllerM,
                                  obligatoire: true,
                                  numeric: true,
                                  hint: l10n.initialBalanceHint,
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// ÉTAT
                              ChampAvecLabel(
                                label: l10n.status,
                                obligatoire: true,
                                child: TextListe(
                                  value: selectedEtatM,
                                  clearable: false,
                                  items: [l10n.active, l10n.inactive],
                                  onChanged: (v) => setState(() => selectedEtatM = v),
                                ),
                              ),
                              const SizedBox(height: 10),

                              /// OBSERVATION
                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerM,
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

                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.modify,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        // ❌ Validation des champs obligatoires
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.cashRegisterDetail,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Confirmation utilisateur
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyCashRegister,
                          message: l10n.confirmModifyCaisse,
                          onConfirmer: () async {
                            // Création de l'objet CaisseGestion mis à jour
                            CaisseGestion NCaisse = CaisseGestion(
                              id: caisse.id,
                              etat: selectedEtatM == l10n.active,
                              code: caisse.code,
                              modifParCode: userCode,
                              dateCree: caisse.dateCree,
                              dateModif: DateTime.now(),
                              nomCaisse: nomCaisseControllerM.text,
                              typecaisse: selectedTypeC == l10n.physical ? "physique" : "compte",
                              magasinCode: selectedMagasinCodeM ?? caisse.magasinCode,
                              creeParCode: caisse.creeParCode,
                              observation: observationControllerM.text,
                              soldeInitial: double.tryParse(soldeInitialControllerM.text) ?? 0,
                            );

                            // Appel du service pour modifier la caisse
                            final response = await _SaveData(
                              caisse: NCaisse,
                              userName: userName,
                              userCode: userCode,
                            );

                            // ❌ ERREUR
                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.cashRegisterDetail,
                                message: response.message ?? "Une erreur est survenue lors de la modification.",
                              );
                              return;
                            }

                            // ✅ Succès
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.cashRegisterDetail,
                              message: l10n.modifySuccess,
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