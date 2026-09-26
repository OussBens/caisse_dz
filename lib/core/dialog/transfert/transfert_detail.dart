import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../data/models/transfert.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> TransfertCaisseDetail(
    BuildContext context,
    TransfertCaisse transfert,
    ) async {
  final caisses = await GCServices.getAllCaisses();
  final nomCaisseExp = caisses.firstWhereOrNull((c) => c.code == transfert.caisseExpCode)?.nomCaisse
      ?? transfert.caisseExpCode;
  final nomCaisseDest = caisses.firstWhereOrNull((c) => c.code == transfert.caisseDestCode)?.nomCaisse
      ?? transfert.caisseDestCode;

  if (!context.mounted) return;
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
                      transfert.code,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.date}: ${transfert.dateTransfert.toString().split(" ").first}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    transfert.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: transfert.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: transfert.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: transfert.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeTransfert(transfert, l10n, nomCaisseExp, nomCaisseDest),
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
                  detailinfo(l10n.code, transfert.code),
                  detailinfo(l10n.transferDate, transfert.dateTransfert.toString().split(" ").first),
                  detailinfo(l10n.sourceCashRegister, nomCaisseExp),
                  detailinfo(l10n.destinationCashRegister, nomCaisseDest),
                  detailinfo(l10n.status, transfert.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.financialInformation,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.amount, "${NumberFormatUtil.formatMontant(transfert.montant, decimales: 2)} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    transfert.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, transfert.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    transfert.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, transfert.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    transfert.dateModif?.toString().split(" ").first,
                  ),
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

// transfert_caisse_detail.dart - Remplacer _resumeTransfert
Widget _resumeTransfert(TransfertCaisse t, AppLocalizations l10n, String nomCaisseExp, String nomCaisseDest) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(label: l10n.amount, value: "${NumberFormatUtil.formatMontant(t.montant, decimales: 2)} ${l10n.currency}"),
      StatsItem(label: l10n.sourceCashRegister, value: nomCaisseExp),
      StatsItem(label: l10n.destinationCashRegister, value: nomCaisseDest),
      StatsItem(label: l10n.status, value: t.etat ? l10n.active : l10n.inactive),
    ],
  );
}