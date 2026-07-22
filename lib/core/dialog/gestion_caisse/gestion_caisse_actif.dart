import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../data/models/gestion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteCaisse({
  required  List<CaisseGestion> caisses,
  required  String userName,
  required  String userCode,
}) async {
  final db        = await DbCreator.openDb();
  final services  = await GCServices(db);
  final serviceH  = await HistoriqueServices(db);

  for(var caisse in caisses){
    await services.deleteCaisse(caisse.id);
    int id = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id          : id,
        code        : "HS$id${DateTime.now().microsecondsSinceEpoch}",
        type        : 'caisseGestion',
        desc        : "l'utilisateur $userName a supprimer la caisse ${caisse.nomCaisse}",
        oper        : ListsConst.typeHisto[3],
        creePar     : userName,
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceH.addHistorique(histo);
  }
}

Future<void> AnnulerCaisseGestion(
    BuildContext context,
    List<CaisseGestion> caissesSelectionnees,
    ) async {
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
                  imagePath: 'assets/icons/sidebar/caisse_icon.png',
                  text: l10n.deleteCashRegisters,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Liste des caisses sélectionnées
                    Text(
                      l10n.selectedCashRegisters,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: caissesSelectionnees.length,
                        itemBuilder: (context, index) {
                          final c = caissesSelectionnees[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.cashRegisterNumber(c.id)} "
                                    "- ${l10n.code} : ${c.code} "
                                    "- ${l10n.name} : ${c.nomCaisse} "
                                    "- ${l10n.store} : ${c.magasin}",
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
                      l10n.confirmDeleteCashRegisters,
                      style: Appstyle.textS.copyWith(
                        color: Appstyle.TgrisC,
                      ),
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
                      icon: Icons.block,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.deleteCashRegisters,
                          message: l10n.confirmDeleteCashRegisters,
                          onConfirmer: () async {
                            await _DeleteCaisse(
                              caisses: caissesSelectionnees,
                              userName: userName,
                              userCode: userCode,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.cashRegisterDetail,
                              message: l10n.deleteSuccess,
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