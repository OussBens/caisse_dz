import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'dart:ui';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/core/dialog/caisse_session/caisse_fermee_dialog.dart';
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
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import '../../../Services/MagasinDetail.dart';
import '../../../data/models/fournisseur.dart';
import '../../../data/models/produit_magasin_detail.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';

/// Entrée rapide : formulaire à un seul produit. En interne, crée un
/// SmartScan à 1 produit (nbrProduit=1, toujours réglé intégralement via un
/// versement fournisseur) au lieu d'une ligne dans l'ancienne table 'entree'
/// (fusionnée dans SmartScan).
final TextEditingController codeControllerE = TextEditingController();
final TextEditingController produitCodeControllerE = TextEditingController();
final TextEditingController quantiteControllerE = TextEditingController();
final TextEditingController nombreControllerE = TextEditingController();
final TextEditingController prixAchatControllerE = TextEditingController(text: '0.00');
final TextEditingController prixVenteControllerE = TextEditingController(text: '0.00');
final TextEditingController montantControllerE = TextEditingController(text: '0.00');
final TextEditingController dateControllerE = TextEditingController();
final TextEditingController observationControllerE = TextEditingController();

String? selectedProduitE;
String? selectedFournisseurE;
String? selectedCaisseE;

List<Produit> produitsTestE = [];
List<Fournisseur> fournisseursTestE = [];
List<CaisseGestion> caissesTestE = [];
List<Magasin> magasinsDisponiblesE = [];

// ✅ Éclatement de l'entrée sur plusieurs magasins — Admin uniquement (voir
// peutEclaterMagasinsE dans EntreeNouveau). Pour tout autre rôle, l'entrée
// va toujours entièrement au magasin de la caisse active, comme avant.
bool splitMagasinsActifE = false;
List<RepartitionMagasinE> repartitionsE = [];

class RepartitionMagasinE {
  String? magasinCode;
  final TextEditingController quantiteController = TextEditingController();
}

// Comparaison avec tolérance : une égalité stricte de double sur des sommes
// d'entrées utilisateur (quantités décimales) peut être cassée par de simples
// dérives d'arrondi IEEE754 alors que les nombres affichés sont identiques.
bool _quantitesEquivalentes(double a, double b) => (a - b).abs() < 0.001;

// Entrée rapide n'a pas besoin de l'heure précise, seulement du jour —
// format date-only cohérent affiché par défaut et après sélection au
// calendrier, pour ne pas dépendre de si l'utilisateur a ouvert le
// datepicker ou non.
String _formatDateOnlyE(DateTime d) =>
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

Future<int> _GetNextSmartScanId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanServices.getNextSmartScanId(txn);
  });
  return id;
}

Future<int> _GetNextSmartScanProduitId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanProduitServices.getNextSmartScanProduitId(txn);
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

Future<void> _LoadDataE() async {
  produitsTestE = await ProduitServices.getAllProduits();
  fournisseursTestE = await FournisseurServices.getAllFournisseurs();
  caissesTestE = await GCServices.getAllCaisses();
  magasinsDisponiblesE = (await MagasinServices.getAllMagasins()).where((m) => m.etat).toList();
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
  nombreControllerE.clear();
  prixAchatControllerE.clear();
  prixVenteControllerE.clear();
  montantControllerE.clear();
  dateControllerE.clear();
  observationControllerE.clear();
  selectedProduitE = null;
  selectedFournisseurE = null;
  selectedCaisseE = null;
  splitMagasinsActifE = false;
  repartitionsE = [];

  quantiteControllerE.removeListener(calculerMontantE);
  quantiteControllerE.addListener(calculerMontantE);
}

final GlobalKey<FormState> entreeFormKey = GlobalKey<FormState>();

