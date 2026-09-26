import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../../data/models/besoinList.dart';
import '../../../data/models/smart_scan.dart';
import '../../../l10n/app_localizations.dart';

class AfficheurBesoinList extends StatelessWidget {
  final BesoinList list;
  final VoidCallback? onDetails;

  const AfficheurBesoinList({
    super.key,
    required this.list,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _container(
      Row(
        children: [

          /// 🔹 Icon
          _icon(Icons.list_alt, Colors.blue),

          /// 🔹 Infos
          Expanded(
            flex: 7,
            child: Row(
              children: [
                _info(l10n.code, list.code),                    // 🔥 Translated
                _info(l10n.number, list.numero),               // 🔥 Translated
                _info(l10n.articles, list.nombreArticle.toString()),  // 🔥 Translated
                _info(l10n.quantity, list.quantite.toString()),      // 🔥 Translated
                _info(l10n.amount, "${list.montant} DA"),      // 🔥 Translated
                _info(l10n.supplier, list.fournisseurCode),        // 🔥 Translated
                _info(l10n.state, list.etat ? l10n.active : l10n.inactive),  // 🔥 Translated
              ],
            ),
          ),

          const SizedBox(width: 16),

          /// 🔹 Bouton détails
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.details,  // 🔥 Translated
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
          offset: const Offset(0, 5),
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

Widget _info(String label, String value) {
  return Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}