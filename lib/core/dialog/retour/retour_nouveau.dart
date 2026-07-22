import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_client.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

final TextEditingController observationControllerN = TextEditingController();
final TextEditingController prixAchatControllerN = TextEditingController();
final TextEditingController prixVenteControllerN = TextEditingController();
final TextEditingController quantiteControllerN = TextEditingController();
final TextEditingController dateController = TextEditingController();

void resetSortieForm() {
  quantiteControllerN.clear();
  dateController.clear();
  observationControllerN.clear();
  newSelectedTypeR = null;
  newSelectedClientR = null;
  newSelectedProduitR = null;
  newSelectedFournisseurR = null;
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
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
    lastDate: DateTime(2100),
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

Future<int> _GetNextHistoriqueId() async {
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
    id = await RetourServices.getNextRetourId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveRetour({
  required String userName,
  required String userCode,
  required Retour retour,
}) async {
  final db = await DbCreator.openDb();
  final serviceh = await HistoriqueServices(db);
  final serviceM = await MouvementsServices(db);
  final serviceP = await ProduitServices(db);
  final services = await RetourServices(db);
  final serviceC = await GCServices(db);
  final serviceClient = ClientServices(db);
  final serviceFournisseur = FournisseurServices(db);

  final response = await services.addRetour(retour);
  final prod = await ProduitServices.getAllProduits();
  final param = params.where((e) => e.creeParCode == userCode).first;
  final caisse = Caisses.where((e) => e.nomCaisse == param.selectedCaisse).first;

  // ✅ Convertir la quantité en int une seule fois
  final int quantiteInt = retour.quantite.toInt();

  if (retour.fournisseur != null) {
    final montant = retour.quantite * retour.prixVente!;
    caisse.soldeInitial = caisse.soldeInitial + montant;
    await serviceC.updateCaisse(caisse);

    Produit produit = prod.where((e) => e.nom == retour.nomProduit).first;
    produit.quantite = produit.quantite - retour.quantite;
    produit.dateModif = DateTime.now();
    produit.modifParCode = userName;
    await serviceP.updateProduit(produit);

    // ✅ AUGMENTER LE NOMBRE DE RETOURS DU FOURNISSEUR
    final fournisseur = fournisseursTest.firstWhere(
          (f) => f.nom == retour.fournisseur,
      orElse: () => throw Exception("Fournisseur introuvable"),
    );
    await serviceFournisseur.ajouterRetour(fournisseur.id, montant);
  }

  if (retour.client != null) {
    final montant = retour.quantite * retour.prixVente!;
    caisse.soldeInitial = caisse.soldeInitial - montant;
    await serviceC.updateCaisse(caisse);

    Produit produit = prod.where((e) => e.nom == retour.nomProduit).first;
    produit.quantite = produit.quantite + retour.quantite;
    produit.dateModif = DateTime.now();
    produit.modifParCode = userName;
    await serviceP.updateProduit(produit);

    // ✅ AUGMENTER LE NOMBRE DE RETOURS DU CLIENT
    final client = clientsTest.firstWhere(
          (c) => c.nom == retour.client,
      orElse: () => throw Exception("Client introuvable"),
    );
    await serviceClient.ajouterRetour(client.id, montant);
  }

  // Historique
  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: idh,
    ),
    type: "Retour",
    desc: "L'utilisateur $userName a ajouté le Retour de Produit ${retour.nomProduit}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);

  // Mouvement
  idh = await _GetNextMouvementId();
  Mouvement mouv = Mouvement(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.mouvement,
      id: idh,
    ),
    date: retour.date,
    type: ListsConst.typeMouvement[2],
    etat: true,
    quantite: quantiteInt.toDouble(),
    dateCree: DateTime.now(),
    prixAchat: retour.prixAchat!,
    prixVente: retour.prixVente!,
    nomProduit: retour.nomProduit,
    codeProduit: retour.codeProduit,
    fournisseur: retour.fournisseur,
    creeParCode: userCode,
    codeOperation: retour.code,
  );
  await serviceM.addMouvement(mouv);

  return response;
}
String? SelectedTypeR;
String? newSelectedTypeR;
String? newSelectedClientR;
String? newSelectedProduitR;
String? newSelectedFournisseurR;

List<Produit> produitsTest = [];
List<Client> clientsTest = [];
List<Fournisseur> fournisseursTest = [];
List<CaisseGestion> Caisses = [];
List<CaisseParam> params = [];

