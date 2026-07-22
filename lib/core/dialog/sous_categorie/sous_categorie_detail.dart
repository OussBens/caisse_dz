import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/sous_categorie.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> SousCategorieDetail(
  BuildContext context,
  SousCategorie sousCategorie, {
  int nombreProduits = 0,
}) async {
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
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
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
                  detailinfo(l10n.parentCategory, sousCategorie.categorieNom),
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
                  detailinfo(l10n.cancelledBy, sousCategorie.annulPar),
                  detailinfo(l10n.cancellationReason, sousCategorie.motifAnnul),
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

Widget _resumeSousCategorie(SousCategorie sc, AppLocalizations l10n, int nombreProduits) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge("ID", sc.id),
        detailbadge(l10n.productCount, nombreProduits),
        detailbadge(l10n.status, sc.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}