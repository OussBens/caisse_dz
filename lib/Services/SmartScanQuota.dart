import 'dart:convert';

import 'package:caisse_dz/Services/ai_proxy.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';
import 'package:http/http.dart' as http;

/// Quota et offres Smart Scan du client (serveur BENS). L'application ne
/// fait qu'afficher : le serveur décide seul si un scan est autorisé.
class SmartScanQuotaServices {
  /// Quota du client, ou null si le serveur est injoignable.
  static Future<SmartScanQuota?> getQuota() async {
    try {
      final response = await http
          .get(Uri.parse('${AiProxy.baseUrl}/quota'), headers: await AiProxy.enTetes())
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;
      final json = jsonDecode(response.body);
      return SmartScanQuota.fromJson(Map<String, dynamic>.from(json['quota'] as Map));
    } catch (_) {
      return null;
    }
  }

  /// Envoie une demande d'offre (activée ensuite depuis l'administration).
  /// Renvoie (succès, déjà demandée, contact).
  static Future<({bool succes, bool dejaDemandee, String contact})> demanderOffre(String codeOffre) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AiProxy.baseUrl}/demande'),
            headers: await AiProxy.enTetes(),
            body: jsonEncode({'offre': codeOffre}),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return (succes: false, dejaDemandee: false, contact: '');
      final json = jsonDecode(response.body) as Map;
      return (
        succes: json['success'] == true,
        dejaDemandee: json['deja_demandee'] == true,
        contact: json['contact']?.toString() ?? '',
      );
    } catch (_) {
      return (succes: false, dejaDemandee: false, contact: '');
    }
  }
}
