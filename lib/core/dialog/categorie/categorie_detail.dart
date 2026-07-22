import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/categorie.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> CategorieDetail(
  BuildContext context,
  Categorie categorie, {
  int nombreSousCategories = 0,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width: 850,
        height: 550,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/categorie_icon.png",
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
                      categorie.nom ?? "-",
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${categorie.code ?? "-"}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    categorie.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeCategorie(categorie, l10n, nombreSousCategories),
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
                  detailinfo(l10n.name, categorie.nom),
                  detailinfo(l10n.code, categorie.code),
                  detailinfo(l10n.status, categorie.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.subcategories, nombreSousCategories),
                ]),
              ),

              // ================= OBSERVATION =================
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    categorie.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              // ================= AUDIT =================
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, categorie.creeParCode),
                  detailinfo(
                    l10n.createdAt,
                    categorie.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, categorie.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    categorie.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, categorie.annulPar),
                  detailinfo(l10n.cancellationReason, categorie.motifAnnul),
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

Widget _resumeCategorie(Categorie c, AppLocalizations l10n, int nombreSousCategories) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(10),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.id, c.id),
        detailbadge(l10n.subcategories, nombreSousCategories),
        detailbadge(l10n.status, c.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}