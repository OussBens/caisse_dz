import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/retour.dart';
import '../../widget/detail_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> RetourDetail(BuildContext context, Retour retour) async {
  final produits = await ProduitServices.getAllProduits();
  final clients = await ClientServices.getAllClients();
  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  final nomProduit = produits.firstWhereOrNull((p) => p.code == retour.codeProduit)?.nom ?? retour.codeProduit;
  final nomClient = clients.firstWhereOrNull((c) => c.code == retour.client_code)?.nom;
  final nomFournisseur = fournisseurs.firstWhereOrNull((f) => f.code == retour.fournisseur_code)?.nom;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      return BaseDialog(
        width: 1100,
        height: 600,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/retour_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomProduit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${retour.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    retour.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: retour.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: retour.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: retour.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeRetour(retour, l10n),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.info_outline,
                child: detailwrap([
                  detailinfo(l10n.type, translator.translateTypeRetour(retour.type)),
                  detailinfo(l10n.client, nomClient),
                  detailinfo(l10n.supplier, nomFournisseur),
                  detailinfo(l10n.status, retour.etat ? l10n.active : l10n.inactive),
                ]),
              ),
              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, nomProduit),
                  detailinfo(l10n.quantity, retour.quantite),
                  detailinfo(l10n.numberField, retour.nombre),
                  detailinfo(l10n.purchasePrice, "${retour.prixAchat ?? 0} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${retour.prixVente ?? 0} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    retour.observation?.isNotEmpty == true
                        ? retour.observation
                        : "-",
                  ),
                ]),
              ),
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, retour.creeParCode),
                  detailinfo(l10n.dateCreated, (retour.dateCree)),
                  detailinfo(l10n.modifiedBy, retour.modifParCode),
                  detailinfo(l10n.modifiedAt, (retour.dateModif)),
                  detailinfo(l10n.cancelledBy, retour.annulParCode),
                  detailinfo(l10n.cancellationReason, retour.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.close),
            label: Text(l10n.close),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}
// retour_detail.dart - Remplacer _resumeRetour
Widget _resumeRetour(Retour r, AppLocalizations l10n) {
  return StatsCard(
     items: [
      StatsItem(label: l10n.quantity, value: r.quantite ?? 0),
      StatsItem(label: l10n.purchasePrice, value: "${r.prixAchat ?? 0} ${l10n.currency}"),
      StatsItem(label: l10n.salePrice, value: "${r.prixVente ?? 0} ${l10n.currency}"),
      StatsItem(label: l10n.type, value: r.type ?? "-"),
    ],
  );
}