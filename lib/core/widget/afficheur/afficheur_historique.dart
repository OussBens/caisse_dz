import 'package:flutter/material.dart';
import '../../../data/models/histore.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class AfficheurHistorique extends StatelessWidget {
  final Historique historique;
  final VoidCallback? onDetails;

  const AfficheurHistorique({
    super.key,
    required this.historique,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
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

          /// 🔹 Icône Operation
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: _operationColor().withOpacity(0.15),
                child: Icon(
                  _operationIcon(),
                  color: _operationColor(),
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              _typeBadge(),
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
                  historique.code,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  historique.observation ?? "",
                  style: TextStyle(color: Appstyle.ink500),
                ),
                if (historique.observation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "${l10n.obs}: ${historique.observation}",  // 🔥 Translated
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Appstyle.gris,
                    ),
                  ),
                ],
              ],
            ),
          ),

          /// 🔹 Infos droite
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.category, historique.type),
                _infoLine(Icons.person, historique.creeParCode),
                _infoLine(
                  Icons.calendar_today,
                  "${historique.dateCree.day}/${historique.dateCree.month}/${historique.dateCree.year}",
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
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Appstyle.radiusMD),
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

  /// 🎨 Couleur selon type
  Color _typeColor() {
    switch (historique.oper) {
      case "création":
        return Appstyle.success;
      case "modification":
        return Appstyle.warning;
      case "suppression":
        return Appstyle.danger;
      default:
        return Appstyle.gris;
    }
  }

  /// 🏷 Badge type
  Widget _typeBadge() {
    final color = _typeColor();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
      ),
      child: Text(
        historique.oper.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 🎨 Couleur selon opération
  Color _operationColor() {
    switch (historique.type) {
      case "Client":
        return Appstyle.info;
      case "Produit":
        return Appstyle.primary;
      case "Fournisseur":
        return Appstyle.successInk;
      case "Facture":
        return Appstyle.primary;
      case "Caisse":
        return Appstyle.warningInk;
      case "Panier":
        return Colors.deepOrange;
      default:
        return Appstyle.gris;
    }
  }

  /// 🔹 Icône selon opération
  IconData _operationIcon() {
    switch (historique.type) {
      case "Client":
        return Icons.person;
      case "Produit":
        return Icons.inventory_2;
      case "Fournisseur":
        return Icons.local_shipping;
      case "Facture":
        return Icons.receipt_long;
      case "Caisse":
        return Icons.account_balance_wallet;
      case "Panier":
        return Icons.shopping_cart;
      default:
        return Icons.history;
    }
  }

  /// ℹ Ligne info
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
}