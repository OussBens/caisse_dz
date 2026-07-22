import 'dart:ui';
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/dialog/confirmation_dialog.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

final TextEditingController observationController = TextEditingController();
final TextEditingController smartDateController = TextEditingController();
final TextEditingController montantController = TextEditingController();
final TextEditingController ecartController = TextEditingController();

List<SmartScanProduit> smartscanProduitsTest = [];
List<Fournisseur> fournisseursTest = [];
List<Mouvement> Mouvments = [];

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> UpdateSS({
  required String userName,
  required String userCode,
  required SmartScan smartscan,
  required List<SmartScanProduit> produits,
  required List<SmartScanProduit> orignal,
}) async {
  final db = await DbCreator.openDb();
  final services = SmartScanServices(db);
  final serviceh = HistoriqueServices(db);
  final servicep = SmartScanProduitServices(db);
  final serviceM = MouvementsServices(db);
  final serviceP = ProduitServices(db);

  final Produitse = await ProduitServices.getAllProduits();
  final mouv = await MouvementsServices.getAllMouvementsByCodeOper(smartscan.code);
  final response = await services.updateSmartScan(smartscan);

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: idh,
    code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
    type: 'SmartScan',
    desc: "l'utilisateur $userName a modife les information de Smart Scan de fournisseur ${smartscan.fournisseur}",
    oper: ListsConst.typeHisto[1],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);

  for (var oldProd in orignal) {
    final exists = produits.any((p) => p.id == oldProd.id);

    if (!exists) {
      await servicep.deleteSmartScanProduit(oldProd.id);
      Produit prod = Produitse.where((e) => e.nom == oldProd.nomProduit).first;
      prod.quantite = prod.quantite - oldProd.quantite;
      prod.dateModif = DateTime.now();
      prod.modifParCode = userName;
      await serviceP.updateProduit(prod);
      await MouvementsServices.deleteMouvement(mouv.where((e) => e.nomProduit == oldProd.nomProduit).first.id);
      int idh = await _GetNextHistoriqueId();
      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
          type: 'SmartScanProduit',
          desc: "l'utilisateur $userName a supprimé le SmartScanProduit ${oldProd.nomProduit} de SmartScan ${oldProd.codeSmartScan}",
          oper: ListsConst.typeHisto[1],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }
  }

  for (var newProd in produits) {
    final exists = orignal.any((p) => p.id == newProd.id);

    if (!exists) {
      int id = await _GetNextMouvementId();
      Mouvement mouve = Mouvement(
          id: id,
          code: "MV$id${DateTime.now().millisecondsSinceEpoch}",
          date: smartscan.date,
          nomProduit: newProd.nomProduit,
          codeProduit: newProd.codeProduit,
          quantite: newProd.quantite,
          prixAchat: newProd.prix,
          prixVente: newProd.prix,
          type: ListsConst.typeMouvement[1],
          etat: true,
          codeOperation: smartscan.code,
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await servicep.addSmartScanProduit(newProd);

      int idh = await _GetNextHistoriqueId();
      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
          type: 'SmartScanProduit',
          desc: "l'utilisateur $userName a ajouté le SmartScanProduit ${newProd.nomProduit} de SmartScan ${newProd.codeSmartScan}",
          oper: ListsConst.typeHisto[0],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }
  }

  for (var newProd in produits) {
    final oldList = orignal.where((p) => p.id == newProd.id);
    if (oldList.isEmpty) continue;
    final oldProd = oldList.first;
    bool isModified = oldProd.quantite != newProd.quantite ||
        oldProd.prix != newProd.prix ||
        oldProd.total != newProd.total;

    if (isModified) {
      Mouvement mouve = mouv.where((f) => f.nomProduit == newProd.nomProduit).first;
      mouve.prixAchat = newProd.prix;
      mouve.quantite = newProd.quantite;
      mouve.modifParCode = userName;
      mouve.dateModif = DateTime.now();

      if (oldProd.prix != newProd.prix) {
        Produit prod = Produitse.where((e) => e.nom == newProd.nomProduit).first;
        prod.prixAchat = newProd.prix;
        prod.modifParCode = userName;
        prod.dateModif = DateTime.now();
        await serviceP.updateProduit(prod);

        int idh = await _GetNextHistoriqueId();
        await serviceh.addHistorique(
            Historique(
              id: idh,
              code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
              type: 'produit',
              desc: "l'utilisateur $userName a modifié Le Prix Achat de Produit${prod.nom}",
              oper: ListsConst.typeHisto[1],
              dateCree: DateTime.now(),
              creeParCode: userCode,
            )
        );
      }
      if (oldProd.quantite != newProd.quantite) {
        Produit prod = Produitse.where((e) => e.nom == newProd.nomProduit).first;
        prod.quantite = (newProd.quantite - oldProd.quantite) + prod.quantite;
        prod.modifParCode = userName;
        prod.dateModif = DateTime.now();
        await serviceP.updateProduit(prod);

        int idh = await _GetNextHistoriqueId();
        await serviceh.addHistorique(
            Historique(
              id: idh,
              code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
              type: 'produit',
              desc: "l'utilisateur $userName a modifié La Quantite de Produit${prod.nom}",
              oper: ListsConst.typeHisto[1],
              dateCree: DateTime.now(),
              creeParCode: userCode,
            )
        );
      }
      await serviceM.updateMouvement(mouve);
      await servicep.updateSmartScanProduit(newProd);
      int idh = await _GetNextHistoriqueId();
      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: 'HS$idh${DateTime.now().millisecondsSinceEpoch}',
          type: 'SmartScanProduit',
          desc: "l'utilisateur $userName a modifié Le SmartScanProduit ${newProd.nomProduit} de SmartScan ${newProd.codeSmartScan} "
              "(Qté: ${oldProd.quantite} → ${newProd.quantite}, "
              "Prix: ${oldProd.prix} → ${newProd.prix})",
          oper: ListsConst.typeHisto[1],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }
  }
  return response;
}

