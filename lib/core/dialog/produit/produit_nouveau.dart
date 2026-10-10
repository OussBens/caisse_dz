import 'dart:async';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'dart:io';
import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pack.dart' hide ApiResponse;
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/CatalogService.dart';
import 'package:caisse_dz/Services/CatalogSyncService.dart';
import 'package:caisse_dz/Services/OpenFoodFactsService.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/insertion_categorie.dart';
import 'package:caisse_dz/core/dialog/insertion_pack.dart';
import 'package:caisse_dz/core/dialog/insertion_remise.dart';
import 'package:caisse_dz/core/dialog/insertion_souscategorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/prix_vente_calculator.dart';
import 'package:caisse_dz/core/widget/champ/affichage_champ.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/ai_smart_icon.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../Services/Photos.dart';
import '../../../data/models/pack.dart';
import '../../utilis/api_response.dart';
import '../../utilis/barcode_scan_listener.dart';
import '../../widget/button/button_add_photo.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/radio_champ.dart';
import '../../widget/code_generateur.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../../widget/internet_status_widget.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_codebar.dart';
import 'produit_barcode_generator.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// Le choix du fournisseur a été retiré de l'interface : tout produit est
// désormais rattaché au fournisseur système "Général" (FOR0000).
const String kSystemFournisseurCode = 'FOR0000';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextPackDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitPackDetailServices.getNextId(txn);
  });
  return id;
}
Future<int> _GetNextCodeDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitServices.getNextId(txn);
  });
  return id;
}
Future<void> _saveProduitCodeDetailes({
  required Produit produit,
  required List<String> codes,
  required String userName,
  required String userCode,
}) async {
  print('📝 Début sauvegarde des codes-barres: ${codes.length} codes');

  final db = await DbCreator.openDb();

  // ✅ Vérifier que la table existe
  try {
    final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='produit_code_detail'"
    );

    if (tables.isEmpty) {
      print('⚠️ Table produit_code_detail manquante - Création...');
      await db.execute('''
        CREATE TABLE produit_code_detail (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codebar TEXT NOT NULL,
          produit_code TEXT NOT NULL,
          date_cree TEXT NOT NULL,
          cree_par_code TEXT NOT NULL
        )
      ''');
      print('✅ Table produit_code_detail créée');
    } else {
      print('✅ Table produit_code_detail existe');
    }
  } catch (e) {
    print('❌ Erreur vérification table: $e');
  }

  for (var code in codes) {
    try {
      print('🔑 Sauvegarde du code: $code');

      // ✅ Obtenir le prochain ID
      final idResult = await db.rawQuery(
          'SELECT MAX(id) AS maxId FROM produit_code_detail'
      );
      final maxId = idResult.first['maxId'] as int?;
      final nextId = (maxId ?? 0) + 1;
      print('📌 ID généré: $nextId');

      // ✅ Créer le détail
      final detail = ProduitCodeDetail(
        id: nextId,
        CodeBar: code,
        produitCode: produit.code,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );

      // ✅ Insertion DIRECTE
      final data = detail.toMap();
      data['id'] = detail.id;

      final insertResult = await db.insert(
        'produit_code_detail',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Code-barres sauvegardé avec succès: $insertResult');

      // Ajouter l'historique
      final int idH = await _GetNextHistoriqueId();
      final db2 = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db2);
      final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a ajouter le CodeBar ${code} au produit ${produit.nom}",
        type: "ProduitCodeDetail",
        oper: ListsConst.typeHisto[0],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );

      await serviceh.addHistorique(histo);
      print('📜 Historique ajouté pour le code: $code');

    } catch (e, stack) {
      print('❌ Erreur lors de la sauvegarde du code $code: $e');
      print(stack);
      // Continuer avec le prochain code
    }
  }

  print('✅ Tous les codes-barres ont été sauvegardés avec succès');
}
Future<void> _saveProduitPackDetailes({
  required Produit produit,
  required List<Pack> packs,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitPackDetailServices(db);
  final packService = PackServices(db);

  for (var pack in packs) {
    final ProduitPackDetail detail = ProduitPackDetail(
      packCode: pack.code,
      produitCode: produit.code,
      dateCree: DateTime.now(),
      id: await _GetNextPackDetailId(),
      creeParCode: userCode, prixUnitaire: produit.prixVente, quantite: 1, montant: produit.prixVente,
    );
    await service.addProduitPackDetail(detail);

    final int idH = await _GetNextHistoriqueId();
    final db = await DbCreator.openDb();
    final serviceh = await HistoriqueServices(db);
    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a ajouter le ProduitPackDetail de Pack ${pack.nom} de produit ${produit.nom}",
        type: "ProduitPackDetail",
        oper: ListsConst.typeHisto[0],
        dateCree: DateTime.now(),
        creeParCode: userCode);

    await serviceh.addHistorique(histo);
  }
}
// Ajoutez cette fonction après les autres fonctions comme _GetNextHistoriqueId, etc.
Future<String?> _saveProductPhoto(String productCode, String? tempPhoto) async {
  if (tempPhoto == null || tempPhoto.isEmpty) return null;

  if (PhotoService.isTempPhoto(tempPhoto)) {
    final tempFile = File(tempPhoto);
    if (await tempFile.exists()) {
      // Sauvegarder la nouvelle photo
      final savedName = await PhotoService.savePhoto(tempFile, productCode);
      await tempFile.delete();
      debugPrint('📸 Photo temporaire sauvegardée: $savedName');
      return savedName;
    }
  } else {
    // C'est déjà une photo sauvegardée
    debugPrint('📸 Photo existante conservée: $tempPhoto');
    return tempPhoto;
  }

  return null;
}
Future<
    ApiResponse<int>> _saveProduit({
  required Produit produit,
  required String? tempPhoto,
}) async {
  final db = await DbCreator.openDb();
  final services = ProduitServices(db);

  // Sauvegarder la photo unique
  final savedPhoto = await _saveProductPhoto(produit.code, tempPhoto);
  produit.photo = savedPhoto;  // ✅ Utiliser photo au lieu de photos

  const systemMagasinNom = "Magasin System"; // Nom du magasin par défaut
  return await services.addProduitWithSystemMagasin(produit, systemMagasinNom);
}
Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitServices.getNextProduitId(txn);
  });
  return id;
}




