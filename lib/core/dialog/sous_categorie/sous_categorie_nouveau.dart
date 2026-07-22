import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../../Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_categorie.dart';

final TextEditingController sousCategorieNomController = TextEditingController();
final TextEditingController sousCategorieDescController = TextEditingController();
String? selectedCategorie;
String code = '';
int id = 0;
List<Produit> produitSouscategorie = [];
List<Produit> produitsTest = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

void resetSousCategorieForm() {
  sousCategorieNomController.clear();
  sousCategorieDescController.clear();
  selectedCategorie = null;
  produitSouscategorie.clear();
}

List<Categorie> categoriesTest = [];

Future<void> _SaveSousCategorieData({
  required SousCategorie sousCategorie,
  required List<Produit> produits,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = SousCategoriesServices(db);
  final produitService = ProduitServices(db);
  final serviceH = HistoriqueServices(db);
  final sousCatService = SousCategoriesServices(db);

  await services.addSousCategorie(sousCategorie);

  final idH = await _GetNextHistoriqueId();
  await serviceH.addHistorique(Historique(
    id: idH,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: idH,
    ), // ✅ Utilisation du générateur
    desc: "Utilisateur $userName a créé la sous-catégorie ${sousCategorie.nom}",
    type: "SousCategorie",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));

  for (var produit in produits) {
    produit.sousCategorie = sousCategorie.nom;
    produit.sousCategorieId = sousCategorie.id;
    produit.categorie = sousCategorie.categorieNom;
    produit.categorieId = sousCategorie.categorieId;
    produit.modifParCode = userName;
    produit.dateModif = DateTime.now();

    await produitService.updateProduit(produit);

    final idN = await _GetNextHistoriqueId();
    await serviceH.addHistorique(Historique(
      id: idN,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idN,
      ), // ✅ Utilisation du générateur
      desc: "Utilisateur $userName a assigné ${sousCategorie.nom} au produit ${produit.nom}",
      type: "Produit",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));
  }
}

Future<void> _loadData() async {
  categoriesTest = await CategorieServices.getAllCategorie();
  categoriesTest.removeWhere((c) => c.code == "CATE0000");
  final result = await ProduitServices.getAllProduits();
  produitsTest = result;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SousCategoriesServices.getNextSousCategorieId(txn);
  });
  return id;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SousCategorieNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  await _loadData();
  id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour la sous-catégorie
  code = CodeGenerator.generateCode(
    prefix: CodePrefix.sousCategorie,
    id: id,
    digitCount: 6, // "SC000001"
  );

  int categorieid = 0;

  if (categoriesTest.isNotEmpty) {
    selectedCategorie = categoriesTest.first.nom;
    categorieid = categoriesTest.first.id;
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/sous_catego_icon.png',
                  text: l10n.newSubcategory,
                ),
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.name,
                          child: TextChampL(
                            controller: sousCategorieNomController,
                            obligatoire: true,
                            hint: l10n.subcategoryNameHint,
                          ),
                        ),

                        const SizedBox(height: 20),

                        ChampAvecLabel(
                          obligatoire: true,
                          label: l10n.category,
                          buttonAjout: true,
                          onAjoutPressed: () async {
                            await showDialog(
                              context: context,
                              barrierColor: Appstyle.gris.withOpacity(0.25),
                              builder: (_) {
                                return InsertionCategorieDialog(
                                  categories: categoriesTest,
                                  onCategorieSelected: (categorie) {
                                    setState(() {
                                      selectedCategorie = categorie.nom;
                                      categorieid = categorie.id;
                                    });
                                  },
                                );
                              },
                            );
                          },
                          child: TextListe(
                            clearable: false,
                            obligatoire: true,
                            value: selectedCategorie,
                            items: categoriesTest.map((c) => c.nom).toList(),
                            onChanged: (v) {
                              setState(() {
                                selectedCategorie = v;
                                categorieid = categoriesTest.firstWhere((u) => u.nom == v).id;
                              });
                            },
                          ),
                        ),

                        const SizedBox(height: 20),

                        ChampAvecLabel(
                          label: l10n.observation,
                          child: TextChampL(
                            controller: sousCategorieDescController,
                            hint: l10n.observationHint,
                          ),
                        ),

                        const SizedBox(height: 20),

                        TitleSmall(
                          imagePath: 'assets/icons/sidebar/produit_icon.png',
                          text: l10n.affectedProducts,
                          couleur: Appstyle.violet,
                        ),

                        const SizedBox(height: 10),

                        _headerTableProduits(l10n),

                        const SizedBox(height: 6),

                        _tableProduits(setState, l10n),

                        const SizedBox(height: 10),

                        GestureDetector(
                          onTap: () {
                            Future.microtask(() {
                              _ouvrirInsertionProduit(context, setState, l10n);
                            });
                          },    child: const AddManualWidget(),
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
                      onPressed: () {
                        resetSousCategorieForm();
                        Navigator.pop(context);
                      },
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.subcategory,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final nouvelleSousCategorie = SousCategorie(
                          id: id,
                          nom: sousCategorieNomController.text,
                          observation: sousCategorieDescController.text,
                          categorieNom: selectedCategorie ?? '',
                          code: code, // ✅ Code généré automatiquement
                          etat: true,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                          categorieId: categorieid,
                        );

                        await _SaveSousCategorieData(
                          sousCategorie: nouvelleSousCategorie,
                          produits: produitSouscategorie,
                          userName: userName,
                          userCode: userCode,
                        );

                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.subcategory,
                          message: l10n.subcategorySavedSuccess,
                          onTerminer: () => Navigator.pop(context),
                        );

                        resetSousCategorieForm();
                      },
                      color: Appstyle.violet,
                      icon: Icons.save,
                    )
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

Widget _headerTableProduits(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(l10n.code,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 4,
          child: Text(l10n.product,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 4,
          child: Text(l10n.currentSubcategory,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

Widget _tableProduits(
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ) {
  if (produitSouscategorie.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAdded,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Column(
    children: produitSouscategorie.map((p) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(p.code, style: Appstyle.textSB)),
            Expanded(flex: 4, child: Text(p.nom, style: Appstyle.textSB)),
            Expanded(flex: 4, child: Text(p.sousCategorie ?? "-", style: Appstyle.textSB)),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  produitSouscategorie.remove(p);
                });
              },
            ),
          ],
        ),
      );
    }).toList(),
  );
}

void _ouvrirInsertionProduit(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ) {
  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      multiselection: true,
      produits: produitsTest,
      onProduitSelected: (Produit produit) {
        Future.microtask(() {
          setState(() {
            if (!produitSouscategorie.any((p) => p.id == produit.id)) {
              produitSouscategorie.add(produit);
            }
          });
        });
      },
    ),
  );
}