Future<void> _LoadAllData() async {
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  produitsTest = await ProduitServices.getAllProduits();
  clientsTest = await ClientServices.getAllClients();
  Caisses = await GCServices.getAllCaisses();
  params = await CaisseParamServices.getAllCaisseParam();
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> RetourNouveau(BuildContext context) async {
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

  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le retour
  String cod = CodeGenerator.generateCode(
    prefix: CodePrefix.retour,
    id: id,
    digitCount: 6, // "RET000001"
  );

  String ProdCode = "";
  String codetype = "";

  observationControllerN.clear();
  prixAchatControllerN.clear();
  prixVenteControllerN.clear();
  quantiteControllerN.clear();
  dateController.clear();

  newSelectedFournisseurR = null;
  newSelectedProduitR = null;
  newSelectedClientR = null;
  newSelectedTypeR = ListsConst.typeRetour.first;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.25),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          bool isTypeFournisseur = (newSelectedTypeR == "Fournisseur");
          SelectedTypeR = translator.typeRetourDisplayList.first;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 420,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/retour_icon.png',
                  text: l10n.newReturn,
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
                                    text: id.toString(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.product,
                                obligatoire: true,
                                buttonAjout: true,
                                onAjoutPressed: () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionProduitDialog(
                                        multiselection: false,
                                        produits: produitsTest,
                                        onProduitSelected: (p) {
                                          setState(() {
                                            newSelectedProduitR = p.nom;
                                            ProdCode = p.code;
                                            prixAchatControllerN.text = p.prixAchat.toString();
                                            prixVenteControllerN.text = p.prixVente.toString();
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  value: newSelectedProduitR,
                                  obligatoire: true,
                                  clearable: false,
                                  items: produitsTest.map((e) => e.nom).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      newSelectedProduitR = v;
                                      final p = produitsTest.firstWhere(
                                              (e) => e.nom == v);
                                      ProdCode = p.code;
                                      prixAchatControllerN.text = p.prixAchat.toString();
                                      prixVenteControllerN.text = p.prixVente.toString();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                obligatoire: true,
                                label: l10n.date,
                                child: TextDate(
                                  obligatoire: true,
                                  hint: "15 nov 2025",
                                  enabled: true,
                                  controller: dateController,
                                  onTap: () => pickDate(context, dateController),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.quantity,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  numeric: true,
                                  controller: quantiteControllerN,
                                  hint: "",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: observationControllerN,
                                  hint: l10n.observationHint,
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
                                  value:  SelectedTypeR,
                                  items: translator.typeRetourDisplayList,
                                  onChanged: (v) => setState(() {
                                    SelectedTypeR = v;
                                    newSelectedTypeR = translator.typeRetourToFrench(v!);
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (newSelectedTypeR == "Client")
                                ChampAvecLabel(
                                  label: l10n.client,
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
                                              newSelectedClientR = client.nom;
                                              codetype = client.code;
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  obligatoire: true,
                                  child: TextListe(
                                    clearable: false,
                                    obligatoire: true,
                                    value: newSelectedClientR,
                                    items: clientsTest.map((e) => e.nom).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        newSelectedClientR = v;
                                        codetype = clientsTest.where((e) => e.nom == v).first.code;
                                      });
                                    },
                                  ),
                                ),

                              if (newSelectedTypeR == "Fournisseur")
                                ChampAvecLabel(
                                  label: l10n.supplier,
                                  obligatoire: true,
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
                                              newSelectedFournisseurR = fournisseur.nom;
                                              codetype = fournisseur.code;
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: TextListe(
                                    value: newSelectedFournisseurR,
                                    obligatoire: true,
                                    clearable: false,
                                    items: fournisseursTest.map((e) => e.nom).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        newSelectedFournisseurR = v;
                                        codetype = fournisseursTest.where((e) => e.nom == v).first.code;
                                      });
                                    },
                                  ),
                                ),

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.purchasePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: prixAchatControllerN,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.salePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: prixVenteControllerN,
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
                      text: l10n.save,
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

                        if (newSelectedTypeR == "Client") {
                          Retour retour = Retour(
                            codeProduit: ProdCode,
                            creeParCode: userCode,
                            observation: observationControllerN.text,
                            client_code: codetype,
                            nomProduit: newSelectedProduitR!,
                            quantite: double.parse(quantiteControllerN.text),
                            dateCree: DateTime.now(),
                            prixAchat: double.parse(prixAchatControllerN.text),
                            prixVente: double.parse(prixVenteControllerN.text),
                            client: newSelectedClientR,
                            code: cod, // ✅ Code généré automatiquement
                            date: DateTime.parse(dateController.text),
                            type: newSelectedTypeR!,
                            etat: true,
                            id: id,
                          );

                          final response = await _SaveRetour(
                            userName: userName,
                            userCode: userCode,
                            retour: retour,
                          );
                          print(response.message);
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
                            message: response.message ?? l10n.returnSavedSuccess,
                            onTerminer: () {
                              resetSortieForm();
                              Navigator.pop(context);
                            },
                          );
                        } else {
                          Retour retour = Retour(
                            codeProduit: ProdCode,
                            creeParCode: userCode,
                            observation: observationControllerN.text,
                            nomProduit: newSelectedProduitR!,
                            fournisseur: newSelectedFournisseurR,
                            fournisseur_code: codetype,
                            quantite: double.parse(quantiteControllerN.text),
                            dateCree: DateTime.now(),
                            prixAchat: double.parse(prixAchatControllerN.text),
                            prixVente: double.parse(prixVenteControllerN.text),
                            code: cod, // ✅ Code généré automatiquement
                            date: DateTime.parse(dateController.text),
                            type: newSelectedTypeR!,
                            etat: true,
                            id: id,
                          );

                          final response = await _SaveRetour(
                            userName: userName,
                            userCode: userCode,
                            retour: retour,
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
                            message: response.message ?? l10n.returnSavedSuccess,
                            onTerminer: () {
                              resetSortieForm();
                              Navigator.pop(context);
                            },
                          );
                        }
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