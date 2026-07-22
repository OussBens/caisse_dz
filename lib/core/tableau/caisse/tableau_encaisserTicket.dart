import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import '../../tableau/caisse/tableau_caisse.dart';

class TableauEncaissementTicket extends StatelessWidget {
  final double height;
  final List<ProduitPanier> produits;
  final double? remiseValue;      // ✅ Valeur de la remise (montant déduit)
  final bool remiseActive;        // ✅ Si la remise est active
  final String? remiseNom;        // ✅ Nom de la remise

  const TableauEncaissementTicket({
    super.key,
    required this.height,
    required this.produits,
    this.remiseValue,
    this.remiseActive = false,
    this.remiseNom,
  });

  double get total => produits.fold(0.0, (s, p) => s + p.montant);

  // ✅ Calcul du total après remise
  double get totalApresRemise {
    if (remiseActive && remiseValue != null && remiseValue! > 0) {
      return total - remiseValue!;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Appstyle.indigo, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          /// HEADER FIXE
          Container(
            color: Appstyle.indigo,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              children: [
                Expanded(flex: 2, child: Text(l10n.code, style: const TextStyle(color: Colors.white))),
                Expanded(flex: 3, child: Text(l10n.product, style: const TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text(l10n.parcel, style: const TextStyle(color: Colors.white))),
                Expanded(flex: 2, child: Text(l10n.price, style: const TextStyle(color: Colors.white))),
                Expanded(flex: 1, child: Text(l10n.qty, style: const TextStyle(color: Colors.white))),
                Expanded(flex: 1, child: Text(l10n.actualQty, style: const TextStyle(color: Colors.white, fontSize: 11))),
                Expanded(flex: 2, child: Text(l10n.amount, style: const TextStyle(color: Colors.white))),
              ],
            ),
          ),

          /// LISTE DES PRODUITS SCROLLABLE
          SizedBox(
            height: height,
            child: ListView.builder(
              itemCount: produits.length,
              itemBuilder: (context, index) {
                final p = produits[index];
                final quantiteReelle = p.quantiteReelleEnPieces;
                final isEmballage = p.piecesParEmballage != null && p.piecesParEmballage! > 1;

                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Appstyle.indigo.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(p.code, style: Appstyle.textpop_S)),
                      Expanded(flex: 3, child: Text(p.nom, style: Appstyle.textpop_S)),
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: isEmballage ? Appstyle.indigo.withOpacity(0.1) : null,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.colis.isEmpty ? "---" : p.colis,
                            style: Appstyle.textpop_S.copyWith(
                              color: isEmballage ? Appstyle.indigo : Appstyle.TgrisF,
                              fontStyle: p.colis.isNotEmpty ? FontStyle.italic : FontStyle.normal,
                              fontWeight: isEmballage ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                      Expanded(flex: 2, child: Text("${p.prix.toStringAsFixed(2)}", style: Appstyle.textpop_S)),
                      Expanded(flex: 1, child: Text(p.qte.toString(), style: Appstyle.textpop_SB)),
                      Expanded(
                        flex: 1,
                        child: Text(
                          quantiteReelle.toInt().toString(),
                          style: Appstyle.textpop_S.copyWith(
                            color: isEmballage ? Colors.orange.shade700 : Appstyle.TgrisF,
                            fontWeight: isEmballage ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      Expanded(flex: 2, child: Text("${p.montant.toStringAsFixed(2)}", style: Appstyle.textpop_SB)),
                    ],
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 10),
          Divider(thickness: 1.5, color: Appstyle.indigo),
          const SizedBox(height: 8),
          /// RÉCAP TOTAL AVEC REMISE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // ✅ Afficher la remise si elle est active
                if (remiseActive && remiseValue != null && remiseValue! > 0)
                  Text(
                    "${l10n.discount} : -${remiseValue!.toStringAsFixed(2)} ${l10n.currency}",
                    style: Appstyle.textpop_S.copyWith(color: Colors.green),
                  ),

                // ✅ Afficher le TOTAL (avant remise) - devient "Total" ou "Sous-total"
                if (remiseActive && remiseValue != null && remiseValue! > 0)
                  Text(
                    "${l10n.totalBeforeDiscount} : ${total.toStringAsFixed(2)} ${l10n.currency}",
                    style: Appstyle.textpop_S.copyWith(
                      color: Appstyle.TgrisF,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),

                const SizedBox(height: 4),

                // ✅ TOTAL FINAL (après remise)
                Text(
                  "${l10n.totalFinal} : ${totalApresRemise.toStringAsFixed(2)} ${l10n.currency}",
                  style: Appstyle.textpop_LB.copyWith(
                    fontSize: 18,
                    color: remiseActive && remiseValue != null && remiseValue! > 0
                        ? Colors.green
                        : Appstyle.TgrisF,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}