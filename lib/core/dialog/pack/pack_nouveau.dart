import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../data/models/pack.dart';
import '../../../data/models/produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/affichage_champ.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_produit.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// Variables globales
List<ProduitPackDetail> produitsPackDetails = [];
List<Produit> produitsTest = [];
int id = 0;
final TextEditingController packCodeC = TextEditingController();
final TextEditingController packNomC = TextEditingController();
final TextEditingController packObservC = TextEditingController();
final TextEditingController packNombreC = TextEditingController();
final TextEditingController packQuantiteTotaleC = TextEditingController();
final TextEditingController packPrixC = TextEditingController();

String cd = "";

void resetPackForm() {
  packCodeC.clear();
  packNomC.clear();
  packObservC.clear();
  packNombreC.clear();
  packQuantiteTotaleC.clear();
  packPrixC.clear();
  produitsPackDetails.clear();
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitPackDetailServices.getNextId(txn);
  });
  return id;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await PackServices.getNextPackId(txn);
  });
  return id;
}

Future<void> _loadData(void Function(VoidCallback fn) setState) async {
  final result = await ProduitServices.getAllProduits();
  setState(() {
    produitsTest = result;
  });
}

Future<ApiResponse<int>> _savePack({required Pack pack}) async {
  final db = await DbCreator.openDb();
  final services = PackServices(db);

  // Vérifier qu'un pack avec le même code n'existe pas déjà
  final existingPack = await db.query(
    'packs',
    where: 'code = ?',
    whereArgs: [pack.code],
  );

  if (existingPack.isNotEmpty) {
    return ApiResponse(
      success: false,
      message: "Un pack avec ce code existe déjà",
    );
  }

  return await services.addPack(pack);
}

