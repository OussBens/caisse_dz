import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Zakat.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/zakat.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteZakawat({
  required List<Zakat> zakawat,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await ZakatServices(db);
  final serviceh = await HistoriqueServices(db);

  for (var zakat in zakawat) {
    await services.deleteZakat(zakat.id);
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
      id: idh,
      code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type: 'zakat',
      desc: "L'utilisateur $userName supprimer Zakat de l'annee ${zakat.annee}",
      oper: ListsConst.typeHisto[3],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }
}

Future<void> AnnulerZakat(
    BuildContext context,
    List<Zakat> zakatsSelectionnees,
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

  final zakatsPayees = zakatsSelectionnees.where((z) => z.datePaiement != null).toList();
  final bool hasZakatsPayees = zakatsPayees.isNotEmpty;

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
                  imagePath: 'assets/icons/sidebar/zakat_icon.png',
                  text: l10n.deleteZakat,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedZakats,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: zakatsSelectionnees.length,
                        itemBuilder: (context, index) {
                          final z = zakatsSelectionnees[index];
                          final bool estPayee = z.datePaiement != null;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: estPayee
                                    ? Colors.red.withOpacity(0.1)
                                    : Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.zakat} ${z.code} | ${l10n.year}: ${z.annee} | "
                                    "${l10n.amount}: ${NumberFormatUtil.formatMontant(z.montantZakat, decimales: 2)} ${l10n.currency}"
                                    "${estPayee ? " (${l10n.alreadyPaid})" : ""}",
                                style: Appstyle.textSB.copyWith(
                                  color: estPayee
                                      ? Colors.red
                                      : Appstyle.Tnoir,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text(
                      hasZakatsPayees
                          ? l10n.cannotDeletePaidZakat
                          : l10n.confirmDeleteZakats,
                      style: Appstyle.textS.copyWith(
                        color: hasZakatsPayees
                            ? Colors.red
                            : Appstyle.TgrisC,
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.confirm,
                      color: hasZakatsPayees ? Appstyle.gris : Appstyle.violet,
                      icon: Icons.delete,
                      onPressed: () async {
                        if (hasZakatsPayees) return;

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.zakat,
                          message: l10n.confirmDeleteZakats,
                          onConfirmer: () async {
                            await _DeleteZakawat(
                              zakawat: zakatsSelectionnees,
                              userCode: userCode,
                              userName: userName,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.zakat,
                              message: l10n.zakatsDeletedSuccess,
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