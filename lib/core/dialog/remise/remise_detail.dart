import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/remise.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import '../produits_liste_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<Produit> ProduitTest = [];

Future<void> _loadData({required Remise remis}) async {
  final db = await DbCreator.openDb();
  final service = ProduitServices(db);
  ProduitTest = await ProduitServices.getAllProduits();
}

Future<void> RemiseDetail(BuildContext context, Remise remise) async {
  await _loadData(remis: remise);

  final int nombreProduits = ProduitTest.where((p) => p.remiseId == remise.id).length;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return BaseDialog(
        width: 1100,
        height: 600,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/remise_icon.png",
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
                      remise.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${remise.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    remise.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: remise.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: remise.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: remise.etat ? 2 : 0,
                )
              ],
            ),
            const SizedBox(height: 16),
            _resumeRemise(remise, l10n, nombreProduits),
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
                  detailinfo(l10n.name, remise.nom),
                  detailinfo(l10n.code, remise.code),
                  detailinfo(l10n.type, remise.type),
                  detailinfo(l10n.amount, remise.montant),
                  detailinfo(l10n.rateType, remise.tauxType),
                  detailinfo(l10n.rate, remise.taux),
                  if (remise.type == "Par Produit")
                    detailinfo(l10n.productCount, nombreProduits),
                  detailinfo(
                    l10n.start,
                    remise.debut?.toString().split(" ").first,
                  ),
                  detailinfo(
                    l10n.end,
                    remise.fin?.toString().split(" ").first,
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: Text(
                  remise.observation ?? "-",
                  style: Appstyle.textSB,
                ),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, remise.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    remise.creeLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, remise.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    remise.modifLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, remise.annulParCode),
                  detailinfo(
                    l10n.cancelledAt,
                    remise.annulLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancellationReason, remise.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (remise.type == "Par Produit")
              ElevatedButton.icon(
                icon: const Icon(Icons.list),
                label: Text(l10n.productList),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.crevete,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                  ),
                ),
                onPressed: () {
                  showRemiseProductsListDialog(context, remise, l10n);
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
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD),
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

// remise_detail.dart - Remplacer _resumeRemise
Widget _resumeRemise(Remise r, AppLocalizations l10n, int nombreProduits) {
  List<StatsItem> items = [
    StatsItem(label: l10n.code, value: r.code),
    StatsItem(label: l10n.type, value: r.type),
  ];



  if (r.type == "Par Produit") {
    items.add(StatsItem(label: l10n.productCount, value: nombreProduits));
  }
  else
  {
    items.add(StatsItem(label: l10n.montant, value: r.montant));
  }


  items.add(StatsItem(label: l10n.discountRate, value: r.tauxType == "Pourcentage" ? "${r.taux}%" : "${r.taux} ${l10n.currency}"));

  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: items,
  );
}
// ================= Dialogue Liste des produits de la remise =================
Future<void> showRemiseProductsListDialog(BuildContext context, Remise remise, AppLocalizations l10n) async {
  await _loadData(remis: remise);

  final produits = ProduitTest.where((e) => e.remiseId == remise.id).toList();

  return ProduitsListeDialog.afficher(
    context: context,
    titre: l10n.productsOfDiscount(remise.code ?? ""),
    sousTitre: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${l10n.discount} : ${remise.nom}", style: Appstyle.textSB),
          Text("${l10n.type} : ${remise.type}", style: Appstyle.textSB.copyWith(color: Appstyle.crevete)),
        ],
      ),
    ],
    stats: [
      StatBadge(label: l10n.numberOfItems, valeur: "${produits.length}"),
    ],
    colonnes: [
      DataColumn(label: Text(l10n.productCode)),
      DataColumn(label: Text(l10n.productName)),
      DataColumn(label: Text(l10n.discountRate), numeric: true),
      DataColumn(label: Text(l10n.discountApplicationAmount), numeric: true),
    ],
    lignes: produits.map((p) {
      double tauxRemise = remise.taux ?? 0;
      double montantRemise = (p.prixVente * tauxRemise / 100);

      return DataRow(
        cells: [
          DataCell(Text(p.code, style: Appstyle.textSB)),
          DataCell(Text(p.nom, style: Appstyle.textSB)),
          DataCell(pilluleCellule("$tauxRemise%", Appstyle.crevete)),
          DataCell(Text(
            "${NumberFormatUtil.formatMontant(montantRemise, decimales: 2)} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
          )),
        ],
      );
    }).toList(),
    messageVide: l10n.noProductsAssociated,
  );
}