import 'package:caisse_dz/core/dialog/cloture_caisse/cloture_caisse_pdf.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'dart:convert';

import '../../../data/models/cloture_caisse.dart';
import '../../../data/models/gestion_caisse.dart';
import '../../../data/models/utilisateur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> ClotureCaisseDetail(
  BuildContext context,
  ClotureCaisse cloture, {
  List<CaisseGestion> caisses = const [],
  List<Utilisateur> utilisateurs = const [],
}) async {
  final nomCaisse = caisses.firstWhereOrNull((c) => c.code == cloture.caisseCode)?.nomCaisse ?? cloture.caisseCode;
  final nomUtilisateur = utilisateurs.firstWhereOrNull((u) => u.code == cloture.utilisateurCode)?.username ?? cloture.utilisateurCode;
  final repartition = cloture.repartitionPaiement != null
      ? (jsonDecode(cloture.repartitionPaiement!) as Map<String, dynamic>)
      : <String, dynamic>{};

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      final l10n = AppLocalizations.of(context)!;

      return BaseDialog(
        width: 1100,
        height: 700,
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/reporting_icon.png",
                  width: 34,
                  height: 34,
                  color: Appstyle.violet,
                  colorBlendMode: BlendMode.srcIn,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cloture.code, style: Appstyle.textLB.copyWith(fontSize: 20)),
                    Text("${l10n.cashRegister} : $nomCaisse", style: Appstyle.textSB),
                  ],
                ),
                const Spacer(),
                // Période couverte par la clôture (une clôture n'a pas d'état :
                // elle n'est jamais modifiée ni annulée).
                Chip(
                  label: Text(
                    "${cloture.dateDebut.toString().split(" ").first} → ${cloture.dateFin.toString().split(" ").first}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.violet.withOpacity(0.8),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: 2,
                ),
              ],
            ),
            const SizedBox(height: 16),
            StatsCard(
              items: [
                StatsItem(
                  label: l10n.totalAmount,
                  value: "${NumberFormatUtil.formatMontant(cloture.totalVentes, decimales: 2)} ${l10n.currency}",
                  icon: Icons.payments_outlined,
                ),
                StatsItem(label: l10n.numberOfSales, value: cloture.nombreTickets.toString(), icon: Icons.receipt_long),
                StatsItem(
                  label: l10n.totalCancelledAmount,
                  value: "${NumberFormatUtil.formatMontant(cloture.totalAnnule, decimales: 2)} ${l10n.currency}",
                  icon: Icons.money_off_outlined,
                ),
                StatsItem(label: l10n.cancelledTicketsCount, value: cloture.nombreTicketsAnnules.toString(), icon: Icons.cancel_outlined),
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
                  detailinfo(l10n.code, cloture.code),
                  detailinfo(l10n.cashRegister, nomCaisse),
                  detailinfo(l10n.from, cloture.dateDebut.toString().split(" ").first),
                  detailinfo(l10n.to, cloture.dateFin.toString().split(" ").first),
                  detailinfo(l10n.createdBy, nomUtilisateur),
                  detailinfo(l10n.createdAt, cloture.dateCree.toString().split(" ").first),
                ]),
              ),
              SectionDecoration(
                title: l10n.financialInformation,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.totalAmount, "${NumberFormatUtil.formatMontant(cloture.totalVentes, decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.numberOfSales, cloture.nombreTickets.toString()),
                  detailinfo(l10n.totalCancelledAmount, "${NumberFormatUtil.formatMontant(cloture.totalAnnule, decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.cancelledTicketsCount, cloture.nombreTicketsAnnules.toString()),
                ]),
              ),
              SectionDecoration(
                title: l10n.paymentMethodBreakdown,
                icon: Icons.pie_chart_outline,
                child: repartition.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text("-", style: Appstyle.textSB),
                      )
                    : detailwrap([
                        for (final entry in repartition.entries)
                          detailinfo(entry.key, "${NumberFormatUtil.formatMontant((entry.value as num).toDouble(), decimales: 2)} ${l10n.currency}"),
                      ]),
              ),
              SectionDecoration(
                title: l10n.fiscalHash,
                icon: Icons.lock_outline,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: SelectableText(cloture.hash, style: Appstyle.textXS),
                ),
              ),
            ],
          ),
        ),
        footer: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: Text(l10n.print),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.gris,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => genererEtAfficherRapportZ(context, l10n, cloture, nomCaisse),
            ),
            const SizedBox(width: 10),
            ElevatedButton.icon(
              icon: const Icon(Icons.close),
              label: Text(l10n.close),
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.violet,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    },
  );
}
