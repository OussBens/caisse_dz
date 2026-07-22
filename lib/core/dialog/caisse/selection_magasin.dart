// selection_magasin_dialog.dart - Version améliorée avec quantité demandée

import 'dart:ui';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

Future<ProduitMagasinDetail?> showMagasinSelectionDialogWithQuantity({
  required BuildContext context,
  required List<ProduitMagasinDetail> magasinsDisponibles,
  required List<Magasin> magasins,
  required String produitNom,
  required double quantiteDemandee,
}) async {
  final l10n = AppLocalizations.of(context)!;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 550,
                height: 450,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: "$produitNom - ${l10n.selectStore}",
                ),
                content: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Appstyle.violet.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${l10n.requestedQuantity}:",
                            style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Appstyle.violet,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${quantiteDemandee.toInt()} ${l10n.piece}",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        l10n.selectStoreForProduct + produitNom,
                        style: Appstyle.textSB,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: magasinsDisponibles.length,
                        itemBuilder: (context, index) {
                          final detail = magasinsDisponibles[index];
                          final bool isStockSuffisant = detail.quantite >= quantiteDemandee;
                          final magasinNom = magasins
                                  .firstWhereOrNull((m) => m.code == detail.magasinCode)
                                  ?.nom ??
                              detail.magasinCode;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                            elevation: 2,
                            color: isStockSuffisant ? Colors.white : Colors.orange.shade50,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isStockSuffisant
                                    ? Appstyle.violet.withOpacity(0.1)
                                    : Colors.orange.withOpacity(0.1),
                                child: Icon(
                                  Icons.store,
                                  color: isStockSuffisant ? Appstyle.violet : Colors.orange,
                                ),
                              ),
                              title: Text(
                                magasinNom,
                                style: Appstyle.textSB.copyWith(
                                  color: isStockSuffisant ? Colors.black : Colors.orange.shade800,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "${l10n.quantity}: ${detail.quantite.toInt()} ${l10n.piece}",
                                    style: Appstyle.textS.copyWith(
                                      color: isStockSuffisant ? Colors.grey.shade600 : Colors.orange.shade700,
                                      fontWeight: isStockSuffisant ? FontWeight.normal : FontWeight.bold,
                                    ),
                                  ),
                                  if (!isStockSuffisant)
                                    Text(
                                      "⚠️ Stock insuffisant",
                                      style: Appstyle.textS.copyWith(
                                        color: Colors.orange,
                                        fontSize: 11,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: isStockSuffisant
                                  ? Icon(Icons.check_circle, color: Appstyle.violet)
                                  : Icon(Icons.warning_amber, color: Colors.orange),
                              onTap: () => Navigator.pop(context, detail),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}