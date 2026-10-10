import 'package:collection/collection.dart';
import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BesionList.dart';
import 'package:caisse_dz/Services/BesionListDetail.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/widget/button/ajouter_manuel.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/l10n/app_localizations.dart';

import '../../utilis/api_response.dart';
import '../../utilis/quantite_format.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// ---- CONTROLLERS ----
final TextEditingController codeControllerB           = TextEditingController();
final TextEditingController dateControllerB           = TextEditingController();
final TextEditingController montantControllerB        = TextEditingController(text: "0");
final TextEditingController quantiteControllerB       = TextEditingController(text: "0");
final TextEditingController observationControllerB    = TextEditingController();
final TextEditingController nombreArticleControllerB  = TextEditingController(text: "0");

// Controllers persistants des lignes produit (clé = code produit). Les
// recréer à chaque frappe (comme avant, dans le itemBuilder) fait retomber
// le curseur en position 0 après chaque caractère et donne l'impression
// d'une saisie "inversée" — voir tableProduits().
final Map<String, TextEditingController> quantiteControllersProduitB = {};
final Map<String, TextEditingController> prixControllersProduitB     = {};

List<BesoinListDetail>  produitsBesoin        = [];
List<Produit>           produitsSelectionnes  = [];
List<Produit>           produitsTest          = [];
List<Fournisseur>       fournisseursTest      = [];

String? fournisseurSelected;
Produit? selectedProduit;