Future<void> loadAllData() async {
  try {
    final sous = await SousCategoriesServices.getAllSousCategorie();
    final remise = await RemiseServices.getAllRemise();
    final categorie = await CategorieServices.getAllCategorie();
    final pack = await PackServices.getAllPacks();
    final Param = await ParamServices.getParam();

    categoriesTest = categorie;
    remisesTest = remise;
    paramters = Param;
    packsTest = pack;
    sousCategoriesTest = sous;
  } catch (e) {
    debugPrint("Erreur chargement : $e");
  }
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
// Ajoutez cette fonction après les autres déclarations
String _calculerPrixParPiece(String quantiteText, String prixText) {
  final double quantite = double.tryParse(quantiteText.replaceAll(',', '.')) ?? 0;
  final double prix = double.tryParse(prixText.replaceAll(',', '.')) ?? 0;

  if (quantite <= 0 || prix <= 0) return "0.00";

  final prixParPiece = prix / quantite;
  return NumberFormatUtil.formatMontant(prixParPiece, decimales: 2);
}
void resetProduitForm() {
  dateController.clear();
  nomController.clear();
  descontroller.clear();
  observcontroller.clear();
  marqueController.clear();
  fournController.clear();
  codeController.clear();
  prixController.clear();
  prixController2.clear();
  tailleController.clear();
  couleurController.clear();
  numserieController.clear();
  refernceController.clear();
  jeu1Controller.clear();
  jeu2Controller.clear();
  jeu1PrixController.clear();
  jeu2PrixController.clear();
  tvaController.clear();
  multicodeController.clear();
  selectedRemise = null;
  selectedCategorie = null;
  selectedSousCategorie = null;
  selectedUnitemesure = ListsConst.uniteMesureList.first;
  productPhoto = null;
  service = false;
  nombreActif = false;
  merge = true;
  multicodebar = false;
  sansCodeBar = false;
  aiBarcodeController.clear();
  aiLoading = false;
  aiNotFound = false;
  aiError = null;
  aiResult = null;
  aiExistingLocal = null;

  packsSelectionnes.clear();
  barcodes.clear();
  afficherErreursTabsProduit = false;
}

// ✅ Mode détaillé (onglets) : indicateur "point rouge" sur l'onglet contenant
// un champ obligatoire invalide, affiché après une tentative de sauvegarde
// échouée pour orienter l'utilisateur — recalculé à chaque frappe/sélection.
bool afficherErreursTabsProduit = false;

bool _emballagePrixInvalide(TextEditingController qteController, TextEditingController prixController2) {
  final prixEmballageTotal = double.tryParse(prixController2.text.replaceAll(',', '.'));
  final quantite = double.tryParse(qteController.text.replaceAll(',', '.'));
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));

  if (prixController2.text.trim().isEmpty) return true;
  if (prixEmballageTotal == null || prixEmballageTotal <= 0) return true;
  if (quantite == null || quantite <= 0) return true;
  if (prixAchat != null && (prixEmballageTotal / quantite) < prixAchat) return true;
  return false;
}

Set<int> _tabsAvecErreursProduit() {
  final erreurs = <int>{};

  // Onglet 0 : Informations générales
  if (nomController.text.trim().isEmpty ||
      marqueController.text.trim().isEmpty) {
    erreurs.add(0);
  }

  // Onglet 2 : Catégorie & Remise
  if (selectedCategorie == null || selectedCategorie!.isEmpty ||
      selectedSousCategorie == null || selectedSousCategorie!.isEmpty) {
    erreurs.add(2);
  }

  // Onglet 3 : Prix & Taxes
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));
  final prixVente = double.tryParse(prixController2.text.replaceAll(',', '.'));
  if (prixController.text.trim().isEmpty || prixAchat == null || prixAchat <= 0 ||
      tvaController.text.trim().isEmpty ||
      prixController2.text.trim().isEmpty || prixVente == null ||
      (prixAchat != null && prixVente != null && prixVente < prixAchat)) {
    erreurs.add(3);
  }

  // Onglet 4 : Stock & Emballage
  if (selectedUnite == null || selectedUnite!.isEmpty) {
    erreurs.add(4);
  } else if (emballage1Actif && _emballagePrixInvalide(jeu1Controller, jeu1PrixController)) {
    erreurs.add(4);
  } else if (emballage2Actif && _emballagePrixInvalide(jeu2Controller, jeu2PrixController)) {
    erreurs.add(4);
  }

  return erreurs;
}

Widget _tabAvecIndicateur(String text, bool showErreur) {
  return Tab(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Text(text),
        if (showErreur)
          Positioned(
            right: -8,
            top: -4,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Appstyle.danger, shape: BoxShape.circle),
            ),
          ),
      ],
    ),
  );
}

Future<void> calculPrixVenteAuto() async {
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.')) ?? 0;
  double prixVente = prixAchat;

  if (merge) {
    prixVente = PrixVenteCalculator.calculAuto(
      prixAchat,
      margeType: margeTypePrmtre,
      margeTaux: margetauxPrmtre,
    );
  } else {
    final margeMontant = double.tryParse(margeController.text.replaceAll(',', '.')) ?? 0;
    final margePercentage = double.tryParse(margePController.text.replaceAll(',', '.')) ?? 0;

    if (margeMontant > 0) {
      prixVente = prixAchat + margeMontant;
    } else if (margePercentage > 0) {
      prixVente = PrixVenteCalculator.arrondirAuMultipleDe5(prixAchat + (prixAchat * margePercentage / 100));
    }
  }

  prixController2.text = prixVente.toStringAsFixed(2);
}
String? productPhoto;

int id = 0;
String code = "";
List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];

String? _codeCategorieByNom(String? nom) =>
    nom == null ? null : categoriesTest.where((c) => c.nom == nom).firstOrNull?.code;
List<Remise> remisesTest = [];
List<Pack> packsTest = [];
List<Pack> packsSelectionnes = [];
List<String> barcodes = [];

// ✅ Nouveau produit : seules les catégories actives contenant au moins une
// sous-catégorie active sont proposées, pour éviter de rattacher un produit
// à une catégorie qui n'a aucune sous-catégorie sélectionnable.
List<Categorie> _categoriesActives() => categoriesTest
    .where((c) => c.etat && sousCategoriesTest.any((sc) => sc.etat && sc.categorieCode == c.code))
    .toList();

List<SousCategorie> _sousCategoriesActivesPour(String? categorieNom) => sousCategoriesTest
    .where((sc) => sc.etat && sc.categorieCode == _codeCategorieByNom(categorieNom))
    .toList();

List<Pack> _packsActifs() => packsTest.where((p) => p.etat).toList();
late Paramters paramters;

int? selectedCategorieid;
int? selectedSousCategorieid;
int? remiseId;
int? packId;

double margetauxPrmtre = 0;
String margeTypePrmtre = "Montant";

final TextEditingController multicodeController = TextEditingController();
final TextEditingController margeController = TextEditingController();
final TextEditingController margePController = TextEditingController();
final TextEditingController dateController = TextEditingController();
final TextEditingController nomController = TextEditingController();
final TextEditingController descontroller = TextEditingController();
final TextEditingController observcontroller = TextEditingController();
final TextEditingController marqueController = TextEditingController();
final TextEditingController fournController = TextEditingController();
final TextEditingController codeController = TextEditingController();
final TextEditingController prixController = TextEditingController();
final TextEditingController prixController2 = TextEditingController();
final TextEditingController tailleController = TextEditingController();
final TextEditingController couleurController = TextEditingController();
final TextEditingController numserieController = TextEditingController();
final TextEditingController refernceController = TextEditingController();
final TextEditingController jeu1Controller = TextEditingController();
final TextEditingController jeu2Controller = TextEditingController();
final TextEditingController jeu1PrixController = TextEditingController();
final TextEditingController jeu2PrixController = TextEditingController();
final TextEditingController tvaController = TextEditingController();

// ✅ Onglet IA : recherche produit par code-barres (scanner ou saisie manuelle)
final TextEditingController aiBarcodeController = TextEditingController();
// Évite de relancer la recherche IA à chaque rebuild du StatefulBuilder :
// remis à false à chaque ouverture du dialog (voir ProduitNouveau).
bool _aiAutoLookupTriggered = false;
bool aiLoading = false;
bool aiNotFound = false;
String? aiError;
ProduitAISuggestion? aiResult;
Produit? aiExistingLocal;
double aiExistingLocalQuantite = 0;
final CatalogService _catalogService = CatalogService();
BarcodeScanListener? _aiScanListener;
void Function(void Function())? _aiSetState;

