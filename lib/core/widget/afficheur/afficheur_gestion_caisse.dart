import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurCaisseGestion extends StatelessWidget {

  final CaisseGestion caisse;
  final VoidCallback? onDetails;

  const AfficheurCaisseGestion({
    super.key,
    required this.caisse,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(

      padding: const EdgeInsets.all(8),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),

        boxShadow: [
          BoxShadow(
            color: Appstyle.shadowTint.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),

      child: Row(
        children: [

          /// 🔹 Icône caisse
          Column(
            children: [

              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.success.withOpacity(0.15),

                child: const Icon(
                  Icons.point_of_sale,
                  size: 24,
                  color: Appstyle.success,
                ),
              ),

              const SizedBox(height: 6),

              _etatBadge(l10n),  // 🔥 Pass l10n

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
                  caisse.nomCaisse,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  "${l10n.code} : ${caisse.code}",  // 🔥 Translated
                  style: TextStyle(color: Appstyle.ink500),
                ),

                const SizedBox(height: 4),

                Text(
                  "${l10n.store} : ${caisse.magasinCode}",  // 🔥 Translated
                  style: TextStyle(color: Appstyle.ink500),
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
                  l10n.initialBalance,  // 🔥 Translated
                  caisse.soldeInitial,
                  Appstyle.success,
                  suffix: " DA",
                ),

                _statCard(
                  l10n.type,  // 🔥 Translated
                  0,
                  _getTypeColor(caisse.typecaisse),
                  customText: caisse.typecaisse,
                ),

                _statCard(
                  l10n.state,  // 🔥 Translated
                  caisse.etat ? 1 : 0,
                  caisse.etat ? Appstyle.success : Appstyle.danger,
                  customText: caisse.etat ? l10n.active : l10n.inactive,  // 🔥 Translated
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

                _infoLine(Icons.store, caisse.magasinCode),

                _infoLine(Icons.badge, caisse.code),

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
                borderRadius: BorderRadius.circular(Appstyle.radiusMD),
              ),
            ),

            child: Text(
              l10n.details,  // 🔥 Translated
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
  Widget _etatBadge(AppLocalizations l10n) {  // 🔥 Accept l10n parameter

    Color color = caisse.etat ? Appstyle.success : Appstyle.danger;

    String label = caisse.etat ? l10n.active : l10n.inactive;  // 🔥 Translated

    return Container(

      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 4,
      ),

      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
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
        String? suffix,
        String? customText,
      }) {

    return Container(

      width: 140,

      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      ),

      child: Column(
        children: [

          Text(label, style: TextStyle(color: color)),

          const SizedBox(height: 6),

          Text(
            customText ??
                "${NumberFormatUtil.formatMontant(value, decimales: 0)}${suffix ?? ""}",

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

          Icon(icon, size: 16, color: Appstyle.gris),

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

  /// Couleur type caisse
  Color _getTypeColor(String type) {

    switch (type.toLowerCase()) {

      case "principale":
        return Appstyle.success;

      case "secondaire":
        return Appstyle.warning;

      default:
        return Appstyle.info;

    }

  }

}