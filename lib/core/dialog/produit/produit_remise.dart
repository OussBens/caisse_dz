import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/produit.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

List<Remise> remisesTest = [];

String? _nomRemise(int? id) =>
    remisesTest.where((r) => r.id == id).firstOrNull?.nom;

Future<void> loadAllData() async {
  try {
    final packtest = await RemiseServices.getAllRemise();
    remisesTest = packtest;
  } catch (e) {
    debugPrint("Erreur chargement : $e");
  }
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _updateProduit({
  required List<Produit> produits,
  required Remise remise,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = ProduitServices(db);
  final serviceh = HistoriqueServices(db);
  final remiseService = RemiseServices(db);

  ApiResponse<int>? lastResponse;

  for (var produit in produits) {
    produit.remiseId = remise.id;
    produit.modifParCode = userCode;
    produit.dateModif = DateTime.now();
    lastResponse = await services.updateProduit(produit);

    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur ${userName} Ajoutee la Remise ${remise.nom} a le Produit ${produit.nom}",
        oper: ListsConst.typeHisto[1],
        type: "Produit",
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histo);
  }
  return lastResponse!;
}

Future<void> RemiseProduit(BuildContext context, List<Produit> produitsSelectionnes) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  await loadAllData();

  Remise? selectedRemiseObj;
  String? selectedRemise;

  if (remisesTest.isNotEmpty) {
    selectedRemiseObj = remisesTest.first;
    selectedRemise = selectedRemiseObj.nom;
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final List<String> remiseNames =
          remisesTest.map((r) => r.nom).where((e) => e.isNotEmpty).toSet().toList();
          final String? safeValue = remiseNames.contains(selectedRemise) ? selectedRemise : null;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/remise_icon.png',
                  text: l10n.applyDiscount,
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.selectedProducts,
                      style: TextStyle(fontWeight: FontWeight.w600, color: Appstyle.Tnoir),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: produitsSelectionnes.length,
                        itemBuilder: (context, index) {
                          final p = produitsSelectionnes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Appstyle.grisC.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "${p.code} (${p.nom})",
                                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                                    ),
                                  ),
                                  if (_nomRemise(p.remiseId) != null && _nomRemise(p.remiseId)!.isNotEmpty)
                                    Text(
                                      "${_nomRemise(p.remiseId)}",
                                      style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      l10n.pleaseSelectDiscount,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),
                    const SizedBox(height: 20),
                    ChampAvecLabel(
                      label: l10n.discount,
                      child: TextListe(
                        value: safeValue,
                        items: remiseNames,
                        onChanged: (v) {
                          setState(() {
                            selectedRemise = v;
                            selectedRemiseObj = remisesTest.firstWhere((r) => r.nom == v);
                          });
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
                      onPressed: () => Navigator.pop(context),
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.confirmation,
                          message: l10n.confirmApplyDiscount(selectedRemiseObj!.nom, produitsSelectionnes.length),
                          onConfirmer: () async {
                            final response = await _updateProduit(
                              produits: produitsSelectionnes,
                              remise: selectedRemiseObj!,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.product,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.product,
                              message: l10n.discountAppliedSuccess,
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