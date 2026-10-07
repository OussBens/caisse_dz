import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/Services/PaiementParam.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/data/models/paiementParam.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/CaisseGestion.dart' hide ApiResponse;
import '../../../Services/Historique.dart';
import '../../../data/constant.dart';
import '../../../data/models/gestion_caisse.dart';
import '../../../data/models/histore.dart';
import '../../../data/models/verssement.dart';
import '../../tableau/insertion_caisse.dart';
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
import 'package:caisse_dz/core/utilis/number_format.dart';

List<Client>          _clientsTest      = [];
List<Fournisseur>     _fournisseursTest = [];
List<CaisseGestion>   _CaissesTest      = [];
PaiementParam?        _paiementParamTest;
List<Retour>          _retoursTest      = [];
List<SmartScan>       _smartScansTest   = [];

Future<void> _loadAllData() async {
  final client       = await ClientServices.getAllClients();
  final fournisseur  = await FournisseurServices.getAllFournisseurs();
  final caisse  = await GCServices.getAllCaisses();
  final paiementParam = await PaiementParamServices.getPaiementParam();
  final retours = await RetourServices.getAllRetour();
  final smartScans = await SmartScanServices.getAllSmartScans();
  _clientsTest = client;
  _fournisseursTest = fournisseur;
  _CaissesTest = caisse;
  _paiementParamTest = paiementParam;
  _retoursTest = retours;
  _smartScansTest = smartScans;
}

