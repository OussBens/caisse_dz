import 'package:collection/collection.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/SmartScanProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseParam.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/Services/MagasinDetail.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/core/dialog/caisse_session/caisse_fermee_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/button/ajouter_manuel.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/step_widget.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import '../../utilis/api_response.dart';
import '../../utilis/quantite_format.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<ApiResponse<int>> SaveSS({
  required String userName,
  required String userCode,
  required SmartScan SmartScan,
  required List<SmartScanProduit> Produits,
  required double paye,
  required String caisseCode,
  required String caisseNom,
  required String? magasinCode,
})
async {
  final db = await DbCreator.openDb();
  final services = await SmartScanServices(db);
  final serviceh = await HistoriqueServices(db);
  final serviceS = await SmartScanProduitServices(db);
  final serviceM = await MouvementsServices(db);
  final serviceP = await ProduitServices(db);
  final serviceFournisseur = FournisseurServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final response = await services.addSmartScan(SmartScan);
  final Produites = await ProduitServices.getAllProduits();

  // ✅ Récupérer le fournisseur
  final fournisseur = fournisseursTest.firstWhere(
        (f) => f.code == SmartScan.fournisseurCode,
    orElse: () => throw Exception("Fournisseur introuvable"),
  );

  try {
    await serviceFournisseur.ajouterAchat(
      fournisseur.id,
      SmartScan.montant,
    );
    print("✅ Fournisseur mis à jour: ${fournisseur.nom}");
  } catch (e) {
    print("⚠️ Erreur lors de la mise à jour du fournisseur: $e");
  }

  // ✅ Créer le versement de règlement du fournisseur
  if (paye > 0) {
    final versementService = VerssementServices(db);
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
      beneficiareCode: SmartScan.fournisseurCode,
      montant: paye,
      etat: true,
      mode_paiement: "Espèces",
      sense: 'Sortie',
      type: "Paiement",
      dateCree: DateTime.now(),
      creeParCode: userCode,
      caisse: caisseNom,
      codeOperation: SmartScan.code,
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
        montant: paye,
        modePaiement: "Espèces",
        codeOperation: SmartScan.code,
        fournisseurCode: SmartScan.fournisseurCode,
        date: DateTime.now(),
        etat: true,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await caisseSessionService.ajouterMouvement(mouvementCaisse);
    }
  }

  final int idH = await _GetNextHistoriqueId();
  final Historique histo = Historique(
      id: idH,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idH,
      ),
      desc: "l'utilisateur $userName a ajoutee une nouvelle Entrée de Fournisseur de ${fournisseur.nom}",
      oper: ListsConst.typeHisto[0],
      type: "SmartScan",
      dateCree: DateTime.now(),
      creeParCode: userCode
  );
  await serviceh.addHistorique(histo);

  for (var produit in Produits) {
    Produit prod = Produites.where((e) => e.code == produit.codeProduit).first;

    // ✅ Mettre à jour les champs du produit
    if (!prod.service) {
      if (produit.nombre != null) prod.nombre = prod.nombre + produit.nombre!;
    }
    prod.prixAchat = produit.prix;
    prod.prixVente = produit.prixVente; // ✅ Mettre à jour le prix de vente
    prod.dateModif = DateTime.now();
    prod.modifParCode = userCode;



    await serviceP.updateProduit(prod);

    produit.id = await _GetNextSmartScanProduitId();
    produit.codeSmartScan = SmartScan.code;

    await serviceS.addSmartScanProduit(produit);

    int idp = await _GetNextHistoriqueId();

    final Historique histoProduit = Historique(
        id: idp,
        code: CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idp,
        ),
        desc: "l'utilisateur $userName a ajoutee un nouveau produit ${prod.nom} à l'Entrée ${SmartScan.code}",
        oper: ListsConst.typeHisto[0],
        type: "SmartScanProduit",
        dateCree: DateTime.now(),
        creeParCode: userCode
    );

    await serviceh.addHistorique(histoProduit);

    // ✅ Le mouvement est construit à partir des valeurs finales du
    // SmartScanProduit (quantité/prix éventuellement modifiés dans le
    // tableau avant sauvegarde), et non d'une copie faite au moment de
    // l'ajout du produit qui pouvait rester périmée.
    int idm = await _GetNextMouvementId();
    Mouvement mouvemnt = Mouvement(
      id: idm,
      code: CodeGenerator.generateCode(
        prefix: CodePrefix.mouvement,
        id: idm,
        digitCount: 8,
      ),
      date: SmartScan.date,
      codeProduit: produit.codeProduit,
      quantite: produit.quantite,
      nombre: produit.nombre,
      prixAchat: produit.prix,
      prixVente: produit.prixVente,
      type: ListsConst.typeMouvement[1],
      // Magasin de la caisse active (voir CaisseGestion.magasinCode) — ce
      // mouvement ne portait jusqu'ici aucun magasin, rendant impossible le
      // calcul du stock par magasin pour toute entrée passée par ce dialog.
      magasinCode: magasinCode,
      etat: true,
      codeOperation: SmartScan.code,
      fournisseurCode: SmartScan.fournisseurCode,
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceM.addMouvement(mouvemnt);

    // Second stock parallèle "nombre" par magasin — quantite se déduit du
    // journal des mouvements, seul nombre reste un compteur réel à tenir.
    if (magasinCode != null) {
      final serviceMagasinDetail = ProduitMagasinDetailServices(db);
      final magasinDetail = await serviceMagasinDetail.getSingleByProduitAndMagasin(
        produit.codeProduit,
        magasinCode,
      );
      if (magasinDetail != null) {
        if (produit.nombre != null) {
          await serviceMagasinDetail.updateNombre(magasinDetail.id, magasinDetail.nombre + produit.nombre!);
        }
      } else {
        await serviceMagasinDetail.addProduitMagasinDetail(ProduitMagasinDetail(
          id: await _GetNextMagasinDetailId(),
          magasinCode: magasinCode,
          produitCode: produit.codeProduit,
          dateCree: DateTime.now(),
          creeParCode: userCode,
          nombre: produit.nombre ?? 0,
        ));
      }
    }
  }
  return response;
}

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

