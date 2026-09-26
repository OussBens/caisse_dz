import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pannier.dart' hide ApiResponse;
import 'package:caisse_dz/Services/PannierProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/MagasinDetail.dart';
import 'package:caisse_dz/Services/SmartScan.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/caisse_session/caisse_fermee_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_client.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/insertion_pannier.dart';
import 'package:caisse_dz/core/dialog/insertion_smartscan.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart'; // ✅ Ajout de l'import
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utilis/api_response.dart';
import '../../utilis/stock_guard.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

final TextEditingController observationControllerN = TextEditingController();
final TextEditingController prixAchatControllerN = TextEditingController();
final TextEditingController prixVenteControllerN = TextEditingController();
final TextEditingController quantiteControllerN = TextEditingController();
final TextEditingController nombreControllerN = TextEditingController();
final TextEditingController dateController = TextEditingController();

/// Document fournisseur (SmartScan, y compris les entrées rapides à 1 produit).
class DocumentFournisseurR {
  final String code;
  final String label;
  final DateTime date;

  const DocumentFournisseurR({
    required this.code,
    required this.label,
    required this.date,
  });
}

String _formatDateR(DateTime d) =>
    "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

String _labelPannier(Pannier p) =>
    "${p.code} • ${_formatDateR(p.date)} • ${NumberFormatUtil.formatMontant(p.montant, decimales: 2)}";

void resetSortieForm() {
  quantiteControllerN.clear();
  nombreControllerN.clear();
  dateController.clear();
  observationControllerN.clear();
  prixAchatControllerN.clear();
  prixVenteControllerN.clear();
  newSelectedTypeR = null;
  newSelectedClientR = null;
  newSelectedProduitR = null;
  newSelectedFournisseurR = null;
  newSelectedPannierR = null;
  codePannierSelectionne = null;
  newSelectedDocumentR = null;
  codeDocumentSelectionne = null;
  panniersDuClient = [];
  produitsDuPannierSelectionne = [];
  documentsDuFournisseur = [];
  smartScansDuFournisseur = [];
  produitsDuSmartScanSelectionne = [];
  quantiteMaxSelectionnee = null;
  quantiteDejaRetourneeSelectionnee = 0;
  produitsDisponibles = [];
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}

Future<void> pickDate(
    BuildContext context,
    TextEditingController controller, {
      DateTime? minDate,
    }) async {
  DateTime initialDate = DateTime.now();

  if (controller.text.isNotEmpty) {
    try {
      initialDate = DateTime.parse(controller.text);
    } catch (_) {}
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initialDate.isBefore(minDate ?? initialDate)
        ? (minDate ?? initialDate)
        : initialDate,
    firstDate: minDate ?? DateTime(2000),
    lastDate: DateTime(2100),
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Appstyle.violet,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      );
    },
  );

  if (picked != null) {
    controller.text =
    "${picked.year.toString().padLeft(4, '0')}-"
        "${picked.month.toString().padLeft(2, '0')}-"
        "${picked.day.toString().padLeft(2, '0')}";
  }
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await RetourServices.getNextRetourId(txn);
  });
  return id;
}

