import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:caisse_dz/Services/simple_cache.dart';
import 'package:caisse_dz/data/models/catalog_product.dart';

/// Levée en cas d'échec technique (réseau, HTTP, réponse invalide) lors d'un
/// appel à l'API du catalogue distant bensds.com.
class CatalogApiException implements Exception {
  CatalogApiException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Page de résultats renvoyée par les endpoints de liste/recherche.
class CatalogPage {
  final List<CatalogProduct> items;
  final int page;
  final int totalPages;

  const CatalogPage({required this.items, required this.page, required this.totalPages});
}

/// Client HTTP pour l'API du catalogue produit distant bensds.com
/// (https://catalog-api.bensds.com). Suit les mêmes conventions que
/// [OpenFoodFactsService] : `http` package brut, exceptions dédiées, pas de
/// dépendance ajoutée. Toutes les réponses suivent l'enveloppe
/// `{"success": bool, "data": ...}`.
///
/// Les lectures sont publiques ; toute écriture (POST/PUT/DELETE, upload
/// photo) exige le header `X-API-Key`, qui doit correspondre à `API_KEY` dans
/// le `.env` du serveur. Le header est envoyé sur toutes les requêtes.
class CatalogApiService {
  static const String _baseUrl = 'https://catalog-api.bensds.com';
  static const String _apiKey = 'dbd176fec8095b043eabd805f3be731bb00ccf4a8765dfdce5c17f77a7f53790';
  static const Duration _timeout = Duration(seconds: 10);

  static final TtlCache<String, List<String>> _lookupCache =
      TtlCache(ttl: const Duration(minutes: 15), maxEntries: 20);
  static final TtlCache<String, CatalogProduct?> _barcodeCache =
      TtlCache(ttl: const Duration(minutes: 10), maxEntries: 50);

  Map<String, String> get _headers => const {
        'Content-Type': 'application/json',
        'User-Agent': 'CaisseDZ - Windows - Version 1.0',
        'X-API-Key': _apiKey,
      };

  Future<http.Response> _get(String path) async {
    try {
      return await http
          .get(Uri.parse('$_baseUrl$path'), headers: _headers)
          .timeout(_timeout);
    } catch (e) {
      debugPrint('CatalogApiService: échec GET $path: $e');
      throw CatalogApiException('Erreur réseau: $e');
    }
  }

  Future<http.Response> _send(String method, String path, Map<String, dynamic> body) async {
    try {
      final uri = Uri.parse('$_baseUrl$path');
      final encoded = jsonEncode(body);
      final response = switch (method) {
        'POST' => await http.post(uri, headers: _headers, body: encoded).timeout(_timeout),
        'PUT' => await http.put(uri, headers: _headers, body: encoded).timeout(_timeout),
        _ => throw ArgumentError('Méthode non supportée: $method'),
      };
      return response;
    } catch (e) {
      debugPrint('CatalogApiService: échec $method $path: $e');
      throw CatalogApiException('Erreur réseau: $e');
    }
  }

  /// Décode l'enveloppe `{success, data}` commune à tous les endpoints.
  /// Retourne `null` si `success` est faux (traité comme "non trouvé" par
  /// les méthodes de recherche) ; lève [CatalogApiException] sur un échec
  /// HTTP ou une réponse JSON invalide.
  dynamic _decodeEnvelope(http.Response response, String path) {
    if (response.statusCode == 404) return null;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('CatalogApiService: HTTP ${response.statusCode} pour $path');
      throw CatalogApiException('Erreur HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> decoded;
    try {
      decoded = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      throw CatalogApiException('Réponse invalide: $e');
    }

    if (decoded['success'] != true) return null;
    return decoded['data'];
  }

  CatalogPage _decodePage(dynamic data, int fallbackPage) {
    if (data is List) {
      return CatalogPage(
        items: data.map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>)).toList(),
        page: fallbackPage,
        totalPages: 1,
      );
    }
    if (data is Map<String, dynamic>) {
      final rawItems = (data['items'] ?? data['products'] ?? data['results'] ?? []) as List;
      final totalPages = data['totalPages'] ?? data['total_pages'];
      return CatalogPage(
        items: rawItems.map((e) => CatalogProduct.fromJson(e as Map<String, dynamic>)).toList(),
        page: (data['page'] as int?) ?? fallbackPage,
        totalPages: totalPages is int ? totalPages : 1,
      );
    }
    return CatalogPage(items: const [], page: fallbackPage, totalPages: 1);
  }

  /// GET /products - liste paginée.
  Future<CatalogPage> getProducts({int page = 1, int limit = 20}) async {
    final response = await _get('/products?page=$page&limit=$limit');
    final data = _decodeEnvelope(response, '/products');
    return _decodePage(data, page);
  }

  /// GET /products/{id}
  Future<CatalogProduct?> getProductById(int id) async {
    final response = await _get('/products/$id');
    final data = _decodeEnvelope(response, '/products/$id');
    if (data == null) return null;
    return CatalogProduct.fromJson(data as Map<String, dynamic>);
  }

