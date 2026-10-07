import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:caisse_dz/DBCreate.dart';

import 'package:caisse_dz/Services/BesionListDetail.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/BesionList.dart';

import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/button/ajouter_manuel.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';

import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/data/models/produit.dart';

import 'package:caisse_dz/core/Auth/auth_state.dart';

import '../../utilis/api_response.dart';
import '../../utilis/quantite_format.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// ---- CONTROLLERS ----
final TextEditingController codeControllerB           = TextEditingController(text: "BSL00001");
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

List<BesoinListDetail>  produitsBesoin        = [];
List<BesoinListDetail>  details               = [];
List<Produit>           produitsSelectionnes  = [];
List<Produit>           produitsTest          = [];

List<BesoinListDetail> originalDetails = [];

List<Fournisseur> fournisseursList = [];
String?           fournisseurSelected;
Produit?          selectedProduit;

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _UpdateBL({
  required List<BesoinListDetail> details,
  required List<BesoinListDetail> original,
  required BesoinList             besionList,
  required String                 userName,
  required String                 userCode,
}) async {
  final db        = await DbCreator.openDb();
  final services  = BesoinListServices(db);
  final serviced  = BesoinListDetailServices(db);
  final serviceh  = HistoriqueServices(db);

  // 1️⃣ Update header
  final response = await services.updatebesionList(besionList);

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id          : idh,
      code        : "HS$idh${DateTime.now().millisecondsSinceEpoch}",
      type        : "besionList",
      desc        : "L'utilisateur $userName a Modifier Les information de Besion List ${besionList.numero}",
      oper        : ListsConst.typeHisto[1],
      dateCree    : DateTime.now(),
      creeParCode : userCode
  );
  await serviceh.addHistorique(histo);

  // 2️⃣ Supprimer les détails supprimés
  for (var old in original) {
    final exists = details.any((d) => d.id == old.id);
    if (!exists) {
      /// supprimer detail
      await serviced.deletebesion_list_detail(old.id);

      /// historique
      int idh = await _GetNextHistoriqueId();

      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type: "besion_list_detail",
          desc: "L'utilisateur $userName a supprimé ${old.ProduitNom} de ${besionList.numero}",
          oper: ListsConst.typeHisto[1],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }
  }

  // 3️⃣ Ajouter ou modifier
  for (var detail in details) {
    if (detail.id == 0) {
      await serviced.addbesion_list_detail(detail);

      int idh = await _GetNextHistoriqueId();

      await serviceh.addHistorique(
        Historique(
          id: idh,
          code: "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type: "besion_list_detail",
          desc: "L'utilisateur $userName a ajouté ${detail.ProduitNom}",
          oper: ListsConst.typeHisto[0],
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    } else {
      // ✏️ Modifier
      final respon = await serviced.updateBesionListDetail(detail);
      print(respon.message);
      int idh = await _GetNextHistoriqueId();
      Historique histo = Historique(
          id          : idh,
          code        : "HS$idh${DateTime.now().millisecondsSinceEpoch}",
          type        : "besion_list_detail",
          desc        : "L'utilisateur $userName a Modifier les information de Besion List Detail ${detail.ProduitNom} de Besion List ${besionList.numero}",
          oper        : ListsConst.typeHisto[1],
          dateCree    : DateTime.now(),
          creeParCode : userCode
      );
      await serviceh.addHistorique(histo);
    }
  }
  return response;
}

void recalculerTotaux() {
  nombreArticleControllerB.text = produitsBesoin.length.toString();
  final quantiteTotale = produitsBesoin.fold(0.0, (s, p) => s + p.quantite);
  quantiteControllerB.text = quantiteTotale.toStringAsFixed(0);
  final montantTotal = produitsBesoin.fold(0.0, (s, p) => s + (p.montant * p.quantite));
  montantControllerB.text = montantTotal.toStringAsFixed(2);
}

Future<void> _LoadAllData() async {
  produitsTest      = await ProduitServices           .getAllProduits();
  details           = await BesoinListDetailServices  .getAllBesoinListDetail();
  fournisseursList  = await FournisseurServices.getAllFournisseurs();
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> BesoinListModifier(BuildContext context, BesoinList header,) async {
  await _LoadAllData();

  final auth      = Provider.of<AuthState>(context, listen: false);
  final userName  = auth.username;
  final userCode  = auth.userCode;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content         : Text(AppLocalizations.of(context)!.loginRequired),
        duration        : const Duration(seconds: 3),
        backgroundColor : Colors.red,
      ),
    );
    return;
  }

  // ===== Charger Header =====
  fournisseurSelected         = fournisseursList.where((f) => f.code == header.fournisseurCode).firstOrNull?.nom;

  codeControllerB.text        = header.code;
  dateControllerB.text        = "${header.date.day}/${header.date.month}/${header.date.year}";
  observationControllerB.text = header.observation ?? "";

  // ===== Charger Details =====
  _clearProduitsBesoinControllers();
  produitsBesoin = details
      .where((d) => d.besoinListCode == header.code)
      .map((d) => BesoinListDetail(
    id              : d.id,
    prix            : d.prix,
    montant         : d.montant,
    quantite        : d.quantite,
    dateCree        : d.dateCree,
    ProduitNom      : d.ProduitNom,
    ProduitCode     : d.ProduitCode,
    creeParCode     : d.creeParCode,
    besoinListCode  : header.code,
  )).toList();

  recalculerTotaux();
  originalDetails = List.from(produitsBesoin);

  return showDialog(
    context             : context,
    barrierDismissible  : false,
    barrierColor        : Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder : (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return BaseDialog(
            width   : 900,
            height  : 830,
            header  : TitreAvecLigne(
              imagePath : 'assets/icons/cardwidget/liste_icon.png',
              text      : l10n.modifyNeedList,
            ),
            content   : Form(
              key: produitFormKey,
              child: Column(
                children  : [
                  buildHeaderUI(context, setState, fournisseursList, l10n),
                  const SizedBox(height: 20),
                  headerTableProduits(l10n),
                  const SizedBox(height: 6),
                  tableProduits(setState, l10n),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => ouvrirInsertionProduit(context, setState, besoinList: header, l10n: l10n),
                    child: const AddManualWidget(),
                  ),
                ],
              ),
            ),
            footer: Row(
              mainAxisAlignment : MainAxisAlignment.end,
              children  : [
                MainButton(
                  color     : Appstyle.gris,
                  text      : l10n.cancel,
                  icon      : Icons.cancel,
                  onPressed : () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                MainButton(
                    text      : l10n.modify,
                    color     : Appstyle.violet,
                    icon      : Icons.save,
                    onPressed: () async {
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

                      /// ✅ Dialog confirmation AVANT modification
                      await ConfirmationDialog(
                          context: context,
                          titre: l10n.modifyNeedList,
                          message: l10n.confirmModifyBesoinListe,
                          onConfirmer: () async {
                            header.date = DateFormat('dd/MM/yyyy').parse(dateControllerB.text);
                            header.fournisseurCode      =   fournisseursList.firstWhere((f) => f.nom == fournisseurSelected!).code;
                            header.observation          =   observationControllerB.text;

                            header.montant        = double.parse(montantControllerB.text);
                            header.quantite       = double.parse(quantiteControllerB.text);
                            header.nombreArticle  = int.parse(nombreArticleControllerB.text);

                            header.dateModif  = DateTime.now();
                            header.modifParCode   = userCode;

                            final response = await _UpdateBL(
                              details     : produitsBesoin,
                              original    : originalDetails,
                              userName    : userName!,
                              userCode    : userCode!,
                              besionList  : header,
                            );

                            /// ❌ ERREUR
                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                kind: DialogKind.refuser,
                                titre_concerne: l10n.besoinList,
                                message: response.message ?? l10n.modificationError,
                              );
                              return;
                            }

                            /// ✅ SUCCÈS
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.besoinList,
                              message: response.message ?? l10n.modifySuccess,
                              onTerminer:() {Navigator.pop(context);},
                            );
                          }
                      );
                    }
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget buildHeaderUI(BuildContext context, void Function(void Function()) setState,
    List<Fournisseur> fournisseursList, AppLocalizations l10n) {
  return Row(
    crossAxisAlignment  : CrossAxisAlignment.start,
    children: [
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
              child : TextDate(
                obligatoire : true,
                controller  : dateControllerB,
                hint        : l10n.selectDatew,
                onTap : () async {
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
              label       : l10n.supplier,
              obligatoire : true,
              child : TextListe(
                obligatoire : true,
                clearable: false,
                value     : fournisseurSelected,
                items     : fournisseursList.map((e) => e.nom).toList(),
                onChanged : (v) => setState(() => fournisseurSelected = v),
              ),
            ),
            const SizedBox(height : 10),
            ChampAvecLabel(
              label : l10n.observation,
              child : TextChampL(
                controller    : observationControllerB,
                hint          : l10n.addObservation,
                maxLines      : 1,
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          children: [
            ChampAvecLabel(
              label : l10n.totalAmount,
              child : TextChampL(
                controller  : montantControllerB,
                enabled     : false,
                hint        : '',
              ),
            ),
            const SizedBox(height : 10),
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
  );
}

Widget headerTableProduits(AppLocalizations l10n) {
  return Container(
    padding     : const EdgeInsets.symmetric(vertical: 6),
    decoration  : BoxDecoration(
      color         : Appstyle.gris.withOpacity(0.08),
      borderRadius  : BorderRadius.circular(8),
    ),
    child : Row(
      children  : [
        Expanded(
          flex  : 3,
          child : Text(l10n.product,
              style : Appstyle.textSB.copyWith(fontWeight : FontWeight.bold)),
        ),
        Expanded(
          flex  : 2,
          child : Text(l10n.quantity,
              style : Appstyle.textSB.copyWith(fontWeight : FontWeight.bold)),
        ),
        Expanded(
          flex: 2,
          child: Text(l10n.price,
              style : Appstyle.textSB.copyWith(fontWeight : FontWeight.bold)),
        ),
        Expanded(
          flex  : 2,
          child : Text(l10n.amount,
              style : Appstyle.textSB.copyWith(fontWeight : FontWeight.bold)),
        ),
        const SizedBox(width: 40),
      ],
    ),
  );
}

Widget tableProduits(void Function(void Function()) setState, AppLocalizations l10n) {
  if (produitsBesoin.isEmpty) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Text(l10n.noProduct,
            style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
      ),
    );
  }

  return SizedBox(
    height: 195,
    child: ListView.builder(
      itemCount: produitsBesoin.length,
      itemBuilder: (_, i) {
        final p         = produitsBesoin[i];
        // Unité du produit : 'Pièce' => quantité entière.
        final uniteLigne = produitsTest.firstWhereOrNull((x) => x.code == p.ProduitCode)?.uniteMesure;
        final qCtrl     = quantiteControllersProduitB.putIfAbsent(
            p.ProduitCode, () => TextEditingController(text: QuantiteFormat.formatPour(p.quantite, uniteLigne)));
        final prixCtrl  = prixControllersProduitB.putIfAbsent(
            p.ProduitCode, () => TextEditingController(text: p.prix.toString()));

        void update() {
          setState(() {
            produitsBesoin[i].quantite  = double.tryParse(qCtrl.text) ?? 1;
            produitsBesoin[i].prix      = double.tryParse(prixCtrl.text) ?? 0;
            produitsBesoin[i].montant   = p.quantite * p.prix;
            recalculerTotaux();
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                  flex: 3,
                  child : Text(
                      produitsBesoin[i].ProduitNom,
                      style: Appstyle.textSB
                  )
              ),

              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType  : TextInputType.number,
                  inputFormatters: QuantiteFormat.inputFormattersPour(uniteLigne),
                  decoration    : const InputDecoration(isDense: true),
                  controller    : qCtrl,
                  onChanged     : (_) => update(),
                ),
              ),

              Expanded(
                flex: 2,
                child: TextField(
                  keyboardType  : TextInputType.number,
                  controller    : prixCtrl,
                  decoration    : const InputDecoration(isDense: true),
                  onChanged     : (_) => update(),
                ),
              ),

              Expanded(
                flex: 2,
                child: Text(
                  NumberFormatUtil.formatMontant(produitsBesoin[i].montant, decimales: 2),
                  style : Appstyle.textSB.copyWith(color: Appstyle.violet),
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () {
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
    {required BesoinList besoinList,
      required AppLocalizations l10n}
    ) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;

  showDialog(
    context: context,
    builder: (_) => InsertionProduitDialog(
      newButton:false,
      produits: produitsTest,
      onProduitSelected: (Produit produit) {
        setParentState(() {
          // ❌ Vérifier si le produit existe déjà
          final exists = produitsBesoin.any((p) => p.ProduitCode == produit.code);
          if (!exists) {
            produitsBesoin.add(
              BesoinListDetail(
                ProduitNom      : produit.nom,
                quantite        : 0,
                prix            : produit.prixAchat.toDouble(),
                montant         : 0,
                id              : 0,
                besoinListCode  : besoinList.code,
                ProduitCode     : produit.code,
                dateCree        : DateTime.now(),
                creeParCode     : userCode,
              ),
            );
            recalculerTotaux();
          }
        });
      },
      multiselection: true,
    ),
  );
}