import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/pack.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import '../produits_liste_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<ProduitPackDetail> produitPackDetailsTest = [];
List<Produit> produitsTest = [];

Future<void> _LoadAllData({required Pack pack}) async {
  final result = await ProduitPackDetailServices.getDetailsByPackNom(pack.code);
  produitPackDetailsTest = result;
  produitsTest = await ProduitServices.getAllProduits();
}

String _nomProduit(String code) =>
    produitsTest.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

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
                    style: Appstyle.textSB.copyWith(
                      color: pack.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: pack.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: pack.etat ? 2 : 0,
                )
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
                  detailinfo(l10n.modifiedBy, pack.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    pack.modifLe?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, pack.annulParCode),
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
              label: Text(l10n.productList),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.crevete,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                showPackProductsListDialog(context, pack, l10n);
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

// pack_detail.dart - Remplacer _resumePack
Widget _resumePack(Pack p, AppLocalizations l10n, int nombreProduits) {
  return StatsCard(
    items: [
      StatsItem(label: l10n.code, value: p.code),
      StatsItem(label: l10n.productCount, value: nombreProduits),
      StatsItem(label: l10n.totalQuantity, value: p.quantiteTotale),
      StatsItem(label: l10n.total, value: "${p.prixVente} ${l10n.currency}"),
    ],
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
Future<void> showPackProductsListDialog(BuildContext context, Pack pack, AppLocalizations l10n) async {
  await _LoadAllData(pack: pack);

  final produits = produitPackDetailsTest
      .where((p) => p.packCode == pack.code)
      .toList();

  final quantiteTotale = produits.fold(0, (sum, item) => sum + item.quantite);
  final montantTotal = produits.fold(0.0, (sum, item) => sum + item.montant);

  return ProduitsListeDialog.afficher(
    context: context,
    titre: l10n.productsOfPack(pack.code ?? ''),
    sousTitre: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${l10n.pack} : ${pack.nom}", style: Appstyle.textSB),
          Text(
            "${l10n.total} : ${NumberFormatUtil.formatMontant(montantTotal, decimales: 2)} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
    stats: [
      StatBadge(label: l10n.numberOfItems, valeur: "${produits.length}"),
      StatBadge(label: l10n.totalQuantity, valeur: "$quantiteTotale"),
      StatBadge(
        label: l10n.total,
        valeur: "${NumberFormatUtil.formatMontant(montantTotal, decimales: 2)} ${l10n.currency}",
        couleur: Appstyle.crevete,
      ),
    ],
    colonnes: [
      DataColumn(label: Text(l10n.productCode)),
      DataColumn(label: Text(l10n.productName)),
      DataColumn(label: Text(l10n.unitPrice), numeric: true),
      DataColumn(label: Text(l10n.quantity), numeric: true),
      DataColumn(label: Text(l10n.total), numeric: true),
    ],
    lignes: produits.map((p) {
      return DataRow(
        cells: [
          DataCell(Text(p.produitCode, style: Appstyle.textSB)),
          DataCell(Text(_nomProduit(p.produitCode), style: Appstyle.textSB)),
          DataCell(pilluleCellule("${NumberFormatUtil.formatMontant(p.prixUnitaire, decimales: 2)} ${l10n.currency}", Appstyle.violet)),
          DataCell(pilluleCellule("${p.quantite}", Appstyle.crevete)),
          DataCell(Text(
            "${NumberFormatUtil.formatMontant(p.montant, decimales: 2)} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
          )),
        ],
      );
    }).toList(),
    messageVide: l10n.noProductsAssociated,
  );
}