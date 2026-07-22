import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/pack.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

List<ProduitPackDetail> produitPackDetailsTest = [];

Future<void> _LoadAllData({required Pack pack}) async {
  final result = await ProduitPackDetailServices.getDetailsByPackNom(pack.nom);
  produitPackDetailsTest = result;
}

Future<void> PackDetail(BuildContext context, Pack pack) async {
  await _LoadAllData(pack: pack);
  final int nombreProduits = produitPackDetailsTest.length;
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 950,
        height: 600,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/pack_icon.png",
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
                      pack.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${pack.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    pack.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _resumePack(pack, l10n, nombreProduits),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= INFORMATIONS GENERALES =================
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.local_offer_outlined,
                child: detailwrap([
                  detailinfo(l10n.name, pack.nom),
                  detailinfo(l10n.code, pack.code),
                  detailinfo(l10n.status, pack.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.totalQuantity, pack.quantiteTotale),  // NOUVEAU
                  detailinfo(l10n.price, "${pack.prixVente} ${l10n.currency}"),  // MODIFIÉ
                  detailinfo(l10n.productCount, nombreProduits),
                ]),
              ),

              // ================= OBSERVATION =================
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    pack.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              // ================= AUDIT =================
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, pack.creeParCode),
                  detailinfo(
                    l10n.createdAt,
                    pack.creeLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, pack.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    pack.modifLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, pack.annulPar),
                  detailinfo(
                    l10n.cancelledAt,
                    pack.annulLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancellationReason, pack.motifAnnul),
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
                showDialog(
                  barrierColor: Appstyle.gris.withOpacity(0.4),
                  context: context,
                  builder: (_) => _dialogListeProduitsPack(context, pack, l10n),
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

// ================= Helper Widgets =================

Widget _resumePack(Pack p, AppLocalizations l10n, int nombreProduits) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _badge(l10n.id, p.id),
        _badge(l10n.productCount, nombreProduits),
        _badge(l10n.totalQuantity, p.quantiteTotale),  // MODIFIÉ
        _badge(l10n.total, "${p.prixVente} ${l10n.currency}"),  // MODIFIÉ
      ],
    ),
  );
}

Widget _badge(String label, dynamic value) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    child: Text(
      "$label : ${value ?? "-"}",
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}

// ================= Dialogue Liste des produits du pack =================
Widget _dialogListeProduitsPack(BuildContext context, Pack pack, AppLocalizations l10n) {
  final produits = produitPackDetailsTest
      .where((p) => p.packCode == pack.code)
      .toList();

  // Calcul des totaux
  int nombreProduits = produits.length;
  int quantiteTotale = produits.fold(0, (sum, item) => sum + item.quantite);
  double montantTotal = produits.fold(0.0, (sum, item) => sum + item.montant);

  return BaseDialog(
    width: 900,
    height: 600,

    // ───────── HEADER ─────────
    header: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productsOfPack(pack.code ?? ''),
          style: Appstyle.textLB,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "${l10n.pack} : ${pack.nom}",
              style: Appstyle.textSB,
            ),
            Text(
              "${l10n.total} : ${montantTotal.toStringAsFixed(2)} ${l10n.currency}",
              style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold),
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
            mainAxisAlignment: MainAxisAlignment.spaceAround,
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
              Container(width: 1, height: 30, color: Appstyle.gris.withOpacity(0.3)),
              Column(
                children: [
                  Text(l10n.totalQuantity, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                  Text(
                    "$quantiteTotale",
                    style: Appstyle.textLB.copyWith(color: Appstyle.violet, fontSize: 16),
                  ),
                ],
              ),
              Container(width: 1, height: 30, color: Appstyle.gris.withOpacity(0.3)),
              Column(
                children: [
                  Text(l10n.total, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                  Text(
                    "${montantTotal.toStringAsFixed(2)} ${l10n.currency}",
                    style: Appstyle.textLB.copyWith(color: Appstyle.crevete, fontSize: 16),
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
                DataColumn(label: Text(l10n.unitPrice, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text(l10n.quantity, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                DataColumn(label: Text(l10n.total, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
              ],
              rows: produits.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p.produitCode, style: Appstyle.textSB)),
                    DataCell(Text(p.produitNom, style: Appstyle.textSB)),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Appstyle.violet.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${p.prixUnitaire.toStringAsFixed(2)} ${l10n.currency}",
                          style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Appstyle.crevete.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "${p.quantite}",
                          style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        "${p.montant.toStringAsFixed(2)} ${l10n.currency}",
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
}
// Ajoutez cette fonction à la fin du fichier pack_detail.dart
Future<void> showPackProductsListDialog(BuildContext context, Pack pack, AppLocalizations l10n) async {
  await _LoadAllData(pack: pack);

  final produits = produitPackDetailsTest
      .where((p) => p.packCode == pack.code)
      .toList();

  // Calcul des totaux
  int nombreProduits = produits.length;
  int quantiteTotale = produits.fold(0, (sum, item) => sum + item.quantite);
  double montantTotal = produits.fold(0.0, (sum, item) => sum + item.montant);

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.4),
    builder: (_) {
      return BaseDialog(
        width: 900,
        height: 550,

        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.productsOfPack(pack.code ?? ''),
              style: Appstyle.textLB,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "${l10n.pack} : ${pack.nom}",
                  style: Appstyle.textSB,
                ),
                Text(
                  "${l10n.total} : ${montantTotal.toStringAsFixed(2)} ${l10n.currency}",
                  style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold),
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
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
                  Container(width: 1, height: 30, color: Appstyle.gris.withOpacity(0.3)),
                  Column(
                    children: [
                      Text(l10n.totalQuantity, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                      Text(
                        "$quantiteTotale",
                        style: Appstyle.textLB.copyWith(color: Appstyle.violet, fontSize: 16),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 30, color: Appstyle.gris.withOpacity(0.3)),
                  Column(
                    children: [
                      Text(l10n.price, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
                      Text(
                        "${montantTotal.toStringAsFixed(2)} ${l10n.currency}",
                        style: Appstyle.textLB.copyWith(color: Appstyle.crevete, fontSize: 16),
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
                    DataColumn(label: Text(l10n.unitPrice, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text(l10n.quantity, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                    DataColumn(label: Text(l10n.total, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)), numeric: true),
                  ],
                  rows: produits.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.produitCode, style: Appstyle.textSB)),
                        DataCell(Text(p.produitNom, style: Appstyle.textSB)),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.violet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p.prixUnitaire.toStringAsFixed(2)} ${l10n.currency}",
                              style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.crevete.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p.quantite}",
                              style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            "${p.montant.toStringAsFixed(2)} ${l10n.currency}",
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