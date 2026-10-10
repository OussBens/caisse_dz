import 'package:flutter/material.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/role.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> RoleDetail(BuildContext context, Role role) async {
  final utilisateurs = await UtilisateurServices.getUtilisateursByRoleCode(role.code);
  final int nombreUtilisateurs = utilisateurs.length;

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
                  "assets/icons/role_icon.png",
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
                      role.rolenom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${role.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    role.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: role.etat ? Appstyle.Tblanc : Appstyle.Tnoir, // ou une autre couleur
                    ),
                  ),
                  backgroundColor: role.etat
                      ? Appstyle.violet.withOpacity(0.8)
                      : Appstyle.crevete.withOpacity(0.7), // ou rouge, orange, etc.
                  labelPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  elevation: role.etat ? 2 : 0,
                )

              ],
            ),

            const SizedBox(height: 16),

            _resumeRole(role, l10n, nombreUtilisateurs),
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
                  detailinfo(l10n.roleName, role.rolenom),
                  detailinfo(l10n.status, role.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.userCount, nombreUtilisateurs),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.notes_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    role.observation?.isNotEmpty == true ? role.observation : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, role.creeParCode),
                  detailinfo(
                    l10n.dateCreated,
                    role.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, role.modifParCode),
                  detailinfo(
                    l10n.modifiedAt,
                    role.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, role.annulParCode),
                  detailinfo(l10n.cancellationReason, role.motifAnnul),
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
// role_detail.dart - Remplacer _resumeRole
Widget _resumeRole(Role r, AppLocalizations l10n, int nombreUtilisateurs) {
  return StatsCard(
    items: [
      StatsItem(label: l10n.code, value: r.code ?? "-"),
      StatsItem(label: l10n.userCount, value: nombreUtilisateurs),
      StatsItem(label: l10n.status, value: r.etat ? l10n.active : l10n.inactive),
    ],
  );
}