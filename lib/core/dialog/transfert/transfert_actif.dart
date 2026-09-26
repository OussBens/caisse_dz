import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/TransfertCaisse.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/transfert.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _deleteTransferts(List<TransfertCaisse> transferts) async {
  final db = await DbCreator.openDb();
  final services = TransfertcaisseServices(db);
  int i = 0;
  for (var transfert in transferts) {
    await services.deleteTransfertcaisse(transfert.id);
    i++;
  }
  return i;
}

Future<void> AnnulerTransfertCaisse(
    BuildContext context,
    List<TransfertCaisse> transfertsSelectionnes,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredDelete,
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
                width: 900,
                height: 520,
                header: TitreAvecLigne(
                  imagePath: "assets/icons/cardwidget/transfert_icon.png",
                  text: l10n.cancelTransfers,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedTransfers,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: transfertsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final t = transfertsSelectionnes[index];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.transferHash} #${t.id ?? '-'} "
                                    "- ${l10n.code}: ${t.code} "
                                    "- ${l10n.from}: ${t.caisseExpCode} "
                                    "- ${l10n.to}: ${t.caisseDestCode} "
                                    "- ${l10n.amount}: ${NumberFormatUtil.formatMontant(t.montant, decimales: 2)} ${l10n.currency} "
                                    "- ${l10n.date}: ${t.dateTransfert.toLocal().toString().split(' ')[0]}",
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
                      "${l10n.confirmCancelTransfers}\n${l10n.irreversibleOperation}",
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
                      text: l10n.close,
                      color: Appstyle.gris,
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.cancelTransfers,
                      color: Appstyle.violet,
                      icon: Icons.block,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.transfers,
                          message: l10n.confirmCancelTransfers,
                          onConfirmer: () async {
                            final response = await _deleteTransferts(transfertsSelectionnes);

                            if (response == 0) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.information,
                                titre_concerne: l10n.transfers,
                                message: l10n.noTransferSelected ?? "Aucun transfert sélectionné !",
                              );
                              return;
                            }

                            await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.transfers,
                                message: l10n.transfersCancelledSuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                }
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