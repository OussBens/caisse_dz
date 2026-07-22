import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class AfficheurCategorie extends StatelessWidget {
  final Categorie categorie;
  final int nombreSousCategories;
  final VoidCallback? onDetails;

  const AfficheurCategorie({
    super.key,
    required this.categorie,
    this.nombreSousCategories = 0,
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
                backgroundColor: Appstyle.blueF.withOpacity(0.15),
                child: Icon(
                  Icons.category,
                  color: Appstyle.blueF,
                  size: 24,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),  // 🔥 Pass l10n to method
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
                  categorie.nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (categorie.code != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${l10n.code} : ${categorie.code}",  // 🔥 Translated
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
                if (categorie.observation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    categorie.observation!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),

          /// 🔹 Statistiques
          Expanded(
            flex: 4,
            child: Row(
              children: [
                _statCard(
                  l10n.subcategories,
                  nombreSousCategories.toDouble(),
                  Appstyle.blueF,
                  isMoney: false,
                ),
              ],
            ),
          ),

          /// 🔹 Infos système
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.person, categorie.creePar ?? "—"),
                _infoLine(
                  Icons.calendar_today,
                  categorie.dateCree != null
                      ? _formatDate(categorie.dateCree!)
                      : "—",
                ),
              ],
            ),
          ),

          const SizedBox(width: 20),

          /// 🔹 Bouton détails
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
              l10n.details,  // 🔥 Translated
              style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
            ),
          ),
        ],
      ),
    );
  }

  /// 🟢 Badge état catégorie
  Widget _etatBadge(AppLocalizations l10n) {  // 🔥 Accept l10n parameter
    final bool actif = categorie.etat;

    final Color color = actif ? Colors.green : Colors.red;
    final String label = actif ? l10n.active : l10n.inactive;  // 🔥 Translated

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
      }) {
    return Container(
      width: 110,
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
                ? "${value.toStringAsFixed(0)} DA"
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

  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }
}