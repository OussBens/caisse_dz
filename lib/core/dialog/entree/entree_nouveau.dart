import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Entree.dart';
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/entree.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../Services/Magasin.dart' hide ApiResponse;
import '../../../Services/MagasinDetail.dart';
import '../../../data/models/fournisseur.dart';
import '../../../data/models/produit_magasin_detail.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

final TextEditingController codeControllerE = TextEditingController();
final TextEditingController produitCodeControllerE = TextEditingController();
final TextEditingController quantiteControllerE = TextEditingController();
final TextEditingController prixAchatControllerE = TextEditingController(text: '0.00');
final TextEditingController prixVenteControllerE = TextEditingController(text: '0.00'); // Nouveau champ
final TextEditingController montantControllerE = TextEditingController(text: '0.00');
final TextEditingController dateControllerE = TextEditingController();
final TextEditingController observationControllerE = TextEditingController();

String? selectedProduitE;
String? selectedFournisseurE;
String founisseur = 'Géneral';

List<Produit> produitsTestE = [];
List<Fournisseur> fournisseursTestE = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}

Future<int> _GetNextEntreeId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await EntreeServices.getNextEntreeId(txn);
  });
  return id;
}

Future<void> _LoadDataE() async {
  produitsTestE = await ProduitServices.getAllProduits();
  fournisseursTestE = await FournisseurServices.getAllFournisseurs();
}

void calculerMontantE() {
  final double qte = double.tryParse(quantiteControllerE.text) ?? 0;
  final double prix = double.tryParse(prixAchatControllerE.text) ?? 0;
  montantControllerE.text = (qte * prix).toStringAsFixed(2);
}

void resetEntreeForm() {
  codeControllerE.clear();
  produitCodeControllerE.clear();
  quantiteControllerE.clear();
  prixAchatControllerE.clear();
  prixVenteControllerE.clear(); // Nouveau
  montantControllerE.clear();
  dateControllerE.clear();
  observationControllerE.clear();
  selectedProduitE = null;
  selectedFournisseurE = null;

  quantiteControllerE.removeListener(calculerMontantE);
  quantiteControllerE.addListener(calculerMontantE);
}

final GlobalKey<FormState> entreeFormKey = GlobalKey<FormState>();

Future<ApiResponse<int>> _SaveEntree({
  required Mouvement mouv,
  required String userName,
  required String userCode,
  required Entree entree,
  required double nouveauPrixVente, // Nouveau paramètre
}) async {
  final db = await DbCreator.openDb();
  final services = EntreeServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final servicep = ProduitServices(db);
  final serviceMagasinDetail = ProduitMagasinDetailServices(db);
  final serviceMagasin = MagasinServices(db);
  final serviceFournisseur = FournisseurServices(db);

  final produits = await ProduitServices.getAllProduits();

  // Récupérer le code du fournisseur sélectionné
  if (selectedFournisseurE != null) {
    final fournisseur = fournisseursTestE.firstWhere((f) => f.nom == selectedFournisseurE);
    entree.fournisseurCode = fournisseur.code;
  }

  // 1. Sauvegarder l'entrée
  final response = await services.addEntree(entree);

  // 2. Sauvegarder le mouvement
  await serviceM.addMouvement(mouv);

  // 3. Mettre à jour le produit
  final prod = produits.where((e) => e.code == entree.produitcode).first;

  final double prixAchat = entree.prix;

  // ✅ Mettre à jour la quantité
  prod.quantite += entree.quantite;

  // ✅ Mettre à jour prixAchat avec le nouveau prix
  prod.prixAchat = prixAchat;

  // ✅ Mettre à jour prixVente avec la nouvelle valeur
  prod.prixVente = nouveauPrixVente;



  // ✅ Audit
  prod.modifParCode = userCode;
  prod.dateModif = DateTime.now();

  // ✅ Mettre à jour le produit
  await servicep.updateProduit(prod);

  // 4. Mettre à jour la quantité dans produit_magasin_detail pour le magasin "System"
  try {
    final systemMagasin = await serviceMagasin.getMagasinByNom("Magasin System");

    if (systemMagasin == null) {
      print("⚠️ Magasin 'System' non trouvé");
    } else {
      final magasinDetail = await serviceMagasinDetail.getSingleByProduitAndMagasin(
          prod.code,
          systemMagasin.code
      );

      if (magasinDetail != null) {
        final nouvelleQuantite = magasinDetail.quantite + entree.quantite;
        await serviceMagasinDetail.updateQuantite(magasinDetail.id, nouvelleQuantite);
        print("✅ Quantité mise à jour pour le magasin System: $nouvelleQuantite");
      } else {
        final newDetail = ProduitMagasinDetail(
          id: await _GetNextMagasinDetailId(),
          magasinCode: systemMagasin.code,
          produitCode: prod.code,
          dateCree: DateTime.now(),
          creeParCode: userCode,
          quantite: entree.quantite,
        );
        await serviceMagasinDetail.addProduitMagasinDetail(newDetail);
        print("✅ Nouvelle ligne créée pour le magasin System avec quantité: ${entree.quantite}");
      }
    }
  } catch (e) {
    print("⚠️ Erreur lors de la mise à jour du magasin System: $e");
  }

  // 5. Mettre à jour le fournisseur
  if (selectedFournisseurE != null) {
    try {
      final fournisseur = fournisseursTestE.firstWhere((f) => f.nom == selectedFournisseurE);
      await serviceFournisseur.ajouterAchat(
        fournisseur.id,
        entree.montant,
      );
      print("✅ Fournisseur mis à jour: ${fournisseur.nom}");
    } catch (e) {
      print("⚠️ Erreur lors de la mise à jour du fournisseur: $e");
    }
  }

  // 6. Historique
  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "entree",
      desc: "L'utilisateur $userName a ajouté une entrée de produit ${prod.nom}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);

  return response;
}

