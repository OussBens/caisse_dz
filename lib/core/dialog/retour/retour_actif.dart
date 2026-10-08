import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/stock_guard.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import '../information_dialog.dart';
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

/// Annulation "douce" des retours sélectionnés : le retour, son mouvement de
/// stock et son versement lié restent en base (jamais de suppression
/// physique), seul leur `etat` bascule à annulé — même principe que
/// pannier_actif.dart/smart_screen_actif.dart. Le stock rendu/repris par le
/// retour est restitué à son état d'avant retour.
Future<void> _AnnulerR({
  required String userName,
  required String userCode,
  required List<Retour> Retours,
  required String motif,
}) async {
  final db = await DbCreator.openDb();
  final services = await RetourServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceP = await ProduitServices(db);
  final serviceM = MouvementsServices(db);
  final serviceV = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final produits = await ProduitServices.getAllProduits();

  for (var retour in Retours) {
    Produit Prod = produits.where((e) => e.code == retour.codeProduit).first;
    if (retour.fournisseur_code != null && !Prod.service) {
      if (retour.nombre != null) Prod.nombre = Prod.nombre + retour.nombre!;
    }
    if (retour.client_code != null && !Prod.service) {
      if (retour.nombre != null) Prod.nombre = Prod.nombre - retour.nombre!;
    }
    Prod.modifParCode = userCode;
    Prod.dateModif = DateTime.now();

    await serviceP.updateProduit(Prod);

    // Symétrique par magasin de ce qui précède — annuler un retour
    // fournisseur restitue le magasin, annuler un retour client le
    // redéstocke (inverse exact de retour_nouveau.dart).
    if (!Prod.service && retour.magasinCode != null) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
        Prod.code,
        retour.magasinCode!,
      );
      if (magasinDetail != null) {
        if (retour.fournisseur_code != null) {
          if (retour.nombre != null) {
            await pmdService.incrementNombre(magasinDetail.id, retour.nombre!);
          }
        } else if (retour.client_code != null) {
          if (retour.nombre != null && magasinDetail.nombre > 0) {
            final nombreADestock = retour.nombre! <= magasinDetail.nombre
                ? retour.nombre!
                : magasinDetail.nombre;
            await pmdService.decrementNombre(magasinDetail.id, nombreADestock);
          }
        }
      }
    }

    // Mouvement de stock lié : soft-cancel (jamais de suppression).
    // Multi-magasin : un retour peut avoir un mouvement par magasin touché.
    final mouv = await MouvementsServices.getAllMouvementsByCodeOper(retour.code);
    for (final m in mouv.where((e) => e.etat)) {
      m.etat = false;
      m.dateAnnul = DateTime.now();
      m.annulParCode = userCode;
      m.motifAnnul = motif;
      await serviceM.updateMouvement(m);
    }

    // Mouvement de caisse (grand-livre) lié : soft-cancel.
    final typeMouvementRetour = retour.fournisseur_code != null ? 'retour_fournisseur' : 'retour_client';
    final mouvementsRetour = await CaisseSessionServices.getMouvementsByCodeOperation(
      retour.code,
      type: typeMouvementRetour,
    );
    for (var m in mouvementsRetour) {
      await caisseSessionService.annulerMouvement(
        code: m.code,
        userCode: userCode,
        motif: motif,
      );
    }

    // Versement(s) lié(s) : soft-cancel (jamais de suppression), même
    // convention que pannier_actif.dart pour son versement client.
    final versementsRetour = await serviceV.getVerssementsByCodeOperation(retour.code);
    for (var v in versementsRetour) {
      if (!v.etat) continue;
      v.etat = false;
      v.dateAnnul = DateTime.now();
      v.annulParCode = userCode;
      v.motifAnnul = motif;
      await serviceV.updateVerssement(v);
    }
    if (versementsRetour.isNotEmpty) {
      int idhv = await _GetNextHistoriqueId();
      Historique histoV = Historique(
        id: idhv,
        code: "HS$idhv${DateTime.now().millisecondsSinceEpoch}",
        type: "Versement",
        desc: "l'utilisateur $userName a annulé le(s) versement(s) lié(s) au retour ${retour.code} (motif: $motif)",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histoV);
    }

    final response = await services.annulerRetour(retour.id, motif: motif, userCode: userCode);

    int idh = await _GetNextHistoriqueId();

    Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "Retours",
      desc: response.success
          ? "L'utilisateur $userName a annulé le Retour ${retour.code} de Produit ${Prod.nom} (motif: $motif)"
          : "Échec annulation du Retour ${retour.code}: ${response.message}",
      oper: ListsConst.typeHisto[2],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await serviceh.addHistorique(histo);
  }
}

