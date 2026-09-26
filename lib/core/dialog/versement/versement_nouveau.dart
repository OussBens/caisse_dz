import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/Services/PaiementParam.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/data/models/paiementParam.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/retour.dart';
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
import 'package:caisse_dz/core/utilis/number_format.dart';

List<Fournisseur> _fournisseursTest = [];
List<Client>      _clientsTest      = [];
List<CaisseGestion>      _CaissesTest      = [];
PaiementParam?    _paiementParamTest;
List<Pannier>     _panniersTest     = [];
List<Retour>      _retoursTest      = [];

Future<void> _loadAllData() async {
  final client       = await ClientServices.getAllClients();
  final fournisseur  = await FournisseurServices.getAllFournisseurs();
  final caisse  = await GCServices.getAllCaisses();
  final paiementParam = await PaiementParamServices.getPaiementParam();
  final panniers = await PannierServices.getAllPanniers();
  final retours  = await RetourServices.getAllRetour();

  _clientsTest = client;
  _fournisseursTest = fournisseur;
  _CaissesTest = caisse;
  _paiementParamTest = paiementParam;
  _panniersTest = panniers;
  _retoursTest = retours;
}

String _formatDateOperationV(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

/// Opérations sélectionnables comme code opération du versement : paniers
/// du client (Client/Entrée) ou retours fournisseur (Fournisseur/Entrée).
List<MapEntry<String, String>> _operationsDisponibles(String? beneficiaireCode) {
  if (beneficiaireCode == null) return [];

  if (selectedTypeV == "Client") {
    return _panniersTest
        .where((p) => p.client_code == beneficiaireCode)
        .map((p) => MapEntry(p.code, "${p.code} • ${_formatDateOperationV(p.date)} • ${NumberFormatUtil.formatMontant(p.montant, decimales: 2)}"))
        .toList();
  }

  return _retoursTest
      .where((r) => r.type == "Fournisseur" && r.fournisseur_code == beneficiaireCode)
      .map((r) => MapEntry(r.code, "${r.code} • ${_formatDateOperationV(r.date)}"))
      .toList();
}


// Modifier la fonction _saveVersement
Future<ApiResponse<int>> _saveVersement({
  required Verssement vers,
  required String userName,
  required String userCode,
  required String caisseCode,
}) async {
  final db = await DbCreator.openDb();
  final services = VerssementServices(db);
  final servicesclient = ClientServices(db);
  final servicesfournisseur = FournisseurServices(db);
  final serviceh = await HistoriqueServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  // ✅ Session de caisse obligatoire : aucun versement ne peut être
  // enregistré tant que la caisse choisie n'a pas été ouverte.
  final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseCode);
  if (sessionOuverte == null) {
    return ApiResponse(
      success: false,
      message: "Aucune session de caisse ouverte pour cette caisse. Veuillez d'abord ouvrir la caisse.",
    );
  }

  String nomBeneficiaire = vers.beneficiareCode;
  if (vers.typebeneficiare == "Client") {
    final client = _clientsTest.firstWhere(
          (c) => c.code == vers.beneficiareCode,
      orElse: () => throw Exception("Client introuvable"),
    );
    nomBeneficiaire = client.nom;

    await servicesclient.ajouterVersement(
      client.id,
      vers.montant,
    );
  } else if (vers.typebeneficiare == "Fournisseur") {
    final fournisseur = _fournisseursTest.firstWhere(
          (f) => f.code == vers.beneficiareCode,
      orElse: () => throw Exception("Fournisseur introuvable"),
    );
    nomBeneficiaire = fournisseur.nom;

    await servicesfournisseur.ajouterVersement(
      fournisseur.id,
      vers.montant,
    );
  }

  final response = await services.addverssement(vers);

  // Ajouter l'historique
  if (response.success) {
    // Mouvement de caisse (grand-livre) : encaissement client ou paiement
    // fournisseur, journalisé dans la session ouverte de cette caisse.
    final nextMouvementId = await CaisseSessionServices.getNextMouvementId(db);
    await caisseSessionService.ajouterMouvement(CaisseMouvement(
      id: nextMouvementId,
      code: CodeGenerator.generateCode(
        prefix: CodePrefix.caisseMouvement,
        id: nextMouvementId,
        digitCount: 8,
      ),
      sessionCode: sessionOuverte.code,
      caisseCode: caisseCode,
      type: vers.typebeneficiare == 'Fournisseur' ? 'versement_fournisseur' : 'versement_client',
      sens: vers.sense,
      montant: vers.montant,
      modePaiement: vers.mode_paiement,
      // ✅ Code du versement lui-même (pas vers.codeOperation, qui pointe
      // vers le pannier/retour et peut être partagé par plusieurs
      // versements) : garantit un lien 1-à-1 retrouvable depuis
      // versement_modif.dart/versement_actif.dart.
      codeOperation: vers.code,
      clientCode: vers.typebeneficiare == 'Client' ? vers.beneficiareCode : null,
      fournisseurCode: vers.typebeneficiare == 'Fournisseur' ? vers.beneficiareCode : null,
      date: vers.date,
      etat: true,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));

    int idh = await _getNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "Versement",
      desc: "L'utilisateur $userName a ajouté un Versement de ${vers.montant} DZD pour $nomBeneficiaire",
      oper: ListsConst.typeHisto[0],
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
String? selectedCodeOperationV;

void resetVersementForm(String typeVersement) {

  dateController.clear();
  selectedCodeOperationV = null;
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
          final modePaiementList = (_paiementParamTest != null
                  ? PaiementParamServices.visibleDisplayList(_paiementParamTest!, translator)
                  : translator.modePaiementDisplayList)
              .toSet()
              .toList();
          bool isFournisseur = selectedTypeV == "Fournisseur";

          // ✅ Types de versement filtrés selon l'opération liée : un panier
          // (Client) autorise les types courants, un retour fournisseur
          // (Fournisseur) ne peut être qu'une Dette.
          final List<String> typeVersementFrancaisOptions = isFournisseur
              ? const ['Dette']
              : const ['Avancement', 'Complément de facture', 'Paiement', 'Dette', 'Acompte'];
          final typeVersementDetailList = typeVersementFrancaisOptions
              .map(translator.translateTypeVersementDetail)
              .toList();

          // ✅ S'assurer que les valeurs par défaut existent dans les listes
          if (modePaiementList.isNotEmpty) {
            selectedModeP = modePaiementList.first;
          }
          if (!typeVersementFrancaisOptions.contains(selectedtype)) {
            selectedtype = typeVersementFrancaisOptions.first;
            selectedtypev = typeVersementDetailList.first;
          }
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                height: 450,
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
                              distance: 145,
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
                                distance: 145,
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
                              distance: 145,
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
                                            selectedCodeOperationV = null;
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
                                            selectedCodeOperationV = null;
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
                                onChanged: (v) => setState(() {
                                  selectedBeneficiaireV = v;
                                  selectedCodeOperationV = null;
                                }),
                              ),
                            ),
                            const SizedBox(height: 10),

                            () {
                              final beneficiaireCode = selectedBeneficiaireV == null
                                  ? null
                                  : (isClient
                                      ? _clientsTest.firstWhereOrNull((c) => c.nom == selectedBeneficiaireV)?.code
                                      : _fournisseursTest.firstWhereOrNull((f) => f.nom == selectedBeneficiaireV)?.code);
                              final operations = _operationsDisponibles(beneficiaireCode);

                              return ChampAvecLabel(
                                label: isClient ? l10n.cart : l10n.supplierReturn,
                                distance: 145,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  enabled: operations.isNotEmpty,
                                  value: selectedCodeOperationV,
                                  hint: beneficiaireCode == null
                                      ? "Choisissez d'abord un bénéficiaire"
                                      : (operations.isEmpty ? "Aucune opération disponible" : l10n.select),
                                  items: operations.map((e) => e.value).toList(),
                                  onChanged: (v) => setState(() => selectedCodeOperationV = v),
                                ),
                              );
                            }(),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              distance: 145,
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
                                      selectedtype = translator.typeVersementDetailToFrench(v!);

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

                        final beneficiaireCode = selectedTypeV == "Client"
                            ? _clientsTest.firstWhere((c) => c.nom == selectedBeneficiaireV!).code
                            : _fournisseursTest.firstWhere((f) => f.nom == selectedBeneficiaireV!).code;
                        final operations = _operationsDisponibles(beneficiaireCode);
                        final operationChoisie = operations.firstWhereOrNull((e) => e.value == selectedCodeOperationV);

                        if (operationChoisie == null) {
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
                          beneficiareCode: beneficiaireCode,
                          montant: double.parse(montantControllerV.text),
                          etat: true,
                          mode_paiement: selectedModePaiement,
                          // Sens du versement selon le bénéficiaire : un
                          // encaissement client entre en caisse (Entrée), un
                          // paiement fournisseur en sort (Sortie).
                          sense: selectedTypeV == "Fournisseur" ? 'Sortie' : 'Entrée',
                          type: selectedtype,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                          caisse: selectedCaisse,
                          codeOperation: operationChoisie.key,
                        );

                        final caisseChoisieV = _CaissesTest.where((c) => c.nomCaisse == selectedCaisse).firstOrNull;
                        if (caisseChoisieV == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.payment,
                            message: l10n.cashRegisterRequired,
                          );
                          return;
                        }

                        final response = await _saveVersement(
                          vers: versement,
                          userName: userName,
                          userCode: userCode,
                          caisseCode: caisseChoisieV.code,
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