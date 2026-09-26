import 'dart:io';
import 'package:collection/collection.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/BonReception.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/ReceiptScannerService.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/Services/receipt_scanner_windows.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/confirmation_dialog.dart';
import 'package:caisse_dz/core/dialog/insertion_caisse.dart';
import 'package:caisse_dz/core/dialog/insertion_produit.dart';
import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart'
    show ProduitNouveau, nomController, prixController, prixController2;
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/text_champ_l.dart';
import 'package:caisse_dz/core/widget/step_widget.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _GetNextId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await SmartScanServices.getNextSmartScanId(txn);
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

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

// ✅ Marge auto par pourcentage (30% par défaut ici) : le prix de vente
// généré est arrondi au multiple de 5 DA supérieur (104 -> 105, 126 -> 130).
// La saisie manuelle du prix de vente (_updateSalePrice) garde la valeur exacte.
double _arrondirAuMultipleDe5(double prix) {
  final prixArrondi = double.parse(prix.toStringAsFixed(2));
  return (prixArrondi / 5).ceil() * 5;
}

class AISmartScanDialog extends StatefulWidget {
  // ✅ Photo pré-sélectionnée (jointe depuis le disque ou reçue depuis le
  // mobile) : quand fourni, l'assistant saute l'étape 1 (galerie) et lance
  // directement l'OCR sur cette image. [receptionPhotoId] permet, une fois
  // le Smart Scan sauvegardé, de marquer la photo d'origine comme traitée.
  final File? initialImage;
  final int? receptionPhotoId;
  // ✅ Fournisseur déjà résolu côté serveur de réception (matché par nom, ou
  // fournisseur système "Général" par défaut) : pré-sélectionné à l'étape 3
  // pour éviter à l'utilisateur de le ressaisir.
  final String? receptionFournisseurCode;

  const AISmartScanDialog({
    super.key,
    this.initialImage,
    this.receptionPhotoId,
    this.receptionFournisseurCode,
  });

  static Future<void> open(
    BuildContext context, {
    File? initialImage,
    int? receptionPhotoId,
    String? receptionFournisseurCode,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AISmartScanDialog(
        initialImage: initialImage,
        receptionPhotoId: receptionPhotoId,
        receptionFournisseurCode: receptionFournisseurCode,
      ),
    );
  }

  @override
  State<AISmartScanDialog> createState() => _AISmartScanDialogState();
}

class _AISmartScanDialogState extends State<AISmartScanDialog> {

  int step = 1;
  File? receiptImage;
  bool isScanning = false;
  bool isSaving = false;
  List<ReceiptItem> extractedItems = [];
  // ✅ Nombre d'items détectés par le scan OCR/IA, figé au moment du scan —
  // sert à avertir si la liste finale (après suppressions/ajouts manuels)
  // ne correspond plus à ce qui a été capté sur le bon.
  int capturedItemsCount = 0;
  List<SmartScanProduit> validatedProducts = [];
  List<Produit> databaseProducts = [];
  List<Fournisseur> fournisseurs = [];
  List<CaisseGestion> caisses = [];

  String _nomProduit(String code) =>
      databaseProducts.firstWhereOrNull((p) => p.code == code)?.nom ?? code;
  String selectedSupplier = '';
  String selectedSupplierCode = '';
  String selectedCaisse = '';
  String selectedCaisseCode = '';
  DateTime? selectedDate;
  double totalAmount = 0;
  double amountPaid = 0;
  double remainingAmount = 0;

  // Controllers
  final TextEditingController fournisseurController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController dateController = TextEditingController();
  final TextEditingController montantController = TextEditingController();
  final TextEditingController payeController = TextEditingController();
  final TextEditingController observationController = TextEditingController();

  @override
  void initState() {
    super.initState();
    dateController.text = _formatDate(DateTime.now());
    selectedDate = DateTime.now();
    if (widget.initialImage != null) {
      receiptImage = widget.initialImage;
      _loadData().then((_) => _scanReceipt());
    } else {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    try {
      print('Loading data...');

      final products = await ProduitServices.getAllProduits();
      print('Loaded ${products.length} products');

      final suppliers = await FournisseurServices.getAllFournisseurs();
      print('Loaded ${suppliers.length} suppliers');

      final caissesList = await GCServices.getAllCaisses();

      if (mounted) {
        setState(() {
          databaseProducts = products;
          fournisseurs = suppliers;
          caisses = caissesList;
          if (caisses.isNotEmpty) {
            selectedCaisse = caisses.first.nomCaisse;
            selectedCaisseCode = caisses.first.code;
          }
          _preselectReceptionFournisseur();
        });
      }

      if (products.isEmpty && mounted) {
        _showError('No products found in database. Please add products first.');
      }

    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        _showError('Failed to load data: $e');
      }
    }
  }

