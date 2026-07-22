import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/produit.dart';
import '../../dialog//confirmation_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';

List<Pack> packsTest = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextPackDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitPackDetailServices.getNextId(txn);
  });
  return id;
}

Future<void> loadAllData() async {
  try {
    final pack = await PackServices.getAllPacks();
    packsTest = pack;
  } catch (e) {
    debugPrint("Erreur chargement : $e");
  }
}

Map<String, List<String>> produitPacksMap = {};

Future<void> loadProduitPackMap() async {
  final details = await ProduitPackDetailServices.getAllDetails();
  produitPacksMap.clear();
  for (var d in details) {
    if (!produitPacksMap.containsKey(d.produitCode)) {
      produitPacksMap[d.produitCode] = [];
    }
    produitPacksMap[d.produitCode]!.add(d.packNom);
  }
}

Future<void> _saveProduitPackDetailes({
  required Produit produit,
  required Pack pack,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = await ProduitPackDetailServices(db);

  final ProduitPackDetail detail = ProduitPackDetail(
    packNom: pack.nom,
    packCode: pack.code,
    produitNom: produit.nom,
    produitCode: produit.code,
    dateCree: DateTime.now(),
    id: await _GetNextPackDetailId(),
    creeParCode: userCode, prixUnitaire: produit.prixVente, quantite: 1, montant: produit.prixVente,
  );

  await service.addProduitPackDetail(detail);
}

Future<void> _saveProccess({
  required BuildContext context,
  required List<Produit> produits,
  required Pack pack,
  required String userName,
  required String userCode,
}) async {
  try {

    final l10n = AppLocalizations.of(context)!;
    final db = await DbCreator.openDb();
    final serviceh = await HistoriqueServices(db);
    final packService = PackServices(db);
    int addedCount = 0;

    for (var produit in produits) {
      final packsProduit = produitPacksMap[produit.code] ?? [];

      if (packsProduit.contains(pack.nom)) {
        continue;
      }

      await _saveProduitPackDetailes(
        produit: produit,
        pack: pack,
        userName: userName,
        userCode: userCode,
      );
      addedCount++;

      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "L'utilisateur $userName a ajouté le pack ${pack.nom} au produit ${produit.nom}",
        type: "ProduitPackDetail",
        oper: ListsConst.typeHisto[1],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );

      await serviceh.addHistorique(histo);
    }

    await InformationDialog(
      context: context,
      titre_type_message: l10n.success,
      titre_concerne: l10n.pack,
      message: l10n.packAppliedSuccess,
    );
  } catch (e) {

    final l10n = AppLocalizations.of(context)!;
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      titre_concerne: l10n.pack,
      message: "$l10n.errorOccurred: $e",
    );
  }
}

Future<void> PackProduit(BuildContext context, List<Produit> produitsSelectionnes) async {
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

  Pack? selectedpack;
  await loadAllData();
  await loadProduitPackMap();

  String? selectedPack;
  if (packsTest.isNotEmpty) {
    selectedPack = packsTest.first.nom;
    selectedpack = packsTest.first;
  }

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final List<String> packNames =
          packsTest.map((p) => p.nom ?? "").where((e) => e.isNotEmpty).toSet().toList();
          final String? safeValue = packNames.contains(selectedPack) ? selectedPack : null;

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 800,
                height: 500,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/pack_icon.png',
                  text: l10n.applyPack,
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
                          final packs = produitPacksMap[p.code] ?? [];
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
                                      "${p.nom} (${p.code})",
                                      style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
                                    ),
                                  ),
                                  if (packs.isNotEmpty)
                                    Text(
                                      packs.join(" | "),
                                      style: Appstyle.textSB.copyWith(
                                        color: Appstyle.violet,
                                        fontWeight: FontWeight.bold,
                                      ),
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
                      l10n.pleaseSelectPack,
                      style: Appstyle.textS.copyWith(color: Appstyle.TgrisC),
                    ),
                    const SizedBox(height: 20),
                    ChampAvecLabel(
                      label: l10n.pack,
                      child: TextListe(
                        value: safeValue,
                        items: packNames,
                        onChanged: (v) {
                          setState(() {
                            selectedPack = v;
                            selectedpack = packsTest.firstWhere((p) => p.nom == v);
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
                        if (selectedpack == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.pack,
                            message: l10n.pleaseSelectPack,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.confirmation,
                          message: l10n.confirmApplyPack(selectedpack!.nom, produitsSelectionnes.length),
                          onConfirmer: () async {
                            await _saveProccess(
                              context: context,
                              produits: produitsSelectionnes,
                              pack: selectedpack!,
                              userCode: userCode,
                              userName: userName,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.product,
                              message: l10n.packAppliedSuccess,
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