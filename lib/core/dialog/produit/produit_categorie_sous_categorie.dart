import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/produit.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];

String _nomCategorie(int? id) =>
    categoriesTest.where((c) => c.id == id).firstOrNull?.nom ?? '';

String _nomSousCategorie(int? id) =>
    sousCategoriesTest.where((sc) => sc.id == id).firstOrNull?.nom ?? '';

Future<void> loadAllData() async {
  try {
    final cate = await CategorieServices.getAllCategorie();
    final sous = await SousCategoriesServices.getAllSousCategorie();
    categoriesTest = cate;
    sousCategoriesTest = sous;
  } catch (e) {
    debugPrint("Erreur chargement : $e");
  }
}

Future<ApiResponse<int>> _updateProduit({
  required List<Produit> produits,
  required Categorie categorie,
  required SousCategorie sous,
  required String userName,
  required String userCode,
}) async {
  if (sous.categorieCode != categorie.code) {
    return ApiResponse(
      success: false,
      message: "La sous-catégorie ne correspond pas à la catégorie choisie.",
      data: 0,
    );
  }

  final db = await DbCreator.openDb();
  final services = ProduitServices(db);
  final sousService = SousCategoriesServices(db);
  ApiResponse<int>? lastResponse;

  for (var produit in produits) {
    produit.categorieId = categorie.id;
    produit.sousCategorieId = sous.id;
    produit.dateModif = DateTime.now();
    produit.modifParCode = userCode;
    lastResponse = await services.updateProduit(produit);

    final db = await DbCreator.openDb();
    final int idH = await _GetNextHistoriqueId();
    final serviceh = await HistoriqueServices(db);

    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a changer le categorie et le sousCategorie de Produit ${produit.nom}",
        oper: ListsConst.typeHisto[2],
        type: "Produit",
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histo);
  }
  return lastResponse!;
}

Future<void> CategorieSousCategorieProduit(
    BuildContext context, List<Produit> produitsSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: "Authentification",
      titre_concerne: "Utilisateur",
      message: "Vous devez être connecté pour changé Categorié & Sous catégorié.",
    );
    return;
  }

  await loadAllData();
  String? selectedCategorie = categoriesTest.isNotEmpty ? categoriesTest.first.nom : null;
  String? selectedSousCategorie = sousCategoriesTest.isNotEmpty ? sousCategoriesTest.first.nom : null;
  Categorie selectedcate = categoriesTest.first;
  SousCategorie selectedsous = sousCategoriesTest.firstWhere(
        (sc) => sc.categorieCode == selectedcate.code,
    orElse: () => sousCategoriesTest.first,
  );

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/categorie_icon.png',
                  text: l10n.applyCategorySubcategory,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedProducts,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: produitsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final p = produitsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${p.nom} (${p.code})",
                                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                                    ),
                                  ),
                                  if (_nomCategorie(p.categorieId).isNotEmpty)
                                    Text(
                                      _nomCategorie(p.categorieId),
                                      style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                                    ),
                                  if (_nomCategorie(p.categorieId).isNotEmpty)
                                    const SizedBox(width: 40),
                                  if (_nomSousCategorie(p.sousCategorieId).isNotEmpty)
                                    Text(
                                      _nomSousCategorie(p.sousCategorieId),
                                      style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ChampAvecLabel(
                      label: l10n.category,
                      child: TextListe(
                        value: selectedCategorie ?? "",
                        items: categoriesTest.map((c) => c.nom).toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            selectedCategorie = v;
                            selectedcate = categoriesTest.firstWhere((r) => r.nom == v);
                            final sousPourCategorie = sousCategoriesTest
                                .where((sc) => sc.categorieCode == selectedcate.code)
                                .toList();
                            if (sousPourCategorie.isNotEmpty) {
                              selectedSousCategorie = sousPourCategorie.first.nom;
                              selectedsous = sousPourCategorie.first;
                            } else {
                              selectedSousCategorie = null;
                              selectedsous = SousCategorie(
                                  nom: "",
                                  code: "",
                                  etat: false,
                                  categorieCode: "",
                                  id: 0,
                                  dateCree: DateTime.now(),
                                  creeParCode: '',
                                  categorieId: 0);
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    ChampAvecLabel(
                      label: l10n.subcategory,
                      child: TextListe(
                        value: selectedSousCategorie,
                        items: sousCategoriesTest
                            .where((sc) => sc.categorieCode == selectedcate.code)
                            .map((sc) => sc.nom)
                            .toList(),
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() {
                            selectedSousCategorie = v;
                            selectedsous = sousCategoriesTest.firstWhere((r) => r.nom == v);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.confirmation,
                          message: l10n.confirmModifyCategorySubcategory(produitsSelectionnes.length),
                          onConfirmer: () async {
                            final response = await _updateProduit(
                              produits: produitsSelectionnes,
                              categorie: selectedcate,
                              sous: selectedsous,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.product,
                                message: l10n.categorySubcategoryModifiedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                },
                              );
                            } else {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.product,
                                message: response.message ?? l10n.errorOccurred,
                              );
                            }
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