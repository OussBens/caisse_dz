import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:flutter/material.dart';
import '../../widget/section_decoration.dart';

List<SmartScanProduit> smartscanProduitsTest = [];

Future<void> _LoadAllData() async {
  smartscanProduitsTest = await SmartScanProduitServices.getAllSmartScanProduits();
}

Future<void> SmartScanDetail(
    BuildContext context,
    SmartScan scan,) async {
  await _LoadAllData();

  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;

      return BaseDialog(
        width: 900,
        height: 600,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/scan_icon.png",
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
                      "${l10n.smartScan} ${scan.code}",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.supplier}: ${scan.fournisseur}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    scan.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),
            _resumeChiffreSmartScan(scan, l10n),
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
                  detailinfo(l10n.code, scan.code),
                  detailinfo(l10n.date, scan.date.toString().split(" ").first),
                  detailinfo(l10n.activity, scan.activity),
                  detailinfo(l10n.supplier, scan.fournisseur),
                  detailinfo(l10n.status, scan.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.statistics,
                icon: Icons.auto_graph_sharp,
                child: detailwrap([
                  detailinfo(l10n.productCount, scan.nbrProduit),
                  detailinfo(l10n.scannedProductCount, scan.nbrProduitCalcul),
                  detailinfo(l10n.totalQuantity, scan.quantiteArticle),
                  detailinfo(l10n.scannedTotalQuantity, scan.quantiteArticleCalcul),
                  detailinfo(l10n.gap, scan.ecart),
                ]),
              ),

              SectionDecoration(
                title: l10n.amount,
                icon: Icons.monetization_on,
                child: detailwrap([
                  detailinfo(l10n.totalAmount, "${scan.montant} ${l10n.currency}"),
                  detailinfo(l10n.scannedTotalAmount, "${scan.montantCalcul} ${l10n.currency}"),
                  detailinfo(l10n.paye, "${scan.paye} ${l10n.currency}"),
                  detailinfo(l10n.reste, "${scan.reste} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    scan.observation?.isNotEmpty == true
                        ? scan.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, scan.creePar),
                  detailinfo(l10n.dateCreated,
                      scan.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, scan.modifPar),
                  detailinfo(l10n.modifiedAt,
                      scan.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, scan.annulPar),
                  detailinfo(l10n.cancelledAt,
                      scan.dateAnnul?.toString().split(" ").first),
                  detailinfo(l10n.cancellationReason, scan.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

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
                showDialog(
                  barrierColor: Appstyle.gris.withOpacity(0.4),
                  context: context,
                  builder: (_) =>
                      _dialogListeProduitsSmartScan(context, scan, l10n),
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

Widget _resumeChiffreSmartScan(SmartScan s, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.products, s.nbrProduit),
        detailbadge(l10n.quantity, s.quantiteArticle),
        detailbadge(l10n.amount, "${s.montant} ${l10n.currency}"),
        detailbadge(l10n.gap, s.ecart),
      ],
    ),
  );
}

Widget _dialogListeProduitsSmartScan(
    BuildContext context,
    SmartScan scan,
    AppLocalizations l10n,
    ) {
  final produits = smartscanProduitsTest
      .where((p) => p.codeSmartScan == scan.code)
      .toList();

  return BaseDialog(
    width: 700,
    height: 550,

    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.smartScanProducts(scan.code),
          style: Appstyle.textLB,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${l10n.supplier}: ${scan.fournisseur}",
                style: Appstyle.textSB),
            Text("${l10n.date}: ${scan.date}", style: Appstyle.textSB),
            Text("${l10n.total}: ${scan.montant} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
          ],
        ),
      ],
    ),

    content: SingleChildScrollView(
      child: DataTable(
        columns: [
          DataColumn(label: Text(l10n.code)),
          DataColumn(label: Text(l10n.product)),
          DataColumn(label: Text(l10n.quantity), numeric: true),
          DataColumn(label: Text(l10n.price), numeric: true),
          DataColumn(label: Text(l10n.total), numeric: true),
        ],
        rows: produits.map((p) {
          return DataRow(cells: [
            DataCell(Text(p.codeProduit)),
            DataCell(Text(p.nomProduit)),
            DataCell(Text("${p.quantite}")),
            DataCell(Text("${p.prix.toStringAsFixed(2)}")),
            DataCell(Text("${p.total.toStringAsFixed(2)}")),
          ]);
        }).toList(),
      ),
    ),

    footer: Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: Icon(Icons.close, color: Appstyle.Tblanc),
        label: Text(l10n.close,
            style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Appstyle.violet,
        ),
        onPressed: () => Navigator.pop(context),
      ),
    ),
  );
}