Future<ApiResponse<int>> _SaveRetour({
  required String userName,
  required String userCode,
  required Retour retour,
}) async {
  final db = await DbCreator.openDb();
  final serviceh = await HistoriqueServices(db);
  final serviceM = await MouvementsServices(db);
  final serviceP = await ProduitServices(db);
  final services = await RetourServices(db);
  final serviceClient = ClientServices(db);
  final serviceFournisseur = FournisseurServices(db);
  final serviceV = VerssementServices(db);
  final caisseSessionService = CaisseSessionServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final param = params.where((e) => e.creeParCode == userCode).first;
  final caisse = Caisses.where((e) => e.nomCaisse == param.selectedCaisse).first;

  // Magasin du retour = magasin de la caisse active — jusqu'ici jamais
  // renseigné (retour.magasinCode restait toujours null).
  retour.magasinCode = caisse.magasinCode;

  // ✅ Session de caisse obligatoire : aucun retour ne peut être enregistré
  // tant que la caisse de l'utilisateur n'a pas été ouverte.
  final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisse.code);
  if (sessionOuverte == null) {
    return ApiResponse(
      success: false,
      message: "Aucune session de caisse ouverte pour '${caisse.nomCaisse}'. Veuillez d'abord ouvrir la caisse.",
    );
  }

  final response = await services.addRetour(retour);
  final prod = await ProduitServices.getAllProduits();

  // ✅ Convertir la quantité en int une seule fois
  final int quantiteInt = retour.quantite.toInt();

  Produit produitConcerne = prod.where((e) => e.code == retour.codeProduit).first;

  if (retour.fournisseur_code != null) {
    // Retour fournisseur : le montant remboursé correspond au prix d'achat
    // (ce que le magasin avait payé), et non au prix de vente.
    final montant = retour.quantite * retour.prixAchat!;

    if (!produitConcerne.service) {
      if (retour.nombre != null) produitConcerne.nombre = produitConcerne.nombre - retour.nombre!;
    }
    produitConcerne.dateModif = DateTime.now();
    produitConcerne.modifParCode = userCode;
    await serviceP.updateProduit(produitConcerne);

    // Retour fournisseur : la marchandise quitte le magasin — déstockage
    // réel par magasin, jusqu'ici seul le stock global était touché.
    if (!produitConcerne.service && retour.magasinCode != null) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
        produitConcerne.code,
        retour.magasinCode!,
      );
      if (magasinDetail != null) {
        if (retour.nombre != null && magasinDetail.nombre > 0) {
          final nombreADestock = retour.nombre! <= magasinDetail.nombre
              ? retour.nombre!
              : magasinDetail.nombre;
          await pmdService.decrementNombre(magasinDetail.id, nombreADestock);
        }
      }
    }

    // ✅ AUGMENTER LE NOMBRE DE RETOURS DU FOURNISSEUR
    final fournisseur = fournisseursTest.firstWhere(
          (f) => f.code == retour.fournisseur_code,
      orElse: () => throw Exception("Fournisseur introuvable"),
    );
    await serviceFournisseur.ajouterRetour(fournisseur.id, montant);

    // ✅ Créer le versement lié : le fournisseur rembourse le magasin, donc
    // le sens est une entrée pour la caisse (contrairement au retour client).
    if (montant > 0) {
      final nextVerssementId = await VerssementServices.getNextVerssementId(db);
      final versement = Verssement(
        id: nextVerssementId,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.verssement,
          id: nextVerssementId,
          digitCount: 6,
        ),
        date: retour.date,
        typebeneficiare: "Fournisseur",
        beneficiareCode: fournisseur.code,
        montant: montant,
        etat: true,
        mode_paiement: "Espèce",
        sense: 'Entrée',
        type: "Remboursement",
        dateCree: DateTime.now(),
        creeParCode: userCode,
        caisse: caisse.nomCaisse,
        codeOperation: retour.code,
      );
      await serviceV.addverssement(versement);

      // Mouvement de caisse (grand-livre) : le fournisseur rembourse le
      // magasin, donc une entrée pour la caisse.
      final nextMouvementIdRF = await CaisseSessionServices.getNextMouvementId(db);
      await caisseSessionService.ajouterMouvement(CaisseMouvement(
        id: nextMouvementIdRF,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.caisseMouvement,
          id: nextMouvementIdRF,
          digitCount: 8,
        ),
        sessionCode: sessionOuverte.code,
        caisseCode: caisse.code,
        type: 'retour_fournisseur',
        sens: 'Entrée',
        montant: montant,
        modePaiement: "Espèce",
        codeOperation: retour.code,
        fournisseurCode: fournisseur.code,
        date: retour.date,
        etat: true,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      ));
    }
  }

  if (retour.client_code != null) {
    final montant = retour.quantite * retour.prixVente!;

    if (!produitConcerne.service) {
      if (retour.nombre != null) produitConcerne.nombre = produitConcerne.nombre + retour.nombre!;
    }
    produitConcerne.dateModif = DateTime.now();
    produitConcerne.modifParCode = userCode;
    await serviceP.updateProduit(produitConcerne);

    // Retour client : la marchandise revient dans le magasin — restockage
    // réel par magasin, jusqu'ici seul le stock global était touché.
    if (!produitConcerne.service && retour.magasinCode != null) {
      final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
        produitConcerne.code,
        retour.magasinCode!,
      );
      if (magasinDetail != null) {
        if (retour.nombre != null) {
          await pmdService.incrementNombre(magasinDetail.id, retour.nombre!);
        }
      }
    }

    // ✅ AUGMENTER LE NOMBRE DE RETOURS DU CLIENT
    final client = clientsTest.firstWhere(
          (c) => c.code == retour.client_code,
      orElse: () => throw Exception("Client introuvable"),
    );
    await serviceClient.ajouterRetour(client.id, montant);

    // ✅ Créer le versement lié (même principe que pour un panier, mais en
    // sortie : le magasin rembourse le client).
    if (montant > 0) {
      final nextVerssementId = await VerssementServices.getNextVerssementId(db);
      final versement = Verssement(
        id: nextVerssementId,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.verssement,
          id: nextVerssementId,
          digitCount: 6,
        ),
        date: retour.date,
        typebeneficiare: "Client",
        beneficiareCode: client.code,
        montant: montant,
        etat: true,
        mode_paiement: "Espèce",
        sense: 'Sortie',
        type: "Remboursement",
        dateCree: DateTime.now(),
        creeParCode: userCode,
        caisse: caisse.nomCaisse,
        codeOperation: retour.code,
      );
      await serviceV.addverssement(versement);

      // Mouvement de caisse (grand-livre) : le magasin rembourse le client,
      // donc une sortie pour la caisse.
      final nextMouvementIdRC = await CaisseSessionServices.getNextMouvementId(db);
      await caisseSessionService.ajouterMouvement(CaisseMouvement(
        id: nextMouvementIdRC,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.caisseMouvement,
          id: nextMouvementIdRC,
          digitCount: 8,
        ),
        sessionCode: sessionOuverte.code,
        caisseCode: caisse.code,
        type: 'retour_client',
        sens: 'Sortie',
        montant: montant,
        modePaiement: "Espèce",
        codeOperation: retour.code,
        clientCode: client.code,
        date: retour.date,
        etat: true,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      ));
    }
  }

  // Historique
  int idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: idh,
    ),
    type: "Retour",
    desc: "L'utilisateur $userName a ajouté le Retour de Produit ${produitConcerne.nom}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);

  // Mouvement
  idh = await _GetNextMouvementId();
  Mouvement mouv = Mouvement(
    id: idh,
    code: CodeGenerator.generateCode(
      prefix: CodePrefix.mouvement,
      id: idh,
      digitCount: 8,
    ),
    date: retour.date,
    type: ListsConst.typeMouvement[2],
    etat: true,
    quantite: quantiteInt.toDouble(),
    nombre: retour.nombre,
    dateCree: DateTime.now(),
    prixAchat: retour.prixAchat!,
    prixVente: retour.prixVente!,
    codeProduit: retour.codeProduit,
    fournisseurCode: retour.fournisseur_code,
    clientCode: retour.client_code,
    creeParCode: userCode,
    codeOperation: retour.code,
    magasinCode: retour.magasinCode,
  );
  await serviceM.addMouvement(mouv);

  return response;
}
String? SelectedTypeR;
String? newSelectedTypeR;
String? newSelectedClientR;
String? newSelectedProduitR;
String? newSelectedFournisseurR;

