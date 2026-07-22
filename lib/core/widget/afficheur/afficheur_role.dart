import 'package:flutter/material.dart';

import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/role.dart';
import '../../../../data/models/utilisateur.dart';
import '../../../../l10n/app_localizations.dart';

class AfficheurRole extends StatelessWidget {

  final Role role;
  final VoidCallback? onDetails;

  const AfficheurRole({
    super.key,
    required this.role,
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

          /// 🔹 Icône rôle
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.blueF.withOpacity(0.15),
                child: Icon(
                  Icons.admin_panel_settings,
                  size: 24,
                  color: Appstyle.blueF,
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
                  role.rolenom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${role.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  role.observation?.isNotEmpty == true
                      ? role.observation!
                      : l10n.noObservation,
                  style: TextStyle(color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                  l10n.status,
                  role.etat ? 1 : 0,
                  role.etat ? Colors.green : Colors.red,
                  isMoney: false,
                  customText: role.etat ? l10n.active : l10n.inactive,
                  l10n: l10n,
                ),
                FutureBuilder<List<Utilisateur>>(
                  future: UtilisateurServices.getUtilisateursByRoleCode(role.code),
                  builder: (context, snapshot) {
                    return _statCard(
                      l10n.userCount,
                      (snapshot.data?.length ?? 0).toDouble(),
                      Appstyle.blueF,
                      isMoney: false,
                      l10n: l10n,
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
                  Icons.badge,
                  role.code,
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

  /// 🟢 Badge état
  Widget _etatBadge(AppLocalizations l10n) {
    Color color = role.etat ? Colors.green : Colors.red;
    String label = role.etat ? l10n.active : l10n.inactive;

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

  /// 📊 Stat Card
  Widget _statCard(
      String label,
      double value,
      Color color, {
        bool isMoney = true,
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
                (isMoney
                    ? "${value.toStringAsFixed(0)} ${l10n.currency}"
                    : value.toStringAsFixed(0)),
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