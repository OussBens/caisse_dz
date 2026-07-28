import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeletePannier ({
  required String         userName,
  required String         userCode,
  required List<Pannier>  panniers,
}) async {
  final db  = await DbCreator.openDb();
  final servicep  = PPServices(db);
  final services  = PannierServices(db);
  final serviceh  = HistoriqueServices(db);
  final serviceC  = ClientServices(db);

  final clients   = await ClientServices.getAllClients();
  final produits  = await PPServices.getAllPP();
  final catalogueProduits = await ProduitServices.getAllProduits();
  String nomProduit(String code) =>
      catalogueProduits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  for(var pannier in panniers){
    final mouvs   = await MouvementsServices.getAllMouvementsByCodeOper(pannier.code);
    final prods   = produits.where((e) => e.codePannier == pannier.code).toList();
    final client  = clients.where((e) => e.code == pannier.client_code).first;
    for(var prod in prods){
      await servicep.deletePP(prod.id);
      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
        id          : idh,
        code        : 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
        type        : 'pannierProduit',
        desc        : "l'utilisateur $userName a supprimer le Produit ${nomProduit(prod.codeProduit)} de Pannier ${pannier.code}",
        oper        : ListsConst.typeHisto[2],
        dateCree    : DateTime.now(),
        creeParCode : userCode,
      );
      await serviceh.addHistorique(histo);
      final mouv  = mouvs.where((e) => e.codeProduit == prod.codeProduit).first;
      await MouvementsServices.deleteMouvement(mouv.id);
    }
    await services.deletePannier(pannier.id);
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
      id          : idh,
      code        : 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
      type        : 'panniers',
      desc        : "l'utilisateur $userName a supprimer le pannier ${pannier.code}",
      oper        : ListsConst.typeHisto[2],
      dateCree    : DateTime.now(),
      creeParCode : userCode,
    );
    await serviceh.addHistorique(histo);

    client.dateModif  = DateTime.now();
    client.modifParCode   = userCode;
    await serviceC.updateClient(client);
  }
}

Future<void> AnnulerPannier(BuildContext context, List<Pannier> paniersSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final clientsCatalogue = await ClientServices.getAllClients();
  String nomClient(String? code) =>
      clientsCatalogue.firstWhereOrNull((c) => c.code == code)?.nom ?? '';

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.loginRequired),
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
                  imagePath: 'assets/icons/action/annuler_icon.png',
                  text: l10n.cancelCarts,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Liste des paniers sélectionnés
                    Text(
                      l10n.selectedCarts,
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: paniersSelectionnes.length,
                        itemBuilder: (context, index) {
                          final p = paniersSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.cartId(p.code)} - ${l10n.client}: ${nomClient(p.client_code)} - ${l10n.totalAmount}: ${p.montant.toStringAsFixed(2)} ${l10n.currency}",
                                style: Appstyle.textSB
                                    .copyWith(color: Appstyle.Tnoir),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.confirmCancelCarts,
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
                      onPressed: () async {
                        await _DeletePannier(
                            userName: userName,
                            userCode: userCode,
                            panniers: paniersSelectionnes
                        );
                        Navigator.pop(context);
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