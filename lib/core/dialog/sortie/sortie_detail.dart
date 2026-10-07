
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/sortie.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/categorie.dart';
import '../../../data/models/sous_categorie.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> SortieDetail(
    BuildContext context,
    Sortie sortie, {
      required List<Produit> produits,
      required List<Categorie> categories,
      required List<SousCategorie> sousCategories,
    }) async {
  final nomProduit = produits.where((p) => p.code == sortie.produitCode).firstOrNull?.nom
      ?? sortie.produitCode;
  final nomCategorie = sortie.categorieCode == null
      ? null
      : categories.where((c) => c.code == sortie.categorieCode).firstOrNull?.nom ?? sortie.categorieCode;
  final nomSousCategorie = sortie.sousCategorieCode == null
      ? null
      : sousCategories.where((sc) => sc.code == sortie.sousCategorieCode).firstOrNull?.nom ?? sortie.sousCategorieCode;

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
                  "assets/icons/cardwidget/sortie_icon.png",
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
                      nomProduit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${sortie.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    sortie.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: sortie.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: sortie.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: sortie.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeSortie(sortie, l10n),
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
                  detailinfo(l10n.type, sortie.type),
                  detailinfo(l10n.category, nomCategorie),
                  detailinfo(l10n.subcategory, nomSousCategorie),
                  detailinfo(l10n.status, sortie.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, nomProduit),
                  detailinfo(l10n.quantity, sortie.quantite),
                  detailinfo(l10n.numberField, sortie.nombre),
                  detailinfo(l10n.unitPrice, "${NumberFormatUtil.formatMontant(sortie.prix, decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.amount, "${NumberFormatUtil.formatMontant(sortie.montant, decimales: 2)} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    sortie.observation?.isNotEmpty == true
                        ? sortie.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, sortie.creeParCode),
                  detailinfo(l10n.dateCreated, sortie.dateCree),
                  detailinfo(l10n.modifiedBy, sortie.modifParCode),
                  detailinfo(l10n.modifiedAt, sortie.dateModif),
                  detailinfo(l10n.cancelledBy, sortie.annulParCode),
                  detailinfo(l10n.cancellationReason, sortie.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
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
        ),
      );
    },
  );
}

// sortie_detail.dart - Remplacer _resumeSortie
Widget _resumeSortie(Sortie s, AppLocalizations l10n) {
  return StatsCard(
    items: [
      StatsItem(label: l10n.quantity, value: s.quantite),
      StatsItem(label: l10n.price, value: "${NumberFormatUtil.formatMontant(s.prix, decimales: 2)} ${l10n.currency}"),
      StatsItem(label: l10n.amount, value: "${NumberFormatUtil.formatMontant(s.montant, decimales: 2)} ${l10n.currency}"),
      StatsItem(label: l10n.type, value: s.type),
    ],
  );
}