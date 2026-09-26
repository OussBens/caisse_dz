import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:caisse_dz/Services/OpenFoodFactsService.dart' show ProduitAISuggestion;
import 'package:caisse_dz/Services/open_facts_client.dart';

/// Levée quand la recherche Mantouj échoue pour une raison technique (réseau,
/// DNS, timeout, réponse invalide) — à distinguer d'un simple "produit non
/// trouvé" (qui retourne null), afin que la cascade puisse enchaîner sur la
/// source suivante sans induire l'utilisateur en erreur.
class MantoujLookupException implements Exception {
  MantoujLookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Recherche de produit par code-barres via **Mantouj**, la plateforme GS1
/// dédiée aux produits maghrébins (GS1 Algérie). Positionnée dans la cascade
/// IA juste après le catalogue CaisseDZ et avant Open Food / Open Beauty Facts
/// (voir [CatalogService]) : les codes-barres locaux (préfixe 613…) y sont
/// mieux couverts que dans les bases internationales.
///
/// L'implémentation reste volontairement défensive : tout champ absent est
/// simplement ignoré, et toute erreur technique est convertie en
/// [MantoujLookupException] pour laisser la cascade continuer.
class MantoujService {
  /// Point d'accès de l'API Mantouj (GS1). Le code-barres est ajouté en fin
  /// d'URL. À ajuster si l'endpoint officiel diffère.
  static const String _baseUrl =
      'https://api.mantouj.dz/api/v1/products/barcode';

  static const Duration _timeout = Duration(seconds: 10);

  /// Retourne null si le produit n'existe pas côté Mantouj.
  /// Lève [MantoujLookupException] en cas d'échec technique.
  static Future<ProduitAISuggestion?> lookupByBarcode(String barcode) async {
    final uri = Uri.parse('$_baseUrl/$barcode');

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: const {
          'User-Agent': 'CaisseDZ - Windows - Version 1.0',
          'Accept': 'application/json',
        },
      ).timeout(_timeout);
    } catch (e) {
      debugPrint('MantoujService: échec requête pour $barcode: $e');
      throw MantoujLookupException('Erreur réseau: $e');
    }

    // 404 = produit non répertorié (résultat métier normal), pas une panne.
    if (response.statusCode == 404) {
      debugPrint('MantoujService: produit non trouvé pour $barcode');
      return null;
    }
    if (response.statusCode != 200) {
      debugPrint('MantoujService: HTTP ${response.statusCode} pour $barcode');
      throw MantoujLookupException('Erreur HTTP ${response.statusCode}');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (e) {
      debugPrint('MantoujService: réponse JSON invalide pour $barcode: $e');
      throw MantoujLookupException('Réponse invalide: $e');
    }

    // La fiche produit peut être renvoyée directement ou encapsulée
    // (`data`/`product`/`result`) selon l'implémentation de l'API.
    final Map<String, dynamic>? product = _extractProduct(decoded);
    if (product == null) return null;

    final nom = _firstNonEmpty(product, const ['nom', 'name', 'product_name', 'libelle', 'designation']);
    if (nom == null) return null;

    final marque = _firstNonEmpty(product, const ['marque', 'brand', 'brands', 'fabricant']);
    final categorie = _firstNonEmpty(product, const ['categorie', 'category', 'categories', 'famille']);
    final photoUrl = _firstNonEmpty(product, const ['photo', 'image', 'image_url', 'imageUrl', 'picture']);
    final taille = _firstNonEmpty(product, const ['taille', 'quantity', 'quantite', 'contenance', 'size']);
    final couleur = _firstNonEmpty(product, const ['couleur', 'color']);

    return ProduitAISuggestion(
      nom: nom,
      marque: marque,
      categorie: categorie,
      codeBarre: barcode,
      photoUrl: photoUrl,
      taille: taille,
      couleur: couleur,
      sourceLabel: 'Mantouj (GS1)',
    );
  }

  /// Télécharge et compresse la photo produit (réutilise l'outil pur-Dart
  /// partagé avec les sources Open Facts, compatible Windows desktop).
  static Future<String?> downloadAndCompressPhoto(String photoUrl) {
    return OpenFactsClient.downloadAndCompressPhoto(photoUrl);
  }

  static Map<String, dynamic>? _extractProduct(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['product', 'data', 'result']) {
        final inner = decoded[key];
        if (inner is Map<String, dynamic>) return inner;
        if (inner is List && inner.isNotEmpty && inner.first is Map<String, dynamic>) {
          return inner.first as Map<String, dynamic>;
        }
      }
      return decoded;
    }
    if (decoded is List && decoded.isNotEmpty && decoded.first is Map<String, dynamic>) {
      return decoded.first as Map<String, dynamic>;
    }
    return null;
  }

  /// Première valeur non vide parmi une liste de clés candidates. Gère les
  /// valeurs listes (`brands: [...]`) en prenant le premier élément.
  static String? _firstNonEmpty(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      String? text;
      if (value is String) {
        text = value.trim();
      } else if (value is List && value.isNotEmpty) {
        text = value.first?.toString().trim();
      } else if (value is num) {
        text = value.toString();
      }
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }
}
