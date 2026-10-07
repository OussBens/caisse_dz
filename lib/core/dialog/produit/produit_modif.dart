import 'dart:io';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pack.dart' hide ApiResponse;
import 'package:caisse_dz/Services/PackDetailes.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart' hide ApiResponse;
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/affichage_champ.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../../data/models/produit.dart';
import '../../../Services/Photos.dart';
import '../../../data/constant.dart';
import '../../../data/models/paramters.dart';
import '../../../data/models/produit_pack_detail.dart';
import '../../dialog//confirmation_dialog.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/button_add_photo.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/radio_champ.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_categorie.dart';
import '../insertion_codebar.dart';
import 'produit_barcode_generator.dart';
import '../insertion_pack.dart';
import '../insertion_remise.dart';
import '../insertion_souscategorie.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

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
Future<void> _UpdatePackDetail({
  required List<Pack> produitsPack,
  required List<ProduitPackDetail> orignal,
  required Produit produite,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitPackDetailServices(db);
  final servicep = PackServices(db);

  int i = 0;
  for (var produit in orignal) {
    i = 0;
    for (var prd in produitsPack) {
      if (prd.nom == produit.packCode) {
        break;
      }
      i++;
    }
    if (i == produitsPack.length) {
      await service.deleteDetailes(produit.produitCode, produit.packCode);
      final int idH = await _GetNextHistoriqueId();
      final db = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db);
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur $userName a supprimer le ProduitPackDetail ${produit.produitCode} de Pack ${produit.packCode}}",
          type: "ProduitPackDetail",
          oper: ListsConst.typeHisto[3],
          dateCree: DateTime.now(),
          creeParCode: userCode);
      await serviceh.addHistorique(histo);
    }
  }

  for (var produit in produitsPack) {
    final detail = ProduitPackDetail(
      packCode: produit.code,
      produitCode: produite.code,
      dateCree: DateTime.now(),
      id: await _GetNextPackDetailId(),
      creeParCode: userCode, prixUnitaire: produit.prixVente, quantite: 1, montant: produit.prixVente,
    );

    final response = await service.addProduitPackDetail(detail);

    if (response == 0) {
      print("le ProduitPackdetail ${produit.nom} est deja existe ");
    } else {
      final int idH = await _GetNextHistoriqueId();
      final db = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db);
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur $userName a ajouter le ProduitPackDetail ${produite.nom} de Pack ${produit.nom}",
          oper: ListsConst.typeHisto[1],
          type: "ProduitPackDetail",
          dateCree: DateTime.now(),
          creeParCode: userCode);
      await serviceh.addHistorique(histo);
      print("le ProduitPackDetail de ${produite.nom} est ajoutee ");
    }
  }
  print('ProduitPackDetail details synced for ${produite.nom}');
}
Future<void> _UpdateCodeDetail({
  required List<String> Codes,
  required Produit produite,
  required String userName,
  required String userCode,
}) async {

  final db = await DbCreator.openDb();
  final service = ProduitServices(db);
  final serviceh = HistoriqueServices(db);

  /// différences
  final toDelete =
  originalBarcodes.where((c) => !Codes.contains(c));

  final toAdd =
  Codes.where((c) => !originalBarcodes.contains(c));

  /// ================= DELETE =================
  for (final code in toDelete) {

    await service.deleteDetailes(produite.code, code);

    final idH = await _GetNextHistoriqueId();

    await serviceh.addHistorique(
      Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc:
        "l'utilisateur $userName a supprimer le Codebar $code de Produit ${produite.nom}",
        type: "ProduitCodeDetail",
        oper: ListsConst.typeHisto[3],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      ),
    );
  }

  /// ================= ADD =================
  for (final code in toAdd) {

    final detail = ProduitCodeDetail(
      CodeBar: code,
      produitCode: produite.code,
      dateCree: DateTime.now(),
      id: await _GetNextCodeDetailId(),
      creeParCode: userCode,
    );

    final response = await service.addProduitCodeDetail(detail);

    if (response != 0) {
      final idH = await _GetNextHistoriqueId();

      await serviceh.addHistorique(
        Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc:
          "l'utilisateur $userName a ajouter le Codebar $code de Produit ${produite.nom}",
          oper: ListsConst.typeHisto[1],
          type: "ProduitCodeDetail",
          dateCree: DateTime.now(),
          creeParCode: userCode,
        ),
      );
    }
  }

  print('ProduitCodesDetail synced for ${produite.nom}');
}
// Ajoutez cette fonction après les autres fonctions comme _GetNextHistoriqueId, etc.
Future<String?> _saveProductPhoto(String productCode, String? tempPhoto) async {
  if (tempPhoto == null || tempPhoto.isEmpty) return null;

  if (PhotoService.isTempPhoto(tempPhoto)) {
    final tempFile = File(tempPhoto);
    if (await tempFile.exists()) {
      final savedName = await PhotoService.savePhoto(tempFile, productCode);
      await tempFile.delete();
      debugPrint('📸 Photo sauvegardée: $savedName');
      return savedName;
    }
  }

  return tempPhoto;
}
String _calculerPrixParPiece(String quantiteText, String prixText) {
  final double quantite = double.tryParse(quantiteText.replaceAll(',', '.')) ?? 0;
  final double prix = double.tryParse(prixText.replaceAll(',', '.')) ?? 0;

  if (quantite <= 0 || prix <= 0) return "0.00";

  final prixParPiece = prix / quantite;
  return NumberFormatUtil.formatMontant(prixParPiece, decimales: 2);
}