int calculNombreProduits(List<SmartScanProduit> produits) {
  return produits.length;
}

double calculQuantiteTotale(List<SmartScanProduit> produits) {
  return produits.fold(0.0, (sum, p) => sum + p.quantite);
}

double calculMontantTotal(List<SmartScanProduit> produits) {
  return produits.fold(0.0, (sum, p) => sum + (p.quantite * p.prix));
}

bool hasEcart(SmartScan scan, List<SmartScanProduit> produits) {
  final articleCalcul = calculNombreProduits(produits);
  final quantiteCalcul = calculQuantiteTotale(produits);
  final montantCalcul = calculMontantTotal(produits);

  return scan.nbrProduit != articleCalcul ||
      scan.quantiteArticle != quantiteCalcul ||
      scan.montant != montantCalcul;
}

Future<void> _LoadAllData({required SmartScan smartscan}) async {
  smartscanProduitsTest = await SmartScanProduitServices.getSmartScanProduitByCode(smartscan.code);
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  Mouvments = await MouvementsServices.getAllMouvementsByCodeOper(smartscan.code);
}

String? selectedEtat;
String? selectedFournisseur;

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> SmartScanModif(
    BuildContext context,
    SmartScan scan,
    ) async {
  await _LoadAllData(smartscan: scan);
  List<SmartScanProduit> orignal = smartscanProduitsTest.map((e) => e.copy()).toList();
  List<SmartScanProduit> produitsScan = smartscanProduitsTest.map((e) => e.copy()).toList();

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  smartDateController.text = "${scan.date}";
  montantController.text = scan.montant.toStringAsFixed(2);
  observationController.text = scan.observation ?? "";
  ecartController.text = scan.ecart ? l10n.yes : l10n.no;

  selectedEtat = scan.etat ? l10n.active : l10n.inactive;
  String fourCode = scan.fournisseurCode;
  selectedFournisseur = scan.fournisseur;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/scan_icon.png',
                  text: l10n.modifySmartScan,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                                    obligatoire: true,
                                    child: TextChampL(
                                      obligatoire: true,
                                      controller: TextEditingController(text: scan.code),
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.date,
                                    obligatoire: true,
                                    child: TextDate(
                                      obligatoire: true,
                                      controller: smartDateController,
                                      hint: "25 Nov 2025",
                                      onTap: () async {
                                        DateTime? picked = await showDatePicker(
                                          context: context,
                                          initialDate: scan.date,
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            smartDateController.text = "$picked";
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.productCount,
                                    obligatoire: true,
                                    child: TextChampL(
                                      controller: TextEditingController(
                                          text: scan.nbrProduit.toString()),
                                      obligatoire: true,
                                      enabled: false,
                                      hint: '',
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.observation,
                                    child: TextChampL(
                                      controller: observationController,
                                      hint: "",
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 20),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ChampAvecLabel(
                                    label: l10n.amount,
                                    obligatoire: true,
                                    child: TextChampL(
                                      obligatoire: true,
                                      numeric: true,
                                      enabled: false,
                                      controller: montantController,
                                      hint: "0.00",
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.gap,
                                    child: TextChampL(
                                      controller: ecartController,
                                      hint: "0.00",
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.supplier,
                                    obligatoire: true,
                                    buttonAjout: true,
                                    onAjoutPressed: () async {
                                      await showDialog(
                                        context: context,
                                        barrierColor: Appstyle.gris.withOpacity(0.25),
                                        builder: (_) {
                                          return InsertionFournisseurDialog(
                                            fournisseurs: fournisseursTest,
                                            onFournisseurSelected: (fournisseur) {
                                              setState(() {
                                                selectedFournisseur = fournisseur.nom;
                                                fourCode = fournisseur.code;
                                              });
                                            },
                                          );
                                        },
                                      );
                                    },
                                    child: TextListe(
                                      obligatoire: true,
                                      clearable: false,
                                      value: selectedFournisseur,
                                      items: fournisseursTest.map((c) => c.nom).toList(),
                                      onChanged: (v) {
                                        setState(() {
                                          selectedFournisseur = v!;
                                          fourCode = fournisseursTest.where((e) => e.nom == v).first.code;
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  ChampAvecLabel(
                                    label: l10n.status,
                                    obligatoire: true,
                                    child: TextListe(
                                      obligatoire: true,
                                      value: selectedEtat,
                                      clearable: false,
                                      items: translator.etatDisplayList,
                                      onChanged: (v) {
                                        setState(() {
                                          selectedEtat = v;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          l10n.smartScanProductsList,
                          style: Appstyle.textLB.copyWith(color: Appstyle.Tnoir),
                        ),
                        const SizedBox(height: 10),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                child: DataTable(
                                  columns: [
                                    DataColumn(label: Text(l10n.productCode)),
                                    DataColumn(label: Text(l10n.productName)),
                                    DataColumn(label: Text(l10n.quantity)),
                                    DataColumn(label: Text(l10n.price)),
                                    DataColumn(label: Text(l10n.total)),
                                    DataColumn(label: Text(l10n.delete)),
                                  ],
                                  rows: produitsScan.map((p) {
                                    final qController = TextEditingController(text: p.quantite.toString());
                                    final prixController = TextEditingController(text: p.prix.toStringAsFixed(2));

                                    void _updateTotal() {
                                      double q = double.tryParse(qController.text) ?? 0;
                                      double pr = double.tryParse(prixController.text) ?? 0;
                                      setState(() {
                                        p.quantite = q;
                                        p.prix = pr;
                                        p.total = q * pr;
                                      });
                                    }

                                    return DataRow(cells: [
                                      DataCell(Text(p.codeProduit)),
                                      DataCell(Text(p.nomProduit)),
                                      DataCell(
                                        SizedBox(
                                          width: 60,
                                          child: TextField(
                                            controller: qController,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => _updateTotal(),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        SizedBox(
                                          width: 80,
                                          child: TextField(
                                            controller: prixController,
                                            keyboardType: TextInputType.number,
                                            onChanged: (_) => _updateTotal(),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(p.total.toStringAsFixed(2))),
                                      DataCell(
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              produitsScan.remove(p);
                                            });
                                          },
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            );
                          },
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
                              titre_concerne: l10n.smartScan,
                              message: l10n.fillRequiredFields,
                            );
                            return;
                          }

                          scan.date = DateTime.parse(smartDateController.text);
                          scan.observation = observationController.text;
                          scan.fournisseur = selectedFournisseur!;
                          scan.etat = selectedEtat == l10n.active;
                          scan.fournisseurCode = fourCode;

                          final articleCalcul = calculNombreProduits(produitsScan);
                          final quantiteCalcul = calculQuantiteTotale(produitsScan);
                          final montantCalcul = calculMontantTotal(produitsScan);

                          scan.nbrProduitCalcul = articleCalcul;
                          scan.quantiteArticleCalcul = quantiteCalcul;
                          scan.montantCalcul = montantCalcul;

                          bool ecart = hasEcart(scan, produitsScan);

                          if (ecart) {
                            bool? continuer = await ConfirmationDialog(
                              context: context,
                              titre: l10n.gapDetected,
                              message: l10n.gapDetectedMessage,
                            );

                            if (continuer != true) return;
                            scan.ecart = true;
                          } else {
                            scan.ecart = false;
                          }

                          final response = await UpdateSS(
                            userName: userName,
                            userCode: userCode,
                            smartscan: scan,
                            produits: produitsScan,
                            orignal: orignal,
                          );

                          if (!response.success) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.smartScan,
                              message: response.message,
                            );
                            return;
                          }

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.success,
                            titre_concerne: l10n.smartScan,
                            message: l10n.smartScanModifiedSuccess,
                            onTerminer: () {
                              Navigator.pop(context);
                            },
                          );
                        }
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