import 'dart:io';
import 'dart:ui';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Categorie.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Fournisseur.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Magasin.dart' hide ApiResponse;
import 'package:caisse_dz/Services/MagasinDetail.dart';
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
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
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
import '../insertion_fournisseur.dart';
import '../insertion_magasin.dart';
import '../insertion_pack.dart';
import '../insertion_remise.dart';
import '../insertion_souscategorie.dart';
import 'package:collection/collection.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextMDetailId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await ProduitMagasinDetailServices.getNextId(txn);
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
      if (prd.nom == produit.packNom) {
        break;
      }
      i++;
    }
    if (i == produitsPack.length) {
      await service.deleteDetailes(produit.produitNom, produit.packNom);
      final int idH = await _GetNextHistoriqueId();
      final db = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db);
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur $userName a supprimer le ProduitPackDetail ${produit.produitNom} de Pack ${produit.packNom}}",
          type: "ProduitPackDetail",
          oper: ListsConst.typeHisto[3],
          dateCree: DateTime.now(),
          creeParCode: userCode);
      await serviceh.addHistorique(histo);
    }
  }

  for (var produit in produitsPack) {
    final detail = ProduitPackDetail(
      packNom: produit.nom,
      packCode: produit.code,
      produitNom: produite.nom,
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

  if (tempPhoto.startsWith('temp_')) {
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
  return prixParPiece.toStringAsFixed(2);
}

Future<void> updateMagasinDetail({
  required List<Magasin> magasins,
  required List<ProduitMagasinDetail> orignal,
  required Produit produit,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitMagasinDetailServices(db);
  final servicep = MagasinServices(db);

  int i = 0;
  for (var magasin in orignal) {
    i = 0;
    for (var magasind in magasins) {
      if (magasind.code == magasin.magasinCode) {
        break;
      }
      i++;
    }
    if (i == magasins.length) {
      final magasinNom = magasins.firstWhereOrNull((m) => m.code == magasin.magasinCode)?.nom ?? magasin.magasinCode;
      await service.deleteDetailes(produit.code, magasin.magasinCode);
      final int idH = await _GetNextHistoriqueId();
      final db = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db);
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur $userName a supprimer le ProduitMagasinDetail ${produit.nom} de Magasin $magasinNom automatiquement",
          type: "ProduitMagasinDetail",
          oper: ListsConst.typeHisto[3],
          dateCree: DateTime.now(),
          creeParCode: userCode);
      await serviceh.addHistorique(histo);
    }
  }
  for (var magasin in magasins) {
    final detail = ProduitMagasinDetail(
      magasinCode: magasin.code,
      produitCode: produit.code,
      dateCree: DateTime.now(),
      id: await _GetNextMDetailId(),
      creeParCode: userCode,
    );
    final response = await service.addProduitMagasinDetail(detail);
    if (response == 0) {
      print("le Magasin ${magasin.nom}est deja existe dans MagasinProduitDetail ");
    } else {
      print("le Magasin ${magasin.nom}est ajoutee dans MagasinProduitDetail ");
      final int idH = await _GetNextHistoriqueId();
      final db = await DbCreator.openDb();
      final serviceh = await HistoriqueServices(db);
      final Historique histo = Historique(
          id: idH,
          code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
          desc: "l'utilisateur $userName a ajoutee le ProduitMagasinDetail ${produit.nom} de Magasin ${magasin.nom} automatiquement",
          oper: ListsConst.typeHisto[1],
          type: "ProduitMagasinDetail",
          dateCree: DateTime.now(),
          creeParCode: userCode);
      await serviceh.addHistorique(histo);
    }
  }
  print('Magasin details synced for ${produit.nom}');
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
  if (newPhoto != null && newPhoto.startsWith('temp_')) {
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
  String? oldSousCategorie,
  String? oldRemise,
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
    final fournisseur = await FournisseurServices.getAllFournisseurs();
    final magasin = await MagasinServices.getAllMagasins();
    final Param = await ParamServices.getParam();
    final packdetail = await ProduitPackDetailServices.getDetailsByNom(produite.nom);
    final magasindetail = await ProduitMagasinDetailServices.getDetailsByCode(produite.code);
    final codedetail = await ProduitServices.getAllCodeDetailsByCode(produite.code);

    fournisseursTest = fournisseur;
    packsTest = pack;
    remisesTest = remise;
    sousCategoriesTest = sous;
    categoriesTest = categorie;
    magasinsTest = magasin;
    paramters = Param;
    produitsMagasinsTest = magasindetail;
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

Future<void> calculPrixVenteAuto() async {
  final prixAchat = double.tryParse(prixController.text.replaceAll(',', '.')) ?? 0;
  double prixVente = prixAchat;

  if (merge) {
    final tauxMontant = margetauxPrmtre;
    final tauxPercentage = margetauxPrmtre;

    if (margeTypePrmtre == "Montant") {
      prixVente = prixAchat + tauxMontant;
    } else {
      prixVente = prixAchat + (prixAchat * tauxPercentage / 100);
    }
  } else {
    final margeMontant = double.tryParse(margeController.text.replaceAll(',', '.')) ?? 0;
    final margePercentage = double.tryParse(margePController.text.replaceAll(',', '.')) ?? 0;

    if (margeMontant > 0) {
      prixVente = prixAchat + margeMontant;
    } else if (margePercentage > 0) {
      prixVente = prixAchat + (prixAchat * margePercentage / 100);
    }
  }

  prixController2.text = prixVente.toStringAsFixed(2);
}

int selectedCategorieid = 0;
int selectedSousCategorieid = 0;
int remiseId = 0;
int id = 0;
String code = "";
List<Fournisseur> fournisseursTest = [];
List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];
List<Remise> remisesTest = [];
List<Pack> packsTest = [];
List<String> codesTest = [];
List<Magasin> magasinsTest = [];
List<Pack> packsSelectionnes = [];
List<String> codesSelectionnes = [];
List<Magasin> magasinsSelectionnes = [];
List<String> barcodes = [];
late List<String> originalBarcodes;
List<ProduitMagasinDetail> magasinsProduit = [];
List<ProduitPackDetail> packsProduit = [];
List<ProduitCodeDetail> codesProduit = [];
List<ProduitMagasinDetail> produitsMagasinsTest = [];
List<ProduitPackDetail> produitPackDetailsTest = [];
List<ProduitCodeDetail> produitCodeDetailsTest = [];
String? productPhoto;
final TextEditingController multicodeController = TextEditingController();
final TextEditingController seuilminController = TextEditingController();
final TextEditingController seuilmaxController = TextEditingController();
final TextEditingController margeController = TextEditingController();
final TextEditingController margePController = TextEditingController();
final TextEditingController couleurController = TextEditingController();
final TextEditingController tailleController = TextEditingController();
final TextEditingController dateController = TextEditingController();
final TextEditingController nomController = TextEditingController();
final TextEditingController descontroller = TextEditingController();
final TextEditingController observcontroller = TextEditingController();
final TextEditingController marqueController = TextEditingController();
final TextEditingController fournController = TextEditingController();
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
String? selectedFournisseur;
bool firstselectsg = false;
bool seuil = true;
bool merge = false;
String?  uniteMesure;

bool emballage1Actif = false;
bool emballage2Actif = false;
Color colorchamp = Appstyle.grisSC;
Color colorchampenabled = Appstyle.grisC;
late Paramters paramters;
double MaxPrmtre = 0;
double MinPrmtre = 0;
double margetauxPrmtre = 0;
String margeTypePrmtre = "Montant";

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
Future<void> ProduitModif(BuildContext context, Produit produit) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final oldSousCategorie = produit.sousCategorie;
  final oldRemise = produit.remise;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredModify,
    );
    return;
  }

  await loadAllData(produite: produit);
  final oldPhoto = productPhoto;
  String selectedCategorie = produit.categorie;
  selectedCategorieid = produit.categorieId;
  selectedSousCategorieid = produit.sousCategorieId;
  remiseId = produit.remiseId ?? 0;
  selectedetat = produit.etat ? l10n.active : l10n.inactive;

  seuil = produit.seuilBool;
  merge = produit.margeBool;

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
      .map((d) => packsTest.firstWhereOrNull((p) => p.nom == d.packNom))
      .whereType<Pack>()
      .toList();

  codesProduit = produitCodeDetailsTest
      .where((p) => p.produitCode == produit.code)
      .toList();
  codesSelectionnes = codesProduit
      .map((d) => codesTest.firstWhereOrNull((p) => p == d.CodeBar))
      .whereType<String>()
      .toList();

  magasinsProduit = produitsMagasinsTest
      .where((p) => p.produitCode == produit.code)
      .toList();
  magasinsSelectionnes = magasinsProduit
      .map((d) => magasinsTest.firstWhereOrNull((p) => p.code == d.magasinCode))
      .whereType<Magasin>()
      .toList();

  return showDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      Produit produits = produit;
      bool isRapide = false;
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
          bool seuilValue = produit.seuilBool;
          bool multicodebar = produit.multicodebar;

          if (!_initialized) {
            _initialized = true;
            uniteMesure = translator.translateUniteMesure(produit.uniteMesure);
            selectedUnitemesure = produit.uniteMesure;
            nomController.text = produit.nom;
            descontroller.text = produit.description!;
            observcontroller.text = produit.observation!;
            marqueController.text = produit.marque;
            prixController.text = produit.prixAchat.toString();
            tvaController.text = produit.tva.toString();
            prixController2.text = produit.prixVente.toString();
            dateController.text = produit.dateEmpreint.toString();
            modifParController.text = produit.modifPar ?? '';
            seuilminController.text = produit.seuilMin.toString();
            seuilmaxController.text = produit.seuilMax.toString();
            margeController.text = produit.margeTaux.toString();
            margePController.text = produit.margeTauxPrct.toString();
            couleurController.text = produit.couleur ?? "";
            tailleController.text = produit.taille ?? "";
            fournController.text = produit.fournisseur ?? "";
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
                          _buildFormRapideDetail(produit, setState, context, l10n, translator)
                        else
                          _buildFormDetailleDetail(
                            produit,
                            setState,
                            mergeValue,
                            seuilValue,
                            multicodebar,
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
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.product,
                            message: l10n.fillRequiredFields,
                          );
                          return;
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
                              fournisseur: produits.fournisseur,
                              categorieId: selectedCategorieid,
                              sousCategorieId: selectedSousCategorieid,
                              remiseId: remiseId,
                              categorie: selectedCategorie.trim(),
                              sousCategorie: produits.sousCategorie.trim(),
                              remise: produits.remise?.trim(),
                              multicodebar: multicodebar,
                              prixAchat: double.tryParse(prixController.text) ?? 0,
                              margeBool: merge,
                              margeTaux: double.tryParse(margeController.text) ?? 0,
                              margeTauxPrct: double.tryParse(margePController.text) ?? 0,
                              tva: double.tryParse(tvaController.text) ?? 0,
                              prixVente: double.tryParse(prixController2.text) ?? 0,
                              uniteMesure: selectedUnitemesure ?? "Piéce",
                              quantite: produits.quantite,
                              seuilBool: seuil,
                              seuilMin: double.tryParse(seuilminController.text) ?? 0,
                              seuilMax: double.tryParse(seuilmaxController.text) ?? 0,
                              observation: observcontroller.text.trim(),
                              dateEmpreint: DateTime.tryParse(dateController.text),
                              emballage1: double.tryParse(jeu1Controller.text) ?? 0,
                              emballage2: double.tryParse(jeu2Controller.text) ?? 0,
                              emballageP1: double.tryParse(jeu1PrixController.text) ?? 0,
                              emballageP2: double.tryParse(jeu2PrixController.text) ?? 0,
                              etat: selectedetat == l10n.active,
                              dateCree: produits.dateCree,
                              service: produits.service,
                              taille: tailleController.text.trim(),
                              couleur: couleurController.text.trim(),
                              modifPar: userName,
                              creeParcode: produits.creeParcode,
                              photo: productPhoto != null ? productPhoto : null,

                            );

                            final response = await _updateProduit(
                              produit: produit,
                              newPhoto: productPhoto,      // Photos actuelles (après modifications)
                              oldPhoto: oldPhoto,          // Photos originales (avant modifications)
                              userName: userName,
                              userCode: userCode,
                              oldSousCategorie: oldSousCategorie,
                              oldRemise: oldRemise,
                            );

                            if (!response.success) {
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.error,
                                titre_concerne: l10n.product,
                                message: response.message ?? l10n.errorOccurred,
                              );
                              return;
                            }

                            await updateMagasinDetail(
                              magasins: magasinsSelectionnes,
                              orignal: produitsMagasinsTest,
                              produit: produit,
                              userName: userName,
                              userCode: userCode,
                            );

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
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
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
                label: l10n.reference,
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
              // Dans _buildFormRapideDetail, remplacez le ChampAvecLabel du fournisseur par :

              ChampAvecLabel(
                label: l10n.supplier,
                obligatoire: true,  // ✅ Ajouter obligatoire
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
                            produit.fournisseur = fournisseur.nom;
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  obligatoire: true,  // ✅ Ajouter obligatoire
                  clearable: false,
                  value: produit.fournisseur ?? "",
                  items: fournisseursTest.map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      produit.fournisseur = v!;
                    });
                  },
                ),
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
                            produit.categorie = categorie.nom;
                            produit.categorieId = categorie.id;
                            selectedSousCategorie = null;

                            final sousCats = sousCategoriesTest
                                .where((sc) => sc.categorieNom == produit.categorie)
                                .toList();

                            if (sousCats.isNotEmpty) {
                              selectedSousCategorie = sousCats.first.nom;
                              selectedSousCategorieid = sousCats.first.id;
                              produit.sousCategorie = sousCats.first.nom;
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
                  value: produit.categorie,
                  items: categoriesTest.map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      produit.categorie = v!;
                      selectedCategorie = v;
                      selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                      produit.categorieId = categoriesTest.where((sc) => sc.nom == v).first.id;
                      if (v.isEmpty) {
                        selectedSousCategorie = null;
                      } else {
                        final sousCats = sousCategoriesTest
                            .where((sc) => sc.categorieNom == v)
                            .toList();

                        if (sousCats.isNotEmpty) {
                          selectedSousCategorie = sousCats.first.nom;
                          selectedSousCategorieid = sousCats.first.id;
                          produit.sousCategorie = sousCats.first.nom;
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
                            .where((sc) => sc.categorieNom == selectedCategorie)
                            .toList(),
                        onSousCategorieSelected: (souscategorie) {
                          setState(() {
                            selectedSousCategorie = souscategorie.nom;
                            selectedSousCategorieid = souscategorie.id;
                            produit.sousCategorie = souscategorie.nom;
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
                  value: produit.sousCategorie,
                  items: sousCategoriesTest
                      .where((sc) => sc.categorieNom == produit.categorie)
                      .map((sc) => sc.nom)
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedSousCategorie = v;
                      selectedSousCategorieid = sousCategoriesTest.where((s) => s.nom == v).first.id;
                      produit.sousCategorie = v!;
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
    bool seuilValue,
    bool multicodebar,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/info_icon.png",
                    text: l10n.generalInformation,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
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
                  // Dans _buildFormDetailleDetail, remplacez le ChampAvecLabel du fournisseur par :

                  ChampAvecLabel(
                    label: l10n.supplier,
                    obligatoire: true,  // ✅ Ajouter obligatoire
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
                                produit.fournisseur = fournisseur.nom;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      clearable: false,
                      obligatoire: true,  // ✅ Ajouter obligatoire
                      value: produit.fournisseur ?? "",
                      items: fournisseursTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          produit.fournisseur = v!;
                        });
                      },
                    ),
                  ),     ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/reference_icon.png",
                    text: l10n.codeReference,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.serialNumber,
                    child: TextChampL(
                      controller: numserieController,
                      hint: l10n.serialNumberHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    label: l10n.barcode,
                    obligatoire: true,
                    child: multicodebar
                        ? buildMultiBarcodeEditor(context,setState, l10n)
                        : TextChampL(
                      controller: codeController,
                      hint: l10n.barcodeHint,
                      numeric: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    label: l10n.multicode,
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

                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/cardwidget/categorie_icon.png",
                    text: l10n.categoryDiscount,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
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
                                produit.categorie = categorie.nom;
                                produit.categorieId = categorie.id;

                                selectedSousCategorie = null;
                                final sousCats = sousCategoriesTest
                                    .where((sc) => sc.categorieNom == selectedCategorie)
                                    .toList();

                                if (sousCats.isNotEmpty) {
                                  selectedSousCategorie = sousCats.first.nom;
                                  selectedSousCategorieid = sousCats.first.id;
                                  produit.sousCategorie = sousCats.first.nom;
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
                      value: produit.categorie,
                      items: categoriesTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          produit.categorie = v!;
                          selectedCategorie = v;
                          selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                          produit.categorieId = categoriesTest.where((sc) => sc.nom == v).first.id;
                          if (v.isEmpty) {
                            selectedSousCategorie = null;
                          } else {
                            final sousCats = sousCategoriesTest
                                .where((sc) => sc.categorieNom == v)
                                .toList();

                            if (sousCats.isNotEmpty) {
                              selectedSousCategorie = sousCats.first.nom;
                              selectedSousCategorieid = sousCats.first.id;
                              produit.sousCategorie = sousCats.first.nom;
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
                                .where((sc) => sc.categorieNom == selectedCategorie)
                                .toList(),
                            onSousCategorieSelected: (souscategorie) {
                              setState(() {
                                selectedSousCategorie = souscategorie.nom;
                                produit.sousCategorie = souscategorie.nom;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      obligatoire: true,
                      clearable: false,
                      value: produit.sousCategorie,
                      items: sousCategoriesTest
                          .where((sc) => sc.categorieNom == produit.categorie)
                          .map((sc) => sc.nom)
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedSousCategorie = v;
                          produit.sousCategorie = v!;
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
                                produit.remise = remise.nom.trim();
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

                        final safeValue = remiseItems.contains(produit.remise?.trim())
                            ? produit.remise!.trim()
                            : null;

                        return TextListe(
                          value: safeValue,
                          items: remiseItems,
                          onChanged: (v) {
                            setState(() {
                              if (v == null || v.isEmpty) {
                                produit.remise = null;
                                produit.remiseId = 0;
                                remiseId = 0;
                                return;
                              }

                              final remise = remisesTest.firstWhereOrNull(
                                    (r) => r.nom.trim() == v.trim(),
                              );

                              produit.remise = v;
                              produit.remiseId = remise?.id;
                              remiseId = remise?.id ?? 0;
                            });
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/sidebar/produit_icon.png",
                    text: l10n.unitPackaging,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
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
                                  if (emballage1Actif && (value == null || value.isEmpty)) {
                                    return l10n.requiredField;
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}), // Pour recalculer
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
                                  if (emballage2Actif && (value == null || value.isEmpty)) {
                                    return l10n.requiredField;
                                  }
                                  return null;
                                },
                                onChanged: (_) => setState(() {}), // Pour recalculer
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
                ],
              ),
            ), ],
        ),
      ),
      const SizedBox(width: 20),
      Expanded(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
                child:ChampAvecLabel(
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
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/devise_icon.png",
                    text: l10n.priceTaxes,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.purchasePrice,
                    obligatoire: true,
                    child: TextChampL(
                      obligatoire: true,
                      color: colorchamp,
                      colorEnabled: colorchampenabled,
                      controller: prixController,
                      onChanged: (_) {
                        produitFormKey.currentState!.validate();
                        calculPrixVenteAuto();
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
                          value: produit.margeBool,
                          onChanged: (v) {
                            setState(() {
                              produit.margeBool = v ?? false;
                            });
                            calculPrixVenteAuto();
                          },
                          auto: true,
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
                    obligatoire: false,
                    child: TextChampL(
                      color: colorchamp,
                      colorEnabled: colorchampenabled,
                      controller: tvaController,
                      hint: '20 %',
                      numeric: true,
                      onChanged: (value) {
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
                        produitFormKey.currentState!.validate();
                        calculPrixVenteAuto();
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
                ],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/sidebar/stock_icon.png",
                    text: l10n.storage,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.service,
                    alignmentStart: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextRadio(
                          value: produit.service,
                          onChanged: (v) {
                            setState(() {
                              produit.service = v ?? false;
                            });
                          },
                          auto: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  ChampAvecLabel(
                    label: l10n.threshold,
                    alignmentStart: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextRadio(
                          value: produit.seuilBool,
                          onChanged: (v) {
                            setState(() {
                              produit.seuilBool = v ?? false;
                            });
                          },
                          auto: true,
                        ),
                        if (!seuil) ...[
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.minThreshold,
                            obligatoire: true,
                            child: TextChampL(
                              obligatoire: true,
                              onChanged: (_) {
                                produitFormKey.currentState!.validate();
                              },
                              controller: seuilminController,
                              hint: "5",
                              numeric: true,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.maxThreshold,
                            obligatoire: true,
                            child: TextChampL(
                              obligatoire: true,
                              onChanged: (_) {
                                produitFormKey.currentState!.validate();
                              },
                              validator: (value) {
                                final seuilmin = double.tryParse(seuilMinController.text) ?? 0;
                                final seuilmax = double.tryParse(value ?? "") ?? 0;
                                if (seuilmin > seuilmax) {
                                  return l10n.maxThresholdLowerThanMin;
                                }
                                return null;
                              },
                              controller: seuilmaxController,
                              hint: "50",
                              numeric: true,
                            ),
                          ),
                        ],
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
                  const SizedBox(height: 10),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/cardwidget/remise_icon.png",
                    text: l10n.packStore,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 15),
                  ChampAvecLabel(
                    label: l10n.packs,
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
                  const SizedBox(height: 10),
                  ChampAvecLabel(
                    label: l10n.stores,
                    distance: 100,
                    alignmentStart: true,
                    child: chipsSelector<Magasin>(
                      values: magasinsSelectionnes,
                      label: (p) => p.nom,
                      l10n: l10n,
                      nonRemovableItems: magasinsSelectionnes
                          .where((m) => m.nom == "Magasin System")
                          .toList(), // ✅ Le magasin System n'est pas supprimable
                      onAdd: () async {
                        // Filtrer pour ne pas pouvoir ajouter le magasin System (déjà présent)
                        final magasinsDisponibles = magasinsTest
                            .where((m) => m.nom != "Magasin System" &&
                            !magasinsSelectionnes.any((s) => s.code == m.code))
                            .toList();

                        if (magasinsDisponibles.isEmpty) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.information,
                            titre_concerne: l10n.stores,
                            message: l10n.noStoreAvailable,
                          );
                          return;
                        }

                        await showDialog(
                          context: context,
                          barrierColor: Appstyle.gris.withOpacity(0.25),
                          builder: (_) {
                            return InsertionMagasinDialog(
                              multiselection: true,
                              magasins: magasinsDisponibles,
                              onMagasinSelected: (magasin) {
                                setState(() {
                                  if (!magasinsSelectionnes.any((p) => p.code == magasin.code)) {
                                    magasinsSelectionnes.add(magasin);
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                      onRemove: (p) {
                        setState(() {
                          magasinsSelectionnes.remove(p);
                        });
                      },
                    ),
                  ),        const SizedBox(height: 10),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              decoration: BoxDecoration(
                color: Appstyle.Tblanc,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Appstyle.grisC, width: 1.5),
              ),
              child: Column(
                children: [
                  TitleSmall(
                    imageSize: 24,
                    imagePath: "assets/icons/info_icon.png",
                    text: l10n.observation,
                    couleur: Appstyle.Tblue,
                    opacity: 0.85,
                  ),
                  const SizedBox(height: 20),
                  ChampAvecLabel(
                    label: l10n.observation,
                    child: TextChampL(
                      controller: observcontroller,
                      hint: l10n.observationHint,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
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