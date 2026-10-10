import 'package:collection/collection.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Carte "afficheur" d'un transfert (marchandise entre magasins)
/// sélectionné — même structure que AfficheurCaisseGestion/AfficheurMagasin.
class AfficheurTransfertMagasin extends StatelessWidget {
  final TransfertMagasin transfert;
  final List<Produit> produits;
  final List<Magasin> magasins;
  final VoidCallback? onDetails;

  const AfficheurTransfertMagasin({
    super.key,
    required this.transfert,
    required this.produits,
    required this.magasins,
    this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final nomProduit = produits.firstWhereOrNull((p) => p.code == transfert.produitCode)?.nom
        ?? transfert.produitCode;
    final nomSource = magasins.firstWhereOrNull((m) => m.code == transfert.magasinSourceCode)?.nom
        ?? transfert.magasinSourceCode;
    final nomDest = magasins.firstWhereOrNull((m) => m.code == transfert.magasinDestCode)?.nom
        ?? transfert.magasinDestCode;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        boxShadow: [
          BoxShadow(color: Appstyle.shadowTint.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          Column(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Appstyle.indigo.withOpacity(0.15),
                child: Icon(Icons.compare_arrows, size: 24, color: Appstyle.indigo),
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
                Text(nomProduit, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${l10n.code} : ${transfert.code}", style: TextStyle(color: Appstyle.ink500)),
                const SizedBox(height: 4),
                Text("$nomSource  →  $nomDest", style: TextStyle(color: Appstyle.ink500)),
              ],
            ),
          ),
          Expanded(
            flex: 9,
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _statCard(l10n.quantity, transfert.quantite.toStringAsFixed(0), Appstyle.violet),
                _statCard(l10n.transferDate, transfert.date.toString().split(" ").first, Appstyle.indigo),
              ],
            ),
          ),
          const SizedBox(width: 20),
          ElevatedButton(
            onPressed: onDetails,
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
            ),
            child: Text(l10n.details, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
          ),
        ],
      ),
    );
  }

  Widget _etatBadge(AppLocalizations l10n) {
    final color = transfert.etat ? Appstyle.success : Appstyle.danger;
    final label = transfert.etat ? l10n.active : l10n.inactive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(Appstyle.radiusCard)),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
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
