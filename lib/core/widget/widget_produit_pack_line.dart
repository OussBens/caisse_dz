import 'package:flutter/material.dart';
import '../../../core/theme/app_style.dart';
import '../../../data/models/produit.dart';
import '../../../data/models/produit_pack_detail.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class ProduitPackLineWidget extends StatelessWidget {
  final ProduitPackDetail detail;
  final Produit produit;
  final VoidCallback onDelete;
  final Function(double) onPrixChanged;
  final Function(int) onQuantiteChanged;

  const ProduitPackLineWidget({
    Key? key,
    required this.detail,
    required this.produit,
    required this.onDelete,
    required this.onPrixChanged,
    required this.onQuantiteChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Code produit
          Expanded(
            flex: 2,
            child: Text(produit.code, style: Appstyle.textSB),
          ),
          // Nom produit
          Expanded(
            flex: 3,
            child: Text(produit.nom, style: Appstyle.textSB),
          ),
          // Prix unitaire
          Expanded(
            flex: 2,
            child: SizedBox(
              width: 100,
              child: TextFormField(
                initialValue: detail.prixUnitaire.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.unitPrice,
                  labelStyle: const TextStyle(fontSize: 12),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final prix = double.tryParse(value) ?? 0;
                  onPrixChanged(prix);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quantité
          Expanded(
            flex: 1,
            child: SizedBox(
              width: 80,
              child: TextFormField(
                initialValue: detail.quantite.toString(),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: l10n.quantity,
                  labelStyle: const TextStyle(fontSize: 12),
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                ),
                onChanged: (value) {
                  final qte = int.tryParse(value) ?? 1;
                  onQuantiteChanged(qte);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Montant
          Expanded(
            flex: 2,
            child: Text(
              '${NumberFormatUtil.formatMontant(detail.montant, decimales: 2)} ${l10n.currency}',
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          // Bouton supprimer
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}