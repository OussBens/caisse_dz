import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/mouvement.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/client.dart';
import '../../../data/models/fournisseur.dart';
import '../../../l10n/app_localizations.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';

Future<void> MouvementDetail(
    BuildContext context,
    Mouvement mouvement, {
      required List<Produit> produits,
      required List<Client> clients,
      required List<Fournisseur> fournisseurs,
    }) async {
  final l10n = AppLocalizations.of(context)!;

  final nomProduit = produits.where((p) => p.code == mouvement.codeProduit).firstOrNull?.nom
      ?? mouvement.codeProduit;
  final nomClient = mouvement.clientCode == null
      ? null
      : clients.where((c) => c.code == mouvement.clientCode).firstOrNull?.nom ?? mouvement.clientCode;
  final nomFournisseur = mouvement.fournisseurCode == null
      ? null
      : fournisseurs.where((f) => f.code == mouvement.fournisseurCode).firstOrNull?.nom ?? mouvement.fournisseurCode;

  return showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) {
      return BaseDialog(
        width   : 900,
        height  : 600,

        // ================= HEADER =================
        header: Column(
          children: [
            Row(
              children: [
                Image.asset(
                  "assets/icons/cardwidget/mouvement_icon.png",
                  width           : 34,
                  height          : 34,
                  color           : Appstyle.violet,
                  colorBlendMode  : BlendMode.srcIn,
                ),
                const SizedBox(width: 10),

                Column(
                  crossAxisAlignment  : CrossAxisAlignment.start,
                  children: [
                    Text(
                      nomProduit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code} : ${mouvement.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

              ],
            ),

            const SizedBox(height: 16),

            _resumeMouvement(mouvement, l10n),
          ],
        ),

        // ================= CONTENT =================
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionDecoration(
                title: l10n.generalInformation,
                icon: Icons.info_outline,
                child: detailwrap([
                  detailinfo(l10n.type, _getTranslatedType(mouvement.type, l10n)),
                  detailinfo(l10n.client, nomClient),
                  detailinfo(l10n.supplier, nomFournisseur),
                  detailinfo(l10n.status, mouvement.etat ? l10n.active : l10n.inactive),
                  detailinfo(l10n.date, _formatDate(mouvement.date)),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.image,
                child: detailwrap([
                  detailinfo(l10n.productName, nomProduit),
                  detailinfo(l10n.quantity, mouvement.quantite.toString()),
                  detailinfo(l10n.purchasePrice, "${mouvement.prixAchat} ${l10n.currency}"),
                  detailinfo(l10n.salePrice, "${mouvement.prixVente} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, mouvement.creeParCode),
                  detailinfo(l10n.createdAt, _formatDate(mouvement.dateCree)),
                  detailinfo(l10n.modifiedBy, mouvement.modifParCode),
                  detailinfo(l10n.modifiedAt, _formatDate(mouvement.dateModif)),
                  detailinfo(l10n.cancelledBy, mouvement.annulParCode),
                  detailinfo(l10n.cancellationReason, mouvement.motifAnnul),
                ]),
              ),
            ],
          ),
        ),

        // ================= FOOTER =================
        footer: Align(
          alignment : Alignment.centerRight,
          child     : ElevatedButton.icon(
            icon  : const Icon(Icons.close),
            label : Text(l10n.close),
            style : ElevatedButton.styleFrom(
              backgroundColor : Appstyle.violet,
              foregroundColor : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius  : BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return "-";
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

String _getTranslatedType(String type, AppLocalizations l10n) {
  switch (type) {
    case "Vente":
      return l10n.sale;
    case "Achat":
      return l10n.purchase;
    case "Retour":
      return l10n.return_;
    case "Sortie":
      return l10n.exit;
    default:
      return type;
  }
}

// Dans mouvement_detail.dart
Widget _resumeMouvement(Mouvement m, AppLocalizations l10n) {
  return StatsCard(
    backgroundColor: Appstyle.violet.withOpacity(0.7),
    items: [
      StatsItem(
        label: l10n.quantity,
        value: m.quantite.toString(),
      ),
      StatsItem(
        label: l10n.purchasePrice,
        value: "${m.prixAchat} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.salePrice,
        value: "${m.prixVente} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.type,
        value: _getTranslatedType(m.type, l10n),
      ),
    ],
  );
}