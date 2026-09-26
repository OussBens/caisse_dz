import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:provider/provider.dart';

import '../../../data/models/caisseParam.dart';
import '../../utilis/api_response.dart';
import '../../utilis/colis_translator.dart';

Future<ApiResponse<int>> _SaveParam({
  required CaisseParam Param,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = CaisseParamServices(db);

  Param.dateModif = DateTime.now();
  Param.modifParCode = userCode;
  final response = await services.updateCaisseParam(Param);

  return response;
}

Future<void> ParametreCaisseDialog({
  required BuildContext context,
  required CaisseParam Param,
  required Function({
  required CaisseParam Param,
  }) onValider,
}) async {
  List<CaisseGestion> caisseTest = [];
  List<Magasin> magasinsTest = [];

  Future<void> _LoadAllData() async {
    final db = await DbCreator.openDb();
    caisseTest = await GCServices.getAllCaisses();
    magasinsTest = await MagasinServices.getAllMagasins();
  }
  await _LoadAllData();

  // ✅ Le magasin n'est jamais choisi indépendamment : il suit toujours la
  // caisse sélectionnée (CaisseGestion.magasinCode). Corrige un bug où
  // changer de caisse ici ne rafraîchissait pas Param.magasinCode/
  // selectedMagasin, laissant le magasin utilisé par le reste de l'app
  // obsolète après un changement de caisse.
  String? _nomMagasinDeLaCaisse(String? nomCaisse) {
    final caisse = caisseTest.where((c) => c.nomCaisse == nomCaisse).firstOrNull;
    if (caisse == null) return null;
    return magasinsTest.where((m) => m.code == caisse.magasinCode).firstOrNull?.nom;
  }

  void _synchroniserMagasin(String? nomCaisse) {
    final caisse = caisseTest.where((c) => c.nomCaisse == nomCaisse).firstOrNull;
    Param.magasinCode = caisse?.magasinCode ?? Param.magasinCode;
    Param.selectedMagasin = _nomMagasinDeLaCaisse(nomCaisse) ?? Param.selectedMagasin;
  }

  bool caisseDefault = Param.caisseParDefaut;

  String? caisseSelectionnee = Param.selectedCaisse;

  // Stocker la clé, pas la valeur d'affichage
  String? colisKey = Param.selectedColis ?? ColisTranslator.UNITE;

  String? erreur;

  final List<String> listeCaisses = caisseTest.map((caisse) => caisse.nomCaisse).toList();

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;

  // ✅ Seul le rôle Admin peut choisir librement la caisse ici : les autres
  // rôles sont verrouillés sur la caisse attachée à leur compte
  // (Utilisateur.caisseCode, cf. utilisateur_nouveau/modif).
  final bool peutChangerCaisse = auth.role == "Admin";
  if (!peutChangerCaisse && auth.userCaisseCode != null) {
    final caisseAttachee = caisseTest
        .where((c) => c.code == auth.userCaisseCode)
        .firstOrNull
        ?.nomCaisse;
    if (caisseAttachee != null) {
      caisseSelectionnee = caisseAttachee;
      Param.selectedCaisse = caisseAttachee;
    }
  }
  // ✅ Toujours resynchroniser le magasin sur la caisse effective (verrouillée
  // ou librement choisie), y compris à l'ouverture du dialog.
  _synchroniserMagasin(caisseSelectionnee);

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          // Obtenir la valeur d'affichage actuelle à partir de la clé
          String colisDisplayValue = ColisTranslator.getDisplayValue(colisKey, context);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 600,
                height: 650,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.cashRegisterSettings,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ▸ Radio Caisse par défaut
                    Text(l10n.defaultCashRegister, style: Appstyle.textSB),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text(l10n.yes),
                            value: true,
                            groupValue: caisseDefault,
                            onChanged: (v) => setState(() {
                              caisseDefault = v!;
                              Param.caisseParDefaut = v;
                            }),
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<bool>(
                            title: Text(l10n.no),
                            value: false,
                            groupValue: caisseDefault,
                            onChanged: (v) => setState(() {
                              caisseDefault = v!;
                              Param.caisseParDefaut = v;
                            }),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),

                    // ▸ Liste déroulante Caisse — verrouillée pour tout rôle
                    // autre que Admin (cf. peutChangerCaisse ci-dessus).
                    ChampAvecLabel(
                      label: l10n.cashRegister,
                      obligatoire: true,
                      child: TextListe(
                        value: caisseSelectionnee,
                        items: listeCaisses,
                        clearable: false,
                        enabled: peutChangerCaisse,
                        onChanged: (v) {
                          setState(() {
                            caisseSelectionnee = v;
                            Param.selectedCaisse = v!;
                            _synchroniserMagasin(v);
                          });
                        },
                      ),
                    ),
                    if (!peutChangerCaisse) ...[
                      const SizedBox(height: 6),
                      Text(
                        l10n.cashRegisterLockedToUser,
                        style: Appstyle.textXS.copyWith(color: Appstyle.gris),
                      ),
                    ],
                    const SizedBox(height: 10),

                    // ▸ Magasin — jamais choisi indépendamment, toujours
                    // dérivé de la caisse sélectionnée ci-dessus.
                    ChampAvecLabel(
                      label: l10n.magasin,
                      child: TextChampL(
                        controller: TextEditingController(
                          text: _nomMagasinDeLaCaisse(caisseSelectionnee) ?? '',
                        ),
                        enabled: false,
                        hint: "",
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ▸ Liste déroulante Colis - CORRIGÉ
                    ChampAvecLabel(
                      label: l10n.parcel,
                      obligatoire: true,
                      child: TextListe(
                        value: colisDisplayValue, // Affiche la traduction
                        items: ColisTranslator.getDisplayList(context), // Liste traduite
                        clearable: false,
                        onChanged: (displayValue) {
                          if (displayValue != null) {
                            // Convertir l'affichage en clé pour le stockage
                            final newKey = ColisTranslator.getKeyFromDisplay(displayValue, context);
                            setState(() {
                              colisKey = newKey;
                              Param.selectedColis = newKey; // Stocke la clé (unite/small/large)
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (erreur != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        erreur!,
                        style: Appstyle.textS.copyWith(color: Colors.red),
                      ),
                    ],
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
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (caisseSelectionnee!.isEmpty ||
                            colisKey!.isEmpty) {
                          setState(() => erreur = l10n.allFieldsRequired);
                          return;
                        }
                        final response = await _SaveParam(
                            userName: userName!,
                            userCode: userCode!,
                            Param: Param
                        );
                        if (response.success) {
                          if (onValider != null) {
                            onValider(Param: Param);
                          }
                          Navigator.pop(context);
                        } else {
                          setState(() => erreur = response.message);
                        }
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