Future<int> _GetNextBesionListid() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await BesoinListServices.getNextbesionListId(txn);
  });
  return id;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveBesion({
  required List<BesoinListDetail> besionDetail,
  required BesoinList besionList,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  try {
    final services  = BesoinListServices(db);
    final serviceh  = HistoriqueServices(db);
    final serviceD  = BesoinListDetailServices(db);

    /// INSERT BESOIN LIST
    final response = await services.addbesionList(besionList);

    if (!response.success) {
      return ApiResponse(success: false, message: response.message);
    }

    /// DETAILS
    for (var detail in besionDetail) {
      detail.id = await BesoinListDetailServices.getNextBesoinListDetailId(db);
      detail.creeParCode = userCode;
      detail.besoinListCode = besionList.code;

      await serviceD.addbesion_list_detail(detail);

      int idh = await HistoriqueServices.getNextHistoriqueId(db);

      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type: "besion_list_detail",
          desc:
          "L'utilisateur $userName a ajouté le besoin du produit ${detail.ProduitNom}",
          oper: ListsConst.typeHisto[0],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }

    return ApiResponse(
      success: true,
      data: besionList.id,
      message: "BesoinList enregistrée avec succès",
    );
  } catch (e) {
    return ApiResponse(
      success: false,
      message: "Erreur lors de l'enregistrement : $e",
    );
  }
}

Future<void> _LoadAllData() async {
  produitsTest      = await ProduitServices     .getAllProduits();
  fournisseursTest  = await FournisseurServices .getAllFournisseurs();
}

void recalculerTotaux() {
  nombreArticleControllerB.text = produitsBesoin.length.toString();
  final quantiteTotale      = produitsBesoin.fold(0.0, (s, p) => s + p.quantite);
  quantiteControllerB.text  = NumberFormatUtil.formatMontant(quantiteTotale, decimales: 0);
  final montantTotal      = produitsBesoin.fold(0.0, (s, p) => s + p.montant);
  montantControllerB.text = montantTotal.toStringAsFixed(2);
}

void _clearProduitsBesoinControllers() {
  for (final c in quantiteControllersProduitB.values) {
    c.dispose();
  }
  for (final c in prixControllersProduitB.values) {
    c.dispose();
  }
  quantiteControllersProduitB.clear();
  prixControllersProduitB.clear();
}

void resetBesoinForm() {
  dateControllerB.clear();
  nombreArticleControllerB.text   = "0";
  quantiteControllerB.text        = "0";
  montantControllerB.text         = "0";
  observationControllerB.clear();
  fournisseurSelected = null;
  selectedProduit = null;
  produitsBesoin.clear();
  produitsSelectionnes.clear();
  _clearProduitsBesoinControllers();
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> BesoinListNouveau(BuildContext context, List<Fournisseur> fournisseursList) async{
  await _LoadAllData();

  produitsBesoin.clear();
  _clearProduitsBesoinControllers();
  recalculerTotaux();
  dateControllerB.text  = "";
  fournisseurSelected   = fournisseursTest.first.nom;

  // ✅ Aperçu de la référence (l'id réel est refetché à la sauvegarde)
  final int previewId = await _GetNextBesionListid();
  codeControllerB.text = CodeGenerator.generateCode(
    prefix: CodePrefix.besoinListe,
    id: previewId,
    digitCount: 6,
  );

  final auth = Provider.of<AuthState>(context, listen: false);

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

  final String userName = auth.username!;
  final String userCode = auth.userCode!;

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return BaseDialog(
            width: 900,
            height: 920,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/cardwidget/scan_out_icon.png',
              text: l10n.newNeedList,
            ),
            content: Form(
              key: produitFormKey,
              child: Column(
                children: [
                  // ================= INFOS =================
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== COLONNE GAUCHE =====
                      Expanded(
                        child: Column(
                          children: [
                            ChampAvecLabel(
                              label : l10n.code,
                              child : TextChampL(
                                controller  : codeControllerB,
                                enabled     : false,
                                hint        : '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label       : l10n.date,
                              obligatoire : true,
                              child       : TextDate(
                                obligatoire : true,
                                controller  : dateControllerB,
                                hint        : l10n.selectDatew,
                                onTap       : () async {
                                  final d = await showDatePicker(
                                    initialDate : DateTime.now(),
                                    firstDate   : DateTime(2020),
                                    lastDate    : DateTime(2030),
                                    context     : context,
                                  );
                                  if (d != null) {
                                    dateControllerB.text = "${d.day}/${d.month}/${d.year}";
                                    setState(() {});
                                  }
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label           : l10n.supplier,
                              obligatoire     : true,
                              buttonAjout     : true,
                              onAjoutPressed  : () async {
                                await showDialog(
                                  context       : context,
                                  barrierColor  : Appstyle.gris.withOpacity(0.25),
                                  builder       : (_) {
                                    return InsertionFournisseurDialog(
                                      fournisseurs          : fournisseursTest,
                                      onFournisseurSelected : (fournisseur) {
                                        setState(() {
                                          fournisseurSelected = fournisseur.nom;
                                        });
                                      },
                                    );
                                  },
                                );
                              },
                              child: TextListe(
                                obligatoire : true,
                                clearable: false,
                                value : fournisseurSelected,
                                items : fournisseursList.map((e) => e.nom).toList(),
                                onChanged : (v) =>
                                    setState(() => fournisseurSelected = v ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label : l10n.observation,
                              child : TextChampL(
                                controller  : observationControllerB,
                                maxLines    : 1,
                                hint        : l10n.addObservation,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 20),

                      // ===== COLONNE DROITE =====
                      Expanded(
                        child : Column(
                          children  : [
                            ChampAvecLabel(
                              label : l10n.totalAmount,
                              child : TextChampL(
                                controller  : montantControllerB,
                                enabled     : false,
                                hint        : '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label : l10n.numberOfArticles,
                              child : TextChampL(
                                controller  : nombreArticleControllerB,
                                enabled     : false,
                                hint        : '',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ChampAvecLabel(
                              label : l10n.totalQuantity,
                              child : TextChampL(
                                controller  : quantiteControllerB,
                                enabled     : false,
                                hint        : '',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  Column(
                    crossAxisAlignment  : CrossAxisAlignment.start,
                    children  : [
                      headerTableProduits(l10n),
                      const SizedBox(height: 6),
                      tableProduits(setState, l10n),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap : () => ouvrirInsertionProduit(context, setState, l10n),
                        child : const AddManualWidget(),
                      ),
                    ],
                  ),
                  // ================= PRODUITS =================
                ],
              ),
            ),

            footer  : Row(
              mainAxisAlignment : MainAxisAlignment.end,
              children  : [
                MainButton(
                  text      : l10n.cancel,
                  icon      : Icons.cancel,
                  color     : Appstyle.gris,
                  onPressed : () {
                    resetBesoinForm();
                    Navigator.pop(context);
                  },
                ),

                const SizedBox(width: 10),
                MainButton(
                  text      : l10n.save,
                  icon      : Icons.save,
                  color     : Appstyle.violet,
                  onPressed : () async{
                    // ❌ Validation formulaire
                    if (!produitFormKey.currentState!.validate()) {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.besoinList,
                        message: l10n.fillRequiredFields,
                      );
                      return;
                    }

                    int id = await _GetNextBesionListid();
                    final String besionListCode = CodeGenerator.generateCode(
                      prefix: CodePrefix.besoinListe,
                      id: id,
                      digitCount: 6,
                    );
                    BesoinList besionList = BesoinList(
                      id            : id,
                      code          : besionListCode,
                      numero        : "BL $id",
                      date          : DateFormat('dd/MM/yyyy').parse(dateControllerB.text),
                      montant       : double.parse(montantControllerB.text),
                      nombreArticle : int.parse(nombreArticleControllerB.text),
                      quantite      : double.parse(quantiteControllerB.text),
                      fournisseurCode : fournisseursTest.firstWhere((f) => f.nom == fournisseurSelected!).code,
                      etat          : true,
                      dateCree      : DateTime.now(),
                      creeParCode   : userCode,
                      observation   : observationControllerB.text,
                    );

                    final response = await _SaveBesion(
                        besionDetail  : produitsBesoin,
                        besionList    : besionList,
                        userName      : userName,
                        userCode      : userCode
                    );

                    // ❌ ERREUR
                    if (!response.success) {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.besoinList,
                        message: response.message ,
                      );
                      return;
                    }

                    // ✅ Historique
                    final int idH = await _GetNextHistoriqueId();
                    final db = await DbCreator.openDb();
                    final serviceh = await HistoriqueServices(db);

                    final Historique histo = Historique(
                      id: idH,
                      code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
                      desc: "L'utilisateur $userName a ajouté un nouveau besoinlist sous le code de $besionListCode",
                      oper: ListsConst.typeHisto[0],
                      type: "BesoinList",
                      dateCree: DateTime.now(),
                      creeParCode: userCode,
                    );

                    // ✅ SUCCÈS
                    await InformationDialog(
                      onTerminer:  (){
                        Navigator.pop(context);
                        resetBesoinForm();
                      },
                      context: context,
                      titre_type_message: l10n.success,
                      titre_concerne: "BesoinList",
                      message: response.message,
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget tableProduits(
    void Function(void Function()) setState,
    AppLocalizations l10n,
    ) {
  if (produitsBesoin.isEmpty) {
    return Padding(
      padding : const EdgeInsets.symmetric(vertical: 8),
      child   : Align(
        alignment : Alignment.center,
        child     : Text(l10n.noProduct,
            style : Appstyle.textSB.copyWith(color  : Appstyle.gris)),
      ),
    );
  }

  return SizedBox(
    height  : 205,
    child   : ListView.builder(
      itemCount   : produitsBesoin.length,
      itemBuilder : (_, i) {
        final p         = produitsBesoin[i];
        // Unité du produit : 'Pièce' => quantité entière.
        final uniteLigne = produitsTest.firstWhereOrNull((x) => x.code == p.ProduitCode)?.uniteMesure;
        final qCtrl     = quantiteControllersProduitB.putIfAbsent(
            p.ProduitCode, () => TextEditingController(text: QuantiteFormat.formatPour(p.quantite, uniteLigne)));
        final prixCtrl  = prixControllersProduitB.putIfAbsent(
            p.ProduitCode, () => TextEditingController(text: p.prix.toString()));

        void update() {
          setState(() {
            p.quantite  = double.tryParse(qCtrl.text)    ?? 1;
            p.prix      = double.tryParse(prixCtrl.text) ?? 0;
            p.montant   = p.quantite * p.prix;
            recalculerTotaux();
          });
        }

        return Padding(
          padding : const EdgeInsets.symmetric(vertical: 4),
          child   : Row(
            children  : [
              Expanded(flex : 3, child: Text(p.ProduitNom, style: Appstyle.textSB)),
              Expanded(
                flex  : 2,
                child : TextField(
                  controller    : qCtrl,
                  keyboardType  : TextInputType.number,
                  inputFormatters: QuantiteFormat.inputFormattersPour(uniteLigne),
                  decoration    : const InputDecoration(isDense: true),
                  onChanged     : (_) => update(),
                ),
              ),

              Expanded(
                flex  : 2,
                child : TextField(
                  controller    : prixCtrl,
                  keyboardType  : TextInputType.number,
                  decoration    : const InputDecoration(isDense: true),
                  onChanged     : (_) => update(),
                ),
              ),

              Expanded(
                flex  : 2,
                child : Text(
                  NumberFormatUtil.formatMontant(p.montant, decimales: 2),
                  style : Appstyle.textSB.copyWith(color: Appstyle.violet),
                ),
              ),

              IconButton(
                icon      : const Icon(Icons.delete, color: Appstyle.danger),
                onPressed : () {
                  setState(() {
                    produitsBesoin.removeAt(i);
                    quantiteControllersProduitB.remove(p.ProduitCode)?.dispose();
                    prixControllersProduitB.remove(p.ProduitCode)?.dispose();
                    recalculerTotaux();
                  });
                },
              ),
            ],
          ),
        );
      },
    ),
  );
}

void ouvrirInsertionProduit(
    BuildContext context,
    void Function(void Function()) setParentState,
    AppLocalizations l10n,
    ) {
  showDialog(
    context : context,
    builder : (_) => InsertionProduitDialog(
      newButton:false,
      filtreBesion: true,
      multiselection    : true,
      produits          : produitsTest,
      onProduitSelected: (Produit produit) {
        /// ✅ Ignore silencieusement si déjà ajouté
        if (produitExisteDeja(produit.code)) {
          return;
        }

        setParentState(() {
          produitsBesoin.add(
            BesoinListDetail(
              id              : 1,
              prix            : produit.prixAchat,
              quantite        : 0,
              montant         : 0,
              dateCree        : DateTime.now(),
              ProduitNom      : produit.nom,
              ProduitCode     : produit.code,
              creeParCode     : "userCode",
              besoinListCode  : '',
            ),
          );

          recalculerTotaux();
        });
      },
    ),
  );
}

bool produitExisteDeja(String produitCode) {
  return produitsBesoin.any(
        (p) => p.ProduitCode == produitCode,
  );
}

Widget headerTableProduits(AppLocalizations l10n) {
  return Container(
    padding     : const EdgeInsets.symmetric(vertical: 6),
    decoration  : BoxDecoration(
      color         : Appstyle.gris.withOpacity(0.08),
      borderRadius  : BorderRadius.circular(Appstyle.radiusSM),
    ),
    child : Row(
      children  : [
        Expanded(
          flex  : 3,
          child : Text(
              l10n.product,
              style : Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex  : 2,
          child : Text(
              l10n.quantity,
              style : Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex  : 2,
          child : Text(
              l10n.price,
              style : Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        Expanded(
          flex  : 2,
          child : Text(
              l10n.amount,
              style : Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 40), // espace pour l'icône delete
      ],
    ),
  );
}