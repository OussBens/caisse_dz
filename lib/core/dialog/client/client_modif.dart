import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import '../../../../data/models/client.dart';
import '../../../../data/models/histore.dart';
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

// ✅ Fonction pour obtenir le prochain ID d'historique
Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

// ✅ Fonction de mise à jour avec historique
Future<ApiResponse<int>> _updateClient({
  required Client client,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = ClientServices(db);
  final serviceh = await HistoriqueServices(db);

  final response = await services.updateClient(client);

  // ✅ Ajouter l'historique de modification
  if (response.success) {
    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "L'utilisateur $userName a modifié le client ${client.nom}",
      type: "Client",
      oper: ListsConst.typeHisto[1], // ✅ Type modification
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

// Controllers
final TextEditingController nomController = TextEditingController();
final TextEditingController telController = TextEditingController();
final TextEditingController wilayaController = TextEditingController();
final TextEditingController adresseController = TextEditingController();
final TextEditingController montantController = TextEditingController();
final TextEditingController emailController = TextEditingController();
final TextEditingController faxController   = TextEditingController();
final TextEditingController nifController   = TextEditingController();
final TextEditingController nisController   = TextEditingController();
final TextEditingController nrcController   = TextEditingController();
final TextEditingController ribController   = TextEditingController();
final TextEditingController banqueController = TextEditingController();
final TextEditingController onbservationControllerN = TextEditingController();

// Non modifiables
final TextEditingController derniereVisiteController = TextEditingController();
final TextEditingController creditController = TextEditingController();
final TextEditingController nombreAchatController = TextEditingController();

// Dropdown
String? selectedType;
String? selectedActivite;
String? selectedEtat;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> ClientModif(BuildContext context, Client client) async {
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

  final l10n = AppLocalizations.of(context)!;

  // Initialisation
  nomController.text = client.nom;
  telController.text = client.telephone;
  wilayaController.text = client.wilaya;
  adresseController.text = client.adresse ?? "";
  emailController.text  = client.email ?? "";
  faxController.text    = client.fax ?? "";
  nifController.text    = client.nif ?? "";
  nisController.text    = client.nis ?? "";
  nrcController.text    = client.nrc ?? "";
  ribController.text    = client.rib ?? "";
  banqueController.text = client.banque ?? "";
  onbservationControllerN.text = client.observation ?? "";
  derniereVisiteController.text = client.dernierAchat != null ? "${client.dernierAchat!.day}-${client.dernierAchat!.month}-${client.dernierAchat!.year}" : "";
  selectedType = client.type ?? ListsConst.typeClient.first;
  selectedActivite = client.activity ?? "";
  selectedEtat = client.etat ? "Actif" : "Inactif";

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
                  imagePath: 'assets/icons/sidebar/client_icon.png',
                  text: l10n.modifyClient,
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
                                      child: AffichageChamp(text: client.code),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.status,
                                      obligatoire: true,
                                      child: TextListe(
                                        value: selectedEtat,
                                        items: const ["Actif", "Inactif"],
                                        clearable: false,
                                        onChanged: (v) {
                                          setState(() {
                                            selectedEtat = v ?? "Actif";
                                            client.etat = selectedEtat == "Actif" ? true : false;
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
                                        controller: nomController,
                                        hint: '',
                                        enabled: false,
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    ChampAvecLabel(
                                      label: l10n.phone,
                                      obligatoire: true,
                                      child: TextChampL(
                                        numeric: true,
                                        obligatoire: true,
                                        controller: telController,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    ChampAvecLabel(
                                      label: l10n.wilaya,
                                      obligatoire: true,
                                      child: TextChampL(
                                        obligatoire: true,
                                        controller: wilayaController,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    ChampAvecLabel(
                                      label: l10n.clientType,
                                      child: TextListe(
                                        value: selectedType,
                                        items: ListsConst.typeClient,
                                        onChanged: (v) => setState(() => selectedType = v),
                                      ),
                                    ),
                                    const SizedBox(height: 10),

                                    ChampAvecLabel(
                                      label: l10n.activity,
                                      child: TextListe(
                                        value: selectedActivite,
                                        items: ListsConst.activitesClient,
                                        onChanged: (v) => setState(() => selectedActivite = v),
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
                                        controller: adresseController,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.email,
                                      child: TextChampL(
                                        controller: emailController,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.fax,
                                      child: TextChampL(
                                        numeric: true,
                                        controller: faxController,
                                        hint: '',
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
                                        controller: nifController,
                                        numeric: true,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: "NIS",
                                      child: TextChampL(
                                        controller: nisController,
                                        numeric: true,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: "NRC",
                                      child: TextChampL(
                                        controller: nrcController,
                                        hint: '',
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
                                        controller: banqueController,
                                        hint: '',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ChampAvecLabel(
                                      label: l10n.rib,
                                      child: TextChampL(
                                        controller: ribController,
                                        numeric: true,
                                        hint: '',
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
                            titre_concerne: l10n.modifyClient,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Vérification des champs obligatoires
                        if (selectedType == null || selectedType!.isEmpty) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.modifyClient,
                            message: l10n.selectClientType,
                          );
                          return;
                        }

                        // ✅ Confirmation utilisateur
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyClient,
                          message: l10n.confirmModifyClient,
                          onConfirmer: () async {
                            Client clientU = Client(
                              id            : client.id,
                              code          : client.code,
                              nom           : client.nom,
                              telephone     : telController.text,
                              email         : emailController.text,
                              fax           : faxController.text,
                              wilaya        : wilayaController.text,
                              adresse       : adresseController.text,
                              type          : selectedType!,
                              activity      : selectedActivite,
                              etat          : selectedEtat == 'Actif',
                              rib           : ribController.text,
                              nrc           : nrcController.text,
                              nis           : nisController.text,
                              nif           : nifController.text,
                              banque        : banqueController.text,
                              dernierAchat  : client.dernierAchat,
                              observation   : onbservationControllerN.text,
                              dateCree      : client.dateCree,
                              creeParCode   : client.creeParCode,
                              dateModif     : DateTime.now(),
                              modifParCode      : userCode,
                            );

                            // ✅ Appel avec historique
                            final response = await _updateClient(
                              client: clientU,
                              userName: userName,
                              userCode: userCode,
                            );

                            // ❌ ERREUR
                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.modifyClient,
                                message: response.message ??
                                    "Une erreur est survenue lors de la modification.",
                              );
                              return;
                            }

                            // ✅ SUCCÈS
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.modifyClient,
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
      borderRadius: BorderRadius.circular(14),
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