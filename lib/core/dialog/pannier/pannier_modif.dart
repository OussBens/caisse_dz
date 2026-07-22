import 'dart:ui';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';

import 'package:caisse_dz/Services/PannierProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart' hide ApiResponse;
import 'package:caisse_dz/Services/MagasinDetail.dart';

import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';

import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../utilis/api_response.dart';

List<PannierProduit> pannierProduitsTest = [];
List<Client> clientsTest = [];
List<Produit> produitsTest = [];

// ✅ Obtenir l'ID d'historique sans transaction
Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM Historique');
  final maxId = result.first['maxId'] as int?;
  return (maxId ?? 0) + 1;
}

Future<void> _LoadAllData() async {
  pannierProduitsTest = await PPServices.getAllPP();
  clientsTest = await ClientServices.getAllClients();
  produitsTest = await ProduitServices.getAllProduits();
}

final TextEditingController dateController = TextEditingController();
final TextEditingController verseController = TextEditingController();
final TextEditingController resteController = TextEditingController();

String? selectedEtatR;
String? selectedModePaiement;
String? selectedClient;

// ✅ Fonction pour ajouter un historique (sans transaction)
Future<void> _addHistorique({
  required String type,
  required String desc,
  required String userName,
  required String userCode,
}) async {
  try {
    final db = await DbCreator.openDb();
    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: "HS$idH${DateTime.now().millisecondsSinceEpoch}",
      type: type,
      desc: desc,
      oper: ListsConst.typeHisto[1],
      creePar: userName,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );

    await db.insert(
      'Historique',
      histo.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  } catch (e) {
    print('❌ Erreur ajout historique: $e');
  }
}

// ✅ Fonction pour mettre à jour le stock (sans transaction)
Future<void> _updateMagasinStock({
  required String produitCode,
  required double ancienneQuantite,
  required double nouvelleQuantite,
}) async {
  try {
    final db = await DbCreator.openDb();
    final service = ProduitMagasinDetailServices(db);
    final magasinService = MagasinServices(db);

    final systemMagasin = await magasinService.getMagasinByNom("Magasin System");
    if (systemMagasin == null) return;

    final magasinDetail = await service.getSingleByProduitAndMagasin(
        produitCode,
        systemMagasin.code
    );

    if (magasinDetail != null) {
      final diff = nouvelleQuantite - ancienneQuantite;
      final nouvelleQuantiteStock = magasinDetail.quantite + diff;

      await service.updateQuantite(magasinDetail.id, nouvelleQuantiteStock);

      print('✅ Stock mis à jour pour $produitCode: ${magasinDetail.quantite} -> $nouvelleQuantiteStock');
    }
  } catch (e) {
    print('❌ Erreur _updateMagasinStock: $e');
  }
}

// ✅ Fonction pour mettre à jour le produit (sans transaction)
Future<void> _updateProduct({
  required String produitCode,
  required double ancienneQuantite,
  required double nouvelleQuantite,
  required double ancienMontant,
  required double nouveauMontant,
}) async {
  try {
    final db = await DbCreator.openDb();
    final service = ProduitServices(db);

    final produit = await service.getProduitByCode(produitCode);
    if (produit == null) return;

    final diffQuantite = nouvelleQuantite - ancienneQuantite;
    produit.quantite = produit.quantite + diffQuantite;



    produit.dateModif = DateTime.now();
    produit.modifPar = "system";

    await service.updateProduit(produit);

    print('✅ Produit mis à jour: ${produit.nom}');
  } catch (e) {
    print('❌ Erreur _updateProduct: $e');
  }
}