String? newSelectedPannierR;
String? codePannierSelectionne;
List<Pannier> panniersDuClient = [];
List<PannierProduit> produitsDuPannierSelectionne = [];

String? newSelectedDocumentR;
String? codeDocumentSelectionne;
List<DocumentFournisseurR> documentsDuFournisseur = [];
// Liste brute des SmartScan du fournisseur, utilisée par le dialog de
// sélection [InsertionSmartScanDialog] (le retour d'un fournisseur part d'un
// SmartScan d'origine).
List<SmartScan> smartScansDuFournisseur = [];
List<SmartScanProduit> produitsDuSmartScanSelectionne = [];

double? quantiteMaxSelectionnee;
double quantiteDejaRetourneeSelectionnee = 0;
List<Produit> produitsDisponibles = [];

List<Produit> produitsTest = [];
List<Client> clientsTest = [];
List<Fournisseur> fournisseursTest = [];
List<CaisseGestion> Caisses = [];
List<CaisseParam> params = [];

Future<void> _LoadAllData() async {
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  produitsTest = await ProduitServices.getAllProduits();
  clientsTest = await ClientServices.getAllClients();
  Caisses = await GCServices.getAllCaisses();
  params = await CaisseParamServices.getAllCaisseParam();
}

Future<void> _chargerPanniersClient(String codeClient) async {
  final tous = await PannierServices.getAllPanniers();
  panniersDuClient = tous.where((p) => p.client_code == codeClient && p.etat).toList();
}

