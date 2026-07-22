import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import '../../../data/models/verssement.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/date_champ.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_client.dart';
import '../insertion_fournisseur.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;

List<Fournisseur> _fournisseursTest = [];
List<Client>      _clientsTest      = [];
List<CaisseGestion>      _CaissesTest      = [];

Future<void> _loadAllData() async {
  final client       = await ClientServices.getAllClients();
  final fournisseur  = await FournisseurServices.getAllFournisseurs();
  final caisse  = await GCServices.getAllCaisses();

  _clientsTest = client;
  _fournisseursTest = fournisseur;
  _CaissesTest = caisse;
}


// Modifier la fonction _saveVersement
Future<ApiResponse<int>> _saveVersement({required Verssement vers, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final services = VerssementServices(db);
  final servicesclient = ClientServices(db);
  final servicesfournisseur = FournisseurServices(db);
  final serviceh = await HistoriqueServices(db);

  if (vers.typebeneficiare == "Client") {
    final client = _clientsTest.firstWhere(
          (c) => c.nom == vers.beneficiare,
      orElse: () => throw Exception("Client introuvable"),
    );

    await servicesclient.ajouterVersement(
      client.id,
      vers.montant,
    );
  } else if (vers.typebeneficiare == "Fournisseur") {
    final fournisseur = _fournisseursTest.firstWhere(
          (f) => f.nom == vers.beneficiare,
      orElse: () => throw Exception("Fournisseur introuvable"),
    );

    await servicesfournisseur.ajouterVersement(
      fournisseur.id,
      vers.montant,
    );
  }

  final response = await services.addverssement(vers);

  // Ajouter l'historique
  if (response.success) {
    int idh = await _getNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Versement",
      desc: "L'utilisateur $userName a ajouté un Versement de ${vers.montant} DZD pour ${vers.beneficiare}",
      oper: ListsConst.typeHisto[0],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

// Ajouter cette fonction
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
    id = await VerssementServices.getNextVerssementId(txn);
  });
  return id;
}

Future<void> pickDate(
    BuildContext context,
    TextEditingController controller, {
      DateTime? minDate,
    }) async {
  DateTime initialDate = DateTime.now();

  if (controller.text.isNotEmpty) {
    try {
      initialDate = DateTime.parse(controller.text);
    } catch (_) {}
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate.isBefore(minDate ?? initialDate)
        ? (minDate ?? initialDate)
        : initialDate,
    firstDate: minDate ?? DateTime(2000),
    lastDate: DateTime.now(),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Appstyle.violet,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.text =
    "${picked.year.toString().padLeft(4, '0')}-"
        "${picked.month.toString().padLeft(2, '0')}-"
        "${picked.day.toString().padLeft(2, '0')}";
  }
}

final TextEditingController montantControllerV = TextEditingController();
final TextEditingController observationControllerV = TextEditingController();
final TextEditingController dateController = TextEditingController();

String? selectedTypeV;
String? selectedBeneficiaireV;
String? selectedEtatV;
String? selectedEtat;
String selectedModePaiement = "";
String selectedModeP = '';
String selectedCaisse = "";
String selectedtype = "";
String selectedtypev = '';

