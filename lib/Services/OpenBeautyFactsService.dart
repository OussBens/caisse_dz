import 'package:caisse_dz/Services/open_facts_client.dart';

/// Recherche de produit par code-barres via l'API REST publique Open Beauty
/// Facts (même plateforme "Product Opener" qu'Open Food Facts, même
/// schéma JSON) — cinquième et dernier maillon de la cascade IA, voir
/// [CatalogService].
class OpenBeautyFactsService {
  static final OpenFactsClient _client = OpenFactsClient(
    baseUrl: 'https://world.openbeautyfacts.org/api/v2/product',
    sourceLabel: 'Open Beauty Facts',
  );

  /// Retourne null si le produit n'existe pas dans la base.
  /// Lève [OpenFactsLookupException] en cas d'échec technique.
  static Future<OpenFactsSuggestion?> lookupByBarcode(String barcode) {
    return _client.lookupByBarcode(barcode);
  }

  static Future<String?> downloadAndCompressPhoto(String photoUrl) {
    return OpenFactsClient.downloadAndCompressPhoto(photoUrl);
  }
}
