import 'package:caisse_dz/Services/ai_proxy.dart';
import 'package:caisse_dz/Services/mistral_ocr_service.dart';
import 'dart:convert';
import 'package:caisse_dz/Services/receipt_scanner_windows.dart';
import 'package:http/http.dart' as http;
import 'package:caisse_dz/data/models/produit.dart';

/// Extraction des lignes d'un bon (texte OCR → produits/quantités/prix) via
/// le serveur BENS (POST /smartscan/extract), rattachée au scan OCR réussi
/// (MistralOCRService.dernierScanId) : elle ne consomme pas de quota.
class GeminiService {

  static const List<String> _models = [
    'mistral-small-latest',
    'mistral-medium-latest',
    'open-mistral-7b',
  ];

  static const int _maxRetries = 3;

  static const int _retryBaseSeconds = 2;

  // ✅ Vrai quand tous les modèles essayés échouent en 429 (service Mistral
  // saturé), pour que l'appelant distingue "service IA indisponible" de
  // "rien trouvé sur le document".
  static bool quotaExceeded = false;

  // ─────────────────────────────────────────────────────────────────────────── //

  static Future<List<ReceiptItem>> parseReceiptWithGemini(
      String ocrText,
      List<Produit> products,
      bool isDeliveryNote,
      ) async {
    print('=== Mistral: parsing items from OCR text ===');
    quotaExceeded = false;

    final scanId = MistralOCRService.dernierScanId;
    if (ocrText.trim().isEmpty || scanId == null) {
      print('⚠️ Mistral: OCR text is empty, skipping');
      return [];
    }

    for (final model in _models) {
      print('🔄 Trying model: $model');

      bool exhausted = false;

      for (int attempt = 1; attempt <= _maxRetries; attempt++) {
        http.Response? response;

        try {
          response = await http.post(
            Uri.parse('${AiProxy.baseUrl}/extract'),
            headers: await AiProxy.enTetes(),
            body: jsonEncode({
              'scan_id': scanId,
              ..._buildRequestBody(model, ocrText, products, isDeliveryNote),
            }),
          );
        } catch (e) {
          print('❌ Network error on $model (attempt $attempt): $e');
          if (attempt == _maxRetries) {
            exhausted = true;
          } else {
            await Future.delayed(
                Duration(seconds: _retryBaseSeconds * attempt));
          }
          continue;
        }

        if (response.statusCode == 200) {
          // ── Success ───────────────────────────────────────────────────── //
          try {
            final data = jsonDecode(response.body);


            final String content =
            data['choices'][0]['message']['content'];
            final items = _parseResponse(content, products);
            print('✅ $model extracted ${items.length} items');
            return items;
          } catch (e) {
            print('⚠️ $model: response parse error – $e');
            exhausted = true;
            break;
          }
        } else if (response.statusCode == 503) {

          print(
              '⚠️ $model is overloaded (503) – retry $attempt/$_maxRetries');
          if (attempt == _maxRetries) {
            exhausted = true;
          } else {
            await Future.delayed(
                Duration(seconds: _retryBaseSeconds * attempt));
          }
        } else if (AiProxy.erreurServeur(response) != null) {
          // Refus du serveur BENS (scan expiré, nombre d'analyses atteint…) :
          // réessayer ou changer de modèle ne sert à rien.
          print('⛔ Analyse refusée par le serveur: ${response.body}');
          return [];
        } else if (response.statusCode == 429) {

          print(
              '⚠️ $model rate-limited (429) – retry $attempt/$_maxRetries');
          if (attempt == _maxRetries) {
            exhausted = true;
            quotaExceeded = true;
          } else {
            await Future.delayed(
                Duration(seconds: _retryBaseSeconds * attempt * 2));
          }
        } else {

          print(
              '❌ $model failed with ${response.statusCode}: ${response.body}');
          exhausted = true;
          break;
        }
      }

      if (exhausted) {
        print('⏭️ Moving to next fallback model...');
      }
    }

    print('❌ All Mistral models failed – returning empty list');
    return [];
  }

  // ─────────────────────────────────────────────────────────────────────────── //

  static Map<String, dynamic> _buildRequestBody(
      String model,
      String ocrText,
      List<Produit> products,
      bool isDeliveryNote,
      ) {
    return {
      "model": model,
      "temperature": 0.1,
      "max_tokens": 8192,
      "messages": [
        {
          "role": "system",
          "content":
          "You are a precise receipt parser for Algerian documents. "
              "Extract every product line with its quantity, unit price, and total price. "
              "Return ONLY a pure JSON array. No markdown, no explanation, no text before or after.",
        },
        {
          "role": "user",
          "content": _buildPrompt(ocrText, products, isDeliveryNote),
        },
      ],
    };
  }

  // ─────────────────────────────────────────────────────────────────────────── //

  static String _buildPrompt(
      String ocrText,
      List<Produit> products,
      bool isDeliveryNote,
      ) {
    final productList =
    products.take(100).map((p) => '  - ${p.nom}').join('\n');

    final contextType = isDeliveryNote
        ? "delivery note (Bon de Livraison)"
        : "grocery receipt";

    return '''Analyze this Algerian $contextType OCR text.
      
      OCR TEXT:
      """
      $ocrText
      """
      
      KNOWN PRODUCT NAMES FOR REFERENCE:
      $productList
      
      STRICT RULES:
      1. Extract every product. For each:
         - "original_name": The product name. 
         - MANDATORY: Strip codes starting with 'AR' followed by digits (e.g., "AR2951 SAVON" -> "SAVON").
         - "quantity": Number of items.
         - "unit_price": Price per item.
         - "total_price": Total line amount.
      
      2. CLEANING: Remove spaces and handle both '.' and ',' as decimals (e.g., "1 750,00" -> 1750.0).
      
      3. SKIP: Headers, footers, and tax lines.

      Return ONLY a JSON array:
      [
        {"original_name": "...", "quantity": 1.0, "unit_price": 100.0, "total_price": 100.0}
      ]''';
  }

  // ─────────────────────────────────────────────────────────────────────────── //

  static List<ReceiptItem> _parseResponse(
      String content, List<Produit> products) {
    try {

      final cleaned = content
          .replaceAll('```json', '')
          .replaceAll('```', '')
          .trim();

      final List<dynamic> jsonList = jsonDecode(cleaned);

      final items = <ReceiptItem>[];
      for (final json in jsonList) {
        final originalName = json['original_name']?.toString() ?? '';
        final quantity     = (json['quantity']    as num?)?.toDouble() ?? 0;
        final unitPrice    = (json['unit_price']  as num?)?.toDouble() ?? 0;
        final totalPrice   = (json['total_price'] as num?)?.toDouble() ?? 0;

        if (quantity <= 0 || totalPrice <= 0 || originalName.isEmpty) continue;

        final matchedName =
        ReceiptScannerWindows.findBestMatch(originalName, products);

        items.add(ReceiptItem(
          originalName:       originalName,
          matchedProductName: matchedName,
          matchedProductCode: '',
          quantity:           quantity,
          unitPrice:          unitPrice > 0 ? unitPrice : totalPrice / quantity,
          totalPrice:         totalPrice,
          confidence:         matchedName.isNotEmpty ? 0.9 : 0.6,
        ));
      }
      return items;
    } catch (e) {
      print('Mistral response parse error: $e');
      return [];
    }
  }
}