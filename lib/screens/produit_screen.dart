import 'package:caisse_dz/Services/excel_apercu.dart';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseParam.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Pack.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/Services/Remise.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_detail.dart';
import 'package:caisse_dz/core/dialog/pack/pack_detail.dart';
import 'package:caisse_dz/core/dialog/pack/pack_nouveau.dart';
import 'package:caisse_dz/core/dialog/remise/remise_detail.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_detail.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_categorie.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_pack.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_remise.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheure_souscateg.dart';
import 'package:caisse_dz/core/widget/header_module.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/card/card_product.dart';
import 'package:caisse_dz/core/widget/time_date_widget.dart';
import 'package:caisse_dz/core/widget/connection_status_bar.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_actif.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_modif.dart';
import 'package:caisse_dz/core/dialog/categorie/categorie_nouveau.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/dialog/pack/pack_actif.dart';
import 'package:caisse_dz/core/dialog/pack/pack_modif.dart';
import 'package:caisse_dz/core/dialog/produit/produit_actif.dart';
import 'package:caisse_dz/core/dialog/entree/entree_nouveau.dart';
import 'package:caisse_dz/core/dialog/produit/produit_categorie_sous_categorie.dart';
import 'package:caisse_dz/core/dialog/produit/produit_detail.dart';
import 'package:caisse_dz/core/dialog/produit/produit_modif.dart';
import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/core/dialog/produit/produit_pack.dart';
import 'package:caisse_dz/core/dialog/produit/produit_remise.dart';
import 'package:caisse_dz/core/dialog/remise/remise_actif.dart';
import 'package:caisse_dz/core/dialog/remise/remise_modif.dart';
import 'package:caisse_dz/core/dialog/remise/remise_nouveau.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_actif.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_modif.dart';
import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_nouveau.dart';
import 'package:caisse_dz/core/tableau/Produit/tableau_produit.dart';
import 'package:caisse_dz/core/tableau/categorie/categorie_tableau.dart';
import 'package:caisse_dz/core/tableau/pack/tableau_pack.dart';
import 'package:caisse_dz/core/tableau/remise/tableau_remise.dart';
import 'package:caisse_dz/core/tableau/sous_categorie/tableau_sous_categorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/barcode_scan_listener.dart';
import 'package:caisse_dz/core/utilis/constant.dart';
import 'package:caisse_dz/core/widget/account.dart';
import 'package:caisse_dz/core/widget/afficheur/afficheur_produit_glolbal.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/produit_code_detail.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

// Valeurs sélectionnées dans le filtre
String? selectedEtatFilter;
String? selectedCategorieFilter;
String? selectedSousCategorieFilter;
String? selectedMarqueFilter;
String typeMargecalcul = "Montant";

class ProduitScreen extends StatefulWidget {
  const ProduitScreen({super.key});

  @override
  State<ProduitScreen> createState() => _ProduitScreenState();
}