/// Recherche le produit dans la cascade complète (local -> catalogue
/// CaisseDZ -> Open Food Facts -> Open Pet Food Facts -> Open Beauty
/// Facts), voir [CatalogService].
Future<void> _lookupProduitIA(String barcode) async {
  _aiSetState?.call(() {
    aiLoading = true;
    aiNotFound = false;
    aiError = null;
    aiResult = null;
    aiExistingLocal = null;
    aiExistingLocalQuantite = 0;
  });

  // CatalogService avale déjà les échecs techniques source par source pour
  // passer au maillon suivant de la cascade ; seul un "introuvable partout"
  // remonte ici (aiNotFound), pas d'exception à intercepter.
  final result = await _catalogService.lookupByBarcode(barcode);
  // Quantité calculée depuis le journal des mouvements — remplace Produit.quantite.
  final quantiteExistante = (result != null && result.source == CatalogLookupSource.local && result.existingProduit != null)
      ? await MouvementsServices.quantiteProduit(result.existingProduit!.code)
      : 0.0;
  _aiSetState?.call(() {
    aiLoading = false;
    if (result == null) {
      aiNotFound = true;
    } else if (result.source == CatalogLookupSource.local) {
      aiExistingLocal = result.existingProduit;
      aiExistingLocalQuantite = quantiteExistante;
    } else {
      aiResult = result.suggestion;
    }
  });
}

Future<void> _appliquerSuggestionIA(ProduitAISuggestion suggestion) async {
  nomController.text = suggestion.nom ?? nomController.text;
  if (suggestion.marque != null) marqueController.text = suggestion.marque!;
  if (suggestion.codeBarre != null) codeController.text = suggestion.codeBarre!;
  if (suggestion.taille != null) tailleController.text = suggestion.taille!;
  if (suggestion.couleur != null) couleurController.text = suggestion.couleur!;

  // ✅ Catégorie suggérée : on ne la sélectionne que si elle existe déjà
  // dans la base locale (comparaison par nom, insensible à la casse). Si
  // elle n'existe pas localement, on garde le repli "Sans Categorie" /
  // "Sans Sous-Catego" déjà positionné à l'ouverture du dialog.
  if (suggestion.categorie != null && suggestion.categorie!.trim().isNotEmpty) {
    final categorieLocale = categoriesTest.firstWhereOrNull(
      (c) => c.nom.trim().toLowerCase() == suggestion.categorie!.trim().toLowerCase(),
    );
    if (categorieLocale != null) {
      selectedCategorie = categorieLocale.nom;
      selectedCategorieid = categorieLocale.id;
      final sousCategorieParDefaut = sousCategoriesTest.firstWhereOrNull(
        (sc) => sc.categorieCode == categorieLocale.code && sc.nom == 'Sans Sous-Catego',
      );
      selectedSousCategorie = sousCategorieParDefaut?.nom;
      selectedSousCategorieid = sousCategorieParDefaut?.id;
    }
  }

  if (suggestion.photoUrl != null) {
    final tempPhotoPath = await OpenFoodFactsService.downloadAndCompressPhoto(suggestion.photoUrl!);
    if (tempPhotoPath != null) productPhoto = tempPhotoPath;
  }
}

bool service = false;
bool nombreActif = false;

// ✅ "Nombre" (stock parallèle en pièces) n'a de sens que pour un produit
// vendu au poids/volume (Kg/Litre) — pour un produit déjà vendu à la pièce,
// quantité == nombre, ça n'apporterait rien.
bool _uniteEligibleNombre(String? uniteMesureFrench) =>
    uniteMesureFrench == 'Kg' || uniteMesureFrench == 'Litre';
bool merge = true;
bool multicodebar = false;
bool sansCodeBar = false;
bool emballage1Actif = false;
bool emballage2Actif = false;
String? selectedUnitemesure = ListsConst.uniteMesureList[1];
String? selectedRemise;
String? selectedCategorie;
String? selectedSousCategorie;
String? selectedUnite;

Color colorchamp = Appstyle.grisSC;
Color colorchampenabled = Appstyle.grisC;
String? selectedUniteDisplay;
final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();
void ajouterBarcode(void Function(VoidCallback fn) setState) {
  final code = multicodeController.text.trim();

  if (code.isEmpty) return;

  if (barcodes.contains(code)) {
    multicodeController.clear();
    return;
  }

  setState(() {
    barcodes.add(code);
    multicodeController.clear();
  });
}
void supprimerBarcode(
    String code,
    void Function(VoidCallback fn) setState,
    ) {
  setState(() {
    barcodes.remove(code);
  });
}

