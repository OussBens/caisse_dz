import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import '../../../../data/models/fournisseur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../Services/Historique.dart';
import '../../../data/models/histore.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<ApiResponse<int>> _saveFournisseur({required Fournisseur fournisseur, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final services = FournisseurServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.addFournisseur(fournisseur);

  // Ajouter l'historique
  if (response.success) {
    int idh = await _getNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Fournisseur",
      desc: "L'utilisateur $userName a ajouté le Fournisseur ${fournisseur.nom}",
      oper: ListsConst.typeHisto[0],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

// Ajouter cette fonction pour obtenir le prochain ID d'historique
Future<int> _getNextHistoriqueId() async {
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
    id = await FournisseurServices.getNextFournisseurId(txn);
  });
  return id;
}

// Controllers
final TextEditingController onbservationControllerF = TextEditingController();
final TextEditingController adresseControllerF      = TextEditingController();
final TextEditingController wilayaControllerF       = TextEditingController();
final TextEditingController emailControllerf        = TextEditingController();
final TextEditingController nomControllerF          = TextEditingController();
final TextEditingController telControllerF          = TextEditingController();

// Non modifiables (infos financières fictives)
final TextEditingController dernierAchatControllerF = TextEditingController();
final TextEditingController totalAchatControllerF   = TextEditingController();
final TextEditingController nbrAchatControllerF     = TextEditingController();
final TextEditingController creditControllerF       = TextEditingController();

// Dropdowns
String? selectedActiviteF = ListsConst.activitesFournisseur.first;
String? selectedTypeF     = ListsConst.typeFournisseur.first;
String? selectedEtatF     = "Actif";

void resetFournisseurForm() {
  onbservationControllerF.clear();
  adresseControllerF.clear();
  wilayaControllerF.clear();
  emailControllerf.clear();
  nomControllerF.clear();
  telControllerF.clear();

  dernierAchatControllerF.text  = "";
  totalAchatControllerF.text    = "0.00";
  nbrAchatControllerF.text      = "0";
  creditControllerF.text        = "0.00";

  selectedActiviteF = ListsConst.activitesFournisseur.first;
  selectedTypeF     = ListsConst.typeFournisseur.first;
  selectedEtatF     = "Actif";
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> FournisseurNouveau(BuildContext context) async {
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

  resetFournisseurForm();
  final id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le fournisseur
  final code = CodeGenerator.generateCode(
    prefix: CodePrefix.fournisseur,
    id: id,
    digitCount: 6, // "FRN000001"
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
                width: 850,
                height: 600,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/fournisseur_icon.png',
                  text: l10n.newSupplier,
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
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.name,
                                      obligatoire: true,
                                      child: TextChampL(
                                        controller: nomControllerF,
                                        hint: l10n.supplierNameHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.phone,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        numeric: true,
                                        controller: telControllerF,
                                        hint: l10n.phoneHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.wilaya,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: wilayaControllerF,
                                        hint: l10n.wilayaHint,
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
                                      child: TextChampL(
                                        controller: adresseControllerF,
                                        hint: l10n.addressHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.email,
                                      child: TextChampL(
                                        controller: emailControllerf,
                                        hint: l10n.emailHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              _section(
                                icon: "assets/icons/info_icon.png",
                                title: l10n.observation,
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.observation,
                                      child: TextChampL(
                                        controller: onbservationControllerF,
                                        hint: l10n.observationHint,
                                        maxLines: 2,
                                      ),
                                    ),
                                    const SizedBox(height: 30),
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
                      onPressed: () {
                        resetFournisseurForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newSupplier,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // Création de l'objet Fournisseur
                        final Nfournisseur = Fournisseur(
                          creeParCode: userCode,
                          observation: onbservationControllerF.text,
                          adresse: adresseControllerF.text,
                          wilaya: wilayaControllerF.text,
                          email: emailControllerf.text,
                          nom: nomControllerF.text,
                          telephone: telControllerF.text,
                          activity: selectedActiviteF!,
                          dateCree: DateTime.now(),
                          type: selectedTypeF!,
                          creePar: userName,
                          etat: true,
                          code: code, // ✅ Code généré automatiquement
                          id: id,
                        );

                        // Appel du service pour enregistrer
                        final response = await _saveFournisseur(
                          fournisseur: Nfournisseur,
                          userName: userName,
                          userCode: userCode,
                        );
                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newSupplier,
                            message: response.message ?? "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        // ✅ Succès
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.newSupplier,
                          message: l10n.createSuccess,
                          onTerminer: () {
                            Navigator.pop(context);
                          },
                        );

                        resetFournisseurForm();
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
  required Widget child,
  required String icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    margin: const EdgeInsets.only(bottom: 20),
    decoration: BoxDecoration(
      border: Border.all(color: Appstyle.grisC, width: 1.5),
      borderRadius: BorderRadius.circular(14),
      color: Appstyle.Tblanc,
    ),
    child: Column(
      children: [
        TitleSmall(
          couleur: Appstyle.Tblue,
          imagePath: icon,
          imageSize: 22,
          opacity: 0.85,
          text: title,
        ),
        const SizedBox(height: 15),
        child,
      ],
    ),
  );
}