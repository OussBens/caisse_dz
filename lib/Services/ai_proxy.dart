import 'dart:convert';

import 'package:caisse_dz/Services/EntrepriseParam.dart';
import 'package:caisse_dz/Services/machine_binding_service.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/data/models/smart_scan_quota.dart';
import 'package:http/http.dart' as http;

/// Accès au service Smart Scan (OCR + analyse des bons) via le serveur BENS,
/// qui détient la clé Mistral, vérifie la licence et applique les quotas
/// par client (routes /smartscan/* de catalog-api.bensds.com).
///
/// Aucune clé Mistral dans l'application : le poste s'authentifie par sa
/// licence (identifiant machine + clé, même calcul que l'activation).
class AiProxy {
  // Production par défaut ; un serveur de test peut être utilisé au lancement :
  // flutter run --dart-define=SMARTSCAN_URL=http://127.0.0.1:8765/smartscan
  static const String baseUrl = String.fromEnvironment(
    'SMARTSCAN_URL',
    defaultValue: 'https://catalog-api.bensds.com/smartscan',
  );

  static String? _entreprise;

  static Future<Map<String, String>> enTetes() async {
    final deviceId = await MachineBindingService().getDeviceId();
    // Nom de la boutique : sert à nommer le client à son premier scan
    // (renommable ensuite dans l'administration BENS).
    if (_entreprise == null) {
      try {
        _entreprise = (await EntrepriseParamServices.getEntrepriseParam()).nomBoutique;
      } catch (_) {
        _entreprise = '';
      }
    }
    return {
      'Content-Type': 'application/json',
      'X-Device-Id': deviceId,
      'X-License-Key': AuthState().cleLicence(deviceId),
      if (_entreprise!.isNotEmpty) 'X-Entreprise': Uri.encodeComponent(_entreprise!),
    };
  }

  /// Refus du serveur Smart Scan ({success:false, error, …}) — par
  /// opposition à une réponse Mistral relayée. Null si ce n'en est pas un.
  static SmartScanErreur? erreurServeur(http.Response response) {
    if (response.statusCode == 200) return null;
    try {
      final json = jsonDecode(response.body);
      if (json is Map && json['success'] == false && json['error'] is String) {
        final quota = json['quota'];
        return SmartScanErreur(
          json['error'] as String,
          json['message']?.toString() ?? '',
          quota: quota is Map ? SmartScanQuota.fromJson(Map<String, dynamic>.from(quota)) : null,
        );
      }
    } catch (_) {
      // Corps non JSON (proxy, page d'erreur) : traité par l'appelant.
    }
    return null;
  }
}
