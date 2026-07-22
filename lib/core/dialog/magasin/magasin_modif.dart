import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/magasin.dart';
import '../../../Services/Historique.dart' hide ApiResponse;
import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import '../insertion_produit.dart';

List<Produit> produitsMagasin = [];
List<Produit> produitsTest    = [];
List<ProduitMagasinDetail> produitsMagasinsTest = [];

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
    id = await ProduitMagasinDetailServices.getNextId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateMagasin({
  required Magasin magasin,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await MagasinServices(db);
  final serviceh = await HistoriqueServices(db);

  // Check if a store with the same name exists (but different id)
  final existingPack = await db.query(
    'magasins',
    where: 'nom = ? AND id != ?',
    whereArgs: [magasin.nom, magasin.id],
  );

  if (existingPack.isNotEmpty) {
    return ApiResponse(
      success: false,
      message: "Un magasin avec ce nom existe déjà",
    );
  }

  final response = await services.updateMagasin(magasin);

  // ✅ Ajouter l'historique de modification
  if (response.success) {
    final int idH = await _GetNextHistoriqueId();
    final Historique histo = Historique(
      id: idH,
      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
      desc: "L'utilisateur $userName a modifié le magasin ${magasin.nom}",
      type: "Magasin",
      oper: ListsConst.typeHisto[1],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo);
  }

  return response;
}

Future<void> _savePackDetail({
  required List<ProduitMagasinDetail> produitsMagasin,
  required Magasin magasin,
  required List<ProduitMagasinDetail> original,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitMagasinDetailServices(db);
  final serviceh = await HistoriqueServices(db);

  int i = 0;
  for(var produit in original){
    i = 0;
    for(var prd in produitsMagasin){
      if (prd.produitCode == produit.produitCode){
        break;
      }
      i++;
    }
    if(i == produitsMagasin.length){
      await service.deleteDetailes(produit.produitCode, magasin.code);
      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "L'utilisateur $userName a supprimé le ProduitMagasinDetail ${produit.produitCode} du magasin ${magasin.nom}",
        type: "ProduitMagasinDetail",
        oper: ListsConst.typeHisto[1],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histo);
    }
  }

  for (var produit in produitsMagasin) {
    final detail = ProduitMagasinDetail(
      magasinCode : magasin.code,
      produitCode : produit.produitCode,
      dateCree    : DateTime.now(),
      id          : await _GetNextDetailId(),
      creeParCode : userCode,
    );
    final response = await service.addProduitMagasinDetail(detail);
    if(response == 0){
      print("le produit ${produit.produitCode} est deja existe ");
    } else {
      final int idH = await _GetNextHistoriqueId();
      final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "L'utilisateur $userName a ajouté ${produit.produitCode} au magasin ${magasin.nom}",
        type: "ProduitMagasinDetail",
        oper: ListsConst.typeHisto[1],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histo);
    }
  }
  print('Magasin details synced for ${magasin.nom}');
}

// Controllers pour le formulaire
final TextEditingController nomControllerM = TextEditingController();
final TextEditingController observatoinControllerM = TextEditingController();
final TextEditingController adresseControllerM = TextEditingController();
List<ProduitMagasinDetail> produitsMagasinSelectionnes = [];

// Dropdown
String? selectedEtatM;

Future<void> laodAlldata({required Magasin magasine}) async {
  final db = await DbCreator.openDb();
  final produit = await ProduitServices.getAllProduits();
  final detail  = await ProduitMagasinDetailServices(db).getDetailsByMagasin(magasine.code);
  produitsTest  = produit;
  produitsMagasinsTest = detail;
}

