import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/sous_categorie.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
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

const String defaultSousCategorie = "Sans Sous-Catego";
const String defaultCategorie = "Sans Categorie";
const int defaultSousCategorieId = 1;
const int defaultCategorieId = 1;

Future<void> DeleteSousCategorie({
  required List<SousCategorie> souscategorie,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  List<Produit> produits = [];
  final services = SousCategoriesServices(db);
  final servicep = ProduitServices(db);
  final serviceh = HistoriqueServices(db);

  for (var sous in souscategorie) {
    produits = await servicep.getProduitsBySousCategorieId(sous.id);

    final int idH = await _GetNextHistoriqueId();

    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur ${userName} Supprimer la SousCategorie ${sous.nom}",
        type: "SousCategorie",
        oper: ListsConst.typeHisto[3],
        dateCree: DateTime.now(),
        creeParCode: userCode
    );
    await serviceh.addHistorique(histo);

    for (var produit in produits) {
      produit.sousCategorieId = defaultSousCategorieId;
      produit.categorieId = defaultCategorieId;
      produit.modifParCode = userCode;
      produit.dateModif = DateTime.now();

      await servicep.updateProduit(produit);

      final int idN = await _GetNextHistoriqueId();
      final Historique histo = Historique(
          id: idN,
          code: "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur ${userName} Supprimer la SousCategorie ${sous.nom} de Produit ${produit.nom}",
          oper: ListsConst.typeHisto[3],
          type: 'SousCategorie',
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }

    await services.deleteSousCategorie(sous.id);
  }
}

Future<void> AnnulerSousCategorie(
    BuildContext context,
    List<SousCategorie> sousCategoriesSelectionnees
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredDelete,
    );
    return;
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
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/action/supprimer_icon.png',
                  text: l10n.deactivateSubcategory,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedSubcategories,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: sousCategoriesSelectionnees.length,
                        itemBuilder: (context, index) {
                          final sc = sousCategoriesSelectionnees[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  "${sc.nom} (${l10n.category}: ${sc.categorieCode})",
                                  style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir)
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.confirmDeactivateSubcategories,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),
                    const SizedBox(height: 20),
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
                      text: l10n.deleteSubcategory,
                      color: Appstyle.violet,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.deletion,
                          message: l10n.confirmDeleteSubcategories,
                          onConfirmer: () async {
                            await DeleteSousCategorie(
                              souscategorie: sousCategoriesSelectionnees,
                              userCode: userCode,
                              userName: userName,
                            );

                            await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.subcategory,
                                message: l10n.subcategoriesDeletedSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
                            );
                          },
                        );
                      },
                      icon: Icons.delete,
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