Future<ApiResponse<int>> _SaveEntreeRapide({
  required String userName,
  required String userCode,
  required SmartScan smartScan,
  required SmartScanProduit ligne,
  // Un mouvement par magasin (voir splitMagasinsActifE) — un seul élément
  // dans le cas normal (non-admin, ou admin sans éclatement), plusieurs si
  // l'Admin a réparti la réception sur plusieurs magasins. Chaque mouvement
  // porte sa propre part de quantite/nombre.
  required List<Mouvement> mouvements,
  required String caisseCode,
  required String caisseNom,
}) async {
  final db = await DbCreator.openDb();
  final serviceSS = SmartScanServices(db);
  final serviceSSP = SmartScanProduitServices(db);
  final serviceh = HistoriqueServices(db);
  final serviceM = MouvementsServices(db);
  final servicep = ProduitServices(db);
  final serviceMagasinDetail = ProduitMagasinDetailServices(db);
  final serviceFournisseur = FournisseurServices(db);
  final versementService = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final response = await serviceSS.addSmartScan(smartScan);
  if (!response.success) return response;

  await serviceSSP.addSmartScanProduit(ligne);

  final produits = await ProduitServices.getAllProduits();
  final prod = produits.where((e) => e.code == ligne.codeProduit).first;

  if (!prod.service) {
    if (ligne.nombre != null) prod.nombre += ligne.nombre!;
  }
  prod.prixAchat = ligne.prix;
  prod.prixVente = ligne.prixVente;
  prod.modifParCode = userCode;
  prod.dateModif = DateTime.now();
  await servicep.updateProduit(prod);

  // ✅ Un mouvement + une mise à jour produit_magasin_detail (nombre) par
  // magasin réparti — plus jamais figé sur le magasin système.
  for (final mouv in mouvements) {
    await serviceM.addMouvement(mouv);

    final magasinCode = mouv.magasinCode;
    if (magasinCode == null) continue;

    try {
      final magasinDetail = await serviceMagasinDetail.getSingleByProduitAndMagasin(
          prod.code,
          magasinCode
      );

      if (magasinDetail != null) {
        if (mouv.nombre != null) {
          await serviceMagasinDetail.updateNombre(magasinDetail.id, magasinDetail.nombre + mouv.nombre!);
        }
      } else {
        final newDetail = ProduitMagasinDetail(
          id: await _GetNextMagasinDetailId(),
          magasinCode: magasinCode,
          produitCode: prod.code,
          dateCree: DateTime.now(),
          creeParCode: userCode,
          nombre: mouv.nombre ?? 0,
        );
        await serviceMagasinDetail.addProduitMagasinDetail(newDetail);
      }
    } catch (e) {
      print("⚠️ Erreur lors de la mise à jour du magasin System: $e");
    }
  }

  // ✅ Mettre à jour le total achat du fournisseur
  try {
    final fournisseur = fournisseursTestE.firstWhere((f) => f.code == smartScan.fournisseurCode);
    await serviceFournisseur.ajouterAchat(fournisseur.id, smartScan.montant);
  } catch (e) {
    print("⚠️ Erreur lors de la mise à jour du fournisseur: $e");
  }

  // ✅ Entrée rapide toujours réglée intégralement en espèces (paye = montant)
  if (smartScan.montant > 0) {
    final nextVerssementId = await VerssementServices.getNextVerssementId(db);
    Verssement versement = Verssement(
      id: nextVerssementId,
      code: CodeGenerator.generateCode(
        prefix: CodePrefix.verssement,
        id: nextVerssementId,
        digitCount: 6,
      ),
      date: DateTime.now(),
      typebeneficiare: "Fournisseur",
      beneficiareCode: smartScan.fournisseurCode,
      montant: smartScan.montant,
      etat: true,
      mode_paiement: "Espèces",
      sense: 'Sortie',
      type: "Paiement",
      dateCree: DateTime.now(),
      creeParCode: userCode,
      caisse: caisseNom,
      codeOperation: smartScan.code,
    );
    await versementService.addverssement(versement);

    // Mouvement de caisse (grand-livre) : décaissement du paiement
    // fournisseur, journalisé dans la session ouverte de cette caisse.
    final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseCode);
    if (sessionOuverte != null) {
      final nextMouvementId = await CaisseSessionServices.getNextMouvementId(db);
      final mouvementCaisse = CaisseMouvement(
        id: nextMouvementId,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.caisseMouvement,
          id: nextMouvementId,
          digitCount: 8,
        ),
        sessionCode: sessionOuverte.code,
        caisseCode: caisseCode,
        type: 'decaissement_achat',
        sens: 'Sortie',
        montant: smartScan.montant,
        modePaiement: "Espèces",
        codeOperation: smartScan.code,
        fournisseurCode: smartScan.fournisseurCode,
        date: DateTime.now(),
        etat: true,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await caisseSessionService.ajouterMouvement(mouvementCaisse);
    }
  }

  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id: idh,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type: "SmartScan",
      desc: "L'utilisateur $userName a ajouté une entrée rapide du produit ${prod.nom}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);

  return response;
}

