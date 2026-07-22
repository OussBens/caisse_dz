import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/entree.dart';

class AfficheurEntreeMouvement extends StatelessWidget {
  final Entree entree;
  final VoidCallback? onDetails;

  const AfficheurEntreeMouvement({
    super.key,
    required this.entree,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {

    final quantite = entree.quantite;
    final prix = entree.prix;
    final montant = entree.montant;

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
      child: Row(
        children: [

          /// 📦 PRODUIT
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(Icons.input, color: Appstyle.violet),
                const SizedBox(width: 10),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        entree.produit,
                        style: Appstyle.textLB.copyWith(fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Code : ${entree.code}",
                        style: Appstyle.textSB
                            .copyWith(color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// 📊 STATS
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _stat("Quantité", quantite.toString(), Colors.blue),
                _stat("Prix achat", prix.toStringAsFixed(2), Colors.green),
                _stat("Montant", montant.toStringAsFixed(2), Colors.deepPurple),
                _stat("Fournisseur", entree.fournisseur, Colors.orange),
                _stat("Etat", entree.etat ? "Validé" : "Annulé",
                    entree.etat ? Colors.green : Colors.red),
              ],
            ),
          ),

          const SizedBox(width: 20),

          /// 🕒 TIMELINE
          Expanded(
            flex: 2,
            child: _timelineCard(),
          ),

          const SizedBox(width: 20),

          /// ✅ DETAILS
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
              "Détails",
              style:
              Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- TIMELINE ----------------
  Widget _timelineCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Appstyle.violet.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.history, color: Appstyle.violet),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Date entrée",
                  style: Appstyle.textSB
                      .copyWith(color: Appstyle.violet),
                ),
                const SizedBox(height: 6),

                Text(
                  _formatDate(entree.date),
                  style: Appstyle.textMB,
                ),

                const SizedBox(height: 4),

                Text(
                  "Créé par : ${entree.creeParCode}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- STAT CARD ----------------
  Widget _stat(String label, String value, Color color) {
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
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "—";
    return DateFormat("dd/MM/yyyy  HH:mm").format(date);
  }
}