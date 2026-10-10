import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../../data/models/mouvement.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurMouvement extends StatelessWidget {
  final Mouvement mouvement;
  final String nomProduit;
  final String? nomClient;
  final String? nomFournisseur;
  final VoidCallback? onDetails;

  const AfficheurMouvement({
    super.key,
    required this.mouvement,
    required this.nomProduit,
    this.nomClient,
    this.nomFournisseur,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
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

          /// 🔹 Type + état
          Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: _typeColor().withOpacity(0.15),
                child: Icon(
                  _typeIcon(),
                  color: _typeColor(),
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),

          const SizedBox(width: 14),

          /// 🔹 Produit
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nomProduit,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${mouvement.code}",
                  style: TextStyle(color: Appstyle.neutral500),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.type} : ${_getTranslatedType(mouvement.type, l10n)}",
                  style: TextStyle(color: _typeColor(), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          /// 🔹 Quantité & Prix
          Expanded(
            flex: 5,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _stat(l10n.quantity, mouvement.quantite, Appstyle.info, isMoney: false, l10n: l10n),
                _stat(l10n.purchasePrice, mouvement.prixAchat, Appstyle.warning, l10n: l10n),
                _stat(l10n.salePrice, mouvement.prixVente, Appstyle.success, l10n: l10n),
              ],
            ),
          ),

          /// 🔹 Client / Fournisseur
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (nomClient != null && nomClient!.isNotEmpty)
                  _infoLine(Icons.person, "${l10n.client} : $nomClient"),
                if (nomFournisseur != null && nomFournisseur!.isNotEmpty)
                  _infoLine(Icons.local_shipping, "${l10n.supplier} : $nomFournisseur"),
              ],
            ),
          ),

          /// 🔹 Date
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoLine(Icons.calendar_today, _formatDate(mouvement.date)),
                _infoLine(Icons.access_time, _formatHeure(mouvement.date)),
              ],
            ),
          ),

          /// 🔹 Bouton
          if (onDetails != null)
            ElevatedButton(
              onPressed: onDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: Appstyle.violet,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                ),
              ),
              child: Text(
                  l10n.details,
                  style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)
              ),
            ),
        ],
      ),
    );
  }

  // --------------------------------------------------

  String _getTranslatedType(String type, AppLocalizations l10n) {
    switch (type) {
      case "Vente":
        return l10n.vente;
      case "Retour":
        return l10n.retour;
      case "SmartScan":
        return "SmartScan"; // Keep as is or add to translations if needed
      default:
        return type;
    }
  }

  Color _typeColor() {
    switch (mouvement.type) {
      case "SmartScan":
        return Appstyle.primary;
      case "Vente":
        return Appstyle.success;
      case "Retour":
        return Appstyle.warning;
      default:
        return Colors.blueGrey;
    }
  }

  IconData _typeIcon() {
    switch (mouvement.type) {
      case "SmartScan":
        return Icons.qr_code_scanner;
      case "Vente":
        return Icons.shopping_cart;
      case "Retour":
        return Icons.undo;
      default:
        return Icons.swap_horiz;
    }
  }

  Widget _etatBadge(AppLocalizations l10n) {
    Color color = mouvement.etat ? Appstyle.success : Appstyle.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
      ),
      child: Text(
        mouvement.etat ? l10n.valide : l10n.annule,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _stat(String label, double value, Color color,
      {bool isMoney = true, required AppLocalizations l10n}) {
    return Container(
      width: 90,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            isMoney ? "${NumberFormatUtil.formatMontant(value, decimales: 0)} ${l10n.currency}" : NumberFormatUtil.formatMontant(value, decimales: 0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoLine(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Appstyle.gris),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) =>
      DateFormat("dd/MM/yyyy").format(date);

  String _formatHeure(DateTime date) =>
      DateFormat("HH:mm").format(date);
}