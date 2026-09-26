/// Représente un produit tel que renvoyé par l'API du catalogue distant
/// bensds.com (table MySQL `catalog_product`, jointe à `catalog_brand` /
/// `catalog_category` / `catalog_product_barcode`). Modèle plat (pas de
/// `copyWith`, `fromMap`/`toMap`) pour suivre la convention des autres
/// modèles de `lib/data/models`.
class CatalogProduct {
  final int? id;
  final String codeProduit;
  final String nom;
  final String? description;
  final String? marque;
  final String? categorie;
  final String? couleur;
  final String? taille;
  final String? photo;
  final String? barcode;

  /// Codes-barres additionnels d'un produit multicode (ex: variantes de
  /// conditionnement du même produit). [barcode] reste le code principal
  /// (`is_primary` côté serveur) ; cette liste est envoyée en plus lors de
  /// la création pour peupler `catalog_product_barcode`. Vide pour un
  /// produit à code-barres unique.
  final List<String> barcodes;

  const CatalogProduct({
    this.id,
    required this.codeProduit,
    required this.nom,
    this.description,
    this.marque,
    this.categorie,
    this.couleur,
    this.taille,
    this.photo,
    this.barcode,
    this.barcodes = const [],
  });

  /// Tolère plusieurs formes possibles de réponse JSON pour marque/catégorie
  /// (chaîne simple `"brand": "Nike"` ou objet joint `"brand": {"nom": ...}`)
  /// pour rester robuste face à l'évolution du format de l'API serveur.
  static String? _readNested(Map<String, dynamic> json, List<String> keys, List<String> nestedKeys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) return value.trim();
      if (value is Map<String, dynamic>) {
        for (final nestedKey in nestedKeys) {
          final nested = value[nestedKey];
          if (nested is String && nested.trim().isNotEmpty) return nested.trim();
        }
      }
    }
    return null;
  }

  factory CatalogProduct.fromJson(Map<String, dynamic> json) {
    return CatalogProduct(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      codeProduit: (json['code_produit'] ?? '').toString(),
      nom: (json['nom'] ?? '').toString(),
      description: json['description'] as String?,
      marque: _readNested(json, ['brand', 'marque'], ['nom', 'name']),
      categorie: _readNested(json, ['category', 'categorie'], ['nom', 'name']),
      couleur: json['couleur'] as String?,
      taille: json['taille'] as String?,
      photo: json['photo'] as String?,
      barcode: (json['barcode'] ?? json['code_barre']) as String?,
      barcodes: (json['barcodes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code_produit': codeProduit,
      'nom': nom,
      if (description != null) 'description': description,
      if (marque != null) 'brand': marque,
      if (categorie != null) 'category': categorie,
      if (couleur != null) 'couleur': couleur,
      if (taille != null) 'taille': taille,
      if (photo != null) 'photo': photo,
      if (barcodes.isNotEmpty) 'barcodes': barcodes,
      if (barcode != null) 'barcode': barcode,
    };
  }
}
