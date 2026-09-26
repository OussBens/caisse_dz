import 'package:flutter/material.dart';

import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/pannier.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurUtilisateur extends StatelessWidget {

  final Utilisateur utilisateur;
  final VoidCallback? onDetails;

  const AfficheurUtilisateur({
    super.key,
    required this.utilisateur,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(8),
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

          /// 🔹 Icône utilisateur
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.violet.withOpacity(0.15),
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: Appstyle.violet,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),

          const SizedBox(width: 16),

          /// 🔹 Infos principales
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  utilisateur.username,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${utilisateur.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.role} : ${utilisateur.role}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.phone} : ${utilisateur.telephone}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          /// 🔹 Stats utilisateur
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(
                  l10n.credit,
                  utilisateur.credit,
                  utilisateur.credit >= 0 ? Colors.green : Colors.red,
                  l10n: l10n,
                ),
                FutureBuilder<List<Pannier>>(
                  future: PannierServices.getPanniersActifsByCaissierCode(utilisateur.code),
                  builder: (context, snapshot) {
                    final panniers = snapshot.data ?? [];
                    final double totalVendu = panniers.fold(0.0, (sum, p) => sum + p.montant);
                    return Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        _statCard(l10n.sales, panniers.length.toDouble(), Colors.blue, isMoney: false, l10n: l10n),
                        _statCard(l10n.totalSold, totalVendu, Colors.teal, l10n: l10n),
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
                _infoLine(
                  Icons.access_time,
                  "${l10n.lastAccess} : ${_formatDate(utilisateur.dernierAcces)}",
                ),
                _infoLine(
                  Icons.badge,
                  "${l10n.role} : ${utilisateur.role}",
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
              l10n.details,
              style: Appstyle.textSB.copyWith(
                color: Appstyle.Tblanc,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🟢 Badge état utilisateur
  Widget _etatBadge(AppLocalizations l10n) {
    Color color = utilisateur.etat ? Colors.green : Colors.red;
    String label = utilisateur.etat ? l10n.active : l10n.inactive;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),
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
            isMoney
                ? "${NumberFormatUtil.formatMontant(value, decimales: 0)} ${l10n.currency}"
                : NumberFormatUtil.formatMontant(value, decimales: 0),
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
    return "${date.day.toString().padLeft(2, '0')}/"
        "${date.month.toString().padLeft(2, '0')}/"
        "${date.year}";
  }
}