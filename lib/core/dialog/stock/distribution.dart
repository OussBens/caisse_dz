import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/besionlist/besoinlist_nouveau.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/title_small.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

final TextEditingController prixVenteController = TextEditingController();
final TextEditingController prixAchatController = TextEditingController();
final TextEditingController marqueController    = TextEditingController();
final TextEditingController uniteController     = TextEditingController();
final TextEditingController codeController      = TextEditingController();
final TextEditingController nomController       = TextEditingController();

List<ProduitMagasinDetail>  magasinsDistribues    = [];
List<ProduitMagasinDetail>  produitsMagasinsTest  = [];
List<Magasin>               magasinsTest          = [];

// Définir le code du magasin système
const String SYSTEM_STORE_CODE = "MAG0000";

// Fonction utilitaire pour vérifier si un magasin est système
bool isSystemStore(String magasinCode) {
  return magasinCode == SYSTEM_STORE_CODE;
}

String magasinNomByCode(String magasinCode) {
  return magasinsTest.firstWhereOrNull((m) => m.code == magasinCode)?.nom ?? magasinCode;
}

Future<void> _LoadData() async {
  produitsMagasinsTest = await ProduitMagasinDetailServices.getAllDetails();
  magasinsTest = await MagasinServices.getAllMagasins();
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<void> UpdateDistribution({
  required List<ProduitMagasinDetail> UDetail,  // Nouvelles données (après modification)
  required List<ProduitMagasinDetail> ODetail,  // Anciennes données (avant modification)
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = ProduitMagasinDetailServices(db);
  final serviceh = HistoriqueServices(db);

  print("=== UpdateDistribution ===");
  print("ODetail (original) count: ${ODetail.length}");
  print("UDetail (updated) count: ${UDetail.length}");

  for (var old in ODetail) {
    print("Original: ${old.magasinCode} - ${old.quantite}");
  }
  for (var newD in UDetail) {
    print("Updated: ${newD.magasinCode} - ${newD.quantite}");
  }

  // ✅ 1. Traiter les mises à jour et les suppressions
  for (var oldDetail in ODetail) {
    // Vérifier si c'est un magasin système - on ignore la suppression
    if (isSystemStore(oldDetail.magasinCode)) {
      print("Magasin système détecté: ${oldDetail.magasinCode} - Ignorer la suppression");
      continue; // Passer ce magasin système
    }

    // Chercher le détail correspondant dans UDetail par ID
    final matchingNewDetail = UDetail.firstWhere(
          (newDetail) => newDetail.id == oldDetail.id,
      orElse: () => ProduitMagasinDetail(
        id: 0,
        magasinCode: '',
        produitCode: '',
        quantite: 0,
        dateCree: DateTime.now(),
        creeParCode: '',
      ),
    );

    if (matchingNewDetail.id == 0) {
      // ✅ Le détail a été supprimé par l'utilisateur
      print("Suppression: ${oldDetail.magasinCode}");
      await services.deleteDetaile(oldDetail);

      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a supprimé le produit ${oldDetail.produitCode} du magasin ${magasinNomByCode(oldDetail.magasinCode)}",
          type: "ProduitMagasinDetail",
          oper: ListsConst.typeHisto[2],
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }
    else if (matchingNewDetail.quantite != oldDetail.quantite) {
      // ✅ La quantité a changé - mettre à jour
      print("Mise à jour: ${oldDetail.magasinCode} - ${oldDetail.quantite} → ${matchingNewDetail.quantite}");
      await services.updateQuantite(oldDetail.id, matchingNewDetail.quantite);

      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a modifié la quantité du produit ${matchingNewDetail.produitCode} dans le magasin ${magasinNomByCode(matchingNewDetail.magasinCode)} : ${oldDetail.quantite.toInt()} → ${matchingNewDetail.quantite.toInt()}",
          type: "ProduitMagasinDetail",
          oper: ListsConst.typeHisto[1],
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }
  }

  // ✅ 2. Traiter les nouveaux ajouts (détails sans ID)
  for (var newDetail in UDetail) {
    if (newDetail.id == 0 && newDetail.quantite > 0) {
      // ✅ Nouveau détail à ajouter
      print("Nouvel ajout: ${newDetail.magasinCode} - ${newDetail.quantite}");
      final newId = await ProduitMagasinDetailServices.getNextId(db);
      newDetail.id = newId;
      newDetail.dateCree = DateTime.now();
      newDetail.creeParCode = userCode;

      await services.addProduitMagasinDetail(newDetail);

      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "L'utilisateur $userName a ajouté le produit ${newDetail.produitCode} dans le magasin ${magasinNomByCode(newDetail.magasinCode)} avec quantité ${newDetail.quantite.toInt()}",
          type: "ProduitMagasinDetail",
          oper: ListsConst.typeHisto[0],
          dateCree: DateTime.now(),
          creeParCode: userCode
      );
      await serviceh.addHistorique(histo);
    }
  }
}

Future<void> DistributionProduit(BuildContext context, Produit produit) async {
  await _LoadData();

  prixVenteController.text = produit.prixVente.toStringAsFixed(2);
  prixAchatController.text = produit.prixAchat.toStringAsFixed(2);
  uniteController.text = produit.uniteMesure;
  marqueController.text = produit.marque;
  codeController.text = produit.code;
  nomController.text = produit.nom;

  // ✅ Récupérer les données actuelles du produit
  final currentDetails = produitsMagasinsTest
      .where((m) => m.produitCode == produit.code)
      .toList();

  // ✅ CRÉER UNE COPIE PROFONDE des données originales pour la comparaison
  final List<ProduitMagasinDetail> originalDetails = [];
  for (var detail in currentDetails) {
    originalDetails.add(ProduitMagasinDetail(
      id: detail.id,
      magasinCode: detail.magasinCode,
      produitCode: detail.produitCode,
      quantite: detail.quantite,
      dateCree: detail.dateCree,
      creeParCode: detail.creeParCode,
    ));
  }

  // ✅ Initialiser la liste modifiable avec une COPIE
  magasinsDistribues = [];
  for (var detail in currentDetails) {
    magasinsDistribues.add(ProduitMagasinDetail(
      id: detail.id,
      magasinCode: detail.magasinCode,
      produitCode: detail.produitCode,
      quantite: detail.quantite,
      dateCree: detail.dateCree,
      creeParCode: detail.creeParCode,
    ));
  }

  Map<int, TextEditingController> controllers = {
    for (var m in magasinsDistribues) m.id: TextEditingController(text: m.quantite.toString())
  };

  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.loginRequired),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    return;
  }

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        double totalDistribue() {
          double sum = 0;
          for (var detail in magasinsDistribues) {
            sum += detail.quantite;
          }
          return sum;
        }

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BaseDialog(
              width: 900,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/action/distribution_icon.png',
                text: l10n.productDistribution,
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.code,
                          child: TextChampL(controller: codeController, enabled: false, hint: ''),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.name,
                          child: TextChampL(controller: nomController, enabled: false, hint: ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.brand,
                          child: TextChampL(controller: marqueController, enabled: false, hint: ''),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.salePrice,
                          child: TextChampL(controller: prixVenteController, enabled: false, hint: ''),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.purchasePrice,
                          child: TextChampL(controller: prixAchatController, enabled: false, hint: ''),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChampAvecLabel(
                          label: l10n.unit,
                          child: TextChampL(controller: uniteController, enabled: false, hint: ''),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TitleSmall(
                        imagePath: 'assets/icons/sidebar/produit_icon.png',
                        text: l10n.distributionByStore,
                        couleur: Appstyle.violet,
                      ),
                      Text(
                        "${l10n.totalDistributed}: ${totalDistribue().toInt()} / ${l10n.available}: ${produit.quantite.toInt()}",
                        style: Appstyle.textSB.copyWith(
                          color: totalDistribue() > produit.quantite.toInt()
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Appstyle.gris.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          decoration: BoxDecoration(
                            color: Appstyle.gris.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(flex: 2, child: Text(l10n.code,
                                  style: const TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 4, child: Text(l10n.store,
                                  style: const TextStyle(fontWeight: FontWeight.bold))),
                              Expanded(flex: 2, child: Text(l10n.quantity,
                                  style: const TextStyle(fontWeight: FontWeight.bold))),
                              const SizedBox(width: 40),
                            ],
                          ),
                        ),
                        const Divider(height: 6),

                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              children: magasinsDistribues.map((m) {
                                TextEditingController ctrl = controllers[m.id]!;

                                // ✅ Vérifier si c'est un magasin système
                                final bool systemStore = isSystemStore(m.magasinCode);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    children: [
                                      Expanded(flex: 2, child: Text(m.magasinCode, style: Appstyle.textSB)),
                                      Expanded(
                                        flex: 4,
                                        child: Row(
                                          children: [
                                            Expanded(child: Text(magasinNomByCode(m.magasinCode), style: Appstyle.textSB)),
                                            if (systemStore)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.orange.withOpacity(0.2),
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(color: Colors.orange),
                                                ),
                                                child: const Text(
                                                  "Système",
                                                  style: TextStyle(fontSize: 10, color: Colors.orange),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: TextField(
                                          controller: ctrl,
                                          keyboardType: TextInputType.number,
                                          enabled: true, // ✅ Toujours activé, même pour le magasin système
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                                            // ✅ Pas de fond grisé pour le magasin système
                                          ),
                                          onChanged: (val) {
                                            setState(() {
                                              m.quantite = double.tryParse(val) ?? 0;
                                              controllers[m.id]?.text = val;
                                            });
                                          },
                                        ),
                                      ),
                                      // ✅ NE PAS afficher le bouton supprimer si c'est un magasin système
                                      if (!systemStore)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              magasinsDistribues.remove(m);
                                              controllers.remove(m.id);
                                            });
                                          },
                                        )
                                      else
                                      // ✅ Espace réservé pour maintenir l'alignement
                                        const SizedBox(width: 40),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
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
                    text: l10n.distribute,
                    color: Appstyle.violet,
                    icon: Icons.save,
                    onPressed: () async {
                      if (totalDistribue() > produit.quantite.toInt()) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.distributionExceedsStock)),
                        );
                        return;
                      }

                      // ✅ Passer les données originales pour comparaison
                      await UpdateDistribution(
                          userCode: userCode,
                          userName: userName,
                          ODetail: originalDetails,  // ✅ Utiliser la copie originale
                          UDetail: magasinsDistribues
                      );

                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}