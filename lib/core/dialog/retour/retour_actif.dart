import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteR({
  required String userName,
  required String userCode,
  required List<Retour> Retours,
}) async {
  final db = await DbCreator.openDb();
  final services = await RetourServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceP = await ProduitServices(db);

  final produits = await ProduitServices.getAllProduits();

  for (var retour in Retours) {
    Produit Prod = produits.where((e) => e.nom == retour.nomProduit).first;
    if (retour.fournisseur != null) {
      Prod.quantite = Prod.quantite + retour.quantite;
    }
    if (retour.client != null) {
      Prod.quantite = Prod.quantite - retour.quantite;
    }
    Prod.modifPar = userName;
    Prod.dateModif = DateTime.now();

    await serviceP.updateProduit(Prod);

    final mouv = await MouvementsServices.getAllMouvementsByCodeOper(retour.code);

    await MouvementsServices.deleteMouvement(mouv.first.id);

    await services.deleteRetour(retour.id);

    int idh = await _GetNextHistoriqueId();

    Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "Retours",
      desc: "L'utilisateur $userName a supprimer le Retour ${retour.code} de Produit ${retour.nomProduit}",
      oper: ListsConst.typeHisto[3],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await serviceh.addHistorique(histo);
  }
}

Future<void> AnnulerRetour(BuildContext context, List<Retour> retoursSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

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
                width: 850,
                height: 550,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/retour_icon.png',
                  text: l10n.deleteReturns,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedReturns,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: retoursSelectionnes.length,
                        itemBuilder: (context, index) {
                          final r = retoursSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${l10n.returnHash} #${r.id} - ${r.code}",
                                    style: Appstyle.textSB.copyWith(
                                        color: Appstyle.Tnoir),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${l10n.product}: ${r.nomProduit} | ${l10n.quantity}: ${r.quantite}",
                                    style: Appstyle.textS,
                                  ),
                                  Text(
                                    "${l10n.purchasePrice}: ${r.prixAchat ?? 0} ${l10n.currency} | ${l10n.salePrice}: ${r.prixVente ?? 0} ${l10n.currency}",
                                    style: Appstyle.textS,
                                  ),
                                  Text(
                                    r.type == "Client"
                                        ? "${l10n.type}: ${l10n.client} | ${l10n.client}: ${r.client ?? '-'}"
                                        : "${l10n.type}: ${l10n.supplier} | ${l10n.supplier}: ${r.fournisseur ?? '-'}",
                                    style: Appstyle.textS,
                                  ),
                                  Text(
                                    "${l10n.status}: ${r.etat ? l10n.active : l10n.inactive}",
                                    style: Appstyle.textS.copyWith(
                                        color: r.etat
                                            ? Colors.green
                                            : Colors.red),
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
                      l10n.confirmDeleteReturns,
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
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.deleteReturns,
                      icon: Icons.delete,
                      color: Appstyle.violet,
                      onPressed: () async {
                        await _DeleteR(
                          userName: userName,
                          userCode: userCode,
                          Retours: retoursSelectionnes,
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