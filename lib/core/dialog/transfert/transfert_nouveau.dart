import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/TransfertCaisse.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/tableau/insertion_caisse.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/transfert.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  final respons = await services.addTransfertcaisse(transfert);
  int id = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: id,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: id,
    ), // ✅ Utilisation du générateur
    type: "transfert",
    desc: "l'utilisateur ${userName} A Transferee le Montant ${transfert.montant} de La Caisse ${transfert.caisseExp} a La Caisse ${transfert.caisseDest}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await Hservices.addHistorique(histo);
  return respons;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await TransfertcaisseServices.getNextTransfertcaisseId(txn);
  });
  return id;
}

Future<void> _loadAllData() async {
  final service = await GCServices.getAllCaisses();
  caissesGestionTest = service;
}

final TextEditingController codeTransfertController = TextEditingController();
final TextEditingController montantController = TextEditingController();
final TextEditingController observationTransfertController = TextEditingController();
String? selectedCaisseSource;
String? selectedCaisseDestination;
List<String> listeCaisses = caissesGestionTest.map((c) => c.nomCaisse).toList();

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> TransfertCaisseNouveau(BuildContext context,) async {
  await _loadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le transfert
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.transfert,
    id: id,
    digitCount: 6, // "TRF000001"
  );

  String caisseexpcode = '';
  String caissedestcode = '';

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  codeTransfertController.text = code;

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
                height: 420,
                header: TitreAvecLigne(
                  imagePath: "assets/icons/cardwidget/transfert_icon.png",
                  text: l10n.newTransfer,
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
                                  controller: codeTransfertController,
                                  hint: l10n.codeAutoGenerated,
                                  enabled: false,
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
                                            selectedCaisseSource = caisse.nomCaisse;
                                            caisseexpcode = caisse.code;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  value: selectedCaisseSource ?? "",
                                  obligatoire: true,
                                  items: caissesGestionTest.map((c) => c.nomCaisse).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedCaisseSource = v;
                                      caisseexpcode = caissesGestionTest.where((c) => c.nomCaisse == v).first.code;
                                    });
                                  },
                                ),
                              ),

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.destinationCashRegister,
                                buttonAjout: true,
                                obligatoire: true,
                                onAjoutPressed: () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionCaisseDialog(
                                        caisses: caissesGestionTest,
                                        onCaisseSelected: (caisse) {
                                          setState(() {
                                            selectedCaisseDestination = caisse.nomCaisse;
                                            caissedestcode = caisse.code;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  value: selectedCaisseDestination ?? "",
                                  obligatoire: true,
                                  items: caissesGestionTest.map((c) => c.nomCaisse).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      selectedCaisseDestination = v;
                                      caissedestcode = caissesGestionTest.where((c) => c.nomCaisse == v).first.code;
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
                                  obligatoire: true,
                                  controller: montantController,
                                  numeric: true,
                                  hint: "0.00",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationTransfertController,
                                  hint: l10n.observationOptional,
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
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.transfer,
                            message: l10n.fillRequiredFields,
                            onTerminer: () {},
                          );
                          return;
                        }

                        // ✅ Vérification : les caisses doivent être différentes
                        if (selectedCaisseSource == selectedCaisseDestination) {
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
                          id: id,
                          etat: true,
                          code: code, // ✅ Code généré automatiquement
                          montant: double.tryParse(montantController.text) ?? 0,
                          creeParCode: userCode,
                          dateCree: DateTime.now(),
                          dateTransfert: DateTime.now(),
                          caisseExp: selectedCaisseSource!,
                          caisseDest: selectedCaisseDestination!,
                          caisseExpCode: caisseexpcode,
                          caisseDestCode: caissedestcode,
                          observation: observationTransfertController.text,
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
                          message: response.message,
                          onTerminer: () {
                            if (response.success) Navigator.pop(context);
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