Future<int> _GetNextSmartScanProduitId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanProduitServices.getNextSmartScanProduitId(txn);
  });
  return id;
}

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanServices.getNextSmartScanId(txn);
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

final TextEditingController codeController = TextEditingController();
// ✅ Aperçu de la référence SmartScan (l'id réel est refetché à la sauvegarde
// dans _validerSmartScan — cet aperçu ne verrouille rien).
final TextEditingController smartScanReferenceController = TextEditingController();
final TextEditingController fournisseurController = TextEditingController();
final TextEditingController observationController = TextEditingController();
final TextEditingController payeController = TextEditingController();
final TextEditingController dateController = TextEditingController();
DateTime? selectedDate;

List<Produit> produitsTest = [];
List<Fournisseur> fournisseursTest = [];
List<CaisseGestion> caissesTest = [];

String _nomProduitCatalogue(String code) =>
    produitsTest.where((p) => p.code == code).firstOrNull?.nom ?? code;

bool _nombreActifCatalogue(String code) =>
    produitsTest.where((p) => p.code == code).firstOrNull?.nombreActif ?? false;

Future<void> _LoadAllData() async {
  produitsTest = await ProduitServices.getAllProduits();
  fournisseursTest = await FournisseurServices.getAllFournisseurs();
  caissesTest = await GCServices.getAllCaisses();

  final previewId = await _GetNextId();
  smartScanReferenceController.text = CodeGenerator.generateCode(
    prefix: CodePrefix.smartscan,
    id: previewId,
    digitCount: 6,
  );
}

class SmartScanDialog extends StatefulWidget {
  const SmartScanDialog({super.key});

  static Future<void> open(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SmartScanDialog(),
    );
  }

  @override
  State<SmartScanDialog> createState() => _SmartScanDialogState();
}

class _SmartScanDialogState extends State<SmartScanDialog> {
  void resetForm() {
    step = 1;
    actif = true;
    etat = true;

    codeController.clear();
    fournisseurController.clear();
    observationController.clear();
    payeController.clear();
    dateController.clear();

    selectedFournisseur = '';
    selectedCaisse = '';

    for (final p in produits) {
      _disposeProduitControllers(p);
    }
    produits.clear();

    selectedDate = null;

    setState(() {});
  }