Future<void> ProduitNouveau(
  BuildContext context, {
  String? initialCodeBarre,
  void Function(Produit)? onCreated,
}) async {
  await loadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  id = await _GetNextId();
  code = CodeGenerator.generateCode(prefix: CodePrefix.produit, id: id, digitCount: 6);
  codeController.text = initialCodeBarre ?? '';
  // ✅ Pré-remplit aussi le champ code-barres de l'onglet IA (par défaut à
  // l'ouverture) avec le code scanné en caisse, pour lancer la recherche
  // automatiquement au lieu de forcer une re-saisie manuelle.
  aiBarcodeController.text = initialCodeBarre ?? '';
  _aiAutoLookupTriggered = false;

  // ✅ Catégorie/sous-catégorie par défaut : "Sans Categorie" / "Sans Sous-Catego"
  final categorieParDefaut = categoriesTest.firstWhereOrNull((c) => c.nom == 'Sans Categorie');
  selectedCategorie = categorieParDefaut?.nom;
  selectedCategorieid = categorieParDefaut?.id;
  final sousCategorieParDefaut = sousCategoriesTest.firstWhereOrNull(
    (sc) => sc.categorieCode == categorieParDefaut?.code && sc.nom == 'Sans Sous-Catego',
  );
  selectedSousCategorie = sousCategorieParDefaut?.nom;
  selectedSousCategorieid = sousCategorieParDefaut?.id;

  _aiScanListener?.stop();
  _aiScanListener = BarcodeScanListener(onScan: (code) {
    aiBarcodeController.text = code;
    _lookupProduitIA(code);
  })
    ..start();

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      // ✅ Démarre sur "rapide" plutôt que "ia" : l'onglet IA nécessite une
      // connexion internet, autant éviter un onglet inutilisable par défaut.
      String modeActif = "rapide"; // "ia" | "rapide" | "detaille"
      margeTypePrmtre = paramters.typeMarge;
      if (margeTypePrmtre == "Montant") {
        margetauxPrmtre = paramters.TauxMargeMontant;
      } else {
        margetauxPrmtre = paramters.TauxMargePerncetage;
      }

      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          _aiSetState = setState;

          // ✅ Un code-barres pré-rempli (venant d'un scan en caisse) lance
          // la recherche IA automatiquement, comme le ferait un scan en
          // direct — après le build en cours pour ne pas appeler setState
          // pendant que ce StatefulBuilder est lui-même en train de builder.
          if (!_aiAutoLookupTriggered && initialCodeBarre != null && initialCodeBarre.isNotEmpty) {
            _aiAutoLookupTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _lookupProduitIA(initialCodeBarre);
            });
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/produit_icon.png',
                  text: l10n.newProduct,
                ),
                content: Form(
                  key: produitFormKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Appstyle.grisC.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => modeActif = "ia"),
                                child: AiSmartIcon(
                                  iconPath: "assets/icons/smart_icon.png",
                                  width: 120,
                                  height: 60,
                                  active: modeActif == "ia",
                                ),
                              ),
                              const SizedBox(width: 10),
                              _modePill(
                                label: l10n.quickMode,
                                actif: modeActif == "rapide",
                                onTap: () => setState(() => modeActif = "rapide"),
                              ),
                              const SizedBox(width: 10),
                              _modePill(
                                label: l10n.detailedMode,
                                actif: modeActif == "detaille",
                                onTap: () => setState(() => modeActif = "detaille"),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (modeActif == "ia")
                          _buildFormIA(
                            setState,
                            context,
                            l10n,
                            translator,
                            onSuggestionApplied: () => setState(() => modeActif = "rapide"),
                          )
                        else if (modeActif == "rapide")
                          _buildFormRapide(setState, context, l10n, translator)
                        else
                          _buildFormDetaille(setState, context, l10n, translator),
                      ],
                    ),
                  ),
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.cancel,
                      onPressed: () {
                        _aiScanListener?.stop();
                        resetProduitForm();
                        Navigator.pop(context);
                      },
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          setState(() => afficherErreursTabsProduit = true);
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.product,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Unicité du nom du produit avant toute création.
                        final produitNomExistant = await ProduitServices.findProduitByNom(nomController.text);
                        if (produitNomExistant != null) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.product,
                            message: l10n.productNameAlreadyExists,
                          );
                          return;
                        }

                        // ✅ Unicité du/des code(s)-barres (produits.code_barre
                        // ET produit_code_detail) avant toute création.
                        final codesAVerifier = multicodebar
                            ? barcodes
                            : (!sansCodeBar && codeController.text.trim().isNotEmpty
                                ? [codeController.text.trim()]
                                : <String>[]);
                        for (final code in codesAVerifier) {
                          final conflit = await ProduitServices.findProduitUsingBarcode(code);
                          if (conflit != null) {
                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.error,
                              kind: DialogKind.refuser,
                              titre_concerne: l10n.product,
                              message: l10n.barcodeAlreadyUsed(conflit.nom),
                            );
                            return;
                          }
                        }

                        double toDouble(TextEditingController c, {double def = 0}) {
                          final text = c.text.trim().replaceAll(',', '.');
                          if (text.isEmpty) return def;
                          return double.tryParse(text) ?? def;
                        }

                        // ✅ Récupérer l'ID au moment de la sauvegarde
                        final int newId = await _GetNextId();
                        // ✅ Générer le code produit avec le même format que le client
                        final String newCode = CodeGenerator.generateCode(
                          prefix: CodePrefix.produit,
                          id: newId,
                          digitCount: 6,  // "PRD000001"
                        );


                        // Dans ProduitNouveau, lors de la création du produit
                        final produit = Produit(
                          id: newId,
                          nom: nomController.text,
                          description: descontroller.text,
                          marque: marqueController.text,
                          codeBarre: codeController.text,
                          code: newCode,
                          numeroSerie: numserieController.text,
                          fournisseurCode: kSystemFournisseurCode,
                          categorieId: selectedCategorieid!,
                          sousCategorieId: selectedSousCategorieid!,
                          remiseId: remiseId, // null = pas de remise
                          multicodebar: multicodebar,
                          margeBool: merge,
                          margeTaux: toDouble(margeController),
                          margeTauxPrct: toDouble(margePController),
                          prixAchat: toDouble(prixController),
                          prixVente: toDouble(prixController2),
                          tva: toDouble(tvaController),
                          emballage1: toDouble(jeu1Controller),
                          emballage2: toDouble(jeu2Controller),
                          emballageP1: toDouble(jeu1PrixController),
                          emballageP2: toDouble(jeu2PrixController),
                          uniteMesure: selectedUnitemesure!,
                          observation: observcontroller.text,
                          dateEmpreint: DateTime.tryParse(dateController.text),
                          etat: true,
                          dateCree: DateTime.now(),
                          creeParcode: userCode,
                          service: service,
                          nombreActif: nombreActif,
                          photo: null, // Initialiser avec une liste vide
                          taille: tailleController.text,
                          couleur: couleurController.text,
                          );

// Appel correct de _saveProduit
                        final response = await _saveProduit(
                          produit: produit,
                          tempPhoto: productPhoto,  // ✅ Déjà correct
                        );
                         print(response.message);
                        if (!response.success) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.product,
                            message: response.message ?? l10n.errorOccurred,
                          );
                          return;
                        }

                        // Pousse le nouveau produit vers le catalogue distant
                        // bensds.com en tâche de fond : ne doit jamais faire
                        // échouer ni ralentir la sauvegarde locale, qui reste
                        // la source de vérité (architecture offline-first).
                        // Le ScaffoldMessenger est capturé maintenant (avant
                        // que ce dialogue ne se ferme) pour pouvoir afficher
                        // une notification discrète même si le résultat de
                        // la synchronisation arrive après coup.
                        // Un produit "sans code barre" n'a pas d'identifiant
                        // fiable pour le catalogue partagé : il reste local
                        // uniquement, jamais poussé vers le serveur.
                        if (!sansCodeBar) {
                          final catalogSyncFailedMessage = l10n.catalogSyncFailed;
                          final messenger = ScaffoldMessenger.of(context);
                          unawaited(
                            CatalogSyncService()
                                .pushProduitToCatalog(produit, barcodesSupplementaires: barcodes)
                                .then((success) {
                              if (!success) {
                                messenger.showSnackBar(SnackBar(content: Text(catalogSyncFailedMessage)));
                              }
                            }),
                          );
                        }

                        final int idH = await _GetNextHistoriqueId();
                        final db = await DbCreator.openDb();
                        final serviceh = await HistoriqueServices(db);
                        final remiseService = RemiseServices(db);
                        final sousCategorieService = SousCategoriesServices(db);

                        final Historique histo = Historique(
                          id: idH,
                          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
                          desc: "L'utilisateur $userName a ajouté un nouveau produit sous le nom de ${produit.nom}",
                          oper: ListsConst.typeHisto[0],
                          type: "Produit",
                          dateCree: DateTime.now(),
                          creeParCode: userCode,
                        );

                        await serviceh.addHistorique(histo);

                        await _saveProduitPackDetailes(
                          produit: produit,
                          packs: packsSelectionnes,
                          userCode: userCode,
                          userName: userName,
                        );

                        if (barcodes.isNotEmpty) {
                          await _saveProduitCodeDetailes(
                            produit: produit,
                            codes: barcodes,
                            userCode: userCode,
                            userName: userName,
                          );
                        }
                        resetProduitForm();

                        await InformationDialog(
                          onTerminer: () {
                            _aiScanListener?.stop();
                            Navigator.pop(context);
                            onCreated?.call(produit);
                          },
                          context: context,
                          titre_type_message: l10n.success,
                          titre_concerne: l10n.product,
                          message: response.message ?? l10n.productSavedSuccess,
                        );
                      },
                      color: Appstyle.violet,
                      icon: Icons.save,
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

