import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/verssement.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> VersementDetail(BuildContext context, Verssement versement) async {
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
                  "assets/icons/devise_icon.png",
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
                      l10n.payment,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${versement.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    versement.etat ? l10n.validated : l10n.cancelled,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor:
                  versement.etat == true ? Appstyle.violet : Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeVersement(versement, l10n),
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
                  detailinfo(l10n.type, versement.typebeneficiare),
                  detailinfo(l10n.beneficiary, versement.beneficiare),
                  detailinfo(l10n.status, versement.etat ? l10n.validated : l10n.cancelled),
                  detailinfo(l10n.date, versement.date),
                  detailinfo(l10n.sense, versement.sense),
                  detailinfo(l10n.cashRegister, versement.caisse),
                ]),
              ),

              SectionDecoration(
                title: l10n.amount,
                icon: Icons.attach_money_outlined,
                child: detailwrap([
                  detailinfo(l10n.amount, "${versement.montant} ${l10n.currency}"),
                  detailinfo(l10n.paymentMethod, "${versement.mode_paiement}"),
                  detailinfo(l10n.paymentType, "${versement.type}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    versement.observation?.isNotEmpty == true
                        ? versement.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, versement.creePar),
                  detailinfo(l10n.dateCreated, versement.dateCree),
                  detailinfo(l10n.modifiedBy, versement.modifPar),
                  detailinfo(l10n.modifiedAt, versement.dateModif),
                  detailinfo(l10n.cancelledBy, versement.annulPar),
                  detailinfo(l10n.cancellationReason, versement.motifAnnul),
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

Widget _resumeVersement(Verssement r, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.amount, r.montant),
        detailbadge(l10n.type, "${r.typebeneficiare} "),
        detailbadge(l10n.beneficiary, "${r.beneficiare} "),
        detailbadge(l10n.paymentMethod, r.mode_paiement),
      ],
    ),
  );
}