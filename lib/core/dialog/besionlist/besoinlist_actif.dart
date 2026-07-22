import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../Services/BesionList.dart';
import '../../../Services/BesionListDetail.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> _DeleteBL({
  required List<BesoinList> besions,
  required String           userName,
  required String           userCode,
}) async {
  final db        = await DbCreator.openDb();
  final services  = BesoinListServices(db);
  final serviceh  = HistoriqueServices(db);
  final serviceD  = BesoinListDetailServices(db);
  List<BesoinListDetail> detailes = [];

  for(var Besion in besions){
    detailes  = await serviceD.getBesoinListDetailByBLCode(Besion.code);
    for(var detail in detailes){
      await serviceD.deletebesion_list_detail(detail.id);
      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
          id          : idh,
          code        : "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type        : "besion_list_detail",
          desc        : "L'utilisateur $userName a Supprimer Le Besion List Detail ${detail.ProduitNom} de Besion List${Besion.numero}",
          oper        : ListsConst.typeHisto[2],
          creePar     : userName,
          dateCree    : DateTime.now(),
          creeParCode : userCode
      );
      await serviceh.addHistorique(histo);
    }
    await services.deletebesionList(Besion.id);
    int idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id          : idh,
        code        : "HS$idh${DateTime.now().millisecondsSinceEpoch}",
        type        : "besionList",
        desc        : "L'utilisateur $userName a Supprimer Le Besion List ${Besion.numero}",
        oper        : ListsConst.typeHisto[2],
        creePar     : userName,
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceh.addHistorique(histo);
  }
}

Future<void> BesoinListActifDialog(BuildContext context, List<BesoinList> besoinsSelectionnes) async{
  final auth      = Provider.of<AuthState>(context, listen: false);
  final userName  = auth.username;
  final userCode  = auth.userCode;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content         : Text(AppLocalizations.of(context)!.loginRequired),
        duration        : const Duration(seconds: 3),
        backgroundColor : Colors.red,
      ),
    );
    return;
  }

  return showDialog(
    barrierDismissible: false,
    context: context,
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
                height: 450,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/liste_icon.png',
                  text: l10n.deleteNeeds,
                ),

                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedNeeds,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Appstyle.Tnoir,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🔹 Liste des besoins
                    Expanded(
                      child: ListView.builder(
                        itemCount: besoinsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final b = besoinsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "${l10n.code}: ${b.code} - Numéro: ${b.numero}",
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
                      l10n.confirmDeleteNeeds,
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
                      onPressed: () async{
                        await _DeleteBL(besions: besoinsSelectionnes, userName: userName!, userCode: userCode!);
                        Navigator.pop(context);
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