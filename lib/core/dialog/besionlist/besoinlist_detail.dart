import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BesionListDetail.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../produits_liste_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<BesoinListDetail>  besoinListDetailsTest = [];

Future<void> _LoadAllData() async {
  final db  = await DbCreator.openDb();
  besoinListDetailsTest = await BesoinListDetailServices.getAllBesoinListDetail();
}

Future<void> BesoinListDetailDialog(
    BuildContext context,
    BesoinList    besoin,
    ) async {
  await _LoadAllData();
  final l10n = AppLocalizations.of(context)!;
  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  final nomFournisseur = fournisseurs.firstWhereOrNull((f) => f.code == besoin.fournisseurCode)?.nom
      ?? besoin.fournisseurCode;

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
                  "assets/icons/cardwidget/liste_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${l10n.needDetail} ${besoin.code}",
                        style: Appstyle.textLB.copyWith(fontSize: 20)),
                    Text("${l10n.supplier} : $nomFournisseur",
                        style: Appstyle.textSB),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    besoin.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: besoin.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: besoin.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: besoin.etat ? 2 : 0,
                )

              ],
            ),
            const SizedBox(height: 16),
            _resumeChiffreBesoin(besoin, l10n),
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
                  detailinfo(l10n.code, besoin.code),
                  detailinfo("Numéro", besoin.numero),
                  detailinfo(l10n.date, besoin.date.toString().split(" ").first),
                  detailinfo(l10n.supplier, nomFournisseur),
                  detailinfo(l10n.status, besoin.etat ? l10n.active : l10n.inactive),
                ]),
              ),
              SectionDecoration(
                title: l10n.articles,
                icon: Icons.auto_graph,
                child: detailwrap([
                  detailinfo(l10n.numberOfArticles, besoin.nombreArticle),
                  detailinfo(l10n.totalQuantity, besoin.quantite),
                  detailinfo(l10n.totalAmount, "${besoin.montant} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    besoin.observation?.isNotEmpty == true
                        ? besoin.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, besoin.creeParCode),
                  detailinfo(l10n.createdAt,
                      besoin.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, besoin.modifParCode),
                  detailinfo(l10n.modifiedAt,
                      besoin.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, besoin.annulParCode),
                  detailinfo(l10n.cancelledAt,
                      besoin.dateAnnul?.toString().split(" ").first),
                  detailinfo(l10n.cancellationReason, besoin.motifAnnul),
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                showBesoinListProduitsDialog(context, besoin, nomFournisseur, l10n);
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
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}

// besoin_list_detail.dart - Remplacer _resumeChiffreBesoin
Widget _resumeChiffreBesoin(BesoinList b, AppLocalizations l10n) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(label: l10n.numberOfArticles, value: b.nombreArticle),
      StatsItem(label: l10n.totalQuantity, value: b.quantite),
      StatsItem(label: l10n.totalAmount, value: "${b.montant} ${l10n.currency}"),
    ],
  );
}

Future<void> showBesoinListProduitsDialog(
    BuildContext context,
    BesoinList besoin,
    String nomFournisseur,
    AppLocalizations l10n,
    ) {
  final produits = besoinListDetailsTest
      .where((d) => d.besoinListCode == besoin.code)
      .toList();

  final quantiteTotale = produits.fold(0.0, (sum, p) => sum + p.quantite);
  final montantTotal = produits.fold(0.0, (sum, p) => sum + p.montant);

  return ProduitsListeDialog.afficher(
    context: context,
    titre: l10n.productsOfNeed(besoin.code),
    sousTitre: [
      Text("${l10n.supplier} : $nomFournisseur", style: Appstyle.textSB),
    ],
    stats: [
      StatBadge(label: l10n.numberOfItems, valeur: "${produits.length}"),
      StatBadge(label: l10n.totalQuantity, valeur: NumberFormatUtil.formatMontant(quantiteTotale, decimales: 0)),
      StatBadge(
        label: l10n.total,
        valeur: "${NumberFormatUtil.formatMontant(montantTotal, decimales: 2)} ${l10n.currency}",
        couleur: Appstyle.crevete,
      ),
    ],
    colonnes: [
      DataColumn(label: Text(l10n.productCode)),
      DataColumn(label: Text(l10n.productName)),
      DataColumn(label: Text(l10n.productQuantity), numeric: true),
      DataColumn(label: Text(l10n.productPrice), numeric: true),
      DataColumn(label: Text(l10n.productTotal), numeric: true),
    ],
    lignes: produits.map((p) {
      return DataRow(cells: [
        DataCell(Text(p.ProduitCode)),
        DataCell(Text(p.ProduitNom)),
        DataCell(pilluleCellule("${p.quantite}", Appstyle.violet)),
        DataCell(Text(NumberFormatUtil.formatMontant(p.prix, decimales: 2))),
        DataCell(Text(
          NumberFormatUtil.formatMontant(p.montant, decimales: 2),
          style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
        )),
      ]);
    }).toList(),
    messageVide: l10n.noProductsAssociated,
  );
}