import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/produit.dart';
import '../../../Services/Magasin.dart';
import '../../../Services/Pack.dart';
import '../../../Services/Remise.dart';
import '../../../Services/SousCategories.dart';
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

Future<List<String>?> havemovment({required List<Produit> produits}) async {
  List<String> produitHaveMouvement = [];
  for (var produit in produits) {
    if (await MouvementsServices.isProduitHaveMouvement(produit.code)) {
      produitHaveMouvement.add(produit.nom);
    }
  }
  return produitHaveMouvement;
}

Future<void> DeleteProduit({
  required List<Produit> produits,
  required String userName,
  required String userCode
}) async {
  final db = await DbCreator.openDb();
  final services = ProduitServices(db);
  final servicesCode = ProduitServices(db);
  final sousCategorieService = SousCategoriesServices(db);
  final remiseService = RemiseServices(db);
  final packService = PackServices(db);
  final magasinService = MagasinServices(db);
  final servicep = await ProduitPackDetailServices(db);
  final servicem = await ProduitMagasinDetailServices(db);
  final serviceh = await HistoriqueServices(db);

  for (var produit in produits) {
    await servicesCode.deleteAllProduitCodeDetailes(produit.code);
    final int idC = await _GetNextHistoriqueId();
    final Historique histC = Historique(
        id: idC,
        code: "HS$idC ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a supprimer le ProduitCodeDetail de  ${produit.nom}",
        type: "ProduitCodeDetail",
        oper: ListsConst.typeHisto[3],
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histC);

    await servicep.deleteAllDetailes(produit.nom);
    final int idN = await _GetNextHistoriqueId();
    final Historique histN = Historique(
        id: idN,
        code: "HS$idN ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a supprimer le ProduitPackDetail de  ${produit.nom}",
        type: "ProduitPackDetail",
        oper: ListsConst.typeHisto[3],
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histN);

    await servicem.deleteAllDetailes(produit.code);
    final int idM = await _GetNextHistoriqueId();
    final Historique histM = Historique(
        id: idM,
        code: "HS$idM ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a supprimer le ProduitMagasinDetail de  ${produit.nom}",
        oper: ListsConst.typeHisto[3],
        type: "ProduitMagasinDetail",
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histM);

    await servicep.deleteAllDetailes2(produit.code);
    await services.deleteProduitt(produit.id);

    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a supprimer le Produit ${produit.nom}",
        type: "Produit",
        oper: ListsConst.typeHisto[3],
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histo);
  }
}

Future<void> AnnulerProduit(
    BuildContext context,
    List<Produit> produitsSelectionnes,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequiredDelete,
    );
    return;
  }

  List<String>? produitsAvecMouvement = await havemovment(produits: produitsSelectionnes);

  if (produitsAvecMouvement == null || produitsAvecMouvement.isEmpty) {
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
                    imagePath: 'assets/icons/sidebar/produit_icon.png',
                    text: l10n.deleteProduct,
                  ),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.selectedProducts,
                        style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: produitsSelectionnes.length,
                          itemBuilder: (context, index) {
                            final p = produitsSelectionnes[index];
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${p.nom} (${p.code})",
                                    style: Appstyle.textSB.copyWith(
                                      color: Appstyle.Tnoir,
                                    ),
                                  ),
                                  Text(
                                    "${l10n.quantity}: ${p.quantite}",
                                    style: Appstyle.textSB.copyWith(
                                      color: Appstyle.violet,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.confirmDeleteProducts,
                        style: Appstyle.textS.copyWith(
                          color: Appstyle.TgrisC,
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
                        text: l10n.delete,
                        color: Appstyle.violet,
                        icon: Icons.delete,
                        onPressed: () async {
                          await ConfirmationDialog(
                            context: context,
                            titre: l10n.deletion,
                            message: l10n.confirmPermanentDelete,
                            onConfirmer: () async {
                              await DeleteProduit(
                                produits: produitsSelectionnes,
                                userCode: userCode,
                                userName: userName,
                              );

                              await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.success,
                                  titre_concerne: l10n.product,
                                  message: l10n.productsDeletedSuccess,
                                  onTerminer: () {
                                    Navigator.pop(context);
                                  }
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

  // CAS 2 : certains produits ont des mouvements
  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      final l10n = AppLocalizations.of(context)!;
      return BaseDialog(
        width: 700,
        height: 450,
        header: TitreAvecLigne(
          imagePath: 'assets/icons/action/annuler_icon.png',
          text: l10n.cannotDelete,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.cannotDeleteWithMovements,
              style: Appstyle.textSB.copyWith(color: Colors.red),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: produitsAvecMouvement.map((p) {
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        p,
                        style: Appstyle.textSB.copyWith(color: Colors.red),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            MainButton(
              text: l10n.close,
              color: Appstyle.gris,
              onPressed: () => Navigator.pop(context),
              icon: Icons.close,
            ),
          ],
        ),
      );
    },
  );
}