import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Carte "afficheur" d'un magasin sélectionné — même structure que
/// AfficheurCaisseGestion (module Gestion Caisse) : icône, infos
/// principales, stats, bouton détails.
class AfficheurMagasin extends StatelessWidget {
  final Magasin magasin;
  final List<TransfertMagasin> transferts;
  final VoidCallback? onDetails;

  const AfficheurMagasin({
    super.key,
    required this.magasin,
    this.transferts = const [],
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Transferts actifs (non annulés) où ce magasin est source ou destination.
    final nombreTransferts = transferts
        .where((t) => t.etat && (t.magasinSourceCode == magasin.code || t.magasinDestCode == magasin.code))
        .length;

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
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.violet.withOpacity(0.15),
                child: Icon(
                  Icons.storefront_outlined,
                  size: 24,
                  color: Appstyle.violet,
                ),
              ),
              const SizedBox(height: 6),
              _etatBadge(l10n),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  magasin.nom,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.code} : ${magasin.code}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
                const SizedBox(height: 4),
                Text(
                  "${l10n.address} : ${magasin.adresse ?? '-'}",
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(l10n.state, magasin.etat ? l10n.active : l10n.inactive,
                    magasin.etat ? Colors.green : Colors.red),
                _statCard(l10n.transfers, nombreTransferts.toString(), Appstyle.violet),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              l10n.details,
              style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc),
            ),
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n) {
    final color = magasin.etat ? Colors.green : Colors.red;
    final label = magasin.etat ? l10n.active : l10n.inactive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statCard(String label, String value, Color color) {
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
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