// ✅ Fonction avec retry pour la modification du panier
Future<ApiResponse<int>> _UpdatePannierWithRetry({
  required String userName,
  required String userCode,
  required Pannier panniere,
  required List<PannierProduit> produits,
  required List<PannierProduit> produitOr,
  required double nouveauMontant,
  required double ancienMontant,
}) async {
  int attempts = 0;
  const maxAttempts = 5;

  while (attempts < maxAttempts) {
    try {
      return await _UpdatePannier(
        userName: userName,
        userCode: userCode,
        panniere: panniere,
        produits: produits,
        produitOr: produitOr,
        nouveauMontant: nouveauMontant,
        ancienMontant: ancienMontant,
      );
    } catch (e) {
      attempts++;
      if (e.toString().contains('database is locked') && attempts < maxAttempts) {
        print('⚠️ Base verrouillée, tentative $attempts/$maxAttempts...');
        await Future.delayed(Duration(milliseconds: 500 * attempts));
      } else {
        print('❌ Erreur _UpdatePannier: $e');
        return ApiResponse(
          success: false,
          message: "Erreur lors de la modification: $e",
        );
      }
    }
  }

  return ApiResponse(
    success: false,
    message: "Échec après $maxAttempts tentatives",
  );
}

// ✅ Modifier le panier SANS transaction globale
Future<ApiResponse<int>> _UpdatePannier({
  required String userName,
  required String userCode,
  required Pannier panniere,
  required List<PannierProduit> produits,
  required List<PannierProduit> produitOr,
  required double nouveauMontant,
  required double ancienMontant,
}) async {
  final db = await DbCreator.openDb();

  try {
    final servicem = MouvementsServices(db);
    final services = PannierServices(db);
    final serviceC = ClientServices(db);
    final servicep = PPServices(db);

    final clients = await ClientServices.getAllClients();
    final client = clients.where((e) => e.nom == panniere.client).first;

    final mouvements = await MouvementsServices.getAllMouvementsByCodeOper(panniere.code);

    final diffMontant = nouveauMontant - ancienMontant;

    // 1. Mettre à jour le panier
    final response = await services.updatePannier(panniere);

    // 2. Parcourir les produits
    for (var prodO in produitOr) {
      final exists = produits.any((p) => p.id == prodO.id);

      if (!exists) {
        // Produit supprimé : AJOUTER au stock
        await _updateMagasinStock(
          produitCode: prodO.codeProduit,
          ancienneQuantite: 0,
          nouvelleQuantite: prodO.quantite,
        );

        await _updateProduct(
          produitCode: prodO.codeProduit,
          ancienneQuantite: prodO.quantite,
          nouvelleQuantite: 0,
          ancienMontant: prodO.total,
          nouveauMontant: 0,
        );

        final mouv = mouvements.where((e) => e.nomProduit == prodO.nomProduit).firstOrNull;
        if (mouv != null) {
          await MouvementsServices.deleteMouvement(mouv.id);
        }

        await servicep.deletePP(prodO.id);

        await _addHistorique(
          type: 'pannierProduit',
          desc: "L'utilisateur $userName a supprimé le produit ${prodO.nomProduit} du panier ${panniere.code}",
          userName: userName,
          userCode: userCode,
        );
      } else {
        final prod = produits.where((e) => e.id == prodO.id).first;
        final diffQte = prod.quantite - prodO.quantite;

        if (diffQte != 0) {
          await _updateMagasinStock(
            produitCode: prod.codeProduit,
            ancienneQuantite: prodO.quantite,
            nouvelleQuantite: prod.quantite,
          );

          await _updateProduct(
            produitCode: prod.codeProduit,
            ancienneQuantite: prodO.quantite,
            nouvelleQuantite: prod.quantite,
            ancienMontant: prodO.total,
            nouveauMontant: prod.total,
          );

          final mouv = mouvements.where((e) => e.nomProduit == prod.nomProduit).firstOrNull;
          if (mouv != null) {
            mouv.dateModif = DateTime.now();
            mouv.prixVente = prod.prix;
            mouv.quantite = prod.quantite;
            mouv.modifPar = userName;
            mouv.client = panniere.client;
            mouv.date = panniere.date;
            await servicem.updateMouvement(mouv);
          }

          await servicep.updatePP(prod);

          await _addHistorique(
            type: 'pannierProduit',
            desc: "L'utilisateur $userName a modifié ${prod.nomProduit}: qté ${prodO.quantite}->${prod.quantite}",
            userName: userName,
            userCode: userCode,
          );
        }
      }
    }

    // 3. Vérifier les nouveaux produits
    for (var prod in produits) {
      final exists = produitOr.any((p) => p.id == prod.id);
      if (!exists) {
        // Nouveau produit : DIMINUER le stock
        await _updateMagasinStock(
          produitCode: prod.codeProduit,
          ancienneQuantite: 0,
          nouvelleQuantite: -prod.quantite,
        );

        await _updateProduct(
          produitCode: prod.codeProduit,
          ancienneQuantite: 0,
          nouvelleQuantite: prod.quantite,
          ancienMontant: 0,
          nouveauMontant: prod.total,
        );
      }
    }

    // 4. Mettre à jour le client
    if (diffMontant != 0) {
      client.dernierAchat = DateTime.now();
      client.dateModif = DateTime.now();
      client.modifPar = userName;
      await serviceC.updateClient(client);

      await _addHistorique(
        type: 'Client',
        desc: "L'utilisateur $userName a modifié le client ${client.nom}",
        userName: userName,
        userCode: userCode,
      );
    }

    // 6. Historique principal du panier
    await _addHistorique(
      type: 'panniers',
      desc: "L'utilisateur $userName a modifié le panier ${panniere.code}: montant $ancienMontant->$nouveauMontant",
      userName: userName,
      userCode: userCode,
    );

    return response;
  } catch (e) {
    print('❌ Erreur _UpdatePannier: $e');
    return ApiResponse(
      success: false,
      message: "Erreur lors de la modification: $e",
    );
  }
}