  /// GET /products/search?q={query}&page=1&limit=20
  Future<CatalogPage> search(String query, {int page = 1, int limit = 20}) async {
    final response = await _get('/products/search?q=${Uri.encodeQueryComponent(query)}&page=$page&limit=$limit');
    final data = _decodeEnvelope(response, '/products/search');
    return _decodePage(data, page);
  }

  /// GET /products/barcode/{barcode} - deuxième maillon de la cascade IA
  /// (voir [CatalogService]). Résultat mis en cache 10 min pour accélérer
  /// les scans répétés du même code-barres pendant une session de saisie.
  Future<CatalogProduct?> searchByBarcode(String barcode) async {
    if (_barcodeCache.has(barcode)) {
      return _barcodeCache.get(barcode);
    }
    final response = await _get('/products/barcode/$barcode');
    final data = _decodeEnvelope(response, '/products/barcode/$barcode');
    final result = data == null ? null : CatalogProduct.fromJson(data as Map<String, dynamic>);
    _barcodeCache.set(barcode, result);
    return result;
  }

  /// GET /brands - noms des marques, mis en cache 15 min (liste de
  /// référence qui change rarement).
  Future<List<String>> getBrands() async {
    final cached = _lookupCache.get('brands');
    if (cached != null) return cached;

    final response = await _get('/brands');
    final data = _decodeEnvelope(response, '/brands');
    final names = _extractNames(data);
    _lookupCache.set('brands', names);
    return names;
  }

  /// GET /categories - noms des catégories (liste plate), mis en cache 15 min.
  Future<List<String>> getCategories() async {
    final cached = _lookupCache.get('categories');
    if (cached != null) return cached;

    final response = await _get('/categories');
    final data = _decodeEnvelope(response, '/categories');
    final names = _extractNames(data);
    _lookupCache.set('categories', names);
    return names;
  }

  /// GET /categories/tree - arborescence brute des catégories (non mise en
  /// cache : consommée seulement par l'écran d'admin, appel peu fréquent).
  Future<List<Map<String, dynamic>>> getCategoriesTree() async {
    final response = await _get('/categories/tree');
    final data = _decodeEnvelope(response, '/categories/tree');
    if (data is List) return data.cast<Map<String, dynamic>>();
    return const [];
  }

  List<String> _extractNames(dynamic data) {
    if (data is! List) return const [];
    return data
        .map((e) => e is Map<String, dynamic> ? (e['nom'] ?? e['name'])?.toString() : e?.toString())
        .whereType<String>()
        .where((s) => s.isNotEmpty)
        .toList();
  }

  /// POST /products - crée un produit sur le catalogue distant. `brand` et
  /// `category` sont envoyés en texte : le serveur fait l'upsert de la
  /// marque/catégorie correspondante (confirmé par le propriétaire de
  /// l'API).
  Future<CatalogProduct> createProduct(CatalogProduct product) async {
    final response = await _send('POST', '/products', product.toJson());
    final data = _decodeEnvelope(response, '/products');
    if (data == null) throw CatalogApiException('Échec de création du produit sur le catalogue');
    return CatalogProduct.fromJson(data as Map<String, dynamic>);
  }

  /// PUT /products/{id} - met à jour un produit existant sur le catalogue.
  Future<CatalogProduct> updateProduct(int id, CatalogProduct product) async {
    final response = await _send('PUT', '/products/$id', product.toJson());
    final data = _decodeEnvelope(response, '/products/$id');
    if (data == null) throw CatalogApiException('Échec de mise à jour du produit sur le catalogue');
    return CatalogProduct.fromJson(data as Map<String, dynamic>);
  }

  /// POST /products/{id}/photo - téléverse la photo principale du produit
  /// (multipart, champ `photo`). Le serveur stocke le fichier et renvoie
  /// l'URL publique désormais enregistrée dans `catalog_product.photo`.
  Future<String> uploadProductPhoto(int id, File photoFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/products/$id/photo');
      final request = http.MultipartRequest('POST', uri)
        ..headers['User-Agent'] = _headers['User-Agent']!
        ..headers['X-API-Key'] = _apiKey
        ..files.add(await http.MultipartFile.fromPath('photo', photoFile.path));
      final streamedResponse = await request.send().timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      final data = _decodeEnvelope(response, '/products/$id/photo');
      if (data is! Map<String, dynamic> || data['photo'] is! String) {
        throw CatalogApiException('Échec de l\'envoi de la photo sur le catalogue');
      }
      return data['photo'] as String;
    } on CatalogApiException {
      rethrow;
    } catch (e) {
      debugPrint('CatalogApiService: échec upload photo produit $id: $e');
      throw CatalogApiException('Erreur réseau: $e');
    }
  }

  /// DELETE /products/{id} - suppression définitive (aucun soft-delete côté
  /// serveur pour cette ressource).
  Future<void> deleteProduct(int id) async {
    try {
      final response = await http
          .delete(Uri.parse('$_baseUrl/products/$id'), headers: _headers)
          .timeout(_timeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw CatalogApiException('Erreur HTTP ${response.statusCode}');
      }
    } on CatalogApiException {
      rethrow;
    } catch (e) {
      throw CatalogApiException('Erreur réseau: $e');
    }
  }
}
