import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/TransfertMagasin.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/stock_guard.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

/// Annulation "douce" des transferts sélectionnés : le transfert et ses 2
/// mouvements liés restent en base (jamais de suppression physique), seul
/// leur `etat` bascule à annulé — même principe que sortie_actif.dart. Le
/// second stock parallèle "nombre" est restitué (source ← incrémenté,
/// destination → décrémenté) ; `quantite` se déduit automatiquement du
/// journal des mouvements une fois ceux-ci annulés.
Future<void> _AnnulerTransferts({
  required String userName,
  required String userCode,
  required List<TransfertMagasin> transferts,
  required String motif,
}) async {
  final db = await DbCreator.openDb();
  final services = TransfertMagasinServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  for (var transfert in transferts) {
    if (transfert.nombre != null) {
      final detailSource = await pmdService.getSingleByProduitAndMagasin(
        transfert.produitCode,
        transfert.magasinSourceCode,
      );
      if (detailSource != null) {
        await pmdService.incrementNombre(detailSource.id, transfert.nombre!);
      }

      final detailDest = await pmdService.getSingleByProduitAndMagasin(
        transfert.produitCode,
        transfert.magasinDestCode,
      );
      if (detailDest != null && detailDest.nombre > 0) {
        final nombreARetirer = transfert.nombre! <= detailDest.nombre ? transfert.nombre! : detailDest.nombre;
        await pmdService.decrementNombre(detailDest.id, nombreARetirer);
      }
    }

    // Les 2 mouvements liés (Sortie@source / Entrée@destination) : soft-cancel.
    final mouvements = await MouvementsServices.getAllMouvementsByCodeOper(transfert.code);
    for (var m in mouvements) {
      m.etat = false;
      m.dateAnnul = DateTime.now();
      m.annulParCode = userCode;
      m.motifAnnul = motif;
      await serviceM.updateMouvement(m);
    }

    final response = await services.annulerTransfert(transfert.id, motif: motif, userCode: userCode);

    final idh = await _GetNextHistoriqueId();
    await serviceh.addHistorique(Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: "transfert_magasin",
      desc: response.success
          ? "L'utilisateur $userName a annulé le transfert ${transfert.code} (motif: $motif)"
          : "Échec annulation du transfert ${transfert.code}: ${response.message}",
      oper: ListsConst.typeHisto[2],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    ));
  }
}

/// Annuler un transfert retire son stock du côté destination (inverse exact
/// de la création) — vérifier, avant d'annuler, que le stock du magasin
/// destination ne passerait pas négatif pour aucun produit (le côté source,
/// qui ne fait que recevoir en retour, n'est jamais à risque). Même principe
/// que retour_actif.dart/smart_screen_actif.dart. Retourne le premier
/// (produit, magasin) en échec, ou null si tout est ok.
Future<(Produit, String magasinCode)?> _premierProduitInsuffisantPourAnnulationTransfert(
    List<TransfertMagasin> transferts, List<Produit> produits) async {
  final deltasParCle = <String, double>{};
  for (final t in transferts) {
    final cle = '${t.magasinDestCode}|${t.produitCode}';
    deltasParCle[cle] = (deltasParCle[cle] ?? 0) - t.quantite;
  }

  for (final entry in deltasParCle.entries) {
    if (entry.value >= 0) continue;
    final cleParts = entry.key.split('|');
    final magasinCode = cleParts[0];
    final produitCode = cleParts[1];
    final prod = produits.firstWhereOrNull((p) => p.code == produitCode);
    if (prod == null || prod.service) continue;
    final quantiteDisponible = await MouvementsServices.quantiteProduit(produitCode, magasinCode: magasinCode);
    if (!StockGuard.suffisant(quantiteDisponible, -entry.value, service: prod.service)) {
      return (prod, magasinCode);
    }
  }
  return null;
}

Future<void> AnnulerTransfertMagasin(
    BuildContext context,
    List<TransfertMagasin> transfertsSelectionnes, {
      required List<Produit> produits,
    }) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;
  final magasins = await MagasinServices.getAllMagasins();
  String nomMagasin(String code) =>
      magasins.firstWhereOrNull((m) => m.code == code)?.nom ?? code;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loginRequired),
        backgroundColor: Appstyle.danger,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // ✅ Permission spéciale (voir RoleDetail) : annuler une opération.
  if (!auth.canAnnulerOperations) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.noPermissionAction),
        backgroundColor: Appstyle.danger,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // ✅ Transfert(s) déjà annulé(s) : on le signale. Si tous le sont, rien à
  // faire ; sinon on n'annule que les transferts encore actifs.
  final dejaAnnules = transfertsSelectionnes.where((t) => !t.etat).toList();
  if (dejaAnnules.isNotEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.transfer,
      message: l10n.transfersAlreadyCancelled(dejaAnnules.map((t) => t.code).join(', ')),
    );
    transfertsSelectionnes = transfertsSelectionnes.where((t) => t.etat).toList();
    if (transfertsSelectionnes.isEmpty || !context.mounted) return;
  }

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
                  imagePath: 'assets/icons/action/supprimer_icon.png',
                  text: l10n.cancelTransfers,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedTransfers,
                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: transfertsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final t = transfertsSelectionnes[index];
                          final nomProduit = produits.firstWhereOrNull((p) => p.code == t.produitCode)?.nom
                              ?? t.produitCode;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.compare_arrows, color: Appstyle.violet, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "$nomProduit  |  ${l10n.quantity}: ${t.quantite}  |  ${t.magasinSourceCode} → ${t.magasinDestCode}",
                                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
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
                      l10n.confirmCancelTransfers,
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
                      icon: Icons.cancel,
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      icon: Icons.block,
                      text: l10n.cancelTransfers,
                      color: Appstyle.violet,
                      onPressed: () async {
                        final motif = motifController.text.trim();
                        if (motif.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.cancellationReason),
                              backgroundColor: Appstyle.danger,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                          return;
                        }

                        final echec = await _premierProduitInsuffisantPourAnnulationTransfert(
                          transfertsSelectionnes,
                          produits,
                        );
                        if (echec != null) {
                          final (produitInsuffisant, magasinCode) = echec;
                          final quantiteDisponible = await MouvementsServices.quantiteProduit(
                            produitInsuffisant.code,
                            magasinCode: magasinCode,
                          );
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.stockInsuffisantMagasin(
                              nomMagasin(magasinCode),
                              quantiteDisponible.toInt().toString(),
                              transfertsSelectionnes
                                  .where((t) => t.produitCode == produitInsuffisant.code && t.magasinDestCode == magasinCode)
                                  .fold<double>(0, (s, t) => s + t.quantite)
                                  .toInt()
                                  .toString(),
                            ),
                          );
                          return;
                        }

                        await _AnnulerTransferts(
                          userName: userName,
                          userCode: userCode,
                          transferts: transfertsSelectionnes,
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
