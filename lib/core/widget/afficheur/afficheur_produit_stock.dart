// afficheur_produit_mouvement.dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/produit.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../Services/Mouvement.dart';
import '../../../Services/Photos.dart';
import '../../../Services/Produits.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurProduitMouvement extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onDetails;

  const AfficheurProduitMouvement({
    super.key,
    required this.produit,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              /// 🆕 PHOTO DU PRODUIT
              _buildProductPhoto(),

              const SizedBox(width: 16),

              /// Titre
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            produit.nom,
                            style: Appstyle.textLB.copyWith(fontSize: 16),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (produit.remiseId != null) ...[
                          const SizedBox(width: 8),
                          _remiseBadge(l10n),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${l10n.code} : ${produit.code}",
                      style: Appstyle.textSB.copyWith(color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              /// 📊 Stats
              Expanded(
                flex: 7,
                child: FutureBuilder<double>(
                  future: MouvementsServices.quantiteProduit(produit.code),
                  builder: (context, snapshot) {
                    final stock = snapshot.data ?? 0;
                    return Row(
                      children: [
                        _stat(l10n.actualStock, stock.toString(), Colors.blue, l10n),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(width: 20),

              /// ✅ Bouton détails
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  l10n.details,
                  style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                ),
              ),
            ],
          ),

          /// 📈 Mouvements de stock (achat / vente / retours / besoin)
          Padding(
            padding: const EdgeInsets.only(top: 10, left: 66),
            child: FutureBuilder<ProduitStats>(
              future: ProduitServices.getProduitStats(produit),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final stats = snapshot.data!;
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _statFixed(
                      l10n.lastPurchaseQuantity,
                      NumberFormatUtil.formatMontant(stats.quantiteDernierAchat, decimales: 0),
                      Colors.indigo,
                    ),
                    _statFixed(
                      l10n.lastPurchaseDate,
                      stats.dateDernierAchat != null ? _formatDate(stats.dateDernierAchat!) : "-",
                      Colors.indigo,
                    ),
                    _statFixed(l10n.totalAchat, NumberFormatUtil.formatMontant(stats.totalAchat, decimales: 0), Colors.purple),
                    _statFixed(l10n.totalSold, NumberFormatUtil.formatMontant(stats.totalVendu, decimales: 0), Colors.teal),
                    _statFixed(l10n.clientReturns, NumberFormatUtil.formatMontant(stats.totalRetourClient, decimales: 0), Colors.redAccent),
                    _statFixed(l10n.supplierReturns, NumberFormatUtil.formatMontant(stats.totalRetourFournisseur, decimales: 0), Colors.brown),
                    _statFixed(l10n.need, stats.besoin ? l10n.yes : l10n.no, stats.besoin ? Colors.red : Colors.green),
                    _statFixed(l10n.needStatus, stats.besoinStatus, Appstyle.blueF),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _remiseBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_offer, size: 12, color: Colors.orange),
          const SizedBox(width: 4),
          Text(
            l10n.discount,
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";

  // ✅ Widget corrigé pour une seule photo
  Widget _buildProductPhoto() {
    // Utiliser produit.photo au lieu de produit.photos
    if (produit.photo == null || produit.photo!.isEmpty) {
      return Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Appstyle.violet.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.inventory_2,
          size: 30,
          color: Appstyle.violet.withOpacity(0.6),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: PhotoService.getPhotoFile(produit.photo),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              snapshot.data!,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.broken_image,
            size: 30,
            color: Colors.grey,
          ),
        );
      },
    );
  }

  // ------------------ STAT CARD (largeur fixe, pour Wrap) ------------------
  Widget _statFixed(String label, String value, Color color) {
    return Container(
      width: 130,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------ STAT CARD ------------------
  Widget _stat(String label, String value, Color color, AppLocalizations l10n) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

}