  int step = 1;

  bool etat = true;
  String selectedFournisseur = '';
  String selectedCaisse = '';

  List<SmartScanProduit> produits = [];

  // Un TextEditingController recréé à chaque rebuild (ex. dans un
  // ListView.builder) perd le focus/curseur de saisie et provoque une
  // saisie qui semble "inversée" (le curseur retombe en position 0 entre
  // deux frappes). On garde donc un controller persistant par ligne,
  // nettoyé quand la ligne est supprimée ou le dialog fermé.
  final Map<SmartScanProduit, TextEditingController> _quantiteControllers = {};
  final Map<SmartScanProduit, TextEditingController> _prixAchatControllers = {};
  final Map<SmartScanProduit, TextEditingController> _prixVenteControllers = {};
  final Map<SmartScanProduit, TextEditingController> _totalControllers = {};
  final Map<SmartScanProduit, TextEditingController> _nombreControllers = {};

  TextEditingController _ctrlFor(
      Map<SmartScanProduit, TextEditingController> store,
      SmartScanProduit p,
      String initialText,
      ) {
    return store.putIfAbsent(p, () => TextEditingController(text: initialText));
  }

  void _disposeProduitControllers(SmartScanProduit p) {
    _quantiteControllers.remove(p)?.dispose();
    _prixAchatControllers.remove(p)?.dispose();
    _prixVenteControllers.remove(p)?.dispose();
    _totalControllers.remove(p)?.dispose();
    _nombreControllers.remove(p)?.dispose();
  }

  bool actif = true;

  // ✅ Seul le rôle Admin peut choisir librement la caisse ici — les autres
  // rôles sont verrouillés sur la caisse attachée à leur compte (même
  // principe que entree_nouveau.dart/sortie_nouveau.dart).
  bool peutChangerCaisseSS = false;

  double get _montantTotal => _calculTotalMontant();

  double get _payeValue => double.tryParse(payeController.text) ?? 0;

  double get _resteValue => _montantTotal - _payeValue;

  int get _nbrProduitValue => produits.length;

  @override
  void initState() {
    super.initState();
    _LoadAllData().then((_) async {
      if (!mounted) return;

      // ✅ La caisse ne se choisit jamais librement pour un non-admin : elle
      // suit toujours celle actuellement sélectionnée par l'utilisateur
      // (CaisseParam, synchronisée par ParametreCaisseDialog).
      final auth = Provider.of<AuthState>(context, listen: false);
      String? caisseSuivieNom;
      if (auth.userCode != null) {
        final db = await DbCreator.openDb();
        final param = await CaisseParamServices(db).getCaisseParamByUserCode(auth.userCode!);
        caisseSuivieNom = caissesTest.where((c) => c.code == param?.caisseCode).firstOrNull?.nomCaisse;
      }

      if (!mounted) return;
      setState(() {
        peutChangerCaisseSS = auth.role == "Admin";

        // ✅ Valeurs par défaut pour aller plus vite : date du jour et
        // fournisseur système "Général", modifiables si besoin.
        dateController.text =
            "${DateTime.now().year.toString().padLeft(4, '0')}-"
            "${DateTime.now().month.toString().padLeft(2, '0')}-"
            "${DateTime.now().day.toString().padLeft(2, '0')}";
        final fournisseurGeneral = fournisseursTest.firstWhereOrNull(
          (f) => f.code == AppConst.fournisseurGeneralCode,
        );
        if (fournisseurGeneral != null) {
          selectedFournisseur = fournisseurGeneral.nom;
          fournisseurController.text = fournisseurGeneral.nom;
        }
        selectedCaisse = caisseSuivieNom
            ?? (caissesTest.isNotEmpty ? caissesTest.first.nomCaisse : '');
      });
    });
  }

