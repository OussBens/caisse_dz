import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/stock_guard.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../information_dialog.dart';
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

/// Annulation "douce" des achats sélectionnés (SmartScan, y compris les
/// entrées rapides à 1 produit) : la ligne, ses lignes produit, ses
/// mouvements de stock et son versement fournisseur restent en base (même
/// principe que pannier_actif.dart), seul leur `etat` bascule à annulé.
/// Le stock ajouté par l'achat est restitué (retiré).
Future<void> _AnnulerSS({
  required List<SmartScan> smartscans,
  required String userName,
  required String userCode,
  required String motif,
}) async {
  final db = await DbCreator.openDb();
  final services = await SmartScanServices(db);
  final servicep = await SmartScanProduitServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceP = await ProduitServices(db);
  final serviceV = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final Produs = await ProduitServices.getAllProduits();

  for (var ss in smartscans) {
    // Mouvements de stock liés : soft-cancel (jamais de suppression).
    final mouvements = await MouvementsServices.getAllMouvementsByCodeOper(ss.code);
    for (var mouvement in mouvements) {
      mouvement.etat = false;
      mouvement.dateAnnul = DateTime.now();
      mouvement.annulParCode = userCode;
      mouvement.motifAnnul = motif;
      await MouvementsServices(db).updateMouvement(mouvement);
    }

    // Lignes produit : restituer le stock ajouté, puis soft-cancel la ligne
    // (conservée comme preuve de l'achat d'origine).
    final produits = await SmartScanProduitServices.getSmartScanProduitByCode(ss.code);
    for (var produit in produits) {
      final prod = Produs.where((e) => e.code == produit.codeProduit).first;
      if (!prod.service) {
        if (produit.nombre != null) prod.nombre = prod.nombre - produit.nombre!;
      }
      prod.modifParCode = userCode;
      prod.dateModif = DateTime.now();
      await serviceP.updateProduit(prod);

      produit.etat = false;
      produit.modifLe = DateTime.now();
      produit.modifParCode = userCode;
      produit.annulLe = DateTime.now();
      produit.annulParCode = userCode;
      produit.motifAnnul = motif;
      await servicep.updateSmartScanProduit(produit);

      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
          id: idh,
          code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type: "SmartScanProduit",
          desc: "l'utilisateur $userName a annulé le produit ${prod.nom} de l'Entrée ${produit.codeSmartScan} (motif: $motif)",
          oper: ListsConst.typeHisto[2],
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }

    // Versement fournisseur lié : soft-cancel (jamais de suppression),
    // même convention que pannier_actif.dart pour son versement client.
    final versementsSS = await serviceV.getVerssementsByCodeOperation(ss.code);
    for (var v in versementsSS) {
      if (!v.etat) continue;
      v.etat = false;
      v.dateAnnul = DateTime.now();
      v.annulParCode = userCode;
      v.motifAnnul = motif;
      await serviceV.updateVerssement(v);
    }
    if (versementsSS.isNotEmpty) {
      int idhv = await _GetNextHistoriqueId();
      Historique histoV = Historique(
        id: idhv,
        code: "HS$idhv${DateTime.now().millisecondsSinceEpoch}",
        type: "Versement",
        desc: "l'utilisateur $userName a annulé le(s) versement(s) lié(s) à l'entrée ${ss.code} (motif: $motif)",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histoV);
    }

    // Mouvement de caisse (grand-livre) lié : soft-cancel.
    final mouvementsCaisseSS = await CaisseSessionServices.getMouvementsByCodeOperation(
      ss.code,
      type: 'decaissement_achat',
    );
    for (var m in mouvementsCaisseSS) {
      await caisseSessionService.annulerMouvement(
        code: m.code,
        userCode: userCode,
        motif: "Entrée ${ss.code} annulée",
      );
    }

    final response = await services.annulerSmartScan(ss.id, motif: motif, userCode: userCode);
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id: idh,
        code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
        type: "SmartScan",
        desc: response.success
            ? "l'utilisateur $userName a annulé l'Entrée ${ss.code} (motif: $motif)"
            : "Échec annulation de l'Entrée ${ss.code}: ${response.message}",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode
    );
    await serviceh.addHistorique(histo);
  }
}

// ✅ Annuler un SmartScan retire du stock la quantité qu'il avait
// ajoutée (voir _AnnulerSS). Vérifier, avant d'annuler, que le retrait
// cumulé des SmartScan sélectionnés ne ferait pas passer un produit en
// négatif (cas réel : entrée de 50, vente de 20, puis annulation de
// l'entrée -> stock qui deviendrait négatif si non vérifié).
Future<(Produit, double quantiteNecessaire, double quantiteDisponible)?> _premierProduitInsuffisantPourSuppressionSS(
    List<SmartScan> smartscans, List<Produit> produits) async {
  final deltasParProduit = <String, double>{};
  for (final ss in smartscans) {
    final lignes = await SmartScanProduitServices.getSmartScanProduitByCode(ss.code);
    for (final ligne in lignes) {
      deltasParProduit[ligne.codeProduit] = (deltasParProduit[ligne.codeProduit] ?? 0) - ligne.quantite;
    }
  }

  // SmartScan ne porte pas encore de magasin (voir Phase 1) — vérification
  // sur le total tous magasins confondus.
  final totaux = await MouvementsServices.totauxParProduit();

  for (final entry in deltasParProduit.entries) {
    final prod = produits.where((p) => p.code == entry.key).firstOrNull;
    if (prod == null || prod.service) continue;
    final quantiteDisponible = totaux.quantites[prod.code] ?? 0;
    if (!StockGuard.suffisant(quantiteDisponible, -entry.value, service: prod.service)) {
      return (prod, -entry.value, quantiteDisponible);
    }
  }
  return null;
}

Future<void> AnnulerSmartScan(
    BuildContext context, List<SmartScan> smartScanSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  String nomFournisseur(String code) =>
      fournisseurs.firstWhereOrNull((f) => f.code == code)?.nom ?? code;

  final motifController = TextEditingController();

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
                height: 550,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/scan_icon.png',
                  text: l10n.cancelSmartScan,
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
                                "${l10n.smartScanHash} #${s.id} - ${l10n.amount}: ${s.montant} - ${l10n.supplier}: ${nomFournisseur(s.fournisseurCode)} - ${l10n.quantity}: ${s.nbrProduit}",
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
                      l10n.confirmCancelSmartScans,
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
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.cancelSmartScan,
                      color: Appstyle.violet,
                      icon: Icons.block,
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

                        final produitsCatalogue = await ProduitServices.getAllProduits();
                        final echec = await _premierProduitInsuffisantPourSuppressionSS(
                          smartScanSelectionnes,
                          produitsCatalogue,
                        );
                        if (echec != null) {
                          final (produitInsuffisant, quantiteNecessaire, quantiteDisponible) = echec;
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.smartScan,
                            message: l10n.stockInsuffisantPourProduit(
                              produitInsuffisant.code,
                              quantiteDisponible.toInt().toString(),
                              quantiteNecessaire.toInt().toString(),
                            ),
                          );
                          return;
                        }

                        await _AnnulerSS(
                            smartscans: smartScanSelectionnes,
                            userName: userName,
                            userCode: userCode,
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