Future<int> _GetNextMagasinDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitMagasinDetailServices.getNextId(txn);
  });
  return id;
}

Future<void> EntreeNouveau(BuildContext context, {VoidCallback? onSuccess}) async {
  await _LoadDataE();
  quantiteControllerE.removeListener(calculerMontantE);
  quantiteControllerE.addListener(calculerMontantE);

  int id = await _GetNextEntreeId();
  Produit? prod;
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  final code = CodeGenerator.generateCode(
    prefix: CodePrefix.entree,
    id: id,
    digitCount: 6,
  );
  codeControllerE.text = code;

  // ✅ Prix de vente par défaut = prix d'achat + 30%
  prixVenteControllerE.text = (double.tryParse(prixAchatControllerE.text) ?? 0 * 1.3).toStringAsFixed(2);

  if (!auth.isAuthenticated) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) => StatefulBuilder(
      builder: (context, setState) {
        final l10n = AppLocalizations.of(context)!;

        return ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: BaseDialog(
              width: 900,
              height: 520, // Augmenté pour le nouveau champ
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/entree_rapide_icon.png',
                text: l10n.newEntry,
              ),
              content: Form(
                key: entreeFormKey,
                child: SingleChildScrollView(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChampAvecLabel(
                              label: l10n.code,
                              child: TextChampL(
                                controller: codeControllerE,
                                enabled: false,
                                hint: "EN000001",
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.product,
                              obligatoire: true,
                              buttonAjout: true,
                              onAjoutPressed: () async {
                                await showDialog(
                                  context: context,
                                  barrierColor: Appstyle.gris.withOpacity(0.25),
                                  builder: (_) => InsertionProduitDialog(
                                    multiselection: false,
                                    produits: produitsTestE,
                                    onProduitSelected: (p) {
                                      setState(() {
                                        selectedProduitE = p.nom;
                                        prod = p;
                                        produitCodeControllerE.text = p.code;
                                        prixAchatControllerE.text = p.prixAchat.toStringAsFixed(2);
                                        // ✅ Récupérer le prix de vente du produit
                                        prixVenteControllerE.text = p.prixVente.toStringAsFixed(2);
                                        calculerMontantE();
                                      });
                                    },
                                  ),
                                );
                              },
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedProduitE,
                                items: produitsTestE.map((e) => e.nom).toList(),
                                onChanged: (v) => setState(() {
                                  selectedProduitE = v;
                                  prod = produitsTestE.where((e) => e.nom == v).first;
                                  produitCodeControllerE.text = prod!.code;
                                  prixAchatControllerE.text = prod!.prixAchat.toStringAsFixed(2);
                                  // ✅ Récupérer le prix de vente du produit
                                  prixVenteControllerE.text = prod!.prixVente.toStringAsFixed(2);
                                  calculerMontantE();
                                }),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.productCode,
                              child: TextChampL(
                                controller: produitCodeControllerE,
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
                                controller: dateControllerE,
                                hint: l10n.dateHint,
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: DateTime.now(),
                                  );
                                  if (d != null) dateControllerE.text = "$d";
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.observation,
                              child: TextChampL(
                                controller: observationControllerE,
                                hint: l10n.observationHint,
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
                              label: l10n.supplier,
                              obligatoire: true,
                              buttonAjout: true,
                              onAjoutPressed: () async {
                                await showDialog(
                                  context: context,
                                  barrierColor: Appstyle.gris.withOpacity(0.25),
                                  builder: (_) {
                                    return InsertionFournisseurDialog(
                                      fournisseurs: fournisseursTestE,
                                      onFournisseurSelected: (fournisseur) {
                                        setState(() {
                                          selectedFournisseurE = fournisseur.nom;
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                value: selectedFournisseurE,
                                items: fournisseursTestE.map((f) => f.nom).toList(),
                                onChanged: (v) {
                                  setState(() {
                                    selectedFournisseurE = v;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.quantity,
                              obligatoire: true,
                              child: TextChampL(
                                obligatoire: true,
                                controller: quantiteControllerE,
                                numeric: true,
                                hint: "0",
                                onChanged: (v) => setState(() => calculerMontantE()),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.purchasePrice,
                              obligatoire: true,
                              child: TextChampL(
                                controller: prixAchatControllerE,
                                enabled: true,
                                numeric: true,
                                hint: '',
                                onChanged: (v) => setState(() {
                                  calculerMontantE();
                                  // ✅ Mettre à jour prix vente si prix achat change
                                  final double prixAchat = double.tryParse(prixAchatControllerE.text) ?? 0;
                                  final double prixVenteActuel = double.tryParse(prixVenteControllerE.text) ?? 0;
                                  if (prixVenteActuel < prixAchat) {
                                    prixVenteControllerE.text = (prixAchat * 1.3).toStringAsFixed(2);
                                  }
                                }),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.amount,
                              child: TextChampL(
                                controller: montantControllerE,
                                enabled: false,
                                numeric: true,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            // ✅ NOUVEAU CHAMP PRIX VENTE
                            ChampAvecLabel(
                              label: l10n.salePrice,
                              obligatoire: true,
                              child: TextChampL(
                                controller: prixVenteControllerE,
                                enabled: true,
                                numeric: true,
                                hint: '',
                                onChanged: (v) {
                                  // ✅ Vérifier que prix vente > prix achat
                                  final double prixAchat = double.tryParse(prixAchatControllerE.text) ?? 0;
                                  final double prixVente = double.tryParse(prixVenteControllerE.text) ?? 0;
                                  if (prixVente <= prixAchat && prixVente > 0) {
                                    // Afficher un warning mais ne pas bloquer
                                    print("⚠️ Prix de vente doit être supérieur au prix d'achat");
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
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
                    icon: Icons.cancel,
                    color: Appstyle.gris,
                    onPressed: () {
                      resetEntreeForm();
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.save,
                    icon: Icons.save,
                    color: Appstyle.violet,
                    onPressed: () async {
                      if (!entreeFormKey.currentState!.validate()) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.fillRequiredFields,
                        );
                        return;
                      }

                      if (selectedFournisseurE == null || selectedFournisseurE!.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.supplierRequired,
                        );
                        return;
                      }

                      final double quantite = double.tryParse(quantiteControllerE.text) ?? 0;
                      if (quantite <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.quantityMustBeGreaterThanZero,
                        );
                        return;
                      }

                      final double prixAchat = double.tryParse(prixAchatControllerE.text) ?? 0;
                      if (prixAchat <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.priceMustBeGreaterThanZero,
                        );
                        return;
                      }

                      // ✅ Validation du prix de vente
                      final double prixVente = double.tryParse(prixVenteControllerE.text) ?? 0;
                      if (prixVente <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: "Le prix de vente doit être supérieur à 0",
                        );
                        return;
                      }

                      if (prixVente <= prixAchat) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: "Le prix de vente doit être supérieur au prix d'achat",
                        );
                        return;
                      }

                      Entree entree = Entree(
                        id: id,
                        code: code,
                        date: DateTime.parse(dateControllerE.text),
                        produitcode: prod!.code,
                        prix: prixAchat,
                        quantite: quantite,
                        montant: double.parse(montantControllerE.text),
                        fournisseurCode: "N/A",
                        etat: true,
                        creeParCode: userCode,
                        dateCree: DateTime.now(),
                        observation: observationControllerE.text,
                      );

                      int idm = await _GetNextMouvementId();
                      Mouvement mouv = Mouvement(
                        id: idm,
                        code: CodeGenerator.generateCodeWithTimestamp(
                          prefix: CodePrefix.mouvement,
                          id: idm,
                        ),
                        date: DateTime.parse(dateControllerE.text),
                        codeProduit: prod!.code,
                        quantite: quantite,
                        prixAchat: prod!.prixAchat,
                        prixVente: prixVente, // ✅ Utiliser le nouveau prix vente
                        type: "Entrée",
                        etat: true,
                        codeOperation: code,
                        dateCree: DateTime.now(),
                        creeParCode: userCode,
                      );

                      final response = await _SaveEntree(
                        mouv: mouv,
                        userName: userName,
                        userCode: userCode,
                        entree: entree,
                        nouveauPrixVente: prixVente, // ✅ Passer le nouveau prix vente
                      );
                      print(response.message);
                      if (!response.success) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: response.message ?? l10n.errorOccurred,
                        );
                        return;
                      }

                      await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.entry,
                          message: response.message ?? l10n.entrySavedSuccess,
                          onTerminer: () {
                            resetEntreeForm();
                            Navigator.pop(context);
                            if (onSuccess != null) {
                              onSuccess();
                            }
                          }
                      );
                    },
                  )
                ],
              ),
            ),
          ),
        );
      },
    ),
  );
}