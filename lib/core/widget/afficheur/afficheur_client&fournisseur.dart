
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class ClientAfficheurWidget extends StatelessWidget {
  final String nom;
  final String code;
  final String type;
  final String activite;
  final bool etat;

  final double totalVersement;

  final String wilaya;
  final String dateCreation;

  // Statistiques financières (Client uniquement — calculées en direct)
  final double? totalAchat;
  final double? totalRetour;
  final DateTime? dateDernierAchat;
  final double? avance;
  final double? credit;
  final double? solde;

  final VoidCallback? onDetails;

  const ClientAfficheurWidget({
    super.key,
    required this.nom,
    required this.code,
    required this.type,
    required this.activite,
    required this.etat,
    required this.totalVersement,
    required this.wilaya,
    required this.dateCreation,
    this.totalAchat,
    this.totalRetour,
    this.dateDernierAchat,
    this.avance,
    this.credit,
    this.solde,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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

          // ================== LEFT : IDENTITÉ ==================
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Appstyle.violet.withOpacity(0.15),
                child: Icon(
                  Icons.person,
                  size: 34,
                  color: Appstyle.violet,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(nom, style: Appstyle.textLB),
                  const SizedBox(height: 4),
                  Text(
                    "$code • $type - $activite",
                    style: Appstyle.textSB.copyWith(color: Colors.grey),
                  ),
                  const SizedBox(height: 6),
                  _etatBadge(l10n),  // 🔥 Pass l10n
                ],
              ),
            ],
          ),

          const Spacer(),

          // ================== STATS ==================
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statItem(
                label: l10n.payments,         // 🔥 Translated
                value: totalVersement,
                icon: Icons.payments,
                color: Appstyle.crevete,
              ),
              if (totalAchat != null)
                _statItem(
                  label: l10n.totalAchat,
                  value: totalAchat!,
                  icon: Icons.shopping_cart,
                  color: Appstyle.violet,
                ),
              if (totalRetour != null)
                _statItem(
                  label: l10n.totalReturn,
                  value: totalRetour!,
                  icon: Icons.assignment_return,
                  color: Colors.redAccent,
                ),
              if (avance != null)
                _statItem(
                  label: l10n.advance,
                  value: avance!,
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
              if (credit != null)
                _statItem(
                  label: l10n.credit,
                  value: credit!,
                  icon: Icons.arrow_downward,
                  color: Colors.orange,
                ),
              if (solde != null)
                _statItem(
                  label: l10n.balance,
                  value: solde!,
                  icon: Icons.account_balance_wallet,
                  color: solde! >= 0 ? Colors.green : Colors.red,
                  highlight: true,
                ),
            ],
          ),

          const Spacer(),

          // ================== RIGHT ==================
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _infoLine(Icons.location_on, wilaya),
              const SizedBox(height: 6),
              _infoLine(Icons.calendar_today, dateCreation),
              if (dateDernierAchat != null) ...[
                const SizedBox(height: 6),
                _infoLine(
                  Icons.shopping_bag_outlined,
                  "${l10n.lastPurchaseDate} : ${dateDernierAchat!.toString().split(" ").first}",
                ),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: onDetails,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  l10n.details,            // 🔥 Translated
                  style: TextStyle(color: Appstyle.Tblanc),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================== BADGE ÉTAT ==================
  Widget _etatBadge(AppLocalizations l10n) {  // 🔥 Accept l10n parameter
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: etat
            ? Colors.green.withOpacity(0.15)
            : Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        etat ? l10n.active : l10n.inactive,  // 🔥 Translated
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: etat ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  // ================== STAT ITEM ==================
  Widget _statItem({
    required String label,
    required double value,
    required IconData icon,
    required Color color,
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(
            "${value.toStringAsFixed(0)} DA",
            style: Appstyle.textMB.copyWith(
              color: highlight ? color : Appstyle.Tnoir,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: Appstyle.textSB),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Text(text, style: Appstyle.textSB),
      ],
    );
  }
}