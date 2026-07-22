import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteSs({
  required String userName,
  required String userCode,
  required List<Sortie> sorties,
}) async {
  final db = await DbCreator.openDb();
  final services = SortieServices(db);
  final serviceh = HistoriqueServices(db);
  final servicep = ProduitServices(db);

  final produits = await ProduitServices.getAllProduits();
  Produit prod;

  for (var sortie in sorties) {
    prod = produits.where((e) => e.nom == sortie.produit).first;

    prod.quantite = prod.quantite + sortie.quantite;
    prod.dateModif = DateTime.now();
    prod.modifParCode = userName;

    await servicep.updateProduit(prod);

    await services.deleteSortie(sortie.id);

    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id: idh,
        code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
        type: "sortie",
        desc: "L'utilisateur $userName a Supprimer la Sortie de Produit ${sortie.produit} de Type ${sortie.type}",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode
    );

    await serviceh.addHistorique(histo);

    final mouvment = await MouvementsServices.getAllMouvementsByCodeOper(sortie.code);
    await MouvementsServices.deleteMouvement(mouvment.first.id);
  }
}

Future<void> AnnulerSortie(
    BuildContext context,
    List<Sortie> sortiesSelectionnees,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loginRequired),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
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
                  text: l10n.deleteExit,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedExits,
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: sortiesSelectionnees.length,
                        itemBuilder: (context, index) {
                          final s = sortiesSelectionnees[index];
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
                                  Icon(Icons.inventory_2,
                                      color: Appstyle.violet, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${s.produit}  |  ${l10n.quantity}: ${s.quantite}",
                                      style: Appstyle.textSB.copyWith(
                                        color: Appstyle.Tnoir,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${s.montant.toStringAsFixed(2)} ${l10n.currency}",
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
                      l10n.confirmDeleteExits,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
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
                      text: l10n.deleteExit,
                      color: Appstyle.violet,
                      onPressed: () async {
                        await _DeleteSs(
                            userName: userName,
                            userCode: userCode,
                            sorties: sortiesSelectionnees
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