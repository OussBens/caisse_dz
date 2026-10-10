import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_modif.dart' show updateMagasinStock, updateProduct;
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

/// Annulation "douce" des paniers sélectionnés : le ticket, ses lignes, ses
/// mouvements de stock et ses versements restent en base (conformité
/// fiscale — rien n'est supprimé ni modifié dans son contenu), seul leur
/// `etat` bascule à annulé/inactif. Le stock vendu est restitué.
Future<void> _AnnulerPannier({
  required String         userName,
  required String         userCode,
  required List<Pannier>  panniers,
  required String         motif,
  VoidCallback? onSuccess,
}) async {
  final db  = await DbCreator.openDb();


  final servicep  = PPServices(db);
  final servicem  = MouvementsServices(db);
  final services  = PannierServices(db);
  final serviceh  = HistoriqueServices(db);
  final serviceC  = ClientServices(db);
  final serviceV  = VerssementServices(db);

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
      // Magasin de la vente d'origine (celui du Mouvement annulé plus bas) —
      // la restitution doit se faire au même magasin, jamais un magasin figé.
      final mouvOriginal = mouvs.where((e) => e.codeProduit == prod.codeProduit).firstOrNull;

      // Restituer au stock la quantité réservée par ce panier pour ce produit
      await updateMagasinStock(
        produitCode: prod.codeProduit,
        ancienneQuantite: prod.quantite,
        nouvelleQuantite: 0,
        ancienNombre: prod.nombre,
        nouveauNombre: 0,
        magasinCode: mouvOriginal?.magasinCode,
      );
      await updateProduct(
        produitCode: prod.codeProduit,
        ancienneQuantite: prod.quantite,
        nouvelleQuantite: 0,
        ancienMontant: prod.total,
        nouveauMontant: 0,
        ancienNombre: prod.nombre,
        nouveauNombre: 0,
      );

      // Ligne conservée (preuve de la vente d'origine), seulement marquée annulée.
      prod.etat = false;
      prod.modifLe = DateTime.now();
      prod.modifParCode = userCode;
      prod.annulLe = DateTime.now();
      prod.annulParCode = userCode;
      prod.motifAnnul = motif;
      await servicep.updatePP(prod);

      // Multi-magasin : une ligne vendue peut avoir un mouvement PAR magasin
      // servi (RepartitionStock) — tous sont annulés, chaque magasin
      // récupère ainsi exactement ce qui en était sorti.
      for (final mouv in mouvs.where((e) => e.codeProduit == prod.codeProduit && e.etat)) {
        mouv.etat = false;
        mouv.dateAnnul = DateTime.now();
        mouv.annulParCode = userCode;
        mouv.motifAnnul = motif;
        await servicem.updateMouvement(mouv);
      }

      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
        id          : idh,
        code        : 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
        type        : 'pannierProduit',
        desc        : "l'utilisateur $userName a annulé le produit ${nomProduit(prod.codeProduit)} du panier ${pannier.code} (motif: $motif)",
        oper        : ListsConst.typeHisto[2],
        dateCree    : DateTime.now(),
        creeParCode : userCode,
      );
      await serviceh.addHistorique(histo);
    }

    // Versements liés à ce panier : bascule etat=inactif (même convention que
    // les versements liés à un retour), jamais de suppression.
    final versementsPannier = await serviceV.getVerssementsByCodeOperation(pannier.code);
    for (var v in versementsPannier) {
      if (!v.etat) continue;
      v.etat = false;
      v.dateAnnul = DateTime.now();
      v.annulParCode = userCode;
      v.motifAnnul = motif;
      await serviceV.updateVerssement(v);
    }
    if (versementsPannier.isNotEmpty) {
      int idhv = await _GetNextHistoriqueId();
      Historique histoV = Historique(
        id          : idhv,
        code        : 'HS$idhv${DateTime.now().millisecondsSinceEpoch}',
        type        : 'Versement',
        desc        : "l'utilisateur $userName a annulé le(s) versement(s) lié(s) au panier ${pannier.code} (motif: $motif)",
        oper        : ListsConst.typeHisto[2],
        dateCree    : DateTime.now(),
        creeParCode : userCode,
      );
      await serviceh.addHistorique(histoV);
    }

    final response = await services.annulerPannier(pannier.id, motif: motif, userCode: userCode);
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
      id          : idh,
      code        : 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
      type        : 'panniers',
      desc        : response.success
          ? "l'utilisateur $userName a annulé le panier ${pannier.code} (motif: $motif)"
          : "Échec annulation du panier ${pannier.code}: ${response.message}",
      oper        : ListsConst.typeHisto[2],
      dateCree    : DateTime.now(),
      creeParCode : userCode,
    );
    await serviceh.addHistorique(histo);

    client.dateModif  = DateTime.now();
    client.modifParCode   = userCode;
    await serviceC.updateClient(client);
  }

  if (onSuccess != null) {
    onSuccess();
  }
}

Future<void> AnnulerPannier(
    BuildContext context,
    List<Pannier> paniersSelectionnes, {
      VoidCallback? onSuccess, // 👈 Ajouter ce callback
    }) async {
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
        content: Text(AppLocalizations.of(context)!.noPermissionAction),
        backgroundColor: Appstyle.danger,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  // ✅ Panier(s) déjà annulé(s) : on le signale. Si tous le sont, rien à
  // faire ; sinon on n'annule que les paniers encore actifs.
  final dejaAnnules = paniersSelectionnes.where((p) => !p.etat).toList();
  if (dejaAnnules.isNotEmpty) {
    final l10n = AppLocalizations.of(context)!;
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.panier,
      message: l10n.cartsAlreadyCancelled(dejaAnnules.map((p) => p.code ?? '').join(', ')),
    );
    paniersSelectionnes = paniersSelectionnes.where((p) => p.etat).toList();
    if (paniersSelectionnes.isEmpty || !context.mounted) return;
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
                                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                              ),
                              child: Text(
                                "${l10n.cartId(p.code)} - ${l10n.client}: ${nomClient(p.client_code)} - ${l10n.totalAmount}: ${NumberFormatUtil.formatMontant(p.montant, decimales: 2)} ${l10n.currency}",
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.confirm,
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
                        await _AnnulerPannier(
                          userName: userName,
                          userCode: userCode,
                          panniers: paniersSelectionnes,
                          motif: motif,
                          onSuccess: onSuccess, // 👈 Passer le callback
                        );
                        Navigator.pop(context);
                      },
                      icon: Icons.block,
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