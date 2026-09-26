import 'package:flutter/material.dart';
import '../../../data/models/verssement.dart';
import '../../../l10n/app_localizations.dart';
import '../../theme/app_style.dart';

class AfficheurVersement extends StatelessWidget {
  final Verssement versement;
  final String nomBeneficiaire;
  final VoidCallback? onDetails;

  const AfficheurVersement({
    super.key,
    required this.versement,
    required this.nomBeneficiaire,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return _container(
      Row(
        children: [
          _icon(Icons.payments_outlined, Colors.teal),

          Expanded(
            flex: 7,
            child: Row(
              children: [
                _info(l10n.code, versement.code, l10n),
                _info(l10n.montant, "${versement.montant} ${l10n.currency}", l10n),
                _info(l10n.sense, versement.sense, l10n),
                _info("Bénéficiaire", nomBeneficiaire, l10n),
                _info(l10n.type, versement.type, l10n),
                _info(l10n.status, versement.etat ? l10n.active : l10n.inactive, l10n),
              ],
            ),
          ),

          const SizedBox(width: 16),

          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.details,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