void resetVersementForm(String typeVersement) {

  dateController.clear();
  observationControllerV.clear();
  montantControllerV.clear();
  selectedTypeV = typeVersement;
  selectedBeneficiaireV = null;
  selectedEtatV = '';
  selectedModePaiement = "Espèces";
  selectedtype = "Paiement";
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> VersementNouveau(
    BuildContext context,
    String typeVersement,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;
  selectedEtatV = l10n.validate;
  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  await _loadAllData();
  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le versement
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.verssement,
    id: id,
    digitCount: 6, // "VRS000001"
  );

  selectedTypeV = typeVersement;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.25),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          bool isClient = selectedTypeV == "Client";
          // ✅ Récupérer les listes uniques
          final modePaiementList = translator.modePaiementDisplayList.toSet().toList();
          final typeVersementDetailList = translator.typeVersementDetailDisplayList.toSet().toList();

          // ✅ S'assurer que les valeurs par défaut existent dans les listes
          if (modePaiementList.isNotEmpty) {
            selectedModeP = modePaiementList.first;
          }
          if (typeVersementDetailList.isNotEmpty) {
            selectedtypev = typeVersementDetailList.first;
          }


          bool isFournisseur = selectedTypeV == "Fournisseur";
          selectedtypev = translator.typeVersementDisplayList.first;
          selectedModeP = translator.modePaiementDisplayList.first;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 420,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/devise_icon.png',
                  text: l10n.newPayment,
                ),

                content: Form(
                  key: produitFormKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChampAvecLabel(
                              label: l10n.number,
                              child: TextChampL(
                                enabled: false,
                                controller: TextEditingController(
                                  text: code,
                                ),
                                hint: "",
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                                obligatoire: true,
                                label: l10n.date,
                                child: TextDate(
                                    hint: "15 nov 2025",
                                    obligatoire: true,
                                    enabled: true,
                                    controller: dateController,
                                    onTap: () => pickDate(context, dateController)
                                )
                            ),

                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.beneficiary,
                              obligatoire: true,
                              buttonAjout: true,
                              onAjoutPressed: () async {
                                if (isClient) {
                                  await showDialog(
                                    context: context,
                                    builder: (_) {
                                      return InsertionClientDialog(
                                        clients: _clientsTest,
                                        onClientSelected: (c) {
                                          setState(() {
                                            selectedBeneficiaireV = c.nom;
                                          });
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  await showDialog(
                                    context: context,
                                    builder: (_) {
                                      return InsertionFournisseurDialog(
                                        fournisseurs: _fournisseursTest,
                                        onFournisseurSelected: (f) {
                                          setState(() {
                                            selectedBeneficiaireV = f.nom;
                                          });
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                              child: TextListe(
                                value: selectedBeneficiaireV,
                                clearable: false,
                                obligatoire: true,
                                items: isClient
                                    ? _clientsTest.map((e) => e.nom).toSet().toList()
                                    : _fournisseursTest.map((e) => e.nom).toSet().toList(),
                                onChanged: (v) => setState(() => selectedBeneficiaireV = v),
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.paymentMethod,
                              obligatoire: true,
                              child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedModeP,
                                  items: modePaiementList, // ✅ Liste unique
                                  onChanged: (v) {
                                    setState(() {
                                      selectedModeP = v!;
                                      selectedModePaiement = translator.modePaiementToFrench(v!);
                                    });
                                  }
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
                              label: l10n.amount,
                              obligatoire: true,
                              child: TextChampL(
                                obligatoire: true,
                                numeric: true,
                                controller: montantControllerV,
                                hint: "0.00",
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.paymentType,
                              child: TextListe(
                                  value: selectedtypev,
                                  items: typeVersementDetailList, // ✅ Liste unique
                                  onChanged: (v) {
                                    setState((){
                                      selectedtypev = v!;
                                      selectedtype = translator.typeVersementToFrench(v!);

                                    });

                                  }
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.cashRegister,
                              obligatoire: true,
                              buttonAjout: true,
                              onAjoutPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder: (_) {
                                    return InsertionCaisseDialog(
                                      caisses: _CaissesTest,
                                      onCaisseSelected: (f) {
                                        setState(() {
                                          selectedCaisse = f.nomCaisse;
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                              child: TextListe(
                                value: selectedCaisse,
                                clearable: false,
                                obligatoire: true,
                                items: _CaissesTest.map((e) => e.nomCaisse).toSet().toList(),
                                onChanged: (v) => setState(() => selectedCaisse = v!),
                              ),
                            ),

                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.observation,
                              child: TextChampL(
                                controller: observationControllerV,
                                hint: "-",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                        resetVersementForm(typeVersement);
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
                            titre_concerne: l10n.payment,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final versement = Verssement(
                          id: id,
                          code: code, // ✅ Code généré automatiquement
                          date: DateTime.parse(dateController.text),
                          typebeneficiare: selectedTypeV!,
                          beneficiare: selectedBeneficiaireV!,
                          montant: double.parse(montantControllerV.text),
                          etat: true,
                          mode_paiement: selectedModePaiement,
                          sense: 'Entrée',
                          type: selectedtype,
                          dateCree: DateTime.now(),
                          creePar: userName,
                          creeParCode: userCode,
                          caisse: selectedCaisse,
                        );

                        final response = await _saveVersement(
                          vers: versement,
                          userName: userName,
                          userCode: userCode,
                        );

                        print(response.message);
                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.payment,
                            message: response.message ?? l10n.errorOccurred,
                          );
                          return;
                        }

                        await InformationDialog(
                            context: context,
                            titre_type_message: l10n.success,
                            titre_concerne: l10n.payment,
                            message: response.message ?? l10n.paymentSavedSuccess,
                            onTerminer: () {
                              Navigator.pop(context);
                            }
                        );

                        resetVersementForm(typeVersement);
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