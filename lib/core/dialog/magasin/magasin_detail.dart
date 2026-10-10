import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/magasin.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../../utilis/number_format.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import '../base_dialog.dart';

Future<void> MagasinDetail(BuildContext context, Magasin magasin) async {
  final stats = await MagasinServices.getStatistiquesMagasin(magasin.code);

  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 1100,
        height: 640,

        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/magasin_icon.png",
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
                      magasin.nom,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${magasin.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),
                const Spacer(),
                Chip(
                  label: Text(
                    magasin.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: magasin.etat ? Appstyle.Tblanc : Appstyle.Tnoir,
                    ),
                  ),
                  backgroundColor: magasin.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: magasin.etat ? 2 : 0,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatsCard(
              items: [
                StatsItem(label: l10n.productCount, value: stats.produitsEnStock, icon: Icons.inventory_2_outlined),
                StatsItem(
                  label: l10n.stockValue,
                  value: "${NumberFormatUtil.formatMontant(stats.valeurStock)} ${l10n.currency}",
                  icon: Icons.payments_outlined,
                ),
                StatsItem(label: l10n.users, value: stats.utilisateurs, icon: Icons.people_outline),
                StatsItem(label: l10n.transfers, value: stats.transferts, icon: Icons.swap_horiz),
              ],
            ),
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
                  detailinfo(l10n.address, magasin.adresse),
                  detailinfo(l10n.status, magasin.etat ? l10n.active : l10n.inactive),
                ]),
              ),
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    magasin.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, magasin.creeParCode),
                  detailinfo(l10n.createdAt, magasin.dateCree.toString().split(" ").first),
                  detailinfo(l10n.modifiedBy, magasin.modifParCode),
                  detailinfo(l10n.modifiedAt, magasin.dateModif?.toString().split(" ").first),
                  detailinfo(l10n.cancelledBy, magasin.annulParCode),
                  detailinfo(l10n.cancellationReason, magasin.motifAnnul),
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