// Remplacer la fonction _updateProductPhotos par:
Future<String?> _updateProductPhoto(
    String productCode,
    String? newPhoto,
    String? oldPhoto,
    ) async {
  // Supprimer l'ancienne photo si elle existe et différente
  if (oldPhoto != null && oldPhoto != newPhoto) {
    await PhotoService.deletePhoto(oldPhoto);
    debugPrint('🗑️ Ancienne photo supprimée: $oldPhoto');
  }

  // Sauvegarder la nouvelle photo temporaire
  if (newPhoto != null && PhotoService.isTempPhoto(newPhoto)) {
    final tempFile = File(newPhoto);
    if (await tempFile.exists()) {
      final savedName = await PhotoService.savePhoto(tempFile, productCode);
      await tempFile.delete();
      debugPrint('📸 Nouvelle photo sauvegardée: $savedName');
      return savedName;
    }
  }

  return newPhoto;
}
Future<ApiResponse<int>> _updateProduit({
  required Produit produit,
  required String? newPhoto,
  required String? oldPhoto,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final services = ProduitServices(db);
  final sousCategorieService = SousCategoriesServices(db);
  final remiseService = RemiseServices(db);

  // Sauvegarder la photo unique
  final savedPhoto = await _updateProductPhoto(produit.code, newPhoto, oldPhoto);
  produit.photo = savedPhoto;  // ✅ Utiliser photo au lieu de photos

  final response = await services.updateProduit(produit);

  final int idH = await _GetNextHistoriqueId();
  final serviceh = await HistoriqueServices(db);

  final Historique histo = Historique(
    id: idH,
    code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
    desc: "l'utilisateur $userName a modifié les informations du produit ${produit.nom}",
    oper: ListsConst.typeHisto[2],
    type: "Produit",
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);

  return response;
}
Future<void> loadAllData({required Produit produite}) async {
  try {
    final pack = await PackServices.getAllPacks();
    final remise = await RemiseServices.getAllRemiseParProduit();
    final sous = await SousCategoriesServices.getAllSousCategorie();
    final categorie = await CategorieServices.getAllCategorie();
    final Param = await ParamServices.getParam();
    final packdetail = await ProduitPackDetailServices.getDetailsByNom(produite.code);
    final codedetail = await ProduitServices.getAllCodeDetailsByCode(produite.code);

    packsTest = pack;
    remisesTest = remise;
    sousCategoriesTest = sous;
    categoriesTest = categorie;
    paramters = Param;
    produitPackDetailsTest = packdetail;
    produitCodeDetailsTest = codedetail;

    barcodes = produitCodeDetailsTest
        .map((d) => d.CodeBar)
        .toList();

    originalBarcodes = List<String>.from(barcodes);

    // ✅ CORRECTION : Charger une seule photo
    // produite.photo est déjà un String?, pas une liste
    productPhoto = produite.photo;

    debugPrint('📸 Photo chargée: ${productPhoto ?? "aucune"}');

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

// ✅ Marge auto par pourcentage : le prix de vente généré est arrondi au
// multiple de 5 DA supérieur (104 -> 105, 126 -> 130). La marge par montant
// fixe et la saisie manuelle gardent la valeur exacte.
double _arrondirAuMultipleDe5(double prix) {
  final prixArrondi = double.parse(prix.toStringAsFixed(2));
  return (prixArrondi / 5).ceil() * 5;
}

Future<void> calculPrixVenteAuto() async {
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.')) ?? 0;
  double prixVente = prixAchat;

  if (merge) {
    final tauxMontant = margetauxPrmtre;
    final tauxPercentage = margetauxPrmtre;

    if (margeTypePrmtre == "Montant") {
      prixVente = prixAchat + tauxMontant;
    } else {
      prixVente = _arrondirAuMultipleDe5(prixAchat + (prixAchat * tauxPercentage / 100));
    }
  } else {
    final margeMontant = double.tryParse(margeController.text.replaceAll(',', '.')) ?? 0;
    final margePercentage = double.tryParse(margePController.text.replaceAll(',', '.')) ?? 0;

    if (margeMontant > 0) {
      prixVente = prixAchat + margeMontant;
    } else if (margePercentage > 0) {
      prixVente = _arrondirAuMultipleDe5(prixAchat + (prixAchat * margePercentage / 100));
    }
  }

  prixController2.text = prixVente.toStringAsFixed(2);
}

int selectedCategorieid = 0;
int selectedSousCategorieid = 0;
int? remiseId; // null = pas de remise (jamais 0, pris pour une remise)
int id = 0;
String code = "";
List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];

String? _codeCategorieByNom(String? nom) =>
    nom == null ? null : categoriesTest.where((c) => c.nom == nom).firstOrNull?.code;
List<Remise> remisesTest = [];
List<Pack> packsTest = [];
List<String> codesTest = [];
List<Pack> packsSelectionnes = [];
List<String> codesSelectionnes = [];
List<String> barcodes = [];
late List<String> originalBarcodes;
List<ProduitPackDetail> packsProduit = [];
List<ProduitCodeDetail> codesProduit = [];
List<ProduitPackDetail> produitPackDetailsTest = [];
List<ProduitCodeDetail> produitCodeDetailsTest = [];
String? productPhoto;
final TextEditingController multicodeController = TextEditingController();
final TextEditingController margeController = TextEditingController();
final TextEditingController margePController = TextEditingController();
final TextEditingController couleurController = TextEditingController();
final TextEditingController tailleController = TextEditingController();
final TextEditingController dateController = TextEditingController();
final TextEditingController nomController = TextEditingController();
final TextEditingController descontroller = TextEditingController();
final TextEditingController observcontroller = TextEditingController();
final TextEditingController marqueController = TextEditingController();
final TextEditingController codeController = TextEditingController();
final TextEditingController prixController = TextEditingController();
final TextEditingController tvaController = TextEditingController();
final TextEditingController prixController2 = TextEditingController();
final TextEditingController numserieController = TextEditingController();
final TextEditingController spec1Controller = TextEditingController();
final TextEditingController spec2Controller = TextEditingController();
final TextEditingController jeu1Controller = TextEditingController();
final TextEditingController jeu2Controller = TextEditingController();
final TextEditingController jeu1PrixController = TextEditingController();
final TextEditingController jeu2PrixController = TextEditingController();

final TextEditingController dateCreeController = TextEditingController();
final TextEditingController creeParController = TextEditingController();
final TextEditingController dateModifController = TextEditingController();
final TextEditingController modifParController = TextEditingController();

String? selectedUnitemesure = ListsConst.uniteMesureList.first;
String? selectedetat;
bool firstselectsg = false;
bool merge = true;
String?  uniteMesure;

// ✅ "Nombre" (stock parallèle en pièces) n'a de sens que pour un produit
// vendu au poids/volume (Kg/Litre) — pour un produit déjà vendu à la pièce,
// quantité == nombre, ça n'apporterait rien.
bool _uniteEligibleNombre(String? uniteMesureFrench) =>
    uniteMesureFrench == 'Kg' || uniteMesureFrench == 'Litre';

bool emballage1Actif = false;
bool emballage2Actif = false;
Color colorchamp = Appstyle.grisSC;
Color colorchampenabled = Appstyle.grisC;
late Paramters paramters;
double margetauxPrmtre = 0;
String margeTypePrmtre = "Montant";

final GlobalKey<FormState> produitFormKey = GlobalKey<FormState>();

// ✅ Mode détaillé (onglets) : indicateur "point rouge" sur l'onglet contenant
// un champ obligatoire invalide, affiché après une tentative de sauvegarde
// échouée pour orienter l'utilisateur — recalculé à chaque frappe/sélection.
bool afficherErreursTabsProduitModif = false;

bool _emballagePrixInvalideModif(TextEditingController qteController, TextEditingController prixController2) {
  final prixEmballageTotal = double.tryParse(prixController2.text.replaceAll(',', '.'));
  final quantite = double.tryParse(qteController.text.replaceAll(',', '.'));
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));

  if (prixController2.text.trim().isEmpty) return true;
  if (prixEmballageTotal == null || prixEmballageTotal <= 0) return true;
  if (quantite == null || quantite <= 0) return true;
  if (prixAchat != null && (prixEmballageTotal / quantite) < prixAchat) return true;
  return false;
}

