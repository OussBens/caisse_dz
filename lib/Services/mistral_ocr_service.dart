import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';

class MistralOCRService {
  static const String _apiKey = 'MagGDgxaej4RtZorOxHGYjngW1ct4a0j';
  static const String _baseUrl = 'https://api.mistral.ai/v1';

  // ✅ Détecté quand l'API Mistral répond 429 (quota/limite de requêtes
  // atteint sur cette clé, partagée par toutes les installations) — permet à
  // ReceiptScannerService/AISmartScanDialog d'afficher un message précis
  // ("service IA indisponible") au lieu de laisser croire que la photo ou le
  // document scanné est en cause (voir deepseek_service.dart, même drapeau).
  static bool quotaExceeded = false;

  static Future<String> extractRawText(File imageFile) async {
    quotaExceeded = false;
    print('=== Mistral OCR: extracting raw text ===');
    try {
      final bytes    = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final dataUrl  = 'data:$mimeType;base64,${base64Encode(bytes)}';
      print('✅ Image encoded (${bytes.length} bytes, $mimeType)');

      final result = await _callOcrApi(dataUrl);
      if (result == null) {
        print('❌ Mistral OCR API returned null');
        return '';
      }

      final pages = result['pages'] as List?;
      if (pages == null || pages.isEmpty) {
        print('⚠️ Mistral OCR: no pages in response');
        return '';
      }

      final buffer = StringBuffer();
      for (final page in pages) {
        final markdown = page['markdown'] as String?;
        if (markdown != null && markdown.isNotEmpty) {
          buffer.writeln(markdown);
        }
      }

      final text = buffer.toString();
      print('✅ Mistral OCR extracted ${text.length} characters of text');
      return text;
    } catch (e) {
      print('Mistral OCR error: $e');
      return '';
    }
  }

  static Future<Map<String, dynamic>?> _callOcrApi(String dataUrl) async {
    try {
      final requestBody = {
        "model": "mistral-ocr-latest",
        "document": {
          "type": "image_url",
          "image_url": dataUrl,
        },
        "include_image_base64": false,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/ocr'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode(requestBody),
      );

      print('Mistral OCR response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print(response.body);
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        if (response.statusCode == 429) quotaExceeded = true;
        print('Mistral OCR failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Mistral OCR API error: $e');
      return null;
    }
  }
}