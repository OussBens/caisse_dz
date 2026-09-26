import 'package:flutter/foundation.dart';

import 'package:caisse_dz/Services/CatalogApiService.dart';
import 'package:caisse_dz/Services/MantoujService.dart';
import 'package:caisse_dz/Services/OpenBeautyFactsService.dart';
// Fournit le type partagé ProduitAISuggestion ainsi que la recherche Open Food.
import 'package:caisse_dz/Services/OpenFoodFactsService.dart';
import 'package:caisse_dz/Services/open_facts_client.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/data/models/catalog_product.dart';
import 'package:caisse_dz/data/models/produit.dart';

/// Source ayant produit un résultat de la cascade de recherche produit.
enum CatalogLookupSource {
  local,
  catalogApi,
  mantouj,
  openFood,
  openBeauty,
}

/// Résultat unifié de [CatalogService.lookupByBarcode]. Quand
/// [source] est [CatalogLookupSource.local], [existingProduit] est renseigné
/// (le produit existe déjà dans le stock local — pas de suggestion à
/// pré-remplir, l'UI doit plutôt orienter l'utilisateur vers la fiche
/// existante). Pour toutes les autres sources, [suggestion] est renseigné.
class CatalogLookupResult {
  final CatalogLookupSource source;
  final Produit? existingProduit;
  final ProduitAISuggestion? suggestion;

  const CatalogLookupResult.local(Produit produit)
      : source = CatalogLookupSource.local,
        existingProduit = produit,
        suggestion = null;

  const CatalogLookupResult.remote(this.source, ProduitAISuggestion this.suggestion)
      : existingProduit = null;
}

/// Orchestre la recherche produit par code-barres en cascade :
///
/// 1. SQLite local (`ProduitServices.findProduitUsingBarcode`)
/// 2. Catalogue distant CaisseDZ (bensds.com, `CatalogApiService`)
/// 3. Mantouj — plateforme GS1 des produits maghrébins (`MantoujService`)
/// 4. Open Food Facts (`OpenFoodFactsService`)
/// 5. Open Beauty Facts (`OpenBeautyFactsService`)
///
/// Chaque maillon est interrogé seulement si les précédents n'ont rien
/// retourné. Les échecs techniques (réseau, HTTP, JSON) d'une source sont
/// avalés pour passer au maillon suivant ; seul un "introuvable partout"
/// remonte comme `null`.
///
/// Utilisé par l'onglet IA de `produit_nouveau.dart`.
class CatalogService {
  CatalogService({CatalogApiService? catalogApiService})
      : _catalogApiService = catalogApiService ?? CatalogApiService();

  final CatalogApiService _catalogApiService;

  Future<CatalogLookupResult?> lookupByBarcode(String barcode) async {
    // 1. Stock local.
    final existing = await ProduitServices.findProduitUsingBarcode(barcode);
    if (existing != null) {
      return CatalogLookupResult.local(existing);
    }

    // 2. Catalogue distant CaisseDZ.
    final fromCatalog = await _tryCatalogApi(barcode);
    if (fromCatalog != null) {
      return CatalogLookupResult.remote(CatalogLookupSource.catalogApi, fromCatalog);
    }

    // 3. Mantouj (GS1 Maghreb).
    final fromMantouj = await _tryMantouj(barcode);
    if (fromMantouj != null) {
      return CatalogLookupResult.remote(CatalogLookupSource.mantouj, fromMantouj);
    }

    // 4. Open Food Facts.
    final fromOpenFood = await _tryOpenFood(barcode);
    if (fromOpenFood != null) {
      return CatalogLookupResult.remote(CatalogLookupSource.openFood, fromOpenFood);
    }

    // 5. Open Beauty Facts.
    final fromOpenBeauty = await _tryOpenBeauty(barcode);
    if (fromOpenBeauty != null) {
      return CatalogLookupResult.remote(CatalogLookupSource.openBeauty, fromOpenBeauty);
    }

    return null;
  }

  Future<ProduitAISuggestion?> _tryCatalogApi(String barcode) async {
    try {
      final firstLookup = await _catalogApiService.searchByBarcode(barcode);
      if (firstLookup == null) return null;
      CatalogProduct product = firstLookup;

      // La recherche par code-barres peut renvoyer une fiche allégée sans
      // marque/catégorie jointe côté serveur, alors que la fiche complète
      // (par id) les a bien — cas rencontré en pratique où la marque existe
      // dans la base distante mais n'était pas remontée ici. On complète
      // dans ce cas via l'endpoint détail, sans faire échouer la recherche
      // si ce complément échoue.
      if ((product.marque == null || product.categorie == null) && product.id != null) {
        try {
          final full = await _catalogApiService.getProductById(product.id!);
          if (full != null) {
            product = CatalogProduct(
              id: product.id,
              codeProduit: product.codeProduit,
              nom: product.nom,
              description: product.description ?? full.description,
              marque: product.marque ?? full.marque,
              categorie: product.categorie ?? full.categorie,
              couleur: product.couleur ?? full.couleur,
              taille: product.taille ?? full.taille,
              photo: product.photo ?? full.photo,
              barcode: product.barcode ?? full.barcode,
            );
          }
        } on CatalogApiException catch (e) {
          debugPrint('CatalogService: complément fiche produit indisponible pour $barcode: $e');
        }
      }

      return _fromCatalogProduct(product);
    } on CatalogApiException catch (e) {
      debugPrint('CatalogService: catalogue distant indisponible pour $barcode: $e');
      return null;
    }
  }

  Future<ProduitAISuggestion?> _tryMantouj(String barcode) async {
    try {
      return await MantoujService.lookupByBarcode(barcode);
    } on MantoujLookupException catch (e) {
      debugPrint('CatalogService: Mantouj indisponible pour $barcode: $e');
      return null;
    }
  }

  Future<ProduitAISuggestion?> _tryOpenFood(String barcode) async {
    try {
      return await OpenFoodFactsService.lookupByBarcode(barcode);
    } on OpenFoodFactsLookupException catch (e) {
      debugPrint('CatalogService: Open Food Facts indisponible pour $barcode: $e');
      return null;
    }
  }

  Future<ProduitAISuggestion?> _tryOpenBeauty(String barcode) async {
    try {
      final result = await OpenBeautyFactsService.lookupByBarcode(barcode);
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
      debugPrint('CatalogService: Open Beauty Facts indisponible pour $barcode: $e');
      return null;
    }
  }

  ProduitAISuggestion _fromCatalogProduct(CatalogProduct product) {
    return ProduitAISuggestion(
      nom: product.nom,
      marque: product.marque,
      categorie: product.categorie,
      codeBarre: product.barcode,
      photoUrl: product.photo,
      taille: product.taille,
      couleur: product.couleur,
      sourceLabel: 'Catalogue CaisseDZ',
    );
  }
}
