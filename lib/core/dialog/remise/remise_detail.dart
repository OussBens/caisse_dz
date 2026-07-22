import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/remise.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

List<Produit> ProduitTest = [];

Future<void> _loadData({required Remise remis}) async {
  final db = await DbCreator.openDb();
  final service = ProduitServices(db);
  ProduitTest = await ProduitServices.getAllProduits();
}

Future<void> RemiseDetail(BuildContext context, Remise remise) async {
  await _loadData(remis: remise);

  final int nombreProduits = ProduitTest.where((p) => p.remise == remise.nom).length;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      return BaseDialog(
        width: 950,
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
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
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
                  detailinfo(l10n.modifiedBy, remise.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    remise.modifLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, remise.annulPar),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  showDialog(
                    barrierColor: Appstyle.gris.withOpacity(0.4),
                    context: context,
                    builder: (_) => _dialogListeProduitsRemise(context, remise, l10n),
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

Widget _resumeRemise(Remise r, AppLocalizations l10n, int nombreProduits) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge("ID", r.id),
        detailbadge(l10n.amount, r.montant),
        if (r.type == "Par Produit")
          detailbadge(l10n.productCount, nombreProduits),
        detailbadge(l10n.status, r.etat),
      ],
    ),
  );
}

// ================= Dialogue Liste des produits de la remise =================
Widget _dialogListeProduitsRemise(BuildContext context, Remise remise, AppLocalizations l10n) {
  final produits = ProduitTest.where((e) => e.remise == remise.nom).toList();

  // Calcul du nombre de produits
  int nombreProduits = produits.length;

  return BaseDialog(
    width: 800,
    height: 550,

    // ───────── HEADER ─────────
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productsOfDiscount(remise.code ?? ""),
          style: Appstyle.textLB,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${l10n.discount} : ${remise.nom}",
              style: Appstyle.textSB,
            ),
            Text(
              "${l10n.type} : ${remise.type}",
              style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Résumé des produits
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Appstyle.violet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Column(
                children: [
                  Text(l10n.numberOfItems, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                  Text(
                    "$nombreProduits",
                    style: Appstyle.textLB.copyWith(color: Appstyle.violet, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),

    // ───────── CONTENT ─────────
    content: produits.isEmpty
        ? Center(
      child: Text(
        l10n.noProductsAssociated,
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
              columnSpacing: 16,
              columns: [
                DataColumn(label: Text(l10n.productCode, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l10n.productName, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
                DataColumn(label: Text(l10n.discountRate, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text(l10n.discountApplicationAmount, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
              ],
              rows: produits.map((p) {
                // Calcul de la remise (à adapter selon votre logique métier)
                double tauxRemise = remise.taux ?? 0;
                double montantRemise = (p.prixVente * tauxRemise / 100);

                return DataRow(
                  cells: [
                    DataCell(Text(p.code, style: Appstyle.textSB)),
                    DataCell(Text(p.nom, style: Appstyle.textSB)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Appstyle.crevete.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "$tauxRemise%",
                          style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        "${montantRemise.toStringAsFixed(2)} ${l10n.currency}",
                        style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
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

    // ───────── FOOTER ─────────
    footer: Align(
      alignment: Alignment.centerRight,
      child: ElevatedButton.icon(
        icon: Icon(Icons.close, color: Appstyle.Tblanc),
        label: Text(
          l10n.close,
          style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
        ),
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
}// Ajoutez cette fonction à la fin du fichier remise_detail.dart
Future<void> showRemiseProductsListDialog(BuildContext context, Remise remise, AppLocalizations l10n) async {
  await _loadData(remis: remise);

  final produits = ProduitTest.where((e) => e.remise == remise.nom).toList();

  // Calcul du nombre de produits
  int nombreProduits = produits.length;

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.4),
    builder: (_) {
      return BaseDialog(
        width: 800,
        height: 550,

        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.productsOfDiscount(remise.code ?? ""),
              style: Appstyle.textLB,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${l10n.discount} : ${remise.nom}",
                  style: Appstyle.textSB,
                ),
                Text(
                  "${l10n.type} : ${remise.type}",
                  style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Appstyle.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(
                    children: [
                      Text(l10n.numberOfItems, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                      Text(
                        "$nombreProduits",
                        style: Appstyle.textLB.copyWith(color: Appstyle.violet, fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),

        content: produits.isEmpty
            ? Center(
          child: Text(
            l10n.noProductsAssociated,
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
                  columnSpacing: 16,
                  columns: [
                    DataColumn(label: Text(l10n.productCode, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.productName, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
                    DataColumn(label: Text(l10n.discountRate, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text(l10n.discountApplicationAmount, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: produits.map((p) {
                    // Calcul de la remise
                    double tauxRemise = remise.taux ?? 0;
                    double montantRemise = (p.prixVente * tauxRemise / 100);

                    return DataRow(
                      cells: [
                        DataCell(Text(p.code, style: Appstyle.textSB)),
                        DataCell(Text(p.nom, style: Appstyle.textSB)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.crevete.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$tauxRemise%",
                              style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${montantRemise.toStringAsFixed(2)} ${l10n.currency}",
                            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
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
            label: Text(
              l10n.close,
              style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
            ),
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