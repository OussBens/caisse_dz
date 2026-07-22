import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../widget/section_decoration.dart';

// ✅ Supprimer cette variable globale si elle n'est pas utilisée ailleurs
// List<PannierProduit> pannierProduitsTest = [];

// Future<void> _LoadAllData() async {
//   final db = await DbCreator.openDb();
//   pannierProduitsTest = await PPServices.getAllPP();
// }

Future<void> PannierDetail(BuildContext context, Pannier pannier) async {
  final l10n = AppLocalizations.of(context)!;

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
                      "${l10n.client} : ${pannier.client}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    pannier.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),
            _resumeChiffrePannier(pannier, l10n),
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
                  detailinfo(l10n.client, pannier.client),
                  detailinfo(l10n.cashier, pannier.caissier),
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
                  detailinfo(l10n.amountPaid, "${pannier.verse} ${l10n.currency}"),
                  detailinfo(l10n.remaining, "${pannier.reste} ${l10n.currency}"),
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
                  detailinfo(l10n.createdBy, pannier.caissier),
                  detailinfo(l10n.createdAt, pannier.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, pannier.modifParCode),
                  detailinfo(l10n.modifiedAt, pannier.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, pannier.annulPar),
                  detailinfo(l10n.cancelledAt, pannier.dateAnnul?.toString().split(" ").first),
                  detailinfo(l10n.cancellationReason, pannier.motifAnnul),
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
              label: Text(l10n.productsList),
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

Widget _resumeChiffrePannier(Pannier p, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.numberOfItems, p.nombreArticle),
        detailbadge(l10n.productQuantity, p.quantiteProduit),
        detailbadge(l10n.totalAmount, "${p.montant ?? 0} ${l10n.currency}"),
        detailbadge(l10n.remaining, "${p.reste ?? 0} ${l10n.currency}"),
      ],
    ),
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

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.4),
    builder: (_) {
      return BaseDialog(
        width: 700,
        height: 550,

        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.productsOfCart(pannier.code),
              style: Appstyle.textLB,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${l10n.client} : ${pannier.client}", style: Appstyle.textSB),
                Text("${l10n.date} : ${pannier.date.toString().split(" ").first}", style: Appstyle.textSB),
              ],
            ),
            Text("${l10n.total} : ${pannier.montant ?? 0} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
          ],
        ),

        content: produits.isEmpty
            ? Center(
          child: Text(
            l10n.noProducts,
            style: Appstyle.textSB.copyWith(color: Appstyle.gris),
          ),
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Appstyle.violet.withOpacity(0.1)),
                  headingTextStyle: Appstyle.textSB.copyWith(color: Appstyle.violet),
                  columns: [
                    DataColumn(label: Text(l10n.productCode)),
                    DataColumn(label: Text(l10n.productName)),
                    DataColumn(label: Text(l10n.quantity), numeric: true),
                    DataColumn(label: Text(l10n.price), numeric: true),
                    DataColumn(label: Text(l10n.total), numeric: true),
                  ],
                  rows: produits.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.codeProduit ?? "")),
                        DataCell(Text(p.nomProduit ?? "")),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.violet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p.quantite ?? 0}",
                              style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                            ),
                          ),
                        ),
                        DataCell(Text("${p.prix?.toStringAsFixed(2) ?? '0.00'}")),
                        DataCell(
                          Text(
                            "${p.total?.toStringAsFixed(2) ?? '0.00'}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),

        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(Icons.close, color: Appstyle.Tblanc),
            label: Text(l10n.close, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
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