  @override
  void dispose() {
    fournisseurController.dispose();
    codeController.dispose();
    dateController.dispose();
    montantController.dispose();
    payeController.dispose();
    observationController.dispose();
    super.dispose();
  }

  // ✅ Pré-remplit l'étape "Fournisseur" à partir du code résolu par le
  // serveur de réception, sans écraser un choix déjà fait par l'utilisateur.
  void _preselectReceptionFournisseur() {
    if (widget.receptionFournisseurCode == null || selectedSupplierCode.isNotEmpty) return;
    final match = fournisseurs.firstWhereOrNull((f) => f.code == widget.receptionFournisseurCode);
    if (match == null) return;
    selectedSupplier = match.nom;
    selectedSupplierCode = match.code;
    fournisseurController.text = match.nom;
    codeController.text = match.code;
  }

  String _formatDate(DateTime d) {
    return "${d.year.toString().padLeft(4, '0')}-"
        "${d.month.toString().padLeft(2, '0')}-"
        "${d.day.toString().padLeft(2, '0')}";
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
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
      setState(() {
        selectedDate = picked;
        dateController.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        setState(() {
          receiptImage = File(image.path);
        });
        await _scanReceipt();
      }
    } catch (e) {
      _showError('Gallery error: $e');
    }
  }

  Future<void> _scanReceipt() async {
    if (receiptImage == null) return;

    setState(() {
      isScanning = true;
    });

    try {
      final items = await ReceiptScannerService.scanReceipt(
        receiptImage!,
        databaseProducts,
      );

      setState(() {
        extractedItems = items;
        capturedItemsCount = items.length;
        isScanning = false;
        step = 2;
        totalAmount = extractedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        montantController.text = totalAmount.toStringAsFixed(2);
      });

      // ✅ Recherche "plus smart" : un item non matché par l'OCR/IA mais qui
      // correspond à 100% à un produit du catalogue est présélectionné
      // automatiquement — sinon on laisse l'utilisateur choisir parmi les
      // suggestions (voir _buildSuggestionsForItem), pas de sélection au hasard.
      for (var i = 0; i < extractedItems.length; i++) {
        if (extractedItems[i].matchedProductName.isNotEmpty) continue;
        final matches = ReceiptScannerWindows.findTopMatches(
          extractedItems[i].originalName,
          databaseProducts,
          topN: 7,
          minScore: 0.5,
        );
        if (matches.isNotEmpty && matches.first.score >= 0.999) {
          _updateProductMatch(i, matches.first.produit.nom);
        }
      }

      if (items.isEmpty) {
        _showError('No items found on receipt. Please try with a clearer photo.');
      } else {
        _showSuccess('Found ${items.length} items');
      }
    } catch (e) {
      setState(() {
        isScanning = false;
      });
      _showError('Scanning failed: $e');
    }
  }

  void _validateAndContinue() {
    if (extractedItems.isEmpty) {
      _showError('No items to validate. Please add products first.');
      return;
    }

    // ✅ Bloque le passage à l'étape 3 tant qu'un item n'a pas de produit
    // associé (auto-match, choix dans les suggestions, "Nouveau produit" ou
    // le bouton "Rechercher") — évite d'enregistrer une ligne "fantôme".
    final nonMatches = extractedItems.where((i) => i.matchedProductName.isEmpty).length;
    if (nonMatches > 0) {
      _showError('$nonMatches produit(s) sans correspondance : veuillez en sélectionner un pour chaque ligne avant de continuer.');
      return;
    }

    validatedProducts = [];
    for (var item in extractedItems) {
      if (item.quantity > 0 && item.totalPrice > 0) {
        final product = databaseProducts.firstWhere(
              (p) => p.nom == item.matchedProductName,
          orElse: () => _createTemporaryProduct(item),
        );

        // ✅ Récupérer ou calculer le prix de vente. Comparaison contre
        // item.unitPrice (le prix d'achat DU BON scanné, qui sera celui
        // enregistré sur la ligne du smart scan) et non product.prixAchat
        // (l'ancien prix du catalogue) : sinon, si le fournisseur a changé
        // son prix depuis la dernière mise à jour du catalogue, le prix de
        // vente hérité du catalogue peut être valide par rapport à l'ancien
        // prix d'achat mais invalide par rapport au nouveau — provoquant un
        // rejet "prix de vente < prix d'achat" à l'enregistrement alors que
        // rien ne semble anormal ni dans le scan ni dans la fiche produit.
        double prixVente = product.prixVente;
        if (prixVente <= item.unitPrice || product.id == 0) {
          prixVente = _arrondirAuMultipleDe5(item.unitPrice * 1.3); // Marge de 30%
        }

        validatedProducts.add(SmartScanProduit(
          id: 0,
          codeSmartScan: '',
          codeProduit: product.code,
          quantite: item.quantity,
          prix: item.unitPrice,
          prixVente: prixVente, // ✅ Ajout du prix de vente
          total: item.totalPrice,
          creeParCode: '',
          creeLe: DateTime.now(),
          etat: true,
        ));
      }
    }

    if (validatedProducts.isEmpty) {
      _showError('No valid products to save.');
      return;
    }

    // ✅ Le nombre de lignes a changé depuis le scan (suppression et/ou
    // ajout manuel) : ce n'est pas forcément une erreur, mais on demande
    // confirmation avant de continuer plutôt que de laisser passer en
    // silence un écart avec ce qui a été détecté sur le bon.
    if (extractedItems.length != capturedItemsCount) {
      ConfirmationDialog(
        context: context,
        titre: 'Attention',
        message:
            'Le nombre de produits sélectionnés (${extractedItems.length}) '
            'n\'est pas le même que le nombre de produits détectés sur le bon '
            '($capturedItemsCount). Voulez-vous continuer ?',
        onConfirmer: () {
          if (mounted) setState(() => step = 3);
        },
      );
      return;
    }

    setState(() {
      step = 3;
    });
  }

