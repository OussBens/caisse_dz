import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
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
  // true depuis « Mon compte » : choix de la caisse (et donc du magasin) en
  // plus du colis ; false depuis la Caisse : « Paramètres de vente », colis
  // uniquement.
  bool choixCaisse = false,
}) async {
  List<CaisseGestion> caisseTest = [];
  List<Magasin> magasinsTest = [];

  Future<void> _LoadAllData() async {
    final db = await DbCreator.openDb();
    caisseTest = await GCServices.getAllCaisses();
    magasinsTest = await MagasinServices.getAllMagasins();
  }
  await _LoadAllData();

  // ✅ Multi-magasin : une caisse n'a plus de magasin. Le magasin de travail
  // est le magasin principal de l'utilisateur (utilisateur_magasin, voir
  // AuthState.magasinPrincipal) — c'est lui qu'utilisent les ventes en
  // attendant leur répartition sur tous ses magasins (RepartitionStock).
  final authMagasin = Provider.of<AuthState>(context, listen: false);
  String? _nomMagasinPrincipal() =>
      magasinsTest.where((m) => m.code == authMagasin.magasinPrincipal).firstOrNull?.nom;

  void _synchroniserMagasin(String? nomCaisse) {
    final caisse = caisseTest.where((c) => c.nomCaisse == nomCaisse).firstOrNull;
    // Le code de caisse suit aussi le nom choisi (il restait sur l'ancienne
    // caisse : nom « Caisse 2 » enregistré avec le code de Caisse System).
    Param.caisseCode = caisse?.code ?? Param.caisseCode;
    Param.magasinCode = authMagasin.magasinPrincipal;
    Param.selectedMagasin = _nomMagasinPrincipal() ?? Param.selectedMagasin;
  }

  String? caisseSelectionnee = Param.selectedCaisse;

  // Stocker la clé, pas la valeur d'affichage
  String? colisKey = Param.selectedColis ?? ColisTranslator.UNITE;

  String? erreur;

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;

  // ✅ Admin ou rôle avec la permission spéciale "changerCaisseMagasin"
  // peut choisir librement la caisse ici : les autres rôles sont verrouillés
  // sur la caisse attachée à leur compte (Utilisateur.caisseCode, cf.
  // utilisateur_nouveau/modif).
  final bool peutChangerCaisse = auth.canChangerCaisseMagasin;
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
  final caisseCodeInitial = Param.caisseCode;
  final magasinCodeInitial = Param.magasinCode;

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
                height: choixCaisse ? 420 : 300,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: choixCaisse ? l10n.cashRegisterSettings : l10n.saleSettings,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Depuis la Caisse : colis uniquement (la caisse vient du
                    // compte). Depuis « Mon compte » : choix de la caisse —
                    // verrouillé pour un rôle sans « changerCaisseMagasin ».
                    if (choixCaisse) ...[
                      ChampAvecLabel(
                        label: l10n.cashRegister,
                        obligatoire: true,
                        child: TextListe(
                          value: caisseSelectionnee,
                          items: caisseTest.map((c) => c.nomCaisse).toList(),
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
                      const SizedBox(height: 10),
                      // Magasin principal de l'utilisateur (lecture seule : il
                      // se règle dans l'écran Utilisateur, pas sur la caisse).
                      ChampAvecLabel(
                        label: l10n.magasin,
                        child: TextChampL(
                          controller: TextEditingController(
                            text: _nomMagasinPrincipal() ?? '',
                          ),
                          enabled: false,
                          hint: "",
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
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
                        if ((caisseSelectionnee ?? '').isEmpty ||
                            (colisKey ?? '').isEmpty) {
                          setState(() => erreur = l10n.allFieldsRequired);
                          return;
                        }
                        final response = await _SaveParam(
                            userName: userName!,
                            userCode: userCode!,
                            Param: Param
                        );
                        if (response.success) {
                          // Le magasin du paramètre utilisateur (Paramètres >
                          // Utilisateur) suit le magasin de la caisse choisie.
                          final magasin = magasinsTest
                              .where((m) => m.code == Param.magasinCode)
                              .firstOrNull;
                          if (magasin != null && auth.currentMagasin != magasin.nom) {
                            await auth.updateUserParameters(
                              language: auth.currentLanguage ?? 'fr',
                              currency: auth.currentCurrency ?? 'DZD',
                              magasin: magasin.nom,
                              magasinId: magasin.id.toString(),
                              modifiedBy: userName!,
                              modifiedByCode: userCode!,
                              reason: "Changement de caisse/magasin (paramètres caisse)",
                            );
                          }
                          // Caisse ou magasin changé : l'écran affiché se recharge
                          // (AppShell, AuthState.contexteVersion).
                          if (Param.caisseCode != caisseCodeInitial ||
                              Param.magasinCode != magasinCodeInitial) {
                            auth.signalerChangementCaisseMagasin();
                          }
                          if (!context.mounted) return;
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