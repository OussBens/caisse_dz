import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/Auth/license_tier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/magasin.dart';
import '../../../data/constant.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../Services/Historique.dart';
import '../../../data/models/histore.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

final TextEditingController nomControllerMagN = TextEditingController();
final TextEditingController adresseControllerMagN = TextEditingController();
final TextEditingController observationControllerMagN = TextEditingController();

String magasinCodeApercu = '';

void resetMagasinForm() {
  nomControllerMagN.clear();
  adresseControllerMagN.clear();
  observationControllerMagN.clear();
}

final GlobalKey<FormState> magasinFormKey = GlobalKey<FormState>();

Future<void> MagasinNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  // Défense en profondeur : la gestion multi-magasin est réservée au palier
  // Premium (déjà masquée côté sidebar/router) — on refuse aussi ici au cas
  // où ce dialog serait un jour appelé depuis un autre point d'entrée.
  if (auth.licenseTier != LicenseTier.premium) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.information,
      titre_concerne: AppLocalizations.of(context)!.magasin,
      message: "La gestion multi-magasin n'est pas incluse dans votre offre actuelle.",
    );
    return;
  }

  final int previewId = await _getNextMagasinId();
  magasinCodeApercu = CodeGenerator.generateCode(
    prefix: CodePrefix.magasin,
    id: previewId,
    digitCount: 6,
  );

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
                width: 600,
                height: 520,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.newStore,
                ),
                content: Form(
                  key: magasinFormKey,
                  child: SingleChildScrollView(
                    child: _section(
                      title: l10n.generalInformation,
                      icon: "assets/icons/info_icon.png",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChampAvecLabel(
                            label: l10n.code,
                            child: AffichageChamp(text: magasinCodeApercu),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.name,
                            obligatoire: true,
                            child: TextChampL(
                              obligatoire: true,
                              controller: nomControllerMagN,
                              hint: l10n.storeNameHint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.address,
                            child: TextChampL(
                              controller: adresseControllerMagN,
                              hint: l10n.storeAddressHint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.observation,
                            child: TextChampL(
                              controller: observationControllerMagN,
                              hint: l10n.observationHint,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
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
                        resetMagasinForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      onPressed: () async {
                        if (!magasinFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newStore,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final magasinNomExistant = await MagasinServices.findMagasinByNom(nomControllerMagN.text);
                        if (magasinNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newStore,
                            message: l10n.storeNameHint,
                          );
                          return;
                        }

                        final int id = await _getNextMagasinId();
                        final String code = CodeGenerator.generateCode(
                          prefix: CodePrefix.magasin,
                          id: id,
                          digitCount: 6,
                        );

                        Magasin magasin = Magasin(
                          id: id,
                          code: code,
                          nom: nomControllerMagN.text,
                          adresse: adresseControllerMagN.text,
                          etat: true,
                          observation: observationControllerMagN.text,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                        );

                        final response = await _saveMagasin(magasin: magasin, userName: userName, userCode: userCode);

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newStore,
                            message: response.message ?? "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        resetMagasinForm();

                        await InformationDialog(
                          onTerminer: () {
                            Navigator.pop(context);
                          },
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.newStore,
                          message: l10n.createSuccess,
                        );
                      },
                      color: Appstyle.violet,
                      icon: Icons.save,
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

Future<int> _getNextMagasinId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MagasinServices.getNextMagasinId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _saveMagasin({required Magasin magasin, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final service = MagasinServices(db);
  final serviceh = HistoriqueServices(db);

  final response = await service.addMagasin(magasin);

  if (response.success) {
    int idh = await _getNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Magasin",
      desc: "L'utilisateur $userName a ajouté le Magasin ${magasin.nom}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

Future<int> _getNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Widget _section({
  required String title,
  required String icon,
  required Widget child,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    decoration: BoxDecoration(
      color: Appstyle.Tblanc,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: Appstyle.grisC, width: 1.5),
    ),
    child: Column(
      children: [
        TitleSmall(
          imageSize: 22,
          imagePath: icon,
          textsize: 20,
          text: title,
          couleur: Appstyle.Tblue,
          opacity: 0.85,
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}
