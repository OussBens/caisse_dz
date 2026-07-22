import 'dart:io';

import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/produit.dart';
import '../../../../l10n/app_localizations.dart';

// Dans afficheur_produit.dart

import '../../../Services/Photos.dart';
import '../../../Services/Produits.dart';

class AfficheurProduit extends StatelessWidget {
  final Produit produit;
  final VoidCallback? onDetails;
  final bool afficherprixachat;
  final bool afficheurBorder; // ✅ NOUVEAU PARAMÈTRE

  const AfficheurProduit({
    super.key,
    required this.produit,
    this.onDetails,
    this.afficherprixachat = true,
    this.afficheurBorder = false, // ✅ VALEUR PAR DÉFAUT
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        // ✅ CONDITION POUR LE COULEUR DE FOND
        color: afficheurBorder ? Colors.transparent : Colors.white,
        borderRadius: BorderRadius.circular(16),
        // ✅ CONDITION POUR LA BORDURE
        border: afficheurBorder
            ? Border.all(
          color: Colors.black.withOpacity(0.2),
          width: 1,
        )
            : null,
        boxShadow: afficheurBorder
            ? null // ✅ PAS D'OMBRE SI BORDURE ACTIVÉE
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🆕 PHOTO DU PRODUIT
          _buildProductPhoto(context),

          const SizedBox(width: 16),

          /// 🔹 Infos principales
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.marque} : ${produit.marque}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${produit.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          /// 🔹 Stats Produit
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(l10n.salePrice, produit.prixVente, Colors.green, l10n: l10n),
                if (afficherprixachat)
                  _statCard(
                    l10n.purchasePrice,
                    produit.prixAchat,
                    Colors.orange,
                    l10n: l10n,
                  ),
                _statCard(l10n.quantity, produit.quantite ?? 0, Colors.blue, isMoney: false, l10n: l10n),
                FutureBuilder<ProduitStats>(
                  future: ProduitServices.getProduitStats(produit),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox.shrink();
                    final stats = snapshot.data!;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _statCard(l10n.totalAchat, stats.totalAchat, Colors.purple, isMoney: false, l10n: l10n),
                        _statCard(l10n.totalSold, stats.totalVendu, Colors.teal, isMoney: false, l10n: l10n),
                        _statCard(l10n.clientReturns, stats.totalRetourClient, Colors.redAccent, isMoney: false, l10n: l10n),
                        _statCard(l10n.supplierReturns, stats.totalRetourFournisseur, Colors.brown, isMoney: false, l10n: l10n),
                        _textBadge(l10n.need, stats.besoin ? l10n.yes : l10n.no, stats.besoin ? Colors.red : Colors.green),
                        _textBadge(l10n.needStatus, stats.besoinStatus, Appstyle.blueF),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.category, "${l10n.categorie} : ${produit.categorie ?? "—"}"),
                _infoLine(Icons.local_shipping, "${l10n.fournisseur} : ${produit.fournisseur ?? "—"}"),
                _infoLine(Icons.straighten, "${l10n.unit} : ${produit.uniteMesure}"),
              ],
            ),
          ),

          const SizedBox(width: 20),

          /// 🔹 Bouton Détails
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
    );
  }

  // 🆕 Widget pour afficher la photo
  Widget _buildProductPhoto(BuildContext context) {
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

  Widget _etatBadge(AppLocalizations l10n) {
    Color color = produit.etat ? Colors.green : Colors.red;
    String label = produit.etat ? l10n.active : l10n.inactive;

    if ((produit.quantite ?? 0) <= 0) {
      color = Colors.orange;
      label = l10n.outOfStock;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 📊 Carte statistique
  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = true,
        required AppLocalizations l10n,
      }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            isMoney
                ? "${value.toStringAsFixed(0)} ${l10n.currency}"
                : value.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 🏷 Badge texte (besoin / statut besoin)
  Widget _textBadge(String label, String value, Color color) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color)),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// ℹ Ligne info
  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}