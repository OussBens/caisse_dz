import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Produits.dart';
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
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> DeleteCategorie({
  required List<Categorie> categories,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  List<Produit> produits = [];
  final servicep = await ProduitServices(db);
  final serviceh = await HistoriqueServices(db);
  final services = await CategorieServices(db);

  for(var cate in categories){
    produits = await servicep.getProduitsByCategorieId(cate.id);
    if (produits.isNotEmpty) {
      throw Exception("CategorieNonVide:${cate.nom}");
    }
    await services.deleteCategorie(cate.id);
    for(var produit in produits){
      produit.categorieId     = 0;
      produit.sousCategorieId = 0;
      produit.modifParCode        = userCode;
      produit.dateModif       = DateTime.now();
      await servicep.updateProduit(produit);

      final int idN = await _GetNextHistoriqueId();
      final Historique histN = Historique(
          id          : idN,
          code        : "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
          desc        : "l'utilisateur ${userName} Supprimer la Categorie ${cate.nom} de Produit ${produit.nom}",
          type        : "Produit",
          oper        : ListsConst.typeHisto[3],
          dateCree    : DateTime.now(),
          creeParCode : userCode
      );
      await serviceh.addHistorique(histN);
    }
    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
        id          : idH,
        code        : "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc        : "l'utilisateur ${userName} Supprimer la Categorie ${cate.nom}",
        type        : "Categorie",
        oper        : ListsConst.typeHisto[3],
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceh.addHistorique(histo);
  }
}

Future<void> AnnulerCategorie(BuildContext context, List<Categorie> categoriesSelectionnees) async{
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      kind: DialogKind.refuser,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
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

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/action/supprimer_icon.png',
                  text: l10n.deleteCategory,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedCategories,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: categoriesSelectionnees.length,
                        itemBuilder: (context, index) {
                          final c = categoriesSelectionnees[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text("${c.nom}", style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir)),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.confirmDeleteCategories,
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
                      text: l10n.delete,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await ConfirmationDialog(
                            context: context,
                            kind: DialogKind.danger,
                            titre: l10n.deleteCategory,
                            message: l10n.confirmDeleteCategory,
                            onConfirmer: () async {
                              try {
                                await DeleteCategorie(
                                  categories: categoriesSelectionnees,
                                  userName: userName!,
                                  userCode: userCode!,
                                );

                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.success,
                                  titre_concerne: l10n.deleteCategory,
                                  message: l10n.deleteSuccess,
                                  onTerminer: () { Navigator.pop(context); },
                                );

                              } catch (e) {
                                if (e.toString().contains("CategorieNonVide")) {
                                  await InformationDialog(
                                    context: context,
                                    titre_type_message: l10n.information,
                                    titre_concerne: l10n.deleteCategory,
                                    message: l10n.deleteError,
                                    onTerminer: () { Navigator.pop(context); },
                                  );
                                }
                              }
                            }
                        );
                      },
                      noIcon: true,
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