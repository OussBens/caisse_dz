import 'package:flutter/foundation.dart';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CatalogApiService.dart';
import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/Services/Photos.dart';
import 'package:caisse_dz/data/models/catalog_product.dart';
import 'package:caisse_dz/data/models/catalog_sync.dart';
import 'package:caisse_dz/data/models/produit.dart';

/// Pousse les produits créés localement vers le catalogue distant bensds.com,
/// et tient à jour la table de correspondance `catalog_sync`.
///
/// Architecture offline-first : la sauvegarde locale SQLite est toujours la
/// source de vérité. Un échec réseau ici ne doit jamais remonter comme une
/// erreur de sauvegarde produit — il est journalisé dans `catalog_sync`
/// (`sync_status = 'error'`) pour permettre une resynchronisation future,
/// mais avalé silencieusement du point de vue de l'appelant.
class CatalogSyncService {
  CatalogSyncService({CatalogApiService? catalogApiService})
      : _catalogApiService = catalogApiService ?? CatalogApiService();

  final CatalogApiService _catalogApiService;

  /// Crée ou met à jour le produit correspondant sur le catalogue distant.
  /// Ne lève jamais d'exception : les erreurs sont journalisées localement
  /// (`catalog_sync.sync_status = 'error'`) et via `debugPrint`. Retourne
  /// `true`/`false` uniquement pour permettre à l'appelant d'afficher une
  /// notification discrète en cas d'échec — la sauvegarde locale du produit
  /// n'est elle jamais conditionnée à ce résultat.
  ///
  /// [barcodesSupplementaires] : codes-barres additionnels d'un produit
  /// multicode (contenu de `produit_code_detail`), à fournir par l'appelant
  /// — au moment de l'appel, ces lignes ne sont pas encore forcément
  /// enregistrées en base locale (`_saveProduitCodeDetailes` est appelé
  /// après dans `ProduitNouveau`), donc on ne les relit pas nous-mêmes ici.
  Future<bool> pushProduitToCatalog(
    Produit produit, {
    List<String> barcodesSupplementaires = const [],
  }) async {
    // Le catalogue distant sert avant tout à la recherche inter-boutiques par
    // code-barres (cascade de lookup dans CatalogService) ; un produit créé
    // localement sans aucun code-barres ("produit sans code-barres" dans
    // ProduitNouveau) n'y a pas sa place et le serveur le rejette de toute
    // façon (barcode obligatoire sur POST /products). On l'ignore donc
    // silencieusement, sans le journaliser en erreur dans `catalog_sync`.
    //
    // ⚠️ Pour un produit multicode, `produit.codeBarre` est vide (le champ
    // unique n'est pas utilisé dans ce mode) : c'est `barcodesSupplementaires`
    // qui porte les codes. Il faut donc regarder les DEUX avant de conclure
    // à "aucun code-barres", sinon tout produit multicode est ignoré ici en
    // silence et n'est jamais poussé vers le serveur.
    final tousLesCodes = <String>{
      if (produit.codeBarre != null && produit.codeBarre!.trim().isNotEmpty) produit.codeBarre!.trim(),
      ...barcodesSupplementaires.map((c) => c.trim()).where((c) => c.isNotEmpty),
    }.toList();

    if (tousLesCodes.isEmpty) {
      return true;
    }

    final db = await DbCreator.openDb();

    final existingMaps = await db.query(
      'catalog_sync',
      where: 'produit_code = ?',
      whereArgs: [produit.code],
      limit: 1,
    );
    final existing = existingMaps.isEmpty ? null : CatalogSync.fromMap(existingMaps.first);

    try {
      final CatalogProduct pushed;
      // `code_produit` = code-barres principal du produit (le premier pour
      // un produit multicode) : un vrai code-barres est déjà unique par
      // nature, contrairement à `produit.code` local (ex. "PRD000123") qui
      // pourrait entrer en collision entre deux boutiques CaisseDZ
      // distinctes poussant vers le même catalogue partagé.
      final codeProduit = existing?.codeProduit ?? tousLesCodes.first;
      final categorieNom = (await CategorieServices(db).getCategorieById(produit.categorieId))?.nom;
      final payload = CatalogProduct(
        codeProduit: codeProduit,
        nom: produit.nom,
        description: produit.description,
        marque: produit.marque,
        categorie: categorieNom,
        couleur: produit.couleur,
        taille: produit.taille,
        barcode: tousLesCodes.first,
        barcodes: tousLesCodes,
      );

      if (existing?.catalogProductId != null) {
        pushed = await _catalogApiService.updateProduct(existing!.catalogProductId!, payload);
      } else {
        pushed = await _catalogApiService.createProduct(payload);
      }

      final catalogProductId = pushed.id ?? existing?.catalogProductId;
      if (catalogProductId != null && produit.photo != null && produit.photo!.isNotEmpty) {
        try {
          final photoFile = await PhotoService.getPhotoFile(produit.photo);
          if (photoFile != null) {
            await _catalogApiService.uploadProductPhoto(catalogProductId, photoFile);
          }
        } catch (e) {
          debugPrint('CatalogSyncService: échec upload photo pour ${produit.code}: $e');
        }
      }

      final row = CatalogSync(
        id: existing?.id,
        produitCode: produit.code,
        catalogProductId: catalogProductId,
        codeProduit: pushed.codeProduit,
        syncStatus: 'success',
        lastError: null,
        syncedAt: DateTime.now(),
        dateCree: existing?.dateCree ?? DateTime.now(),
      );
      await _saveSyncRow(row, hasExisting: existing != null);
      return true;
    } catch (e) {
      debugPrint('CatalogSyncService: échec de synchronisation pour ${produit.code}: $e');
      final row = CatalogSync(
        id: existing?.id,
        produitCode: produit.code,
        catalogProductId: existing?.catalogProductId,
        codeProduit: existing?.codeProduit,
        syncStatus: 'error',
        lastError: e.toString(),
        syncedAt: existing?.syncedAt,
        dateCree: existing?.dateCree ?? DateTime.now(),
      );
      await _saveSyncRow(row, hasExisting: existing != null);
      return false;
    }
  }

  /// Supprime le suivi de synchronisation local pour ce produit (appelé
  /// lorsqu'un produit local est supprimé). Ne touche jamais au catalogue
  /// distant : la fiche partagée peut être référencée par d'autres
  /// installations CaisseDZ et ne doit pas disparaître à cause d'une
  /// suppression locale.
  Future<void> deleteSyncRow(String produitCode) async {
    final db = await DbCreator.openDb();
    await db.delete('catalog_sync', where: 'produit_code = ?', whereArgs: [produitCode]);
  }

  Future<void> _saveSyncRow(CatalogSync row, {required bool hasExisting}) async {
    final db = await DbCreator.openDb();
    if (hasExisting) {
      await db.update('catalog_sync', row.toMap(), where: 'produit_code = ?', whereArgs: [row.produitCode]);
    } else {
      await db.insert('catalog_sync', row.toMap()..remove('id'));
    }
  }
}