class _ProduitScreenState extends State<ProduitScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late BarcodeScanListener _barcodeScanListener;

  // ✅ Constantes pour les index des tabs
  static const int TAB_PRODUIT = 0;
  static const int TAB_CATEGORIE = 1;
  static const int TAB_SOUS_CATEGORIE = 2;
  static const int TAB_REMISE = 3;
  static const int TAB_PACK = 4;

  late List<String> categorieFilterOptions = categoriesTest
      .map((c) => c.nom)
      .toSet()
      .toList();
  late List<String> sousCategorieFilterOptions = sousCategoriesTest
      .map((sc) => sc.nom)
      .toSet()
      .toList();

  bool filtresActifs = false;
  // ✅ Plus besoin de selectedCardIndex, on utilise _tabController.index

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _searchControllerPack = TextEditingController();
  final TextEditingController _searchControllerRemise = TextEditingController();
  final TextEditingController _searchControllerCategorie = TextEditingController();
  final TextEditingController _searchControllerSousCategorie = TextEditingController();

  Color colorbuttonactionicon = Appstyle.violet;
  Color colorbuttonactionicon2 = Appstyle.gris;
  Color colorbuttonactionicon3 = Appstyle.blueC;
  Color colorbuttonactionicon4 = Appstyle.maron;
  Color colorbuttonactionicon5 = Appstyle.indigo;
  Color colorbuttonactionicon6 = Appstyle.jaune;

  double? prixAchatMin;
  double? prixAchatMax;
  double? prixVenteMin;
  double? prixVenteMax;
  String nombre_produit = "4122";
  String nombre_categorie = "20";
  String nombre_sous_categorie = "12";
  String nombre_remise = "5";
  String nombre_pack = "8";

  List<Produit> produitsSelectionnes = [];

  // Onglet Produit : affichage en cards (CardProduct, comme la recherche
  // produit de la caisse) au lieu du tableau. Mêmes données
  // (produitsFiltres) et même sélection (produitsSelectionnes) : filtres,
  // exports et boutons d'action fonctionnent à l'identique.
  bool affichageCardProduit = false;
  final ScrollController _scrollCardsProduit = ScrollController();
  List<Categorie> categoriesSelectionnes = [];
  List<SousCategorie> souscategoriesSelectionnes = [];
  List<Remise> remisesSelectionnes = [];
  List<Pack> packsSelectionnes = [];
  List<Produit> produitsFiltres = [];
  List<Pack> packsFiltres = [];
  List<Categorie> categoriesFiltres = [];
  List<SousCategorie> souscategoriesFiltres = [];
  List<Remise> remiseFiltres = [];
  List<List<Map<String, dynamic>>> actionButtons = [];

  List<Pack> packsTest = [];
  List<Remise> remisesTest = [];
  List<Produit> produitsTest = [];
  List<SousCategorie> sousCategoriesTest = [];
  List<Fournisseur> fournisseursTest = [];
  List<Categorie> categoriesTest = [];
  List<Utilisateur> utilisateursTest = [];

  // Quantité par produit calculée depuis le journal des mouvements (voir
  // MouvementsServices.totauxParProduit) — remplace Produit.quantite pour
  // l'affichage, filtrable par magasin. null = tous magasins confondus.
  Map<String, double> quantitesParMagasin = {};
  String? magasinFiltreCode;
  bool _magasinFiltreInitialise = false;
  List<Magasin> magasinsDisponiblesProduit = [];

  Future<void> _chargerQuantitesParMagasin() async {
    final auth = Provider.of<AuthState>(context, listen: false);
    final totaux = await MouvementsServices.totauxPourFiltre(
      magasinCode: magasinFiltreCode,
      magasinsConsultation: auth.magasinsConsultation,
    );
    if (!mounted) return;
    setState(() => quantitesParMagasin = totaux.quantites);
  }

  // ✅ Codes-barres/codes secondaires (produit_code_detail), pour les produits
  // à plusieurs codes-barres : produitCode -> textes recherchables en minuscule.
  Map<String, List<String>> codeDetailsSecondairesMap = {};

  void _buildCodeDetailsSecondairesMap(List<ProduitCodeDetail> details) {
    codeDetailsSecondairesMap = {};
    for (var d in details) {
      codeDetailsSecondairesMap
          .putIfAbsent(d.produitCode, () => [])
          .add(d.CodeBar.toLowerCase());
    }
  }
  Paramters ParamtersDB = Paramters(
      id: 0,
      TauxMargePerncetage: 0,
      TauxMargeMontant: 0,
      Maximum: 0,
      Minimum: 0,
      typeMarge: "Montant",
      Datecree: DateTime.now(),
      creeParCode: "IMAD2"
  );
  bool isLoading = true;
  // Garde anti-double-clic pour l'export Excel : sans elle, un double-clic
  // sur "Extract" pendant la génération (synchrone, potentiellement lente)
  // lance deux exports en parallèle, chacun avec son propre showDialog(
  // barrierDismissible:false)/Navigator.pop — les pops peuvent alors fermer
  // le mauvais dialog et laisser un spinner bloquant à l'écran pour de bon.
  bool _exportEnCours = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          vider_les_liste_selectionne();
        });
      }
    });
    _barcodeScanListener = BarcodeScanListener(onScan: _onBarcodeScanned)..start();
    loadAllData();
  }

  /// Bascule tableau ⇄ cards de l'onglet Produit. La sélection est vidée :
  /// le tableau, recréé au retour, repart sans sélection — les deux vues
  /// restent ainsi cohérentes avec les boutons d'action.
  Widget _boutonAffichageProduit(AppLocalizations l10n) {
    return Tooltip(
      message: affichageCardProduit ? l10n.tableView : l10n.cardView,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() {
          affichageCardProduit = !affichageCardProduit;
          produitsSelectionnes = [];
        }),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Appstyle.indigo,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            affichageCardProduit ? Icons.view_list : Icons.grid_view,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }

  /// Cards des produits filtrés. Clic = sélectionner / désélectionner
  /// (sélection multiple, comme les cases du tableau) ; double-clic =
  /// détail, comme le double-clic sur une ligne du tableau.
  Widget _grilleCardsProduits(AppLocalizations l10n) {
    if (produitsFiltres.isEmpty) {
      return Center(child: Text(l10n.noData, style: Appstyle.textSB.copyWith(color: Appstyle.gris)));
    }
    final codesSelectionnes = produitsSelectionnes.map((p) => p.code).toSet();
    final toutSelectionne = codesSelectionnes.length == produitsFiltres.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Checkbox(
              value: toutSelectionne
                  ? true
                  : codesSelectionnes.isEmpty
                      ? false
                      : null,
              tristate: true,
              activeColor: Appstyle.violet,
              onChanged: (_) => setState(() {
                produitsSelectionnes = toutSelectionne ? [] : List.of(produitsFiltres);
              }),
            ),
            Text(
              "${l10n.selectAll} (${codesSelectionnes.length}/${produitsFiltres.length})",
              style: Appstyle.textSB,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Scrollbar(
            controller: _scrollCardsProduit,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollCardsProduit,
              child: SectionDecorationFiltre(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      for (final p in produitsFiltres)
                        CardProduct(
                          couleur: Appstyle.Tblanc,
                          iconPath: 'assets/icons/sidebar/produit_icon.png',
                          hasRemise: p.remiseId != null && p.remiseId != 0,
                          text1: p.nom,
                          text2: "${p.prixVente} ${l10n.currency}",
                          photo: p.photo,
                          sousCategorieId: p.sousCategorieId,
                          quantite: quantitesParMagasin[p.code] ?? 0,
                          actif: p.etat,
                          selected: codesSelectionnes.contains(p.code),
                          seuil: ParamtersDB.Minimum,
                          onTap: () => setState(() {
                            produitsSelectionnes = codesSelectionnes.contains(p.code)
                                ? produitsSelectionnes.where((s) => s.code != p.code).toList()
                                : [...produitsSelectionnes, p];
                          }),
                          onDoubleTap: () => ProduitDetail(context, p),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _barcodeScanListener.stop();
    _tabController.dispose();
    _scrollCardsProduit.dispose();
    super.dispose();
  }

  // ✅ Scan lecteur code-barres/QR : bascule sur l'onglet Produit si besoin et
  // remplit le champ de recherche avec le code scanné (remplace tout texte déjà saisi).
  // Ignoré si un dialog est ouvert au-dessus de l'écran (route plus "current"),
  // pour que le scan profite au dialog ouvert et non à l'écran en arrière-plan.
  void _onBarcodeScanned(String rawCode) {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return;
    final code = rawCode.trim();
    if (code.isEmpty) return;

    if (_tabController.index != TAB_PRODUIT) {
      _tabController.animateTo(TAB_PRODUIT);
    }

    setState(() {
      filtresActifs = true;
      _searchController.text = code;
      appliquerFiltre();
    });
  }

  Future<void> _exportCurrentModuleToExcel({bool enPdf = false}) async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    try {
      final l10n = AppLocalizations.of(context);
      final translator = ListsConstTranslator(l10n);

      // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
      final currentTab = _tabController.index;

      List<dynamic> dataToExport = [];
      String moduleName = '';
      String sheetName = '';
      File? excelFile;

      // Determine which module is active based on tab index
      switch (currentTab) {
        case TAB_PRODUIT: // 0 - Produits
          dataToExport = filtresActifs ? produitsFiltres : produitsTest;
          moduleName = l10n.produit;
          sheetName = 'Produits';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateProduitsExcel(
              produits: dataToExport.cast<Produit>(),
              categories: categoriesTest,
              sousCategories: sousCategoriesTest,
              remises: remisesTest,
              l10n: l10n,
              translator: translator,
              seuilMin: ParamtersDB.Minimum,
              seuilMax: ParamtersDB.Maximum,
              quantites: quantitesParMagasin,
            );
          }
          break;
        case TAB_CATEGORIE: // 1 - Categories
          dataToExport = categoriesFiltres;
          moduleName = l10n.categorie;
          sheetName = 'Categories';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateCategoriesExcel(
              categories: dataToExport.cast<Categorie>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_SOUS_CATEGORIE: // 2 - Sous Categories
          dataToExport = souscategoriesFiltres;
          moduleName = l10n.sousCategorie;
          sheetName = 'SousCategories';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateSousCategoriesExcel(
              sousCategories: dataToExport.cast<SousCategorie>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_REMISE: // 3 - Remises
          dataToExport = remiseFiltres;
          moduleName = l10n.remise;
          sheetName = 'Remises';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generateRemisesExcel(
              remises: dataToExport.cast<Remise>(),
              l10n: l10n,
            );
          }
          break;
        case TAB_PACK: // 4 - Packs
          dataToExport = packsFiltres;
          moduleName = l10n.pack;
          sheetName = 'Packs';
          if (dataToExport.isNotEmpty) {
            excelFile = await ExcelGenerator.generatePacksExcel(
              packs: dataToExport.cast<Pack>(),
              l10n: l10n,
            );
          }
          break;
      }

      if (dataToExport.isEmpty) {
        await InformationDialog(
          context: context,
          titre_type_message: l10n.information,
          titre_concerne: moduleName,
          message: l10n.noDataToExport,
        );
        return;
      }

      if (excelFile == null) {
        throw Exception('Failed to generate Excel file');
      }

      final fichier = excelFile;
      // Extract PDF : même fichier que l'export Excel, mis en page en PDF.
      if (enPdf) {
        await ouvrirApercuPdfDepuisExcel(context, fichier: fichier, titre: moduleName);
        return;
      }

      final excel = await executerAvecSpinner(context, () async => Excel.decodeBytes(await fichier.readAsBytes()));

      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        if (data.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('No data found in Excel file'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: moduleName,
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  Future<void> _exportSelectedToExcel() async {
    if (_exportEnCours) return;
    setState(() => _exportEnCours = true);
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);

    // ✅ Utilisation de _tabController.index au lieu de selectedCardIndex
    final currentTab = _tabController.index;

    List<dynamic> selectedData = [];
    String moduleName = '';
    String sheetName = '';
    File? excelFile;

    // Determine which module is active and get selected items
    switch (currentTab) {
      case TAB_PRODUIT: // 0 - Produits
        if (produitsSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.produit,
            message: l10n.noProductSelected,
          );
          setState(() => _exportEnCours = false);
          return;
        }
        selectedData = produitsSelectionnes;
        moduleName = l10n.produit;
        sheetName = 'Produits';
        excelFile = await ExcelGenerator.generateProduitsExcel(
          produits: selectedData.cast<Produit>(),
          categories: categoriesTest,
          sousCategories: sousCategoriesTest,
          remises: remisesTest,
          l10n: l10n,
          translator: translator,
          seuilMin: ParamtersDB.Minimum,
          seuilMax: ParamtersDB.Maximum,
          quantites: quantitesParMagasin,
        );
        break;
      case TAB_CATEGORIE: // 1 - Categories
        if (categoriesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.categorie,
            message: l10n.noCategorySelected,
          );
          setState(() => _exportEnCours = false);
          return;
        }
        selectedData = categoriesSelectionnes;
        moduleName = l10n.categorie;
        sheetName = 'Categories';
        excelFile = await ExcelGenerator.generateCategoriesExcel(
          categories: selectedData.cast<Categorie>(),
          l10n: l10n,
        );
        break;
      case TAB_SOUS_CATEGORIE: // 2 - Sous Categories
        if (souscategoriesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.sousCategorie,
            message: l10n.noSubCategorySelected,
          );
          setState(() => _exportEnCours = false);
          return;
        }
        selectedData = souscategoriesSelectionnes;
        moduleName = l10n.sousCategorie;
        sheetName = 'SousCategories';
        excelFile = await ExcelGenerator.generateSousCategoriesExcel(
          sousCategories: selectedData.cast<SousCategorie>(),
          l10n: l10n,
        );
        break;
      case TAB_REMISE: // 3 - Remises
        if (remisesSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.remise,
            message: l10n.noDiscountSelected,
          );
          setState(() => _exportEnCours = false);
          return;
        }
        selectedData = remisesSelectionnes;
        moduleName = l10n.remise;
        sheetName = 'Remises';
        excelFile = await ExcelGenerator.generateRemisesExcel(
          remises: selectedData.cast<Remise>(),
          l10n: l10n,
        );
        break;
      case TAB_PACK: // 4 - Packs
        if (packsSelectionnes.isEmpty) {
          await InformationDialog(
            context: context,
            titre_type_message: l10n.information,
            titre_concerne: l10n.pack,
            message: l10n.noPackSelected,
          );
          setState(() => _exportEnCours = false);
          return;
        }
        selectedData = packsSelectionnes;
        moduleName = l10n.pack;
        sheetName = 'Packs';
        excelFile = await ExcelGenerator.generatePacksExcel(
          packs: selectedData.cast<Pack>(),
          l10n: l10n,
        );
        break;
    }

    try {
      final fichier = excelFile;
      if (fichier == null) {
        throw Exception('Failed to generate Excel file');
      }

      final excel = await executerAvecSpinner(context, () async => Excel.decodeBytes(await fichier.readAsBytes()));

      var sheet = excel.tables[sheetName];

      if (sheet == null && excel.tables.isNotEmpty) {
        sheet = excel.tables.values.first;
      }

      if (sheet != null) {
        List<List<dynamic>> data = [];
        List<String> headers = [];

        // Extract headers
        for (int col = 0; col < sheet.maxColumns; col++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
          if (cell.value != null && cell.value.toString().isNotEmpty) {
            headers.add(cell.value.toString());
          }
        }

        // Extract data rows
        for (int row = 1; row < sheet.maxRows; row++) {
          List<dynamic> rowData = [];
          bool hasData = false;

          for (int col = 0; col < sheet.maxColumns; col++) {
            final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
            if (cell.value != null && cell.value.toString().isNotEmpty) {
              rowData.add(cell.value);
              hasData = true;
            } else {
              rowData.add('-');
            }
          }

          if (hasData) {
            data.add(rowData);
          }
        }

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ExcelPreviewDialog(
            data: data,
            headers: headers,
            title: "$moduleName (${l10n.selected})",
            l10n: l10n,
            excelFile: excelFile,
            onSave: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.exportSuccess),
                  backgroundColor: Colors.green,
                ),
              );
            },
            onShare: () {
              Navigator.pop(context);
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find data sheet in Excel file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Excel export error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${AppLocalizations.of(context)!.exportError}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _exportEnCours = false);
    }
  }

  Future<void> _initActionButtons(AppLocalizations l10n, ListsConstTranslator translator) async {
    actionButtons = [
      // Pour Produit: 6 Boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.length == 1) {
              ProduitDetail(context, produitsSelectionnes.first);
            } else if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.selectSingleProductForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/supprimer_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              await AnnulerProduit(context, produitsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                context: context,
                message: l10n.noProductSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.length == 1) {
              await ProduitModif(context, produitsSelectionnes.first);
              await loadAllData();
            } else if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else {
              await InformationDialog(
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.selectSingleProductToModify,
                context: context,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon4,
          'icon': 'assets/icons/cardwidget/categorie_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isNotEmpty) {
              final saved = await CategorieSousCategorieProduit(context, produitsSelectionnes);
              if (saved == true) await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon5,
          'icon': 'assets/icons/cardwidget/remise_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else if (remisesTest.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountExists,
              );
            } else {
              final saved = await RemiseProduit(context, produitsSelectionnes);
              if (saved == true) await loadAllData();
            }
          },
        },
        {
          'color': colorbuttonactionicon6,
          'icon': 'assets/icons/cardwidget/pack_icon.png',
          'onPressed': () async {
            if (produitsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.produit,
                message: l10n.noProductSelected,
              );
            } else if (packsTest.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackExists,
              );
            } else {
              final saved = await PackProduit(context, produitsSelectionnes);
              if (saved == true) await loadAllData();
            }
          },
        },
      ],

      // Pour Catégorie: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.length == 1) {
              CategorieDetail(
                context,
                categoriesSelectionnes.first,
                nombreSousCategories: sousCategoriesTest
                    .where((sc) => sc.categorieCode == categoriesSelectionnes.first.code)
                    .length,
              );
            } else if (categoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.selectSingleCategoryForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.isNotEmpty) {
              bool contientNonSupprimable = categoriesSelectionnes.any(
                    (cate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Categorie" && p.code == cate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.categorie,
                  message: l10n.cannotDeleteSystemCategory,
                );
              } else {
                await AnnulerCategorie(context, categoriesSelectionnes);
                await loadAllData();
              }
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (categoriesSelectionnes.length == 1) {
              bool contientNonSupprimable = categoriesSelectionnes.any(
                    (cate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Categorie" && p.code == cate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.categorie,
                  message: l10n.cannotModifySystemCategory,
                );
              } else {
                await CategorieModif(context, categoriesSelectionnes.first);
                await loadAllData();
              }
            } else if (categoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.noCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.categorie,
                message: l10n.selectSingleCategoryToModify,
              );
            }
          },
        },
      ],

      // Pour Remise: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.length == 1) {
              RemiseDetail(context, remisesSelectionnes.first);
            } else if (remisesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.selectSingleDiscountForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.isNotEmpty) {
              await AnnulerRemise(context, remisesSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (remisesSelectionnes.length == 1) {
              await RemiseModif(context, remisesSelectionnes.first);
              await loadAllData();
            } else if (remisesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.noDiscountSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.remise,
                message: l10n.selectSingleDiscountToModify,
              );
            }
          },
        },
      ],

      // Pour Pack: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.length == 1) {
              PackDetail(context, packsSelectionnes.first);
            } else if (packsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.selectSinglePackForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.isNotEmpty) {
              await ActiverPack(context, packsSelectionnes);
              await loadAllData();
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (packsSelectionnes.length == 1) {
              await PackModif(context, packsSelectionnes.first);
              await loadAllData();
            } else if (packsSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.noPackSelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.pack,
                message: l10n.selectSinglePackToModify,
              );
            }
          },
        },
      ],

      // Pour Sous Catégorie: 3 boutons
      [
        {
          'color': colorbuttonactionicon,
          'icon': 'assets/icons/action/detail_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.length == 1) {
              SousCategorieDetail(
                context,
                souscategoriesSelectionnes.first,
                nombreProduits: produitsTest
                    .where((p) => p.sousCategorieId == souscategoriesSelectionnes.first.id)
                    .length,
              );
            } else if (souscategoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.selectSingleSubCategoryForDetail,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon2,
          'icon': 'assets/icons/action/annuler_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.isNotEmpty) {
              bool contientNonSupprimable = souscategoriesSelectionnes.any(
                    (scate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Sous Categorie" && p.code == scate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.sousCategorie,
                  message: l10n.cannotDeleteSystemSubCategory,
                );
              } else {
                await AnnulerSousCategorie(context, souscategoriesSelectionnes);
                await loadAllData();
              }
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            }
          },
        },
        {
          'color': colorbuttonactionicon3,
          'icon': 'assets/icons/action/edit_icon.png',
          'onPressed': () async {
            if (souscategoriesSelectionnes.length == 1) {
              bool contientNonSupprimable = souscategoriesSelectionnes.any(
                    (scate) => ListsConst.nonSupprimablePacks.any(
                      (p) => p.nom == "Sous Categorie" && p.code == scate.code,
                ),
              );

              if (contientNonSupprimable) {
                await InformationDialog(
                  context: context,
                  titre_type_message: l10n.information,
                  titre_concerne: l10n.sousCategorie,
                  message: l10n.cannotModifySystemSubCategory,
                );
              } else {
                await SousCategorieModif(context, souscategoriesSelectionnes.first);
                await loadAllData();
              }
            } else if (souscategoriesSelectionnes.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.noSubCategorySelected,
              );
            } else {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.sousCategorie,
                message: l10n.selectSingleSubCategoryToModify,
              );
            }
          },
        },
      ],
    ];
    if (mounted) setState(() {});
  }

