import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:caisse_dz/Services/ai_proxy.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';

/// OCR des bons via le serveur BENS (POST /smartscan/scan), qui vérifie la
/// licence et le quota du client puis appelle Mistral avec sa propre clé.
/// Un scan n'est décompté par le serveur que s'il a réussi.
class MistralOCRService {
  /// Identifiant du dernier scan réussi : l'analyse des lignes
  /// (GeminiService) y est rattachée côté serveur.
  static int? dernierScanId;

  /// Quota renvoyé par le serveur après le dernier scan réussi.
  static SmartScanQuota? dernierQuota;

  /// Refus / échec du dernier scan (quota atteint, licence, réseau…).
  static SmartScanErreur? derniereErreur;

  static bool get quotaExceeded => derniereErreur?.estQuotaAtteint ?? false;

  static Future<String> extractRawText(File imageFile) async {
    dernierScanId = null;
    derniereErreur = null;
    try {
      final bytes = await imageFile.readAsBytes();
      final mimeType = lookupMimeType(imageFile.path) ?? 'image/jpeg';
      final dataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';

      final response = await http
          .post(
            Uri.parse('${AiProxy.baseUrl}/scan'),
            headers: await AiProxy.enTetes(),
            body: jsonEncode({'image': dataUrl}),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode != 200) {
        derniereErreur = AiProxy.erreurServeur(response) ??
            SmartScanErreur('HTTP_${response.statusCode}', response.reasonPhrase ?? '');
        print('Smart Scan refusé: ${derniereErreur!.code}');
        return '';
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      dernierScanId = (json['scan_id'] as num?)?.toInt();
      final quota = json['quota'];
      if (quota is Map) dernierQuota = SmartScanQuota.fromJson(Map<String, dynamic>.from(quota));
      final text = json['text']?.toString() ?? '';
      print('✅ Smart Scan OCR: ${text.length} caractères');
      return text;
    } catch (e) {
      print('Smart Scan OCR error: $e');
      derniereErreur = SmartScanErreur(SmartScanErreur.reseau, e.toString());
      return '';
    }
  }
}
