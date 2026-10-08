import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/TransfertMagasin.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/api_response.dart';
import 'package:caisse_dz/core/utilis/stock_guard.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Transfert de marchandise entre deux magasins — distinct du module
// "Transfert" existant (lib/core/dialog/transfert/), qui déplace de l'argent
// entre deux caisses. Accessible depuis l'onglet "Transferts" de l'écran
// Magasin (pas un module séparé dans la sidebar).

String _formatDateOnlyT(DateTime d) =>
    "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

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

Future<int> _GetNextTransfertId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await TransfertMagasinServices.getNextTransfertId(txn);
  });
  return id;
}

Future<int> _GetNextMagasinDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitMagasinDetailServices.getNextId(txn);
  });
  return id;
}

/// Enregistre le transfert : la ligne `transfert_magasin`, les 2 mouvements
/// liés (Sortie@source / Entrée@destination, même codeOperation), et
/// l'ajustement du second stock parallèle "nombre" par magasin (quantite
/// n'est jamais stockée : elle se déduit du journal des mouvements).
Future<ApiResponse<int>> _SaveTransfertMagasin({
  required TransfertMagasin transfert,
  required Produit produit,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = TransfertMagasinServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final response = await services.addTransfert(transfert);
  if (!response.success) return response;

  final idmSortie = await _GetNextMouvementId();
  await serviceM.addMouvement(Mouvement(
    id: idmSortie,
    code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: idmSortie, digitCount: 8),
    date: transfert.date,
    codeProduit: produit.code,
    quantite: transfert.quantite,
    nombre: transfert.nombre,
    prixAchat: produit.prixAchat,
    prixVente: produit.prixVente,
    type: 'Transfert',
    sousType: 'Sortie',
    magasinCode: transfert.magasinSourceCode,
    etat: true,
    codeOperation: transfert.code,
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));

  final idmEntree = await _GetNextMouvementId();
  await serviceM.addMouvement(Mouvement(
    id: idmEntree,
    code: CodeGenerator.generateCode(prefix: CodePrefix.mouvement, id: idmEntree, digitCount: 8),
    date: transfert.date,
    codeProduit: produit.code,
    quantite: transfert.quantite,
    nombre: transfert.nombre,
    prixAchat: produit.prixAchat,
    prixVente: produit.prixVente,
    type: 'Transfert',
    sousType: 'Entrée',
    magasinCode: transfert.magasinDestCode,
    etat: true,
    codeOperation: transfert.code,
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));

  await _ajusterNombreTransfert(pmdService, transfert, userCode);

  final idh = await _GetNextHistoriqueId();
  await serviceh.addHistorique(Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(prefix: CodePrefix.historique, id: idh),
    type: "transfert_magasin",
    desc: "L'utilisateur $userName a transféré ${transfert.quantite.toInt()} ${produit.nom} du magasin ${transfert.magasinSourceCode} vers ${transfert.magasinDestCode}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));

  return response;
}

/// Second stock parallèle "nombre" : un transfert le décrémente côté
/// source et l'incrémente côté destination (ligne créée si le produit n'y
/// était pas encore référencé). [inverse] défait cet effet (modification).
Future<void> _ajusterNombreTransfert(
  ProduitMagasinDetailServices pmdService,
  TransfertMagasin t,
  String userCode, {
  bool inverse = false,
}) async {
  if (t.nombre == null) return;
  final magasinRetrait = inverse ? t.magasinDestCode : t.magasinSourceCode;
  final magasinAjout = inverse ? t.magasinSourceCode : t.magasinDestCode;

  final detailRetrait = await pmdService.getSingleByProduitAndMagasin(t.produitCode, magasinRetrait);
  if (detailRetrait != null && detailRetrait.nombre > 0) {
    final aDeduire = t.nombre! <= detailRetrait.nombre ? t.nombre! : detailRetrait.nombre;
    await pmdService.decrementNombre(detailRetrait.id, aDeduire);
  }

  final detailAjout = await pmdService.getSingleByProduitAndMagasin(t.produitCode, magasinAjout);
  if (detailAjout != null) {
    await pmdService.incrementNombre(detailAjout.id, t.nombre!);
  } else {
    await pmdService.addProduitMagasinDetail(ProduitMagasinDetail(
      id: await _GetNextMagasinDetailId(),
      magasinCode: magasinAjout,
      produitCode: t.produitCode,
      dateCree: DateTime.now(),
      creeParCode: userCode,
      nombre: t.nombre!,
    ));
  }
}

/// Modifie un transfert actif : la ligne `transfert_magasin`, ses 2
/// mouvements liés (même codeOperation, mis à jour sur place : produit,
/// quantité, magasins, date) et le stock "nombre" (ancien effet défait, nouvel
/// effet appliqué).
Future<ApiResponse<int>> _ModifierTransfertMagasin({
  required TransfertMagasin ancien,
  required TransfertMagasin nouveau,
  required Produit produit,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = TransfertMagasinServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final response = await services.updateTransfert(nouveau);
  if (!response.success) return response;

  final mouvements = await MouvementsServices.getAllMouvementsByCodeOper(ancien.code);
  for (final m in mouvements.where((m) => m.etat)) {
    m.codeProduit = produit.code;
    m.quantite = nouveau.quantite;
    m.nombre = nouveau.nombre;
    m.prixAchat = produit.prixAchat;
    m.prixVente = produit.prixVente;
    m.date = nouveau.date;
    m.magasinCode = m.sousType == 'Entrée' ? nouveau.magasinDestCode : nouveau.magasinSourceCode;
    m.dateModif = DateTime.now();
    m.modifParCode = userCode;
    await serviceM.updateMouvement(m);
  }

  await _ajusterNombreTransfert(pmdService, ancien, userCode, inverse: true);
  await _ajusterNombreTransfert(pmdService, nouveau, userCode);

  final idh = await _GetNextHistoriqueId();
  await serviceh.addHistorique(Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(prefix: CodePrefix.historique, id: idh),
    type: "transfert_magasin",
    desc: "L'utilisateur $userName a modifié le transfert ${nouveau.code} : "
        "${nouveau.quantite.toInt()} ${produit.nom} du magasin ${nouveau.magasinSourceCode} vers ${nouveau.magasinDestCode}",
    oper: ListsConst.typeHisto[1],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  ));

  return response;
}

List<Produit> produitsTestTM = [];
List<Magasin> magasinsDisponiblesTM = [];

final TextEditingController codeControllerTM = TextEditingController();
final TextEditingController quantiteControllerTM = TextEditingController();
final TextEditingController nombreControllerTM = TextEditingController();
final TextEditingController dateControllerTM = TextEditingController();
final TextEditingController observationControllerTM = TextEditingController();

String? selectedProduitTM;
String? selectedMagasinSourceCodeTM;
String? selectedMagasinDestCodeTM;

final GlobalKey<FormState> transfertMagasinFormKey = GlobalKey<FormState>();

Future<void> _LoadDataTM() async {
  produitsTestTM = await ProduitServices.getAllProduits();
  // Multi-magasin : source et destination parmi les magasins de
  // l'utilisateur (Admin : tous), dans leur ordre.
  final mesMagasins = AuthState().magasins;
  magasinsDisponiblesTM = (await MagasinServices.getAllMagasins())
      .where((m) => m.etat && mesMagasins.contains(m.code))
      .toList()
    ..sort((a, b) => mesMagasins.indexOf(a.code).compareTo(mesMagasins.indexOf(b.code)));
}

void resetTransfertMagasinForm() {
  codeControllerTM.clear();
  quantiteControllerTM.clear();
  nombreControllerTM.clear();
  dateControllerTM.clear();
  observationControllerTM.clear();
  selectedProduitTM = null;
  selectedMagasinDestCodeTM = null;
}

Future<void> TransfertMagasinNouveau(BuildContext context) =>
    _TransfertMagasinDialog(context);

/// Même dialog que [TransfertMagasinNouveau], pré-rempli avec [transfert].
Future<void> TransfertMagasinModif(BuildContext context, TransfertMagasin transfert) =>
    _TransfertMagasinDialog(context, existant: transfert);

Future<void> _TransfertMagasinDialog(BuildContext context, {TransfertMagasin? existant}) async {
  await _LoadDataTM();

  final auth = Provider.of<AuthState>(context, listen: false);
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  final userName = auth.username!;
  final userCode = auth.userCode!;
  final bool peutChoisirMagasin = auth.role == "Admin";

  // Un transfert annulé ne se modifie plus.
  if (existant != null && !existant.etat) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.transfer,
      message: l10n.transfersAlreadyCancelled(existant.code),
    );
    return;
  }

  final int id = existant?.id ?? await _GetNextTransfertId();
  final String code = existant?.code ??
      CodeGenerator.generateCode(prefix: CodePrefix.transfertMagasin, id: id, digitCount: 6);
  codeControllerTM.text = code;
  dateControllerTM.text = _formatDateOnlyT(existant?.date ?? DateTime.now());

  Produit? prod;

  if (existant != null) {
    // Modification : formulaire rempli avec le transfert existant.
    prod = produitsTestTM.firstWhereOrNull((p) => p.code == existant.produitCode);
    selectedProduitTM = prod?.nom;
    selectedMagasinSourceCodeTM = existant.magasinSourceCode;
    selectedMagasinDestCodeTM = existant.magasinDestCode;
    quantiteControllerTM.text = existant.quantite.toString();
    nombreControllerTM.text = existant.nombre?.toString() ?? '';
    observationControllerTM.text = existant.observation ?? '';
  } else {
    // ✅ Magasin source : toujours celui de la caisse actuellement sélectionnée
    // pour un non-admin (jamais un choix libre) ; libre pour l'Admin.
    final db = await DbCreator.openDb();
    final param = await CaisseParamServices(db).getCaisseParamByUserCode(userCode);
    selectedMagasinSourceCodeTM = param?.magasinCode
        ?? (magasinsDisponiblesTM.isNotEmpty ? magasinsDisponiblesTM.first.code : null);
    selectedMagasinDestCodeTM = null;
  }

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          String nomMagasin(String? code) =>
              magasinsDisponiblesTM.firstWhereOrNull((m) => m.code == code)?.nom ?? '';

          final magasinsDestinationDisponibles = magasinsDisponiblesTM
              .where((m) => m.code != selectedMagasinSourceCodeTM)
              .toList();

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 460,

                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/transfert_icon.png',
                  text: existant != null ? l10n.modifyTransfer : l10n.newTransfer,
                ),

                content: Form(
                  key: transfertMagasinFormKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
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
                                  controller: codeControllerTM,
                                  enabled: false,
                                  hint: "TRM000001",
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
                                    builder: (_) {
                                      return InsertionProduitDialog(
                                        newButton: false,
                                        multiselection: false,
                                        produits: produitsTestTM,
                                        onProduitSelected: (p) {
                                          setState(() {
                                            selectedProduitTM = p.nom;
                                            prod = p;
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: selectedProduitTM,
                                  items: produitsTestTM.where((e) => e.etat).map((e) => e.nom).toList(),
                                  onChanged: (v) => setState(() {
                                    selectedProduitTM = v;
                                    prod = produitsTestTM.where((e) => e.nom == v).first;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Magasin source : verrouillé sur la caisse
                              // active pour un non-admin (cf. plus haut).
                              ChampAvecLabel(
                                label: l10n.source,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  enabled: peutChoisirMagasin,
                                  value: nomMagasin(selectedMagasinSourceCodeTM),
                                  items: magasinsDisponiblesTM.map((m) => m.nom).toList(),
                                  onChanged: (v) => setState(() {
                                    selectedMagasinSourceCodeTM = magasinsDisponiblesTM
                                        .firstWhereOrNull((m) => m.nom == v)?.code;
                                    if (selectedMagasinDestCodeTM == selectedMagasinSourceCodeTM) {
                                      selectedMagasinDestCodeTM = null;
                                    }
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.destination,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: nomMagasin(selectedMagasinDestCodeTM),
                                  items: magasinsDestinationDisponibles.map((m) => m.nom).toList(),
                                  onChanged: (v) => setState(() {
                                    selectedMagasinDestCodeTM = magasinsDisponiblesTM
                                        .firstWhereOrNull((m) => m.nom == v)?.code;
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.date,
                                obligatoire: true,
                                child: TextDate(
                                  obligatoire: true,
                                  controller: dateControllerTM,
                                  hint: l10n.dateHint,
                                  onTap: () async {
                                    final d = await showDatePicker(
                                      context: context,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2100),
                                      initialDate: DateTime.now(),
                                    );
                                    if (d != null) dateControllerTM.text = _formatDateOnlyT(d);
                                  },
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
                                label: l10n.quantity,
                                obligatoire: true,
                                child: TextChampL(
                                  obligatoire: true,
                                  controller: quantiteControllerTM,
                                  numeric: true,
                                  isQuantite: true,
                                  uniteMesure: prod?.uniteMesure,
                                  hint: "0",
                                ),
                              ),
                              if (prod?.nombreActif ?? false) ...[
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberField,
                                  obligatoire: true,
                                  child: TextChampL(
                                    controller: nombreControllerTM,
                                    obligatoire: true,
                                    numeric: true,
                                    isQuantite: true,
                                    uniteMesure: QuantiteFormat.unitePiece,
                                    hint: "0",
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                child: TextChampL(
                                  controller: observationControllerTM,
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
                      onPressed: () {
                        resetTransfertMagasinForm();
                        Navigator.pop(context);
                      },
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!transfertMagasinFormKey.currentState!.validate() || prod == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        if (selectedMagasinSourceCodeTM == null || selectedMagasinDestCodeTM == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        if (selectedMagasinSourceCodeTM == selectedMagasinDestCodeTM) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.sourceAndDestinationStoreMustBeDifferent,
                          );
                          return;
                        }

                        final double quantite = double.tryParse(quantiteControllerTM.text) ?? 0;
                        if (quantite <= 0) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.quantityMustBeGreaterThanZero,
                          );
                          return;
                        }

                        final double nombreSaisiTM = double.tryParse(nombreControllerTM.text) ?? 0;
                        if ((prod?.nombreActif ?? false) && nombreSaisiTM <= 0) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.numberMustBeGreaterThanZero,
                          );
                          return;
                        }

                        // Stock disponible dans le magasin source uniquement. En
                        // modification, la quantité déjà sortie de ce magasin par
                        // l'ancien transfert (même produit) y revient d'abord.
                        final restitutionSource = existant != null &&
                                existant.produitCode == prod!.code &&
                                existant.magasinSourceCode == selectedMagasinSourceCodeTM
                            ? existant.quantite
                            : 0.0;
                        final quantiteDisponibleTM = await MouvementsServices.quantiteProduit(
                          prod!.code,
                          magasinCode: selectedMagasinSourceCodeTM,
                        ) + restitutionSource;
                        if (!StockGuard.suffisant(quantiteDisponibleTM, quantite, service: prod!.service)) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: l10n.stockInsuffisantMagasin(
                              nomMagasin(selectedMagasinSourceCodeTM),
                              quantiteDisponibleTM.toInt().toString(),
                              quantite.toInt().toString(),
                            ),
                          );
                          return;
                        }

                        // Modification : l'ancien magasin destination perd la
                        // quantité reçue — son stock ne doit pas devenir négatif.
                        if (existant != null) {
                          final produitAncien = produitsTestTM.firstWhereOrNull((p) => p.code == existant.produitCode);
                          final stockDestAncien = await MouvementsServices.quantiteProduit(
                            existant.produitCode,
                            magasinCode: existant.magasinDestCode,
                          );
                          final memeProduit = existant.produitCode == prod!.code;
                          final apres = stockDestAncien -
                              existant.quantite +
                              (memeProduit && selectedMagasinDestCodeTM == existant.magasinDestCode ? quantite : 0) -
                              (memeProduit && selectedMagasinSourceCodeTM == existant.magasinDestCode ? quantite : 0);
                          if (apres < 0 && !(produitAncien?.service ?? false)) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              kind: DialogKind.refuser,
                              titre_concerne: l10n.transfer,
                              message: l10n.stockInsuffisantMagasin(
                                nomMagasin(existant.magasinDestCode),
                                stockDestAncien.toInt().toString(),
                                existant.quantite.toInt().toString(),
                              ),
                            );
                            return;
                          }
                        }

                        final nombreTM = nombreControllerTM.text.trim().isEmpty
                            ? null
                            : double.tryParse(nombreControllerTM.text);

                        final transfert = TransfertMagasin(
                          id: id,
                          code: code,
                          date: DateTime.parse(dateControllerTM.text),
                          produitCode: prod!.code,
                          quantite: quantite,
                          nombre: nombreTM,
                          magasinSourceCode: selectedMagasinSourceCodeTM!,
                          magasinDestCode: selectedMagasinDestCodeTM!,
                          etat: true,
                          observation: observationControllerTM.text,
                          dateCree: existant?.dateCree ?? DateTime.now(),
                          creeParCode: existant?.creeParCode ?? userCode,
                          dateModif: existant != null ? DateTime.now() : null,
                          modifParCode: existant != null ? userCode : null,
                        );

                        final response = existant != null
                            ? await _ModifierTransfertMagasin(
                                ancien: existant,
                                nouveau: transfert,
                                produit: prod!,
                                userName: userName,
                                userCode: userCode,
                              )
                            : await _SaveTransfertMagasin(
                                transfert: transfert,
                                produit: prod!,
                                userName: userName,
                                userCode: userCode,
                              );

                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.transfer,
                            message: response.message ?? l10n.errorOccurred,
                          );
                          return;
                        }

                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.transfer,
                          message: response.message ?? l10n.transfer,
                          onTerminer: () {
                            resetTransfertMagasinForm();
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
