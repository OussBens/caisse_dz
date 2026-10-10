import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:flutter/material.dart';
import '../../../data/models/produit.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Affiche les informations pertinentes à l'expiration d'un produit
/// sélectionné dans l'onglet "Produits expirés" (date d'expiration,
/// ancienneté, quantité concernée) — équivalent de [AfficheurProduit] mais
/// centré sur l'expiration plutôt que sur les infos générales du produit.
class AfficheurProduitExpire extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onDetails;

  const AfficheurProduitExpire({
    super.key,
    required this.produit,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dateExpiration = produit.dateEmpreint;
    final joursDepuisExpiration =
        dateExpiration != null ? DateTime.now().difference(dateExpiration).inDays : null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusButton),
        boxShadow: [
          BoxShadow(
            color: Appstyle.shadowTint.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CircleAvatar(
              backgroundColor: Appstyle.danger.withOpacity(0.15),
              child: const Icon(Icons.event_busy, color: Appstyle.danger),
            ),
          ),
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _info(l10n.code, produit.code),
                _info(l10n.product, produit.nom),
                _info(
                  l10n.expiryDate,
                  dateExpiration != null
                      ? "${dateExpiration.day.toString().padLeft(2, '0')}/"
                          "${dateExpiration.month.toString().padLeft(2, '0')}/"
                          "${dateExpiration.year}"
                      : '-',
                ),
                _info(
                  l10n.daysSinceExpiry,
                  joursDepuisExpiration != null ? joursDepuisExpiration.toString() : '-',
                ),
                Expanded(
                  child: FutureBuilder<double>(
                    future: MouvementsServices.quantiteProduit(produit.code),
                    builder: (context, snapshot) {
                      return _infoContent(l10n.quantity, NumberFormatUtil.formatMontant(snapshot.data ?? 0, decimales: 0));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
            ),
            child: Text(
              l10n.details,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return Expanded(child: _infoContent(label, value));
  }

  Widget _infoContent(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Appstyle.gris)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
