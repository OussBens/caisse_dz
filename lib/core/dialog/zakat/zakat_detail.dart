import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/zakat.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

Future<void> ZakatDetail(BuildContext context, Zakat zakat) async {
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
                  "assets/icons/sidebar/zakat_icon.png",
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
                      zakat.code,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.year}: ${zakat.annee}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    zakat.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: zakat.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: zakat.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: zakat.etat ? 2 : 0,
                )
              ],
            ),

            const SizedBox(height: 16),

            _resumeZakat(zakat, l10n),
          ],
        ),

        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionDecoration(
                title: l10n.financialData,
                icon: Icons.account_balance_wallet_outlined,
                child: detailwrap([
                  detailinfo(l10n.code, zakat.code),
                  detailinfo(l10n.stock, "${zakat.stock} ${l10n.currency}"),
                  detailinfo(l10n.liquidities, "${zakat.liquidites} ${l10n.currency}"),
                  detailinfo(l10n.receivables, "${zakat.creances} ${l10n.currency}"),
                  detailinfo(l10n.debts, "${zakat.dettes} ${l10n.currency}"),
                  detailinfo(l10n.totalCapital, "${zakat.capitalTotal} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.rulesZakat,
                icon: Icons.rule_folder_outlined,
                child: detailwrap([
                  detailinfo(l10n.nissab, "${zakat.nissab} ${l10n.currency}"),
                  detailinfo(l10n.rate, "${zakat.taux} %"),
                  detailinfo(l10n.zakatAmount, "${zakat.montantZakat} ${l10n.currency}"),
                  detailinfo(l10n.mandatory, zakat.obligatoire ? l10n.yes : l10n.no),
                  detailinfo(l10n.status, zakat.statut),
                ]),
              ),

              SectionDecoration(
                title: l10n.hawlDueDate,
                icon: Icons.event_available_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.hawlStart,
                    zakat.dateDebutHawl?.toString().split(" ").first ?? "-",
                  ),
                  detailinfo(
                    l10n.zakatDueDate,
                    zakat.dateZakatDue?.toString().split(" ").first ?? "-",
                  ),
                  detailinfo(
                    l10n.paymentDate,
                    zakat.datePaiement?.toString().split(" ").first ?? "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    zakat.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, zakat.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    zakat.dateCree?.toString().split(" ").first ?? "-",
                  ),
                  detailinfo(l10n.modifiedBy, zakat.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    zakat.dateModif?.toString().split(" ").first ?? "-",
                  ),
                  detailinfo(l10n.cancelledBy, zakat.annulParCode),
                  detailinfo(l10n.cancellationReason, zakat.motifAnnul),
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

Widget _resumeZakat(Zakat z, AppLocalizations l10n) {
  return Column(
    children: [
      StatsCard(
        items: [
          StatsItem(label: l10n.stock, value: "${z.stock} ${l10n.currency}", icon: Icons.inventory_2_outlined),
          StatsItem(label: l10n.liquidities, value: "${z.liquidites} ${l10n.currency}", icon: Icons.account_balance_wallet_outlined),
          StatsItem(label: l10n.receivables, value: "${z.creances} ${l10n.currency}", icon: Icons.call_received),
        ],
      ),
      const SizedBox(height: 8),
      StatsCard(
        backgroundColor: Appstyle.crevete,
        items: [
          StatsItem(label: l10n.debts, value: "${z.dettes} ${l10n.currency}", icon: Icons.call_made),
          StatsItem(label: l10n.totalCapital, value: "${z.capitalTotal} ${l10n.currency}", icon: Icons.account_balance_outlined),
          StatsItem(label: l10n.zakatAmount, value: "${z.montantZakat} ${l10n.currency}", icon: Icons.volunteer_activism_outlined),
        ],
      ),
    ],
  );
}
