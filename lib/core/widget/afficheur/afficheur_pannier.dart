import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../data/models/pannier.dart';
import '../../../core/dialog/pannier/pannier_detail.dart'; // Pour showProductsListDialog

class AfficheurPanier extends StatelessWidget {
  final Pannier pannier;
  final VoidCallback? onDetails;

  const AfficheurPanier({
    super.key,
    required this.pannier,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final date = _formatDate(pannier.date);
    final heure = _formatHeure(pannier.date);

    return Container(
      padding: const EdgeInsets.all(16),
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
          /// 🔹 Icône
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(
              Icons.shopping_basket,
              size: 36,
              color: Colors.deepPurple,
            ),
          ),

          const SizedBox(width: 10),

          /// 🔹 Infos Panier
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${l10n.panier} N° ${pannier.code}",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text("${l10n.client} : ${pannier.client_code ?? ""}",
                    style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 6),
                _etatBadge(l10n),
              ],
            ),
          ),

          /// 🔹 Stats
          Expanded(
            flex: 6,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _statCard(l10n.total, pannier.montant, Colors.deepPurple, l10n),
                _statCard(l10n.paid, pannier.verse, Colors.green, l10n),
                _statCard(l10n.remaining, pannier.reste, Colors.blue, l10n),
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.calendar_today, "${l10n.date} : $date"),
                _infoLine(Icons.access_time, "${l10n.time} : $heure"),
                _infoLine(Icons.person, "${l10n.caissier} : ${pannier.caissier_code}"),
              ],
            ),
          ),

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
              // ✅ NOUVEAU BOUTON : Liste des produits
              ElevatedButton(
                onPressed: () {
                  showProductsListDialog(context, pannier, l10n);
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

  Widget _statCard(String label, double value, Color color, AppLocalizations l10n) {
    return Container(
      width: 120,
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
            "${value.toStringAsFixed(0)} ${l10n.currency}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n) {
    Color color = pannier.etat ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        pannier.etat ? l10n.actif : l10n.inactif,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/"
      "${date.month.toString().padLeft(2, '0')}/"
      "${date.year}";
}

String _formatHeure(DateTime date) {
  return "${date.hour.toString().padLeft(2, '0')}:"
      "${date.minute.toString().padLeft(2, '0')}";
}