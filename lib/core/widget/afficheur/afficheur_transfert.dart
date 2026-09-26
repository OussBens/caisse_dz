import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/transfert.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurTransfert extends StatelessWidget {

  final TransfertCaisse transfert;
  final VoidCallback? onDetails;

  const AfficheurTransfert({
    super.key,
    required this.transfert,
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

          /// 🔹 Icône transfert
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.violet.withOpacity(0.15),
                child: Icon(
                  Icons.swap_horiz,
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
                  "${l10n.transfert} ${transfert.code}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.date} : ${_formatDate(transfert.dateTransfert)}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.from} : ${transfert.caisseExpCode}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.to} : ${transfert.caisseDestCode}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),

          /// 🔹 Stats
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(
                  l10n.amount,
                  transfert.montant,
                  Colors.blue,
                  suffix: " ${l10n.currency}",
                  l10n: l10n,
                ),
                _statCard(
                  l10n.source,
                  0,
                  Colors.orange,
                  customText: transfert.caisseExpCode,
                  l10n: l10n,
                ),
                _statCard(
                  l10n.destination,
                  0,
                  Colors.green,
                  customText: transfert.caisseDestCode,
                  l10n: l10n,
                ),
                _statCard(
                  l10n.status,
                  transfert.etat ? 1 : 0,
                  transfert.etat ? Colors.green : Colors.red,
                  customText: transfert.etat ? l10n.validated : l10n.pending,
                  isMoney: false,
                  l10n: l10n,
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
                  Icons.account_balance_wallet,
                  "${NumberFormatUtil.formatMontant(transfert.montant, decimales: 2)} ${l10n.currency}",
                ),
                _infoLine(
                  Icons.calendar_today,
                  _formatDate(transfert.dateTransfert),
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

  /// Badge état
  Widget _etatBadge(AppLocalizations l10n) {
    Color color = transfert.etat ? Colors.green : Colors.red;
    String label = transfert.etat ? l10n.validated : l10n.waiting;

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

  /// Stat Card
  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = false,
        String? suffix,
        String? customText,
        required AppLocalizations l10n,
      }) {
    return Container(
      width: 140,
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
            customText ??
                "${NumberFormatUtil.formatMontant(value, decimales: 2)}${suffix ?? ""}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Info line
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

  /// Format date
  String _formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2,'0')}/"
        "${date.month.toString().padLeft(2,'0')}/"
        "${date.year}";
  }
}