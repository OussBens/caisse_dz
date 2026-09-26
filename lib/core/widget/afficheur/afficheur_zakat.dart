import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../data/models/zakat.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurZakat extends StatelessWidget {
  final Zakat zakat;
  final VoidCallback? onDetails;

  const AfficheurZakat({
    super.key,
    required this.zakat,
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
          /// 🔹 Icône Zakat
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.violet.withOpacity(0.2),
                child: Icon(
                  Icons.account_balance,
                  size: 28,
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
                  zakat.code,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text("${l10n.year} : ${zakat.annee}", style: TextStyle(color: Colors.grey.shade700)),
                const SizedBox(height: 4),
                Text("${l10n.zakatAmount} : ${NumberFormatUtil.formatMontant(zakat.montantZakat, decimales: 2)} ${l10n.currency}", style: TextStyle(color: Colors.grey.shade700)),
              ],
            ),
          ),

          /// 🔹 Stats Zakat
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(l10n.stock, zakat.stock, Colors.blue, l10n),
                _statCard(l10n.cash, zakat.liquidites, Colors.green, l10n),
                _statCard(l10n.receivables, zakat.creances, Colors.orange, l10n),
                _statCard(l10n.debts, zakat.dettes, Colors.red, l10n),
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.percent, "${l10n.rate}: ${zakat.taux}%"),
                _infoLine(Icons.account_balance_wallet, "${l10n.nissab}: ${zakat.nissab} ${l10n.currency}"),
                _infoLine(Icons.check_circle, "${l10n.mandatory}: ${zakat.obligatoire ? l10n.yes : l10n.no}"),
              ],
            ),
          ),

          const SizedBox(width: 20),

          /// 🔹 Bouton Détails
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

  /// 🟢 Badge état
  Widget _etatBadge(AppLocalizations l10n) {
    Color color = zakat.etat ? Colors.green : Colors.red;
    String label = zakat.etat ? l10n.active : l10n.inactive;

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
  Widget _statCard(String label, double value, Color color, AppLocalizations l10n) {
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
            "${NumberFormatUtil.formatMontant(value, decimales: 2)} ${l10n.currency}",
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