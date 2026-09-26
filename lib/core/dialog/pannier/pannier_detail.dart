import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/core/widget/status_badge.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../produits_liste_dialog.dart';

// ✅ Supprimer cette variable globale si elle n'est pas utilisée ailleurs
// List<PannierProduit> pannierProduitsTest = [];

// Future<void> _LoadAllData() async {
//   final db = await DbCreator.openDb();
//   pannierProduitsTest = await PPServices.getAllPP();
// }

Future<void> PannierDetail(BuildContext context, Pannier pannier) async {
  final l10n = AppLocalizations.of(context)!;
  final db = await DbCreator.openDb();
  final serviceV = VerssementServices(db);
  final clients = await ClientServices.getAllClients();
  final utilisateurs = await UtilisateurServices.getAllUtilisateurs();
  final versementsPannier = await serviceV.getVerssementsByCodeOperation(pannier.code);
  final nomClient = clients.firstWhereOrNull((c) => c.code == pannier.client_code)?.nom ?? '';
  final nomCaissier = utilisateurs.firstWhereOrNull((u) => u.code == pannier.caissier_code)?.username ?? pannier.caissier_code;
  final hasRetour = (await RetourServices.getRetoursByPannierCode(pannier.code)).isNotEmpty;

  // Montant versé / reste / nombre de versements : calculés dynamiquement à
  // partir des versements liés à ce panier (plus de colonnes statiques).
  final double verse = PannierServices.calculerVerse(versementsPannier, pannier.code);
  final double reste = pannier.montant - verse;
  final int nbrVersement = PannierServices.calculerNbrVersement(versementsPannier, pannier.code);

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 1100,
        height: 700,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/pannier_icon.png",
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
                      l10n.cartNumber.replaceAll('{code}', pannier.code),
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.client} : $nomClient",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                if (hasRetour) ...[
                  StatusBadge(text: l10n.hasReturn, color: Colors.orange),
                  const SizedBox(width: 8),
                ],
                Chip(
                  label: Text(
                    pannier.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: pannier.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: pannier.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: pannier.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),
            _resumeChiffrePannier(pannier, verse, reste, nbrVersement, l10n),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.info_outline,
                child: detailwrap([
                  detailinfo(l10n.code, pannier.code),
                  detailinfo(l10n.date, pannier.date.toString().split(" ").first),
                  detailinfo(l10n.client, nomClient),
                  detailinfo(l10n.cashier, nomCaissier),
                  detailinfo(l10n.cartType, pannier.typepannier),
                  detailinfo(l10n.status, pannier.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.itemsAndQuantities,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.numberOfItems, pannier.nombreArticle),
                  detailinfo(l10n.productQuantity, pannier.quantiteProduit),
                ]),
              ),

              SectionDecoration(
                title: l10n.payment,
                icon: Icons.paid,
                child: detailwrap([
                  detailinfo(l10n.totalAmount, "${pannier.montant} ${l10n.currency}"),
                  detailinfo(l10n.totalAchat, "${pannier.montantAchat} ${l10n.currency}"),
                  detailinfo(l10n.marge, "${pannier.marge} ${l10n.currency}"),
                  detailinfo(l10n.amountPaid, "$verse ${l10n.currency}"),
                  detailinfo(l10n.remaining, "$reste ${l10n.currency}"),
                  detailinfo(l10n.numberOfPayments, nbrVersement),
                  detailinfo(l10n.paymentMethod, pannier.modePaiement),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    pannier.observation?.isNotEmpty == true ? pannier.observation : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, nomCaissier),
                  detailinfo(l10n.createdAt, pannier.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, pannier.modifParCode),
                  detailinfo(l10n.modifiedAt, pannier.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, pannier.annulParCode),
                  detailinfo(l10n.cancelledAt, pannier.dateAnnul?.toString().split(" ").first),
                  detailinfo(l10n.cancellationReason, pannier.motifAnnul),
                  detailinfo(l10n.fiscalHash, pannier.hash),
                ]),
              ),
            ],
          ),
        ),

        // ================= FOOTER =================
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.list),
              label: Text(l10n.productList),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.crevete,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                // ✅ Utiliser la fonction partagée
                showProductsListDialog(context, pannier, l10n);
              },
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
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
          ],
        ),
      );
    },
  );
}
// Dans pannier_detail.dart
Widget _resumeChiffrePannier(
    Pannier p, double verse, double reste, int nbrVersement, AppLocalizations l10n) {
  return StatsCard(
    items: [
      StatsItem(
        label: l10n.numberOfItems,
        value: p.nombreArticle,
      ),
      StatsItem(
        label: l10n.productQuantity,
        value: p.quantiteProduit,
      ),
      StatsItem(
        label: l10n.totalAmount,
        value: "${p.montant} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.amountPaid,
        value: "$verse ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.numberOfPayments,
        value: nbrVersement,
      ),
      StatsItem(
        label: l10n.remaining,
        value: "$reste ${l10n.currency}",
      ),
    ],
  );
}
/// Dialogue partagé pour afficher la liste des produits d'un panier
Future<void> showProductsListDialog(
    BuildContext context,
    Pannier pannier,
    AppLocalizations l10n,
    ) async {
  final db = await DbCreator.openDb();
  final ppService = PPServices(db);
  final produits = await ppService.getPPByCodePannier(pannier.code!);
  final catalogueProduits = await ProduitServices.getAllProduits();
  String nomProduit(String code) =>
      catalogueProduits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;
  final catalogueClients = await ClientServices.getAllClients();
  final nomClient = catalogueClients.firstWhereOrNull((c) => c.code == pannier.client_code)?.nom ?? '';

  return ProduitsListeDialog.afficher(
    context: context,
    titre: l10n.productsOfCart(pannier.code),
    sousTitre: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${l10n.client} : $nomClient", style: Appstyle.textSB),
          Text("${l10n.date} : ${pannier.date.toString().split(" ").first}", style: Appstyle.textSB),
        ],
      ),
      Text("${l10n.total} : ${pannier.montant ?? 0} ${l10n.currency}",
          style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
    ],
    colonnes: [
      DataColumn(label: Text(l10n.productCode)),
      DataColumn(label: Text(l10n.productName)),
      DataColumn(label: Text(l10n.quantity), numeric: true),
      DataColumn(label: Text(l10n.numberField), numeric: true),
      DataColumn(label: Text(l10n.price), numeric: true),
      DataColumn(label: Text(l10n.total), numeric: true),
    ],
    lignes: produits.map((p) {
      return DataRow(
        cells: [
          DataCell(Text(p.codeProduit ?? "")),
          DataCell(Text(nomProduit(p.codeProduit))),
          DataCell(pilluleCellule("${p.quantite ?? 0}", Appstyle.violet)),
          DataCell(Text(p.nombre != null ? "${p.nombre}" : "-")),
          DataCell(Text(NumberFormatUtil.formatMontant(p.prix ?? 0, decimales: 2))),
          DataCell(Text(
            NumberFormatUtil.formatMontant(p.total ?? 0, decimales: 2),
            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
          )),
        ],
      );
    }).toList(),
    messageVide: l10n.noProducts,
  );
}