  @override
  void dispose() {
    for (final store in [
      _quantiteControllers,
      _prixAchatControllers,
      _prixVenteControllers,
      _totalControllers,
      _nombreControllers,
    ]) {
      for (final c in store.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseDialog(
      width: 1200,
      header: _buildHeader(l10n),
      content: _buildContent(l10n),
      footer: _buildFooter(l10n),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitreAvecLigne(
          imagePath: 'assets/icons/cardwidget/scan_icon.png',
          text: l10n.newSmartScan,
        ),
        const SizedBox(height: 15),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 80),
          child: StepIndicator(activeStep: step, totalSteps: 2),
        ),
      ],
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    switch (step) {
      case 1:
        return _stepFournisseurEtProduits(l10n);
      case 2:
        return _stepRecap(l10n);
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (step > 1)
          MainButton(
            onPressed: () => setState(() => step--),
            color: Appstyle.gris,
            text: l10n.back,
            icon: Icons.chevron_left,
            iconOnRight: false,
          )
        else
          MainButton(
            text: l10n.cancel,
            icon: Icons.close,
            color: Appstyle.gris,
            onPressed: () {
              resetForm();
              Navigator.pop(context);
            },
          ),

        MainButton(
          onPressed: _onNext,
          text: step == 2 ? l10n.validate : l10n.next,
          color: step == 2 ? Appstyle.violet : Appstyle.crevete,
          icon: step == 2 ? Icons.save : Icons.chevron_right,
        ),
      ],
    );
  }

  bool _validerStep(AppLocalizations l10n) {
    if (step == 1) {
      if (codeController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.supplierCodeRequired,
        );
        return false;
      }

      if (dateController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.dateRequired,
        );
        return false;
      }

      if (payeController.text.trim().isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.amountRequired,
        );
        return false;
      }

      if (selectedCaisse.isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.cashRegisterRequired,
        );
        return false;
      }

      if (produits.isEmpty) {
        InformationDialog(
          context: context,
          titre_type_message: l10n.error,
          titre_concerne: l10n.smartScan,
          message: l10n.atLeastOneProduct,
        );
        return false;
      }

      // ✅ Quantité et prix d'achat doivent être strictement positifs
      for (var produit in produits) {
        if (produit.quantite <= 0 || produit.prix <= 0) {
          InformationDialog(
            context: context,
            titre_type_message: l10n.error,
            titre_concerne: _nomProduitCatalogue(produit.codeProduit),
            message: l10n.qtyAndBuyPriceMustBePositiveFor(_nomProduitCatalogue(produit.codeProduit)),
          );
          return false;
        }
      }

      // ✅ Nombre obligatoire quand le produit suit le second stock "nombre"
      // (nombreActif).
      for (var produit in produits) {
        if (_nombreActifCatalogue(produit.codeProduit) && (produit.nombre == null || produit.nombre! <= 0)) {
          InformationDialog(
            context: context,
            titre_type_message: l10n.error,
            titre_concerne: _nomProduitCatalogue(produit.codeProduit),
            message: l10n.numberMustBeGreaterThanZero,
          );
          return false;
        }
      }

      // ✅ Vérifier que le prix de vente est supérieur au prix d'achat pour chaque produit
      for (var produit in produits) {
        if (produit.prixVente <= produit.prix) {
          InformationDialog(
            context: context,
            titre_type_message: l10n.error,
            titre_concerne: _nomProduitCatalogue(produit.codeProduit),
            message: l10n.sellPriceMustExceedBuyPriceFor(_nomProduitCatalogue(produit.codeProduit)),
          );
          return false;
        }
      }

      return true;
    }

    return true;
  }

  void _onNext() async {
    final l10n = AppLocalizations.of(context)!;

    if (!_validerStep(l10n)) return;

    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;

    if (step < 2) {
      setState(() => step++);
      return;
    }

    await _validerSmartScan(userName: userName, userCode: userCode, l10n: l10n);
  }

  double _calculTotalMontant() {
    return produits.fold(0.0, (sum, p) => sum + (p.prix * p.quantite));
  }

  Future<void> _validerSmartScan({
    required String userName,
    required String userCode,
    required AppLocalizations l10n
  }) async {
    // ✅ Session de caisse obligatoire : aucun achat ne peut être enregistré
    // tant que la caisse choisie n'a pas été ouverte.
    final caisseChoisie = caissesTest.where((c) => c.nomCaisse == selectedCaisse).firstOrNull;
    if (caisseChoisie == null) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.smartScan,
        message: l10n.caisseNotFound(selectedCaisse),
      );
      return;
    }
    final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseChoisie.code);
    if (sessionOuverte == null) {
      await CaisseFermeeDialog(
        context: context,
        caisses: caissesTest,
        caisseInitiale: caisseChoisie,
      );
      return;
    }

    DateTime date = DateTime.tryParse(dateController.text) ?? DateTime.now();

    final id = await _GetNextId();

    final code = CodeGenerator.generateCode(
      prefix: CodePrefix.smartscan,
      id: id,
      digitCount: 6,
    );

    SmartScan smartscan = SmartScan(
      id: id,
      code: code,
      date: date,
      etat: etat,
      dateCree: DateTime.now(),
      creeParCode: userCode,
      fournisseurCode: codeController.text,
      nbrProduit: _nbrProduitValue,
      montant: _montantTotal,
      observation: observationController.text.trim().isEmpty
          ? null
          : observationController.text.trim(),
    );

    final response = await SaveSS(
      userName: userName,
      userCode: userCode,
      SmartScan: smartscan,
      Produits: produits,
      paye: _payeValue,
      caisseCode: caisseChoisie.code,
      caisseNom: caisseChoisie.nomCaisse,
      magasinCode: caisseChoisie.magasinCode,
    );

    if (response.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.success,
        titre_concerne: l10n.smartScan,
        message: l10n.smartScanSavedSuccess,
        onTerminer: () {
          resetForm();
          Navigator.pop(context);
        },
      );
    }

    if (!response.success) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.error,
        titre_concerne: l10n.smartScan,
        message: response.message,
        onTerminer: () {
          resetForm();
          Navigator.pop(context);
        },
      );
    }
  }

  Widget _stepFournisseurEtProduits(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
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
                      enabled: false,
                      controller: smartScanReferenceController,
                      hint: "",
                    ),
                  ),
                  const SizedBox(height: 15),
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
                            onFournisseurSelected: (fournisseur) {
                              setState(() {
                                selectedFournisseur = fournisseur.nom;
                                codeController.text = fournisseur.code;
                                fournisseurController.text = fournisseur.nom;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      obligatoire: true,
                      width: 350,
                      value: selectedFournisseur,
                      clearable: false,
                      items: fournisseursTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedFournisseur = v!;
                          fournisseurController.text = v;
                          codeController.text = fournisseursTest.where((t) => t.nom == v).first.code;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Caisse toujours celle actuellement sélectionnée par
                  // l'utilisateur — libre uniquement pour l'Admin (voir
                  // peutChangerCaisseSS), jamais un choix libre pour les
                  // autres rôles (cf. ParametreCaisseDialog pour la changer).
                  ChampAvecLabel(
                    label: l10n.cashRegister,
                    obligatoire: true,
                    buttonAjout: peutChangerCaisseSS,
                    onAjoutPressed: !peutChangerCaisseSS ? null : () async {
                      await showDialog(
                        context: context,
                        barrierColor: Appstyle.gris.withOpacity(0.25),
                        builder: (_) {
                          return InsertionCaisseDialog(
                            caisses: caissesTest,
                            onCaisseSelected: (c) {
                              setState(() => selectedCaisse = c.nomCaisse);
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      obligatoire: true,
                      width: 350,
                      clearable: false,
                      enabled: peutChangerCaisseSS,
                      value: selectedCaisse,
                      items: caissesTest.map((c) => c.nomCaisse).toSet().toList(),
                      onChanged: peutChangerCaisseSS ? (v) => setState(() => selectedCaisse = v!) : (_) {},
                    ),
                  ),
                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    obligatoire: true,
                    label: l10n.date,
                    child: TextDate(
                        obligatoire: true,
                        width: 350,
                        hint: "15 nov 2025",
                        controller: dateController,
                        onTap: () => pickDate(context, dateController)
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    label: l10n.paye,
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      controller: payeController,
                      hint: "0.00",
                      numeric: true,
                      onChanged: (v) => setState(() {}),
                    ),
                  ),
                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    label: l10n.observation,
                    child: TextChampL(
                      hint: '',
                      controller: observationController,
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
                    label: l10n.amount,
                    child: TextChampL(
                      enabled: false,
                      controller: TextEditingController(
                        text: _montantTotal.toStringAsFixed(2),
                      ),
                      hint: "0.00",
                      numeric: true,
                    ),
                  ),


                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    label: l10n.reste,
                    child: TextChampL(
                      enabled: false,
                      controller: TextEditingController(
                        text: _resteValue.toStringAsFixed(2),
                      ),
                      hint: "0.00",
                      numeric: true,
                    ),
                  ),

                  const SizedBox(height: 15),

                  ChampAvecLabel(
                    label: l10n.productCount,
                    child: TextChampL(
                      enabled: false,
                      controller: TextEditingController(
                        text: _nbrProduitValue.toString(),
                      ),
                      hint: '0',
                    ),
                  ),


                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Tableau dimensionné à son contenu suivi directement du bouton
        // « ajouter » (même disposition que le dialog Pack), au lieu d'un
        // tableau extensible poussant le bouton en bas du dialog.
        _produitsTable(l10n),
        const SizedBox(height: 15),
        GestureDetector(
          onTap: _ouvrirInsertionProduitDialog,
          child: const AddManualWidget(),
        ),
      ],
      ),
    );
  }

  Widget _stepRecap(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.summary,
          style: Appstyle.textL.copyWith(
            color: Appstyle.violet,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("${l10n.supplier}: ${fournisseurController.text}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.date}: ${dateController.text}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.productCount}: $_nbrProduitValue",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${l10n.amount}: ${NumberFormatUtil.formatMontant(_montantTotal, decimales: 2)} ${l10n.currency}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
                Text("${l10n.paye}: ${NumberFormatUtil.formatMontant(_payeValue, decimales: 2)} ${l10n.currency}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
                Text("${l10n.reste}: ${NumberFormatUtil.formatMontant(_resteValue, decimales: 2)} ${l10n.currency}",
                    style: Appstyle.textSB.copyWith(color: Appstyle.gris)),
              ],
            ),
          ],
        ),

        const Divider(height: 30, color: Colors.grey),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Appstyle.violetC.withOpacity(0.2),
          child: Row(
            children: [
              Expanded(flex: 2, child: Text(l10n.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text(l10n.product,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.quantity,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.purchasePrice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.salePrice,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text(l10n.amount,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ),

        const Divider(height: 0, color: Colors.grey),

        Expanded(
          child: ListView.separated(
            itemCount: produits.length,
            separatorBuilder: (_, __) => const Divider(color: Colors.grey),
            itemBuilder: (_, i) {
              final p = produits[i];
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                color: i % 2 == 0 ? Colors.white : Appstyle.grisC.withOpacity(0.05),
                child: Row(
                  children: [
                    Expanded(flex: 2, child: Text(p.codeProduit,
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 3, child: Text(_nomProduitCatalogue(p.codeProduit),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(NumberFormatUtil.formatMontant(p.quantite, decimales: 0),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(NumberFormatUtil.formatMontant(p.prix, decimales: 2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB)),
                    Expanded(flex: 2, child: Text(NumberFormatUtil.formatMontant(p.prixVente, decimales: 2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB.copyWith(color: Appstyle.crevete))),
                    Expanded(flex: 2, child: Text(NumberFormatUtil.formatMontant((p.quantite * p.prix), decimales: 2),
                        textAlign: TextAlign.center,
                        style: Appstyle.textSB.copyWith(color: Appstyle.violet))),
                  ],
                ),
              );
            },
          ),
        ),

        const Divider(color: Colors.grey),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          color: Appstyle.violetC.withOpacity(0.2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l10n.total,
                  style: Appstyle.textMB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
              Text("${NumberFormatUtil.formatMontant(_montantTotal, decimales: 2)} ${l10n.currency}",
                  style: Appstyle.textMB.copyWith(color: Appstyle.violet, fontWeight: FontWeight.bold)),
            ],
          ),
        ),

        const SizedBox(height: 15),
      ],
    );
  }

  Widget _produitsTable(AppLocalizations l10n) {
    if (produits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(child: Text(l10n.noProductsAdded)),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: produits.length,
      itemBuilder: (_, i) {
        final p = produits[i];

        final quantiteController = _ctrlFor(_quantiteControllers, p, QuantiteFormat.format(p.quantite));
        final prixAchatController = _ctrlFor(_prixAchatControllers, p, p.prix.toString());
        final prixVenteController = _ctrlFor(_prixVenteControllers, p, p.prixVente.toString());
        final totalController = _ctrlFor(_totalControllers, p, NumberFormatUtil.formatMontant((p.quantite * p.prix), decimales: 2));
        final nombreController = _ctrlFor(_nombreControllers, p, p.nombre != null ? QuantiteFormat.format(p.nombre!) : '');

        void _updateTotal() {
          final q = double.tryParse(quantiteController.text) ?? 0;
          final prix = double.tryParse(prixAchatController.text) ?? 0;
          final prixVente = double.tryParse(prixVenteController.text) ?? 0;

          setState(() {
            p.quantite = q;
            p.prix = prix;
            p.prixVente = prixVente;
            p.total = q * prix;
            totalController.text = p.total.toStringAsFixed(2);
          });
        }

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text("${p.codeProduit}-${_nomProduitCatalogue(p.codeProduit)}",
                    style: Appstyle.textSB),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: quantiteController,
                  keyboardType: TextInputType.number,
                  inputFormatters: QuantiteFormat.inputFormatters,
                  decoration: InputDecoration(
                    labelText: l10n.quantity,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (_) => _updateTotal(),
                ),
              ),

              if (_nombreActifCatalogue(p.codeProduit)) ...[
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: nombreController,
                    keyboardType: TextInputType.number,
                    inputFormatters: QuantiteFormat.inputFormatters,
                    decoration: InputDecoration(
                      labelText: l10n.numberField,
                      border: const OutlineInputBorder(),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    onChanged: (v) {
                      final saisie = v.replaceAll(',', '.').trim();
                      setState(() {
                        p.nombre = saisie.isEmpty ? null : double.tryParse(saisie);
                      });
                    },
                  ),
                ),
              ],

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: prixAchatController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.purchasePrice,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (_) => _updateTotal(),
                ),
              ),

              const SizedBox(width: 10),

              // ✅ NOUVEAU CHAMP PRIX VENTE
              Expanded(
                flex: 2,
                child: TextField(
                  controller: prixVenteController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.salePrice,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                  onChanged: (v) {
                    // ✅ Vérifier que prix vente > prix achat
                    final prixAchat = double.tryParse(prixAchatController.text) ?? 0;
                    final prixVente = double.tryParse(v) ?? 0;
                    if (prixVente <= prixAchat && prixVente > 0) {
                      // Afficher un warning mais ne pas bloquer
                      print("⚠️ Prix de vente doit être supérieur au prix d'achat pour ${_nomProduitCatalogue(p.codeProduit)}");
                    }
                    _updateTotal();
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                flex: 2,
                child: TextField(
                  controller: totalController,
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: l10n.total,
                    border: const OutlineInputBorder(),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  ),
                ),
              ),

              const SizedBox(width: 10),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => setState(() {
                  produits.removeAt(i);
                  _disposeProduitControllers(p);
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  void _ouvrirInsertionProduitDialog() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username!;
    final userCode = auth.userCode!;
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (_) => InsertionProduitDialog(
        multiselection: true,
        newButton:false,
        produits: produitsTest,
        onProduitSelected: (produit) async {
          final existe = produits.any(
                (p) => p.codeProduit == produit.code,
          );

          if (existe) {
            InformationDialog(
              context: context,
              titre_type_message: l10n.information,
              titre_concerne: l10n.productAlreadyAdded(produit.nom),
              message: l10n.productExistsInSmartScan,
            );
            return;
          }

          setState(() {
            // ✅ Quantité par défaut = 1 (quantité achetée, pas le stock
            // catalogue actuel) ; le mouvement correspondant est construit
            // à la sauvegarde à partir de ce SmartScanProduit.
            final smartScanProduit = SmartScanProduit(
              codeSmartScan: "SMC-PRD",
              codeProduit: produit.code,
              creeParCode: userCode,
              quantite: 1,
              creeLe: DateTime.now(),
              total: produit.prixAchat.toDouble(),
              prix: produit.prixAchat.toDouble(),
              prixVente: produit.prixVente.toDouble(), // ✅ Ajout du prix de vente
              etat: true,
              id: 0,
            );

            produits.add(smartScanProduit);
          });
        },
      ),
    );
  }
}