void resetMagasinForm() {
  nomControllerM.clear();
  observatoinControllerM.clear();
  adresseControllerM.clear();
  selectedEtatM = "actif";
  produitsMagasin.clear();
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> MagasinModif(BuildContext context, Magasin magasin) async {
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

  final l10n = AppLocalizations.of(context)!;

  // ✅ Sauvegarder l'ancien nom
  final String oldMagasinNom = magasin.nom;

  // Initialisation des champs avec les valeurs existantes
  nomControllerM.text = magasin.nom;
  observatoinControllerM.text = magasin.observation ?? "";
  adresseControllerM.text = magasin.adresse ?? "";
  selectedEtatM = magasin.etat ? l10n.active : l10n.inactive;

  await laodAlldata(magasine: magasin);
  produitsMagasinSelectionnes = produitsMagasinsTest
      .where((e) => e.magasinCode == magasin.code)
      .toList();

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
                width: 900,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.modifyStore,
                ),

                content: Form(
                  key: produitFormKey,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ────────────── COLONNE GAUCHE ──────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ChampAvecLabel(
                                  label: l10n.name,
                                  obligatoire: true,
                                  child: TextChampL(
                                    obligatoire: true,
                                    controller: nomControllerM,
                                    enabled: true,
                                    hint: l10n.storeNameHint,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ChampAvecLabel(
                                  label: l10n.observation,
                                  child: TextChampL(
                                    controller: observatoinControllerM,
                                    enabled: true,
                                    hint: l10n.observationHint,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 20),

                          // ────────────── COLONNE DROITE ──────────────
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ChampAvecLabel(
                                  label: l10n.address,
                                  child: TextChampL(
                                    controller: adresseControllerM,
                                    enabled: true,
                                    hint: l10n.storeAddressHint,
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ChampAvecLabel(
                                  label: l10n.status,
                                  child: TextListe(
                                    value: selectedEtatM,
                                    clearable: false,
                                    items: [l10n.active, l10n.inactive],
                                    onChanged: (v) => setState(() {
                                      selectedEtatM = v;
                                    }),
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
                      _tableProduitsMagasin(setState, l10n),

                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => _ajouterProduitMagasin(context, setState, magasin, l10n),
                        child: const AddManualWidget(),
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
                      icon: Icons.save,
                      onPressed: () async {
                        // ❌ Validation formulaire
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.store,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        final String newMagasinNom = nomControllerM.text.trim();
                        final bool nomChanged = oldMagasinNom != newMagasinNom;

                        // ✅ Confirmation avant modification
                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyStore,
                          message: nomChanged
                              ? "Êtes-vous sûr de vouloir modifier le nom du magasin '$oldMagasinNom' en '$newMagasinNom' ?\n\n⚠️ Cela mettra à jour automatiquement tous les produits associés."
                              : "Êtes-vous sûr de vouloir modifier ce magasin ?",
                          onConfirmer: () async {
                            // Création de l'objet Magasin modifié
                            Magasin magasinU = Magasin(
                              observation: observatoinControllerM.text,
                              adresse: adresseControllerM.text,
                              dateModif: DateTime.now(),
                              modifPar: userName,
                              dateCree: magasin.dateCree,
                              etat: selectedEtatM == l10n.active,
                              code: magasin.code,
                              nom: newMagasinNom,
                              id: magasin.id,
                              creeParCode: magasin.creeParCode,
                            );

                            // Appel du service pour modifier le magasin
                            final response = await _UpdateMagasin(
                              magasin: magasinU,
                              userName: userName,
                              userCode: userCode,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.store,
                                message: response.message ?? "Une erreur est survenue lors de la modification.",
                              );
                              return;
                            }

                            // Mise à jour des produits liés au magasin
                            await _savePackDetail(
                              produitsMagasin: produitsMagasinSelectionnes,
                              magasin: magasinU,
                              original: produitsMagasinsTest,
                              userName: userName,
                              userCode: userCode,
                            );

                            // ✅ Succès
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.store,
                              message: nomChanged
                                  ? "Magasin modifié avec succès.\n\nTous les produits associés ont été mis à jour."
                                  : l10n.modifySuccess,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
                            );

                            resetMagasinForm();
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

Widget _tableProduitsMagasin(void Function(void Function()) setState, AppLocalizations l10n) {
  if (produitsMagasinSelectionnes.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        l10n.noProductsAdded,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
    );
  }

  return Container(
    height: 315,
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      children: [
        // HEADER (fixe)
        Row(
          children: [
            Expanded(flex: 2, child: Text(l10n.code, style: Appstyle.textSB)),
            Expanded(flex: 4, child: Text(l10n.product, style: Appstyle.textSB)),
            const SizedBox(width: 40),
          ],
        ),
        const Divider(),

        // 👇 ZONE SCROLLABLE
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: produitsMagasinSelectionnes.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(flex: 2, child: Text(p.produitCode)),
                      Expanded(
                        flex: 4,
                        child: Text(
                          produitsTest.firstWhereOrNull((pr) => pr.code == p.produitCode)?.nom ?? p.produitCode,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            produitsMagasinSelectionnes.remove(p);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    ),
  );
}

void _ajouterProduitMagasin(
    BuildContext context,
    void Function(void Function()) setState,
    Magasin magasin,
    AppLocalizations l10n,
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      multiselection: true,
      produits: produitsTest,
      onProduitSelected: (produit) {
        final existe = produitsMagasinSelectionnes.any(
              (p) => p.produitCode == produit.code && p.magasinCode == magasin.code,
        );

        if (existe) {
          return;
        }

        setState(() {
          produitsMagasinSelectionnes.add(
            ProduitMagasinDetail(
              produitCode : produit.code,
              magasinCode : magasin.code,
              creeParCode : userCode,
              dateCree    : DateTime.now(),
              id          : 0,
            ),
          );
        });
      },
    ),
  );
}