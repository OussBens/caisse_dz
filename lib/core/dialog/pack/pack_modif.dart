import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pack.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import '../insertion_produit.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

final TextEditingController packNomController = TextEditingController();
final TextEditingController packObserController = TextEditingController();
final TextEditingController packNombreController = TextEditingController();
final TextEditingController packQuantiteTotaleController = TextEditingController();
final TextEditingController packPrixController = TextEditingController();

List<ProduitPackDetail> produitsPackSelectionnes = [];
List<Produit> produitsTest = [];
List<ProduitPackDetail> orignal = [];
String? selectedEtatR;

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

Produit? _trouverProduitParCode(String code) {
  for (final p in produitsTest) {
    if (p.code == code) return p;
  }
  return null;
}

void _recalculerTotauxPackModif(void Function(void Function()) setState) {
  setState(() {
    int nombreProduits = produitsPackSelectionnes.length;
    int quantiteTotale = produitsPackSelectionnes.fold(0, (sum, item) => sum + item.quantite);
    double prixTotal = produitsPackSelectionnes.fold(0.0, (sum, item) => sum + item.montant);

    packNombreController.text = nombreProduits.toString();
    packQuantiteTotaleController.text = quantiteTotale.toString();
    packPrixController.text = prixTotal.toStringAsFixed(2);
  });
}