Future<void> PannierModif(BuildContext context, Pannier panier) async {
  await _LoadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.loginRequired),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  final double ancienMontant = panier.montant;

  dateController.text = panier.date.toString();
  verseController.text = panier.verse.toStringAsFixed(2);
  resteController.text = ((panier.montant) - (panier.verse)).toStringAsFixed(2);
  selectedModePaiement = panier.modePaiement ?? "Espèce";
  selectedClient = panier.client;
  selectedEtatR = panier.etat ? 'Actif' : 'Inactif';

  List<PannierProduit> produitsDuPanier = pannierProduitsTest
      .where((p) => p.codePannier == panier.code).toList();
  List<PannierProduit> Orignal = List.from(produitsDuPanier);

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          double nouveauMontant = panier.montant;

          void _updateReste() {
            double verse = double.tryParse(verseController.text) ?? 0;
            double montant = nouveauMontant;
            resteController.text = (montant - verse).toStringAsFixed(2);
          }

          void _recalculerTotal() {
            double total = 0;
            for (var p in produitsDuPanier) {
              total += p.quantite * p.prix;
            }
            nouveauMontant = total;
            panier.montant = total;
            _updateReste();
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/pannier_icon.png',
                  text: l10n.modifyCart,
                ),
                content: SingleChildScrollView(
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
                                  child: TextChampL(
                                    controller: TextEditingController(text: panier.code),
                                    enabled: false,
                                    hint: '',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.status,
                                  child: TextListe(
                                    value: selectedEtatR,
                                    items: [l10n.active, l10n.inactive],
                                    onChanged: (v) => setState(() {
                                      selectedEtatR = v;
                                    }),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.date,
                                  child: TextDate(
                                    controller: dateController,
                                    hint: l10n.selectDatew,
                                    onTap: () async {
                                      DateTime? pickedDate = await showDatePicker(
                                        initialDate: panier.dateCree,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime(2100),
                                        context: context,
                                      );
                                      if (pickedDate != null) {
                                        setState(() {
                                          dateController.text = pickedDate.toString();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberOfItems,
                                  child: TextChampL(
                                    controller: TextEditingController(
                                        text: panier.nombreArticle?.toString() ?? "0"),
                                    hint: '',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.totalAmount,
                                  child: TextChampL(
                                    controller: TextEditingController(
                                        text: nouveauMontant.toStringAsFixed(2)),
                                    hint: '',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.observation,
                                  child: TextChampL(
                                    controller: TextEditingController(
                                        text: panier.observation ?? '-'),
                                    hint: '',
                                    enabled: false,
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
                                  label: l10n.amountPaid,
                                  child: TextChampL(
                                    hint: "0.00",
                                    enabled: true,
                                    controller: verseController,
                                    onChanged: (_) => _updateReste(),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.remaining,
                                  child: TextChampL(
                                    hint: '',
                                    enabled: false,
                                    controller: resteController,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.paymentMethod,
                                  child: TextListe(
                                    value: selectedModePaiement ?? "Espèce",
                                    items: ListsConst.modePaiementList,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedModePaiement = v;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.client,
                                  child: TextListe(
                                    value: selectedClient ?? "",
                                    items: clientsTest.map((c) => c.nom).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        selectedClient = v;
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
                        l10n.productsList,
                        style: Appstyle.textLB.copyWith(color: Appstyle.Tnoir),
                      ),
                      const SizedBox(height: 10),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: constraints.maxWidth,
                              ),
                              child: DataTable(
                                columns: [
                                  DataColumn(label: Text(l10n.productCode)),
                                  DataColumn(label: Text(l10n.productName)),
                                  DataColumn(label: Text(l10n.quantity)),
                                  DataColumn(label: Text(l10n.price)),
                                  DataColumn(label: Text(l10n.total)),
                                  DataColumn(label: Text(l10n.delete)),
                                ],
                                rows: produitsDuPanier.map((p) {
                                  final quantiteController = TextEditingController(text: p.quantite.toString());
                                  final prixController = TextEditingController(text: p.prix.toStringAsFixed(2));

                                  void _updateTotal() {
                                    double q = double.tryParse(quantiteController.text) ?? 0;
                                    double pr = double.tryParse(prixController.text) ?? 0;
                                    setState(() {
                                      p.quantite = q;
                                      p.prix = pr;
                                      p.total = q * pr;
                                      _recalculerTotal();
                                    });
                                  }

                                  return DataRow(cells: [
                                    DataCell(Text(p.codeProduit)),
                                    DataCell(Text(p.nomProduit)),
                                    DataCell(
                                      SizedBox(
                                        width: 60,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: quantiteController,
                                          onChanged: (_) {
                                            _updateTotal();
                                          },
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 80,
                                        child: TextField(
                                          keyboardType: TextInputType.number,
                                          controller: prixController,
                                          onChanged: (_) {
                                            _updateTotal();
                                          },
                                        ),
                                      ),
                                    ),
                                    DataCell(Text((p.total).toStringAsFixed(2))),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          setState(() {
                                            produitsDuPanier.remove(p);
                                            _recalculerTotal();
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
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      icon: Icons.cancel,
                      color: Appstyle.gris,
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.modify,
                      color: Appstyle.violet,
                      onPressed: () async {
                        // Mise à jour du panier
                        panier.modePaiement = selectedModePaiement;
                        panier.dateModif = DateTime.now();
                        panier.modifPar = userName;
                        panier.client = selectedClient!;
                        panier.client_code = clientsTest
                            .where((c) => c.nom == selectedClient)
                            .firstOrNull
                            ?.code;
                        panier.verse = double.tryParse(verseController.text) ?? 0;
                        panier.reste = nouveauMontant - panier.verse;
                        panier.date = DateTime.parse(dateController.text);
                        panier.montant = nouveauMontant;
                        panier.nombreArticle = produitsDuPanier.length;
                        panier.etat = selectedEtatR == 'Actif';

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Modification en cours..."),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        final response = await _UpdatePannierWithRetry(
                          panniere: panier,
                          userCode: userCode,
                          userName: userName,
                          produits: produitsDuPanier,
                          produitOr: Orignal,
                          nouveauMontant: nouveauMontant,
                          ancienMontant: ancienMontant,
                        );

                        if (!response.success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message ?? "Erreur"),
                              duration: const Duration(seconds: 5),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response.message ?? "Modification réussie"),
                            duration: const Duration(seconds: 5),
                            backgroundColor: Colors.green,
                          ),
                        );

                        Navigator.pop(context);
                      },
                      icon: Icons.save,
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