Future<void> _chargerProduitsPannier(String codePannier) async {
  final db = await DbCreator.openDb();
  final services = PPServices(db);
  produitsDuPannierSelectionne = await services.getPPByCodePannier(codePannier);
}

Future<void> _chargerDocumentsFournisseur(String codeFournisseur) async {
  final scans = (await SmartScanServices.getAllSmartScans())
      .where((s) => s.fournisseurCode == codeFournisseur && s.etat)
      .toList();

  smartScansDuFournisseur = scans;
  documentsDuFournisseur = scans.map((s) => DocumentFournisseurR(
    code: s.code,
    label: "[Entrée] ${s.code} • ${_formatDateR(s.date)}",
    date: s.date,
  )).toList();
}

Future<void> _onDocumentFournisseurChoisi(DocumentFournisseurR doc) async {
  codeDocumentSelectionne = doc.code;
  produitsDuSmartScanSelectionne =
      await SmartScanProduitServices.getSmartScanProduitByCode(doc.code);

  _recalculerProduitsDisponibles();
}

void _recalculerProduitsDisponibles() {
  if (newSelectedTypeR == "Client") {
    final codes = produitsDuPannierSelectionne.map((p) => p.codeProduit).toSet();
    produitsDisponibles = produitsTest.where((p) => p.etat && codes.contains(p.code)).toList();
  } else if (newSelectedTypeR == "Fournisseur") {
    final codes = produitsDuSmartScanSelectionne.map((p) => p.codeProduit).toSet();
    produitsDisponibles = produitsTest.where((p) => p.etat && codes.contains(p.code)).toList();
  } else {
    produitsDisponibles = [];
  }
}

void _resetProduitEtQuantite() {
  newSelectedProduitR = null;
  quantiteMaxSelectionnee = null;
  quantiteDejaRetourneeSelectionnee = 0;
  prixAchatControllerN.clear();
  prixVenteControllerN.clear();
  quantiteControllerN.clear();
  nombreControllerN.clear();
}

/// Quantité déjà retournée pour ce produit sur ce panier/document d'origine
/// (retours actifs existants) — plafonne le prochain retour pour que la
/// somme des retours sur ce produit ne dépasse jamais la quantité vendue/achetée.
Future<void> _chargerQuantiteDejaRetournee(String codeProduit) async {
  final correspondance = newSelectedTypeR == "Client" ? codePannierSelectionne : codeDocumentSelectionne;
  quantiteDejaRetourneeSelectionnee = correspondance == null
      ? 0
      : await RetourServices.getQuantiteDejaRetournee(
          retourCorrespondDe: correspondance,
          codeProduit: codeProduit,
        );
}

/// Applique la sélection d'un produit (restreint au document source) : renseigne
/// le code produit, les prix et le plafond de quantité (ligne d'origine moins
/// ce qui a déjà été retourné pour ce produit sur ce document).
void _appliquerProduitChoisi(Produit p) {
  newSelectedProduitR = p.nom;

  if (newSelectedTypeR == "Client") {
    final ligne = produitsDuPannierSelectionne
        .firstWhereOrNull((e) => e.codeProduit == p.code);
    final max = (ligne?.quantite ?? 0) - quantiteDejaRetourneeSelectionnee;
    quantiteMaxSelectionnee = max < 0 ? 0 : max;
    prixAchatControllerN.text = (ligne?.prixAchat ?? p.prixAchat).toStringAsFixed(2);
    prixVenteControllerN.text = (ligne?.prix ?? p.prixVente).toStringAsFixed(2);
  } else if (newSelectedTypeR == "Fournisseur") {
    final ligne = produitsDuSmartScanSelectionne
        .firstWhereOrNull((e) => e.codeProduit == p.code);
    final max = (ligne?.quantite ?? 0) - quantiteDejaRetourneeSelectionnee;
    quantiteMaxSelectionnee = max < 0 ? 0 : max;
    prixAchatControllerN.text = (ligne?.prix ?? p.prixAchat).toStringAsFixed(2);
    prixVenteControllerN.text = (ligne?.prixVente ?? p.prixVente).toStringAsFixed(2);
  } else {
    prixAchatControllerN.text = p.prixAchat.toStringAsFixed(2);
    prixVenteControllerN.text = p.prixVente.toStringAsFixed(2);
  }
}

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

