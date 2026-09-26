import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'Photos.dart';

/// Levée quand la recherche échoue pour une raison technique (réseau, DNS,
/// timeout, réponse invalide) — à distinguer d'un simple "produit non
/// trouvé" (qui retourne null) pour ne pas induire l'utilisateur en erreur.
class OpenFactsLookupException implements Exception {
  OpenFactsLookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Suggestion de produit trouvée via l'une des API publiques "Open ... Facts"
/// (Open Food Facts, Open Pet Food Facts, Open Beauty Facts) pour un
/// code-barres scanné, à faire confirmer par l'utilisateur avant remplissage.
class OpenFactsSuggestion {
  final String? nom;
  final String? marque;
  final String? categorie;
  final String? codeBarre;
  final String? photoUrl;
  final String? taille;
  final String? couleur;
  final String sourceLabel;

  const OpenFactsSuggestion({
    this.nom,
    this.marque,
    this.categorie,
    this.codeBarre,
    this.photoUrl,
    this.taille,
    this.couleur,
    required this.sourceLabel,
  });
}

/// Client HTTP générique pour la famille d'API publiques "Product Opener"
/// (Open Food Facts / Open Pet Food Facts / Open Beauty Facts), qui partagent
/// toutes le même schéma JSON `/api/v2/product/{barcode}.json`. Appelé
/// directement en HTTP (pas de package wrapper : ni truthinscanner ni
/// media_compressor ne supportent Windows desktop).
class OpenFactsClient {
  OpenFactsClient({required String baseUrl, required this.sourceLabel})
      : _baseUrl = baseUrl;

  final String _baseUrl;
  final String sourceLabel;
  static const int _maxPhotoBytes = 500 * 1024;

  /// Retourne null si le produit n'existe pas dans la base.
  /// Lève [OpenFactsLookupException] en cas d'échec technique (réseau,
  /// timeout, réponse invalide) plutôt que de retourner null silencieusement,
  /// pour que l'UI puisse afficher un message différent de "n'existe pas".
  Future<OpenFactsSuggestion?> lookupByBarcode(String barcode) async {
    final uri = Uri.parse(
      '$_baseUrl/$barcode.json?fields=product_name,brands,categories,image_front_url,image_url,quantity',
    );

    http.Response response;
    try {
      response = await http.get(
        uri,
        headers: const {'User-Agent': 'CaisseDZ - Windows - Version 1.0'},
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('OpenFactsClient($sourceLabel): échec requête pour $barcode: $e');
      throw OpenFactsLookupException('Erreur réseau: $e');
    }

    if (response.statusCode != 200) {
      debugPrint('OpenFactsClient($sourceLabel): HTTP ${response.statusCode} pour $barcode');
      throw OpenFactsLookupException('Erreur HTTP ${response.statusCode}');
    }

    final Map<String, dynamic> data;
    try {
      data = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OpenFactsClient($sourceLabel): réponse JSON invalide pour $barcode: $e');
      throw OpenFactsLookupException('Réponse invalide: $e');
    }

    if (data['status'] != 1) {
      debugPrint('OpenFactsClient($sourceLabel): produit non trouvé pour $barcode (status=${data['status']})');
      return null; // 0 = produit non trouvé
    }

    final product = data['product'] as Map<String, dynamic>?;
    if (product == null) return null;

    final nom = (product['product_name'] as String?)?.trim();
    if (nom == null || nom.isEmpty) return null;

    final marque = (product['brands'] as String?)?.split(',').first.trim();
    // "categories" est une liste de tags séparés par virgules, du plus
    // générique au plus spécifique (ex. "Snacks, Snacks sucrés, Biscuits") ;
    // le dernier tag est le plus proche d'une catégorie locale exploitable.
    final categoriesRaw = (product['categories'] as String?)?.split(',') ?? [];
    final categorie = categoriesRaw.isEmpty ? null : categoriesRaw.last.trim();
    final photoUrl = (product['image_front_url'] ?? product['image_url']) as String?;
    final taille = (product['quantity'] as String?)?.trim();

    return OpenFactsSuggestion(
      nom: nom,
      marque: (marque != null && marque.isNotEmpty) ? marque : null,
      categorie: (categorie != null && categorie.isNotEmpty) ? categorie : null,
      codeBarre: barcode,
      photoUrl: (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null,
      taille: (taille != null && taille.isNotEmpty) ? taille : null,
      couleur: null, // non exposé par cette famille d'API
      sourceLabel: sourceLabel,
    );
  }

  /// Télécharge la photo produit et la compresse sous 500 Ko en pur Dart
  /// (package `image`, sans plugin natif indisponible sur Windows). Le
  /// fichier est nommé selon la convention 'temp_...' déjà utilisée par
  /// ButtonAddPhoto pour une photo pas encore rattachée à un produit.
  static Future<String?> downloadAndCompressPhoto(String photoUrl) async {
    try {
      final response = await http.get(Uri.parse(photoUrl)).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) return null;

      final image = img.decodeImage(response.bodyBytes);
      if (image == null) return null;

      int quality = 90;
      List<int> encoded = img.encodeJpg(image, quality: quality);
      while (encoded.length > _maxPhotoBytes && quality > 30) {
        quality -= 10;
        encoded = img.encodeJpg(image, quality: quality);
      }

      final tempPath = PhotoService.buildTempPhotoPath('.jpg');
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(encoded);
      return tempFile.path;
    } catch (_) {
      return null;
    }
  }
}
