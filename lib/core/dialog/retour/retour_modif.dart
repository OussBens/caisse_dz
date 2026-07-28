import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
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
import 'package:caisse_dz/core/dialog/insertion_client.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
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

final TextEditingController observationControllerR = TextEditingController();
final TextEditingController quantiteControllerR = TextEditingController();
final TextEditingController smartDateController = TextEditingController();

String? selectedType;
String? selectedTypeR;
String? selectedEtatR;
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
  required double Orignal,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final serviceh = await HistoriqueServices(db);
  final serviceM = await MouvementsServices(db);
  final serviceP = await ProduitServices(db);
  final services = await RetourServices(db);
  final serviceC = await GCServices(db);
  final mouv = await MouvementsServices.getAllMouvementsByCodeOper(retour.code);

  final prods = await ProduitServices.getAllProduits();
  Produit prod = prods.where((e) => e.code == retour.codeProduit).first;
  if (retour.fournisseur_code != null) {
    prod.quantite = prod.quantite + (Orignal - retour.quantite);
    prod.dateModif = DateTime.now();
    prod.modifParCode = userCode;
    await serviceP.updateProduit(prod);
  }
  if (retour.client_code != null) {
    prod.quantite = prod.quantite - (Orignal - retour.quantite);
    prod.dateModif = DateTime.now();
    prod.modifParCode = userCode;
    await serviceP.updateProduit(prod);
  }
  mouv.first.fournisseurCode = retour.fournisseur_code;
  mouv.first.quantite = retour.quantite;
  mouv.first.clientCode = retour.client_code;
  mouv.first.etat = retour.etat;
  mouv.first.date = retour.date;

  await serviceM.updateMouvement(mouv.first);

  final response = await services.updateRetour(retour);

  int idh = await _GetNextHistoriqueId();

  Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "Retours",
      desc: "L'utilisateur $userName modifee le Retour ${retour.code} de Produit ${prod.nom}",
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
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  double Orignal = retour.quantite;

  observationControllerR.text = retour.observation.toString();
  quantiteControllerR.text = retour.quantite.toString();
  smartDateController.text = "${retour.date.day}-${retour.date.month}-${retour.date.year}";

  selectedFournisseurR = fournisseursTest.where((f) => f.code == retour.fournisseur_code).firstOrNull?.nom;
  selectedNomProduitR = produitsTest.where((p) => p.code == retour.codeProduit).firstOrNull?.nom;
  selectedClientR = clientsTest.where((c) => c.code == retour.client_code).firstOrNull?.nom;
  selectedTypeR = retour.type;
  selectedEtatR = retour.etat ? l10n.active : l10n.inactive;
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
                                obligatoire: true,
                                label: l10n.status,
                                child: TextListe(
                                  value: selectedEtatR,
                                  obligatoire: true,
                                  items: translator.etatDisplayList,
                                  onChanged: (v) => setState(() {
                                    selectedEtatR = v;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),
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
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
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
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  numeric: true,
                                  controller: quantiteControllerR,
                                  hint: "",
                                ),
                              ),
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
                                label: l10n.type,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedType,
                                  items: translator.typeRetourDisplayList,
                                  onChanged: (v) {
                                    setState(() {
                                      selectedType= v;
                                      selectedTypeR = translator.typeRetourToFrench(v!);
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (isTypeFournisseur)
                                ChampAvecLabel(
                                  label: l10n.supplier,
                                  buttonAjout: true,
                                  onAjoutPressed: () async {
                                    await showDialog(
                                      context: context,
                                      barrierColor: Appstyle.gris.withOpacity(0.25),
                                      builder: (_) {
                                        return InsertionFournisseurDialog(
                                          fournisseurs: fournisseursTest,
                                          onFournisseurSelected: (fournisseur) {
                                            setState(() {
                                              selectedFournisseurR = fournisseur.nom;
                                              retour.fournisseur_code = fournisseur.code;
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  obligatoire: true,
                                  child: TextListe(
                                    obligatoire: true,
                                    value: selectedFournisseurR,
                                    items: fournisseursTest.map((f) => f.nom).toList(),
                                    onChanged: (v) => setState(() {
                                      selectedFournisseurR = v;
                                      retour.fournisseur_code = fournisseursTest.where((e) => e.nom == v).first.code;
                                    }),
                                  ),
                                ),

                              if (!isTypeFournisseur)
                                ChampAvecLabel(
                                  label: l10n.client,
                                  obligatoire: true,
                                  buttonAjout: true,
                                  onAjoutPressed: () async {
                                    await showDialog(
                                      context: context,
                                      barrierColor: Appstyle.gris.withOpacity(0.25),
                                      builder: (_) {
                                        return InsertionClientDialog(
                                          clients: clientsTest,
                                          onClientSelected: (client) {
                                            setState(() {
                                              selectedClientR = client.nom;
                                              retour.client_code = client.code;
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: TextListe(
                                    value: selectedClientR,
                                    obligatoire: true,
                                    items: clientsTest.map((c) => c.nom).toList(),
                                    onChanged: (v) => setState(() {
                                      selectedClientR = v;
                                      retour.client_code = clientsTest.where((e) => e.nom == v).first.code;
                                    }),
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
                            retour.quantite = double.parse(quantiteControllerR.text);
                            retour.type = selectedTypeR!;
                            retour.modifParCode = userCode;
                            retour.dateModif = DateTime.now();
                            retour.etat = selectedEtatR == l10n.active;
                            retour.observation = observationControllerR.text;

                            final response = await _UpdateR(
                              retour: retour,
                              Orignal: Orignal,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
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