import 'package:collection/collection.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/transfert_magasin.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/magasin.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> TransfertMagasinDetail(
    BuildContext context,
    TransfertMagasin transfert, {
      required List<Produit> produits,
      required List<Magasin> magasins,
    }) async {
  final nomProduit = produits.firstWhereOrNull((p) => p.code == transfert.produitCode)?.nom
      ?? transfert.produitCode;
  final nomSource = magasins.firstWhereOrNull((m) => m.code == transfert.magasinSourceCode)?.nom
      ?? transfert.magasinSourceCode;
  final nomDest = magasins.firstWhereOrNull((m) => m.code == transfert.magasinDestCode)?.nom
      ?? transfert.magasinDestCode;

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
                  "assets/icons/cardwidget/transfert_icon.png",
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
                      "${l10n.code}: ${transfert.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    transfert.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: transfert.etat ? Appstyle.Tblanc : Appstyle.Tnoir,
                    ),
                  ),
                  backgroundColor: transfert.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: transfert.etat ? 2 : 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _resumeTransfert(transfert, l10n),
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
                  detailinfo(l10n.source, nomSource),
                  detailinfo(l10n.destination, nomDest),
                  detailinfo(l10n.transferDate, transfert.date.toString().split(" ").first),
                  detailinfo(l10n.status, transfert.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, nomProduit),
                  detailinfo(l10n.quantity, transfert.quantite),
                  detailinfo(l10n.numberField, transfert.nombre),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    transfert.observation?.isNotEmpty == true
                        ? transfert.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, transfert.creeParCode),
                  detailinfo(l10n.dateCreated, transfert.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, transfert.modifParCode),
                  detailinfo(l10n.modifiedAt, transfert.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, transfert.annulParCode),
                  detailinfo(l10n.cancellationReason, transfert.motifAnnul),
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
                borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

Widget _resumeTransfert(TransfertMagasin t, AppLocalizations l10n) {
  return StatsCard(
    items: [
      StatsItem(label: l10n.quantity, value: t.quantite),
      StatsItem(label: l10n.transferDate, value: t.date.toString().split(" ").first),
      StatsItem(label: l10n.code, value: t.code),
    ],
  );
}