String _formatDateOperationVR(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

/// Opérations sélectionnables comme code opération du versement : retours
/// client (Client/Sortie) ou smart scans du fournisseur (Fournisseur/Sortie).
List<MapEntry<String, String>> _operationsDisponiblesVR(String? beneficiaireCode) {
  if (beneficiaireCode == null) return [];

  if (selectedTypeV == "Client") {
    return _retoursTest
        .where((r) => r.type == "Client" && r.client_code == beneficiaireCode)
        .map((r) => MapEntry(r.code, "${r.code} • ${_formatDateOperationVR(r.date)}"))
        .toList();
  }

  return _smartScansTest
      .where((s) => s.fournisseurCode == beneficiaireCode)
      .map((s) => MapEntry(s.code, "${s.code} • ${_formatDateOperationVR(s.date)} • ${NumberFormatUtil.formatMontant(s.montant, decimales: 2)}"))
      .toList();
}

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

    await servicesclient.ajouterVersementSortie(
      client.id,
      vers.montant,
    );
  } else if (vers.typebeneficiare == "Fournisseur") {
    final fournisseur = _fournisseursTest.firstWhere(
          (f) => f.code == vers.beneficiareCode,
      orElse: () => throw Exception("Fournisseur introuvable"),
    );
    nomBeneficiaire = fournisseur.nom;

    await servicesfournisseur.ajouterVersementSortie(
      fournisseur.id,
      vers.montant,
    );
  }

  final response = await services.addverssement(vers);

  // Ajouter l'historique
  if (response.success) {
    // Mouvement de caisse (grand-livre) : sortie de caisse, journalisée dans
    // la session ouverte de cette caisse.
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
      // vers le retour/smart scan et peut être partagé par plusieurs
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
      type: "Versement Sortie",
      desc: "L'utilisateur $userName a ajouté un Versement Sortie de ${vers.montant} DZD pour $nomBeneficiaire",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

// Ajouter _getNextHistoriqueId si ce n'est pas déjà fait
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
String selectedModePaiement = "";
String selectedmode = '';
String selectedtype = "";
String selectedType = '';
String selectedCaisse = "";
String? selectedCodeOperationVR;

void resetVersementRetourForm(String typeVersement) {
  observationControllerV.clear();
  montantControllerV.clear();
  selectedTypeV = typeVersement;
  selectedBeneficiaireV = null;
  selectedEtatV = "Validé";
  selectedModePaiement = "Espèces";
  selectedtype = "Paiement";
  selectedCodeOperationVR = null;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> VersementNouveauRetour(
    BuildContext context,
    String typeVersement,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  await _loadAllData();
  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le versement retour
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.verssement,
    id: id,
    digitCount: 6, // "VRS000001"
  );

  montantControllerV.clear();
  dateController.clear();
  selectedCodeOperationVR = null;
  selectedTypeV = typeVersement;
  selectedBeneficiaireV = null;
  selectedEtatV = "Validé";
  selectedModePaiement = "Espèces";
  selectedtype = "Paiement";
  int numero = DateTime.now().millisecondsSinceEpoch % 100000;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.25),
    barrierDismissible: true,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          final modePaiementList = _paiementParamTest != null
              ? PaiementParamServices.visibleDisplayList(_paiementParamTest!, translator)
              : translator.modePaiementDisplayList;
          if (modePaiementList.isNotEmpty) {
            selectedmode = modePaiementList.first;
          }
          bool isClient = selectedTypeV == "Client";
          bool isFournisseur = selectedTypeV == "Fournisseur";

          // ✅ Types de versement filtrés selon l'opération liée : un retour
          // client ne peut être qu'un Remboursement, un smart scan
          // fournisseur autorise les types courants.
          final List<String> typeVersementFrancaisOptions = isClient
              ? const ['Remboursement']
              : const ['Avancement', 'Complément de facture', 'Paiement', 'Dette', 'Acompte'];
          final typeVersementDetailListVR = typeVersementFrancaisOptions
              .map(translator.translateTypeVersementDetail)
              .toList();

          if (!typeVersementFrancaisOptions.contains(selectedtype)) {
            selectedtype = typeVersementFrancaisOptions.first;
            selectedType = typeVersementDetailListVR.first;
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                height: 450,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/devise_icon.png',
                  text: l10n.newPaymentExit,
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
                                            selectedCodeOperationVR = null;
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
                                            selectedCodeOperationVR = null;
                                          });
                                        },
                                      );
                                    },
                                  );
                                }
                              },
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedBeneficiaireV,
                                items: isClient
                                    ? _clientsTest.map((e) => e.nom).toList()
                                    : _fournisseursTest.map((e) => e.nom).toList(),
                                onChanged: (v) => setState(() {
                                  selectedBeneficiaireV = v;
                                  selectedCodeOperationVR = null;
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
                              final operations = _operationsDisponiblesVR(beneficiaireCode);

                              return ChampAvecLabel(
                                label: isClient ? l10n.clientReturn : l10n.smartScan,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  enabled: operations.isNotEmpty,
                                  value: selectedCodeOperationVR,
                                  hint: beneficiaireCode == null
                                      ? "Choisissez d'abord un bénéficiaire"
                                      : (operations.isEmpty ? "Aucune opération disponible" : l10n.select),
                                  items: operations.map((e) => e.value).toList(),
                                  onChanged: (v) => setState(() => selectedCodeOperationVR = v),
                                ),
                              );
                            }(),
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
                              label: l10n.paymentMethod,
                              obligatoire: true,
                              child: TextListe(
                                  clearable: false,
                                  obligatoire: true,
                                  value: selectedmode,
                                  items: modePaiementList,
                                  onChanged: (v) {
                                    setState(() {
                                      selectedModePaiement = translator.modePaiementToFrench(v!);
                                      selectedmode = v;
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
                                  value: selectedType,
                                  items: typeVersementDetailListVR,
                                  onChanged: (v) {
                                    setState(() {
                                      selectedtype = translator.typeVersementDetailToFrench(v!);
                                      selectedType = v;
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
                                clearable: false,
                                value: selectedCaisse,
                                obligatoire: true,
                                items: _CaissesTest.map((e) => e.nomCaisse).toList(),
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
                        resetVersementRetourForm(typeVersement);
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.jaune,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.payment,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final beneficiaireCode = selectedTypeV == "Client"
                            ? _clientsTest.firstWhere((c) => c.nom == selectedBeneficiaireV!).code
                            : _fournisseursTest.firstWhere((f) => f.nom == selectedBeneficiaireV!).code;
                        final operations = _operationsDisponiblesVR(beneficiaireCode);
                        final operationChoisie = operations.firstWhereOrNull((e) => e.value == selectedCodeOperationVR);

                        if (operationChoisie == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
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
                          sense: 'Sortie',
                          type: selectedtype,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                          caisse: selectedCaisse,
                          codeOperation: operationChoisie.key,
                        );

                        final caisseChoisieVR = _CaissesTest.where((c) => c.nomCaisse == selectedCaisse).firstOrNull;
                        if (caisseChoisieVR == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.payment,
                            message: l10n.cashRegisterRequired,
                          );
                          return;
                        }

                        final response = await _saveVersement(
                          vers: versement,
                          userName: userName,
                          userCode: userCode,
                          caisseCode: caisseChoisieVR.code,
                        );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
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

                        resetVersementRetourForm(typeVersement);
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