Future<void> RetourNouveau(BuildContext context, {String? initialType}) async {
  await _LoadAllData();
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

  // ✅ Utilisation du générateur de code pour le retour
  String cod = CodeGenerator.generateCode(
    prefix: CodePrefix.retour,
    id: id,
    digitCount: 6, // "RET000001"
  );

  String ProdCode = "";
  String codetype = "";

  resetSortieForm();

  // ✅ Date du jour par défaut, modifiable si besoin.
  final today = DateTime.now();
  dateController.text =
      "${today.year.toString().padLeft(4, '0')}-"
      "${today.month.toString().padLeft(2, '0')}-"
      "${today.day.toString().padLeft(2, '0')}";

  newSelectedTypeR = initialType ?? ListsConst.typeRetour.first;

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.25),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          // ✅ Dérivé de newSelectedTypeR (source de vérité) à chaque build,
          // au lieu d'être réinitialisé sur le 1er item à chaque rebuild
          // (setState) — ça écrasait le choix de l'utilisateur en plein
          // formulaire.
          SelectedTypeR = translator.translateTypeRetour(
            newSelectedTypeR ?? ListsConst.typeRetour.first,
          );

          String produitHint() {
            if (produitsDisponibles.isNotEmpty) return l10n.select;
            return newSelectedTypeR == "Client"
                ? "Choisissez d'abord un panier"
                : "Choisissez d'abord un document";
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 900,
                height: 520,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/cardwidget/retour_icon.png',
                  text: l10n.newReturn,
                ),

                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Icône centrée en haut qui change selon le type de
                        // retour sélectionné (client / fournisseur).
                        Center(
                          child: Image.asset(
                            newSelectedTypeR == "Fournisseur"
                                ? 'assets/icons/sidebar/fournisseur_icon.png'
                                : 'assets/icons/sidebar/client_icon.png',
                            width: 44,
                            height: 44,
                            color: Appstyle.violet,
                            colorBlendMode: BlendMode.srcIn,
                          ),
                        ),
                        const SizedBox(height: 28),
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
                                  hint: "",
                                  enabled: false,
                                  controller: TextEditingController(
                                    text: cod,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.type,
                                obligatoire: true,
                                child: TextListe(
                                  obligatoire: true,
                                  clearable: false,
                                  value: SelectedTypeR,
                                  items: translator.typeRetourDisplayList,
                                  // ✅ Type verrouillé sur celui de l'onglet d'origine
                                  // (retour client / retour fournisseur) : on ne
                                  // laisse pas mélanger les deux depuis un même
                                  // formulaire, cohérent avec le filtrage par type
                                  // des tableaux (voir RetourScreen).
                                  enabled: initialType == null,
                                  onChanged: (v) => setState(() {
                                    SelectedTypeR = v;
                                    newSelectedTypeR = translator.typeRetourToFrench(v!);
                                    newSelectedClientR = null;
                                    newSelectedFournisseurR = null;
                                    newSelectedPannierR = null;
                                    codePannierSelectionne = null;
                                    newSelectedDocumentR = null;
                                    codeDocumentSelectionne = null;
                                    panniersDuClient = [];
                                    produitsDuPannierSelectionne = [];
                                    documentsDuFournisseur = [];
                                    produitsDuSmartScanSelectionne = [];
                                    codetype = "";
                                    _resetProduitEtQuantite();
                                    _recalculerProduitsDisponibles();
                                  }),
                                ),
                              ),
                              const SizedBox(height: 10),

                              if (newSelectedTypeR == "Client") ...[
                                ChampAvecLabel(
                                  label: l10n.client,
                                  buttonAjout: true,
                                  onAjoutPressed: () async {
                                    await showDialog(
                                      context: context,
                                      barrierColor: Appstyle.gris.withOpacity(0.25),
                                      builder: (_) {
                                        return InsertionClientDialog(
                                          clients: clientsTest,
                                          onClientSelected: (client) async {
                                            await _chargerPanniersClient(client.code);
                                            setState(() {
                                              newSelectedClientR = client.nom;
                                              codetype = client.code;
                                              newSelectedPannierR = null;
                                              codePannierSelectionne = null;
                                              produitsDuPannierSelectionne = [];
                                              _resetProduitEtQuantite();
                                              _recalculerProduitsDisponibles();
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  obligatoire: true,
                                  child: TextListe(
                                    clearable: false,
                                    obligatoire: true,
                                    value: newSelectedClientR,
                                    items: clientsTest.map((e) => e.nom).toList(),
                                    onChanged: (v) async {
                                      final client = clientsTest.firstWhere((e) => e.nom == v);
                                      await _chargerPanniersClient(client.code);
                                      setState(() {
                                        newSelectedClientR = v;
                                        codetype = client.code;
                                        newSelectedPannierR = null;
                                        codePannierSelectionne = null;
                                        produitsDuPannierSelectionne = [];
                                        _resetProduitEtQuantite();
                                        _recalculerProduitsDisponibles();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ChampAvecLabel(
                                  label: "Panier",
                                  obligatoire: true,
                                  buttonAjout: true,
                                  onAjoutPressed: panniersDuClient.isEmpty
                                      ? null
                                      : () async {
                                          await showDialog(
                                            context: context,
                                            barrierColor: Appstyle.gris.withOpacity(0.25),
                                            builder: (_) {
                                              return InsertionPannierDialog(
                                                panniers: panniersDuClient,
                                                onPannierSelected: (p) async {
                                                  await _chargerProduitsPannier(p.code);
                                                  setState(() {
                                                    newSelectedPannierR = _labelPannier(p);
                                                    codePannierSelectionne = p.code;
                                                    _resetProduitEtQuantite();
                                                    _recalculerProduitsDisponibles();
                                                  });
                                                },
                                              );
                                            },
                                          );
                                        },
                                  child: TextListe(
                                    obligatoire: true,
                                    clearable: false,
                                    enabled: panniersDuClient.isNotEmpty,
                                    value: newSelectedPannierR,
                                    hint: panniersDuClient.isEmpty
                                        ? "Aucun panier pour ce client"
                                        : l10n.select,
                                    items: panniersDuClient.map(_labelPannier).toList(),
                                    onChanged: (v) async {
                                      final p = panniersDuClient
                                          .firstWhere((e) => _labelPannier(e) == v);
                                      await _chargerProduitsPannier(p.code);
                                      setState(() {
                                        newSelectedPannierR = v;
                                        codePannierSelectionne = p.code;
                                        _resetProduitEtQuantite();
                                        _recalculerProduitsDisponibles();
                                      });
                                    },
                                  ),
                                ),
                              ],

                              if (newSelectedTypeR == "Fournisseur") ...[
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
                                          fournisseurs: fournisseursTest,
                                          onFournisseurSelected: (fournisseur) async {
                                            await _chargerDocumentsFournisseur(fournisseur.code);
                                            setState(() {
                                              newSelectedFournisseurR = fournisseur.nom;
                                              codetype = fournisseur.code;
                                              newSelectedDocumentR = null;
                                              codeDocumentSelectionne = null;
                                              produitsDuSmartScanSelectionne = [];
                                              _resetProduitEtQuantite();
                                              _recalculerProduitsDisponibles();
                                            });
                                          },
                                        );
                                      },
                                    );
                                  },
                                  child: TextListe(
                                    value: newSelectedFournisseurR,
                                    obligatoire: true,
                                    clearable: false,
                                    items: fournisseursTest.map((e) => e.nom).toList(),
                                    onChanged: (v) async {
                                      final fournisseur =
                                          fournisseursTest.firstWhere((e) => e.nom == v);
                                      await _chargerDocumentsFournisseur(fournisseur.code);
                                      setState(() {
                                        newSelectedFournisseurR = v;
                                        codetype = fournisseur.code;
                                        newSelectedDocumentR = null;
                                        codeDocumentSelectionne = null;
                                        produitsDuSmartScanSelectionne = [];
                                        _resetProduitEtQuantite();
                                        _recalculerProduitsDisponibles();
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),

                                ChampAvecLabel(
                                  label: "Document",
                                  obligatoire: true,
                                  buttonAjout: true,
                                  onAjoutPressed: smartScansDuFournisseur.isEmpty
                                      ? null
                                      : () async {
                                          await showDialog(
                                            context: context,
                                            barrierColor: Appstyle.gris.withOpacity(0.25),
                                            builder: (_) {
                                              return InsertionSmartScanDialog(
                                                smartScans: smartScansDuFournisseur,
                                                onSmartScanSelected: (s) async {
                                                  final doc = documentsDuFournisseur
                                                      .firstWhere((d) => d.code == s.code);
                                                  await _onDocumentFournisseurChoisi(doc);
                                                  setState(() {
                                                    newSelectedDocumentR = doc.label;
                                                    _resetProduitEtQuantite();
                                                  });
                                                },
                                              );
                                            },
                                          );
                                        },
                                  child: TextListe(
                                    obligatoire: true,
                                    clearable: false,
                                    enabled: documentsDuFournisseur.isNotEmpty,
                                    value: newSelectedDocumentR,
                                    hint: documentsDuFournisseur.isEmpty
                                        ? "Aucune entrée pour ce fournisseur"
                                        : l10n.select,
                                    items: documentsDuFournisseur.map((d) => d.label).toList(),
                                    onChanged: (v) async {
                                      final doc = documentsDuFournisseur
                                          .firstWhere((e) => e.label == v);
                                      await _onDocumentFournisseurChoisi(doc);
                                      setState(() {
                                        newSelectedDocumentR = v;
                                        _resetProduitEtQuantite();
                                      });
                                    },
                                  ),
                                ),
                              ],

                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                obligatoire: true,
                                label: l10n.date,
                                child: TextDate(
                                  obligatoire: true,
                                  hint: "15 nov 2025",
                                  enabled: true,
                                  controller: dateController,
                                  onTap: () => pickDate(context, dateController),
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
                                label: l10n.product,
                                obligatoire: true,
                                buttonAjout: true,
                                onAjoutPressed: produitsDisponibles.isEmpty
                                    ? null
                                    : () async {
                                  await showDialog(
                                    context: context,
                                    barrierColor: Appstyle.gris.withOpacity(0.25),
                                    builder: (_) {
                                      return InsertionProduitDialog(
                                        multiselection: false,
                                        produits: produitsDisponibles,
                                        newButton: false,
                                        onProduitSelected: (p) async {
                                          await _chargerQuantiteDejaRetournee(p.code);
                                          setState(() {
                                            ProdCode = p.code;
                                            _appliquerProduitChoisi(p);
                                          });
                                        },
                                      );
                                    },
                                  );
                                },
                                child: TextListe(
                                  value: newSelectedProduitR,
                                  obligatoire: true,
                                  clearable: false,
                                  enabled: produitsDisponibles.isNotEmpty,
                                  hint: produitHint(),
                                  items: produitsDisponibles.map((e) => e.nom).toList(),
                                  onChanged: (v) async {
                                    final p = produitsDisponibles.firstWhere((e) => e.nom == v);
                                    await _chargerQuantiteDejaRetournee(p.code);
                                    setState(() {
                                      ProdCode = p.code;
                                      _appliquerProduitChoisi(p);
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
                                  numeric: true,
                                  isQuantite: true,
                                  controller: quantiteControllerN,
                                  maxValue: quantiteMaxSelectionnee,
                                  hint: quantiteMaxSelectionnee != null
                                      ? "${l10n.max}: ${NumberFormatUtil.formatMontant(quantiteMaxSelectionnee!, decimales: 0)}"
                                      : "",
                                ),
                              ),
                              if (produitsTest.firstWhereOrNull((p) => p.code == ProdCode)?.nombreActif ?? false) ...[
                                const SizedBox(height: 10),
                                ChampAvecLabel(
                                  label: l10n.numberField,
                                  obligatoire: true,
                                  child: TextChampL(
                                    obligatoire: true,
                                    numeric: true,
                                    isQuantite: true,
                                    controller: nombreControllerN,
                                    hint: "",
                                  ),
                                ),
                              ],
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.purchasePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: prixAchatControllerN,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.salePrice,
                                child: TextChampL(
                                  hint: "",
                                  enabled: false,
                                  controller: prixVenteControllerN,
                                ),
                              ),
                              const SizedBox(height: 10),

                              ChampAvecLabel(
                                label: l10n.observation,
                                obligatoire: true,
                                child: TextChampL(
                                  controller: observationControllerN,
                                  hint: l10n.observationHint,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
                      text: l10n.save,
                      icon: Icons.save,
                      color: Appstyle.violet,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.return_,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        if (newSelectedTypeR == "Client" && newSelectedPannierR == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.return_,
                            message: l10n.selectPannierForReturn,
                          );
                          return;
                        }

                        if (newSelectedTypeR == "Fournisseur" && newSelectedDocumentR == null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.return_,
                            message: l10n.selectEntreeOrSmartScanForReturn,
                          );
                          return;
                        }

                        // ✅ Session de caisse obligatoire : aucun retour ne
                        // peut être enregistré tant que la caisse de
                        // l'utilisateur n'a pas été ouverte.
                        final paramR = params.where((e) => e.creeParCode == userCode).first;
                        final caisseR = Caisses.where((e) => e.nomCaisse == paramR.selectedCaisse).first;
                        final sessionOuverteR = await CaisseSessionServices.getSessionOuverte(caisseR.code);
                        if (sessionOuverteR == null) {
                          await CaisseFermeeDialog(
                            context: context,
                            caisses: Caisses,
                            caisseInitiale: caisseR,
                          );
                          return;
                        }

                        // ✅ Nombre obligatoire quand le produit suit le
                        // second stock "nombre" (nombreActif).
                        final double nombreSaisiN = double.tryParse(nombreControllerN.text) ?? 0;
                        if ((produitsTest.firstWhereOrNull((p) => p.code == ProdCode)?.nombreActif ?? false) &&
                            nombreSaisiN <= 0) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.return_,
                            message: l10n.numberMustBeGreaterThanZero,
                          );
                          return;
                        }

                        if (newSelectedTypeR == "Client") {
                          Retour retour = Retour(
                            codeProduit: ProdCode,
                            creeParCode: userCode,
                            observation: observationControllerN.text,
                            client_code: codetype,
                            retourCorrespondDe: codePannierSelectionne,
                            quantite: double.parse(quantiteControllerN.text),
                            nombre: nombreControllerN.text.trim().isEmpty ? null : double.tryParse(nombreControllerN.text),
                            dateCree: DateTime.now(),
                            prixAchat: double.parse(prixAchatControllerN.text),
                            prixVente: double.parse(prixVenteControllerN.text),
                            code: cod, // ✅ Code généré automatiquement
                            date: DateTime.parse(dateController.text),
                            type: newSelectedTypeR!,
                            etat: true,
                            id: id,
                          );

                          final response = await _SaveRetour(
                            userName: userName,
                            userCode: userCode,
                            retour: retour,
                          );
                          print(response.message);
                          if (!response.success) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.return_,
                              message: response.message ?? l10n.errorOccurred,
                            );
                            return;
                          }

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.success,
                            titre_concerne: l10n.return_,
                            message: response.message ?? l10n.returnSavedSuccess,
                            onTerminer: () {
                              resetSortieForm();
                              Navigator.pop(context);
                            },
                          );
                        } else {
                          // ✅ Retour fournisseur : la marchandise quitte le stock,
                          // vérifier que ça ne le ferait pas passer en négatif
                          // (scope au magasin de la caisse active).
                          final produitConcerneRetour = produitsTest.where((p) => p.code == ProdCode).firstOrNull;
                          final quantiteRetourF = double.parse(quantiteControllerN.text);
                          if (produitConcerneRetour != null) {
                            final quantiteDisponibleR = await MouvementsServices.quantiteProduit(
                              produitConcerneRetour.code,
                              magasinCode: caisseR.magasinCode,
                            );
                            if (!StockGuard.suffisant(quantiteDisponibleR, quantiteRetourF, service: produitConcerneRetour.service)) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.return_,
                                message: l10n.stockInsuffisantPourProduit(
                                  produitConcerneRetour.code,
                                  quantiteDisponibleR.toInt().toString(),
                                  quantiteRetourF.toInt().toString(),
                                ),
                              );
                              return;
                            }
                          }

                          Retour retour = Retour(
                            codeProduit: ProdCode,
                            creeParCode: userCode,
                            observation: observationControllerN.text,
                            fournisseur_code: codetype,
                            retourCorrespondDe: codeDocumentSelectionne,
                            quantite: double.parse(quantiteControllerN.text),
                            nombre: nombreControllerN.text.trim().isEmpty ? null : double.tryParse(nombreControllerN.text),
                            dateCree: DateTime.now(),
                            prixAchat: double.parse(prixAchatControllerN.text),
                            prixVente: double.parse(prixVenteControllerN.text),
                            code: cod, // ✅ Code généré automatiquement
                            date: DateTime.parse(dateController.text),
                            type: newSelectedTypeR!,
                            etat: true,
                            id: id,
                          );

                          final response = await _SaveRetour(
                            userName: userName,
                            userCode: userCode,
                            retour: retour,
                          );

                          if (!response.success) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              titre_concerne: l10n.return_,
                              message: response.message ?? l10n.errorOccurred,
                            );
                            return;
                          }

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.success,
                            titre_concerne: l10n.return_,
                            message: response.message ?? l10n.returnSavedSuccess,
                            onTerminer: () {
                              resetSortieForm();
                              Navigator.pop(context);
                            },
                          );
                        }
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
