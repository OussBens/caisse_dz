import 'package:collection/collection.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/smart_scan.dart';
import '../../../data/models/smart_scan_produit.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/fournisseur.dart';
import '../../widget/detail_widget.dart';
import '../../widget/section_decoration.dart';
import '../../widget/stats_card.dart';
import '../base_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Détail d'une entrée rapide : lecture seule d'un SmartScan à 1 produit,
/// affiché comme avant la fusion (produit/quantité/prix directement, sans
/// passer par la liste de produits du SmartScan classique).
Future<void> EntreeDetail(
    BuildContext context,
    SmartScan scan, {
      required List<Produit> produits,
      required List<Fournisseur> fournisseurs,
    }) async {
  final lignes = await SmartScanProduitServices.getSmartScanProduitByCode(scan.code);
  final SmartScanProduit? ligne = lignes.firstOrNull;

  final nomProduit = ligne == null
      ? ''
      : produits.where((p) => p.code == ligne.codeProduit).firstOrNull?.nom ?? ligne.codeProduit;
  final nomFournisseur = fournisseurs.where((f) => f.code == scan.fournisseurCode).firstOrNull?.nom
      ?? scan.fournisseurCode;

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
                  "assets/icons/cardwidget/entree_rapide_icon.png",
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
                      nomProduit,
                      style: Appstyle.textLB.copyWith(fontSize: 20),
                    ),
                    Text(
                      "${l10n.code}: ${scan.code}",
                      style: Appstyle.textSB,
                    ),
                  ],
                ),

                const Spacer(),

                Chip(
                  label: Text(
                    scan.etat ? l10n.active : l10n.inactive,
                    style: Appstyle.textSB.copyWith(
                      color: Appstyle.Tblanc,
                    ),
                  ),
                  backgroundColor: Appstyle.crevete,
                ),
              ],
            ),

            const SizedBox(height: 16),

            _resumeEntree(scan, ligne, l10n, nomFournisseur),
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
                  detailinfo(l10n.code, scan.code),
                  detailinfo(l10n.date, scan.date),
                  detailinfo(l10n.status, scan.etat ? l10n.active : l10n.inactive),
                ]),
              ),

              SectionDecoration(
                title: l10n.product,
                icon: Icons.inventory_2_outlined,
                child: detailwrap([
                  detailinfo(l10n.productName, nomProduit),
                  detailinfo(l10n.productCode, ligne?.codeProduit ?? ''),
                  detailinfo(l10n.quantity, ligne?.quantite ?? 0),
                  detailinfo(l10n.unitPrice, "${NumberFormatUtil.formatMontant((ligne?.prix ?? 0), decimales: 2)} ${l10n.currency}"),
                  detailinfo(l10n.amount, "${NumberFormatUtil.formatMontant(scan.montant, decimales: 2)} ${l10n.currency}"),
                ]),
              ),

              SectionDecoration(
                title: l10n.supplier,
                icon: Icons.local_shipping_outlined,
                child: detailwrap([
                  detailinfo(l10n.supplier, nomFournisseur),
                  detailinfo(l10n.supplierCode, scan.fournisseurCode),
                ]),
              ),

              SectionDecoration(
                title: l10n.observation,
                icon: Icons.description_outlined,
                child: detailwrap([
                  detailinfo(
                    l10n.observation,
                    scan.observation?.isNotEmpty == true
                        ? scan.observation
                        : "-",
                  ),
                ]),
              ),

              SectionDecoration(
                title: l10n.audit,
                icon: Icons.history,
                child: detailwrap([
                  detailinfo(l10n.createdBy, scan.creeParCode),
                  detailinfo(l10n.dateCreated, scan.dateCree),
                  detailinfo(l10n.modifiedBy, scan.modifParCode),
                  detailinfo(l10n.modifiedAt, scan.dateModif),
                  detailinfo(l10n.cancelledBy, scan.annulParCode),
                  detailinfo(l10n.cancellationReason, scan.motifAnnul),
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

// Dans entree_detail.dart
Widget _resumeEntree(SmartScan scan, SmartScanProduit? ligne, AppLocalizations l10n, String nomFournisseur) {
  return StatsCard(
    backgroundColor: Appstyle.green.withOpacity(0.7),
    items: [
      StatsItem(
        label: l10n.quantity,
        value: ligne?.quantite ?? 0,
      ),
      StatsItem(
        label: l10n.price,
        value: "${NumberFormatUtil.formatMontant((ligne?.prix ?? 0), decimales: 2)} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.amount,
        value: "${NumberFormatUtil.formatMontant(scan.montant, decimales: 2)} ${l10n.currency}",
      ),
      StatsItem(
        label: l10n.supplier,
        value: nomFournisseur,
      ),
    ],
  );
}
