import 'dart:ui';
import 'package:caisse_dz/data/models/entree.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../DBCreate.dart';
import '../../../Services/Entree.dart';
import '../../../Services/Historique.dart';
import '../../../Services/Mouvement.dart';
import '../../../Services/Produits.dart';
import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import '../../../data/models/produit.dart';
import '../../Auth/auth_state.dart';
import '../../tableau/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteEs({
  required String userName,
  required String userCode,
  required List<Entree> entrees,
}) async {
  final db = await DbCreator.openDb();

  final servicesE = EntreeServices(db);
  final serviceh = HistoriqueServices(db);
  final servicep = ProduitServices(db);

  final produits = await ProduitServices.getAllProduits();

  Produit prod;

  for (var entree in entrees) {
    prod = produits.where((e) => e.nom == entree.produit).first;

    prod.quantite = prod.quantite - entree.quantite;
    prod.dateModif = DateTime.now();
    prod.modifPar = userName;

    await servicep.updateProduit(prod);

    await servicesE.deleteEntree(entree.id);

    int idh = await _GetNextHistoriqueId();

    Historique histo = Historique(
      id: idh,
      code: "HE$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "entree",
      desc: "L'utilisateur $userName a Supprimer l'Entrée du Produit ${entree.produit}",
      oper: ListsConst.typeHisto[2],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await serviceh.addHistorique(histo);

    final mouvment = await MouvementsServices
        .getAllMouvementsByCodeOper(entree.code);

    if (mouvment.isNotEmpty) {
      await MouvementsServices.deleteMouvement(mouvment.first.id);
    }
  }
}

Future<void> AnnulerEntree(
    BuildContext context,
    List<Entree> entreesSelectionnees,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated) {
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
                  text: l10n.deleteEntry,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedEntries,
                      style: Appstyle.textSB
                          .copyWith(color: Appstyle.Tnoir),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: entreesSelectionnees.length,
                        itemBuilder: (context, index) {
                          final e = entreesSelectionnees[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.input,
                                    color: Appstyle.violet,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${e.produit}  |  ${l10n.quantity}: ${e.quantite}",
                                      style: Appstyle.textSB.copyWith(
                                        color: Appstyle.Tnoir,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${e.montant.toStringAsFixed(2)} ${l10n.currency}",
                                    style: Appstyle.textSB.copyWith(
                                      color: Appstyle.violet,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.confirmDeleteEntries,
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
                      icon: Icons.cancel,
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      icon: Icons.delete,
                      text: l10n.deleteEntry,
                      color: Appstyle.violet,
                      onPressed: () async {
                        await _DeleteEs(
                          userName: userName,
                          userCode: userCode,
                          entrees: entreesSelectionnees,
                        );
                        Navigator.pop(context);
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