Widget _headerTableProduitsPackComplet(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(flex: 2, child: Text(l10n.code, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        Expanded(flex: 3, child: Text(l10n.product, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text(l10n.salePrice, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        Expanded(flex: 2, child: Text(l10n.unitPrice, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(flex: 1, child: Text(l10n.quantity, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        const SizedBox(width: 8),
        Expanded(flex: 2, child: Text(l10n.total, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold))),
        const SizedBox(width: 40),
      ],
    ),
  );
}

Widget _tableProduitsPackComplet(void Function(void Function()) setState, AppLocalizations l10n) {
  if (produitsPackSelectionnes.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAssociated,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Column(
    children: produitsPackSelectionnes.asMap().entries.map((entry) {
      int index = entry.key;
      ProduitPackDetail detail = entry.value;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(flex: 2, child: Text(detail.produitCode, style: Appstyle.textSB)),
            Expanded(flex: 3, child: Text(_trouverProduitParCode(detail.produitCode)?.nom ?? detail.produitCode, style: Appstyle.textSB)),
            Expanded(
              flex: 2,
              child: Text(
                '${NumberFormatUtil.formatMontant((_trouverProduitParCode(detail.produitCode)?.prixVente ?? 0), decimales: 2)} ${l10n.currency}',
                style: Appstyle.textSB,
              ),
            ),
            Expanded(
              flex: 2,
              child: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: detail.prixUnitaire.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      double prix = double.tryParse(value) ?? 0;
                      detail.prixUnitaire = prix;
                      detail.calculerMontant();
                      _recalculerTotauxPackModif(setState);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 1,
              child: SizedBox(
                width: 80,
                child: TextFormField(
                  initialValue: detail.quantite.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                  onChanged: (value) {
                    setState(() {
                      int qte = int.tryParse(value) ?? 1;
                      if (qte < 1) qte = 1;
                      detail.quantite = qte;
                      detail.calculerMontant();
                      _recalculerTotauxPackModif(setState);
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: Text(
                '${NumberFormatUtil.formatMontant(detail.montant, decimales: 2)} ${l10n.currency}',
                style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  produitsPackSelectionnes.removeAt(index);
                  _recalculerTotauxPackModif(setState);
                });
              },
            ),
          ],
        ),
      );
    }).toList(),
  );
}

void _ajouterProduitPackComplet(
    BuildContext context,
    void Function(void Function()) setState,
    Pack pack,
    AppLocalizations l10n,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      multiselection: true,
      newButton:false,
      produits: produitsTest,
      onProduitSelected: (produit) async {
        bool existeDeja = produitsPackSelectionnes.any(
              (p) => p.produitCode == produit.code,
        );

        if (!existeDeja) {
          int id = await _GetNextPackDetailId();

          setState(() {
            produitsPackSelectionnes.add(
              ProduitPackDetail(
                id: id,
                packCode: pack.code,
                produitCode: produit.code,
                prixUnitaire: produit.prixVente,
                quantite: 1,
                montant: produit.prixVente,
                dateCree: DateTime.now(),
                creeParCode: userCode,
              ),
            );
            _recalculerTotauxPackModif(setState);
          });
        } else {
          Future.microtask(() async {
            await InformationDialog(
              context: context,
              titre_type_message: l10n.error,
              titre_concerne: l10n.pack,
              message: l10n.productAlreadyAdded(produit.nom),
            );
          });
        }
      },
    ),
  );
}

Future<void> _UpdatePackDetailComplet({
  required List<ProduitPackDetail> produitsPack,
  required Pack pack,
  required List<ProduitPackDetail> original,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitPackDetailServices(db);
  final serviceh = HistoriqueServices(db);

  // Supprimer les produits qui ne sont plus dans le pack
  for (var produit in original) {
    bool existeToujours = produitsPack.any(
          (p) => p.produitCode == produit.produitCode,
    );

    if (!existeToujours) {
      await service.deleteDetailes(produit.produitCode, pack.code);

      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "Suppression de ${produit.produitCode} du pack ${pack.nom} par $userName",
        type: "ProduitPackDetail",
        oper: ListsConst.typeHisto[1],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histo);
    }
  }

  // Ajouter ou mettre à jour les produits
  for (var produit in produitsPack) {
    bool existeDansOriginal = original.any(
          (p) => p.produitCode == produit.produitCode,
    );

    if (!existeDansOriginal) {
      final response = await service.addProduitPackDetail(produit);

      if (response != 0) {
        final int idH = await _GetNextHistoriqueId();
        final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "Ajout de ${produit.produitCode} au pack ${pack.nom} par $userName",
          type: "ProduitPackDetail",
          oper: ListsConst.typeHisto[0],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await serviceh.addHistorique(histo);
      }
    } else {
      await service.updateDetail(produit);
    }
  }
}

Future<ApiResponse<int>> _savePack({required Pack pack}) async {
  final db = await DbCreator.openDb();
  final services = PackServices(db);

  final existingPack = await db.query(
    'packs',
    where: 'nom = ? AND id != ?',
    whereArgs: [pack.nom, pack.id],
  );

  if (existingPack.isNotEmpty) {
    return ApiResponse(
      success: false,
      message: "Un pack avec ce nom existe déjà",
    );
  }

  return await services.updatePack(pack);
}

Future<void> _loadProduits({required int id}) async {
  Pack? result = await PackServices.getPackById(id);
  final produit = await ProduitPackDetailServices.getDetailsByPackNom(result!.code);
  final prd = await ProduitServices.getAllProduits();

  produitsTest = prd;
  produitsPackSelectionnes = List.from(produit);
  orignal = List.from(produit);
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> PackModif(BuildContext context, Pack pack) async {
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

  await _loadProduits(id: pack.id);
  Pack Orignal = pack;

  // Pré-remplissage
  packNomController.text = pack.nom;
  packObserController.text = pack.observation ?? '';
  packQuantiteTotaleController.text = pack.quantiteTotale.toString();
  packPrixController.text = pack.prixVente.toStringAsFixed(2);

  produitsPackSelectionnes = produitsPackSelectionnes
      .where((e) => e.packCode == pack.code)
      .toList();
  selectedEtatR = pack.etat ? "Actif" : 'Inactif';

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
                width: 1100,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/pack_icon.png',
                  text: l10n.modifyPack,
                ),
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Colonne gauche
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChampAvecLabel(
                                    label: l10n.code,
                                    child: AffichageChamp(text: pack.code),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.status,
                                    child: TextListe(
                                      value: selectedEtatR,
                                      clearable: false,
                                      items: [l10n.active, l10n.inactive],
                                      onChanged: (v) => setState(() {
                                        selectedEtatR = v;
                                      }),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.name,
                                    obligatoire: true,
                                    child: TextChampL(
                                      obligatoire: true,
                                      controller: packNomController,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.observation,
                                    child: TextChampL(
                                      controller: packObserController,
                                      hint: '',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            // Colonne droite - Champs calculés
                            Expanded(
                              child: Column(
                                children: [
                                  ChampAvecLabel(
                                    label: l10n.numberOfItems,
                                    child: TextChampL(
                                      controller: packNombreController,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.totalQuantity,
                                    child: TextChampL(
                                      controller: packQuantiteTotaleController,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.total,
                                    child: TextChampL(
                                      controller: packPrixController,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _headerTableProduitsPackComplet(l10n),
                        const SizedBox(height: 6),
                        _tableProduitsPackComplet(setState, l10n),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _ajouterProduitPackComplet(context, setState, pack, l10n),
                          child: const AddManualWidget(),
                        ),
                      ],
                    ),
                  ),
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
                      text: l10n.modify,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.pack,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyPack,
                          message: l10n.confirmModifyPack,
                          onConfirmer: () async {
                            try {
                              int nombreProduits = produitsPackSelectionnes.length;
                              int quantiteTotale = produitsPackSelectionnes.fold(0, (sum, item) => sum + item.quantite);
                              double prixTotal = produitsPackSelectionnes.fold(0.0, (sum, item) => sum + item.montant);

                              final updatedPack = Pack(
                                id: pack.id,
                                code: pack.code,
                                etat: selectedEtatR == l10n.active,
                                nom: packNomController.text.trim(),
                                observation: packObserController.text.trim(),
                                quantiteTotale: quantiteTotale,
                                prixVente: prixTotal,
                                modifLe: DateTime.now(),
                                modifParCode: userCode,
                                creeParCode: pack.creeParCode,
                                creeLe: pack.creeLe,
                              );

                              final response = await _savePack(pack: updatedPack);

                              if (!response.success) {
                                await InformationDialog(
                                  context: context,
                                  titre_type_message: l10n.error,
                                  titre_concerne: l10n.pack,
                                  message: response.message ?? l10n.modificationError,
                                );
                                return;
                              }

                              final int idH = await _GetNextHistoriqueId();
                              final db = await DbCreator.openDb();
                              final serviceh = HistoriqueServices(db);

                              final Historique histo = Historique(
                                id: idH,
                                code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
                                desc: "Modification du pack ${updatedPack.nom} par $userName",
                                type: "Pack",
                                oper: ListsConst.typeHisto[1],
                                dateCree: DateTime.now(),
                                creeParCode: userCode,
                              );

                              await serviceh.addHistorique(histo);

                              await _UpdatePackDetailComplet(
                                produitsPack: produitsPackSelectionnes,
                                pack: updatedPack,
                                original: orignal,
                                userName: userName,
                                userCode: userCode,
                              );

                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.pack,
                                message: l10n.modifySuccess,
                                onTerminer: () {
                                  Navigator.pop(context);
                                },
                              );
                            } catch (e) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.pack,
                                message: "${l10n.errorOccurred}: $e",
                              );
                            }
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