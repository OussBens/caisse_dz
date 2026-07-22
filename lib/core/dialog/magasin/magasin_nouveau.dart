import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../data/constant.dart';
import '../../../Services/Historique.dart' hide ApiResponse;
import '../../../data/models/histore.dart';
import '../../../data/models/produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/ajouter_manuel.dart';
import '../../widget/button/main_button.dart';
import '../../widget/champ/champ_avec_label.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/text_champ_l.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/code_generateur.dart'; // ✅ Ajout de l'import
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_produit.dart';

List<Produit> produitsMagasin = [];
List<Produit> produitsTest    = [];

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveMagasin({
  required Magasin magasin,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = await MagasinServices(db);
  final serviceh = await HistoriqueServices(db);

  // 1. Sauvegarder le magasin
  final response = await services.addMagasin(magasin);

  // 2. Ajouter l'historique pour le magasin
  final int idH = await _GetNextHistoriqueId();
  final Historique histo = Historique(
    id: idH,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: idH,
    ),
    desc: "L'utilisateur $userName a ajouté un nouveau magasin: ${magasin.nom} (Code: ${magasin.code})",
    oper: ListsConst.typeHisto[0],
    type: "Magasin",
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );

  await serviceh.addHistorique(histo);

  return response;
}
Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MagasinServices.getNextMagasinId(txn);
  });
  return id;
}

Future<void> _loadData(void Function(VoidCallback fn) setState) async {
  final result = await ProduitServices.getAllProduits();
  setState(() {
    produitsTest = result;
  });
}

Future<int> _GetNextDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitMagasinDetailServices.getNextId(txn);
  });
  return id;
}

Future<void> _savePackDetail({
  required List<Produit> produitsMagasin,
  required Magasin magasin,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitMagasinDetailServices(db);

  if (userName.isEmpty || userCode.isEmpty) {
    throw Exception("Utilisateur non authentifié. Veuillez vous reconnecter.");
  }

  for (var produit in produitsMagasin) {
    final int idH = await _GetNextHistoriqueId();
    final serviceh = await HistoriqueServices(db);
    final Historique histo = Historique(
        id          : idH,
        code        : CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idH,
        ), // ✅ Utilisation du générateur
        desc        : "Creation d'un nouveau Magasin Produit detail Par ${userName}",
        type        : "Magasin",
        oper        : ListsConst.typeHisto[0],
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );

    await serviceh.addHistorique(histo);

    final detail = ProduitMagasinDetail(
      creeParCode : userCode,
      produitCode : produit.code,
      magasinCode : magasin.code,
      dateCree    : DateTime.now(),
      id          : await _GetNextDetailId(),
    );
    await service.addProduitMagasinDetail(detail);
  }

  print('${produitsMagasin.length} produit(s) saved for pack ${magasin.nom}');
}

// Controllers pour le formulaire
final TextEditingController nomControllerM = TextEditingController();
final TextEditingController observationControllerM = TextEditingController();
final TextEditingController adresseControllerM = TextEditingController();

// Dropdown ou autres options si nécessaire
String? selectedEtatM = "actif";

void resetMagasinForm() {
  nomControllerM.clear();
  observationControllerM.clear();
  adresseControllerM.clear();
  selectedEtatM = "actif";
  produitsMagasin.clear(); // 🔥 IMPORTANT
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> MagasinNouveau(BuildContext context) async {
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

  int id = await _GetNextId();

  // ✅ Utilisation du générateur de code pour le magasin
  String code = CodeGenerator.generateCode(
    prefix: CodePrefix.magasin,
    id: id,
    digitCount: 6, // "MAG000001"
  );

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          _loadData(setState);
          final translator = ListsConstTranslator(l10n);
          selectedEtatM = translator.etatDisplayList.first;
          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/magasin_icon.png',
                  text: l10n.newStore,
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
                                    hint: l10n.storeNameHint,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.observation,
                                  child: TextChampL(
                                    controller: observationControllerM,
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
                                    hint: l10n.storeAddressHint,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.status,
                                  child: TextListe(
                                    value: selectedEtatM,
                                    items: translator.etatDisplayList,
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
                      tableProduitsMagasin(setState, l10n),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () => ouvrirInsertionProduitMagasin(context, setState, l10n),
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
                      onPressed: () {
                        resetMagasinForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        // Validation des champs obligatoires
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.store,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // Création de l'objet Magasin
                        Magasin magasinN = Magasin(
                          observation: observationControllerM.text,
                          adresse: adresseControllerM.text,
                          dateCree: DateTime.now(),
                          code: code,
                          etat: selectedEtatM == l10n.active,
                          nom: nomControllerM.text,
                          id: id,
                          creeParCode: userCode,
                        );

                        // ✅ Appel du service avec les paramètres corrects
                        final response = await _SaveMagasin(
                          magasin: magasinN,
                          userName: userName,
                          userCode: userCode,
                        );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.store,
                            message: response.message ?? "Une erreur est survenue lors de l'enregistrement.",
                          );
                          return;
                        }

                        // ✅ Sauvegarde des produits du magasin
                        await _savePackDetail(
                          magasin: magasinN,
                          produitsMagasin: produitsMagasin,
                          userName: userName,
                          userCode: userCode,
                        );

                        // ✅ Succès
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.store,
                          message: l10n.createSuccess,
                          onTerminer: () {
                            resetMagasinForm();
                            Navigator.pop(context);
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

Widget tableProduitsMagasin(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
  if (produitsMagasin.isEmpty) {
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
        // HEADER fixe
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
              children: produitsMagasin.map((p) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(p.code, style: Appstyle.textSB),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(p.nom, style: Appstyle.textSB),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            produitsMagasin.remove(p);
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

Widget headerTableProduitsMagasin(AppLocalizations l10n) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: Appstyle.gris.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(l10n.code,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex: 4,
          child: Text(l10n.product,
              style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

void ouvrirInsertionProduitMagasin(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ) {
  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      multiselection: true,
      produits: produitsTest,
      onProduitSelected: (Produit produit) {
        setState(() {
          if (!produitsMagasin.any((p) => p.id == produit.id)) {
            produitsMagasin.add(produit);
          }
        });
      },
    ),
  );
}