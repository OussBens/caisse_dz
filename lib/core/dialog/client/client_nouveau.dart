import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import '../../../../data/models/client.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../Services/Historique.dart';
import '../../../data/models/histore.dart';
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

// ✅ NE PAS APPELER _GetNextId() ICI
// L'ID sera généré au moment de la sauvegarde

// Controllers
final TextEditingController nomControllerN = TextEditingController();
final TextEditingController telControllerN = TextEditingController();
final TextEditingController wilayaControllerN = TextEditingController();
final TextEditingController adresseControllerN = TextEditingController();
final TextEditingController montantControllerN = TextEditingController();
final TextEditingController emailControllerN   = TextEditingController();
final TextEditingController faxControllerN     = TextEditingController();

final TextEditingController nifControllerN     = TextEditingController();
final TextEditingController nisControllerN     = TextEditingController();
final TextEditingController nrcControllerN     = TextEditingController();

final TextEditingController ribControllerN     = TextEditingController();
final TextEditingController banqueControllerN  = TextEditingController();
final TextEditingController onbservationControllerN  = TextEditingController();

// Dropdowns
String? selectedTypeN = ListsConst.typeClient.first;
String? selectedActiviteN = ListsConst.activitesClient.first;

// ✅ Aperçu du code qui sera généré à la sauvegarde (l'id réel est refetché
// au moment du save, voir _getNextClientId plus bas — l'aperçu ne verrouille rien).
String clientCodeApercu = '';

void resetClientForm() {
  nomControllerN.clear();
  telControllerN.clear();
  wilayaControllerN.clear();
  adresseControllerN.clear();
  emailControllerN.clear();
  faxControllerN.clear();
  nifControllerN.clear();
  nisControllerN.clear();
  nrcControllerN.clear();
  ribControllerN.clear();
  banqueControllerN.clear();
  onbservationControllerN.clear();
  montantControllerN.text = "0.00";
  selectedTypeN = ListsConst.typeClient.first;
  selectedActiviteN = ListsConst.activitesClient.first;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> ClientNouveau(BuildContext context) async {
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

  // ✅ NE PAS APPELER _GetNextId() ICI (l'id réel est refetché à la sauvegarde)
  selectedTypeN = ListsConst.typeClient.first;
  selectedActiviteN = ListsConst.activitesClient.first;

  // ✅ Aperçu uniquement : n'affecte pas l'id réellement utilisé à la sauvegarde
  final int previewId = await _getNextClientId();
  clientCodeApercu = CodeGenerator.generateCode(
    prefix: CodePrefix.client,
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
                width: 850,
                height: 800,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/client_icon.png',
                  text: l10n.newClient,
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
                                      child: AffichageChamp(text: clientCodeApercu),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.name,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: nomControllerN,
                                        hint: l10n.clientNameHint,
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
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.wilaya,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: wilayaControllerN,
                                        hint: l10n.wilayaHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.clientType,
                                      child: TextListe(
                                        value: selectedTypeN,
                                        items: ListsConst.typeClient,
                                        onChanged: (v) => setState(() => selectedTypeN = v),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.activity,
                                      child: TextListe(
                                        value: selectedActiviteN,
                                        items: ListsConst.activitesClient,
                                        onChanged: (v) => setState(() => selectedActiviteN = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              _section(
                                title: l10n.contact,
                                icon: "assets/icons/phone_icon.png",
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.address,
                                      child: TextChampL(
                                        controller: adresseControllerN,
                                        hint: l10n.addressHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.email,
                                      child: TextChampL(
                                        controller: emailControllerN,
                                        hint: l10n.emailHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.fax,
                                      child: TextChampL(
                                        numeric: true,
                                        controller: faxControllerN,
                                        hint: l10n.faxHint,
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
                                title: l10n.administrativeInformation,
                                icon: "assets/icons/admin_icon.png",
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: "NIF",
                                      child: TextChampL(
                                        controller: nifControllerN,
                                        hint: l10n.nifHint,
                                        numeric: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: "NIS",
                                      child: TextChampL(
                                        controller: nisControllerN,
                                        hint: l10n.nisHint,
                                        numeric: true,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: "NRC",
                                      child: TextChampL(
                                        controller: nrcControllerN,
                                        hint: l10n.nrcHint,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              _section(
                                title: l10n.bankingInformation,
                                icon: "assets/icons/bank_icon.png",
                                child: Column(
                                  children: [
                                    ChampAvecLabel(
                                      label: l10n.bank,
                                      child: TextChampL(
                                        controller: banqueControllerN,
                                        hint: l10n.bankHint,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.rib,
                                      child: TextChampL(
                                        controller: ribControllerN,
                                        hint: l10n.ribHint,
                                        numeric: true,
                                      ),
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
                                        controller: onbservationControllerN,
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
                        resetClientForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.save,
                      onPressed: () async {
                        // ❌ Validation formulaire
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.newClient,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Unicité du nom du client avant toute création.
                        final clientNomExistant = await ClientServices.findClientByNom(nomControllerN.text);
                        if (clientNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.newClient,
                            message: l10n.clientNameAlreadyExists,
                          );
                          return;
                        }

                        // ✅ ICI : Récupérer l'ID au moment de la sauvegarde
                        final int id = await _getNextClientId();
                        final String code = CodeGenerator.generateCode(
                          prefix: CodePrefix.client,
                          id: id,
                          digitCount: 6,
                        );

                        Client client = Client(
                          id: id,
                          code: code,
                          nom: nomControllerN.text,
                          telephone: telControllerN.text,
                          email: emailControllerN.text,
                          fax: faxControllerN.text,
                          wilaya: wilayaControllerN.text,
                          adresse: adresseControllerN.text,
                          type: selectedTypeN!,
                          activity: selectedActiviteN,
                          etat: true,
                          nif: nifControllerN.text,
                          nis: nisControllerN.text,
                          nrc: nrcControllerN.text,
                          rib: ribControllerN.text,
                          banque: banqueControllerN.text,
                          dernierAchat: null,
                          observation: onbservationControllerN.text,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                        );

                        final response = await _saveClient(client: client, userName: userName, userCode: userCode);

                        // ❌ ERREUR
                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.newClient,
                            message: response.message ??
                                "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        // ✅ Succès
                        resetClientForm();

                        await InformationDialog(
                          onTerminer: () {
                            Navigator.pop(context);
                          },
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.newClient,
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

// ✅ Fonction pour récupérer le prochain ID (appelée uniquement au moment de la sauvegarde)
Future<int> _getNextClientId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ClientServices.getNextClientId(txn);
  });
  return id;
}
// Modifier la fonction _saveClient
Future<ApiResponse<int>> _saveClient({required Client client, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final service = ClientServices(db);
  final serviceh = await HistoriqueServices(db);

  // Sauvegarder le client
  final response = await service.addClient(client);

  // Ajouter l'historique
  if (response.success) {
    int idh = await _getNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Client",
      desc: "L'utilisateur $userName a ajouté le Client ${client.nom}",
      oper: ListsConst.typeHisto[0],
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