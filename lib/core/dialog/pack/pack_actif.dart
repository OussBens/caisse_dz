import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/pack.dart';
import '../../dialog/confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> DeletePack({required List<Pack> packs, required String userName, required String userCode}) async {
  final db = await DbCreator.openDb();
  final services = ProduitPackDetailServices(db);

  for (var pack in packs) {
    // 1️⃣ supprimer les détails du pack
    await services.deleteAllDetailes(pack.code);

    final int id2 = await _GetNextHistoriqueId();
    final Historique hist2 = Historique(
      id: id2,
      code: "HS$id2 ${DateTime.now().microsecondsSinceEpoch}",
      desc: "l'utilisateur $userName a supprimé tous les ProduitPackDetail du pack ${pack.nom}",
      oper: ListsConst.typeHisto[3],
      type: "ProduitPackDetail",
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    final db = await DbCreator.openDb();
    final serviceh = HistoriqueServices(db);
    await serviceh.addHistorique(hist2);

    // 2️⃣ supprimer le pack
    await PackServices.deletePack(pack.id);

    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "l'utilisateur $userName a supprimé le pack ${pack.nom}",
      oper: ListsConst.typeHisto[3],
      type: "Pack",
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await serviceh.addHistorique(histo);
  }
}

Future<void> ActiverPack(BuildContext context, List<Pack> packsSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

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
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/action/supprimer_icon.png',
                  text: l10n.reactivatePack,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Liste des packs sélectionnés
                    Text(
                      l10n.selectedPacks,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: packsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final p = packsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${p.nom} (${p.code})",
                                style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    // 🔹 Message de confirmation
                    Text(
                      l10n.confirmReactivatePacks,
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.delete,
                      color: Appstyle.violet,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.deletePacks,
                          message: l10n.confirmDeletePacks,
                          onConfirmer: () async {
                            await DeletePack(
                              packs: packsSelectionnes,
                              userCode: userCode,
                              userName: userName,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.pack,
                              message: l10n.deleteSuccess,
                              onTerminer: (){Navigator.pop(context);},
                            );
                          },
                        );
                      },
                      icon: Icons.delete,
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