import 'dart:ui';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';

import 'package:caisse_dz/Services/PannierProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;

import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/verssement.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';

import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';

import 'package:caisse_dz/data/constant.dart';

import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:collection/collection.dart';

import '../../utilis/api_response.dart';
import '../../utilis/quantite_format.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

List<PannierProduit> pannierProduitsTest = [];
List<Client> clientsTest = [];
List<Produit> produitsTest = [];

String _nomProduit(String code) =>
    produitsTest.where((p) => p.code == code).firstOrNull?.nom ?? code;

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
// ancienneQuantite/nouvelleQuantite = quantité réservée par CE panier pour ce
// produit (avant/après modification, 0 si le produit n'y était pas / n'y est
// plus). Augmenter la quantité réservée par le panier consomme du stock ;
// la diminuer (ou supprimer le produit du panier) en restitue.
//
// Conservée exportée : utilisée par pannier_actif.dart (annulation d'un
// panier) pour restituer le stock, même si ce dialog ne modifie plus lui-même
// le contenu d'un panier déjà encaissé (voir PannierServices.updatePannier).
Future<void> updateMagasinStock({
  required String produitCode,
  required double ancienneQuantite,
  required double nouvelleQuantite,
  // Second stock parallèle "Nombre" (Paramètres > Nombre et Quantité) —
  // restitué en même temps que quantite si fourni. Null si le paramètre est
  // inactif ou la ligne n'a pas de nombre renseigné : ignoré dans ce cas.
  double? ancienNombre,
  double? nouveauNombre,
  // Magasin où la vente d'origine a été faite (celui du Mouvement annulé) —
  // repli sur le magasin système pour les mouvements antérieurs à l'ajout
  // de cette colonne (magasinCode alors NULL).
  String? magasinCode,
}) async {
  try {
    final db = await DbCreator.openDb();
    final service = ProduitMagasinDetailServices(db);

    final magasinDetail = await service.getSingleByProduitAndMagasin(
        produitCode,
        magasinCode ?? 'MAG0000'
    );

    if (magasinDetail != null) {
      if (ancienNombre != null || nouveauNombre != null) {
        final diffNombre = (ancienNombre ?? 0) - (nouveauNombre ?? 0);
        final nouveauNombreStock = magasinDetail.nombre + diffNombre;
        await service.updateNombre(magasinDetail.id, nouveauNombreStock < 0 ? 0 : nouveauNombreStock);
      }

      print('✅ Stock (nombre) mis à jour pour $produitCode');
    }
  } catch (e) {
    print('❌ Erreur updateMagasinStock: $e');
  }
}

// ✅ Fonction pour mettre à jour le produit (sans transaction)
// Conservée exportée : utilisée par pannier_actif.dart, voir updateMagasinStock ci-dessus.
Future<void> updateProduct({
  required String produitCode,
  required double ancienneQuantite,
  required double nouvelleQuantite,
  required double ancienMontant,
  required double nouveauMontant,
  double? ancienNombre,
  double? nouveauNombre,
}) async {
  try {
    final db = await DbCreator.openDb();
    final service = ProduitServices(db);

    final produit = await service.getProduitByCode(produitCode);
    if (produit == null) return;

    if (!produit.service) {
      if (ancienNombre != null || nouveauNombre != null) {
        produit.nombre = produit.nombre + ((ancienNombre ?? 0) - (nouveauNombre ?? 0));
      }
    }



    produit.dateModif = DateTime.now();
    produit.modifParCode = "system";

    await service.updateProduit(produit);

    print('✅ Produit mis à jour: ${produit.nom}');
  } catch (e) {
    print('❌ Erreur _updateProduct: $e');
  }
}

