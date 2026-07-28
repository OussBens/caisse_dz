import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../data/models/gestion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/detail_widget.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

Future<void> CaisseGestionDetail(
    BuildContext context,
    CaisseGestion caisse,
    ) async {
  final l10n = AppLocalizations.of(context)!;
  final magasins = await MagasinServices.getAllMagasins();
  final nomMagasin = magasins.firstWhereOrNull((m) => m.code == caisse.magasinCode)?.nom
      ?? caisse.magasinCode;

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
                  "assets/icons/sidebar/caisse_icon.png",
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
                      caisse.nomCaisse,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${caisse.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    caisse.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                  ),
                  backgroundColor:
                  caisse.etat ? Appstyle.crevete : Appstyle.gris,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeCaisse(caisse, nomMagasin, l10n),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              detailsection(l10n.generalInformation),
              detailwrap([
                detailinfo(l10n.cashRegisterName, caisse.nomCaisse),
                detailinfo(l10n.code, caisse.code),
                detailinfo(l10n.store, nomMagasin),
                detailinfo(l10n.type, caisse.typecaisse == "physique" ? l10n.physical : l10n.account),
                detailinfo(l10n.status, caisse.etat ? l10n.active : l10n.inactive),
              ]),

              detailsection(l10n.financialInformation),
              detailwrap([
                detailinfo(
                  l10n.initialBalance,
                  "${caisse.soldeInitial.toStringAsFixed(2)} ${l10n.currency}",
                ),
              ]),

              detailsection(l10n.observation),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  caisse.observation ?? "-",
                  style: Appstyle.textSB,
                ),
              ),

              detailsection(l10n.audit),
              detailwrap([
                detailinfo(l10n.createdBy, caisse.creeParCode),
                detailinfo(
                  l10n.createdAt,
                  caisse.dateCree?.toString().split(" ").first,
                ),
                detailinfo(l10n.modifiedBy, caisse.modifParCode),
                detailinfo(
                  l10n.modifiedAt,
                  caisse.dateModif?.toString().split(" ").first,
                ),
                detailinfo(l10n.cancelledBy, caisse.annulParCode),
                detailinfo(l10n.cancellationReason, caisse.motifAnnul),
              ]),
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

Widget _resumeCaisse(CaisseGestion c, String nomMagasin, AppLocalizations l10n) {
  return Container(
    decoration: BoxDecoration(
      color: Appstyle.violet.withOpacity(0.6),
      borderRadius: BorderRadius.circular(10),
    ),
    padding: const EdgeInsets.all(8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        detailbadge(
          l10n.initialBalance,
          "${c.soldeInitial.toStringAsFixed(2)} ${l10n.currency}",
        ),
        detailbadge(l10n.store, nomMagasin),
        detailbadge(l10n.status, c.etat ? l10n.active : l10n.inactive),
      ],
    ),
  );
}