  Produit _createTemporaryProduct(ReceiptItem item) {
    final prixAchat = item.unitPrice > 0 ? item.unitPrice : 1.0;
    final prixVente = _arrondirAuMultipleDe5(prixAchat * 1.3); // Marge de 30%

    return Produit(
      id: 0,
      code: item.matchedProductCode.isNotEmpty
          ? item.matchedProductCode
          : 'TEMP-${DateTime.now().millisecondsSinceEpoch}',
      nom: item.matchedProductName.isNotEmpty
          ? item.matchedProductName
          : item.originalName,
      prixAchat: prixAchat,
      prixVente: prixVente,
      dateCree: DateTime.now(),
      creeParcode: '',
      marque: '',
      multicodebar: false,
      uniteMesure: '',
      margeBool: false,
      tva: 0,
      etat: true,
      service: false,
      categorieId: _getDefaultCategoryId(),
      sousCategorieId: 1,
      margeTaux: 0,
    );
  }

  int _getDefaultCategoryId() {
    try {
      final categories = databaseProducts.map((p) => p.categorieId).toSet();
      if (categories.isNotEmpty) return categories.first;
    } catch (_) {}
    return 1;
  }

  void _updateProductMatch(int index, String productName) {
    final product = databaseProducts.firstWhere((p) => p.nom == productName);
    // ✅ Même correction que dans _validateAndContinue : comparer contre le
    // prix d'achat scanné (celui qui sera réellement enregistré sur la
    // ligne), pas l'ancien prix d'achat du catalogue.
    final prixAchatScanne = extractedItems[index].unitPrice;
    double prixVente = product.prixVente;
    if (prixVente <= prixAchatScanne) {
      prixVente = _arrondirAuMultipleDe5(prixAchatScanne * 1.3);
    }

    setState(() {
      extractedItems[index] = ReceiptItem(
        originalName: extractedItems[index].originalName,
        matchedProductName: product.nom,
        matchedProductCode: product.code,
        quantity: extractedItems[index].quantity,
        unitPrice: extractedItems[index].unitPrice,
        totalPrice: extractedItems[index].quantity * extractedItems[index].unitPrice,
        confidence: 1.0,
        prixVente: prixVente, // ✅ Ajout du prix de vente
      );
      _recalculateTotal();
    });
  }

  Future<void> _creerProduitPourItem(int index) async {
    final ancienCodes = databaseProducts.map((p) => p.code).toSet();
    final item = extractedItems[index];

    nomController.text = item.originalName;
    // ✅ Pré-remplit aussi le prix d'achat/vente détecté sur le reçu, pour
    // éviter à l'utilisateur de les ressaisir juste après le scan IA.
    if (item.unitPrice > 0) {
      prixController.text = item.unitPrice.toStringAsFixed(2);
    }
    if (item.prixVente > 0) {
      prixController2.text = item.prixVente.toStringAsFixed(2);
    }
    await ProduitNouveau(context);

    await _loadData();

    final nouveauxProduits = databaseProducts.where((p) => !ancienCodes.contains(p.code));
    if (nouveauxProduits.isNotEmpty) {
      _updateProductMatch(index, nouveauxProduits.first.nom);
    }
  }

