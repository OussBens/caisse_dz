import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import '../../../../data/models/fournisseur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

Future<ApiResponse<int>> _updateFournisseur({required Fournisseur fournisseur}) async {
  final db        = await DbCreator.openDb();
  final services  = FournisseurServices(db);
  return await services.updateFournisseur(fournisseur);
}

// Controllers
final TextEditingController nomControllerF          = TextEditingController();
final TextEditingController telControllerF          = TextEditingController();
final TextEditingController wilayaControllerF       = TextEditingController();
final TextEditingController adresseControllerF      = TextEditingController();
final TextEditingController onbservationControllerF = TextEditingController();
final TextEditingController emailControllerf        = TextEditingController();

// Non modifiables (infos financières)
final TextEditingController creditControllerF       = TextEditingController();
final TextEditingController totalAchatControllerF   = TextEditingController();
final TextEditingController nbrAchatControllerF     = TextEditingController();
final TextEditingController dernierAchatControllerF = TextEditingController();

// Dropdown
String? selectedTypeF;
String? selectedActiviteF;
String? selectedEtatF;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> FournisseurModif(BuildContext context, Fournisseur fournisseur) async {
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

  // Initialisation des controllers
  nomControllerF.text           = fournisseur.nom;
  telControllerF.text           = fournisseur.telephone;
  wilayaControllerF.text        = fournisseur.wilaya ?? "";
  adresseControllerF.text       = fournisseur.adresse ?? "";
  onbservationControllerF.text  = fournisseur.observation ?? "";
  emailControllerf.text         = fournisseur.email ?? "";

  selectedTypeF     = fournisseur.type ?? ListsConst.typeFournisseur.first;
  selectedActiviteF = fournisseur.activity ?? "";
  selectedEtatF     = fournisseur.etat ? "Actif" : "Inactif";

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
                width: 850,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/fournisseur_icon.png',
                  text: l10n.modifySupplier,
                ),
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // ===== COLONNE GAUCHE =====
                        Expanded(
                          child: Column(
                            children: [
                              _section(
                                title: l10n.generalInformation,
                                icon: "assets/icons/info_icon.png",
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.code,
                                      child: AffichageChamp(text: fournisseur.code),
                                    ),
                                    const SizedBox(height: 10),

                                    ChampAvecLabel(
                                      label: l10n.status,
                                      obligatoire: true,
                                      child: TextListe(
                                        value: selectedEtatF,
                                        items: const ["Actif", "Inactif"],
                                        clearable: false,
                                        onChanged: (v) {
                                          setState(() {
                                            selectedEtatF = v ?? "Actif";
                                            fournisseur.etat = selectedEtatF == "Actif";
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.name,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: nomControllerF,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.phone,
                                      obligatoire: true,
                                      child: TextChampL(
                                        numeric: true,
                                        obligatoire: true,
                                        controller: telControllerF,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.wilaya,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: wilayaControllerF,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.supplierType,
                                      child: TextListe(
                                        value: selectedTypeF,
                                        items: ListsConst.typeFournisseur,
                                        onChanged: (v) => setState(() => selectedTypeF = v),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.activity,
                                      child: TextListe(
                                        value: selectedActiviteF,
                                        items: ListsConst.activitesFournisseur,
                                        onChanged: (v) => setState(() => selectedActiviteF = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        // ===== COLONNE DROITE =====
                        Expanded(
                          child: Column(
                            children: [
                              _section(
                                title: l10n.contact,
                                icon: "assets/icons/phone_icon.png",
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.address,
                                      child: TextChampL(controller: adresseControllerF, hint: ''),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.email,
                                      child: TextChampL(controller: emailControllerf, hint: ''),
                                    ),
                                  ],
                                ),
                              ),

                              _section(
                                title: l10n.observation,
                                icon: "assets/icons/info_icon.png",
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.observation,
                                      child: TextChampL(
                                        controller: onbservationControllerF,
                                        maxLines: 2,
                                        hint: l10n.observationHint,
                                      ),
                                    ),
                                  ],
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
                        // ❌ Validation formulaire
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.modifySupplier,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Unicité du nom du fournisseur, en excluant ce fournisseur lui-même.
                        final fournisseurNomExistant = await FournisseurServices.findFournisseurByNom(
                          nomControllerF.text,
                          excludeFournisseurCode: fournisseur.code,
                        );
                        if (fournisseurNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.modifySupplier,
                            message: l10n.supplierNameAlreadyExists,
                          );
                          return;
                        }

                        // ✅ Confirmation utilisateur
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifySupplier,
                          message: l10n.confirmModifyFournisseur,
                          onConfirmer: () async {
                            // Création de l'objet Fournisseur modifié
                            final Ufournisseur = Fournisseur(
                              id: fournisseur.id,
                              code: fournisseur.code,
                              nom: nomControllerF.text,
                              telephone: telControllerF.text,
                              email: emailControllerf.text,
                              etat: selectedEtatF == 'Actif',
                              type: selectedTypeF!,
                              activity: selectedActiviteF!,
                              adresse: adresseControllerF.text,
                              observation: onbservationControllerF.text,
                              wilaya: wilayaControllerF.text,
                              dateCree: fournisseur.dateCree,
                              dateModif: DateTime.now(),
                              modifParCode: userCode,
                              creeParCode: fournisseur.creeParCode,
                            );

                            // Appel du service pour mettre à jour
                            final response = await _updateFournisseur(fournisseur: Ufournisseur);

                            // ❌ ERREUR
                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.modifySupplier,
                                message: response.message ?? "Une erreur est survenue lors de la modification.",
                              );
                              return;
                            }

                            // ✅ Succès
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.modifySupplier,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
                              message: l10n.modifySuccess,
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