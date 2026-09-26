import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_client.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:provider/provider.dart';
import '../../../Services/CaisseGestion.dart' hide ApiResponse;
import '../../../data/models/gestion_caisse.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';
import '../../../Services/PaiementParam.dart';
import '../../../data/models/paiementParam.dart';

List<Fournisseur> _fournisseursTest = [];
List<Client>      _clientsTest      = [];
List<CaisseGestion>      _caissesTest      = [];
PaiementParam?    _paiementParamTest;

Future<void> _loadAllData() async {
  final client       = await ClientServices.getAllClients();
  final fournisseur  = await FournisseurServices.getAllFournisseurs();
  final caisse  = await GCServices.getAllCaisses();
  final paiementParam = await PaiementParamServices.getPaiementParam();
  _clientsTest = client;
  _fournisseursTest = fournisseur;
  _caissesTest = caisse;
  _paiementParamTest = paiementParam;
}

Future<ApiResponse<int>> _updateVersment({
  required Verssement verssement,
  required String ancienMontant,
  required String caisseCode,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);
  final response = await services.updateVerssement(verssement);

  if (response.success) {
    final ancien = double.tryParse(ancienMontant) ?? verssement.montant;
    if (ancien != verssement.montant) {
      final type = verssement.typebeneficiare == 'Fournisseur' ? 'versement_fournisseur' : 'versement_client';
      final mouvementsExistants = await CaisseSessionServices.getMouvementsByCodeOperation(
        verssement.code,
        type: type,
      );
      final mouvementExistant = mouvementsExistants.firstOrNull;

      if (mouvementExistant != null) {
        await caisseSessionService.updateMontantMouvement(
          code: mouvementExistant.code,
          montant: verssement.montant,
          userCode: userCode,
        );
      } else {
        final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseCode);
        if (sessionOuverte != null) {
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
            type: type,
            sens: verssement.sense,
            montant: verssement.montant,
            modePaiement: verssement.mode_paiement,
            codeOperation: verssement.code,
            clientCode: verssement.typebeneficiare == 'Client' ? verssement.beneficiareCode : null,
            fournisseurCode: verssement.typebeneficiare == 'Fournisseur' ? verssement.beneficiareCode : null,
            date: verssement.date,
            etat: true,
            dateCree: DateTime.now(),
            creeParCode: userCode,
          ));
        }
      }
    }
  }

  return response;
}

String selectedCaisse = "";
String? _selectedTypeV;
String? _selectedBeneficiaireV;
String  _selectedModePaiement = "";
String  selectedModeP = '';
String  _selectedType = "";
String  selectedTyp = '';

