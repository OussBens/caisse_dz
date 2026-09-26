import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/client.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> ClientDetail(BuildContext context, Client client) async {
  final stats = await ClientServices.getClientStats(client);

  if (!context.mounted) return;
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 1100,
        height: 700,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/sidebar/client_icon.png",
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
                      client.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${client.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    client.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: client.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: client.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: client.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeClient(client, l10n, stats),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= INFORMATIONS GENERALES =================
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.info_outline,
                child: detailwrap([
                  detailinfo(l10n.phone, client.telephone),
                  detailinfo(l10n.clientType, client.type),
                  detailinfo(l10n.activity, client.activity),
                  detailinfo(l10n.status, client.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              // ================= CONTACT =================
              SectionDecoration(
                title: l10n.contact,
                icon: Icons.contact_phone_outlined,
                child: detailwrap([
                  detailinfo(l10n.email, client.email),
                  detailinfo(l10n.fax, client.fax),
                ]),
              ),

              // ================= ADRESSE =================
              SectionDecoration(
                title: l10n.addressInfo,
                icon: Icons.location_on_outlined,
                child: detailwrap([
                  detailinfo(l10n.wilaya, client.wilaya),
                  detailinfo(l10n.address, client.adresse),
                ]),
              ),

              // ================= INFORMATIONS FINANCIERES =================
              SectionDecoration(
                title: l10n.financialInformation,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.totalAchat, stats.totalAchat),
                  detailinfo(l10n.numberOfPurchases, stats.nbrAchat),
                  detailinfo(l10n.totalPaid, stats.totalVerse),
                  detailinfo(l10n.numberOfPayments, stats.nbrVersement),
                  detailinfo(l10n.nbReturn, stats.nbrRetour),
                  detailinfo(l10n.totalReturn, stats.totalRetour),
                  detailinfo(l10n.lastPurchaseDate, stats.dateDernierAchat?.toString().split(" ").first),
                  detailinfo(l10n.advance, stats.avance),
                  detailinfo(l10n.credit, stats.credit),
                  detailinfo(l10n.balance, stats.solde),
                  detailinfo(l10n.loyaltyBalance, client.soldeBonus),
                ]),
              ),

              // ================= INFORMATIONS ADMINISTRATIVES =================
              SectionDecoration(
                title: l10n.administrativeInformation,
                icon: Icons.badge_outlined,
                child: detailwrap([
                  detailinfo("NIF", client.nif),
                  detailinfo("NIS", client.nis),
                  detailinfo("NRC", client.nrc),
                ]),
              ),

              // ================= COORDONNEES BANCAIRES =================
              SectionDecoration(
                title: l10n.bankingInformation,
                icon: Icons.account_balance_outlined,
                child: detailwrap([
                  detailinfo(l10n.bank, client.banque),
                  detailinfo(l10n.rib, client.rib),
                ]),
              ),

              // ================= OBSERVATION =================
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    client.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              // ================= AUDIT =================
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, client.creeParCode),
                  detailinfo(
                    l10n.createdAt,
                    client.dateCree.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, client.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    client.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, client.annulParCode),
                  detailinfo(l10n.cancellationReason, client.motifAnnul),
                ]),
              ),

            ],
          ),
        ),

        // ================= FOOTER =================
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
// Dans client_detail.dart
Widget _resumeClient(Client c, AppLocalizations l10n, ClientStats stats) {
  return Column(
    children: [
      StatsCard(
        items: [
          StatsItem(
            label: l10n.totalAchat,
            value: "${stats.totalAchat} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.totalPaid,
            value: "${stats.totalVerse} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.totalReturn,
            value: "${stats.totalRetour} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.lastPurchaseDate,
            value: stats.dateDernierAchat?.toString().split(" ").first ?? "-",
          ),

        ],
      ),
      const SizedBox(height: 8),
      StatsCard(
        items: [

          StatsItem(
            label: l10n.advance,
            value: "${stats.avance} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.credit,
            value: "${stats.credit} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.balance,
            value: "${stats.solde} ${l10n.currency}",
          ),
          StatsItem(
            label: l10n.telephonie,
            value: c.telephone,
          ),
        ],
      ),
    ],
  );
}