import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/categorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../base_dialog.dart';
import '../information_dialog.dart';

// Contrôleurs pour le formulaire
final TextEditingController categorieNomController = TextEditingController();
final TextEditingController categorieObservController = TextEditingController();
int id = 0;
String cd = "";
List<Produit> produitsTest = [];

void resetCategorieForm() {
  categorieNomController.clear();
  categorieObservController.clear();
}

Future<void> _loadData(void Function(VoidCallback fn) setState) async {
  final result = await ProduitServices.getAllProduits();
  setState(() {
    produitsTest = result;
  });
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await CategorieServices.getNextCategorieId(txn);
  });
  return id;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _saveCategorie({
  required Categorie  categorie,
  required String     userName,
  required String     userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = CategorieServices(db);
  final serviceh = HistoriqueServices(db);
  final response = await services.addCategorie(categorie);

  final int idH   = await _GetNextHistoriqueId();
  final Historique histo = Historique(
      id          : idH,
      code        : CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idH,
      ), // ✅ Utilisation du générateur
      desc        : "l'utilisateur ${userName} Ajoutee la Categorie ${categorie.nom}",
      oper        : ListsConst.typeHisto[0],
      type        : "Categorie",
      dateCree    : DateTime.now(),
      creeParCode : userCode
  );
  await serviceh.addHistorique(histo);

  return response;
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> CategorieNouveau(BuildContext context) async{
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  /////
  id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour la catégorie
  cd = CodeGenerator.generateCode(
    prefix: CodePrefix.categorie,
    id: id,
    digitCount: 6, // "CAT000001"
  );

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          _loadData(setState);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 500,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/categorie_icon.png',
                  text: l10n.newCategory,
                ),

                content: Form(
                  key: produitFormKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChampAvecLabel(
                        obligatoire: true,
                        label: l10n.name,
                        child: TextChampL(
                          controller: categorieNomController,
                          obligatoire: true,
                          hint: l10n.categoryNameHint,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ChampAvecLabel(
                        label: l10n.observation,
                        child: TextChampL(
                          controller: categorieObservController,
                          hint: l10n.addObservation,
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
                      onPressed: () {
                        resetCategorieForm();
                        Navigator.pop(context);
                      },
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      onPressed: () async {
                        // ❌ Validation formulaire
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newCategory,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final nouvelleCategorie = Categorie(
                          id: id,
                          nom: categorieNomController.text,
                          etat: true,
                          code: cd, // ✅ Code généré automatiquement
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                          observation: categorieObservController.text,
                        );

                        // Appel API pour sauvegarder la catégorie
                        final response = await _saveCategorie(
                          categorie: nouvelleCategorie,
                          userCode: userCode,
                          userName: userName,
                        );

                        // ❌ ERREUR
                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.newCategory,
                            message: response.message ?? "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        // ✅ SUCCÈS
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.newCategory,
                          message: l10n.createSuccess,
                          onTerminer: () {
                            Navigator.pop(context); // Ferme la page si nécessaire
                          },
                        );

                        // Reset des champs du formulaire
                        resetCategorieForm();
                      },
                      color: Appstyle.violet,
                      icon: Icons.save,
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