final TextEditingController _smartDateController     = TextEditingController();
final TextEditingController _montantControllerV      = TextEditingController();
final TextEditingController _observationControllerV  = TextEditingController();
final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> VersementModif(
    BuildContext context,
    Verssement versement, {
      String? typeInitial,
    }) async {
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

  // Un versement généré par un retour ne peut pas être modifié directement :
  // il doit rester synchronisé avec le retour, donc toute modification doit
  // passer par le retour lui-même.
  if (await RetourServices.estLieAUnRetour(versement.codeOperation)) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.information,
      titre_concerne: l10n.payment,
      message: l10n.versementLieRetourModif(versement.codeOperation),
    );
    return;
  }

  await _loadAllData();

  _montantControllerV.text     = versement.montant.toString();
  _observationControllerV.text = versement.observation.toString();
  _smartDateController.text    = "${versement.date.day}-${versement.date.month}-${versement.date.year}";
  selectedCaisse = versement.caisse;
  _selectedTypeV               = typeInitial ?? versement.typebeneficiare;
  _selectedModePaiement        = versement.mode_paiement;
  _selectedType                = versement.type;

  bool isInitiallyClient = versement.typebeneficiare == "Client";

  final beneficiaireNomInitial = isInitiallyClient
      ? _clientsTest.firstWhere((c) => c.code == versement.beneficiareCode, orElse: () => _clientsTest.first).nom
      : _fournisseursTest.firstWhere((f) => f.code == versement.beneficiareCode, orElse: () => _fournisseursTest.first).nom;

  if (isInitiallyClient) {
    final clientNames = _clientsTest.map((e) => e.nom).toSet().toList();
    _selectedBeneficiaireV = clientNames.contains(beneficiaireNomInitial)
        ? beneficiaireNomInitial
        : (clientNames.isNotEmpty ? clientNames.first : null);
  } else {
    final fournisseurNames = _fournisseursTest.map((e) => e.nom).toSet().toList();
    _selectedBeneficiaireV = fournisseurNames.contains(beneficiaireNomInitial)
        ? beneficiaireNomInitial
        : (fournisseurNames.isNotEmpty ? fournisseurNames.first : null);
  }

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          selectedModeP = translator.translateModePaiement(versement.mode_paiement);
          selectedTyp   = translator.translateTypeVersement(versement.type);
          bool isClient = _selectedTypeV == "Client";

          List<String> getBeneficiaireItems() {
            List<String> items;
            if (isClient) {
              items = _clientsTest.map((e) => e.nom).toSet().toList();
            } else {
              items = _fournisseursTest.map((e) => e.nom).toSet().toList();
            }
            if (_selectedBeneficiaireV != null && !items.contains(_selectedBeneficiaireV)) {
              items.insert(0, _selectedBeneficiaireV!);
            }
            return items;
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                height: 450,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/devise_icon.png',
                  text: l10n.modifyPayment,
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
                                  text: versement.code,
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
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionClientDialog(
                                        clients: _clientsTest,
                                        onClientSelected: (c) {
                                          setState(() {
                                            _selectedBeneficiaireV = c.nom;
                                          });
                                        },
                                      );
                                    },
                                  );
                                } else {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionFournisseurDialog(
                                        fournisseurs: _fournisseursTest,
                                        onFournisseurSelected: (f) {
                                          setState(() {
                                            _selectedBeneficiaireV = f.nom;
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
                                value: _selectedBeneficiaireV,
                                items: getBeneficiaireItems(),
                                onChanged: (v) => setState(() => _selectedBeneficiaireV = v),
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.date,
                              obligatoire: true,
                              child: TextDate(
                                obligatoire: true,
                                controller: _smartDateController,
                                hint: "25 Nov 2025",
                                onTap: () async {
                                  DateTime? picked = await showDatePicker(
                                    context: context,
                                    initialDate: versement.date,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null) {
                                    setState(() {
                                      _smartDateController.text =
                                      "${picked.day}-${picked.month}-${picked.year}";
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.paymentMethod,
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedModeP,
                                items: _paiementParamTest != null
                                    ? PaiementParamServices.visibleDisplayList(
                                        _paiementParamTest!,
                                        translator,
                                        toujoursInclure: versement.mode_paiement,
                                      )
                                    : translator.modePaiementDisplayList,
                                onChanged: (v) {
                                  setState((){
                                    selectedModeP         = v!;
                                    _selectedModePaiement = translator.modePaiementToFrench(v!);

                                  });
                                }),
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
                              label: l10n.paymentType,
                              child: TextListe(
                                value:  selectedTyp,
                                items: translator.typeVersementDetailDisplayList,
                                onChanged: (v) {
                                  setState(() {
                                    selectedTyp = v!;
                                    _selectedType = translator.typeVersementToFrench(v!);
                                  });
                                }
                              ),
                            ),

                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.amount,
                              obligatoire: true,
                              child: TextChampL(
                                obligatoire: true,
                                controller: _montantControllerV,
                                numeric: true,
                                hint: _montantControllerV.text,
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
                                  barrierColor: Appstyle.gris.withOpacity(0.25),
                                  builder: (_) {
                                    return InsertionCaisseDialog(
                                      caisses: _caissesTest,
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
                                obligatoire: true,
                                clearable: false,
                                value: selectedCaisse,
                                items: _caissesTest.map((e) => e.nomCaisse).toList(),
                                onChanged: (v) => setState(() => selectedCaisse = v!),
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.observation,
                              child: TextChampL(
                                controller: _observationControllerV,
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.modify,
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

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.payment,
                          message: l10n.confirmModifyPayment,
                          onConfirmer: () async {
                            final dateParts = _smartDateController.text.split('-');
                            // ✅ Conserve l'heure d'origine du versement : le
                            // sélecteur de date ne renvoie qu'un jour, sans
                            // quoi chaque modification (même sans toucher à
                            // la date) écraserait l'heure réelle de
                            // l'opération avec minuit.
                            final parsedDate = DateTime(
                              int.parse(dateParts[2]),
                              int.parse(dateParts[1]),
                              int.parse(dateParts[0]),
                              versement.date.hour,
                              versement.date.minute,
                              versement.date.second,
                            );

                            Verssement updatedVerssement = Verssement(
                              typebeneficiare: _selectedTypeV!,
                              mode_paiement: _selectedModePaiement,
                              beneficiareCode: _selectedTypeV == "Client"
                                  ? _clientsTest.firstWhere((c) => c.nom == _selectedBeneficiaireV!).code
                                  : _fournisseursTest.firstWhere((f) => f.nom == _selectedBeneficiaireV!).code,
                              dateModif: DateTime.now(),
                              dateCree: versement.dateCree,
                              modifParCode: userCode,
                              montant: double.parse(_montantControllerV.text),
                              sense: versement.sense,
                              etat: versement.etat,
                              date: parsedDate,
                              code: versement.code,
                              type: _selectedType,
                              id: versement.id,
                              creeParCode: versement.creeParCode,
                              caisse: selectedCaisse,
                              codeOperation: versement.codeOperation,
                            );

                            final db = await DbCreator.openDb();
                            final clientService = ClientServices(db);
                            final fournisseurService = FournisseurServices(db);

                            if (_selectedTypeV == "Client") {
                              final client = _clientsTest.firstWhere(
                                    (c) => c.nom == _selectedBeneficiaireV,
                              );

                              double ancienMontant = versement.montant;
                              double nouveauMontant = double.parse(_montantControllerV.text);

                              await clientService.modifVersement(
                                client.id,
                                ancienMontant,
                                nouveauMontant,
                              );
                            } else if (_selectedTypeV == "Fournisseur") {
                              final fournisseur = _fournisseursTest.firstWhere(
                                    (c) => c.nom == _selectedBeneficiaireV,
                              );

                              double ancienMontant = versement.montant;
                              double nouveauMontant = double.parse(_montantControllerV.text);

                              await fournisseurService.modifVersement(
                                fournisseur.id,
                                ancienMontant,
                                nouveauMontant,
                              );
                            }

                            final caisseChoisieModif = _caissesTest.where((c) => c.nomCaisse == selectedCaisse).firstOrNull;
                            if (caisseChoisieModif == null) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.payment,
                                message: l10n.cashRegisterRequired,
                              );
                              return;
                            }

                            // ✅ Session de caisse obligatoire uniquement quand
                            // le montant change réellement (le mouvement de
                            // caisse lié va être mis à jour ou créé).
                            if (updatedVerssement.montant != versement.montant) {
                              final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseChoisieModif.code);
                              if (sessionOuverte == null) {
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.attention,
                                  titre_concerne: l10n.payment,
                                  message: l10n.aucuneSessionOuverte(caisseChoisieModif.nomCaisse),
                                );
                                return;
                              }
                            }

                            final response = await _updateVersment(
                              verssement: updatedVerssement,
                              ancienMontant: versement.montant.toString(),
                              caisseCode: caisseChoisieModif.code,
                              userCode: userCode,
                            );

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
                              onTerminer: () => Navigator.pop(context),
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.payment,
                              message: response.message ?? l10n.paymentModifiedSuccess,
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