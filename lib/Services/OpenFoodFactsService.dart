import 'package:caisse_dz/Services/open_facts_client.dart';

/// Levée quand la recherche échoue pour une raison technique (réseau, DNS,
/// timeout, réponse invalide) — à distinguer d'un simple "produit non
/// trouvé" (qui retourne null) pour ne pas induire l'utilisateur en erreur.
class OpenFoodFactsLookupException implements Exception {
  OpenFoodFactsLookupException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Suggestion de produit trouvée via l'API publique Open Food Facts (ou une
/// autre source de la cascade IA, voir [CatalogService]) pour un code-barres
/// scanné, à faire confirmer par l'utilisateur avant remplissage.
class ProduitAISuggestion {
  final String? nom;
  final String? marque;
  final String? categorie;
  final String? codeBarre;
  final String? photoUrl;
  final String? taille;
  final String? couleur;

  /// Libellé affichable de la source ayant fourni la suggestion (ex.
  /// "Open Food Facts", "Catalogue CaisseDZ"). Optionnel pour préserver la
  /// compatibilité avec le code existant qui construisait ce type sans ce
  /// champ.
  final String? sourceLabel;

  const ProduitAISuggestion({
    this.nom,
    this.marque,
    this.categorie,
    this.codeBarre,
    this.photoUrl,
    this.taille,
    this.couleur,
    this.sourceLabel,
  });
}

/// Recherche de produit par code-barres via l'API REST publique Open Food
/// Facts. Délègue au client HTTP générique partagé avec les autres sources
/// "Product Opener" (Open Pet Food Facts, Open Beauty Facts) — voir
/// [OpenFactsClient] — sans changer la signature publique historique de ce
/// service pour ne pas casser les appelants existants.
class OpenFoodFactsService {
  static final OpenFactsClient _client = OpenFactsClient(
    baseUrl: 'https://world.openfoodfacts.org/api/v2/product',
    sourceLabel: 'Open Food Facts',
  );

  /// Retourne null si le produit n'existe pas dans la base Open Food Facts.
  /// Lève [OpenFoodFactsLookupException] en cas d'échec technique (réseau,
  /// timeout, réponse invalide) plutôt que de retourner null silencieusement,
  /// pour que l'UI puisse afficher un message différent de "n'existe pas".
  static Future<ProduitAISuggestion?> lookupByBarcode(String barcode) async {
    try {
      final result = await _client.lookupByBarcode(barcode);
      if (result == null) return null;
      return ProduitAISuggestion(
        nom: result.nom,
        marque: result.marque,
        categorie: result.categorie,
        codeBarre: result.codeBarre,
        photoUrl: result.photoUrl,
        taille: result.taille,
        couleur: result.couleur,
        sourceLabel: result.sourceLabel,
      );
    } on OpenFactsLookupException catch (e) {
      throw OpenFoodFactsLookupException(e.message);
    }
  }

  /// Télécharge la photo produit et la compresse sous 500 Ko.
  static Future<String?> downloadAndCompressPhoto(String photoUrl) {
    return OpenFactsClient.downloadAndCompressPhoto(photoUrl);
  }
}