// ✅ Fonction avec retry pour la modification du panier
//
// Le contenu fiscal de la vente (produits, quantités, prix, montant, date)
// est verrouillé dès l'encaissement (conformité art. 51 bis — voir
// PannierServices.updatePannier) : seules les métadonnées non fiscales
// (client, mode de paiement, montant versé) restent modifiables ici. Toute
// correction du contenu vendu doit passer par un Retour.
Future<ApiResponse<int>> _UpdatePannierWithRetry({
  required String userName,
  required String userCode,
  required Pannier panniere,
  required double ancienVerse,
  required double nouveauVerse,
}) async {
  int attempts = 0;
  const maxAttempts = 5;

  while (attempts < maxAttempts) {
    try {
      return await _UpdatePannier(
        userName: userName,
        userCode: userCode,
        panniere: panniere,
        ancienVerse: ancienVerse,
        nouveauVerse: nouveauVerse,
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

// ✅ Modifier les métadonnées du panier (client, mode de paiement, montant
// versé) SANS transaction globale — le contenu vendu n'est plus touché ici.
Future<ApiResponse<int>> _UpdatePannier({
  required String userName,
  required String userCode,
  required Pannier panniere,
  required double ancienVerse,
  required double nouveauVerse,
}) async {
  final db = await DbCreator.openDb();

  try {
    final services = PannierServices(db);
    final serviceC = ClientServices(db);
    final serviceV = VerssementServices(db);

    final clients = await ClientServices.getAllClients();
    final client = clients.where((e) => e.code == panniere.client_code).first;

    // 1. Mettre à jour les métadonnées du panier
    final response = await services.updatePannier(panniere);
    if (!response.success) {
      return response;
    }

    // 2. Répercuter le nouveau montant versé sur le versement client lié à ce panier
    final diffVerse = nouveauVerse - ancienVerse;
    if (diffVerse != 0) {
      final versementsPannier = await serviceV.getVerssementsByCodeOperation(panniere.code);
      final versementClient = versementsPannier
          .where((v) => v.typebeneficiare == 'Client' && v.sense == 'Entrée')
          .firstOrNull;

      if (versementClient != null) {
        versementClient.montant = nouveauVerse;
        versementClient.etat = nouveauVerse > 0;
        versementClient.dateModif = DateTime.now();
        versementClient.modifParCode = userCode;
        await serviceV.updateVerssement(versementClient);
      } else if (nouveauVerse > 0) {
        final nextVerssementId = await VerssementServices.getNextVerssementId(db);
        final nouveauVersement = Verssement(
          id: nextVerssementId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.verssement,
            id: nextVerssementId,
            digitCount: 6,
          ),
          date: DateTime.now(),
          typebeneficiare: "Client",
          beneficiareCode: client.code,
          montant: nouveauVerse,
          etat: true,
          mode_paiement: panniere.modePaiement ?? "Espèce",
          sense: 'Entrée',
          type: "Paiement",
          dateCree: DateTime.now(),
          creeParCode: userCode,
          caisse: panniere.caisse,
          codeOperation: panniere.code,
        );
        await serviceV.addverssement(nouveauVersement);
      }

      await _addHistorique(
        type: 'Versement',
        desc: "L'utilisateur $userName a modifié le montant versé du panier ${panniere.code}: $ancienVerse->$nouveauVerse",
        userName: userName,
        userCode: userCode,
      );
    }

    // 3. Historique principal du panier
    await _addHistorique(
      type: 'panniers',
      desc: "L'utilisateur $userName a modifié le panier ${panniere.code} (client/mode de paiement/versement)",
      userName: userName,
      userCode: userCode,
    );

    client.dateModif = DateTime.now();
    client.modifParCode = userCode;
    await serviceC.updateClient(client);

    return response;
  } catch (e) {
    print('❌ Erreur _UpdatePannier: $e');
    return ApiResponse(
      success: false,
      message: "Erreur lors de la modification: $e",
    );
  }
}

Future<void> PannierModif(
    BuildContext context,
    Pannier panier, {
      VoidCallback? onSuccess, // 👈 Ajouter ce callback
    }) async {
  await _LoadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.loginRequired),
        backgroundColor: Appstyle.danger,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  final db = await DbCreator.openDb();
  final serviceV = VerssementServices(db);
  final versementsPannier = await serviceV.getVerssementsByCodeOperation(panier.code);
  // Montant versé = somme des versements actifs liés à ce panier (calcul
  // dynamique, la colonne verse/reste n'existe plus sur le panier).
  final double ancienVerse = versementsPannier
      .where((v) => v.etat)
      .fold(0.0, (s, v) => s + v.montant);

  dateController.text = panier.date.toString();
  verseController.text = ancienVerse.toStringAsFixed(2);
  resteController.text = ((panier.montant) - ancienVerse).toStringAsFixed(2);
  selectedModePaiement = panier.modePaiement ?? "Espèce";
  selectedClient = clientsTest.where((c) => c.code == panier.client_code).firstOrNull?.nom;

  // Contenu vendu — affichage seul, non modifiable (voir PannierServices.updatePannier).
  final List<PannierProduit> produitsDuPanier = pannierProduitsTest
      .where((p) => p.codePannier == panier.code).toList();

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          void _updateReste() {
            double verse = double.tryParse(verseController.text) ?? 0;
            if (verse > panier.montant) {
              verse = panier.montant;
              verseController.text = verse.toStringAsFixed(2);
            }
            resteController.text = (panier.montant - verse).toStringAsFixed(2);
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
                                  label: l10n.date,
                                  child: TextChampL(
                                    controller: dateController,
                                    enabled: false,
                                    hint: '',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberOfItems,
                                  child: TextChampL(
                                    controller: TextEditingController(
                                        text: (panier.nombreArticle ?? produitsDuPanier.length).toString()),
                                    hint: '',
                                    enabled: false,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.totalAmount,
                                  child: TextChampL(
                                    controller: TextEditingController(
                                        text: panier.montant.toStringAsFixed(2)),
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
                                  DataColumn(label: Text(l10n.numberField)),
                                  DataColumn(label: Text(l10n.price)),
                                  DataColumn(label: Text(l10n.total)),
                                ],
                                rows: produitsDuPanier.map((p) {
                                  return DataRow(cells: [
                                    DataCell(Text(p.codeProduit)),
                                    DataCell(Text(_nomProduit(p.codeProduit))),
                                    DataCell(Text(QuantiteFormat.format(p.quantite))),
                                    DataCell(Text(p.nombre != null ? QuantiteFormat.format(p.nombre!) : '-')),
                                    DataCell(Text(p.prix.toStringAsFixed(2))),
                                    DataCell(Text(NumberFormatUtil.formatMontant(p.total, decimales: 2))),
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
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.modify,
                      color: Appstyle.violet,
                      onPressed: () async {
                        // Mise à jour des métadonnées uniquement — le contenu vendu
                        // (produits/qté/prix/montant/date) reste inchangé.
                        panier.modePaiement = selectedModePaiement;
                        panier.dateModif = DateTime.now();
                        panier.modifParCode = userCode;
                        panier.client_code = clientsTest
                            .where((c) => c.nom == selectedClient)
                            .firstOrNull
                            ?.code;
                        final nouveauVerse = double.tryParse(verseController.text) ?? 0;

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
                          ancienVerse: ancienVerse,
                          nouveauVerse: nouveauVerse,
                        );

                        if (!response.success) {


                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(response.message ?? "Erreur"),
                              duration: const Duration(seconds: 5),
                              backgroundColor: Appstyle.danger,
                            ),
                          );
                          return;
                        }
                        if (onSuccess != null) {
                          onSuccess();
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(response.message ?? "Modification réussie"),
                            duration: const Duration(seconds: 5),
                            backgroundColor: Appstyle.success,
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