  Widget _buildSuggestionsForItem(int index, ReceiptItem item) {
    // ✅ Jusqu'à 7 produits avec une similarité > 50%, triés par similarité
    // décroissante (déjà fait par findTopMatches) — l'utilisateur choisit,
    // rien n'est présélectionné ici (le 100% l'est déjà avant d'arriver ici).
    final matches = ReceiptScannerWindows.findTopMatches(
      item.originalName,
      databaseProducts,
      topN: 7,
      minScore: 0.5,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matches.isEmpty)
          Text(
            'Aucun produit similaire trouvé',
            style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: matches.map((m) {
              final sousTitre = [m.produit.marque, m.produit.taille ?? '']
                  .where((s) => s.trim().isNotEmpty)
                  .join(' • ');
              final pct = (m.score * 100).round();
              return ActionChip(
                avatar: const Icon(Icons.inventory_2, size: 16),
                label: Text(
                  sousTitre.isEmpty
                      ? '${m.produit.nom} ($pct%)'
                      : '${m.produit.nom} ($sousTitre) $pct%',
                ),
                backgroundColor: Colors.blue.shade50,
                onPressed: () => _updateProductMatch(index, m.produit.nom),
              );
            }).toList(),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _creerProduitPourItem(index),
          icon: const Icon(Icons.add_circle_outline, size: 18),
          label: const Text('Nouveau produit'),
        ),
      ],
    );
  }

  void _updateQuantity(int index, String value) {
    final newQuantity = double.tryParse(value) ?? extractedItems[index].quantity;
    setState(() {
      extractedItems[index] = ReceiptItem(
        originalName: extractedItems[index].originalName,
        matchedProductName: extractedItems[index].matchedProductName,
        matchedProductCode: extractedItems[index].matchedProductCode,
        quantity: newQuantity,
        unitPrice: extractedItems[index].unitPrice,
        totalPrice: newQuantity * extractedItems[index].unitPrice,
        confidence: extractedItems[index].confidence,
        prixVente: extractedItems[index].prixVente,
      );
      _recalculateTotal();
    });
  }

  void _updateUnitPrice(int index, String value) {
    final newPrice = double.tryParse(value) ?? extractedItems[index].unitPrice;
    setState(() {
      extractedItems[index] = ReceiptItem(
        originalName: extractedItems[index].originalName,
        matchedProductName: extractedItems[index].matchedProductName,
        matchedProductCode: extractedItems[index].matchedProductCode,
        quantity: extractedItems[index].quantity,
        unitPrice: newPrice,
        totalPrice: extractedItems[index].quantity * newPrice,
        confidence: extractedItems[index].confidence,
        prixVente: extractedItems[index].prixVente,
      );
      _recalculateTotal();
    });
  }

  void _updateSalePrice(int index, String value) {
    final newSalePrice = double.tryParse(value) ?? extractedItems[index].prixVente;
    final prixAchat = extractedItems[index].unitPrice;

    // ✅ Vérifier que prix vente > prix achat
    if (newSalePrice <= prixAchat && newSalePrice > 0) {
      _showError('Le prix de vente doit être supérieur au prix d\'achat (${NumberFormatUtil.formatMontant(prixAchat, decimales: 2)})');
      return;
    }

    setState(() {
      extractedItems[index] = ReceiptItem(
        originalName: extractedItems[index].originalName,
        matchedProductName: extractedItems[index].matchedProductName,
        matchedProductCode: extractedItems[index].matchedProductCode,
        quantity: extractedItems[index].quantity,
        unitPrice: extractedItems[index].unitPrice,
        totalPrice: extractedItems[index].totalPrice,
        confidence: extractedItems[index].confidence,
        prixVente: newSalePrice,
      );
    });
  }

  void _recalculateTotal() {
    totalAmount = extractedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    montantController.text = totalAmount.toStringAsFixed(2);
  }

  void _removeItem(int index) {
    setState(() {
      extractedItems.removeAt(index);
      _recalculateTotal();
    });
    _showSuccess('Item removed');
  }

  // ✅ Sélecteur produit standard (sélection simple) pour associer/remplacer
  // le produit d'une ligne scannée, en gardant la qté/prix détectés
  // (_updateProductMatch ne touche pas quantity/unitPrice).
  void _ouvrirRechercheProduitPourItem(int index) {
    showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.25),
      builder: (_) => InsertionProduitDialog(
        multiselection: false,
        produits: databaseProducts,
        onProduitSelected: (product) {
          _updateProductMatch(index, product.nom);
          _showSuccess('Product updated to: ${product.nom}');
        },
      ),
    );
  }

  // ✅ Même sélecteur que partout ailleurs dans l'app (recherche, filtres,
  // catégories...), en sélection multiple — au lieu d'un formulaire dédié.
  // Chaque produit choisi est ajouté avec son prix d'achat et une quantité
  // de 1 (modifiables ensuite directement dans la liste, comme les autres
  // items).
  void _showAddProductDialog() async {
    await _loadData();
    if (!mounted) return;

    await showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.25),
      builder: (_) => InsertionProduitDialog(
        multiselection: true,
        produits: databaseProducts,
        onProduitSelected: (product) {
          final prixVente = product.prixVente > product.prixAchat
              ? product.prixVente
              : _arrondirAuMultipleDe5(product.prixAchat * 1.3);

          final newItem = ReceiptItem(
            originalName: product.nom,
            matchedProductName: product.nom,
            matchedProductCode: product.code,
            quantity: 1.0,
            unitPrice: product.prixAchat,
            totalPrice: product.prixAchat,
            confidence: 1.0,
            prixVente: prixVente,
          );

          setState(() {
            extractedItems.add(newItem);
            _recalculateTotal();
          });

          _showSuccess('Product added: ${product.nom}');
        },
      ),
    );
  }

  Widget _buildScanStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (receiptImage != null)
          Container(
            height: 400,
            width: 400,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: FileImage(receiptImage!),
                fit: BoxFit.cover,
              ),
            ),
          ),
        const SizedBox(height: 30),
        if (isScanning)
          const CircularProgressIndicator()
        else
          // ✅ Une photo est déjà choisie (retour depuis l'étape 2/3) :
          // proposer de relancer l'OCR sur cette même image plutôt que d'en
          // reprendre une nouvelle.
          MainButton(
            text: receiptImage != null ? 'Rescanner' : 'Choose from Gallery',
            icon: receiptImage != null ? Icons.replay : Icons.photo_library,
            onPressed: receiptImage != null ? _scanReceipt : _pickImageFromGallery,
            color: Appstyle.crevete,
          ),
      ],
    );
  }

  Widget _buildValidationStep() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (receiptImage != null)
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Appstyle.violetC, width: 2),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.file(
                  receiptImage!,
                  fit: BoxFit.contain,
                  height: 1500,
                  width: 500,
                ),
              ),
            ),
          ),

        Expanded(
          flex: 7,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appstyle.violetC.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Scanned Receipt',
                            style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${extractedItems.length} products detected',
                            style: Appstyle.textXS,
                          ),
                          if (isScanning)
                            const Row(
                              children: [
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                                SizedBox(width: 8),
                                Text('Processing...'),
                              ],
                            ),
                        ],
                      ),
                      MainButton(
                        text: 'Add Product Manually',
                        icon: Icons.add_circle,
                        onPressed: _showAddProductDialog,
                        color: Colors.green,
                        width: 280,
                      ),
                    ],
                  ),
                ),
              ),

              Expanded(
                child: ListView.builder(
                  itemCount: extractedItems.length,
                  itemBuilder: (context, index) {
                    final item = extractedItems[index];
                    final isMatched = item.matchedProductName.isNotEmpty;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.originalName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // ✅ Disponible sur toutes les lignes (pas
                                // seulement les lignes déjà matchées) : ouvre
                                // le sélecteur produit standard (sélection
                                // simple) en conservant la qté/prix scannés.
                                IconButton(
                                  icon: const Icon(Icons.search, color: Colors.blue, size: 20),
                                  tooltip: 'Rechercher un produit',
                                  onPressed: () => _ouvrirRechercheProduitPourItem(index),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                  tooltip: 'Remove Item',
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (!isMatched)
                              _buildSuggestionsForItem(index, item)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${item.matchedProductCode} - ${item.matchedProductName}',
                                        style: TextStyle(
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.quantity.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Quantity',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _updateQuantity(index, value),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: item.unitPrice.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Unit Price',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _updateUnitPrice(index, value),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // ✅ NOUVEAU CHAMP PRIX VENTE
                                Expanded(
                                  child: TextFormField(
                                    initialValue: (item.prixVente > 0 ? item.prixVente : _arrondirAuMultipleDe5(item.unitPrice * 1.3)).toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Sale Price',
                                      border: OutlineInputBorder(),
                                      hintText: 'Must be > purchase price',
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (value) => _updateSalePrice(index, value),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Total: ${NumberFormatUtil.formatMontant(item.totalPrice, decimales: 2)} DZD',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Appstyle.violet,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${extractedItems.length} items',
                          style: Appstyle.textSB,
                        ),
                        Text(
                          'Total: ${NumberFormatUtil.formatMontant(totalAmount, decimales: 2)} DZD',
                          style: Appstyle.textMB.copyWith(color: Appstyle.violet),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MainButton(
                            text: 'Back',
                            icon: Icons.chevron_left,
                            onPressed: () => setState(() => step = 1),
                            color: Appstyle.gris,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: MainButton(
                            text: 'Continue (${extractedItems.length})',
                            icon: Icons.chevron_right,
                            onPressed: extractedItems.isEmpty ? null : _validateAndContinue,
                            color: Appstyle.violet,
                          ),
                        ),
                      ],
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

  Widget _buildSupplierStep() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ✅ Formulaire sur deux colonnes plutôt qu'empilé sur toute la
            // largeur (le dialog fait 1500px de large : des champs étirés
            // sur toute cette largeur étaient disproportionnés).
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      ChampAvecLabel(
                        label: 'Supplier',
                        buttonAjout: true,
                        onAjoutPressed: () async {
                          _showError('Please add supplier from main menu first');
                        },
                        child: TextListe(
                          value: selectedSupplier.isEmpty ? null : selectedSupplier,
                          items: fournisseurs.map((f) => f.nom).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedSupplier = value;
                                final supplier = fournisseurs.firstWhere((f) => f.nom == value);
                                selectedSupplierCode = supplier.code;
                                codeController.text = supplier.code;
                                fournisseurController.text = supplier.nom;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 15),
                      ChampAvecLabel(
                        label: 'Supplier Code',
                        child: TextChampL(
                          controller: codeController,
                          enabled: false,
                          hint: 'Auto-filled',
                        ),
                      ),
                      const SizedBox(height: 15),
                      ChampAvecLabel(
                        label: 'Cash Register',
                        buttonAjout: true,
                        onAjoutPressed: () async {
                          await showDialog(
                            context: context,
                            barrierColor: Appstyle.gris.withOpacity(0.25),
                            builder: (_) {
                              return InsertionCaisseDialog(
                                caisses: caisses,
                                onCaisseSelected: (c) {
                                  setState(() {
                                    selectedCaisse = c.nomCaisse;
                                    selectedCaisseCode = c.code;
                                  });
                                },
                              );
                            },
                          );
                        },
                        child: TextListe(
                          value: selectedCaisse.isEmpty ? null : selectedCaisse,
                          items: caisses.map((c) => c.nomCaisse).toSet().toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedCaisse = value;
                                selectedCaisseCode = caisses.firstWhere((c) => c.nomCaisse == value).code;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      ChampAvecLabel(
                        label: 'Date',
                        child: TextDate(
                          controller: dateController,
                          onTap: _pickDate,
                          hint: 'Select date',
                        ),
                      ),
                      const SizedBox(height: 15),
                      ChampAvecLabel(
                        label: 'Amount Paid',
                        child: TextChampL(
                          controller: payeController,
                          hint: '0.00',
                          numeric: true,
                          onChanged: (value) {
                            setState(() {
                              amountPaid = double.tryParse(value) ?? 0;
                              remainingAmount = totalAmount - amountPaid;
                            });
                          },
                        ),
                      ),
                      if (remainingAmount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              'Remaining: ${NumberFormatUtil.formatMontant(remainingAmount, decimales: 2)} DZD',
                              style: TextStyle(color: Colors.orange.shade700),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            // ✅ Récapitulatif des produits validés à l'étape 2 (nom, qté,
            // prix d'achat/vente, total) — évite de valider "à l'aveugle".
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Appstyle.violetC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Produits (${validatedProducts.length})', style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(flex: 3, child: Text('Produit', style: Appstyle.textXSB)),
                      Expanded(flex: 1, child: Text('Qté', style: Appstyle.textXSB, textAlign: TextAlign.center)),
                      Expanded(flex: 2, child: Text('P. Achat', style: Appstyle.textXSB, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('P. Vente', style: Appstyle.textXSB, textAlign: TextAlign.right)),
                      Expanded(flex: 2, child: Text('Total', style: Appstyle.textXSB, textAlign: TextAlign.right)),
                    ],
                  ),
                  const Divider(height: 12),
                  ...validatedProducts.map((p) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(_nomProduit(p.codeProduit), style: Appstyle.textXS, overflow: TextOverflow.ellipsis),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('x${NumberFormatUtil.formatMontant(p.quantite, decimales: 0)}', style: Appstyle.textXS, textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(NumberFormatUtil.formatMontant(p.prix, decimales: 2), style: Appstyle.textXS, textAlign: TextAlign.right),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(NumberFormatUtil.formatMontant(p.prixVente, decimales: 2), style: Appstyle.textXS.copyWith(color: Appstyle.crevete), textAlign: TextAlign.right),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(NumberFormatUtil.formatMontant(p.total, decimales: 2), style: Appstyle.textXSB.copyWith(color: Appstyle.violet), textAlign: TextAlign.right),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Appstyle.violetC.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Items:', style: Appstyle.textSB),
                      Text(validatedProducts.length.toString(), style: Appstyle.textSB),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Quantity:', style: Appstyle.textSB),
                      Text(
                        NumberFormatUtil.formatMontant(validatedProducts.fold(0.0, (sum, p) => sum + p.quantite), decimales: 0),
                        style: Appstyle.textSB,
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Amount:', style: Appstyle.textMB),
                      Text(
                        '${NumberFormatUtil.formatMontant(totalAmount, decimales: 2)} DZD',
                        style: Appstyle.textMB.copyWith(color: Appstyle.violet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ChampAvecLabel(
              label: 'Observation',
              child: TextChampL(
                controller: observationController,
                hint: 'Additional notes...',
                maxLines: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveSmartScan() async {
    if (isSaving) return;

    final auth = Provider.of<AuthState>(context, listen: false);
    final userName = auth.username ?? 'system';
    final userCode = auth.userCode ?? 'SYS';

    if (selectedSupplier.isEmpty) {
      _showError('Please select a supplier');
      return;
    }

    if (selectedCaisseCode.isEmpty) {
      _showError('Please select a cash register');
      return;
    }

    if (validatedProducts.isEmpty) {
      _showError('No products to save');
      return;
    }

    // ✅ Session de caisse obligatoire : aucun achat ne peut être enregistré
    // tant que la caisse choisie n'a pas été ouverte.
    final sessionOuverte = await CaisseSessionServices.getSessionOuverte(selectedCaisseCode);
    if (sessionOuverte == null) {
      _showError('No open cash register session for "$selectedCaisse" — please open the cash register first.');
      return;
    }

    // ✅ Vérifier que le prix de vente est supérieur au prix d'achat pour chaque produit
    for (var produit in validatedProducts) {
      if (produit.prixVente <= produit.prix) {
        _showError('Le prix de vente doit être supérieur au prix d\'achat pour ${_nomProduit(produit.codeProduit)}');
        return;
      }
    }

    setState(() {
      isSaving = true;
    });

    try {
      final db = await DbCreator.openDb();
      final smartScanService = await SmartScanServices(db);
      final nextId = await _GetNextId();

      final code = CodeGenerator.generateCode(
        prefix: CodePrefix.smartscan,
        id: nextId,
        digitCount: 6,
      );

      final smartScan = SmartScan(
        id: nextId,
        code: code,
        date: selectedDate ?? DateTime.now(),
        etat: true,
        montant: totalAmount,
        dateCree: DateTime.now(),
        nbrProduit: validatedProducts.length,
        creeParCode: userCode,
        fournisseurCode: selectedSupplierCode,
      );

      List<Mouvement> movements = [];

      for (var product in validatedProducts) {
        final fullProduct = databaseProducts.firstWhere(
              (p) => p.code == product.codeProduit,
          orElse: () => _createTemporaryProductFromSmartScan(product),
        );

        // ✅ Mettre à jour tous les champs du produit
        fullProduct.prixAchat = product.prix;
        fullProduct.prixVente = product.prixVente; // ✅ Mettre à jour le prix de vente
        fullProduct.dateModif = DateTime.now();
        fullProduct.modifParCode = userCode;


        final services = ProduitServices(db);
        await services.updateProduit(fullProduct);

        movements.add(Mouvement(
          id: 0,
          code: '',
          date: selectedDate ?? DateTime.now(),
          codeProduit: product.codeProduit,
          quantite: product.quantite,
          prixAchat: product.prix,
          prixVente: product.prixVente, // ✅ Utiliser le prix de vente
          type: ListsConst.typeMouvement[1],
          codeOperation: code,
          etat: true,
          dateCree: DateTime.now(),
          creeParCode: userCode,
          fournisseurCode: selectedSupplierCode,
        ));
      }

      final response = await smartScanService.addSmartScan(smartScan);
      print(response);

      if (!response.success) {
        _showError(response.message);
        return;
      }

      // ✅ Créer le versement de règlement du fournisseur (montant versé)
      if (amountPaid > 0) {
        final versementService = VerssementServices(db);
        final nextVerssementId = await VerssementServices.getNextVerssementId(db);
        final versement = Verssement(
          id: nextVerssementId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.verssement,
            id: nextVerssementId,
            digitCount: 6,
          ),
          date: DateTime.now(),
          typebeneficiare: "Fournisseur",
          beneficiareCode: selectedSupplierCode,
          montant: amountPaid,
          etat: true,
          mode_paiement: "Espèces",
          sense: 'Sortie',
          type: "Paiement",
          dateCree: DateTime.now(),
          creeParCode: userCode,
          caisse: selectedCaisse,
          codeOperation: code,
        );
        await versementService.addverssement(versement);

        // Mouvement de caisse (grand-livre) : décaissement du paiement
        // fournisseur, journalisé dans la session ouverte de cette caisse.
        final caisseSessionService = CaisseSessionServices(db);
        final nextMouvementId = await CaisseSessionServices.getNextMouvementId(db);
        final mouvementCaisse = CaisseMouvement(
          id: nextMouvementId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.caisseMouvement,
            id: nextMouvementId,
            digitCount: 8,
          ),
          sessionCode: sessionOuverte.code,
          caisseCode: selectedCaisseCode,
          type: 'decaissement_achat',
          sens: 'Sortie',
          montant: amountPaid,
          modePaiement: "Espèces",
          codeOperation: code,
          fournisseurCode: selectedSupplierCode,
          date: DateTime.now(),
          etat: true,
          dateCree: DateTime.now(),
          creeParCode: userCode,
        );
        await caisseSessionService.ajouterMouvement(mouvementCaisse);
      }

      final mouvementService = await MouvementsServices(db);
      for (var movement in movements) {
        final movementId = await _GetNextMouvementId();
        movement.id = movementId;
        movement.code = CodeGenerator.generateCode(
          prefix: CodePrefix.mouvement,
          id: movementId,
          digitCount: 8,
        );
        await mouvementService.addMouvement(movement);
      }

      final historiqueService = await HistoriqueServices(db);
      final historiqueId = await _GetNextHistoriqueId();
      final historique = Historique(
        id: historiqueId,
        code: CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: historiqueId,
        ),
        desc: "L'utilisateur $userName a ajouté une nouvelle Entrée (IA) de $selectedSupplier avec ${validatedProducts.length} produits",
        oper: ListsConst.typeHisto[0],
        type: "SmartScanAI",
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await historiqueService.addHistorique(historique);

      // ✅ Si cet assistant a été ouvert depuis une photo de la file de
      // réception (mobile ou jointe), marquer cette photo comme traitée et
      // la lier au Smart Scan créé (pour la bordure verte côté écran).
      if (widget.receptionPhotoId != null) {
        await BonReceptionServices(db).markAsTraite(widget.receptionPhotoId!, code, userCode);
      }

      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      await InformationDialog(
        context: context,
        titre_type_message: l10n.success,
        titre_concerne: '${l10n.smartScan} (IA)',
        message: l10n.aiScanSavedDetails(
            code,
            selectedSupplier,
            validatedProducts.length.toString(),
            NumberFormatUtil.formatMontant(totalAmount, decimales: 2)),
        onTerminer: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      );
    } catch (e) {
      _showError(AppLocalizations.of(context)!.saveFailed(e.toString()));
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Produit _createTemporaryProductFromSmartScan(SmartScanProduit product) {
    return Produit(
      id: 0,
      code: product.codeProduit,
      nom: _nomProduit(product.codeProduit),
      prixAchat: product.prix,
      prixVente: product.prixVente > product.prix ? product.prixVente : _arrondirAuMultipleDe5(product.prix * 1.3),
       dateCree: DateTime.now(),
      creeParcode: '',
      marque: '',
      multicodebar: false,
      uniteMesure: '',
      margeBool: false,
      tva: 0,
      etat: true,
      service: false,
      categorieId: _getDefaultCategoryId(),
      sousCategorieId: 1,
      margeTaux: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseDialog(
      width: 1500,
      header: _buildHeader(),
      content: _buildContent(),
      footer: _buildFooter(),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TitreAvecLigne(
                imagePath: 'assets/icons/cardwidget/scan_icon.png',
                text: '${AppLocalizations.of(context)!.smartScan} (IA)',
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 30),
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
              tooltip: 'Close',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
        const SizedBox(height: 15),
        StepIndicator(activeStep: step),
      ],
    );
  }

  Widget _buildContent() {
    switch (step) {
      case 1:
        return _buildScanStep();
      case 2:
        return _buildValidationStep();
      case 3:
        return _buildSupplierStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildFooter() {
    if (step == 3) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MainButton(
              text: 'Back',
              icon: Icons.chevron_left,
              onPressed: isSaving ? null : () => setState(() => step = 2),
              color: Appstyle.gris,
            ),
            MainButton(
              text: isSaving ? 'Saving...' : 'Save',
              icon: Icons.save,
              onPressed: isSaving ? null : _saveSmartScan,
              color: Appstyle.violet,
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}