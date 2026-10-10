import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../data/models/client.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

String userName = AuthState().username!;
String userCode = AuthState().userCode!;

Future<List<String>?> DeleteClients({required List<Client> clients}) async {
  final db = await DbCreator.openDb();
  final services = ClientServices(db);

  for(var client in clients){
    services.deleteClient(client.id);
  }
}

Future<void> AnnulerClient(
    BuildContext context, List<Client> clientsSelectionnes)
{
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
                  imagePath: 'assets/icons/sidebar/client_icon.png',
                  text: l10n.deleteClients,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 Liste des clients sélectionnés
                    Text(
                      l10n.selectedClients,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        itemCount: clientsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final c = clientsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                              ),
                              child: Text(
                                "${l10n.clientNumber(c.id)} - ${l10n.name}: ${c.nom ?? '-'} - ${l10n.phone}: ${c.telephone ?? '-'}",
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
                      l10n.confirmDeleteClients,
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
                          kind: DialogKind.danger,
                          titre: l10n.deleteClients,
                          message: l10n.confirmDeleteClients,
                          onConfirmer: () async {
                            await DeleteClients(
                              clients: clientsSelectionnes,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.clientDetail,
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