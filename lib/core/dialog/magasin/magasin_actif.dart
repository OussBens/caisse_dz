import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../data/models/magasin.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

Future<void> DeleteMagasins({required List<Magasin> magasins}) async {
  final db = await DbCreator.openDb();
  final services = MagasinServices(db);

  for (var magasin in magasins) {
    await services.deleteMagasin(magasin.id);
  }
}

Future<void> AnnulerMagasin(BuildContext context, List<Magasin> magasinsSelectionnes) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 700,
                height: 480,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.deleteStores,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedStores,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: magasinsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final m = magasinsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.storeNumber(m.id)} - ${l10n.name}: ${m.nom} - ${l10n.address}: ${m.adresse ?? '-'}",
                                style: Appstyle.textSB.copyWith(
                                  color: Appstyle.Tnoir,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      l10n.confirmDeleteStores,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),

                    const SizedBox(height: 20),
                  ],
                ),

                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),

                    MainButton(
                      text: l10n.delete,
                      color: Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.deleteStores,
                          message: l10n.confirmDeleteStores,
                          onConfirmer: () async {
                            await DeleteMagasins(magasins: magasinsSelectionnes);

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.storeDetail,
                              message: l10n.storeDeleteSuccess,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
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
