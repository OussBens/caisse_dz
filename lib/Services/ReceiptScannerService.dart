import 'dart:io';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/Services/receipt_scanner_windows.dart';
import 'package:caisse_dz/Services/mistral_ocr_service.dart';
import 'package:caisse_dz/Services/deepseek_service.dart';

class ReceiptScannerService {
  static const bool _useGemini = true;

  // ✅ Vrai si le dernier scan a échoué parce que la clé API Mistral
  // (partagée par OCR et extraction, voir mistral_ocr_service.dart /
  // deepseek_service.dart) a atteint son quota — permet à l'appelant
  // d'afficher "service IA indisponible, réessayez plus tard" plutôt que de
  // laisser croire que la photo/le document scanné est en cause.
  static bool get lastScanHitQuotaLimit =>
      MistralOCRService.quotaExceeded || GeminiService.quotaExceeded;

  static Future<List<ReceiptItem>> scanReceipt(
      File imageFile,
      List<Produit> products,
      ) async {
    print('=== Starting Receipt Scan ===');

    // ── STEP 1: Mistral OCR → raw text ──────────────────────────────────────
    print('Step 1: Running Mistral OCR...');
    final rawText = await MistralOCRService.extractRawText(imageFile);

    if (rawText.trim().isEmpty) {
      print('⚠️ Mistral OCR returned no text — using local fallback with empty input');
      return ReceiptScannerWindows.parseReceiptText('', products);
    }

    print('✅ OCR text obtained (${rawText.length} chars)');

    // ── STEP 2: Pre-clean OCR text ───────────────────────────────────────────
    final cleanedText  = _preCleanOcrText(rawText);
    final isDelivery   = ReceiptScannerWindows.isDeliveryNote(cleanedText);

    print(isDelivery
        ? '📦 Document type: DELIVERY NOTE'
        : '🧾 Document type: GROCERY RECEIPT');

    // ── STEP 3: Try DeepSeek first if enabled ─────────────────────────────────
    // ── STEP 3: Try Gemini first if enabled ─────────────────────────────────
    if (_useGemini) {
      print('Step 3: Sending OCR text to Gemini for item extraction...');
      // Update the class and method name here
      final geminiItems = await GeminiService.parseReceiptWithGemini(
        cleanedText,
        products,
        isDelivery,
      );

      if (geminiItems.isNotEmpty) {
        print('✅ Gemini extracted ${geminiItems.length} items');
        return geminiItems;
      }
      print('⚠️ Gemini returned no items — using local fallback parser...');
    } else {
      print('Step 3: Gemini disabled, using local parser directly...');
    }

    // ── STEP 4: Local parsers (with table support) ───────────────────────────
    List<ReceiptItem> items = [];

    if (isDelivery) {
      // For delivery notes, try table parser first
      print('Trying markdown table parser for delivery note...');
      items = ReceiptScannerWindows.parseMarkdownTableDeliveryNote(cleanedText, products);

      // If table parser fails, fall back to original delivery note parser
      if (items.isEmpty) {
        print('Table parser found nothing, trying original delivery note parser...');
        items = ReceiptScannerWindows.parseDeliveryNoteText(cleanedText, products);
      }
    } else {
      // For grocery receipts, try table parser first (in case it's a table)
      print('Trying markdown table parser...');
      items = ReceiptScannerWindows.parseMarkdownTableDeliveryNote(cleanedText, products);

      // If table parser fails, try grocery receipt parser
      if (items.isEmpty) {
        print('Table parser found nothing, trying grocery receipt parser...');
        items = ReceiptScannerWindows.parseReceiptText(cleanedText, products);
      }
    }

    print('✅ Local parser extracted ${items.length} items');

    if (items.isEmpty) {
      print('⚠️ WARNING: No items were extracted from the receipt!');
    }

    return items;
  }

  // ---------------------------------------------------------------------------
  // Shared text pre-cleaner
  // ---------------------------------------------------------------------------

  static String _preCleanOcrText(String raw) {
    final lines = raw.split('\n');
    final fixed = <String>[];
    for (var line in lines) {
      var l = line;
      l = l.replaceAll(RegExp(r'\$'), '');
      l = l.replaceAll('«', ' ').replaceAll('»', ' ');
      l = l.replaceAllMapped(
          RegExp(r'(\d+[,.]00)(\d)'), (m) => '${m.group(1)} ${m.group(2)}');
      l = l.replaceAll(RegExp(r' {3,}'), '  ');
      l = l.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF]'), '');
      fixed.add(l);
    }
    return fixed.join('\n');
  }
}