import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}

Future<int> _GetNextSortieId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SortieServices.getNextSortieId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveSortie({
  required Mouvement mouv,
  required String userName,
  required String userCode,
  required Sortie sortie,
}) async {
  final db = await DbCreator.openDb();
  final services = SortieServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final servicep = ProduitServices(db);

  final produits = await ProduitServices.getAllProduits();
  final response = await services.addSortie(sortie);
  await serviceM.addMouvement(mouv);

  final prod = produits.where((e) => e.nom == sortie.produit).first;
  prod.quantite = prod.quantite - sortie.quantite;
  prod.modifPar = userName;
  prod.dateModif = DateTime.now();
  await servicep.updateProduit(prod);

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ), // ✅ Utilisation du générateur
      type: "sortie",
      desc: "L'utilisateur $userName a Ajoutee le Retour de Produit ${sortie.produit} de Type ${sortie.type}",
      oper: ListsConst.typeHisto[0],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);
  return response;
}

List<Produit> produitsTest = [];

final TextEditingController observationControllerS = TextEditingController();
final TextEditingController quantiteControllerS = TextEditingController();
final TextEditingController montantControllerS = TextEditingController(text: '0.00');
final TextEditingController codeControllerS = TextEditingController();
final TextEditingController prixControllerS = TextEditingController(text: '0.00');
final TextEditingController dateControllerS = TextEditingController();

String? selectedProduitS;
String? selectedTypeS;
String? selectedType;

Future<void> _LoadData() async {
  produitsTest = await ProduitServices.getAllProduits();
}

void calculerMontant() {
  final double qte = double.tryParse(quantiteControllerS.text) ?? 0;
  final double prix = double.tryParse(prixControllerS.text) ?? 0;
  final double montant = qte * prix;
  montantControllerS.text = montant.toStringAsFixed(2);
}

void resetSortieForm() {
  observationControllerS.clear();
  quantiteControllerS.clear();
  montantControllerS.clear();
  codeControllerS.clear();
  prixControllerS.clear();
  dateControllerS.clear();

  selectedProduitS = null;
  selectedTypeS = ListsConst.typeSortie.first;

  quantiteControllerS.removeListener(calculerMontant);
  prixControllerS.removeListener(calculerMontant);

  quantiteControllerS.addListener(calculerMontant);
  prixControllerS.addListener(calculerMontant);
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SortieNouveau(BuildContext context) async {
  await _LoadData();

  quantiteControllerS.removeListener(calculerMontant);
  prixControllerS.removeListener(calculerMontant);
  quantiteControllerS.addListener(calculerMontant);
  prixControllerS.addListener(calculerMontant);

  int id = await _GetNextSortieId();
  Produit? prod;

  // ✅ Utilisation du générateur de code pour la sortie
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.sortie,
    id: id,
    digitCount: 6, // "SRT000001"
  );
  codeControllerS.text = code;

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

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          selectedType  = translator.typeSortieDisplayList.first;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 420,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/sortie_icon.png',
                  text: l10n.newExit,
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
                                child: TextChampL(
                                  controller: codeControllerS,
                                  enabled: false,
                                  hint: "SRT000001",
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
                                            selectedProduitS = p.nom;
                                            prod = p;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedProduitS,
                                  items: produitsTest.map((e) => e.nom).toList(),
                                  onChanged: (v) => setState(() {
                                    selectedProduitS = v;
                                    prod = produitsTest.where((e) => e.nom == v).first;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.exitType,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedType,
                                  items: translator.typeSortieDisplayList,
                                  onChanged: (v) => setState(() {
                                    selectedType  = v;
                                    selectedTypeS = translator.typeSortieToFrench(v!);
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.date,
                                obligatoire: true,
                                child: TextDate(
                                  obligatoire: true,
                                  controller: dateControllerS,
                                  hint: l10n.dateHint,
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: DateTime.now(),
                                    );
                                    if (d != null) {
                                      dateControllerS.text = "$d";
                                    }
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
                                label: l10n.quantity,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: quantiteControllerS,
                                  numeric: true,
                                  hint: "0",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.price,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: prixControllerS,
                                  obligatoire: true,
                                  numeric: true,
                                  hint: "0.00",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.amount,
                                child: TextChampL(
                                  controller: montantControllerS,
                                  numeric: true,
                                  enabled: false,
                                  hint: "0.00",
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerS,
                                  hint: l10n.observationHint,
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
                        resetSortieForm();
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
                            titre_concerne: l10n.exit,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }
                        // ✅ Validation de la quantité (doit être > 0)
                        final double quantite = double.tryParse(quantiteControllerS.text) ?? 0;
                        if (quantite <= 0) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.entry,
                            message: l10n.quantityMustBeGreaterThanZero,
                          );
                          return;
                        }
                        Sortie sortie = Sortie(
                          id: id,
                          code: code, // ✅ Code généré automatiquement
                          prix: double.parse(prixControllerS.text),
                          type: selectedTypeS!,
                          etat: true,
                          date: DateTime.parse(dateControllerS.text),
                          creePar: userName,
                          produit: selectedProduitS!,
                          montant: double.parse(montantControllerS.text),
                          quantite: double.parse(quantiteControllerS.text),
                          dateCree: DateTime.now(),
                          categorie: prod!.categorie,
                          produitCode: prod!.code,
                          creeParCode: userCode,
                          observation: observationControllerS.text,
                          souscategorie: prod!.sousCategorie,
                        );

                        int idm = await _GetNextMouvementId();
                        Mouvement mouv = Mouvement(
                          id: idm,
                          code: CodeGenerator.generateCodeWithTimestamp(
                            prefix: CodePrefix.mouvement,
                            id: idm,
                          ), // ✅ Utilisation du générateur
                          date: DateTime.parse(dateControllerS.text),
                          nomProduit: selectedProduitS!,
                          codeProduit: prod!.code,
                          quantite: double.parse(quantiteControllerS.text),
                          prixAchat: prod!.prixAchat,
                          prixVente: double.parse(prixControllerS.text),
                          type: "Sortie ( $selectedTypeS )",
                          etat: true,
                          codeOperation: code,
                          dateCree: DateTime.now(),
                          creePar: userName,
                          creeParCode: userCode,
                        );

                        final response = await _SaveSortie(
                            mouv: mouv,
                            userName: userName,
                            userCode: userCode,
                            sortie: sortie
                        );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.exit,
                            message: response.message ?? l10n.errorOccurred,
                          );
                          return;
                        }

                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.exit,
                          message: response.message ?? l10n.exitSavedSuccess,
                          onTerminer: () {
                            resetSortieForm();
                            Navigator.pop(context);
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