import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Sortie.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

/// Annulation "douce" des sorties sélectionnées : la sortie et son mouvement
/// de stock restent en base (jamais de suppression physique), seul leur
/// `etat` bascule à annulé — même principe que pannier_actif.dart. Le stock
/// sorti (perte/don/expiration) est restitué.
Future<void> _AnnulerSs({
  required String userName,
  required String userCode,
  required List<Sortie> sorties,
  required String motif,
}) async {
  final db = await DbCreator.openDb();
  final services = SortieServices(db);
  final serviceh = HistoriqueServices(db);
  final servicep = ProduitServices(db);
  final serviceM = MouvementsServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final produits = await ProduitServices.getAllProduits();
  Produit prod;

  for (var sortie in sorties) {
    prod = produits.where((e) => e.code == sortie.produitCode).first;

    if (!prod.service) {
      if (sortie.nombre != null) prod.nombre = prod.nombre + sortie.nombre!;
    }
    prod.dateModif = DateTime.now();
    prod.modifParCode = userCode;

    await servicep.updateProduit(prod);

    // Restitution du stock par magasin — symétrique du déstockage fait à la
    // création (sortie_nouveau.dart), sinon annuler une sortie ne restaurait
    // que le stock global et laissait produit_magasin_detail faux.
    if (!prod.service && sortie.magasinCode != null) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
        prod.code,
        sortie.magasinCode!,
      );
      if (magasinDetail != null) {
        if (sortie.nombre != null) {
          await pmdService.incrementNombre(magasinDetail.id, sortie.nombre!);
        }
      }
    }

    // Mouvement de stock lié : soft-cancel (jamais de suppression).
    // Multi-magasin : une sortie peut avoir un mouvement par magasin touché.
    final mouvment = await MouvementsServices.getAllMouvementsByCodeOper(sortie.code);
    for (final m in mouvment.where((e) => e.etat)) {
      m.etat = false;
      m.dateAnnul = DateTime.now();
      m.annulParCode = userCode;
      m.motifAnnul = motif;
      await serviceM.updateMouvement(m);
    }

    final response = await services.annulerSortie(sortie.id, motif: motif, userCode: userCode);

    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id: idh,
        code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
        type: "sortie",
        desc: response.success
            ? "L'utilisateur $userName a annulé la Sortie de Produit ${prod.nom} de Type ${sortie.type} (motif: $motif)"
            : "Échec annulation de la Sortie ${sortie.code}: ${response.message}",
        oper: ListsConst.typeHisto[2],
        dateCree: DateTime.now(),
        creeParCode: userCode
    );

    await serviceh.addHistorique(histo);
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
  final produitsA = await ProduitServices.getAllProduits();

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
                  text: l10n.cancelExits,
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
                                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.inventory_2,
                                      color: Appstyle.violet, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "${produitsA.where((p) => p.code == s.produitCode).firstOrNull?.nom ?? s.produitCode}  |  ${l10n.quantity}: ${s.quantite}",
                                      style: Appstyle.textSB.copyWith(
                                        color: Appstyle.Tnoir,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "${NumberFormatUtil.formatMontant(s.montant, decimales: 2)} ${l10n.currency}",
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
                      l10n.confirmCancelExits,
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
                      text: l10n.cancelExits,
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

                        await _AnnulerSs(
                            userName: userName,
                            userCode: userCode,
                            sorties: sortiesSelectionnees,
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
