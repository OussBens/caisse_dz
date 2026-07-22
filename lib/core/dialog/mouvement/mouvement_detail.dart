import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/mouvement.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> MouvementDetail(BuildContext context, Mouvement mouvement) async {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width   : 900,
        height  : 600,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/mouvement_icon.png",
                  width           : 34,
                  height          : 34,
                  color           : Appstyle.violet,
                  colorBlendMode  : BlendMode.srcIn,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment  : CrossAxisAlignment.start,
                  children: [
                    Text(
                      mouvement.nomProduit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${mouvement.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    mouvement.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeMouvement(mouvement, l10n),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.info_outline,
                child: detailwrap([
                  detailinfo(l10n.type, _getTranslatedType(mouvement.type, l10n)),
                  detailinfo(l10n.client, mouvement.client),
                  detailinfo(l10n.supplier, mouvement.fournisseur),
                  detailinfo(l10n.status, mouvement.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.date, _formatDate(mouvement.date)),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, mouvement.nomProduit),
                  detailinfo(l10n.quantity, mouvement.quantite.toString()),
                  detailinfo(l10n.purchasePrice, "${mouvement.prixAchat} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${mouvement.prixVente} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, mouvement.creePar),
                  detailinfo(l10n.createdAt, _formatDate(mouvement.dateCree)),
                  detailinfo(l10n.modifiedBy, mouvement.modifPar),
                  detailinfo(l10n.modifiedAt, _formatDate(mouvement.dateModif)),
                  detailinfo(l10n.cancelledBy, mouvement.annulPar),
                  detailinfo(l10n.cancellationReason, mouvement.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        // ================= FOOTER =================
        footer: Align(
          alignment : Alignment.centerRight,
          child     : ElevatedButton.icon(
            icon  : const Icon(Icons.close),
            label : Text(l10n.close),
            style : ElevatedButton.styleFrom(
              backgroundColor : Appstyle.violet,
              foregroundColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius  : BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return "-";
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

String _getTranslatedType(String type, AppLocalizations l10n) {
  switch (type) {
    case "Vente":
      return l10n.sale;
    case "Achat":
      return l10n.purchase;
    case "Retour":
      return l10n.return_;
    case "Déstockage":
      return l10n.destocking;
    default:
      return type;
  }
}

Widget _resumeMouvement(Mouvement m, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.quantity, m.quantite.toString()),
        detailbadge(l10n.purchasePrice, "${m.prixAchat} ${l10n.currency}"),
        detailbadge(l10n.salePrice, "${m.prixVente} ${l10n.currency}"),
        detailbadge(l10n.type, _getTranslatedType(m.type, l10n)),
      ],
    ),
  );
}