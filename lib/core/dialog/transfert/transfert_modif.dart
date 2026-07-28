import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/TransfertCaisse.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/tableau/insertion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/transfert.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

List<CaisseGestion> caissesGestionTest = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveData({
  required TransfertCaisse transfert,
  required String userName,
  required String userCode
}) async {
  final db = await DbCreator.openDb();
  final services = await TransfertcaisseServices(db);
  final Hservices = await HistoriqueServices(db);

  final respons = await services.updateTransfertcaisse(transfert);
  int id = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: id,
    code: "HS$id${DateTime.now().microsecondsSinceEpoch}",
    type: "transfert",
    desc: "l'utilisateur ${userName} A Transferee le Montant ${transfert.montant} de La Caisse ${transfert.caisseExpCode} a La Caisse ${transfert.caisseDestCode}",
    oper: ListsConst.typeHisto[1],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await Hservices.addHistorique(histo);
  return respons;
}

Future<void> _loadAllData() async {
  final service = await GCServices.getAllCaisses();
  caissesGestionTest = service;
}

final TextEditingController codeTransfertControllerM = TextEditingController();
final TextEditingController montantControllerM = TextEditingController();
final TextEditingController observationTransfertControllerM = TextEditingController();

String? selectedCaisseSourceM;
String? selectedCaisseDestinationM;
String? selectedEtatTransfertM;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> TransfertCaisseModif(
    BuildContext context,
    TransfertCaisse transfert,
    ) async {
  await _loadAllData();

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredModify,
    );
    return;
  }

  String caisseexpcode = transfert.caisseExpCode;
  String caissedestcode = transfert.caisseDestCode;

  codeTransfertControllerM.text = transfert.code;
  montantControllerM.text = transfert.montant.toString();
  observationTransfertControllerM.text = transfert.observation ?? "";

  selectedCaisseSourceM = transfert.caisseExpCode;
  selectedCaisseDestinationM = transfert.caisseDestCode;
  selectedEtatTransfertM = transfert.etat ? l10n.active : l10n.inactive;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 460,
                header: TitreAvecLigne(
                  imagePath: "assets/icons/cardwidget/transfert_icon.png",
                  text: l10n.modifyTransfer,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChampAvecLabel(
                                label: l10n.code,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: codeTransfertControllerM,
                                  enabled: false,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.sourceCashRegister,
                                obligatoire: true,
                                buttonAjout: true,
                                onAjoutPressed: () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionCaisseDialog(
                                        caisses: caissesGestionTest,
                                        onCaisseSelected: (caisse) {
                                          setState(() {
                                            selectedCaisseSourceM = caisse.nomCaisse;
                                            caisseexpcode = caisse.code;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  value: selectedCaisseSourceM,
                                  clearable: false,
                                  obligatoire: true,
                                  items: caissesGestionTest.map((c) => c.nomCaisse).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedCaisseSourceM = v;
                                      caisseexpcode = caissesGestionTest.where((e) => e.nomCaisse == v).first.code;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.destinationCashRegister,
                                obligatoire: true,
                                buttonAjout: true,
                                onAjoutPressed: () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionCaisseDialog(
                                        caisses: caissesGestionTest,
                                        onCaisseSelected: (caisse) {
                                          setState(() {
                                            selectedCaisseDestinationM = caisse.nomCaisse;
                                            caissedestcode = caisse.code;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  obligatoire: true,
                                  value: selectedCaisseDestinationM,
                                  clearable: false,
                                  items: caissesGestionTest.map((c) => c.nomCaisse).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedCaisseDestinationM = v;
                                      caissedestcode = caissesGestionTest.where((e) => e.nomCaisse == v).first.code;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 20),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChampAvecLabel(
                                label: "${l10n.amount} (${l10n.currency})",
                                obligatoire: true,
                                child: TextChampL(
                                  controller: montantControllerM,
                                  obligatoire: true,
                                  numeric: true,
                                  hint: "0.00",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.status,
                                obligatoire: true,
                                child: TextListe(
                                  value: selectedEtatTransfertM,
                                  items: translator.etatDisplayList,
                                  onChanged: (v) => setState(() {
                                    selectedEtatTransfertM = translator.etatToFrench(v!);
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationTransfertControllerM,
                                  maxLines: 2,
                                  hint: '',
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
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.fillRequiredFields),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.transfer,
                          message: l10n.confirmModifyTransfer,
                          onConfirmer: () async {
                            // ✅ Vérification : les caisses doivent être différentes
                            if (selectedCaisseSourceM == selectedCaisseDestinationM) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.transfer,
                                message: l10n.sourceAndDestinationMustBeDifferent,
                                onTerminer: () {},
                              );
                              return;
                            }

                            TransfertCaisse trans = TransfertCaisse(
                              id: transfert.id,
                              montant: double.tryParse(montantControllerM.text) ?? 0,
                              observation: observationTransfertControllerM.text,
                              etat: selectedEtatTransfertM == l10n.active,
                              creeParCode: transfert.creeParCode,
                              code: transfert.code,
                              dateCree: transfert.dateCree,
                              dateTransfert: DateTime.now(),
                              caisseDestCode: caissedestcode,
                              dateModif: DateTime.now(),
                              caisseExpCode: caisseexpcode,
                              modifParCode: userCode,
                            );

                            final response = await _SaveData(
                              transfert: trans,
                              userName: userName,
                              userCode: userCode,
                            );

                            await InformationDialog(
                                context: context,
                                titre_type_message: response.success ? l10n.success : l10n.error,
                                titre_concerne: l10n.transfer,
                                message: response.message ?? (response.success ? l10n.transferModifiedSuccess : l10n.errorOccurred),
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
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