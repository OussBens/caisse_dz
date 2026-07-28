import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/core/dialog/versement/versement_nouveau.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/constant.dart';
import '../../../data/models/verssement.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
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

List<Fournisseur> _fournisseursTest = [];
List<Client>      _clientsTest      = [];
List<CaisseGestion>      _caissesTest      = [];

Future<void> _loadAllData() async {
  final client       = await ClientServices.getAllClients();
  final fournisseur  = await FournisseurServices.getAllFournisseurs();
  final caisse  = await GCServices.getAllCaisses();

  _clientsTest = client;
  _fournisseursTest = fournisseur;
  _caissesTest = caisse;
}

Future<ApiResponse<int>> _updateVersment({required Verssement verssement}) async {
  final db = await DbCreator.openDb();
  final services = VerssementServices(db);
  return await services.updateVerssement(verssement);
}

String selectedCaisse = "";
String? selectedTypeV;
String? selectedBeneficiaireV;
String selectedEtatV = "";
String selectedModePaiement = "";
String selectedType = "";

final TextEditingController smartDateController = TextEditingController();
final TextEditingController observationControllerV = TextEditingController();
final TextEditingController montantControllerV = TextEditingController();
final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> VersementModifRetour(
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

  await _loadAllData();

  montantControllerV.text = versement.montant.abs().toString();
  observationControllerV.text = versement.observation.toString();
  smartDateController.text = "${versement.date.day}-${versement.date.month}-${versement.date.year}";
  selectedCaisse = versement.caisse;
  selectedTypeV = typeInitial ?? versement.typebeneficiare;
  selectedBeneficiaireV = selectedTypeV == "Client"
      ? _clientsTest.firstWhere((c) => c.code == versement.beneficiareCode, orElse: () => _clientsTest.first).nom
      : _fournisseursTest.firstWhere((f) => f.code == versement.beneficiareCode, orElse: () => _fournisseursTest.first).nom;
  selectedEtatV = versement.etat ? l10n.validated : l10n.cancelled;
  selectedModePaiement = versement.mode_paiement;
  selectedType = versement.type ?? "";

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          bool isClient = selectedTypeV == "Client";

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 450,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/devise_icon.png',
                  text: l10n.modifyPaymentExit,
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
                              label: l10n.status,
                              obligatoire: true,
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedEtatV,
                                items: [l10n.validated, l10n.cancelled],
                                onChanged: (v) =>
                                    setState(() => selectedEtatV = v!),
                              ),
                            ),

                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.number,
                              obligatoire: true,
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
                                            selectedBeneficiaireV = c.nom;
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
                                            selectedBeneficiaireV = f.nom;
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
                                onChanged: (v) =>
                                    setState(() => selectedBeneficiaireV = v),
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              label: l10n.date,
                              obligatoire: true,
                              child: TextDate(
                                controller: smartDateController,
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
                                      smartDateController.text =
                                      "${picked.day}-${picked.month}-${picked.year}";
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),

                            ChampAvecLabel(
                              obligatoire: true,
                              label: l10n.paymentMethod,
                              child: TextListe(
                                obligatoire: true,
                                value: selectedModePaiement,
                                items: translator.modePaiementDisplayList,
                                onChanged: (v) =>
                                    setState(() => selectedModePaiement = translator.modePaiementToFrench(v!)),
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
                              label: l10n.paymentType,
                              child: TextListe(
                                value: selectedType,
                                items: translator.typeVersementDetailDisplayList,
                                onChanged: (v) =>
                                    setState(() => selectedType = translator.typeVersementToFrench(v!)),
                              ),
                            ),

                            const SizedBox(height: 10),

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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.modify,
                      icon: Icons.save,
                      color: Appstyle.jaune,
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
                          titre: l10n.paymentExit,
                          message: l10n.confirmModifyPayment,
                          onConfirmer: () async {
                            final dateParts = smartDateController.text.split('-');
                            final parsedDate = DateTime(
                              int.parse(dateParts[2]),
                              int.parse(dateParts[1]),
                              int.parse(dateParts[0]),
                            );

                            Verssement updatedVerssement = Verssement(
                              typebeneficiare: selectedTypeV!,
                              mode_paiement: selectedModePaiement,
                              beneficiareCode: selectedTypeV == "Client"
                                  ? _clientsTest.firstWhere((c) => c.nom == selectedBeneficiaireV!).code
                                  : _fournisseursTest.firstWhere((f) => f.nom == selectedBeneficiaireV!).code,
                              dateModif: DateTime.now(),
                              dateCree: versement.dateCree,
                              modifParCode: userCode,
                              montant: double.parse(montantControllerV.text),
                              sense: versement.sense,
                              etat: selectedEtatV == l10n.validated,
                              date: parsedDate,
                              code: versement.code,
                              type: selectedType,
                              id: versement.id,
                              creeParCode: versement.creeParCode,
                              caisse: selectedCaisse,
                            );

                            final db = await DbCreator.openDb();
                            final clientService = ClientServices(db);
                            final founisseurService = FournisseurServices(db);

                            if (selectedTypeV == "Client") {
                              final client = _clientsTest.firstWhere(
                                    (c) => c.nom == selectedBeneficiaireV,
                              );

                              double ancienMontant = versement.montant;
                              double nouveauMontant = double.parse(montantControllerV.text);

                              await clientService.modifVersementRetour(
                                client.id,
                                ancienMontant,
                                nouveauMontant,
                              );
                            } else if (selectedTypeV == "Fournisseur") {
                              final fournisseur = _fournisseursTest.firstWhere(
                                    (c) => c.nom == selectedBeneficiaireV,
                              );

                              double ancienMontant = versement.montant;
                              double nouveauMontant = double.parse(montantControllerV.text);

                              await founisseurService.modifVersementRetour(
                                fournisseur.id,
                                ancienMontant,
                                nouveauMontant,
                              );
                            }

                            final response = await _updateVersment(verssement: updatedVerssement);

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