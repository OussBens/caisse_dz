import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;  // Ajouter cet import
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';  // Ajouter cet import
import 'package:caisse_dz/core/dialog/sortie/sortie_nouveau.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';  // Ajouter cet import
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Services/Entree.dart';
import '../../../data/models/entree.dart';
import '../../../data/models/mouvement.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

String? selectedEtatR;
String? selectedProduitE;
String? selectedFournisseurE;  // Nouveau champ pour le fournisseur

List<Produit> produitsTestE = [];
List<Fournisseur> fournisseursTestE = [];  // Nouvelle liste pour les fournisseurs

Future<void> _LoadAllData() async {
  produitsTestE = await ProduitServices.getAllProduits();
  fournisseursTestE = await FournisseurServices.getAllFournisseurs();  // Charger les fournisseurs
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateEntree({
  required Entree entree,
  required Mouvement mouv,
  required String userName,
  required String userCode,
  required double originalQte,
}) async {
  final db = await DbCreator.openDb();
  final serviceE = EntreeServices(db);
  final serviceM = MouvementsServices(db);
  final serviceP = ProduitServices(db);
  final serviceH = HistoriqueServices(db);

  // Récupérer le code du fournisseur sélectionné
  if (selectedFournisseurE != null) {
    final fournisseur = fournisseursTestE.firstWhere((f) => f.nom == selectedFournisseurE);
    entree.fournisseurCode = fournisseur.code;
  }

  final response = await serviceE.updateEntree(entree);

  mouv.quantite = entree.quantite;
  mouv.prixVente = entree.prix;
  mouv.codeProduit = entree.produitcode;
  mouv.date = entree.date;
  mouv.dateModif = DateTime.now();
  mouv.modifParCode = userCode;
  mouv.type = "Entrée";
  await serviceM.updateMouvement(mouv);

  final produits = await ProduitServices.getAllProduits();
  final prod = produits.where((p) => p.code == entree.produitcode).first;
  prod.quantite += (entree.quantite - originalQte);
  prod.modifParCode = userCode;
  prod.dateModif = DateTime.now();
  await serviceP.updateProduit(prod);

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: idh,
    code: "HE$idh${DateTime.now().millisecondsSinceEpoch}",
    type: "entree",
    desc: "L'utilisateur $userName a modifié l'entrée du produit ${prod.nom}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceH.addHistorique(histo);

  return response;
}

final GlobalKey<FormState> entreeFormKey = GlobalKey<FormState>();

Future<void> EntreeModif(BuildContext context, Entree entree) async {
  await _LoadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;
  double originalQte = entree.quantite;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  TextEditingController codeControllerE = TextEditingController();
  TextEditingController prixControllerE = TextEditingController();
  TextEditingController produitCodeControllerE = TextEditingController();
  TextEditingController montantControllerE = TextEditingController();
  TextEditingController quantiteControllerE = TextEditingController();
  TextEditingController observationControllerE = TextEditingController();
  TextEditingController dateControllerE = TextEditingController();
  Produit? prod = produitsTestE.where((p) => p.code == entree.produitcode).cast<Produit?>().firstWhere((p) => true, orElse: () => null);

  selectedProduitE = prod?.nom;
  // Récupérer le fournisseur actuel de l'entrée
  selectedFournisseurE = fournisseursTestE.where((f) => f.code == entree.fournisseurCode).firstOrNull?.nom;

  void calculerMontantE() {
    final double qte = double.tryParse(quantiteControllerE.text.replaceAll(',', '.')) ?? 0;
    final double prix = double.tryParse(prixControllerE.text.replaceAll(',', '.')) ?? 0;
    final String montant = (qte * prix).toStringAsFixed(2);

    montantControllerE.value = TextEditingValue(
      text: montant,
      selection: TextSelection.collapsed(offset: montant.length),
    );
  }

  codeControllerE.text = entree.code;
  produitCodeControllerE.text = prod!.code;
  quantiteControllerE.text = entree.quantite.toString();
  prixControllerE.text = entree.prix.toStringAsFixed(2);
  montantControllerE.text = entree.montant.toStringAsFixed(2);
  dateControllerE.text = "${entree.date}";
  observationControllerE.text = entree.observation ?? "";

  quantiteControllerE.removeListener(calculerMontantE);
  quantiteControllerE.addListener(calculerMontantE);

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
              height: 480,  // Augmenter la hauteur
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/entree_rapide_icon.png',
                text: l10n.modifyEntry,
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
                                hint: '',
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
                                        prod = p;
                                        selectedProduitE = p.nom;
                                        produitCodeControllerE.text = p.code;
                                        prixControllerE.text = p.prixVente.toStringAsFixed(2);
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
                                onChanged: (v) {
                                  setState(() {
                                    selectedProduitE = v;
                                    prod = produitsTestE.where((p) => p.nom == v).first;
                                    produitCodeControllerE.text = prod!.code;
                                    prixControllerE.text = prod!.prixVente.toStringAsFixed(2);
                                    calculerMontantE();
                                  });
                                },
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
                                controller: dateControllerE,
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    firstDate: DateTime(2020),
                                    lastDate: DateTime(2100),
                                    initialDate: entree.date,
                                  );
                                  if (d != null) dateControllerE.text = "$d";
                                },
                                hint: '',
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
                            // NOUVEAU CHAMP FOURNISSEUR
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
                                controller: quantiteControllerE,
                                numeric: true,
                                hint: '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label: l10n.price,
                              child: TextChampL(
                                controller: prixControllerE,
                                enabled: false,
                                numeric: true,
                                hint: '',
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
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.modify,
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

                      // Validation du fournisseur
                      if (selectedFournisseurE == null || selectedFournisseurE!.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.supplierRequired,
                        );
                        return;
                      }

                      // ✅ Validation de la quantité (doit être > 0)
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

                      // ✅ Validation du prix (doit être > 0)
                      final double prix = double.tryParse(prixControllerE.text) ?? 0;
                      if (prix <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          titre_concerne: l10n.entry,
                          message: l10n.priceMustBeGreaterThanZero,
                        );
                        return;
                      }

                      entree.date = DateTime.parse(dateControllerE.text);
                      entree.produitcode = prod!.code;
                      entree.quantite = double.parse(quantiteControllerE.text);
                      entree.prix = double.parse(prixControllerE.text);
                      entree.montant = double.parse(montantControllerE.text);
                      entree.observation = observationControllerE.text;
                      entree.modifParCode = userCode;
                      entree.dateModif = DateTime.now();

                      Mouvement mouv = Mouvement(
                        id: entree.id,
                        code: "MV${entree.id}${DateTime.now().millisecondsSinceEpoch}",
                        date: entree.date,
                        codeProduit: entree.produitcode,
                        quantite: entree.quantite,
                        prixVente: entree.prix,
                        type: "Entrée",
                        etat: true,
                        codeOperation: entree.code,
                        dateCree: DateTime.now(),
                        creeParCode: userCode,
                        prixAchat: 100,
                      );

                      final response = await _UpdateEntree(
                        entree: entree,
                        mouv: mouv,
                        userName: userName,
                        userCode: userCode,
                        originalQte: originalQte,
                      );

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
                        message: response.message ?? l10n.entryModifiedSuccess,
                        onTerminer: () => Navigator.pop(context),
                      );
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