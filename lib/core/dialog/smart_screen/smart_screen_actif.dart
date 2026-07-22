import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteSS({
  required List<SmartScan> smartscans,
  required String userName,
  required String userCode
}) async {
  final db = await DbCreator.openDb();
  final services = await SmartScanServices(db);
  final servicep = await SmartScanProduitServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceP = await ProduitServices(db);

  List<Produit> Produs = await ProduitServices.getAllProduits();
  List<SmartScanProduit> produits = [];

  for (var ss in smartscans) {
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id: idh,
        code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
        type: "SmartScan",
        desc: "l'utilisateur $userName a supprimer le SmartScan ${ss.code}",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode
    );
    await serviceh.addHistorique(histo);

    produits = await SmartScanProduitServices.getSmartScanProduitByCode(ss.code);
    for (var produit in produits) {
      final prod = Produs.where((e) => e.nom == produit.nomProduit).first;
      if (prod.quantite < produit.quantite) {
        SnackBar(
          content: Text("Produit Quantite < Smart Scan Produit Quantite"),
          duration: Duration(seconds: 5),
        );
      }
      prod.quantite = prod.quantite - produit.quantite;
      prod.modifParCode = userName;
      prod.dateModif = DateTime.now();
      await serviceP.updateProduit(prod);

      await servicep.deleteSmartScanProduit(produit.id);
      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
          id: idh,
          code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type: "SmartScanProduit",
          desc: "l'utilisateur $userName a supprimer le SmartScanProduit ${produit.nomProduit} de SmartScan ${produit.codeSmartScan}",
          oper: ListsConst.typeHisto[2],
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }
    await services.deleteSmartScan(ss.id);
  }
}

Future<void> AnnulerSmartScan(
    BuildContext context, List<SmartScan> smartScanSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

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
                  imagePath: 'assets/icons/cardwidget/scan_icon.png',
                  text: l10n.deleteSmartScan,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedSmartScans,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: smartScanSelectionnes.length,
                        itemBuilder: (context, index) {
                          final s = smartScanSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.smartScanHash} #${s.id} - ${l10n.amount}: ${s.montant} - ${l10n.supplier}: ${s.fournisseur} - ${l10n.quantity}: ${s.nbrProduit}",
                                style: Appstyle.textSB.copyWith(
                                  color: Appstyle.Tnoir,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.confirmDeleteSmartScans,
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
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.deleteSmartScan,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await _DeleteSS(
                            smartscans: smartScanSelectionnes,
                            userName: userName,
                            userCode: userCode
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