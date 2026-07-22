import 'package:flutter/material.dart';
import 'package:caisse_dz/core/dialog/remise/remise_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/remise.dart';
import '../../../../l10n/app_localizations.dart';

class AfficheurRemise extends StatelessWidget {
  final Remise remise;
  final int nombreProduits;
  final VoidCallback? onDetails;

  const AfficheurRemise({
    super.key,
    required this.remise,
    this.nombreProduits = 0,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// 🔹 Icône + état
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.green.withOpacity(0.15),
                child: const Icon(
                  Icons.percent,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),

          const SizedBox(width: 16),

          /// 🔹 Infos principales
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  remise.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (remise.code != null)
                  Text("${l10n.code} : ${remise.code}",
                      style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text(
                  "${l10n.type} : ${remise.type}",
                  style: TextStyle(color: Appstyle.blueF),
                ),
              ],
            ),
          ),

          /// 🔹 Statistiques
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _statCard(
                  remise.tauxType == "POURCENTAGE"
                      ? l10n.rate
                      : l10n.amount,
                  remise.tauxType == "POURCENTAGE"
                      ? (remise.taux)
                      : (remise.montant?.toDouble() ?? 0),
                  Colors.orange,
                  suffix: remise.tauxType == "POURCENTAGE" ? " %" : " ${l10n.currency}",
                  l10n: l10n,
                ),
                if (remise.type == "Par Produit")
                  _statCard(
                    l10n.productCount,
                    nombreProduits.toDouble(),
                    Appstyle.violet,
                    suffix: "",
                    l10n: l10n,
                  ),
              ],
            ),
          ),

          /// 🔹 Période
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(
                  Icons.date_range,
                  remise.debut != null && remise.fin != null
                      ? "${_formatDate(remise.debut!)} ${l10n.to} ${_formatDate(remise.fin!)}"
                      : "—",
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          /// 🔹 Boutons d'action
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Bouton Détails
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  minimumSize: const Size(120, 40),
                ),
                child: Text(
                  l10n.details,
                  style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                ),
              ),
              const SizedBox(height: 8),
              // Bouton Liste des produits (uniquement pour les remises de type "Par Produit")
               if (remise.type == "Par Produit")
                ElevatedButton(
                  onPressed: () {
                    // Appel de la fonction dédiée pour la liste des produits
                    showRemiseProductsListDialog(context, remise, l10n);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Appstyle.crevete,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: const Size(120, 40),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.list, size: 18, color: Colors.white),
                      const SizedBox(width: 8),
                      Text(
                        l10n.productsList,
                        style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n) {
    final bool actif = remise.etat;
    final Color color = actif ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        actif ? l10n.active : l10n.inactive,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statCard(
      String label,
      double value,
      Color color, {
        required String suffix,
        required AppLocalizations l10n,
      }) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            "${value.toStringAsFixed(0)}$suffix",
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

  Widget _infoLine(IconData icon, String text) {
    return Row(
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
    );
  }

  String _formatDate(DateTime date) =>
      "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}