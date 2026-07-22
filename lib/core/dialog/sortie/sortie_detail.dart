
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/sortie.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> SortieDetail(BuildContext context, Sortie sortie) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
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
                      sortie.produit,
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
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
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
                  detailinfo(l10n.category, sortie.categorie),
                  detailinfo(l10n.subcategory, sortie.souscategorie),
                  detailinfo(l10n.status, sortie.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, sortie.produit),
                  detailinfo(l10n.quantity, sortie.quantite),
                  detailinfo(l10n.unitPrice, "${sortie.prix.toStringAsFixed(2)} ${l10n.currency}"),
                  detailinfo(l10n.amount, "${sortie.montant.toStringAsFixed(2)} ${l10n.currency}"),
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
                  detailinfo(l10n.modifiedBy, sortie.modifPar),
                  detailinfo(l10n.modifiedAt, sortie.dateModif),
                  detailinfo(l10n.cancelledBy, sortie.annulPar),
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

Widget _resumeSortie(Sortie s, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.quantity, s.quantite),
        detailbadge(l10n.price, "${s.prix.toStringAsFixed(2)} ${l10n.currency}"),
        detailbadge(l10n.amount, "${s.montant.toStringAsFixed(2)} ${l10n.currency}"),
        detailbadge(l10n.type, s.type),
      ],
    ),
  );
}