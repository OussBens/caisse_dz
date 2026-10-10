import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/constant.dart';
import '../../../data/models/magasin.dart';
import '../../../data/models/histore.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<int> _getNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _updateMagasin({
  required Magasin magasin,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = MagasinServices(db);
  final serviceh = HistoriqueServices(db);

  final response = await services.updateMagasin(magasin);

  if (response.success) {
    final int idH = await _getNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: CodeGenerator.generateCodeWithTimestamp(prefix: CodePrefix.historique, id: idH),
      desc: "L'utilisateur $userName a modifié le magasin ${magasin.nom}",
      type: "Magasin",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

final TextEditingController nomControllerMagM = TextEditingController();
final TextEditingController adresseControllerMagM = TextEditingController();
final TextEditingController observationControllerMagM = TextEditingController();

String? selectedEtatMag;

final GlobalKey<FormState> magasinModifFormKey = GlobalKey<FormState>();

Future<void> MagasinModif(BuildContext context, Magasin magasin) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      kind: DialogKind.refuser,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  nomControllerMagM.text = magasin.nom;
  adresseControllerMagM.text = magasin.adresse ?? "";
  observationControllerMagM.text = magasin.observation ?? "";
  selectedEtatMag = magasin.etat ? "Actif" : "Inactif";

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
                height: 560,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.modifyStore,
                ),
                content: Form(
                  key: magasinModifFormKey,
                  child: SingleChildScrollView(
                    child: _section(
                      title: l10n.generalInformation,
                      icon: "assets/icons/info_icon.png",
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ChampAvecLabel(
                            label: l10n.code,
                            child: AffichageChamp(text: magasin.code),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.status,
                            obligatoire: true,
                            child: TextListe(
                              value: selectedEtatMag,
                              items: const ["Actif", "Inactif"],
                              clearable: false,
                              onChanged: (v) => setState(() => selectedEtatMag = v ?? "Actif"),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.name,
                            obligatoire: true,
                            child: TextChampL(
                              obligatoire: true,
                              controller: nomControllerMagM,
                              hint: l10n.storeNameHint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.address,
                            child: TextChampL(
                              controller: adresseControllerMagM,
                              hint: l10n.storeAddressHint,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.observation,
                            child: TextChampL(
                              controller: observationControllerMagM,
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.modify,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!magasinModifFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.modifyStore,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        Magasin magasinU = Magasin(
                          id: magasin.id,
                          code: magasin.code,
                          nom: nomControllerMagM.text,
                          adresse: adresseControllerMagM.text,
                          etat: selectedEtatMag == 'Actif',
                          observation: observationControllerMagM.text,
                          dateCree: magasin.dateCree,
                          creeParCode: magasin.creeParCode,
                          dateModif: DateTime.now(),
                          modifParCode: userCode,
                        );

                        final response = await _updateMagasin(
                          magasin: magasinU,
                          userName: userName,
                          userCode: userCode,
                        );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.modifyStore,
                            message: response.message ?? "Une erreur est survenue lors de la modification.",
                          );
                          return;
                        }

                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.modifyStore,
                          onTerminer: () {
                            Navigator.pop(context);
                          },
                          message: l10n.modifySuccess,
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
      borderRadius: BorderRadius.circular(Appstyle.radiusButton),
      border: Border.all(color: Appstyle.grisC, width: 1.5),
    ),
    child: Column(
      children: [
        TitleSmall(
          textsize: 20,
          imageSize: 22,
          imagePath: icon,
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
