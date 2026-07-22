import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/fournisseur.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../base_dialog.dart';

Future<void> FournisseurDetail(BuildContext context, Fournisseur fournisseur) async {
  final stats = await FournisseurServices.getFournisseurStats(fournisseur);

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
                  "assets/icons/sidebar/fournisseur_icon.png",
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
                      fournisseur.nom,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${fournisseur.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    fournisseur.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeFournisseur(fournisseur, l10n, stats),
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
                  detailinfo(l10n.phone, fournisseur.telephone),
                  detailinfo(l10n.supplierType, fournisseur.type),
                  detailinfo(l10n.activity, fournisseur.activity),
                  detailinfo(l10n.status, fournisseur.etat ? l10n.active : l10n.inactive),
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
                ]),
              ),

              // ================= CONTACT =================
              SectionDecoration(
                title: l10n.contact,
                icon: Icons.contact_phone_outlined,
                child: detailwrap([
                  detailinfo(l10n.email, fournisseur.email),
                  detailinfo(l10n.fax, fournisseur.fax),
                ]),
              ),

              // ================= ADRESSE =================
              SectionDecoration(
                title: l10n.addressInfo,
                icon: Icons.location_on_outlined,
                child: detailwrap([
                  detailinfo(l10n.wilaya, fournisseur.wilaya),
                  detailinfo(l10n.address, fournisseur.adresse),
                ]),
              ),

              // ================= OBSERVATION =================
              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    fournisseur.observation ?? "-",
                    style: Appstyle.textSB,
                  ),
                ),
              ),

              // ================= AUDIT =================
              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, fournisseur.creeParCode),
                  detailinfo(
                    l10n.createdAt,
                    fournisseur.dateCree?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.modifiedBy, fournisseur.modifPar),
                  detailinfo(
                    l10n.modifiedAt,
                    fournisseur.dateModif?.toString().split(" ").first,
                  ),
                  detailinfo(l10n.cancelledBy, fournisseur.annulPar),
                  detailinfo(l10n.cancellationReason, fournisseur.motifAnnul),
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

Widget _resumeFournisseur(Fournisseur f, AppLocalizations l10n, FournisseurStats stats) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(l10n.totalAchat, stats.totalAchat),
        detailbadge(l10n.totalPaid, stats.totalVerse),
        detailbadge(l10n.totalReturn, stats.totalRetour),
        detailbadge(l10n.lastPurchaseDate, stats.dateDernierAchat?.toString().split(" ").first ?? "-"),
        detailbadge(l10n.advance, stats.avance),
        detailbadge(l10n.credit, stats.credit),
        detailbadge(l10n.balance, stats.solde),
        detailbadge(l10n.status, f.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}