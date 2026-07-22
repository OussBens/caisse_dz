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
import 'package:caisse_dz/core/dialog/insertion_categorie.dart';
import 'package:caisse_dz/core/dialog/insertion_fournisseur.dart';
import 'package:caisse_dz/core/dialog/insertion_magasin.dart';
import 'package:caisse_dz/core/dialog/insertion_pack.dart';
import 'package:caisse_dz/core/dialog/insertion_remise.dart';
import 'package:caisse_dz/core/dialog/insertion_souscategorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/champ/affichage_champ.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../../../Services/Photos.dart';
import '../../../data/models/magasin.dart';
import '../../../data/models/pack.dart';
import '../../utilis/api_response.dart';
import '../../widget/button/button_add_photo.dart';
import '../../widget/champ/liste_champ.dart';
import '../../widget/champ/radio_champ.dart';
import '../../widget/code_generateur.dart';
import '../../widget/title/title_small.dart';
import '../../widget/title/titre_avec_ligne.dart';
import '../base_dialog.dart';
import '../information_dialog.dart';
import '../insertion_codebar.dart';

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
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
      packNom: pack.nom,
      packCode: pack.code,
      produitNom: produit.nom,
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
Future<void> _savePrduitMagasinDetail({
  required Produit produit,
  required List<Magasin> magasins,
  required String userName,
  required String userCode,
}) async {
  final db = await DbCreator.openDb();
  final service = ProduitMagasinDetailServices(db);
  final magasinService = MagasinServices(db);

  // Filtrer pour exclure le magasin System car il est déjà créé automatiquement
  final magasinsToSave = magasins.where((m) => m.nom != "System").toList();

  for (var magasin in magasinsToSave) {
    final ProduitMagasinDetail detail = ProduitMagasinDetail(
      magasinCode: magasin.code,
      produitCode: produit.code,
      dateCree: DateTime.now(),
      id: await _GetNextMagasinDetailId(),
      creeParCode: userCode,
      quantite: 0, // Initialiser à 0
    );
    await service.addProduitMagasinDetail(detail);

    final int idH = await _GetNextHistoriqueId();
    final db = await DbCreator.openDb();
    final serviceh = HistoriqueServices(db);
    final Historique histo = Historique(
        id: idH,
        code: "HS$idH ${DateTime.now().microsecondsSinceEpoch}",
        desc: "l'utilisateur $userName a ajouter le ProduitMagasinDetail de Magasin ${magasin.nom} de produit ${produit.nom}",
        type: "ProduitMagasinDetail",
        oper: ListsConst.typeHisto[0],
        dateCree: DateTime.now(),
        creeParCode: userCode);
    await serviceh.addHistorique(histo);
  }
}
// Ajoutez cette fonction après les autres fonctions comme _GetNextHistoriqueId, etc.
Future<String?> _saveProductPhoto(String productCode, String? tempPhoto) async {
  if (tempPhoto == null || tempPhoto.isEmpty) return null;

  if (tempPhoto.startsWith('temp_')) {
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
    final fournisseur = await FournisseurServices.getAllFournisseurs();
    final remise = await RemiseServices.getAllRemise();
    final categorie = await CategorieServices.getAllCategorie();
    final magasin = await MagasinServices.getAllMagasins();
    final pack = await PackServices.getAllPacks();
    final Param = await ParamServices.getParam();

    fournisseursTest = fournisseur;
    categoriesTest = categorie;
    magasinsTest = magasin;
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
  return prixParPiece.toStringAsFixed(2);
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
  selectedFournisseur = null;
  selectedRemise = null;
  selectedCategorie = null;
  selectedSousCategorie = null;
  selectedUnitemesure = ListsConst.uniteMesureList.first;
  productPhoto = null;
  service = false;
  merge = false;
  seuil = true;
  multicodebar = false;

  // Ne pas vider complètement, garder seulement le magasin System
  final systemMagasin = magasinsSelectionnes.firstWhere(
        (m) => m.nom == "Magasin System",
    orElse: () => Magasin(
      id: 0,
      nom: "Magasin System",
      code: "MAG0000",
      etat: true,
      creeParCode: "SYS001",
      dateCree: DateTime.now(),
    ),
  );
  magasinsSelectionnes.clear();
  magasinsSelectionnes.add(systemMagasin);

  packsSelectionnes.clear();
  barcodes.clear();
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
String? productPhoto;

int id = 0;
String code = "";
List<Fournisseur> fournisseursTest = [];
List<Categorie> categoriesTest = [];
List<SousCategorie> sousCategoriesTest = [];
List<Remise> remisesTest = [];
List<Pack> packsTest = [];
List<Magasin> magasinsTest = [];
List<Pack> packsSelectionnes = [];
List<Magasin> magasinsSelectionnes = [];
List<String> barcodes = [];
late Paramters paramters;

int? selectedCategorieid;
int? selectedSousCategorieid;
int? remiseId;
int? packId;

double MaxPrmtre = 0;
double MinPrmtre = 0;
double margetauxPrmtre = 0;
String margeTypePrmtre = "Montant";

final TextEditingController multicodeController = TextEditingController();
final TextEditingController seuilMaxController = TextEditingController();
final TextEditingController seuilMinController = TextEditingController();
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

bool service = false;
bool merge = false;
bool seuil = true;
bool multicodebar = false;
bool emballage1Actif = false;
bool emballage2Actif = false;
String? selectedUnitemesure = ListsConst.uniteMesureList[1];
String? selectedFournisseur;
String? selectedRemise;
String? selectedCategorie;
String? selectedSousCategorie;
String? selectedUnite;

Color colorchamp = Appstyle.grisSC;
Color colorchampenabled = Appstyle.grisC;

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

Future<void> ProduitNouveau(BuildContext context) async {
  await loadAllData();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username!;
  final userCode = auth.userCode!;
  final l10n = AppLocalizations.of(context)!;

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  id = await _GetNextId();
  code = "PRD$id${DateTime.now().millisecondsSinceEpoch}";

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      bool isRapide = true;
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
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.product,
                            message: l10n.fillRequiredFields,
                          );
                          return;
                        }

                        double toDouble(TextEditingController c, {double def = 0}) {
                          final text = c.text.trim().replaceAll(',', '.');
                          if (text.isEmpty) return def;
                          return double.tryParse(text) ?? def;
                        }

                        if (seuil) {
                          MinPrmtre = paramters.Minimum;
                          MaxPrmtre = paramters.Maximum;
                        } else {
                          MinPrmtre = toDouble(seuilMinController);
                          MaxPrmtre = toDouble(seuilMaxController);
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
                          fournisseur: selectedFournisseur!,
                          categorieId: selectedCategorieid!,
                          sousCategorieId: selectedSousCategorieid!,
                          remiseId: remiseId ?? 0,
                          categorie: selectedCategorie!,
                          sousCategorie: selectedSousCategorie!,
                          remise: selectedRemise,
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
                          quantite: 0,
                          seuilBool: seuil,
                          seuilMin: MinPrmtre,
                          seuilMax: MaxPrmtre,
                          observation: observcontroller.text,
                          dateEmpreint: DateTime.tryParse(dateController.text),
                          etat: true,
                          dateCree: DateTime.now(),
                          creeParcode: userCode,
                          service: service,
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
                            titre_concerne: l10n.product,
                            message: response.message ?? l10n.errorOccurred,
                          );
                          return;
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

                        await _savePrduitMagasinDetail(
                          produit: produit,
                          magasins: magasinsSelectionnes,
                          userName: userName,
                          userCode: userCode,
                        );

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
                            Navigator.pop(context);
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

Widget _buildFormRapide(
    void Function(VoidCallback fn) setState,
    BuildContext context,
    AppLocalizations l10n,
    ListsConstTranslator translator) {
  selectedUnite = translator.uniteMesureDisplayList.first;
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
                label: l10n.reference,
                child: AffichageChamp(text: "Généré automatiquement"),  // ✅ Texte temporaire
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
              // Dans _buildFormRapide, remplacez le ChampAvecLabel du fournisseur par :

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
                            selectedFournisseur = fournisseur.nom;
                          });
                        },
                      );
                    },
                  );
                },
                child: TextListe(
                  obligatoire: true,  // ✅ Ajouter obligatoire
                  clearable: false,
                  value: selectedFournisseur ?? "",
                  items: fournisseursTest.map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedFournisseur = v;
                    });
                  },
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
                        categories: categoriesTest,
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
                  items: categoriesTest.map((c) => c.nom).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedCategorie = v;
                      selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                      if (v == null || v.isEmpty) {
                        selectedSousCategorie = "";
                      } else {
                        final sousCats = sousCategoriesTest
                            .where((sc) => sc.categorieNom == v)
                            .toList();

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
                        sousCategories: sousCategoriesTest
                            .where((sc) => sc.categorieNom == selectedCategorie)
                            .toList(),
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
                  items: sousCategoriesTest
                      .where((sc) => sc.categorieNom == selectedCategorie)
                      .map((sc) => sc.nom)
                      .toList(),
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
            borderRadius: BorderRadius.circular(14),
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
                    final prixVente = double.tryParse(value ?? "") ?? 0;
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
                  value: selectedUnite,
                  items: translator.uniteMesureDisplayList,
                  clearable: false,
                  onChanged: (v) {
                    setState(() {
                      selectedUnite       = v;
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

  // Initialiser le magasin System au chargement du formulaire
  Future<void> initSystemMagasin() async {
    if (magasinsSelectionnes.isEmpty) {
      final db = await DbCreator.openDb();
      final magasinService = MagasinServices(db);
      final systemMagasin = await magasinService.getMagasinByNom("Magasin System");

      if (systemMagasin != null) {
        setState(() {
          magasinsSelectionnes.add(systemMagasin);
        });
      }
    }
  }
  // Initialiser le magasin System une seule fois
  WidgetsBinding.instance.addPostFrameCallback((_) {
    initSystemMagasin();
  });
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
                  // Dans _buildFormDetaille, remplacez le ChampAvecLabel du fournisseur par :

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
                                selectedFournisseur = fournisseur.nom;
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      obligatoire: true,  // ✅ Ajouter obligatoire
                      clearable: false,
                      value: selectedFournisseur ?? "",
                      items: fournisseursTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedFournisseur = v;
                        });
                      },
                    ),
                  ), ],
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
                              });
                            },
                          );
                        },
                      );
                    },
                    child: TextListe(
                      obligatoire: true,
                      value: selectedCategorie ?? "",
                      items: categoriesTest.map((c) => c.nom).toList(),
                      onChanged: (v) {
                        setState(() {
                          selectedCategorie = v;
                          selectedCategorieid = categoriesTest.where((sc) => sc.nom == v).first.id;
                          if (v == null || v.isEmpty) {
                            selectedSousCategorie = "";
                          } else {
                            final sousCats = sousCategoriesTest
                                .where((sc) => sc.categorieNom == v)
                                .toList();

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
                            sousCategories: sousCategoriesTest
                                .where((sc) => sc.categorieNom == selectedCategorie)
                                .toList(),
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
                      items: sousCategoriesTest
                          .where((sc) => sc.categorieNom == selectedCategorie)
                          .map((sc) => sc.nom)
                          .toList(),
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
            const SizedBox(height: 30),
            // Dans _buildFormDetaille, remplacez la section "unitPackaging" par :

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
                      value: selectedUnitemesure,
                      items: translator.uniteMesureDisplayList,
                      onChanged: (v) {
                        setState(() {
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
            ),
          ],
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
              child: ChampAvecLabel(
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
                      onChanged: (_) {
                        produitFormKey.currentState!.validate();
                        calculPrixVenteAuto();
                      },
                      controller: prixController,
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
                      controller: prixController2,
                      enabled: false,
                      obligatoire: true,
                      hint: '250 ${l10n.currency}',
                      numeric: true,
                      onChanged: (_) {
                        produitFormKey.currentState!.validate();
                        calculPrixVenteAuto();
                      },
                      validator: (value) {
                        final prixAchat = double.tryParse(prixController.text) ?? 0;
                        final prixVente = double.tryParse(value ?? "") ?? 0;
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
                          value: service,
                          onChanged: (v) {
                            setState(() {
                              service = v ?? false;
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
                    obligatoire: true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextRadio(
                          value: seuil,
                          onChanged: (v) {
                            setState(() {
                              seuil = v ?? false;
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
                              obligatoire: !seuil,
                              controller: seuilMinController,
                              hint: "5",
                              numeric: true,
                              onChanged: (_) {
                                produitFormKey.currentState!.validate();
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          ChampAvecLabel(
                            label: l10n.maxThreshold,
                            obligatoire: true,
                            child: TextChampL(
                              obligatoire: !seuil,
                              controller: seuilMaxController,
                              hint: "50",
                              numeric: true,
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
                      onTap: () => pickDate(context, dateController),
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  // Dans _buildFormDetaille, remplacez l'appel chipsSelector pour les magasins :

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
                          .toList(), // Le magasin System n'est pas supprimable
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
                  ),
                  const SizedBox(height: 10),
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