// Modifiez la fonction loadAllData pour être plus robuste
  Future<void> loadAllData() async {
    try {
      if (!mounted) return;
      setState(() => isLoading = true);

      final Param = await ParamServices.getParam();

      final pack = await PackServices.getAllPacks();
      // ✅ Recale actif/inactif sur la période [debut, fin] de chaque remise
      // avant affichage, pour que le statut reste toujours à jour même sans
      // action manuelle (remise qui démarre ou expire avec le temps).
      final remise = await RemiseServices.synchroniserEtatsSelonDates();
      final produit = await ProduitServices.getAllProduits();
      final categorie = await CategorieServices.getAllCategorie();
      final sous = await SousCategoriesServices.getAllSousCategorie();
      final fournisseur = await FournisseurServices.getAllFournisseurs();
      final codeDetails = await ProduitServices.getAllCodeDetails();
      final utilisateurs = await UtilisateurServices.getAllUtilisateurs();
      final magasins = (await MagasinServices.getAllMagasins()).where((m) => m.etat).toList();

      final auth = Provider.of<AuthState>(context, listen: false);
      // Quantités (multi-magasin) : par défaut la SOMME des magasins que
      // l'utilisateur peut consulter (les siens ; tous pour un Admin ou un
      // rôle « Voir le stock de tous les magasins »). Le filtre permet de
      // n'en voir qu'un, parmi ceux-là uniquement.
      if (magasinFiltreCode != null && !auth.peutConsulterMagasin(magasinFiltreCode!)) {
        magasinFiltreCode = null;
      }
      _magasinFiltreInitialise = true;

      final totaux = await MouvementsServices.totauxPourFiltre(
        magasinCode: magasinFiltreCode,
        magasinsConsultation: auth.magasinsConsultation,
      );

      if (!mounted) return;

      setState(() {
        ParamtersDB = Param;
        magasinsDisponiblesProduit = magasins;
        quantitesParMagasin = totaux.quantites;

        // Mettre à jour les listes principales
        utilisateursTest = utilisateurs;
        packsTest = pack;
        packsFiltres = List.from(pack); // Créer une nouvelle liste

        remisesTest = remise;
        remiseFiltres = List.from(remise); // Créer une nouvelle liste

        sousCategoriesTest = sous;
        souscategoriesFiltres = List.from(sous); // Créer une nouvelle liste

        categoriesTest = categorie;
        categoriesFiltres = List.from(categorie); // Créer une nouvelle liste

        fournisseursTest = fournisseur;

        produitsTest = produit;
        produitsFiltres = List.from(produit); // Créer une nouvelle liste

        _buildCodeDetailsSecondairesMap(codeDetails);

        // Mettre à jour les compteurs
        nombre_produit = produitsTest.length.toString();
        nombre_categorie = categoriesTest.length.toString();
        nombre_sous_categorie = sousCategoriesTest.length.toString();
        nombre_remise = remisesTest.length.toString();
        nombre_pack = packsTest.length.toString();

        // Réappliquer les filtres si nécessaire
        _reapplyFilters();

        produitsSelectionnes.clear();
        categoriesSelectionnes.clear();
        souscategoriesSelectionnes.clear();
        remisesSelectionnes.clear();
        packsSelectionnes.clear();

        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => isLoading = false);
      }
      debugPrint("Erreur chargement : $e");
    }
  }

