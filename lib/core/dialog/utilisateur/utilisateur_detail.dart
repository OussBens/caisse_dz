import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/utilisateur.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> UtilisateurDetail(BuildContext context, Utilisateur user) async {
  final panniers = await PannierServices.getPanniersActifsByCaissierCode(user.code);
  final int nbrVente = panniers.length;
  final double totalVendu = panniers.fold(0.0, (sum, p) => sum + p.montant);

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
                  "assets/icons/sidebar/profile_icon.png",
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
                      user.username ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${user.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),
                Chip(
                  label: Text(
                    user.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: user.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: user.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: user.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeUtilisateur(user, l10n, nbrVente, totalVendu),
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
                  detailinfo(l10n.phone, user.telephone),
                  detailinfo(l10n.role, user.role),
                  detailinfo(l10n.status, user.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.financialInformation,
                icon: Icons.payments_outlined,
                child: detailwrap([
                  detailinfo(l10n.credit, "${user.credit ?? 0} ${l10n.currency}"),
                  detailinfo(l10n.sales, nbrVente),
                  detailinfo(l10n.totalSold, "${NumberFormatUtil.formatMontant(totalVendu, decimales: 2)} ${l10n.currency}"),
                  detailinfo(
                    l10n.lastAccess,
                    user.dernierAcces?.toString().split(" ").first,
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    user.observation?.isNotEmpty == true ? user.observation : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, user.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    user.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, user.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    user.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, user.annulParCode),
                  detailinfo(l10n.cancellationReason, user.motifAnnul),
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

// utilisateur_detail.dart - Remplacer _resumeUtilisateur
Widget _resumeUtilisateur(Utilisateur u, AppLocalizations l10n, int nbrVente, double totalVendu) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(label: l10n.credit, value: "${u.credit ?? 0} ${l10n.currency}"),
      StatsItem(label: l10n.sales, value: nbrVente),
      StatsItem(label: l10n.totalSold, value: "${NumberFormatUtil.formatMontant(totalVendu, decimales: 2)} ${l10n.currency}"),
      StatsItem(
        label: l10n.lastAccess,
        value: u.dernierAcces?.toString().split(" ").first ?? "-",
      ),
    ],
  );
}