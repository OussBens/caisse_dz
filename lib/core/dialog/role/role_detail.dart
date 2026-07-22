import 'package:flutter/material.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/role.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
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
        width: 900,
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
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
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
                  detailinfo(l10n.modifiedBy, role.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    role.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, role.annulPar),
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

Widget _resumeRole(Role r, AppLocalizations l10n, int nombreUtilisateurs) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.code, r.code ?? "-"),
        detailbadge(l10n.userCount, nombreUtilisateurs),
        detailbadge(l10n.status, r.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}