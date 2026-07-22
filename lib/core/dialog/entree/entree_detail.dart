import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/entree.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> EntreeDetail(BuildContext context, Entree entree) async {
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
                  "assets/icons/cardwidget/entree_icon.png",
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
                      entree.produit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${entree.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    entree.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: Appstyle.Tblanc,
                    ),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeEntree(entree, l10n),
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
                  detailinfo(l10n.code, entree.code),
                  detailinfo(l10n.date, entree.date),
                  detailinfo(l10n.status, entree.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.inventory_2_outlined,
                child: detailwrap([
                  detailinfo(l10n.productName, entree.produit),
                  detailinfo(l10n.productCode, entree.produitcode),
                  detailinfo(l10n.quantity, entree.quantite),
                  detailinfo(l10n.unitPrice, "${entree.prix.toStringAsFixed(2)} ${l10n.currency}"),
                  detailinfo(l10n.amount, "${entree.montant.toStringAsFixed(2)} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.supplier,
                icon: Icons.local_shipping_outlined,
                child: detailwrap([
                  detailinfo(l10n.supplier, entree.fournisseur),
                  detailinfo(l10n.supplierCode, entree.fournisseurCode),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    entree.observation?.isNotEmpty == true
                        ? entree.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, entree.creeParCode),
                  detailinfo(l10n.dateCreated, entree.dateCree),
                  detailinfo(l10n.modifiedBy, entree.modifParCode),
                  detailinfo(l10n.modifiedAt, entree.dateModif),
                  detailinfo(l10n.cancelledBy, entree.annulParCode),
                  detailinfo(l10n.cancellationReason, entree.motifAnnul),
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

Widget _resumeEntree(Entree e, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.quantity, e.quantite),
        detailbadge(l10n.price, "${e.prix.toStringAsFixed(2)} ${l10n.currency}"),
        detailbadge(l10n.amount, "${e.montant.toStringAsFixed(2)} ${l10n.currency}"),
        detailbadge(l10n.supplier, e.fournisseur),
      ],
    ),
  );
}