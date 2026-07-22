import 'package:caisse_dz/data/constant.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/retour.dart';
import '../../widget/detail_widget.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> RetourDetail(BuildContext context, Retour retour) async {
  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;
      final translator = ListsConstTranslator(l10n);

      return BaseDialog(
        width: 900,
        height: 600,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/retour_icon.png",
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
                      retour.nomProduit ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${retour.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    retour.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeRetour(retour, l10n),
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
                  detailinfo(l10n.type, translator.translateTypeRetour(retour.type)),
                  detailinfo(l10n.client, retour.client),
                  detailinfo(l10n.supplier, retour.fournisseur),
                  detailinfo(l10n.status, retour.etat ? l10n.active : l10n.inactive),
                ]),
              ),
              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, retour.nomProduit),
                  detailinfo(l10n.quantity, retour.quantite),
                  detailinfo(l10n.purchasePrice, "${retour.prixAchat ?? 0} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${retour.prixVente ?? 0} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    retour.observation?.isNotEmpty == true
                        ? retour.observation
                        : "-",
                  ),
                ]),
              ),
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, retour.creeParCode),
                  detailinfo(l10n.dateCreated, (retour.dateCree)),
                  detailinfo(l10n.modifiedBy, retour.modifPar),
                  detailinfo(l10n.modifiedAt, (retour.dateModif)),
                  detailinfo(l10n.cancelledBy, retour.annulPar),
                  detailinfo(l10n.cancellationReason, retour.motifAnnul),
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

Widget _resumeRetour(Retour r, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.quantity, r.quantite ?? 0),
        detailbadge(l10n.purchasePrice, "${r.prixAchat ?? 0} ${l10n.currency}"),
        detailbadge(l10n.salePrice, "${r.prixVente ?? 0} ${l10n.currency}"),
        detailbadge(l10n.type, r.type ?? "-"),
      ],
    ),
  );
}