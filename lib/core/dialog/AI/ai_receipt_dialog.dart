import 'dart:io';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Historique.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/ReceiptScannerService.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/receipt_scanner_windows.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
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
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import '../information_dialog.dart';

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

class AISmartScanDialog extends StatefulWidget {
  const AISmartScanDialog({super.key});

  static void open(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AISmartScanDialog(),
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
  List<SmartScanProduit> validatedProducts = [];
  List<Produit> databaseProducts = [];
  List<Fournisseur> fournisseurs = [];
  String selectedSupplier = '';
  String selectedSupplierCode = '';
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
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      print('Loading data...');

      final products = await ProduitServices.getAllProduits();
      print('Loaded ${products.length} products');

      final suppliers = await FournisseurServices.getAllFournisseurs();
      print('Loaded ${suppliers.length} suppliers');

      if (mounted) {
        setState(() {
          databaseProducts = products;
          fournisseurs = suppliers;
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
        extractedItems = items.cast<ReceiptItem>();
        isScanning = false;
        step = 2;
        totalAmount = extractedItems.fold(0.0, (sum, item) => sum + item.totalPrice);
        montantController.text = totalAmount.toStringAsFixed(2);
      });

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

    validatedProducts = [];
    for (var item in extractedItems) {
      if (item.quantity > 0 && item.totalPrice > 0) {
        final product = databaseProducts.firstWhere(
              (p) => p.nom == item.matchedProductName,
          orElse: () => _createTemporaryProduct(item),
        );

        // ✅ Récupérer ou calculer le prix de vente
        double prixVente = product.prixVente;
        // Si le produit est temporaire ou prixVente <= prixAchat, calculer automatiquement
        if (prixVente <= product.prixAchat || product.id == 0) {
          prixVente = product.prixAchat * 1.3; // Marge de 30%
        }

        validatedProducts.add(SmartScanProduit(
          id: 0,
          codeSmartScan: '',
          codeProduit: product.code,
          nomProduit: product.nom,
          quantite: item.quantity,
          prix: item.unitPrice,
          prixVente: prixVente, // ✅ Ajout du prix de vente
          total: item.totalPrice,
          creePar: '',
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

    setState(() {
      step = 3;
    });
  }

  Produit _createTemporaryProduct(ReceiptItem item) {
    final prixAchat = item.unitPrice > 0 ? item.unitPrice : 1.0;
    final prixVente = prixAchat * 1.3; // Marge de 30%

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
      quantite: 0,
      seuilMin: 10,
      dateCree: DateTime.now(),
      creePar: '',
      creeParcode: '',
      marque: '',
      categorie: '',
      sousCategorie: '',
      multicodebar: false,
      uniteMesure: '',
      seuilBool: false,
      seuilMax: 0,
      margeBool: false,
      tva: 0,
      etat: true,
      service: false,
      categorieId: _getDefaultCategoryId(),
      sousCategorieId: 1,
      margeTaux: 0,
      fournisseur: '',
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
    double prixVente = product.prixVente;
    if (prixVente <= product.prixAchat) {
      prixVente = product.prixAchat * 1.3;
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
      _showError('Le prix de vente doit être supérieur au prix d\'achat (${prixAchat.toStringAsFixed(2)})');
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

  void _showChangeProductDialog(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Product'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: databaseProducts.length,
            itemBuilder: (context, prodIndex) {
              final product = databaseProducts[prodIndex];
              final isCurrentlySelected = product.nom == extractedItems[index].matchedProductName;

              return ListTile(
                leading: isCurrentlySelected
                    ? Icon(Icons.check_circle, color: Appstyle.violet)
                    : const Icon(Icons.radio_button_unchecked),
                title: Text(product.nom),
                subtitle: Text('Code: ${product.code}'),
                selected: isCurrentlySelected,
                onTap: () {
                  _updateProductMatch(index, product.nom);
                  Navigator.pop(context);
                  _showSuccess('Product updated to: ${product.nom}');
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() async {
    String? selectedProductName;
    double quantity = 1.0;
    double unitPrice = 0.0;
    double salePrice = 0.0;
    await _loadData();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add Product'),
          content: SizedBox(
            width: 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedProductName,
                  hint: const Text('Select product from database'),
                  isExpanded: true,
                  items: databaseProducts.map((p) {
                    return DropdownMenuItem(
                      value: p.nom,
                      child: Text('${p.code} - ${p.nom}'),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedProductName = value;
                      if (value != null) {
                        final product = databaseProducts.firstWhere((p) => p.nom == value);
                        unitPrice = product.prixAchat;
                        salePrice = product.prixVente > product.prixAchat
                            ? product.prixVente
                            : product.prixAchat * 1.3;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    quantity = double.tryParse(value) ?? 1.0;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: unitPrice.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Purchase Price',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    unitPrice = double.tryParse(value) ?? 0.0;
                    // Mettre à jour le prix de vente automatiquement si pas défini
                    if (salePrice <= unitPrice) {
                      salePrice = unitPrice * 1.3;
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: salePrice > 0 ? salePrice.toString() : '',
                  decoration: const InputDecoration(
                    labelText: 'Sale Price (must be > purchase price)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    final newSalePrice = double.tryParse(value) ?? 0.0;
                    if (newSalePrice > unitPrice || newSalePrice == 0) {
                      salePrice = newSalePrice;
                    } else if (newSalePrice > 0) {
                      _showError('Sale price must be greater than purchase price');
                    }
                  },
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Appstyle.violetC.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '${(quantity * unitPrice).toStringAsFixed(2)} DZD',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Appstyle.violet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedProductName == null
                  ? null
                  : () {
                final product = databaseProducts.firstWhere((p) => p.nom == selectedProductName!);
                final finalSalePrice = salePrice > unitPrice ? salePrice : unitPrice * 1.3;

                final newItem = ReceiptItem(
                  originalName: product.nom,
                  matchedProductName: product.nom,
                  matchedProductCode: product.code,
                  quantity: quantity,
                  unitPrice: unitPrice,
                  totalPrice: quantity * unitPrice,
                  confidence: 1.0,
                  prixVente: finalSalePrice,
                );

                setState(() {
                  extractedItems.add(newItem);
                  _recalculateTotal();
                });

                Navigator.pop(context);
                _showSuccess('Product added: ${product.nom}');
              },
              style: ElevatedButton.styleFrom(backgroundColor: Appstyle.violet),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanStep() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (receiptImage != null)
          Container(
            height: 500,
            width: 500,
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
          MainButton(
            text: 'Choose from Gallery',
            icon: Icons.photo_library,
            onPressed: _pickImageFromGallery,
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
                        width: 200,
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
                                if (isMatched)
                                  IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                                    tooltip: 'Change Product',
                                    onPressed: () => _showChangeProductDialog(index),
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
                              DropdownButtonFormField<String>(
                                value: null,
                                hint: const Text('Select product from database'),
                                items: databaseProducts.map((p) {
                                  return DropdownMenuItem(
                                    value: p.nom,
                                    child: Text('${p.code} - ${p.nom}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    _updateProductMatch(index, value);
                                  }
                                },
                              )
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
                                    initialValue: (item.prixVente > 0 ? item.prixVente : item.unitPrice * 1.3).toString(),
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
                                'Total: ${item.totalPrice.toStringAsFixed(2)} DZD',
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
                          'Total: ${totalAmount.toStringAsFixed(2)} DZD',
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
              label: 'Date',
              child: TextDate(
                controller: dateController,
                onTap: _pickDate,
                hint: 'Select date',
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
                        validatedProducts.fold(0.0, (sum, p) => sum + p.quantite).toStringAsFixed(0),
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
                        '${totalAmount.toStringAsFixed(2)} DZD',
                        style: Appstyle.textMB.copyWith(color: Appstyle.violet),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    'Remaining: ${remainingAmount.toStringAsFixed(2)} DZD',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
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

    if (validatedProducts.isEmpty) {
      _showError('No products to save');
      return;
    }

    // ✅ Vérifier que le prix de vente est supérieur au prix d'achat pour chaque produit
    for (var produit in validatedProducts) {
      if (produit.prixVente <= produit.prix) {
        _showError('Le prix de vente doit être supérieur au prix d\'achat pour ${produit.nomProduit}');
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
        paye: amountPaid,
        ecart: false,
        reste: remainingAmount,
        creePar: userName,
        montant: totalAmount,
        dateCree: DateTime.now(),
        activity: ListsConst.typeactivitySmartScan[1],
        nbrProduit: validatedProducts.length,
        fournisseur: selectedSupplier,
        creeParCode: userCode,
        montantCalcul: totalAmount,
        fournisseurCode: selectedSupplierCode,
        quantiteArticle: validatedProducts.fold(0.0, (sum, p) => sum + p.quantite),
        nbrProduitCalcul: validatedProducts.length,
        quantiteArticleCalcul: validatedProducts.fold(0.0, (sum, p) => sum + p.quantite),
      );

      List<Mouvement> movements = [];

      for (var product in validatedProducts) {
        final fullProduct = databaseProducts.firstWhere(
              (p) => p.code == product.codeProduit,
          orElse: () => _createTemporaryProductFromSmartScan(product),
        );

        // ✅ Mettre à jour tous les champs du produit
        fullProduct.quantite += product.quantite;
        fullProduct.prixAchat = product.prix;
        fullProduct.prixVente = product.prixVente; // ✅ Mettre à jour le prix de vente
        fullProduct.dateModif = DateTime.now();
        fullProduct.modifPar = userName;


        final services = ProduitServices(db);
        await services.updateProduit(fullProduct);

        movements.add(Mouvement(
          id: 0,
          code: '',
          date: selectedDate ?? DateTime.now(),
          nomProduit: product.nomProduit,
          codeProduit: product.codeProduit,
          quantite: product.quantite,
          prixAchat: product.prix,
          prixVente: product.prixVente, // ✅ Utiliser le prix de vente
          type: ListsConst.typeMouvement[1],
          codeOperation: code,
          etat: true,
          dateCree: DateTime.now(),
          creePar: userName,
          creeParCode: userCode,
          fournisseur: selectedSupplier,
        ));
      }

      final response = await smartScanService.addSmartScan(smartScan);
      print(response);
      final mouvementService = await MouvementsServices(db);
      for (var movement in movements) {
        final movementId = await _GetNextMouvementId();
        movement.id = movementId;
        movement.code = CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.mouvement,
          id: movementId,
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
        desc: "L'utilisateur $userName a ajouté un nouveau Smart Scan IA de $selectedSupplier avec ${validatedProducts.length} produits",
        oper: ListsConst.typeHisto[0],
        type: "SmartScanAI",
        creePar: userName,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await historiqueService.addHistorique(historique);

      if (!mounted) return;

      await InformationDialog(
        context: context,
        titre_type_message: 'Success',
        titre_concerne: 'AI Smart Scan',
        message: 'Smart Scan saved successfully!\n\n'
            'Code: $code\n'
            'Supplier: $selectedSupplier\n'
            'Products: ${validatedProducts.length}\n'
            'Total: ${totalAmount.toStringAsFixed(2)} DZD',
        onTerminer: () {
          if (Navigator.canPop(context)) Navigator.pop(context);
        },
      );
    } catch (e) {
      _showError('Save failed: $e');
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
      nom: product.nomProduit,
      prixAchat: product.prix,
      prixVente: product.prixVente > product.prix ? product.prixVente : product.prix * 1.3,
      quantite: product.quantite,
      seuilMin: 10,
       dateCree: DateTime.now(),
      creePar: '',
      creeParcode: '',
      marque: '',
      categorie: '',
      sousCategorie: '',
      multicodebar: false,
      uniteMesure: '',
      seuilBool: false,
      seuilMax: 0,
      margeBool: false,
      tva: 0,
      etat: true,
      service: false,
      categorieId: _getDefaultCategoryId(),
      sousCategorieId: 1,
      margeTaux: 0,
      fournisseur: '',
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
                text: 'AI Smart Scan',
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

// ✅ Mise à jour du modèle ReceiptItem pour inclure prixVente
class ReceiptItem {
  final String originalName;
  final String matchedProductName;
  final String matchedProductCode;
  final double quantity;
  final double unitPrice;
  final double totalPrice;
  final double confidence;
  final double prixVente; // ✅ Nouveau champ

  ReceiptItem({
    required this.originalName,
    required this.matchedProductName,
    required this.matchedProductCode,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.confidence,
    this.prixVente = 0.0, // Valeur par défaut
  });
}