import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/smart_scan.dart';
import '../../../l10n/app_localizations.dart';

class AfficheurSmartScan extends StatelessWidget {
  final SmartScan scan;
  final VoidCallback? onDetails;

  const AfficheurSmartScan({
    super.key,
    required this.scan,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _container(
      Row(
        children: [

          /// 🔹 Icon
          _icon(Icons.qr_code_scanner, Colors.deepPurple),

          /// 🔹 Infos
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _info(l10n.code, scan.code, l10n),
                _info(l10n.amount, "${scan.montant} ${l10n.currency}", l10n),
                _info(l10n.products, scan.nbrProduit.toString(), l10n),
                _info(l10n.quantity, scan.quantiteArticle.toString(), l10n),
                _info(l10n.supplier, scan.fournisseur, l10n),
                _info(l10n.status, scan.etat ? l10n.active : l10n.inactive, l10n),
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// 🔹 Bouton détails
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.details,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _container(Widget child) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );
}

Widget _icon(IconData icon, Color color) {
  return Padding(
    padding: const EdgeInsets.only(right: 12),
    child: CircleAvatar(
      backgroundColor: color.withOpacity(0.15),
      child: Icon(icon, color: color),
    ),
  );
}

Widget _info(String label, String value, AppLocalizations l10n) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}