Widget _modePill({
  required String label,
  required bool actif,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 0),
      decoration: BoxDecoration(
        color: actif ? Appstyle.crevete : Colors.transparent,
        borderRadius: BorderRadius.circular(Appstyle.radiusSM),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Text(
          label,
          style: TextStyle(
            color: actif ? Colors.white : Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

/// Onglet IA : recherche produit par code-barres scanné (ou saisi
/// manuellement) via Open Food Facts, avec confirmation avant remplissage.
Widget _buildFormIA(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator, {
      required VoidCallback onSuggestionApplied,
    }) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        l10n.aiScanInstructions,
        style: Appstyle.textSB.copyWith(color: Appstyle.gris),
      ),
      const SizedBox(height: 15),
      Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: ChampAvecLabel(
              label: l10n.barcode,
              child: TextChampL(
                controller: aiBarcodeController,
                hint: l10n.barcodeHint,
                numeric: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          MainButton(
            text: l10n.search,
            icon: Icons.search,
            color: Appstyle.violet,
            onPressed: aiLoading
                ? null
                : () async {
              final barcode = aiBarcodeController.text.trim();
              if (barcode.isEmpty) return;
              // ✅ La recherche IA interroge des API cloud (catalogue,
              // Open Food Facts...) : prévenir plutôt qu'échouer en silence.
              if (!await hasInternetConnection()) {
                if (!context.mounted) return;
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.attention,
                  kind: DialogKind.attention,
                  titre_concerne: '',
                  message: l10n.internetDisconnected,
                );
                return;
              }
              await _lookupProduitIA(barcode);
            },
          ),
        ],
      ),
      const SizedBox(height: 20),
      if (aiLoading)
        const Center(child: CircularProgressIndicator())
      else if (aiError != null)
        Text(
          aiError!,
          style: Appstyle.textSB.copyWith(color: Appstyle.crevete, fontWeight: FontWeight.bold),
        )
      else if (aiNotFound)
        Text(
          l10n.productNotFoundBarcode,
          style: Appstyle.textSB.copyWith(color: Appstyle.crevete, fontWeight: FontWeight.bold),
        )
      else if (aiExistingLocal != null)
        _aiExistingLocalCard(l10n, aiExistingLocal!, aiExistingLocalQuantite)
      else if (aiResult != null)
        _aiResultCard(setState, l10n, aiResult!, onSuggestionApplied),
    ],
  );
}

/// Carte affichée quand le produit scanné existe déjà en local (onglet IA) —
/// donne assez d'infos (code, stock, prix) pour que l'utilisateur comprenne
/// pourquoi la création est refusée, sans devoir rouvrir la fiche produit.
Widget _aiExistingLocalCard(AppLocalizations l10n, Produit produit, double quantiteExistante) {
  Widget champ(String label, String valeur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
        Text(valeur, style: Appstyle.textSB.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Appstyle.grisSC,
      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      border: Border.all(color: Appstyle.crevete.withOpacity(0.3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.productAlreadyExistsLocally(produit.nom),
          style: Appstyle.textSB.copyWith(color: Appstyle.crevete, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            champ(l10n.code, produit.code),
            champ(l10n.quantity, NumberFormatUtil.formatMontant(quantiteExistante, decimales: 2)),
            champ(l10n.purchasePrice, NumberFormatUtil.formatMontant(produit.prixAchat, decimales: 2)),
            champ(l10n.salePrice, NumberFormatUtil.formatMontant(produit.prixVente, decimales: 2)),
          ],
        ),
      ],
    ),
  );
}

