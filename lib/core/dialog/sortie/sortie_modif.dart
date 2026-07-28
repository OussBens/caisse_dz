import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/besionlist/besoinlist_nouveau.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/sortie/sortie_nouveau.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

String? selectedEtatR;
List<Produit> produitsTest = [];
List<Categorie> categoriesTestSM = [];
List<SousCategorie> sousCategoriesTestSM = [];

Future<void> _LoadAllData() async {
  produitsTest = await ProduitServices.getAllProduits();
  categoriesTestSM = await CategorieServices.getAllCategorie();
  sousCategoriesTestSM = await SousCategoriesServices.getAllSousCategorie();
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateR({
  required String userName,
  required String userCode,
  required Sortie sortie,
  required double orignal,
}) async {
  final db = await DbCreator.openDb();
  final services = SortieServices(db);
  final servicep = ProduitServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);

  final produits = await ProduitServices.getAllProduits();
  final response = await services.updateSortie(sortie);
  final mouvement = await MouvementsServices.getAllMouvementsByCodeOper(sortie.code);

  mouvement.first.type = "Sortie (${sortie.type})";
  mouvement.first.quantite = sortie.quantite;
  mouvement.first.etat = sortie.etat;
  mouvement.first.date = sortie.date;
  mouvement.first.dateModif = DateTime.now();
  mouvement.first.modifParCode = userCode;
  mouvement.first.prixVente = sortie.prix;
  mouvement.first.codeProduit = sortie.produitCode;

  await serviceM.updateMouvement(mouvement.first);

  final prod = produits.where((e) => e.code == sortie.produitCode).first;
  prod.quantite = prod.quantite + (orignal - sortie.quantite);
  prod.dateModif = DateTime.now();
  prod.modifParCode = userCode;
  servicep.updateProduit(prod);

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "sortie",
      desc: "L'utilisateur $userName a Modifee les information de Sortie de Produit ${prod.nom}",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode
  );

  await serviceh.addHistorique(histo);
  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SortieModif(BuildContext context, Sortie sortie) async {
  await _LoadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;
  double orginal = sortie.quantite;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  TextEditingController codeControllerS = TextEditingController();
  TextEditingController prixControllerS = TextEditingController();
  TextEditingController montantControllerS = TextEditingController();
  TextEditingController quantiteControllerS = TextEditingController();
  TextEditingController observationControllerS = TextEditingController();
  TextEditingController dateControllerS = TextEditingController();

  String? selectedTypeS;
  String? selectedType;

  void calculerMontant() {
    final double qte = double.tryParse(quantiteControllerS.text.replaceAll(',', '.')) ?? 0;
    final double prix = double.tryParse(prixControllerS.text.replaceAll(',', '.')) ?? 0;
    final String montant = (qte * prix).toStringAsFixed(2);

    montantControllerS.value = TextEditingValue(
      text: montant,
      selection: TextSelection.collapsed(offset: montant.length),
    );
  }
  codeControllerS.text = sortie.code;
  prixControllerS.text = sortie.prix.toStringAsFixed(2);
  montantControllerS.text = sortie.montant.toStringAsFixed(2);
  quantiteControllerS.text = sortie.quantite.toString();
  observationControllerS.text = sortie.observation ?? "";

  selectedEtatR = sortie.etat ? l10n.active : l10n.inactive;
  dateControllerS.text = "${sortie.dateCree}";
  selectedTypeS = sortie.type;

  Produit prods = produitsTest.where((e) => e.code == sortie.produitCode).first;

  quantiteControllerS.removeListener(calculerMontant);
  prixControllerS.removeListener(calculerMontant);

  quantiteControllerS.addListener(calculerMontant);
  prixControllerS.addListener(calculerMontant);

  WidgetsBinding.instance.addPostFrameCallback((_) {
    calculerMontant();
  });

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          selectedType  = translator.translateTypeSortie(sortie.type);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 420,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/sortie_icon.png',
                  text: l10n.modifyExit,
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
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.status,
                                obligatoire: true,
                                child: TextListe(
                                  value: selectedEtatR,
                                  clearable: false,
                                  items: translator.etatDisplayList,
                                  onChanged: (v) => setState(() {
                                    selectedEtatR = translator.etatToFrench(v!);
                                  }),
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
                                            prods = p;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  clearable: false,
                                  value: prods.nom,
                                  obligatoire: true,
                                  items: produitsTest.map((e) => e.nom).toList(),
                                  onChanged: (v) => setState(() {
                                    prods = produitsTest.where((e) => e.nom == v).first;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.exitType,
                                obligatoire: true,
                                child: TextListe(
                                  value: selectedType,
                                  obligatoire: true,
                                  clearable: false,
                                  items: translator.typeSortieDisplayList,
                                  onChanged: (v) => setState(() {
                                    selectedType= v;
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
                                  hint: '',
                                  controller: dateControllerS,
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: sortie.dateCree,
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
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.price,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: prixControllerS,
                                  numeric: true,
                                  hint: '',
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.amount,
                                child: TextChampL(
                                  controller: montantControllerS,
                                  enabled: false,
                                  numeric: true,
                                  hint: '',
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
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modification,
                          message: l10n.confirmModifyExit,
                          onConfirmer: () async {
                            sortie.modifParCode = userCode;
                            sortie.dateModif = DateTime.now();
                            sortie.etat = selectedEtatR == l10n.active;
                            sortie.observation = observationControllerS.text;
                            sortie.date = DateTime.parse(dateControllerS.text);
                            sortie.montant = double.parse(montantControllerS.text);
                            sortie.prix = double.parse(prixControllerS.text);
                            sortie.quantite = double.parse(quantiteControllerS.text);
                            sortie.type = selectedTypeS!;
                            sortie.produitCode = prods.code;
                            sortie.categorieCode = categoriesTestSM
                                .where((c) => c.id == prods.categorieId)
                                .firstOrNull?.code;
                            sortie.sousCategorieCode = sousCategoriesTestSM
                                .where((sc) => sc.id == prods.sousCategorieId)
                                .firstOrNull?.code;

                            final response = await _UpdateR(
                                userName: userName,
                                userCode: userCode,
                                sortie: sortie,
                                orignal: orginal
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
                              message: response.message ?? l10n.exitModifiedSuccess,
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