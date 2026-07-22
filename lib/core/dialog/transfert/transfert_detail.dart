import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../data/models/transfert.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> TransfertCaisseDetail(
    BuildContext context,
    TransfertCaisse transfert,
    ) async {
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
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor:
                  transfert.etat ? Appstyle.crevete : Appstyle.gris,
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
                  detailinfo(l10n.code, transfert.code),
                  detailinfo(l10n.transferDate, transfert.dateTransfert.toString().split(" ").first),
                  detailinfo(l10n.sourceCashRegister, transfert.caisseExp),
                  detailinfo(l10n.destinationCashRegister, transfert.caisseDest),
                  detailinfo(l10n.status, transfert.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.financialInformation,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.amount, "${transfert.montant.toStringAsFixed(2)} ${l10n.currency}"),
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
                  detailinfo(l10n.createdBy, transfert.creePar),
                  detailinfo(
                    l10n.dateCreated,
                    transfert.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, transfert.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    transfert.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, transfert.annulPar),
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

Widget _resumeTransfert(TransfertCaisse t, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.amount, "${t.montant.toStringAsFixed(2)} ${l10n.currency}"),
        detailbadge(l10n.sourceCashRegister, t.caisseExp),
        detailbadge(l10n.destinationCashRegister, t.caisseDest),
        detailbadge(l10n.status, t.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}