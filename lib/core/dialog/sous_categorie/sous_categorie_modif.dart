import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
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
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
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

const String defaultSousCategorie = "Sans Sous-Catego";
const String defaultCategorie = "Sans Categorie";
const int defaultSousCategorieId = 1;
const int defaultCategorieId = 1;

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

final TextEditingController nomSousCategorieController = TextEditingController();
final TextEditingController descSousCategorieController = TextEditingController();
String? selectedCategorieNom;
int? newCategorieId;
List<Produit> produitsSouscategorie = [];
List<Produit> produitsSouscategorieOriginal = [];
List<Produit> produitsTest = [];
String? selectedEtatR;
List<Categorie> categoriesTest = [];

Future<void> _loadData({required int sousCategorieId}) async {
  categoriesTest = await CategorieServices.getAllCategorie();
  categoriesTest.removeWhere((c) => c.code == "CATE0000");
  produitsTest = await ProduitServices.getAllProduits();
  produitsSouscategorie = produitsTest.where((e) => e.sousCategorieId == sousCategorieId).toList();
  produitsSouscategorieOriginal = List.from(produitsSouscategorie);
}

Future<ApiResponse<int>> _saveSousCategorie({
  required SousCategorie sousCategorie,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final sousCatService = await SousCategoriesServices(db);
  final produitService = await ProduitServices(db);
  final histoService = await HistoriqueServices(db);

  final produitsSupprimes = produitsSouscategorieOriginal
      .where((p) => !produitsSouscategorie.any((x) => x.id == p.id))
      .toList();

  for (var produit in produitsSupprimes) {
    produit.sousCategorieId = defaultSousCategorieId;
    produit.categorieId = defaultCategorieId;
    produit.dateModif = DateTime.now();
    produit.modifParCode = userCode;

    await produitService.updateProduit(produit);
  }

  final existingSousCategorie = await db.query(
    'sous_categories',
    where: 'nom = ? AND id != ?',
    whereArgs: [sousCategorie.nom, sousCategorie.id],
  );
  if (existingSousCategorie.isNotEmpty) {
    return ApiResponse(success: false, message: "Un SousCategorie avec ce nom existe déjà");
  }

  for (var produit in produitsSouscategorie) {
    produit.sousCategorieId = sousCategorie.id;
    produit.categorieId = sousCategorie.categorieId;
    produit.dateModif = DateTime.now();
    produit.modifParCode = userCode;

    await produitService.updateProduit(produit);

    final int idN = await _GetNextHistoriqueId();
    final Historique histoProduit = Historique(
      id: idN,
      code: "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
      desc: "L'utilisateur $userName a modifié le produit ${produit.nom} pour la sous-catégorie ${sousCategorie.nom}",
      oper: ListsConst.typeHisto[1],
      type: 'Produit',
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await histoService.addHistorique(histoProduit);
  }

  await sousCatService.updateSousCategorie(sousCategorie);

  final int idH = await _GetNextHistoriqueId();
  final Historique histo = Historique(
    id: idH,
    code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
    desc: "L'utilisateur $userName a modifié la SousCategorie ${sousCategorie.nom}",
    oper: ListsConst.typeHisto[1],
    type: 'SousCategorie',
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await histoService.addHistorique(histo);

  return ApiResponse(success: true, message: "Sous-catégorie mise à jour avec succès", data: sousCategorie.id);
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SousCategorieModif(BuildContext context, SousCategorie sousCategorie) async {
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
      message: l10n.loginRequiredModify,
    );
    return;
  }

  nomSousCategorieController.text = sousCategorie.nom;
  descSousCategorieController.text = sousCategorie.observation ?? '';
  newCategorieId = sousCategorie.categorieId;
  selectedEtatR = sousCategorie.etat ? l10n.active : l10n.inactive;

  await _loadData(sousCategorieId: sousCategorie.id);
  selectedCategorieNom = categoriesTest.where((c) => c.code == sousCategorie.categorieCode).firstOrNull?.nom;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
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
                  imagePath: 'assets/icons/cardwidget/categorie_icon.png',
                  text: l10n.modifySubcategory,
                ),
                content: Form(
                  key: produitFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChampAvecLabel(
                        label: l10n.status,
                        obligatoire: true,
                        child: TextListe(
                          obligatoire: true,
                          clearable: false,
                          value: selectedEtatR,
                          items: translator.etatDisplayList,
                          onChanged: (v) => setState(() {
                            selectedEtatR = v;
                          }),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.name,
                        obligatoire: true,
                        child: TextChampL(
                          obligatoire: true,
                          controller: nomSousCategorieController,
                          hint: l10n.subcategoryNameHint,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                                    sousCategorie.categorieId = categorie.id;
                                    selectedCategorieNom = categorie.nom;
                                    newCategorieId = categorie.id;
                                  });
                                },
                              );
                            },
                          );
                        },
                        child: TextListe(
                          clearable: false,
                          obligatoire: true,
                          value: selectedCategorieNom ?? "",
                          items: categoriesTest.map((c) => c.nom).toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedCategorieNom = v;
                              final cat = categoriesTest.firstWhere((c) => c.nom == v);
                              newCategorieId = cat.id;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      ChampAvecLabel(
                        label: l10n.observation,
                        child: TextChampL(
                          controller: descSousCategorieController,
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

                      _tableProduits(setState, l10n, sousCategorie),

                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: () => _ouvrirInsertionProduit(context, setState, l10n),
                        child: AddManualWidget(),
                      ),
                    ],
                  ),
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                        text: l10n.modify,
                        icon: Icons.save,
                        color: Appstyle.violet,
                        onPressed: () async {
                          if (!produitFormKey.currentState!.validate()) return;

                          await ConfirmationDialog(
                            context: context,
                            titre: l10n.modification,
                            message: l10n.confirmModifySubcategory,
                            onConfirmer: () async {
                              try {
                                SousCategorie updated = SousCategorie(
                                  id: sousCategorie.id,
                                  nom: nomSousCategorieController.text.trim(),
                                  code: sousCategorie.code,
                                  etat: selectedEtatR == l10n.active,
                                  dateCree: sousCategorie.dateCree,
                                  creeParCode: sousCategorie.creeParCode,
                                  modifParCode: userCode,
                                  dateModif: DateTime.now(),
                                  categorieId: newCategorieId!,
                                  categorieCode: categoriesTest.where((c) => c.id == newCategorieId).firstOrNull?.code ?? "",
                                  observation: descSousCategorieController.text.trim(),
                                );

                                final response = await _saveSousCategorie(
                                  sousCategorie: updated,
                                  userName: userName,
                                  userCode: userCode,
                                );

                                if (!response.success) {
                                  await InformationDialog(
                                    context: context,
                                    titre_type_message: l10n.error,
                                    kind: DialogKind.refuser,
                                    titre_concerne: l10n.subcategory,
                                    message: response.message,
                                  );
                                  return;
                                }

                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.success,
                                  titre_concerne: l10n.subcategory,
                                  message: response.message ?? l10n.subcategoryModifiedSuccess,
                                  onTerminer: () => Navigator.pop(context),
                                );
                              } catch (e) {
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  kind: DialogKind.refuser,
                                  titre_concerne: l10n.subcategory,
                                  message: "${l10n.errorOccurred}: $e",
                                );
                              }
                            },
                          );
                        }
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

Widget _headerTableProduits(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(Appstyle.radiusSM),
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
    SousCategorie sousCategorie,
    ) {
  if (produitsSouscategorie.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAdded,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Column(
    children: produitsSouscategorie.map((p) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Text(p.code, style: Appstyle.textSB),
            ),
            Expanded(
              flex: 4,
              child: Text(p.nom, style: Appstyle.textSB),
            ),
            Expanded(
              flex: 4,
              child: Text(
                p.sousCategorieId == sousCategorie.id ? sousCategorie.nom : "-",
                style: Appstyle.textSB,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Appstyle.danger),
              onPressed: () {
                setState(() {
                  produitsSouscategorie.remove(p);
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
      newButton:false,
      multiselection: true,
      produits: produitsTest,
      onProduitSelected: (Produit produit) {
        setState(() {
          if (!produitsSouscategorie.any((p) => p.id == produit.id)) {
            produitsSouscategorie.add(produit);
          }
        });
      },
    ),
  );
}