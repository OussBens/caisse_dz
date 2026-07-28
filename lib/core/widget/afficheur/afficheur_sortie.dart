import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/sortie.dart';
import '../../../l10n/app_localizations.dart';

class AfficheurSortie extends StatelessWidget {
  final Sortie sortie;
  final String nomProduit;
  final VoidCallback? onDetails;

  const AfficheurSortie({
    super.key,
    required this.sortie,
    required this.nomProduit,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _container(
      Row(
        children: [

          /// 🔹 Icon
          _icon(Icons.outbox, Colors.red),

          /// 🔹 Infos sortie
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _info(l10n.product, nomProduit, l10n),
                _info(l10n.quantity, sortie.quantite.toString(), l10n),
                _info(l10n.price, sortie.prix.toString(), l10n),
                _info(l10n.total, sortie.montant.toString(), l10n),
                _info(l10n.type, sortie.type, l10n),
                _info(l10n.status, sortie.etat ? l10n.active : l10n.inactive, l10n),
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