Set<int> _tabsAvecErreursProduitModif() {
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

  // Onglet 3 : Stock & Emballage
  if (uniteMesure == null || uniteMesure!.isEmpty) {
    erreurs.add(3);
  } else if (emballage1Actif && _emballagePrixInvalideModif(jeu1Controller, jeu1PrixController)) {
    erreurs.add(3);
  } else if (emballage2Actif && _emballagePrixInvalideModif(jeu2Controller, jeu2PrixController)) {
    erreurs.add(3);
  }

  // Onglet 4 : Prix & Taxes
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.'));
  final prixVente = double.tryParse(prixController2.text.replaceAll(',', '.'));
  if (prixController.text.trim().isEmpty || prixAchat == null || prixAchat <= 0 ||
      prixController2.text.trim().isEmpty || prixVente == null ||
      (prixAchat != null && prixVente != null && prixVente < prixAchat)) {
    erreurs.add(4);
  }

  return erreurs;
}

Widget _tabAvecIndicateurModif(String text, bool showErreur) {
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
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            ),
          ),
      ],
    ),
  );
}
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
Future<void> ProduitModif(BuildContext context, Produit produit) async {
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
      message: l10n.loginRequiredModify,
    );
    return;
  }

  await loadAllData(produite: produit);
  afficherErreursTabsProduitModif = false;
  final oldPhoto = productPhoto;
  selectedCategorie = categoriesTest.firstWhereOrNull((c) => c.id == produit.categorieId)?.nom;
  selectedCategorieid = produit.categorieId;
  selectedSousCategorieid = produit.sousCategorieId;
  selectedSousCategorie = sousCategoriesTest.firstWhereOrNull((sc) => sc.id == produit.sousCategorieId)?.nom;
  remiseId = (produit.remiseId == 0) ? null : produit.remiseId;
  selectedRemise = remisesTest.firstWhereOrNull((r) => r.id == produit.remiseId)?.nom;
  selectedetat = produit.etat ? l10n.active : l10n.inactive;

  merge = true;

  emballage1Actif =
      produit.emballage1 != null &&
          produit.emballage1!.toString().trim().isNotEmpty;

  emballage2Actif =
      produit.emballage2 != null &&
          produit.emballage2!.toString().trim().isNotEmpty;

  packsProduit = produitPackDetailsTest
      .where((p) => p.produitCode == produit.code)
      .toList();
  packsSelectionnes = packsProduit
      .map((d) => packsTest.firstWhereOrNull((p) => p.code == d.packCode))
      .whereType<Pack>()
      .toList();

  codesProduit = produitCodeDetailsTest
      .where((p) => p.produitCode == produit.code)
      .toList();
  codesSelectionnes = codesProduit
      .map((d) => codesTest.firstWhereOrNull((p) => p == d.CodeBar))
      .whereType<String>()
      .toList();

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      Produit produits = produit;
      bool isRapide = false;
      bool sansCodeBar = (produit.codeBarre ?? '').startsWith(CodePrefix.barcode);
      margeTypePrmtre = paramters.typeMarge;
      if (margeTypePrmtre == "Montant") {
        margetauxPrmtre = paramters.TauxMargeMontant;
      } else {
        margetauxPrmtre = paramters.TauxMargePerncetage;
      }
      bool _initialized = false;
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);
          bool mergeValue = produit.margeBool;
          bool multicodebar = produit.multicodebar;

          if (!_initialized) {
            _initialized = true;
            uniteMesure = translator.translateUniteMesure(produit.uniteMesure);
            selectedUnitemesure = produit.uniteMesure;
            // ✅ Corrige un état hérité incohérent (produit créé avant cette
            // règle, avec nombreActif=true sur une unité autre que Kg/Litre).
            if (!_uniteEligibleNombre(selectedUnitemesure)) {
              produit.nombreActif = false;
            }
            nomController.text = produit.nom;
            descontroller.text = produit.description ?? '';
            observcontroller.text = produit.observation ?? '';
            marqueController.text = produit.marque;
            prixController.text = produit.prixAchat.toString();
            tvaController.text = produit.tva.toString();
            prixController2.text = produit.prixVente.toString();
            dateController.text = produit.dateEmpreint.toString();
            modifParController.text = produit.modifParCode ?? '';
            margeController.text = produit.margeTaux.toString();
            margePController.text = produit.margeTauxPrct.toString();
            couleurController.text = produit.couleur ?? "";
            tailleController.text = produit.taille ?? "";
            codeController.text = produit.codeBarre ?? "";
            numserieController.text = produit.numeroSerie ?? "";
            jeu1Controller.text = produit.emballage1.toString();
            jeu2Controller.text = produit.emballage2.toString();
            jeu1PrixController.text = produit.emballageP1.toString();
            jeu2PrixController.text = produit.emballageP2.toString();

           }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1000,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/produit_icon.png',
                  text: l10n.modifyProduct,
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
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => setState(() => isRapide = true),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isRapide
                                        ? Appstyle.crevete
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.quickMode,
                                    style: TextStyle(
                                      color: isRapide
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => setState(() => isRapide = false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 25,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !isRapide
                                        ? Appstyle.crevete
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.detailedMode,
                                    style: TextStyle(
                                      color: !isRapide
                                          ? Colors.white
                                          : Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (isRapide)
                          _buildFormRapideDetail(
                            produit,
                            setState,
                            sansCodeBar,
                            (v) {
                              setState(() {
                                sansCodeBar = v;
                                codeController.clear();
                              });
                            },
                            context,
                            l10n,
                            translator,
                          )
                        else
                          _buildFormDetailleDetail(
                            produit,
                            setState,
                            mergeValue,
                            multicodebar,
                            sansCodeBar,
                            (v) {
                              setState(() {
                                sansCodeBar = v;
                                codeController.clear();
                              });
                            },
                            context,
                            l10n,
                            translator,
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
                      onPressed: () => Navigator.pop(context),
                      color: Appstyle.gris,
                      icon: Icons.cancel,
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                      text: l10n.modify,
                      color: Appstyle.violet,
                      icon: Icons.save,
                      onPressed: () async {
                        if (!produitFormKey.currentState!.validate()) {
                          setState(() => afficherErreursTabsProduitModif = true);
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.product,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        // ✅ Unicité du nom du produit, en excluant ce produit lui-même.
                        final produitNomExistant = await ProduitServices.findProduitByNom(
                          nomController.text,
                          excludeProduitCode: produits.code,
                        );
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
                        // ET produit_code_detail), en excluant ce produit lui-même.
                        final codesAVerifier = multicodebar
                            ? barcodes
                            : (!sansCodeBar && codeController.text.trim().isNotEmpty
                                ? [codeController.text.trim()]
                                : <String>[]);
                        for (final code in codesAVerifier) {
                          final conflit = await ProduitServices.findProduitUsingBarcode(
                            code,
                            excludeProduitCode: produits.code,
                          );
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

                        await ConfirmationDialog(
                          context: context,
                          titre: l10n.modification,
                          message: l10n.confirmModifyProduct,
                          onConfirmer: () async {
                            final produit = Produit(
                              id: produits.id,
                              nom: nomController.text.trim(),
                              description: descontroller.text.trim(),
                              marque: marqueController.text.trim(),
                              codeBarre: codeController.text.trim(),
                              code: produits.code,
                              numeroSerie: numserieController.text.trim(),
                              fournisseurCode: kSystemFournisseurCode,
                              categorieId: selectedCategorieid,
                              sousCategorieId: selectedSousCategorieid,
                              remiseId: remiseId,
                              multicodebar: multicodebar,
                              prixAchat: double.tryParse(prixController.text) ?? 0,
                              margeBool: merge,
                              margeTaux: double.tryParse(margeController.text) ?? 0,
                              margeTauxPrct: double.tryParse(margePController.text) ?? 0,
                              tva: double.tryParse(tvaController.text) ?? 0,
                              prixVente: double.tryParse(prixController2.text) ?? 0,
                              uniteMesure: selectedUnitemesure ?? "Piéce",
                              observation: observcontroller.text.trim(),
                              dateEmpreint: DateTime.tryParse(dateController.text),
                              emballage1: double.tryParse(jeu1Controller.text) ?? 0,
                              emballage2: double.tryParse(jeu2Controller.text) ?? 0,
                              emballageP1: double.tryParse(jeu1PrixController.text) ?? 0,
                              emballageP2: double.tryParse(jeu2PrixController.text) ?? 0,
                              etat: selectedetat == l10n.active,
                              dateCree: produits.dateCree,
                              service: produits.service,
                              nombreActif: produits.nombreActif,
                              taille: tailleController.text.trim(),
                              couleur: couleurController.text.trim(),
                              modifParCode: userCode,
                              creeParcode: produits.creeParcode,
                              photo: productPhoto != null ? productPhoto : null,

                            );

                            final response = await _updateProduit(
                              produit: produit,
                              newPhoto: productPhoto,      // Photos actuelles (après modifications)
                              oldPhoto: oldPhoto,          // Photos originales (avant modifications)
                              userName: userName,
                              userCode: userCode,
                            );

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

                            await _UpdatePackDetail(
                              produitsPack: packsSelectionnes,
                              orignal: produitPackDetailsTest,
                              produite: produit,
                              userName: userName,
                              userCode: userCode,
                            );
                            await _UpdateCodeDetail(
                              Codes: barcodes,
                              produite: produit,
                              userName: userName,
                              userCode: userCode,
                            );

                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.product,
                              message: response.message ?? l10n.productModifiedSuccess,
                              onTerminer: () {
                                Navigator.pop(context);
                              },
                            );
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

Widget _buildFormRapideDetail(
    Produit produit,
    void Function(VoidCallback fn) setState,
    bool sansCodeBar,
    ValueChanged<bool> onSansCodeBarChanged,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  // ✅ Permission spéciale (voir RoleDetail) : modifier le prix de vente
  // reste verrouillé pour un rôle qui n'a pas la permission correspondante.
  final canModifierPrixVente = Provider.of<AuthState>(context, listen: false).canModifierPrixVente;
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
          decoration: BoxDecoration(
            color: Appstyle.Tblanc,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Appstyle.grisC, width: 1.5),
          ),
          child: Column(
            children: [
              ChampAvecLabel(
                label: l10n.status,
                obligatoire: true,
                child: TextListe(
                  value: selectedetat,
                  items: translator.etatDisplayList,
                  clearable: false,
                  onChanged: (v) {
                    setState(() {
                      selectedetat = translator.etatToFrench(v ?? l10n.active);
                      produit.etat = selectedetat == l10n.active;
                    });
                  },
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.code,
                child: AffichageChamp(text: produit.code),
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
                obligatoire: !sansCodeBar,
                child: TextChampL(
                  controller: codeController,
                  hint: l10n.barcodeHint,
                  numeric: true,
                  enabled: !sansCodeBar,
                  obligatoire: !sansCodeBar,
                ),
              ),
              const SizedBox(height: 10),
              ProduitBarcodeGenerator(
                barcodeController: codeController,
                sansCodeBar: sansCodeBar,
                onSansCodeBarChanged: onSansCodeBarChanged,
              ),
              const SizedBox(height: 30),
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
                        categories: categoriesTest,
                        onCategorieSelected: (categorie) {
                          setState(() {
                            selectedCategorie = categorie.nom;
                            selectedCategorieid = categorie.id;
                            produit.categorieId = categorie.id;
                            selectedSousCategorie = null;

                            final sousCats = sousCategoriesTest
                                .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                                .toList();

                            if (sousCats.isNotEmpty) {
                              selectedSousCategorie = sousCats.first.nom;
                              selectedSousCategorieid = sousCats.first.id;
                              produit.sousCategorieId = sousCats.first.id;
                            }
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  obligatoire: true,
                  clearable: false,
                  value: selectedCategorie,
                  items: categoriesTest.map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedCategorie = v!;
                      selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                      produit.categorieId = categoriesTest.where((sc) => sc.nom == v).first.id;
                      if (v.isEmpty) {
                        selectedSousCategorie = null;
                      } else {
                        final sousCats = sousCategoriesTest
                            .where((sc) => sc.categorieCode == _codeCategorieByNom(v))
                            .toList();

                        if (sousCats.isNotEmpty) {
                          selectedSousCategorie = sousCats.first.nom;
                          selectedSousCategorieid = sousCats.first.id;
                          produit.sousCategorieId = sousCats.first.id;
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
                buttonAjout: true,
                obligatoire: true,
                onAjoutPressed: () async {
                  await showDialog(
                    context: context,
                    barrierColor: Appstyle.gris.withOpacity(0.25),
                    builder: (_) {
                      return InsertionSousCategorieDialog(
                        sousCategories: sousCategoriesTest
                            .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                            .toList(),
                        onSousCategorieSelected: (souscategorie) {
                          setState(() {
                            selectedSousCategorie = souscategorie.nom;
                            selectedSousCategorieid = souscategorie.id;
                            produit.sousCategorieId = souscategorie.id;
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  clearable: false,
                  obligatoire: true,
                  value: selectedSousCategorie,
                  items: sousCategoriesTest
                      .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                      .map((sc) => sc.nom)
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSousCategorie = v;
                      selectedSousCategorieid = sousCategoriesTest.where((s) => s.nom == v).first.id;
                      produit.sousCategorieId = sousCategoriesTest.where((s) => s.nom == v).first.id;
                    });
                  },
                ),
              ),
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
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Appstyle.grisC, width: 1.5),
          ),
          child: Column(
            children: [
              ChampAvecLabel(
                label: l10n.purchasePrice,
                obligatoire: true,
                child: TextChampL(
                  obligatoire: true,
                  controller: prixController,
                  hint: '150 ${l10n.currency}',
                  numeric: true,
                ),
              ),
              const SizedBox(height: 10),
              ChampAvecLabel(
                label: l10n.salePrice,
                obligatoire: true,
                child: TextChampL(
                  obligatoire: true,
                  enabled: canModifierPrixVente,
                  controller: prixController2,
                  hint: '250 ${l10n.currency}',
                  numeric: true,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.requiredField;
                    }
                    final prixAchat = double.tryParse(prixController.text) ?? 0;
                    final prixVente = double.tryParse(value) ?? 0;
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
                child: TextListe(
                  obligatoire: true,
                  value: uniteMesure,
                  items: translator.uniteMesureDisplayList,
                  clearable: false,
                  onChanged: (v) {
                    setState(() {
                      uniteMesure         = v;
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
              const SizedBox(height: 10),
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

Widget _buildFormDetailleDetail(
    Produit produit,
    void Function(VoidCallback fn) setState,
    bool mergeValue,
    bool multicodebar,
    bool sansCodeBar,
    ValueChanged<bool> onSansCodeBarChanged,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  // ✅ Permission spéciale (voir RoleDetail) : modifier le prix de vente
  // reste verrouillé pour un rôle qui n'a pas la permission correspondante.
  final canModifierPrixVente = Provider.of<AuthState>(context, listen: false).canModifierPrixVente;
  Widget tabPage(List<Widget> children) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  final erreursTabs = afficherErreursTabsProduitModif ? _tabsAvecErreursProduitModif() : <int>{};

  return DefaultTabController(
    length: 7,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Appstyle.grisC.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(4),
          child: TabBar(
            isScrollable: true,
            indicator: BoxDecoration(
              color: Appstyle.violet,
              borderRadius: BorderRadius.circular(10),
            ),
            labelColor: Colors.white,
            unselectedLabelColor: Appstyle.gris,
            dividerColor: Colors.transparent,
            indicatorSize: TabBarIndicatorSize.tab,
            labelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w600),
            unselectedLabelStyle: Appstyle.textSB.copyWith(fontWeight: FontWeight.w500),
            tabs: [
              _tabAvecIndicateurModif(l10n.generalInformation, erreursTabs.contains(0)),
              _tabAvecIndicateurModif(l10n.codeReference, erreursTabs.contains(1)),
              _tabAvecIndicateurModif(l10n.categoryDiscount, erreursTabs.contains(2)),
              _tabAvecIndicateurModif(l10n.priceTaxes, erreursTabs.contains(4)),
              _tabAvecIndicateurModif(l10n.unitPackaging, erreursTabs.contains(3)),
              _tabAvecIndicateurModif(l10n.packStore, erreursTabs.contains(5)),
              _tabAvecIndicateurModif(l10n.observation, erreursTabs.contains(6)),
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
                  label: l10n.status,
                  obligatoire: true,
                  child: TextListe(
                    value: selectedetat,
                    items: translator.etatDisplayList,
                    clearable: false,
                    onChanged: (v) {
                      setState(() {
                        selectedetat = translator.etatToFrench(v ?? l10n.active);
                        produit.etat = selectedetat == l10n.active;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.reference,
                  child: AffichageChamp(text: produit.code),
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
                    onChanged: (_) { if (afficherErreursTabsProduitModif) setState(() {}); },
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
                    onChanged: (_) { if (afficherErreursTabsProduitModif) setState(() {}); },
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
                      ? buildMultiBarcodeEditor(context, setState, l10n, excludeProduitCode: produit.code)
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
                    onSansCodeBarChanged: onSansCodeBarChanged,
                  ),
                ],
                const SizedBox(height: 10),
                ChampAvecLabel(
                  label: l10n.multicode,
                  distance: 200,
                  alignmentStart: true,
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
                  obligatoire: true,
                  buttonAjout: true,
                  onAjoutPressed: () async {
                    await showDialog(
                      context: context,
                      barrierColor: Appstyle.gris.withOpacity(0.25),
                      builder: (_) {
                        return InsertionCategorieDialog(
                          categories: categoriesTest,
                          onCategorieSelected: (categorie) {
                            setState(() {
                              selectedCategorie = categorie.nom;
                              selectedCategorieid = categorie.id;
                              produit.categorieId = categorie.id;

                              selectedSousCategorie = null;
                              final sousCats = sousCategoriesTest
                                  .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                                  .toList();

                              if (sousCats.isNotEmpty) {
                                selectedSousCategorie = sousCats.first.nom;
                                selectedSousCategorieid = sousCats.first.id;
                                produit.sousCategorieId = sousCats.first.id;
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                  child: TextListe(
                    obligatoire: true,
                    clearable: false,
                    value: selectedCategorie,
                    items: categoriesTest.map((c) => c.nom).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedCategorie = v!;
                        selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                        produit.categorieId = categoriesTest.where((sc) => sc.nom == v).first.id;
                        if (v.isEmpty) {
                          selectedSousCategorie = null;
                        } else {
                          final sousCats = sousCategoriesTest
                              .where((sc) => sc.categorieCode == _codeCategorieByNom(v))
                              .toList();

                          if (sousCats.isNotEmpty) {
                            selectedSousCategorie = sousCats.first.nom;
                            selectedSousCategorieid = sousCats.first.id;
                            produit.sousCategorieId = sousCats.first.id;
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
                  buttonAjout: true,
                  obligatoire: true,
                  onAjoutPressed: () async {
                    await showDialog(
                      context: context,
                      barrierColor: Appstyle.gris.withOpacity(0.25),
                      builder: (_) {
                        return InsertionSousCategorieDialog(
                          sousCategories: sousCategoriesTest
                              .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                              .toList(),
                          onSousCategorieSelected: (souscategorie) {
                            setState(() {
                              selectedSousCategorie = souscategorie.nom;
                              selectedSousCategorieid = souscategorie.id;
                              produit.sousCategorieId = souscategorie.id;
                            });
                          },
                        );
                      },
                    );
                  },
                  child: TextListe(
                    obligatoire: true,
                    clearable: false,
                    value: selectedSousCategorie,
                    items: sousCategoriesTest
                        .where((sc) => sc.categorieCode == _codeCategorieByNom(selectedCategorie))
                        .map((sc) => sc.nom)
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSousCategorie = v;
                        selectedSousCategorieid = sousCategoriesTest.where((sc) => sc.nom == v).first.id;
                        produit.sousCategorieId = sousCategoriesTest.where((sc) => sc.nom == v).first.id;
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
                              selectedRemise = remise.nom.trim();
                              produit.remiseId = remise.id;
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

                      final safeValue = remiseItems.contains(selectedRemise?.trim())
                          ? selectedRemise!.trim()
                          : null;

                      return TextListe(
                        value: safeValue,
                        items: remiseItems,
                        onChanged: (v) {
                          setState(() {
                            if (v == null || v.isEmpty) {
                              selectedRemise = null;
                              produit.remiseId = null;
                              remiseId = null;
                              return;
                            }

                            final remise = remisesTest.firstWhereOrNull(
                                  (r) => r.nom.trim() == v.trim(),
                            );

                            selectedRemise = v;
                            produit.remiseId = remise?.id;
                            remiseId = remise?.id;
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
                    controller: prixController,
                    onChanged: (_) {
                      setState(() {
                        // ✅ Recalculer le prix de vente AVANT de valider :
                        // sinon validate() s'exécute sur l'ancien
                        // prixController2.text (pas encore recalculé) et
                        // affiche "prix de vente inférieur au prix d'achat"
                        // même quand le prix recalculé qui s'affiche juste
                        // après est correct.
                        calculPrixVenteAuto();
                        produitFormKey.currentState!.validate();
                      });
                    },
                    hint: '150 ${l10n.currency}',
                    numeric: true,
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
                            enabled: canModifierPrixVente,
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
                            enabled: canModifierPrixVente,
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
                  obligatoire: false,
                  child: TextChampL(
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: tvaController,
                    hint: '20 %',
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
                    obligatoire: true,
                    enabled: false,
                    color: colorchamp,
                    colorEnabled: colorchampenabled,
                    controller: prixController2,
                    hint: '250 ${l10n.currency}',
                    numeric: true,
                    onChanged: (_) {
                      setState(() {
                        calculPrixVenteAuto();
                        produitFormKey.currentState!.validate();
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return l10n.requiredField;
                      }
                      final prixAchat = double.tryParse(prixController.text) ?? 0;
                      final prixVente = double.tryParse(value) ?? 0;
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
                    clearable: false,
                    value: uniteMesure,
                    items: translator.uniteMesureDisplayList,
                    onChanged: (v) {
                      setState(() {
                        uniteMesure = v;
                        selectedUnitemesure = translator.uniteMesureToFrench(v!);
                        // ✅ "Nombre" n'a de sens que pour un produit vendu au
                        // poids/volume (Kg/Litre) : si l'unité change pour
                        // autre chose, on désactive l'option pour éviter un
                        // état incohérent (toggle verrouillé mais resté actif).
                        if (!_uniteEligibleNombre(selectedUnitemesure)) {
                          produit.nombreActif = false;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),


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
                              enabled: true,
                              onChanged: (value) {
                                setState(() {
                                  emballage1Actif = value.trim().isNotEmpty;
                                  if (!emballage1Actif) {
                                    jeu1PrixController.clear();
                                  }
                                });
                                produitFormKey.currentState?.validate();
                              },
                            ),
                          ),
                          SizedBox(width: 20),
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
                              enabled: true,
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
                          SizedBox(width: 20),
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
                  alignmentStart: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: produit.service,
                        onChanged: (v) {
                          final nouveauService = v ?? false;
                          setState(() {
                            produit.service = nouveauService;
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
                  alignmentStart: true,
                  distance: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextRadio(
                        value: produit.nombreActif,
                        enabled: _uniteEligibleNombre(selectedUnitemesure),
                        onChanged: (v) {
                          setState(() {
                            produit.nombreActif = v ?? false;
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
                    onTap: () {},
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
                            packs: packsTest,
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
  List<T>? nonRemovableItems, // ✅ Ajout du paramètre
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
                color: isNonRemovable ? Colors.grey[700] : Colors.white,
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
    AppLocalizations l10n, {
    String? excludeProduitCode,
    }) {
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
                excludeProduitCode: excludeProduitCode,
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