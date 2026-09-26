import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/sous_categorie.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import '../produits_liste_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> SousCategorieDetail(
  BuildContext context,
  SousCategorie sousCategorie, {
  int nombreProduits = 0,
}) async {
  final categories = await CategorieServices.getAllCategorie();
  final nomCategorie = categories.firstWhereOrNull((c) => c.code == sousCategorie.categorieCode)?.nom
      ?? sousCategorie.categorieCode;

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
                  "assets/icons/cardwidget/sous_catego_icon.png",
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
                      sousCategorie.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${sousCategorie.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    sousCategorie.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: sousCategorie.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: sousCategorie.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: sousCategorie.etat ? 2 : 0,
                )
              ],
            ),
            const SizedBox(height: 16),
            _resumeSousCategorie(sousCategorie, l10n, nombreProduits),
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
                  detailinfo(l10n.name, sousCategorie.nom),
                  detailinfo(l10n.code, sousCategorie.code),
                  detailinfo(l10n.status, sousCategorie.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.parentCategory, nomCategorie),
                  detailinfo(l10n.productCount, nombreProduits),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    sousCategorie.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, sousCategorie.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    sousCategorie.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, sousCategorie.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    sousCategorie.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, sousCategorie.annulParCode),
                  detailinfo(l10n.cancellationReason, sousCategorie.motifAnnul),
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
                showSousCategorieProductsListDialog(context, sousCategorie, l10n);
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

// ================= Dialogue Liste des produits de la sous-catégorie =================
// Aligné sur le style "liste des produits" utilisé par les packs
// (showPackProductsListDialog), réutilisé par SousCategorieDetail et AfficheurSousCategorie.
Future<void> showSousCategorieProductsListDialog(
    BuildContext context,
    SousCategorie sousCategorie,
    AppLocalizations l10n,
    ) async {
  final db = await DbCreator.openDb();
  final service = ProduitServices(db);
  final produits = await service.getProduitsBySousCategorieId(sousCategorie.id);
  // Quantité par produit calculée depuis le journal des mouvements — voir
  // produit_screen.dart pour le même mécanisme. Remplace Produit.quantite.
  final quantites = (await MouvementsServices.totauxParProduit()).quantites;
  double qte(Produit p) => quantites[p.code] ?? 0;

  final quantiteTotale = produits.fold(0.0, (sum, p) => sum + qte(p));
  final valeurTotale = produits.fold(0.0, (sum, p) => sum + (qte(p) * p.prixVente));

  if (!context.mounted) return;
  return ProduitsListeDialog.afficher(
    context: context,
    titre: l10n.productsOfSubCategory(sousCategorie.code ?? ''),
    sousTitre: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("${l10n.subcategory} : ${sousCategorie.nom}", style: Appstyle.textSB),
          Text(
            "${l10n.total} : ${NumberFormatUtil.formatMontant(valeurTotale, decimales: 2)} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ],
    stats: [
      StatBadge(label: l10n.productCount, valeur: "${produits.length}"),
      StatBadge(label: l10n.totalQuantity, valeur: NumberFormatUtil.formatMontant(quantiteTotale, decimales: 0)),
      StatBadge(
        label: l10n.total,
        valeur: "${NumberFormatUtil.formatMontant(valeurTotale, decimales: 2)} ${l10n.currency}",
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
          DataCell(Text(p.code, style: Appstyle.textSB)),
          DataCell(Text(p.nom, style: Appstyle.textSB)),
          DataCell(pilluleCellule("${NumberFormatUtil.formatMontant(p.prixVente, decimales: 2)} ${l10n.currency}", Appstyle.violet)),
          DataCell(pilluleCellule(NumberFormatUtil.formatMontant(qte(p), decimales: 0), Appstyle.crevete)),
          DataCell(Text(
            "${NumberFormatUtil.formatMontant((qte(p) * p.prixVente), decimales: 2)} ${l10n.currency}",
            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
          )),
        ],
      );
    }).toList(),
    messageVide: l10n.noProduct,
  );
}

// sous_categorie_detail.dart - Remplacer _resumeSousCategorie
Widget _resumeSousCategorie(SousCategorie sc, AppLocalizations l10n, int nombreProduits) {
  return StatsCard(
    items: [
      StatsItem(label: l10n.code, value: sc.code),
      StatsItem(label: l10n.productCount, value: nombreProduits),
      StatsItem(label: l10n.categorie, value: sc.categorieCode ),
    ],
  );
}