// ✅ Annuler un retour Client = défaire l'entrée de stock qu'il avait
// générée (donc un retrait). Vérifier, avant d'annuler, que le stock
// cumulé des retours Client sélectionnés ne passerait négatif pour aucun
// produit (les retours Fournisseur restituent toujours du stock : jamais
// risqué). Retourne le premier produit en échec, ou null si tout est ok.
Future<Produit?> _premierProduitInsuffisantPourSuppression(
    List<Retour> retours, List<Produit> produits) async {
  final deltasParProduit = <String, double>{};
  for (final r in retours) {
    if (r.client_code != null) {
      deltasParProduit[r.codeProduit] = (deltasParProduit[r.codeProduit] ?? 0) - r.quantite;
    }
  }

  // Les retours sélectionnés peuvent venir de magasins différents — vérifié
  // sur le total tous magasins confondus (plus simple qu'un scope par
  // retour, et suffisant pour cette garde de suppression).
  final totaux = await MouvementsServices.totauxParProduit();

  for (final entry in deltasParProduit.entries) {
    if (entry.value >= 0) continue;
    final prod = produits.where((p) => p.code == entry.key).firstOrNull;
    if (prod == null || prod.service) continue;
    final quantiteDisponible = totaux.quantites[prod.code] ?? 0;
    if (!StockGuard.suffisant(quantiteDisponible, -entry.value, service: prod.service)) {
      return prod;
    }
  }
  return null;
}

Future<void> AnnulerRetour(BuildContext context, List<Retour> retoursSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  // ✅ Permission spéciale (voir RoleDetail) : annuler une opération.
  if (!auth.canAnnulerOperations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.noPermissionAction),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  final produitsCatalogue = await ProduitServices.getAllProduits();
  final clientsCatalogue = await ClientServices.getAllClients();
  final fournisseursCatalogue = await FournisseurServices.getAllFournisseurs();
  String nomProduit(String code) =>
      produitsCatalogue.where((p) => p.code == code).firstOrNull?.nom ?? code;
  String? nomClient(String? code) =>
      code == null ? null : clientsCatalogue.where((c) => c.code == code).firstOrNull?.nom;
  String? nomFournisseur(String? code) =>
      code == null ? null : fournisseursCatalogue.where((f) => f.code == code).firstOrNull?.nom;

  final motifController = TextEditingController();

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 850,
                height: 600,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/retour_icon.png',
                  text: l10n.cancelReturns,
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
                                    "${l10n.product}: ${nomProduit(r.codeProduit)} | ${l10n.quantity}: ${r.quantite}",
                                    style: Appstyle.textS,
                                  ),
                                  Text(
                                    "${l10n.purchasePrice}: ${r.prixAchat ?? 0} ${l10n.currency} | ${l10n.salePrice}: ${r.prixVente ?? 0} ${l10n.currency}",
                                    style: Appstyle.textS,
                                  ),
                                  Text(
                                    r.type == "Client"
                                        ? "${l10n.type}: ${l10n.client} | ${l10n.client}: ${nomClient(r.client_code) ?? '-'}"
                                        : "${l10n.type}: ${l10n.supplier} | ${l10n.supplier}: ${nomFournisseur(r.fournisseur_code) ?? '-'}",
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
                      l10n.confirmCancelReturns,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),
                    const SizedBox(height: 12),
                    ChampAvecLabel(
                      label: l10n.cancellationReason,
                      child: TextChampL(
                        controller: motifController,
                        hint: '',
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      text: l10n.cancelReturns,
                      icon: Icons.block,
                      color: Appstyle.violet,
                      onPressed: () async {
                        final motif = motifController.text.trim();
                        if (motif.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.cancellationReason),
                              backgroundColor: Colors.red,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        final produitInsuffisant = await _premierProduitInsuffisantPourSuppression(
                          retoursSelectionnes,
                          produitsCatalogue,
                        );
                        if (produitInsuffisant != null) {
                          final quantiteDisponible = await MouvementsServices.quantiteProduit(produitInsuffisant.code);
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.return_,
                            message: l10n.stockInsuffisantPourProduit(
                              produitInsuffisant.code,
                              quantiteDisponible.toInt().toString(),
                              retoursSelectionnes
                                  .where((r) => r.codeProduit == produitInsuffisant.code && r.client_code != null)
                                  .fold<double>(0, (s, r) => s + r.quantite)
                                  .toInt()
                                  .toString(),
                            ),
                          );
                          return;
                        }

                        await _AnnulerR(
                          userName: userName,
                          userCode: userCode,
                          Retours: retoursSelectionnes,
                          motif: motif,
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
