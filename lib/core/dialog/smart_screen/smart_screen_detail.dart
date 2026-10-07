import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/detail_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<SmartScanProduit> smartscanProduitsTest = [];

Future<void> _LoadAllData() async {
  smartscanProduitsTest = await SmartScanProduitServices.getAllSmartScanProduits();
}

Future<void> SmartScanDetail(
    BuildContext context,
    SmartScan scan,) async {
  await _LoadAllData();
  final db = await DbCreator.openDb();
  final serviceV = VerssementServices(db);
  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  final nomFournisseur = fournisseurs.firstWhereOrNull((f) => f.code == scan.fournisseurCode)?.nom
      ?? scan.fournisseurCode;
  final produitsCatalogue = await ProduitServices.getAllProduits();
  String nomProduit(String code) =>
      produitsCatalogue.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  // Montant versé / reste / nombre de versements : calculés dynamiquement à
  // partir des versements liés à ce smart scan (plus de colonnes statiques).
  final versementsScan = await serviceV.getVerssementsByCodeOperation(scan.code);
  final double verse = SmartScanServices.calculerVerse(versementsScan, scan.code);
  final double reste = scan.montant - verse;
  final int nbrVersement = SmartScanServices.calculerNbrVersement(versementsScan, scan.code);

  return showDialog(
    context: context,
    barrierDismissible: false,
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
                      "${l10n.supplier}: $nomFournisseur",
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
            _resumeChiffreSmartScan(scan, verse, reste, nbrVersement, l10n),
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
                  detailinfo(l10n.supplier, nomFournisseur),
                  detailinfo(l10n.status, scan.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.statistics,
                icon: Icons.auto_graph_sharp,
                child: detailwrap([
                  detailinfo(l10n.productCount, scan.nbrProduit),
                ]),
              ),

              SectionDecoration(
                title: l10n.amount,
                icon: Icons.monetization_on,
                child: detailwrap([
                  detailinfo(l10n.totalAmount, "${scan.montant} ${l10n.currency}"),
                  detailinfo(l10n.paye, "$verse ${l10n.currency}"),
                  detailinfo(l10n.numberOfPayments, nbrVersement),
                  detailinfo(l10n.reste, "$reste ${l10n.currency}"),
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
                  detailinfo(l10n.createdBy, scan.creeParCode),
                  detailinfo(l10n.dateCreated,
                      scan.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, scan.modifParCode),
                  detailinfo(l10n.modifiedAt,
                      scan.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, scan.annulParCode),
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
                      _dialogListeProduitsSmartScan(context, scan, nomFournisseur, nomProduit, l10n),
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

/// Affiche la liste des produits d'un smart scan de façon autonome (charge
/// ses propres données) — utilisé par AfficheurSmartScan (bouton "Liste
/// produit") sans passer par SmartScanDetail.
Future<void> showSmartScanProductsListDialog(
    BuildContext context,
    SmartScan scan,
    AppLocalizations l10n,
    ) async {
  await _LoadAllData();
  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  final nomFournisseur = fournisseurs.firstWhereOrNull((f) => f.code == scan.fournisseurCode)?.nom
      ?? scan.fournisseurCode;
  final produitsCatalogue = await ProduitServices.getAllProduits();
  String nomProduit(String code) =>
      produitsCatalogue.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  if (!context.mounted) return;
  return showDialog(
    barrierColor: Appstyle.gris.withOpacity(0.4),
    context: context,
    builder: (_) =>
        _dialogListeProduitsSmartScan(context, scan, nomFournisseur, nomProduit, l10n),
  );
}

// smart_scan_detail.dart - Remplacer _resumeChiffreSmartScan
Widget _resumeChiffreSmartScan(
    SmartScan s, double verse, double reste, int nbrVersement, AppLocalizations l10n) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(label: l10n.products, value: s.nbrProduit),
      StatsItem(label: l10n.amount, value: "${s.montant} ${l10n.currency}"),
      StatsItem(label: l10n.paye, value: "$verse ${l10n.currency}"),
      StatsItem(label: l10n.numberOfPayments, value: nbrVersement),
      StatsItem(label: l10n.reste, value: "$reste ${l10n.currency}"),
    ],
  );
}

Widget _dialogListeProduitsSmartScan(
    BuildContext context,
    SmartScan scan,
    String nomFournisseur,
    String Function(String) nomProduit,
    AppLocalizations l10n,
    ) {
  final produits = smartscanProduitsTest
      .where((p) => p.codeSmartScan == scan.code)
      .toList();

  return BaseDialog(
    width: 1100,
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
            Text("${l10n.supplier}: $nomFournisseur",
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
          DataColumn(label: Text(l10n.numberField), numeric: true),
          DataColumn(label: Text(l10n.price), numeric: true),
          DataColumn(label: Text(l10n.total), numeric: true),
        ],
        rows: produits.map((p) {
          return DataRow(cells: [
            DataCell(Text(p.codeProduit)),
            DataCell(Text(nomProduit(p.codeProduit))),
            DataCell(Text("${p.quantite}")),
            DataCell(Text(p.nombre != null ? "${p.nombre}" : "-")),
            DataCell(Text("${NumberFormatUtil.formatMontant(p.prix, decimales: 2)}")),
            DataCell(Text("${NumberFormatUtil.formatMontant(p.total, decimales: 2)}")),
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