Widget _aiResultCard(
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ProduitAISuggestion suggestion,
    VoidCallback onSuggestionApplied,
    ) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Appstyle.grisSC,
      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
      border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (suggestion.photoUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            child: Image.network(
              suggestion.photoUrl!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 100,
                height: 100,
                color: Appstyle.grisC,
                child: const Icon(Icons.image_not_supported),
              ),
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                suggestion.nom ?? '',
                style: Appstyle.textMB.copyWith(fontWeight: FontWeight.bold),
              ),
              if (suggestion.sourceLabel != null)
                Text(suggestion.sourceLabel!, style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
              if (suggestion.marque != null)
                Text("${l10n.brand}: ${suggestion.marque}", style: Appstyle.textSB),
              if (suggestion.categorie != null)
                Text("${l10n.category}: ${suggestion.categorie}", style: Appstyle.textSB),
              if (suggestion.taille != null)
                Text("${l10n.size}: ${suggestion.taille}", style: Appstyle.textSB),
              const SizedBox(height: 12),
              Row(
                children: [
                  MainButton(
                    text: l10n.confirmThisProduct,
                    icon: Icons.check,
                    color: Appstyle.green,
                    onPressed: () async {
                      await _appliquerSuggestionIA(suggestion);
                      onSuggestionApplied();
                    },
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.cancel,
                    icon: Icons.close,
                    color: Appstyle.gris,
                    onPressed: () => setState(() => aiResult = null),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFormRapide(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  selectedUniteDisplay ??= translator.uniteMesureDisplayList.first;


  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Appstyle.Tblanc,
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            border: Border.all(color: Appstyle.grisC, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChampAvecLabel(
                label: l10n.code,
                child: AffichageChamp(text: code),
              ),
              const SizedBox(height: 20),
              ChampAvecLabel(
                label: l10n.name,
                obligatoire: true,
                child: TextChampL(
                  obligatoire: true,
                  controller: nomController,
                  hint: l10n.productNameHint,
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.description,
                child: TextChampL(
                  controller: descontroller,
                  hint: l10n.descriptionHint,
                ),
              ),
              const SizedBox(height: 30),
              ChampAvecLabel(
                label: l10n.brand,
                obligatoire: true,
                child: TextChampL(
                  obligatoire: true,
                  controller: marqueController,
                  hint: l10n.brandHint,
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.barcode,
                child: TextChampL(
                  controller: codeController,
                  hint: l10n.barcodeHint,
                  numeric: true,
                ),
              ),
              const SizedBox(height: 30),
              ChampAvecLabel(
                label: l10n.category,
                obligatoire: true,
                buttonAjout: true,
                onAjoutPressed: () async {
                  await showDialog(
                    context: context,
                    barrierColor: Appstyle.gris.withOpacity(0.25),
                    builder: (_) {
                      return InsertionCategorieDialog(
                        categories: _categoriesActives(),
                        onCategorieSelected: (categorie) {
                          setState(() {
                            selectedCategorie = categorie.nom;
                            selectedCategorieid = categorie.id;
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  obligatoire: true,
                  value: selectedCategorie ?? "",
                  items: _categoriesActives().map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedCategorie = v;
                      selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                      if (v == null || v.isEmpty) {
                        selectedSousCategorie = "";
                      } else {
                        final sousCats = _sousCategoriesActivesPour(v);

                        if (sousCats.isNotEmpty) {
                          selectedSousCategorie = sousCats.first.nom;
                          selectedSousCategorieid = sousCats.first.id;
                        } else {
                          selectedSousCategorie = "";
                        }
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.subcategory,
                obligatoire: true,
                buttonAjout: true,
                onAjoutPressed: () async {
                  await showDialog(
                    context: context,
                    barrierColor: Appstyle.gris.withOpacity(0.25),
                    builder: (_) {
                      return InsertionSousCategorieDialog(
                        sousCategories: _sousCategoriesActivesPour(selectedCategorie),
                        onSousCategorieSelected: (souscategorie) {
                          setState(() {
                            selectedSousCategorie = souscategorie.nom;
                            selectedSousCategorieid = souscategorie.id;
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  obligatoire: true,
                  value: selectedSousCategorie,
                  items: _sousCategoriesActivesPour(selectedCategorie).map((sc) => sc.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSousCategorie = v ?? "";
                      selectedSousCategorieid = sousCategoriesTest.where((sc) => sc.nom == v).first.id;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.discount,
                buttonAjout: true,
                onAjoutPressed: () async {
                  await showDialog(
                    context: context,
                    barrierColor: Appstyle.gris.withOpacity(0.25),
                    builder: (_) {
                      return InsertionRemiseDialog(
                        multiselection: false,
                        remises: remisesTest
                            .where((r) => r.type == "Par Produit")
                            .toList(),
                        onRemiseSelected: (remise) {
                          setState(() {
                            selectedRemise = remise.nom;
                            remiseId = remise.id;
                          });
                        },
                      );
                    },
                  );
                },
                child: Builder(
                  builder: (context) {
                    final remiseItems = remisesTest
                        .where((r) => r.type == "Par Produit")
                        .map((r) => r.nom.trim())
                        .toSet()
                        .toList();

                    return TextListe(
                      value: selectedRemise,
                      items: remiseItems,
                      onChanged: (v) {
                        setState(() {
                          selectedRemise = v;
                          remiseId = remisesTest.where((sc) => sc.nom == v).first.id;
                        });
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Appstyle.Tblanc,
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            border: Border.all(color: Appstyle.grisC, width: 1.5),
          ),
          child: Column(
            children: [
              ChampAvecLabel(
                label: l10n.purchasePrice,
                obligatoire: true,
                child: TextChampL(
                  controller: prixController,
                  obligatoire: true,
                  hint: '150 ${l10n.currency}',
                  numeric: true,
                  onChanged: (_) {
                    produitFormKey.currentState!.validate();
                  },
                  validator: (value) {
                    final prixAchat = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (prixAchat == null || prixAchat <= 0) {
                      return l10n.invalidPrice;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.salePrice,
                obligatoire: true,
                child: TextChampL(
                  controller: prixController2,
                  obligatoire: true,
                  hint: '250 ${l10n.currency}',
                  numeric: true,
                  onChanged: (_) {
                    produitFormKey.currentState!.validate();
                  },
                  validator: (value) {
                    final prixAchat = double.tryParse(prixController.text) ?? 0;
                    final prixVente = double.tryParse((value ?? '').replaceAll(',', '.'));
                    if (prixVente == null || prixVente <= 0) {
                      return l10n.invalidPrice;
                    }
                    if (prixVente < prixAchat) {
                      return l10n.salePriceLowerThanPurchase;
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 15),
              ChampAvecLabel(
                label: l10n.unitOfMeasure,
                obligatoire: true,
                child:TextListe(
                  obligatoire: true,
                  value: selectedUniteDisplay,  // Changé ici
                  items: translator.uniteMesureDisplayList,
                  clearable: false,
                  onChanged: (v) {
                    setState(() {
                      selectedUniteDisplay = v;  // Changé ici
                      selectedUnitemesure = translator.uniteMesureToFrench(v!);
                    });
                  },
                ),
              ),
              const SizedBox(height: 30),
              ChampAvecLabel(
                label: l10n.size,
                child: TextChampL(
                  controller: tailleController,
                  hint: l10n.sizeHint,
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.color,
                child: TextChampL(
                  controller: couleurController,
                  hint: l10n.colorHint,
                ),
              ),
              const SizedBox(height: 15),
              ChampAvecLabel(
                label: l10n.photos,
                child: ButtonAddPhoto(
                  photo: productPhoto,
                  onPhotoChanged: (newPhoto) {
                    setState(() {
                      productPhoto = newPhoto;
                    });
                  },
                  isEditMode: true,
                ),
              ),
              const SizedBox(height: 15),
              ChampAvecLabel(
                label: l10n.observation,
                child: TextChampL(
                  controller: observcontroller,
                  hint: l10n.observationHint,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildFormDetaille(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {

  Widget tabPage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  final erreursTabs = afficherErreursTabsProduit ? _tabsAvecErreursProduit() : <int>{};

  return DefaultTabController(
    length: 7,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Appstyle.grisC.withOpacity(0.15),
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            isScrollable: true,
            indicator: BoxDecoration(
              color: Appstyle.violet,
              borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Appstyle.gris,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w500),
            tabs: [
              _tabAvecIndicateur(l10n.generalInformation, erreursTabs.contains(0)),
              _tabAvecIndicateur(l10n.codeReference, erreursTabs.contains(1)),
              _tabAvecIndicateur(l10n.categoryDiscount, erreursTabs.contains(2)),
              _tabAvecIndicateur(l10n.priceTaxes, erreursTabs.contains(3)),
              _tabAvecIndicateur(l10n.unitPackaging, erreursTabs.contains(4)),
              _tabAvecIndicateur(l10n.packStore, erreursTabs.contains(5)),
              _tabAvecIndicateur(l10n.observation, erreursTabs.contains(6)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 480,
          child: TabBarView(
            children: [
              // ── Informations générales ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.reference,
                  child: AffichageChamp(text: code),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.name,
                  obligatoire: true,
                  child: TextChampL(
                    obligatoire: true,
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: nomController,
                    hint: l10n.productNameHint,
                    onChanged: (_) { if (afficherErreursTabsProduit) setState(() {}); },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.description,
                  child: TextChampL(
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: descontroller,
                    hint: l10n.descriptionHint,
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.brand,
                  obligatoire: true,
                  child: TextChampL(
                    obligatoire: true,
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: marqueController,
                    hint: l10n.brandHint,
                    onChanged: (_) { if (afficherErreursTabsProduit) setState(() {}); },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.size,
                  child: TextChampL(
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: tailleController,
                    hint: l10n.sizeHint,
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.color,
                  child: TextChampL(
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: couleurController,
                    hint: l10n.colorHint,
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.photos,
                  child: ButtonAddPhoto(
                    photo: productPhoto,
                    onPhotoChanged: (newPhoto) {
                      setState(() {
                        productPhoto = newPhoto;
                      });
                    },
                    isEditMode: true,
                  ),
                ),
              ]),

              // ── Code & Référence ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.serialNumber,
                  child: TextChampL(
                    controller: numserieController,
                    hint: l10n.serialNumberHint,
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: multicodebar ? l10n.multipleBarcodeLabel : l10n.barcode,
                  obligatoire: !multicodebar && !sansCodeBar,
                  child: multicodebar
                      ? buildMultiBarcodeEditor(context,setState, l10n)
                      : TextChampL(
                    controller: codeController,
                    hint: l10n.barcodeHint,
                    numeric: true,
                    enabled: !sansCodeBar,
                    obligatoire: !sansCodeBar,
                  ),
                ),
                if (!multicodebar) ...[
                  const SizedBox(height: 10),
                  ProduitBarcodeGenerator(
                    barcodeController: codeController,
                    sansCodeBar: sansCodeBar,
                    onSansCodeBarChanged: (v) {
                      setState(() {
                        sansCodeBar = v;
                        codeController.clear();
                      });
                    },
                  ),
                ],
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.multicode,
                  distance: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: multicodebar,
                        onChanged: (v) {
                          setState(() {
                            multicodebar = v ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ]),

              // ── Catégorie & Remise ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.category,
                  buttonAjout: true,
                  obligatoire: true,
                  onAjoutPressed: () async {
                    await showDialog(
                      context: context,
                      barrierColor: Appstyle.gris.withOpacity(0.25),
                      builder: (_) {
                        return InsertionCategorieDialog(
                          categories: _categoriesActives(),
                          onCategorieSelected: (categorie) {
                            setState(() {
                              selectedCategorie = categorie.nom;
                              selectedCategorieid = categorie.id;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: TextListe(
                    obligatoire: true,
                    value: selectedCategorie ?? "",
                    items: _categoriesActives().map((c) => c.nom).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCategorie = v;
                        selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                        if (v == null || v.isEmpty) {
                          selectedSousCategorie = "";
                        } else {
                          final sousCats = _sousCategoriesActivesPour(v);

                          if (sousCats.isNotEmpty) {
                            selectedSousCategorie = sousCats.first.nom;
                            selectedSousCategorieid = sousCats.first.id;
                          } else {
                            selectedSousCategorie = "";
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.subcategory,
                  obligatoire: true,
                  buttonAjout: true,
                  onAjoutPressed: () async {
                    await showDialog(
                      context: context,
                      barrierColor: Appstyle.gris.withOpacity(0.25),
                      builder: (_) {
                        return InsertionSousCategorieDialog(
                          sousCategories: _sousCategoriesActivesPour(selectedCategorie),
                          onSousCategorieSelected: (souscategorie) {
                            setState(() {
                              selectedSousCategorie = souscategorie.nom;
                              selectedSousCategorieid = souscategorie.id;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: TextListe(
                    obligatoire: true,
                    value: selectedSousCategorie,
                    items: _sousCategoriesActivesPour(selectedCategorie).map((sc) => sc.nom).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSousCategorie = v ?? "";
                        selectedSousCategorieid = sousCategoriesTest.where((sc) => sc.nom == v).first.id;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.discount,
                  buttonAjout: true,
                  onAjoutPressed: () async {
                    await showDialog(
                      context: context,
                      barrierColor: Appstyle.gris.withOpacity(0.25),
                      builder: (_) {
                        return InsertionRemiseDialog(
                          multiselection: false,
                          remises: remisesTest
                              .where((r) => r.type == "Par Produit")
                              .toList(),
                          onRemiseSelected: (remise) {
                            setState(() {
                              selectedRemise = remise.nom;
                              remiseId = remise.id;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: Builder(
                    builder: (context) {
                      final remiseItems = remisesTest
                          .where((r) => r.type == "Par Produit")
                          .map((r) => r.nom.trim())
                          .toSet()
                          .toList();

                      return TextListe(
                        value: selectedRemise,
                        items: remiseItems,
                        onChanged: (v) {
                          setState(() {
                            selectedRemise = v;
                            remiseId = remisesTest.where((sc) => sc.nom == v).first.id;
                          });
                        },
                      );
                    },
                  ),
                ),
              ]),

              // ── Prix & Taxes ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.purchasePrice,
                  obligatoire: true,
                  child: TextChampL(
                    obligatoire: true,
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    onChanged: (_) {
                      setState(() {
                        // ✅ Recalculer le prix de vente AVANT de valider : sinon
                        // validate() s'exécute sur l'ancien prixController2.text
                        // (pas encore recalculé) et affiche "prix de vente
                        // inférieur au prix d'achat" même quand le prix
                        // recalculé qui s'affiche juste après est correct.
                        calculPrixVenteAuto();
                        produitFormKey.currentState!.validate();
                      });
                    },
                    controller: prixController,
                    hint: '150 ${l10n.currency}',
                    numeric: true,
                    validator: (value) {
                      final prixAchat = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (prixAchat == null || prixAchat <= 0) {
                        return l10n.invalidPrice;
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  alignmentStart: true,
                  label: l10n.margin,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: merge,
                        onChanged: (v) {
                          setState(() {
                            merge = v ?? false;
                          });
                          calculPrixVenteAuto();
                        },
                        auto: true,
                      ),
                      if (merge)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: Appstyle.gris),
                              const SizedBox(width: 4),
                              Text(
                                "${l10n.typeCalcul}: ${translator.translateTypeCalcul(margeTypePrmtre)}  •  "
                                "${l10n.marginRate}: ${margeTypePrmtre == "Montant" ? "$margetauxPrmtre ${l10n.currency}" : "$margetauxPrmtre%"}",
                                style: Appstyle.textXS.copyWith(
                                  color: Appstyle.gris,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!merge) ...[
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.marginAmount,
                          child: TextChampL(
                            controller: margeController,
                            hint: "100 ${l10n.currency}",
                            numeric: true,
                            onChanged: (_) {
                              margePController.clear();
                              calculPrixVenteAuto();
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChampAvecLabel(
                          label: l10n.marginPercentage,
                          child: TextChampL(
                            controller: margePController,
                            hint: "5 %",
                            maxValue: 100,
                            numeric: true,
                            onChanged: (_) {
                              margeController.clear();
                              calculPrixVenteAuto();
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.vat,
                  obligatoire: true,
                  child: TextChampL(
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: tvaController,
                    hint: '20%',
                    numeric: true,
                    onChanged: (value) {
                      setState(() {
                        String cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (cleaned.isNotEmpty) {
                          int number = int.parse(cleaned);
                          if (number > 100) number = 100;
                          if (number < 0) number = 0;
                          if (number.toString() != value) {
                            tvaController.text = number.toString();
                            tvaController.selection = TextSelection.fromPosition(
                              TextPosition(offset: tvaController.text.length),
                            );
                          }
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.salePrice,
                  obligatoire: true,
                  child: TextChampL(
                    controller: prixController2,
                    enabled: false,
                    obligatoire: true,
                    hint: '250 ${l10n.currency}',
                    numeric: true,
                    onChanged: (_) {
                      setState(() {
                        calculPrixVenteAuto();
                        produitFormKey.currentState!.validate();
                      });
                    },
                    validator: (value) {
                      final prixAchat = double.tryParse(prixController.text) ?? 0;
                      final prixVente = double.tryParse((value ?? '').replaceAll(',', '.'));
                      if (prixVente == null || prixVente <= 0) {
                        return l10n.invalidPrice;
                      }
                      if (prixVente < prixAchat) {
                        return l10n.salePriceLowerThanPurchase;
                      }
                      return null;
                    },
                  ),
                ),
              ]),

              // ── Stock & Emballage ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.unitOfMeasure,
                  obligatoire: true,
                  child: TextListe(
                    obligatoire: true,
                    value: selectedUnite,
                    items: translator.uniteMesureDisplayList,
                    clearable: false,
                    onChanged: (v) {
                      setState(() {
                        selectedUnite       = v;
                        selectedUnitemesure = translator.uniteMesureToFrench(v!);
                        // ✅ "Nombre" n'a de sens que pour un produit vendu au
                        // poids/volume (Kg/Litre) : si l'unité change pour
                        // autre chose, on désactive l'option pour éviter un
                        // état incohérent (toggle verrouillé mais resté actif).
                        if (!_uniteEligibleNombre(selectedUnitemesure)) {
                          nombreActif = false;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                // ✅ Emballage 1 (Boîte)
                // ✅ Emballage 1 (Boîte)
                ChampAvecLabel(
                  label: l10n.packaging1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextChampL(
                              width: 120,
                              controller: jeu1Controller,
                              // Pièces par emballage : entier si le produit se vend à la pièce.
                              isQuantite: true,
                              uniteMesure: selectedUnitemesure,
                              color: colorchamp,
                              colorEnabled: colorchampenabled,
                              hint: l10n.packaging1Hint,
                              numeric: true,
                              onChanged: (value) {
                                setState(() {
                                  emballage1Actif = value.trim().isNotEmpty;
                                  if (!emballage1Actif) {
                                    jeu1PrixController.clear();
                                  }
                                });
                                // Valider après changement
                                produitFormKey.currentState?.validate();
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextChampL(
                              width: 120,
                              controller: jeu1PrixController,
                              color: colorchamp,
                              colorEnabled: colorchampenabled,
                              hint: l10n.packagingPrice1Hint,
                              numeric: true,
                              enabled: emballage1Actif,
                              obligatoire: emballage1Actif,
                              validator: (value) {
                                if (emballage1Actif) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.requiredField;
                                  }

                                  final prixEmballageTotal = double.tryParse(value.replaceAll(',', '.'));
                                  final quantite = double.tryParse(jeu1Controller.text.replaceAll(',', '.'));
                                  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));

                                  if (prixEmballageTotal == null || prixEmballageTotal <= 0) {
                                    return l10n.invalidPrice;
                                  }

                                  if (quantite == null || quantite <= 0) {
                                    return l10n.invalidQuantity;
                                  }

                                  // ✅ Calcul du prix par pièce
                                  final prixParPiece = prixEmballageTotal / quantite;

                                  if (prixAchat != null && prixParPiece < prixAchat) {
                                    return l10n.packagingPricePerPieceLowerThanPurchase(prixParPiece.toStringAsFixed(2));
                                  }
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() => produitFormKey.currentState?.validate()),
                            ),
                          ),
                        ],
                      ),
                      // ✅ Affichage du prix par pièce pour l'emballage 1
                      if (emballage1Actif && jeu1Controller.text.isNotEmpty && jeu1PrixController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: Text(
                            "💰 Prix par pièce : ${_calculerPrixParPiece(jeu1Controller.text, jeu1PrixController.text)} DA",
                            style: Appstyle.textpop_S.copyWith(
                              color: Appstyle.violet,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

// ✅ Emballage 2 (Carton)
                ChampAvecLabel(
                  label: l10n.packaging2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextChampL(
                              width: 120,
                              controller: jeu2Controller,
                              // Pièces par emballage : entier si le produit se vend à la pièce.
                              isQuantite: true,
                              uniteMesure: selectedUnitemesure,
                              color: colorchamp,
                              colorEnabled: colorchampenabled,
                              hint: l10n.packaging2Hint,
                              numeric: true,
                              onChanged: (value) {
                                setState(() {
                                  emballage2Actif = value.trim().isNotEmpty;
                                  if (!emballage2Actif) {
                                    jeu2PrixController.clear();
                                  }
                                });
                                produitFormKey.currentState?.validate();
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: TextChampL(
                              width: 120,
                              controller: jeu2PrixController,
                              color: colorchamp,
                              colorEnabled: colorchampenabled,
                              hint: l10n.packagingPrice2Hint,
                              numeric: true,
                              enabled: emballage2Actif,
                              obligatoire: emballage2Actif,
                              validator: (value) {
                                if (emballage2Actif) {
                                  if (value == null || value.isEmpty) {
                                    return l10n.requiredField;
                                  }

                                  final prixEmballageTotal = double.tryParse(value.replaceAll(',', '.'));
                                  final quantite = double.tryParse(jeu2Controller.text.replaceAll(',', '.'));
                                  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));

                                  if (prixEmballageTotal == null || prixEmballageTotal <= 0) {
                                    return l10n.invalidPrice;
                                  }

                                  if (quantite == null || quantite <= 0) {
                                    return l10n.invalidQuantity;
                                  }

                                  // ✅ Calcul du prix par pièce
                                  final prixParPiece = prixEmballageTotal / quantite;

                                  if (prixAchat != null && prixParPiece < prixAchat) {
                                    return l10n.packagingPricePerPieceLowerThanPurchase(prixParPiece.toStringAsFixed(2));
                                  }
                                }
                                return null;
                              },
                              onChanged: (_) => setState(() => produitFormKey.currentState?.validate()),
                            ),
                          ),
                        ],
                      ),
                      // ✅ Affichage du prix par pièce pour l'emballage 2
                      if (emballage2Actif && jeu2Controller.text.isNotEmpty && jeu2PrixController.text.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, left: 8.0),
                          child: Text(
                            "💰 Prix par pièce : ${_calculerPrixParPiece(jeu2Controller.text, jeu2PrixController.text)} DA",
                            style: Appstyle.textpop_S.copyWith(
                              color: Appstyle.violet,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.service,
                  distance: 200,
                  alignmentStart: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: service,
                        onChanged: (v) {
                          final nouveauService = v ?? false;
                          setState(() {
                            service = nouveauService;
                          });
                          if (nouveauService) {
                            InformationDialog(
                              context: context,
                              titre_type_message: l10n.information,
                              titre_concerne: l10n.service,
                              message: l10n.serviceModeInfo,
                            );
                          }
                        },
                        auto: false,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.nombreActifLabel,
                  distance: 200,
                  alignmentStart: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: nombreActif,
                        enabled: _uniteEligibleNombre(selectedUnitemesure),
                        onChanged: (v) {
                          setState(() {
                            nombreActif = v ?? false;
                          });
                        },
                        auto: false,
                      ),
                      Text(
                        _uniteEligibleNombre(selectedUnitemesure)
                            ? l10n.nombreActifHint
                            : l10n.nombreActifUniteRequiredHint,
                        style: Appstyle.textS.copyWith(color: Appstyle.gris),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.expiryDate,
                  child: TextDate(
                    hint: "15 nov 2025",
                    controller: dateController,
                    onTap: () => pickDate(context, dateController),
                  ),
                ),
              ]),


              // ── Pack & Magasin ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.pack,
                  distance: 100,
                  alignmentStart: true,
                  child: chipsSelector<Pack>(
                    values: packsSelectionnes,
                    label: (p) => p.nom,
                    l10n: l10n,
                    onAdd: () async {
                      await showDialog(
                        context: context,
                        barrierColor: Appstyle.gris.withOpacity(0.25),
                        builder: (_) {
                          return InsertionPackDialog(
                            multiselection: true,
                            packs: _packsActifs(),
                            onPackSelected: (pack) {
                              setState(() {
                                if (!packsSelectionnes.any((p) => p.code == pack.code)) {
                                  packsSelectionnes.add(pack);
                                  packId = pack.id;
                                }
                              });
                            },
                          );
                        },
                      );
                    },
                    onRemove: (p) {
                      setState(() {
                        packsSelectionnes.remove(p);
                      });
                    },
                  ),
                ),
              ]),

              // ── Observation ──
              tabPage([
                ChampAvecLabel(
                  label: l10n.observation,
                  child: TextChampL(
                    controller: observcontroller,
                    hint: l10n.observationHint,
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget chipsSelector<T>({
  required List<T> values,
  required String Function(T) label,
  required AppLocalizations l10n,
  required VoidCallback onAdd,
  required void Function(T) onRemove,
  List<T>? nonRemovableItems, // Nouveau paramètre
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: values.map((e) {
          final bool isNonRemovable = nonRemovableItems?.contains(e) ?? false;

          return Chip(
            backgroundColor: isNonRemovable ? Appstyle.gris : Appstyle.crevete,
            label: Text(
              label(e),
              style: TextStyle(
                color: isNonRemovable ? Appstyle.ink500 : Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            deleteIcon: isNonRemovable
                ? null // Pas d'icône de suppression
                : const Icon(Icons.close, size: 18, color: Colors.white),
            onDeleted: isNonRemovable ? null : () => onRemove(e),
          );
        }).toList(),
      ),
      if (values.isNotEmpty) const SizedBox(height: 10),
      OutlinedButton.icon(
        icon: const Icon(Icons.add),
        label: Text(l10n.add),
        onPressed: onAdd,
      ),
    ],
  );
}
Widget buildMultiBarcodeEditor(
    BuildContext context,
    void Function(VoidCallback fn) setState,
    AppLocalizations l10n,
    ) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [

      /// champ saisie
      Row(
        children: [
          Expanded(
            child: TextChampL(
              controller: multicodeController,
              hint: l10n.barcodeHint,
              numeric: true,
              onChanged: (_) => ajouterBarcode(setState),
            ),
          ),

        ],
      ),

      const SizedBox(height: 12),

      /// chips
      chipsSelector<String>(
        values: barcodes,
        label: (c) => c,
        l10n: l10n,
        onAdd: () async {
          await showDialog(
            context: context,
            barrierColor: Appstyle.gris.withOpacity(0.25),
            builder: (_) {
              return InsertionCodebarDialog(
                onBarcodeAdded: (code) {
                  setState(() {
                    if (!barcodes.contains(code)) {
                      barcodes.add(code);
                    }
                  });
                },
              );
            },
          );
        },
        onRemove: (c) => supprimerBarcode(c, setState),
      ),
    ],
  );
}