Future<void> _savePackDetails({
  required List<ProduitPackDetail> produitsPackDetails,
  required String packCode,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitPackDetailServices(db);

  if (userName.isEmpty || userCode.isEmpty) {
    throw Exception("Utilisateur non authentifié. Veuillez vous reconnecter.");
  }

  // Vérifier que le pack existe avant d'insérer
  final packExists = await db.query(
    'packs',
    where: 'code = ?',
    whereArgs: [packCode],
  );

  if (packExists.isEmpty) {
    throw Exception("Le pack avec le code $packCode n'existe pas dans la base de données");
  }

  for (var detail in produitsPackDetails) {
    // Mettre à jour les informations du détail
    detail.packCode = packCode;
    detail.creeParCode = userCode;

    // Vérifier que le produit existe
    final produitExists = await db.query(
      'produits',
      where: 'code = ?',
      whereArgs: [detail.produitCode],
    );

    if (produitExists.isEmpty) {
      print("Attention: Le produit ${detail.produitCode} n'existe pas, insertion ignorée");
      continue;
    }

    final int idH = await _GetNextHistoriqueId();
    final serviceh = HistoriqueServices(db);

    final Historique histo = Historique(
      id: idH,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idH,
      ),
      desc: "Ajout de produit ${detail.produitCode} au pack $packCode par $userName",
      type: "Pack",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await serviceh.addHistorique(histo);

    final result = await service.addProduitPackDetail(detail);
    if (result == 0) {
      print("Erreur lors de l'insertion du détail pour ${detail.produitCode}");
    }
  }
}

Produit? _trouverProduitParCode(String code) {
  for (final p in produitsTest) {
    if (p.code == code) return p;
  }
  return null;
}

void recalculerTotauxPack(void Function(VoidCallback fn) setState) {
  setState(() {
    int nombreProduits = produitsPackDetails.length;
    int quantiteTotale = produitsPackDetails.fold(0, (sum, item) => sum + item.quantite);
    double prixTotal = produitsPackDetails.fold(0.0, (sum, item) => sum + item.montant);

    packNombreC.text = nombreProduits.toString();
    packQuantiteTotaleC.text = quantiteTotale.toString();
    packPrixC.text = prixTotal.toStringAsFixed(2);
  });
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> PackNouveau(BuildContext context) async {
  final auth = Provider.of<AuthState>(context, listen: false);

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: AppLocalizations.of(context)!.authentication,
      kind: DialogKind.refuser,
      titre_concerne: AppLocalizations.of(context)!.user,
      message: AppLocalizations.of(context)!.loginRequired,
    );
    return;
  }

  id = await _GetNextId();
  cd = CodeGenerator.generateCode(
    prefix: CodePrefix.pack,
    id: id,
    digitCount: 4,
  );

  produitsPackDetails.clear();
  packNomC.clear();
  packObservC.clear();
  packNombreC.clear();
  packQuantiteTotaleC.clear();
  packPrixC.clear();

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;
        _loadData(setState);

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BaseDialog(
              width: 1100,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/pack_icon.png',
                text: l10n.newPack,
              ),
              content: Form(
                key: produitFormKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ChampAvecLabel(
                                  label: l10n.code,
                                  child: AffichageChamp(text: cd),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.name,
                                  obligatoire: true,
                                  child: TextChampL(
                                    controller: packNomC,
                                    obligatoire: true,
                                    hint: l10n.packNameHint,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.observation,
                                  child: TextChampL(
                                    controller: packObservC,
                                    hint: l10n.observationHint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              children: [
                                ChampAvecLabel(
                                  label: l10n.numberOfItems,
                                  child: TextChampL(
                                    controller: packNombreC,
                                    enabled: false,
                                    hint: '0',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.totalQuantity,
                                  child: TextChampL(
                                    controller: packQuantiteTotaleC,
                                    enabled: false,
                                    hint: '0',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.total,
                                  child: TextChampL(
                                    controller: packPrixC,
                                    enabled: false,
                                    hint: '0',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      TitleSmall(
                        imagePath: 'assets/icons/sidebar/produit_icon.png',
                        text: l10n.products,
                        couleur: Appstyle.violet,
                      ),
                      const SizedBox(height: 10),
                      _headerTableProduitsPack(l10n),
                      const SizedBox(height: 6),
                      _tableProduitsPackNouveau(setState, l10n),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _ouvrirInsertionProduitPackNouveau(context, setState, l10n),
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
                    onPressed: () {
                      resetPackForm();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.save,
                    color: Appstyle.violet,
                    icon: Icons.save,
                    onPressed: () async {
                      if (packNomC.text.trim().isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.pack,
                          message: l10n.fillRequiredFields,
                        );
                        return;
                      }

                      if (produitsPackDetails.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.pack,
                          message: l10n.atLeastOneProduct,
                        );
                        return;
                      }

                      final userName = auth.username!;
                      final userCode = auth.userCode!;

                      int nombreProduits = produitsPackDetails.length;
                      int quantiteTotale = produitsPackDetails.fold(0, (sum, item) => sum + item.quantite);
                      double prixTotal = produitsPackDetails.fold(0.0, (sum, item) => sum + item.montant);

                      final packN = Pack(
                        id: id,
                        code: cd,
                        nom: packNomC.text.trim(),
                        observation: packObservC.text,
                        quantiteTotale: quantiteTotale,
                        prixVente: prixTotal,
                        etat: true,
                        creeLe: DateTime.now(),
                        creeParCode: userCode,
                      );

                      final int idH = await _GetNextHistoriqueId();
                      final db = await DbCreator.openDb();
                      final serviceh = HistoriqueServices(db);

                      final Historique histo = Historique(
                        id: idH,
                        code: CodeGenerator.generateCodeWithTimestamp(
                          prefix: CodePrefix.historique,
                          id: idH,
                        ),
                        desc: "Création d'un nouveau Pack ${packN.nom} par $userName",
                        type: "Pack",
                        oper: ListsConst.typeHisto[1],
                        dateCree: DateTime.now(),
                        creeParCode: userCode,
                      );

                      // 1. D'abord sauvegarder le pack
                      final response = await _savePack(pack: packN);

                      if (!response.success) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.pack,
                          message: response.message ?? "Erreur lors de l'enregistrement.",
                        );
                        return;
                      }

                      // 2. Ensuite sauvegarder les détails
                      try {
                        await _savePackDetails(
                          produitsPackDetails: produitsPackDetails,
                          packCode: packN.code,
                          userName: userName,
                          userCode: userCode,
                        );
                        await serviceh.addHistorique(histo);

                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.pack,
                          message: l10n.createSuccess,
                          onTerminer: () {
                            resetPackForm();
                            Navigator.pop(context);
                          },
                        );
                      } catch (e) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.pack,
                          message: "${l10n.errorOccurred}: $e",
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      });
    },
  );
}

Widget _headerTableProduitsPack(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(Appstyle.radiusSM),
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

Widget _tableProduitsPackNouveau(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
  if (produitsPackDetails.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAdded,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Column(
    children: produitsPackDetails.asMap().entries.map((entry) {
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
                      recalculerTotauxPack(setState);
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
                      recalculerTotauxPack(setState);
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
                style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold, color: Appstyle.crevete),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Appstyle.danger),
              onPressed: () {
                setState(() {
                  produitsPackDetails.removeAt(index);
                  recalculerTotauxPack(setState);
                });
              },
            ),
          ],
        ),
      );
    }).toList(),
  );
}

void _ouvrirInsertionProduitPackNouveau(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ) {
  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      newButton:false,
      multiselection: true,
      produits: produitsTest,
      onProduitSelected: (Produit produit) async {
        bool existeDeja = produitsPackDetails.any((p) => p.produitCode == produit.code);

        if (!existeDeja) {
          // ⚠️ NE PAS générer d'ID ici - la base de données le fera
          setState(() {
            produitsPackDetails.add(
              ProduitPackDetail(
                id: 0,  // Mettre 0, ne sera pas utilisé
                packCode: cd,     // Le code du pack
                produitCode: produit.code,
                prixUnitaire: produit.prixVente,
                quantite: 1,
                montant: produit.prixVente,
                dateCree: DateTime.now(),
                creeParCode: '',  // Sera mis à jour dans _savePackDetails
              ),
            );
            recalculerTotauxPack(setState);
          });
        } else {
          Future.microtask(() async {
            await InformationDialog(
              context: context,
              titre_type_message: l10n.error,
              kind: DialogKind.refuser,
              titre_concerne: l10n.pack,
              message: l10n.productAlreadyAdded(produit.nom),
            );
          });
        }
      },
    ),
  );
}