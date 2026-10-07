import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

/// Modification d'un retour déjà enregistré : le contenu (produit, quantité,
/// prix, type, bénéficiaire) est verrouillé dès l'enregistrement — même
/// principe que Pannier/SmartScan. Le remboursement lié (Versement) est
/// toujours quantité×prix, jamais un paiement partiel séparé, donc rien à
/// resynchroniser ici : seules la date et l'observation restent modifiables.
/// Une correction du contenu passe par une annulation.
final TextEditingController observationControllerR = TextEditingController();
final TextEditingController quantiteControllerR = TextEditingController();
final TextEditingController nombreControllerR = TextEditingController();
final TextEditingController smartDateController = TextEditingController();

String? selectedType;
String? selectedTypeR;
String? selectedClientR;
String? selectedNomProduitR;
String? selectedFournisseurR;

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

List<Client> clientsTest = [];
List<Produit> produitsTest = [];
List<Fournisseur> fournisseursTest = [];
List<CaisseParam> params = [];
List<CaisseGestion> Caisses = [];

Future<void> _LoadAllData() async {
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  produitsTest = await ProduitServices.getAllProduits();
  clientsTest = await ClientServices.getAllClients();
  Caisses = await GCServices.getAllCaisses();
  params = await CaisseParamServices.getAllCaisseParam();
}

Future<ApiResponse<int>> _UpdateR({
  required Retour retour,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final services = RetourServices(db);

  final response = await services.updateRetour(retour);
  if (!response.success) {
    return response;
  }

  // Répercuter la date sur le mouvement de stock lié — le contenu ne change
  // plus, seule la date peut être corrigée.
  final mouv = await MouvementsServices.getAllMouvementsByCodeOper(retour.code);
  if (mouv.isNotEmpty) {
    final m = mouv.first;
    m.date = retour.date;
    m.dateModif = DateTime.now();
    m.modifParCode = userCode;
    await serviceM.updateMouvement(m);
  }

  final produits = await ProduitServices.getAllProduits();
  final prod = produits.where((e) => e.code == retour.codeProduit).firstOrNull;

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "Retours",
      desc: "L'utilisateur $userName a modifié la date/observation du Retour ${retour.code}"
          "${prod != null ? ' de Produit ${prod.nom}' : ''}",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode);
  await serviceh.addHistorique(histo);
  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> RetourModif(BuildContext context, Retour retour) async {
  await _LoadAllData();
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

  observationControllerR.text = retour.observation.toString();
  quantiteControllerR.text = QuantiteFormat.format(retour.quantite);
  nombreControllerR.text = retour.nombre != null ? QuantiteFormat.format(retour.nombre!) : '';
  smartDateController.text = "${retour.date.day}-${retour.date.month}-${retour.date.year}";

  selectedFournisseurR = fournisseursTest.where((f) => f.code == retour.fournisseur_code).firstOrNull?.nom;
  selectedNomProduitR = produitsTest.where((p) => p.code == retour.codeProduit).firstOrNull?.nom;
  final bool afficheNombreR = produitsTest.where((p) => p.code == retour.codeProduit).firstOrNull?.nombreActif ?? false;
  selectedClientR = clientsTest.where((c) => c.code == retour.client_code).firstOrNull?.nom;
  selectedTypeR = retour.type;
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          bool isTypeFournisseur = (selectedTypeR == "Fournisseur");
          selectedType  = translator.translateTypeRetour(selectedTypeR!);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 420,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/retour_icon.png',
                  text: l10n.modifyReturn,
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
                                label: l10n.number,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: TextEditingController(
                                    text: retour.code.toString(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.product,
                                child: TextListe(
                                  clearable: false,
                                  value: selectedNomProduitR,
                                  items: produitsTest.map((p) => p.nom).toList(),
                                  enabled: false,
                                  onChanged: (String? p1) {},
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.date,
                                obligatoire: true,
                                child: TextDate(
                                  obligatoire: true,
                                  controller: smartDateController,
                                  hint: "25 Nov 2025",
                                  onTap: () async {
                                    DateTime? picked = await showDatePicker(
                                      context: context,
                                      initialDate: retour.date,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2100),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        retour.date = picked;
                                        smartDateController.text = "${picked.day}-${picked.month}-${picked.year}";
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.quantity,
                                child: TextChampL(
                                  numeric: true,
                                  isQuantite: true,
                                  uniteMesure: produitsTest.firstWhereOrNull((p) => p.nom == selectedNomProduitR)?.uniteMesure,
                                  enabled: false,
                                  controller: quantiteControllerR,
                                  hint: "",
                                ),
                              ),
                              if (afficheNombreR) ...[
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberField,
                                  child: TextChampL(
                                    numeric: true,
                                    isQuantite: true,
                                    uniteMesure: QuantiteFormat.unitePiece,
                                    enabled: false,
                                    controller: nombreControllerR,
                                    hint: "",
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.observation,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: observationControllerR,
                                  hint: "",
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
                                label: l10n.code,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: TextEditingController(
                                    text: retour.code,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.type,
                                child: TextListe(
                                  clearable: false,
                                  value: selectedType,
                                  items: translator.typeRetourDisplayList,
                                  enabled: false,
                                  onChanged: (v) {},
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (isTypeFournisseur)
                                ChampAvecLabel(
                                  label: l10n.supplier,
                                  child: TextChampL(
                                    controller: TextEditingController(text: selectedFournisseurR ?? ''),
                                    enabled: false,
                                    hint: '',
                                  ),
                                ),

                              if (!isTypeFournisseur)
                                ChampAvecLabel(
                                  label: l10n.client,
                                  child: TextChampL(
                                    controller: TextEditingController(text: selectedClientR ?? ''),
                                    enabled: false,
                                    hint: '',
                                  ),
                                ),

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.purchasePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: TextEditingController(
                                      text: retour.prixAchat.toString()),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.salePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: TextEditingController(
                                      text: retour.prixVente.toString()),
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
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.return_,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modification,
                          message: l10n.confirmModifyReturn,
                          onConfirmer: () async {
                            // ✅ retour.date est déjà à jour : mis à jour en
                            // direct par le sélecteur de date ci-dessus.
                            retour.modifParCode = userCode;
                            retour.dateModif = DateTime.now();
                            retour.observation = observationControllerR.text;

                            final response = await _UpdateR(
                              retour: retour,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.return_,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.return_,
                              message: response.message ?? l10n.returnModifiedSuccess,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
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