Future<void> EntreeNouveau(
  BuildContext context, {
  VoidCallback? onSuccess,
  String? initialProduitCode,
}) async {
  await _LoadDataE();
  quantiteControllerE.removeListener(calculerMontantE);
  quantiteControllerE.addListener(calculerMontantE);

  int id = await _GetNextSmartScanId();
  Produit? prod;
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  final code = CodeGenerator.generateCode(
    prefix: CodePrefix.smartscan,
    id: id,
    digitCount: 6,
  );
  codeControllerE.text = code;

  // ✅ Prix de vente par défaut = prix d'achat + 30%
  prixVenteControllerE.text = (double.tryParse(prixAchatControllerE.text) ?? 0 * 1.3).toStringAsFixed(2);

  // ✅ Valeurs par défaut pour aller plus vite : date du jour et fournisseur
  // système "Général" (déjà utilisé comme repli ailleurs dans l'app),
  // modifiables par l'utilisateur si besoin.
  dateControllerE.text = _formatDateOnlyE(DateTime.now());
  final fournisseurGeneral = fournisseursTestE.firstWhereOrNull(
    (f) => f.code == AppConst.fournisseurGeneralCode,
  );
  if (fournisseurGeneral != null) {
    selectedFournisseurE = fournisseurGeneral.nom;
  }

  // ✅ La caisse ne se choisit jamais librement ici : c'est toujours celle
  // actuellement sélectionnée par l'utilisateur (CaisseParam, synchronisée
  // par ParametreCaisseDialog) — jamais un choix libre parmi toutes les
  // caisses, ni figée sur la première de la liste.
  selectedCaisseE = caissesTestE.isNotEmpty ? caissesTestE.first.nomCaisse : null;
  if (auth.userCode != null) {
    final db = await DbCreator.openDb();
    final param = await CaisseParamServices(db).getCaisseParamByUserCode(auth.userCode!);
    final caisseSuivie = caissesTestE.where((c) => c.code == param?.caisseCode).firstOrNull;
    if (caisseSuivie != null) selectedCaisseE = caisseSuivie.nomCaisse;
  }

  // ✅ Éclatement sur plusieurs magasins réservé à l'Admin, et seulement s'il
  // y a plus d'un magasin actif — pour tout autre cas, l'entrée va
  // entièrement au magasin de la caisse active (comportement inchangé).
  // (rôle Admin enregistré « admin » en minuscules en base)
  final bool peutEclaterMagasinsE = auth.estAdmin && magasinsDisponiblesE.length > 1;
  splitMagasinsActifE = false;
  repartitionsE = [];

  if (!auth.isAuthenticated) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequired,
    );
    return;
  }

  // ✅ Pré-sélectionne le produit qu'on vient de créer (ex: caisse_screen
  // enchaîne "Nouveau produit" -> "Entrée rapide" sur ce même produit).
  if (initialProduitCode != null) {
    final produitCree = produitsTestE.where((p) => p.code == initialProduitCode).firstOrNull;
    if (produitCree != null) {
      prod = produitCree;
      selectedProduitE = produitCree.nom;
      produitCodeControllerE.text = produitCree.code;
      prixAchatControllerE.text = produitCree.prixAchat.toStringAsFixed(2);
      prixVenteControllerE.text = produitCree.prixVente.toStringAsFixed(2);
      calculerMontantE();
    }
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
              height: peutEclaterMagasinsE && splitMagasinsActifE ? 680 : 520,
              header: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/entree_rapide_icon.png',
                text: l10n.newEntry,
              ),
              content: Form(
                key: entreeFormKey,
                child: SingleChildScrollView(
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
                                controller: codeControllerE,
                                enabled: false,
                                hint: "SS000001",
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
                              label: l10n.product,
                              obligatoire: true,
                              buttonAjout: true,
                              onAjoutPressed: () async {
                                await showDialog(
                                  context: context,
                                  barrierColor: Appstyle.gris.withOpacity(0.25),
                                  builder: (_) => InsertionProduitDialog(
                                    multiselection: false,
                                    newButton:false,
                                    produits: produitsTestE,
                                    onProduitSelected: (p) {
                                      setState(() {
                                        selectedProduitE = p.nom;
                                        prod = p;
                                        produitCodeControllerE.text = p.code;
                                        prixAchatControllerE.text = p.prixAchat.toStringAsFixed(2);
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
                                items: produitsTestE.where((e) => e.etat).map((e) => e.nom).toList(),
                                onChanged: (v) => setState(() {
                                  selectedProduitE = v;
                                  prod = produitsTestE.where((e) => e.nom == v).first;
                                  produitCodeControllerE.text = prod!.code;
                                  prixAchatControllerE.text = prod!.prixAchat.toStringAsFixed(2);
                                  prixVenteControllerE.text = prod!.prixVente.toStringAsFixed(2);
                                  calculerMontantE();
                                }),
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
                                  if (d != null) dateControllerE.text = _formatDateOnlyE(d);
                                },
                              ),
                            ),

                            const SizedBox(height: 10),
                            // Caisse toujours celle actuellement sélectionnée
                            // par l'utilisateur — jamais un choix libre ici
                            // (voir ParametreCaisseDialog pour la changer).
                            ChampAvecLabel(
                              label: l10n.cashRegister,
                              obligatoire: true,
                              child: TextListe(
                                obligatoire: true,
                                clearable: false,
                                enabled: false,
                                value: selectedCaisseE,
                                items: caissesTestE.map((c) => c.nomCaisse).toSet().toList(),
                                onChanged: (_) {},
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
                                isQuantite: true,
                                uniteMesure: prod?.uniteMesure,
                                hint: "0",
                                onChanged: (v) => setState(() => calculerMontantE()),
                              ),
                            ),
                            if (prod?.nombreActif ?? false) ...[
                              const SizedBox(height: 10),
                              ChampAvecLabel(
                                label: l10n.numberField,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: nombreControllerE,
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
                              label: l10n.purchasePrice,
                              obligatoire: true,
                              child: TextChampL(
                                controller: prixAchatControllerE,
                                enabled: true,
                                numeric: true,
                                hint: '',
                                onChanged: (v) => setState(() {
                                  calculerMontantE();
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
                            ChampAvecLabel(
                              label: l10n.salePrice,
                              obligatoire: true,
                              child: TextChampL(
                                controller: prixVenteControllerE,
                                enabled: true,
                                numeric: true,
                                hint: '',
                                onChanged: (v) {
                                  final double prixAchat = double.tryParse(prixAchatControllerE.text) ?? 0;
                                  final double prixVente = double.tryParse(prixVenteControllerE.text) ?? 0;
                                  if (prixVente <= prixAchat && prixVente > 0) {
                                    print("⚠️ Prix de vente doit être supérieur au prix d'achat");
                                  }
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
                    ],
                  ),
                      if (peutEclaterMagasinsE) ...[
                        const SizedBox(height: 10),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          activeColor: Appstyle.violet,
                          title: Text(l10n.splitEntryAcrossStores, style: Appstyle.textSB),
                          value: splitMagasinsActifE,
                          onChanged: (v) => setState(() {
                            splitMagasinsActifE = v ?? false;
                            if (splitMagasinsActifE && repartitionsE.isEmpty) {
                              repartitionsE.add(RepartitionMagasinE());
                              repartitionsE.add(RepartitionMagasinE());
                            }
                          }),
                        ),
                        if (splitMagasinsActifE) ...[
                          ...repartitionsE.map((rep) {
                            final magasinsExclus = repartitionsE
                                .where((r) => r != rep)
                                .map((r) => r.magasinCode)
                                .whereType<String>()
                                .toSet();
                            final choixDisponibles = magasinsDisponiblesE
                                .where((m) => !magasinsExclus.contains(m.code))
                                .toList();

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: TextListe(
                                      clearable: false,
                                      value: magasinsDisponiblesE
                                          .firstWhereOrNull((m) => m.code == rep.magasinCode)?.nom,
                                      items: choixDisponibles.map((m) => m.nom).toList(),
                                      onChanged: (v) => setState(() {
                                        rep.magasinCode = magasinsDisponiblesE
                                            .firstWhereOrNull((m) => m.nom == v)?.code;
                                      }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextChampL(
                                      controller: rep.quantiteController,
                                      numeric: true,
                                      isQuantite: true,
                                      uniteMesure: prod?.uniteMesure,
                                      hint: "0",
                                      onChanged: (_) => setState(() {}),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Appstyle.danger),
                                    onPressed: repartitionsE.length > 1
                                        ? () => setState(() => repartitionsE.remove(rep))
                                        : null,
                                  ),
                                ],
                              ),
                            );
                          }),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.add),
                                label: Text("${l10n.add} ${l10n.magasin}"),
                                onPressed: () => setState(() => repartitionsE.add(RepartitionMagasinE())),
                              ),
                              Builder(builder: (context) {
                                final totalReparti = repartitionsE.fold<double>(
                                  0.0,
                                  (s, r) => s + (double.tryParse(r.quantiteController.text) ?? 0),
                                );
                                final quantiteTotale = double.tryParse(quantiteControllerE.text) ?? 0;
                                final ok = _quantitesEquivalentes(totalReparti, quantiteTotale);
                                return Text(
                                  "${l10n.total}: ${totalReparti.toStringAsFixed(0)} / ${quantiteTotale.toStringAsFixed(0)}",
                                  style: Appstyle.textSB.copyWith(color: ok ? Appstyle.green : Appstyle.danger),
                                );
                              }),
                            ],
                          ),
                        ],
                      ],
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
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.fillRequiredFields,
                        );
                        return;
                      }

                      if (selectedFournisseurE == null || selectedFournisseurE!.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.supplierRequired,
                        );
                        return;
                      }

                      if (selectedCaisseE == null || selectedCaisseE!.isEmpty) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.cashRegisterRequired,
                        );
                        return;
                      }

                      final double quantite = double.tryParse(quantiteControllerE.text) ?? 0;
                      if (quantite <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.quantityMustBeGreaterThanZero,
                        );
                        return;
                      }

                      // ✅ Nombre obligatoire quand le produit suit le
                      // second stock "nombre" (nombreActif).
                      final double nombreSaisiE = double.tryParse(nombreControllerE.text) ?? 0;
                      if ((prod?.nombreActif ?? false) && nombreSaisiE <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.numberMustBeGreaterThanZero,
                        );
                        return;
                      }

                      final double prixAchat = double.tryParse(prixAchatControllerE.text) ?? 0;
                      if (prixAchat <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.priceMustBeGreaterThanZero,
                        );
                        return;
                      }

                      final double prixVente = double.tryParse(prixVenteControllerE.text) ?? 0;
                      if (prixVente <= 0) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.sellPriceMustBePositive,
                        );
                        return;
                      }

                      if (prixVente <= prixAchat) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.entry,
                          message: l10n.sellPriceMustExceedBuyPrice,
                        );
                        return;
                      }

                      // ✅ Validation de la répartition multi-magasins (Admin
                      // uniquement) : chaque ligne doit avoir un magasin et
                      // une quantité, sans doublon, et la somme doit égaler
                      // la quantité totale saisie plus haut.
                      if (splitMagasinsActifE) {
                        final lignesIncompletes = repartitionsE.any((r) =>
                            r.magasinCode == null || (double.tryParse(r.quantiteController.text) ?? 0) <= 0);
                        if (lignesIncompletes) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.entry,
                            message: l10n.incompleteStoreSplit,
                          );
                          return;
                        }

                        final codesRepartis = repartitionsE.map((r) => r.magasinCode).toList();
                        if (codesRepartis.toSet().length != codesRepartis.length) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.entry,
                            message: l10n.duplicateStoreInSplit,
                          );
                          return;
                        }

                        final totalReparti = repartitionsE.fold<double>(
                          0.0,
                          (s, r) => s + (double.tryParse(r.quantiteController.text) ?? 0),
                        );
                        if (!_quantitesEquivalentes(totalReparti, quantite)) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.entry,
                            message: l10n.splitTotalMustMatchQuantity,
                          );
                          return;
                        }
                      }

                      final fournisseur = fournisseursTestE.firstWhere((f) => f.nom == selectedFournisseurE);
                      final caisseChoisieE = caissesTestE.firstWhere((c) => c.nomCaisse == selectedCaisseE);

                      // ✅ Session de caisse obligatoire : aucun achat ne peut
                      // être enregistré tant que la caisse choisie n'a pas
                      // été ouverte.
                      final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseChoisieE.code);
                      if (sessionOuverte == null) {
                        await CaisseFermeeDialog(
                          context: context,
                          caisses: caissesTestE,
                          caisseInitiale: caisseChoisieE,
                        );
                        return;
                      }

                      final montant = double.parse(montantControllerE.text);
                      final nombreSaisi = nombreControllerE.text.trim();
                      final nombre = nombreSaisi.isEmpty ? null : double.tryParse(nombreSaisi);

                      SmartScan smartScan = SmartScan(
                        id: id,
                        code: code,
                        date: DateTime.parse(dateControllerE.text),
                        montant: montant,
                        nbrProduit: 1,
                        fournisseurCode: fournisseur.code,
                        etat: true,
                        creeParCode: userCode,
                        dateCree: DateTime.now(),
                        observation: observationControllerE.text,
                      );

                      final ligneId = await _GetNextSmartScanProduitId();
                      SmartScanProduit ligne = SmartScanProduit(
                        id: ligneId,
                        codeSmartScan: code,
                        codeProduit: prod!.code,
                        quantite: quantite,
                        nombre: nombre,
                        prix: prixAchat,
                        prixVente: prixVente,
                        total: montant,
                        etat: true,
                        creeParCode: userCode,
                        creeLe: DateTime.now(),
                      );

                      // ✅ Un mouvement par magasin réparti (Admin), ou un
                      // seul mouvement sur le magasin de la caisse active
                      // (comportement normal, inchangé) — voir
                      // splitMagasinsActifE plus haut.
                      final List<Mouvement> mouvementsE = [];
                      if (splitMagasinsActifE) {
                        for (final rep in repartitionsE) {
                          final partQuantite = double.parse(rep.quantiteController.text);
                          final partNombre = nombre != null ? (nombre * (partQuantite / quantite)) : null;
                          final idmPart = await _GetNextMouvementId();
                          mouvementsE.add(Mouvement(
                            id: idmPart,
                            code: CodeGenerator.generateCode(
                              prefix: CodePrefix.mouvement,
                              id: idmPart,
                              digitCount: 8,
                            ),
                            date: DateTime.parse(dateControllerE.text),
                            codeProduit: prod!.code,
                            quantite: partQuantite,
                            nombre: partNombre,
                            prixAchat: prixAchat,
                            prixVente: prixVente,
                            type: ListsConst.typeMouvement[1],
                            magasinCode: rep.magasinCode,
                            etat: true,
                            codeOperation: code,
                            dateCree: DateTime.now(),
                            creeParCode: userCode,
                          ));
                        }
                      } else {
                        int idm = await _GetNextMouvementId();
                        mouvementsE.add(Mouvement(
                          id: idm,
                          code: CodeGenerator.generateCode(
                            prefix: CodePrefix.mouvement,
                            id: idm,
                            digitCount: 8,
                          ),
                          date: DateTime.parse(dateControllerE.text),
                          codeProduit: prod!.code,
                          quantite: quantite,
                          nombre: nombre,
                          prixAchat: prixAchat,
                          prixVente: prixVente,
                          type: ListsConst.typeMouvement[1],
                          // Multi-magasin : une entrée alimente le magasin
                          // principal de l'utilisateur (AuthState.magasinPrincipal).
                          magasinCode: auth.magasinPrincipal,
                          etat: true,
                          codeOperation: code,
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                        ));
                      }

                      final response = await _SaveEntreeRapide(
                        userName: userName,
                        userCode: userCode,
                        smartScan: smartScan,
                        ligne: ligne,
                        mouvements: mouvementsE,
                        caisseCode: caisseChoisieE.code,
                        caisseNom: caisseChoisieE.nomCaisse,
                      );
                      print(response.message);
                      if (!response.success) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
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
