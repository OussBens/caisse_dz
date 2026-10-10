import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/verssement.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> VersementDetail(BuildContext context, Verssement versement) async {
  final clients = await ClientServices.getAllClients();
  final fournisseurs = await FournisseurServices.getAllFournisseurs();
  final nomBeneficiaire = versement.typebeneficiare == "Client"
      ? (clients.firstWhereOrNull((c) => c.code == versement.beneficiareCode)?.nom ?? versement.beneficiareCode)
      : (fournisseurs.firstWhereOrNull((f) => f.code == versement.beneficiareCode)?.nom ?? versement.beneficiareCode);

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
                    versement.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: versement.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: versement.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: versement.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeVersement(versement, nomBeneficiaire, l10n),
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
                  detailinfo(l10n.beneficiary, nomBeneficiaire),
                  detailinfo(l10n.status, versement.etat ? l10n.validated : l10n.cancelled),
                  detailinfo(l10n.date, versement.date),
                  detailinfo(l10n.sense, versement.sense),
                  detailinfo(l10n.cashRegister, versement.caisse),
                  detailinfo(l10n.operationCode, versement.codeOperation),
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
                  detailinfo(l10n.createdBy, versement.creeParCode),
                  detailinfo(l10n.dateCreated, versement.dateCree),
                  detailinfo(l10n.modifiedBy, versement.modifParCode),
                  detailinfo(l10n.modifiedAt, versement.dateModif),
                  detailinfo(l10n.cancelledBy, versement.annulParCode),
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

// versement_detail.dart - Remplacer _resumeVersement
Widget _resumeVersement(Verssement r, String nomBeneficiaire, AppLocalizations l10n) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(label: l10n.amount, value: "${r.montant} ${l10n.currency}"),
      StatsItem(label: l10n.type, value: r.typebeneficiare),
      StatsItem(label: l10n.beneficiary, value: nomBeneficiaire),
      StatsItem(label: l10n.paymentMethod, value: r.mode_paiement),
    ],
  );
}