// Ajoutez cette méthode pour réappliquer les filtres après rechargement
  void _reapplyFilters() {
    // Réappliquer le filtre pour les packs
    if (_searchControllerPack.text.isNotEmpty) {
      appliquefiltrePack();
    } else {
      packsFiltres = List.from(packsTest);
    }

    // Réappliquer le filtre pour les remises
    if (_searchControllerRemise.text.isNotEmpty) {
      appliquefiltreRemise();
    } else {
      remiseFiltres = List.from(remisesTest);
    }

    // Réappliquer le filtre pour les catégories
    if (_searchControllerCategorie.text.isNotEmpty) {
      appliquefiltreCatgorie();
    } else {
      categoriesFiltres = List.from(categoriesTest);
    }

    // Réappliquer le filtre pour les sous-catégories
    if (_searchControllerSousCategorie.text.isNotEmpty) {
      appliquefiltreSousCatgorie();
    } else {
      souscategoriesFiltres = List.from(sousCategoriesTest);
    }

    // Réappliquer le filtre pour les produits
    if (filtresActifs) {
      appliquerFiltre();
    } else {
      produitsFiltres = List.from(produitsTest);
    }
  }

  // ✅ Vrai si au moins un champ de filtre produit est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresProduitActifs =>
      (selectedCategorieFilter != null && selectedCategorieFilter!.isNotEmpty) ||
      (selectedSousCategorieFilter != null && selectedSousCategorieFilter!.isNotEmpty) ||
      (selectedEtatFilter != null && selectedEtatFilter!.isNotEmpty) ||
      (selectedMarqueFilter != null && selectedMarqueFilter!.isNotEmpty) ||
      prixAchatMin != null ||
      prixAchatMax != null ||
      prixVenteMin != null ||
      prixVenteMax != null ||
      _searchController.text.isNotEmpty;

  void appliquerFiltre() {
    produitsFiltres = produitsTest.where((p) {
      final searchText = _searchController.text.toLowerCase();
      final nomCategorieP = categoriesTest.where((c) => c.id == p.categorieId).firstOrNull?.nom ?? '';
      final nomSousCategorieP = sousCategoriesTest.where((sc) => sc.id == p.sousCategorieId).firstOrNull?.nom ?? '';
      final catOk = selectedCategorieFilter == null || selectedCategorieFilter!.isEmpty || nomCategorieP == selectedCategorieFilter;
      final sousCatOk = selectedSousCategorieFilter == null || selectedSousCategorieFilter!.isEmpty || nomSousCategorieP == selectedSousCategorieFilter;
      final marqueOk = selectedMarqueFilter == null || selectedMarqueFilter!.isEmpty || p.marque == selectedMarqueFilter;
      final searchOk = searchText.isEmpty ||
          '${p.searchableText} $nomCategorieP $nomSousCategorieP'.toLowerCase().contains(searchText) ||
          (codeDetailsSecondairesMap[p.code]?.any((c) => c.contains(searchText)) ?? false);
      final prixAchatOk = (prixAchatMin == null || p.prixAchat >= prixAchatMin!) &&
          (prixAchatMax == null || p.prixAchat <= prixAchatMax!);
      final prixVenteOk = (prixVenteMin == null || p.prixVente >= prixVenteMin!) &&
          (prixVenteMax == null || p.prixVente <= prixVenteMax!);
      final etatOk = selectedEtatFilter == null ||
          selectedEtatFilter == "" ||
          (selectedEtatFilter == "Actif" && p.etat) ||
          (selectedEtatFilter == "Inactif" && !p.etat);

      return catOk && sousCatOk && marqueOk && prixAchatOk && prixVenteOk && etatOk && searchOk;
    }).toList();

    if ((selectedCategorieFilter == null || selectedCategorieFilter!.isEmpty) &&
        (selectedSousCategorieFilter == null || selectedSousCategorieFilter!.isEmpty) &&
        (selectedEtatFilter == null || selectedEtatFilter!.isEmpty) &&
        (selectedMarqueFilter == null || selectedMarqueFilter!.isEmpty) &&
        prixAchatMin == null &&
        prixAchatMax == null &&
        prixVenteMin == null &&
        prixVenteMax == null &&
        _searchController.text.isEmpty) {
      produitsFiltres = produitsTest;
    }
  }

  void appliquefiltrePack() {
    final searchText = _searchControllerPack.text.toLowerCase();
    if (searchText.isEmpty) {
      packsFiltres = packsTest;
      return;
    }
    packsFiltres = packsTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreRemise() {
    final searchText = _searchControllerRemise.text.toLowerCase();
    if (searchText.isEmpty) {
      remiseFiltres = remisesTest; // Créer une nouvelle liste
      return;
    }
    remiseFiltres = remisesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreCatgorie() {
    final searchText = _searchControllerCategorie.text.toLowerCase();
    if (searchText.isEmpty) {
      categoriesFiltres = categoriesTest;
      return;
    }
    categoriesFiltres = categoriesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void appliquefiltreSousCatgorie() {
    final searchText = _searchControllerSousCategorie.text.toLowerCase();
    if (searchText.isEmpty) {
      souscategoriesFiltres = sousCategoriesTest;
      return;
    }
    souscategoriesFiltres = sousCategoriesTest.where((c) {
      return c.searchableText.contains(searchText);
    }).toList();
  }

  void supprimerFilter() {
    selectedCategorieFilter = null;
    selectedSousCategorieFilter = null;
    selectedMarqueFilter = null;
    selectedEtatFilter = null;
    prixAchatMin = null;
    prixAchatMax = null;
    prixVenteMin = null;
    prixVenteMax = null;
    _searchController.clear();
  }

  void vider_les_liste_selectionne() {
    categoriesSelectionnes.clear();
    souscategoriesSelectionnes.clear();
    remisesSelectionnes.clear();
    packsSelectionnes.clear();
    produitsSelectionnes.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final translator = ListsConstTranslator(l10n);
    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? '';

    if (actionButtons.isEmpty) {
      _initActionButtons(l10n, translator);
    }

    // ✅ Noms des tabs
    final tabNames = [
      l10n.produit,
      l10n.categorie,
      l10n.sousCategorie,
      l10n.remise,
      l10n.pack,
    ];

    // ✅ Icônes des tabs
    final tabIcons = [
      'assets/icons/sidebar/produit_icon.png',
      'assets/icons/cardwidget/categorie_icon.png',
      'assets/icons/cardwidget/sous_catego_icon.png',
      'assets/icons/cardwidget/remise_icon.png',
      'assets/icons/cardwidget/pack_icon.png',
    ];

    // ✅ Compteurs pour les tabs
    final tabCounts = [
      nombre_produit,
      nombre_categorie,
      nombre_sous_categorie,
      nombre_remise,
      nombre_pack,
    ];

    // ✅ Map index vers actionButtons
    final Map<int, int> actionIndexMap = {
      TAB_PRODUIT: 0,
      TAB_CATEGORIE: 1,
      TAB_SOUS_CATEGORIE: 4,
      TAB_REMISE: 2,
      TAB_PACK: 3,
    };

    // ✅ Index actuel du tab
    final currentTab = _tabController.index;
    final int actionIndex = actionIndexMap[currentTab]!;

    return Scaffold(
      backgroundColor: Appstyle.violetC,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final screenHeight = constraints.maxHeight;
          final screenWidth = constraints.maxWidth;
          const minHeight = Constant.minHeight;
          const minWidth = Constant.minWidth;

          final adjustedWidth = screenWidth < minWidth ? minWidth : screenWidth;
          final adjustedHeight = screenHeight < minHeight ? minHeight : screenHeight;

          final paddingV = adjustedHeight * 0.02;
          final paddingH = adjustedWidth * 0.02;

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: minWidth,
                minHeight: minHeight,
              ),
              child: SizedBox(
                width: adjustedWidth,
                height: adjustedHeight,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// HEADER
                              HeaderModule(
                                gradientColors: [Appstyle.Tblanc, Appstyle.Tblanc],
                                child: Row(
                                  children: [
                                    Row(
                                      children: [
                                        Image.asset(
                                          "assets/icons/sidebar/produit_icon.png",
                                          width: 40,
                                          color: Appstyle.blueF,
                                        ),
                                        const SizedBox(width: 10),
                                        Text(
                                          "${l10n.produit} (${tabNames[currentTab]})",
                                          style: Appstyle.textXLB.copyWith(
                                            color: Appstyle.blueF,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Row(
                                      children: [
                                        const ConnectionStatusBar(),
                                        const SizedBox(width: 20),
                                        TimeDateWidget(
                                          iconHeure: "assets/icons/hour_icon.png",
                                          iconDate: "assets/icons/agenda_icon.png",
                                        ),
                                        const SizedBox(width: 20),
                                        AccountWidget(
                                          name: userName,
                                          imageUrl: "assets/images/support.png",
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              SizedBox(height: paddingV / 2),

                              /// ✅ TAB BAR (remplace les CardWidget)
                              /// ✅ TAB BAR - Version avec largeur égale sans isScrollable
                              Container(
                                margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final double tabWidth = constraints.maxWidth / 5; // 5 tabs
                                    return TabBar(
                                      controller: _tabController,
                                      isScrollable: false,
                                      indicator: BoxDecoration(
                                        color: Appstyle.violet,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      labelColor: Colors.white,
                                      unselectedLabelColor: Appstyle.gris,
                                      dividerColor: Colors.transparent,
                                      indicatorSize: TabBarIndicatorSize.tab,
                                      padding: const EdgeInsets.all(6),
                                      labelStyle: Appstyle.textXS.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                      unselectedLabelStyle: Appstyle.textXS.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                      tabs: List.generate(5, (index) {
                                        final isSelected = currentTab == index;
                                        return SizedBox(
                                          width: tabWidth,
                                          child: Tab(
                                            icon: Container(
                                              width: 24,
                                              height: 24,
                                              child: Image.asset(
                                                tabIcons[index],
                                                width: 20,
                                                height: 20,
                                                color: isSelected ? Colors.white : Appstyle.gris,
                                              ),
                                            ),
                                            text: "${tabNames[index]} (${tabCounts[index]})",
                                          ),
                                        );
                                      }),
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: paddingV / 2),

// ═══════════════════════════════════════════════════════════════════════════════
// SECTION PRINCIPALE - GESTION PAR TYPE DE TAB
// ═══════════════════════════════════════════════════════════════════════════════

// ──────────────────────────────────────────────────────────────
// 1. CAS PRODUIT (currentTab == TAB_PRODUIT)
// ──────────────────────────────────────────────────────────────
                              if (currentTab == TAB_PRODUIT)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Afficheur
                                    if (produitsSelectionnes.length == 1)
                                      AfficheurProduit(
                                        produit: produitsSelectionnes.first,
                                        onDetails: () {
                                          ProduitDetail(context, produitsSelectionnes.first);
                                        },
                                      )
                                    else
                                      AfficheurProduitsGlobalWidget(
                                        nombreProduits: produitsTest.length,
                                        nombreCategories: categoriesTest.length,
                                        nombrePacks: packsTest.length,
                                        nombreRemises: remisesTest.length,
                                        nombreSousCategories: sousCategoriesTest.length,
                                      ),

                                    SizedBox(height: paddingV),

                                    // Filtres & Actions
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            MainButton(
                                              text: l10n.filter,
                                              textColor:Appstyle.violet ,
                                              iconColor: Appstyle.violet,
                                              color: Appstyle.Tblanc,
                                              showBadge: _filtresProduitActifs,
                                              icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                                              onPressed: () {
                                                setState(() {
                                                  filtresActifs = !filtresActifs;
                                                  if (!filtresActifs) {
                                                    supprimerFilter();
                                                    appliquerFiltre();
                                                  }
                                                });
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            if (filtresActifs)
                                              MainIconButton(
                                                color: Colors.grey.shade400,
                                                imagePath: 'assets/icons/action/supprimer_icon.png',
                                                onPressed: () {
                                                  setState(() {
                                                    supprimerFilter();
                                                    appliquerFiltre();
                                                  });
                                                },
                                              ),
                                            if (filtresActifs)
                                              SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.extract,
                                              textColor:Colors.green ,
                                              iconColor: Colors.green,
                                              color: Appstyle.Tblanc,
                                              icon: Icons.download,
                                              loading: _exportEnCours,
                                              onPressed: () async {
                                                await _exportCurrentModuleToExcel();
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.extractPdf,
                                              textColor: Colors.red,
                                              iconColor: Colors.red,
                                              color: Appstyle.Tblanc,
                                              icon: Icons.picture_as_pdf,
                                              onPressed: () async {
                                                await _exportCurrentModuleToExcel(enPdf: true);
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                              color: Colors.orange,
                                              onPressed: () async {
                                                await _exportSelectedToExcel();
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            _boutonAffichageProduit(l10n),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            ...actionButtons[actionIndex].map(
                                                  (btn) => Padding(
                                                padding: EdgeInsets.only(right: paddingH / 5),
                                                child: MainIconButton(
                                                  color: btn['color'] as Color,
                                                  onPressed: btn['onPressed'] as void Function(),
                                                  imagePath: btn['icon'] as String,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: paddingH / 4),

                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await ProduitNouveau(
                                                  context,
                                                  // Même enchaînement que caisse_screen.dart : un produit tout
                                                  // juste créé n'a encore aucun stock, on ouvre directement
                                                  // l'Entrée rapide dessus (fournisseur général présélectionné
                                                  // par EntreeNouveau lui-même) pour le stocker immédiatement.
                                                  onCreated: (produit) async {
                                                    await loadAllData();
                                                    await EntreeNouveau(
                                                      context,
                                                      initialProduitCode: produit.code,
                                                      onSuccess: () async {
                                                        await loadAllData();
                                                      },
                                                    );
                                                  },
                                                );
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    // Filtres produit
                                    if (filtresActifs)
                                      Padding(
                                        padding: EdgeInsets.symmetric(vertical: paddingV),
                                        child: filtreproduit(setState, adjustedWidth, l10n, translator),
                                      ),

                                    if (!filtresActifs)
                                      SizedBox(height: paddingV / 2),

                                    // Tableau ou cards
                                    if (affichageCardProduit)
                                      SizedBox(
                                        height: adjustedHeight * 0.72,
                                        child: _grilleCardsProduits(l10n),
                                      )
                                    else
                                    SizedBox(
                                      height: adjustedHeight * 0.72,
                                      child: TableauProduitAdvanced(
                                        // ⚠️ Clé STABLE (pas basée sur produitsFiltres) : une
                                        // ValueKey construite à partir de la liste change
                                        // d'identité à chaque rafraîchissement (nouvelle
                                        // instance de liste), ce qui force Flutter à détruire
                                        // et recréer tout l'état du tableau (tri, sélection,
                                        // pagination) à chaque fois. didUpdateWidget() du
                                        // tableau gère déjà la mise à jour des données en
                                        // conservant cet état.
                                        key: const ValueKey('produit-table'),
                                        produits: produitsFiltres,
                                        categories: categoriesTest,
                                        sousCategories: sousCategoriesTest,
                                        remises: remisesTest,
                                        fournisseurs: fournisseursTest,
                                        seuilMinimum: ParamtersDB.Minimum,
                                        utilisateurs: utilisateursTest,
                                        quantites: quantitesParMagasin,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            produitsSelectionnes = selection;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )

// ──────────────────────────────────────────────────────────────
// 2. CAS CATEGORIE (currentTab == TAB_CATEGORIE)
// ──────────────────────────────────────────────────────────────
                              else if (currentTab == TAB_CATEGORIE)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (categoriesSelectionnes.length == 1)
                                      AfficheurCategorie(
                                        categorie: categoriesSelectionnes.first,
                                        nombreSousCategories: sousCategoriesTest
                                            .where((sc) => sc.categorieCode == categoriesSelectionnes.first.code)
                                            .length,
                                        onDetails: () {
                                          CategorieDetail(
                                            context,
                                            categoriesSelectionnes.first,
                                            nombreSousCategories: sousCategoriesTest
                                                .where((sc) => sc.categorieCode == categoriesSelectionnes.first.code)
                                                .length,
                                          );
                                        },
                                      )
                                    else
                                      AfficheurProduitsGlobalWidget(
                                        nombreProduits: produitsTest.length,
                                        nombreCategories: categoriesTest.length,
                                        nombrePacks: packsTest.length,
                                        nombreRemises: remisesTest.length,
                                        nombreSousCategories: sousCategoriesTest.length,
                                      ),

                                    SizedBox(height: paddingV),

                                    Row(
                                      children: [
                                        filtrcategorie(setState, l10n),
                                        SizedBox(width: paddingH / 3),
                                        MainButton(
                                          text: l10n.extract,
                                          textColor:Colors.green ,
                                          iconColor: Colors.green,
                                          color: Appstyle.Tblanc,
                                          icon: Icons.download,
                                          loading: _exportEnCours,
                                          onPressed: () async {
                                            await _exportCurrentModuleToExcel();
                                          },
                                        ),
                                        SizedBox(width: paddingH / 4),
                                        MainButton(
                                          text: l10n.extractPdf,
                                          textColor: Colors.red,
                                          iconColor: Colors.red,
                                          color: Appstyle.Tblanc,
                                          icon: Icons.picture_as_pdf,
                                          onPressed: () async {
                                            await _exportCurrentModuleToExcel(enPdf: true);
                                          },
                                        ),
                                        SizedBox(width: paddingH / 4),
                                        MainIconButton(
                                          imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                          color: Colors.orange,
                                          onPressed: () async {
                                            await _exportSelectedToExcel();
                                          },
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            ...actionButtons[actionIndex].map(
                                                  (btn) => Padding(
                                                padding: EdgeInsets.only(right: paddingH / 5),
                                                child: MainIconButton(
                                                  color: btn['color'] as Color,
                                                  onPressed: btn['onPressed'] as void Function(),
                                                  imagePath: btn['icon'] as String,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: paddingH / 4),

                                            MainButton(
                                              text: l10n.newWord,
                                              color: Appstyle.crevete,
                                              onPressed: () async {
                                                await CategorieNouveau(context);
                                                await loadAllData();
                                              },
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),

                                    SizedBox(height: paddingV / 2),

                                    SizedBox(
                                      height: adjustedHeight * 0.72,
                                      child: TableauCategorieAdvanced(
                                        key: ValueKey(categoriesFiltres),
                                        categories: categoriesFiltres,
                                        sousCategories: sousCategoriesTest,
                                        utilisateurs: utilisateursTest,
                                        onSelectionChanged: (selection) {
                                          setState(() {
                                            categoriesSelectionnes = selection;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                )

// ──────────────────────────────────────────────────────────────
// 3. CAS SOUS CATEGORIE (currentTab == TAB_SOUS_CATEGORIE)
// ──────────────────────────────────────────────────────────────
                              else if (currentTab == TAB_SOUS_CATEGORIE)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (souscategoriesSelectionnes.length == 1)
                                        AfficheurSousCategorie(
                                          sousCategorie: souscategoriesSelectionnes.first,
                                          nombreProduits: produitsTest
                                              .where((p) => p.sousCategorieId == souscategoriesSelectionnes.first.id)
                                              .length,
                                          onDetails: () {
                                            SousCategorieDetail(
                                              context,
                                              souscategoriesSelectionnes.first,
                                              nombreProduits: produitsTest
                                                  .where((p) => p.sousCategorieId == souscategoriesSelectionnes.first.id)
                                                  .length,
                                            );
                                          },
                                        )
                                      else
                                        AfficheurProduitsGlobalWidget(
                                          nombreProduits: produitsTest.length,
                                          nombreCategories: categoriesTest.length,
                                          nombrePacks: packsTest.length,
                                          nombreRemises: remisesTest.length,
                                          nombreSousCategories: sousCategoriesTest.length,
                                        ),

                                      SizedBox(height: paddingV),

                                      Row(
                                        children: [
                                          filtresouscategorie(setState, l10n),
                                          SizedBox(width: paddingH / 3),
                                          MainButton(
                                            text: l10n.extract,
                                            textColor:Colors.green ,
                                            iconColor: Colors.green,
                                            color: Appstyle.Tblanc,
                                            icon: Icons.download,
                                            loading: _exportEnCours,
                                            onPressed: () async {
                                              await _exportCurrentModuleToExcel();
                                            },
                                          ),
                                          SizedBox(width: paddingH / 4),
                                          MainButton(
                                            text: l10n.extractPdf,
                                            textColor: Colors.red,
                                            iconColor: Colors.red,
                                            color: Appstyle.Tblanc,
                                            icon: Icons.picture_as_pdf,
                                            onPressed: () async {
                                              await _exportCurrentModuleToExcel(enPdf: true);
                                            },
                                          ),
                                          SizedBox(width: paddingH / 4),
                                          MainIconButton(
                                            imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                            color: Colors.orange,
                                            onPressed: () async {
                                              await _exportSelectedToExcel();
                                            },
                                          ),
                                          const Spacer(),
                                          Row(
                                            children: [
                                              ...actionButtons[actionIndex].map(
                                                    (btn) => Padding(
                                                  padding: EdgeInsets.only(right: paddingH / 5),
                                                  child: MainIconButton(
                                                    color: btn['color'] as Color,
                                                    onPressed: btn['onPressed'] as void Function(),
                                                    imagePath: btn['icon'] as String,
                                                  ),
                                                ),
                                              ),
                                              SizedBox(width: paddingH / 4),

                                              MainButton(
                                                text: l10n.newWord,
                                                color: Appstyle.crevete,
                                                onPressed: () async {
                                                  if (categoriesTest.length > 1) {
                                                    await SousCategorieNouveau(context);
                                                    await loadAllData();
                                                  } else {
                                                    await InformationDialog(
                                                      context: context,
                                                      titre_type_message: l10n.information,
                                                      titre_concerne: l10n.sousCategorie,
                                                      message: l10n.needCategoryToCreateSubCategory,
                                                    );
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      SizedBox(height: paddingV / 2),

                                      SizedBox(
                                        height: adjustedHeight * 0.72,
                                        child: TableauSousCategorieAdvanced(
                                          key: ValueKey(souscategoriesFiltres),
                                          sousCategories: souscategoriesFiltres,
                                          produits: produitsTest,
                                          categories: categoriesTest,
                                          utilisateurs: utilisateursTest,
                                          onSelectionChanged: (selection) {
                                            setState(() {
                                              souscategoriesSelectionnes = selection;
                                            });
                                          },
                                        ),
                                      ),
                                    ],
                                  )

// ──────────────────────────────────────────────────────────────
// 4. CAS REMISE (currentTab == TAB_REMISE)
// ──────────────────────────────────────────────────────────────
                                else if (currentTab == TAB_REMISE)
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (remisesSelectionnes.length == 1)
                                          AfficheurRemise(
                                            remise: remisesSelectionnes.first,
                                            nombreProduits: produitsTest
                                                .where((p) => p.remiseId == remisesSelectionnes.first.id)
                                                .length,
                                            onDetails: () {
                                              RemiseDetail(context, remisesSelectionnes.first);
                                            },
                                          )
                                        else
                                          AfficheurProduitsGlobalWidget(
                                            nombreProduits: produitsTest.length,
                                            nombreCategories: categoriesTest.length,
                                            nombrePacks: packsTest.length,
                                            nombreRemises: remisesTest.length,
                                            nombreSousCategories: sousCategoriesTest.length,
                                          ),

                                        SizedBox(height: paddingV),

                                        Row(
                                          children: [
                                            filtrremise(setState, l10n),
                                            SizedBox(width: paddingH / 3),
                                            MainButton(
                                              text: l10n.extract,
                                              textColor:Colors.green ,
                                              iconColor: Colors.green,
                                              color: Appstyle.Tblanc,
                                              icon: Icons.download,
                                              loading: _exportEnCours,
                                              onPressed: () async {
                                                await _exportCurrentModuleToExcel();
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainButton(
                                              text: l10n.extractPdf,
                                              textColor: Colors.red,
                                              iconColor: Colors.red,
                                              color: Appstyle.Tblanc,
                                              icon: Icons.picture_as_pdf,
                                              onPressed: () async {
                                                await _exportCurrentModuleToExcel(enPdf: true);
                                              },
                                            ),
                                            SizedBox(width: paddingH / 4),
                                            MainIconButton(
                                              imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                              color: Colors.orange,
                                              onPressed: () async {
                                                await _exportSelectedToExcel();
                                              },
                                            ),
                                            const Spacer(),
                                            Row(
                                              children: [
                                                ...actionButtons[actionIndex].map(
                                                      (btn) => Padding(
                                                    padding: EdgeInsets.only(right: paddingH / 5),
                                                    child: MainIconButton(
                                                      color: btn['color'] as Color,
                                                      onPressed: btn['onPressed'] as void Function(),
                                                      imagePath: btn['icon'] as String,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: paddingH / 4),

                                                MainButton(
                                                  text: l10n.newWord,
                                                  color: Appstyle.crevete,
                                                  onPressed: () async {
                                                    await RemiseNouveau(
                                                      context,
                                                      onSuccess: () async {
                                                        await loadAllData();
                                                        if (mounted) {
                                                          setState(() {
                                                            remiseFiltres = List.from(remisesTest);
                                                          });
                                                        }
                                                      },
                                                    );
                                                  },
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),

                                        SizedBox(height: paddingV / 2),

                                        SizedBox(
                                          height: adjustedHeight * 0.72,
                                          child: TableauRemiseAdvanced(
                                            key: ValueKey(remiseFiltres),
                                            remises: remiseFiltres,
                                            utilisateurs: utilisateursTest,
                                            onSelectionChanged: (selection) {
                                              setState(() {
                                                remisesSelectionnes = selection;
                                              });
                                            },
                                          ),
                                        ),
                                      ],
                                    )

// ──────────────────────────────────────────────────────────────
// 5. CAS PACK (currentTab == TAB_PACK)
// ──────────────────────────────────────────────────────────────
                                  else if (currentTab == TAB_PACK)
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (packsSelectionnes.length == 1)
                                            AfficheurPack(
                                              pack: packsSelectionnes.first,
                                              onDetails: () {
                                                PackDetail(context, packsSelectionnes.first);
                                              },
                                            )
                                          else
                                            AfficheurProduitsGlobalWidget(
                                              nombreProduits: produitsTest.length,
                                              nombreCategories: categoriesTest.length,
                                              nombrePacks: packsTest.length,
                                              nombreRemises: remisesTest.length,
                                              nombreSousCategories: sousCategoriesTest.length,
                                            ),

                                          SizedBox(height: paddingV),

                                          Row(
                                            children: [
                                              filtrepack(setState, l10n),
                                              SizedBox(width: paddingH / 3),
                                              MainButton(
                                                text: l10n.extract,
                                                textColor:Colors.green ,
                                                iconColor: Colors.green,
                                                color: Appstyle.Tblanc,
                                                icon: Icons.download,
                                                loading: _exportEnCours,
                                                onPressed: () async {
                                                  await _exportCurrentModuleToExcel();
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainButton(
                                                text: l10n.extractPdf,
                                                textColor: Colors.red,
                                                iconColor: Colors.red,
                                                color: Appstyle.Tblanc,
                                                icon: Icons.picture_as_pdf,
                                                onPressed: () async {
                                                  await _exportCurrentModuleToExcel(enPdf: true);
                                                },
                                              ),
                                              SizedBox(width: paddingH / 4),
                                              MainIconButton(
                                                imagePath: "assets/icons/action/extacter_filtre_icon.png",
                                                color: Colors.orange,
                                                onPressed: () async {
                                                  await _exportSelectedToExcel();
                                                },
                                              ),
                                              const Spacer(),
                                              Row(
                                                children: [
                                                  ...actionButtons[actionIndex].map(
                                                        (btn) => Padding(
                                                      padding: EdgeInsets.only(right: paddingH / 5),
                                                      child: MainIconButton(
                                                        color: btn['color'] as Color,
                                                        onPressed: btn['onPressed'] as void Function(),
                                                        imagePath: btn['icon'] as String,
                                                      ),
                                                    ),
                                                  ),
                                                  SizedBox(width: paddingH / 4),
                                                  MainButton(
                                                    text: l10n.newWord,
                                                    color: Appstyle.crevete,
                                                    onPressed: () async {
                                                      await PackNouveau(context);
                                                      await loadAllData();
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),

                                          SizedBox(height: paddingV / 2),

                                          SizedBox(
                                            height: adjustedHeight * 0.72,
                                            child: TableauPackAdvanced(
                                              key: ValueKey(packsFiltres),
                                              packs: packsFiltres,
                                              utilisateurs: utilisateursTest,
                                              onSelectionChanged: (selection) {
                                                setState(() {
                                                  packsSelectionnes = selection;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                            ],
                          ),
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
  Widget filtreproduit(void Function(VoidCallback fn) setState, double width, AppLocalizations l10n, ListsConstTranslator translator) {
    List<String> marqueFilterOptions = produitsTest.map((p) => p.marque).toSet().toList();
    // ✅ Permission spéciale (voir RoleDetail) : filtre "Tous les magasins".
    final authFiltre = Provider.of<AuthState>(context, listen: false);
    // Filtre limité aux magasins consultables par l'utilisateur.
    final magasinsFiltrables =
        magasinsDisponiblesProduit.where((m) => authFiltre.peutConsulterMagasin(m.code)).toList();

    return SectionDecorationFiltre(
      padding: EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.categorie,
                  child: TextListe(
                    value: selectedCategorieFilter ?? "",
                    items: categorieFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedCategorieFilter = v;
                        selectedSousCategorieFilter = null;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.sousCategorie,
                  child: TextListe(
                    value: selectedSousCategorieFilter,
                    items: sousCategorieFilterOptions.where((sc) {
                      if (selectedCategorieFilter == null) return true;
                      final categorieCode = sousCategoriesTest.firstWhere((s) => s.nom == sc).categorieCode;
                      return categoriesTest.where((c) => c.code == categorieCode).firstOrNull?.nom == selectedCategorieFilter;
                    }).toList(),
                    onChanged: (v) {
                      setState(() {
                        selectedSousCategorieFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.marque,
                  child: TextListe(
                    value: selectedMarqueFilter,
                    items: marqueFilterOptions,
                    onChanged: (v) {
                      setState(() {
                        selectedMarqueFilter = v;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LigneFiltreTiers(
            children: [
              // Quantité affichée = calculée depuis le journal des
              // mouvements pour ce magasin (ou tous magasins si "Tous").
              ChampAvecLabel(
                label: l10n.magasin,
                child: TextListe(
                  enabled: magasinsFiltrables.length > 1,
                  value: magasinFiltreCode == null
                      ? null
                      : magasinsFiltrables
                          .firstWhereOrNull((m) => m.code == magasinFiltreCode)
                          ?.nom,
                  hint: "Tous les magasins",
                  items: magasinsFiltrables.map((m) => m.nom).toList(),
                  onChanged: (v) {
                    magasinFiltreCode = (v == null || v.isEmpty)
                        ? null
                        : magasinsFiltrables.firstWhereOrNull((m) => m.nom == v)?.code;
                    _chargerQuantitesParMagasin();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.purchasePrice,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: prixAchatMin,
                    maxValue: prixAchatMax,
                    onChanged: (min, max) {
                      setState(() {
                        prixAchatMin = min;
                        prixAchatMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.salePrice,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: prixVenteMin,
                    maxValue: prixVenteMax,
                    onChanged: (min, max) {
                      setState(() {
                        prixVenteMin = min;
                        prixVenteMax = max;
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.etat,
                  child: TextListe(
                    value: selectedEtatFilter != null ? translator.translateEtat(selectedEtatFilter!) : null,
                    items: translator.etatDisplayList,
                    onChanged: (v) {
                      setState(() {
                        selectedEtatFilter = translator.etatToFrench(v!);
                        appliquerFiltre();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.search,
                child: SearchField(
                  controller: _searchController,
                  onChanged: (v) {
                    setState(() {
                      appliquerFiltre();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget filtrepack(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerPack,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltrePack();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtrremise(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerRemise,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreRemise();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtrcategorie(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(

          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerCategorie,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreCatgorie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget filtresouscategorie(void Function(VoidCallback fn) setState, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 480,
          child: Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  distance: 100,
                  label: l10n.search,
                  child: SearchField(
                    controller: _searchControllerSousCategorie,
                    onChanged: (v) {
                      setState(() {
                        appliquefiltreSousCatgorie();
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}