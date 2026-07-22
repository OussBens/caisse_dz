import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BesionListDetail.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import '../../widget/section_decoration.dart';

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
                    Text("${l10n.supplier} : ${besoin.fournisseur}",
                        style: Appstyle.textSB),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    besoin.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
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
                  detailinfo(l10n.supplier, besoin.fournisseur),
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
              label: Text(l10n.productsList),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.crevete,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                showDialog(
                  barrierColor: Appstyle.gris.withOpacity(0.4),
                  context: context,
                  builder: (_) => _dialogListeProduitsBesoin(context, besoin, l10n),
                );
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

Widget _resumeChiffreBesoin(BesoinList b, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.numberOfArticles, b.nombreArticle),
        detailbadge(l10n.totalQuantity, b.quantite),
        detailbadge(l10n.totalAmount, "${b.montant} ${l10n.currency}"),
      ],
    ),
  );
}

Widget _dialogListeProduitsBesoin(
    BuildContext context,
    BesoinList besoin,
    AppLocalizations l10n,
    ) {
  final produits = besoinListDetailsTest
      .where((d) => d.besoinListCode == besoin.code)
      .toList();

  return BaseDialog(
    width: 700,
    height: 550,

    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.productsOfNeed(besoin.code),
            style: Appstyle.textLB),
        const SizedBox(height: 6),
        Text("${l10n.supplier} : ${besoin.fournisseur}", style: Appstyle.textSB),
        Text("${l10n.total} : ${besoin.montant} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
      ],
    ),

    content: SingleChildScrollView(
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.productCode)),
          DataColumn(label: Text(l10n.productName)),
          DataColumn(label: Text(l10n.productQuantity), numeric: true),
          DataColumn(label: Text(l10n.productPrice), numeric: true),
          DataColumn(label: Text(l10n.productTotal), numeric: true),
        ],
        rows: produits.map((p) {
          return DataRow(cells: [
            DataCell(Text(p.ProduitCode)),
            DataCell(Text(p.ProduitNom)),
            DataCell(Text("${p.quantite}")),
            DataCell(Text("${p.prix.toStringAsFixed(2)}")),
            DataCell(Text("${p.montant.toStringAsFixed(2)}")),
          ]);
        }).toList(),
      ),
    ),

    footer: Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: const Icon(Icons.close, color: Colors.white),
        label: Text(l10n.close),
        style: ElevatedButton.styleFrom(backgroundColor: Appstyle.violet),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );
}