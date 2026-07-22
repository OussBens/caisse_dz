import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';
import '../data/constant.dart';
import '../data/models/produit_code_detail.dart';
import 'Photos.dart';

/// Statistiques de stock calculées en direct pour un produit
/// (entrées, smart scans, ventes, retours) — aucune valeur n'est
/// mise en cache sur le produit lui-même.
class ProduitStats {
  final double quantiteDernierAchat;
  final DateTime? dateDernierAchat;
  final double totalAchat;
  final double totalVendu;
  final double totalRetourClient;
  final double totalRetourFournisseur;
  final bool besoin;
  final String besoinStatus;

  ProduitStats({
    required this.quantiteDernierAchat,
    required this.dateDernierAchat,
    required this.totalAchat,
    required this.totalVendu,
    required this.totalRetourClient,
    required this.totalRetourFournisseur,
    required this.besoin,
    required this.besoinStatus,
  });
}

class ProduitServices{

  final Database db;

  ProduitServices(this.db);

  static Future<List<Produit>> getAllProduits() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('produits', orderBy: 'nom ASC',);
    if (result.isNotEmpty) {
      print('Colonnes disponibles : ${result.first.keys}');
    }
    return result.map((e) => Produit.fromMap(e)).toList();

  }
  Future<void> updateCategorieNomInProducts(String oldCategorieNom, String newCategorieNom) async {
    try {
      final db = await DbCreator.openDb();
      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE produits SET categorie = ? WHERE categorie = ?',
          [newCategorieNom, oldCategorieNom],
        );
      });
      print('✅ Catégorie nom mis à jour dans les produits: $oldCategorieNom -> $newCategorieNom');
    } catch (e) {
      print('❌ Erreur updateCategorieNomInProducts: $e');
    }
  }


// Ajoutez ces méthodes dans ProduitServices.dart

  // ✅ Méthode avec transaction pour updateProduit
  Future<ApiResponse<int>> updateProduitWithTransaction(Transaction txn, Produit produit) async {
    try {
      final data = produit.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await txn.update(
        'produits',
        data,
        where: 'id = ?',
        whereArgs: [produit.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Un produit avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  // ✅ Méthode avec transaction pour getAllProduits
  static Future<List<Produit>> getAllProduitsWithTransaction(Transaction txn) async {
    final List<Map<String, dynamic>> result = await txn.query('produits', orderBy: 'nom ASC');
    return result.map((e) => Produit.fromMap(e)).toList();
  }
  static Future<int> getNextId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM produit_code_detail',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
// Services/Produits.dart - Ajoutez cette méthode
  Future<void> deleteProductWithPhotos(Produit produit) async {
    final db = await DbCreator.openDb();

    await db.transaction((txn) async {
      // Supprimer le produit
      await txn.delete(
        'produits',
        where: 'code = ?',
        whereArgs: [produit.code],
      );

      // Supprimer les photos physiquement
      await PhotoService.deletePhoto(produit.photo);

      // Supprimer les relations
      await txn.delete(
        'produit_magasin_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );

      await txn.delete(
        'produit_pack_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );

      await txn.delete(
        'produit_code_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );
    });
  }
  Future<void> deleteDetailes(String produitCode,String codebar) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_code_detail',
      where: 'produit_code = ? AND codebar = ?',
      whereArgs: [produitCode,codebar],
    );
  }

  static Future<List<ProduitCodeDetail>> getAllCodeDetailsByCode(String code) async {

    final db = await DbCreator.openDb();

    final maps = await db.query(
      'produit_code_detail',
      where: 'produit_code = ?',
      whereArgs: [code],
    );

    return maps.map((e) => ProduitCodeDetail.fromMap(e)).toList();
  }

  Future<void> deleteAllProduitCodeDetailes(String produitCode) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_code_detail',
      where: 'produit_code = ?',
      whereArgs: [produitCode],
    );
  }



  // Dans ProduitServices.dart
  // Dans ProduitServices.dart
  Future<int> addProduitCodeDetail(ProduitCodeDetail detail) async {
    try {
      print('📝 addProduitCodeDetail - Début');

      // ✅ Vérifier que la table existe
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='produit_code_detail'"
      );

      if (tables.isEmpty) {
        print('⚠️ Table produit_code_detail manquante - Création...');
        await db.execute('''
        CREATE TABLE produit_code_detail (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codebar TEXT NOT NULL,
          produit_code TEXT NOT NULL,
          date_cree TEXT NOT NULL,
          cree_par TEXT NOT NULL
        )
      ''');
        print('✅ Table produit_code_detail créée');
      }

      // ✅ Obtenir le prochain ID SANS transaction
      final idResult = await db.rawQuery(
          'SELECT MAX(id) AS maxId FROM produit_code_detail'
      );
      final maxId = idResult.first['maxId'] as int?;
      final nextId = (maxId ?? 0) + 1;
      detail.id = nextId;

      // ✅ Préparer les données
      final data = detail.toMap();
      data['id'] = detail.id;

      print('📝 Insertion dans produit_code_detail: $data');

      // ✅ Insertion DIRECTE sans transaction
      final insertResult = await db.insert(
        'produit_code_detail',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Insertion réussie: $insertResult');
      return insertResult > 0 ? detail.id : 0;

    } catch (e, stack) {
      print('❌ addProduitCodeDetail ERROR: $e');
      print(stack);
      return 0;
    }
  }// Dans ProduitServices.dart - Corriger la méthode addProduitWithSystemMagasin
  Future<ApiResponse<int>> addProduitWithSystemMagasin(Produit produit, String systemMagasinNom) async {
    try {
      return await db.transaction((txn) async {
        // 1. Insérer le produit
        final insertData = produit.toMap();
        insertData['id'] = produit.id;
        final result = await txn.insert('produits', insertData);

        if (result == 0) {
          return ApiResponse(success: false, message: "Erreur lors de l'insertion du produit");
        }

        // 2. Récupérer le magasin "System"
        final magasinResult = await txn.query(
          'magasins',
          where: 'nom = ?',
          whereArgs: [systemMagasinNom],
        );

        if (magasinResult.isEmpty) {
          // Créer le magasin System s'il n'existe pas
          final systemMagasinId = await _getNextMagasinId(txn);
          final systemMagasin = {
            'id': systemMagasinId,
            'nom': systemMagasinNom,
            'code': 'SYS${systemMagasinId.toString().padLeft(6, '0')}',
            'etat': 1,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par': produit.creePar,
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('magasins', systemMagasin);

          // 3. Créer la relation produit_magasin_detail
          final detailId = await _getNextMagasinDetailId(txn);
          final detail = {
            'id': detailId,
            'magasin_code': systemMagasin['code'],
            'produit_code': produit.code,
            'quantite': 0,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par': produit.creePar,
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('produit_magasin_detail', detail);
        } else {
          final magasin = magasinResult.first;

          // 3. Créer la relation produit_magasin_detail
          final detailId = await _getNextMagasinDetailId(txn);
          final detail = {
            'id': detailId,
            'magasin_code': magasin['code'],
            'produit_code': produit.code,
            'quantite': 0,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par': produit.creePar,
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('produit_magasin_detail', detail);
        }

        return ApiResponse(success: true, message: "Produit ajouté avec succès", data: produit.id);
      });
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur: $e");
    }
  }

  Future<int> _getNextMagasinId(DatabaseExecutor txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM magasins');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  Future<int> _getNextMagasinDetailId(DatabaseExecutor txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM produit_magasin_detail');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


  Future<List<Produit>> getProduitsByRemise(String remise) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'remise = ?' , whereArgs: [remise],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }

  Future<List<Produit>> getProduitsByCategorie(String categorie) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'categorie = ?' , whereArgs: [categorie],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }
  Future<List<Produit>> getProduitsBySousCategorie(String sous) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'sous_categorie = ?' , whereArgs: [sous],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }

  Future<Produit?> getProduitById(int id) async {

    final maps = await db.query('produits' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Produit.fromMap(maps.first);

    }

    return null;

  } Future<Produit?> getProduitByCode(String id) async {

    final maps = await db.query('produits' , where: 'code = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Produit.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateProduit(Produit produit) async{
    try{

      final data = produit.toMap()
          ..remove('id')
          ..remove('code');

      final rows = await db.update(
        'produits',
        data,
        where: 'id = ?',
        whereArgs: [produit.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );

    } catch(e){
      if(e.toString().contains('UNIQUE constraint failed')){
        return ApiResponse(
          success : false,
          message : "Un produit avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteProduitt(int id) async {

    return await db.delete(
      'produits',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  // Dans ProduitServices.dart
  Future<ApiResponse<int>> addProduit(Produit produit) async {
    try {
      final id = await db.insert(
        'produits',
        produit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return ApiResponse(success: true, message: "Produit ajouté avec succès", data: id);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur ajout: ${e.toString()}");
    }
  }


  static Future<int> getNextProduitId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM produits',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Calcule en direct les statistiques de mouvement d'un produit
  /// (dernier achat, totaux achat/vente/retours, besoin) à partir
  /// des tables entree, smartScanProduit, pannierProduit et retours.
  static Future<ProduitStats> getProduitStats(Produit produit) async {
    final db = await DbCreator.openDb();

    final entrees = await db.query(
      'entree',
      where: 'produit_code = ? AND etat = 1',
      whereArgs: [produit.code],
    );
    final scans = await db.query(
      'smartScanProduit',
      where: 'code_produit = ? AND etat = 1',
      whereArgs: [produit.code],
    );
    final paniers = await db.query(
      'pannierProduit',
      where: 'code_produit = ? AND etat = 1',
      whereArgs: [produit.code],
    );
    final retoursClient = await db.query(
      'retours',
      where: 'code_produit = ? AND etat = 1 AND type = ?',
      whereArgs: [produit.code, 'Client'],
    );
    final retoursFournisseur = await db.query(
      'retours',
      where: 'code_produit = ? AND etat = 1 AND type = ?',
      whereArgs: [produit.code, 'Fournisseur'],
    );
    final besoinDetails = await db.query(
      'besion_list_detail',
      where: 'produit_code = ?',
      whereArgs: [produit.code],
      orderBy: 'date_cree DESC',
      limit: 1,
    );

    double _sumQuantite(List<Map<String, dynamic>> rows) =>
        rows.fold(0.0, (sum, r) => sum + (r['quantite'] as num).toDouble());

    DateTime? dernierEntreeDate;
    double dernierEntreeQuantite = 0;
    for (final e in entrees) {
      final date = DateTime.parse(e['date'] as String);
      if (dernierEntreeDate == null || date.isAfter(dernierEntreeDate)) {
        dernierEntreeDate = date;
        dernierEntreeQuantite = (e['quantite'] as num).toDouble();
      }
    }

    DateTime? dernierScanDate;
    double dernierScanQuantite = 0;
    for (final e in scans) {
      final date = DateTime.parse(e['date_cree'] as String);
      if (dernierScanDate == null || date.isAfter(dernierScanDate)) {
        dernierScanDate = date;
        dernierScanQuantite = (e['quantite'] as num).toDouble();
      }
    }

    DateTime? dateDernierAchat;
    double quantiteDernierAchat = 0;
    if (dernierEntreeDate != null &&
        (dernierScanDate == null || dernierEntreeDate.isAfter(dernierScanDate))) {
      dateDernierAchat = dernierEntreeDate;
      quantiteDernierAchat = dernierEntreeQuantite;
    } else if (dernierScanDate != null) {
      dateDernierAchat = dernierScanDate;
      quantiteDernierAchat = dernierScanQuantite;
    }

    final bool besoin = produit.quantite < produit.seuilMin;

    String besoinStatus;
    if (!besoin) {
      besoinStatus = ListsConst.typeBesionproduit[2]; // "Disponible"
    } else if (besoinDetails.isEmpty || dateDernierAchat == null) {
      besoinStatus = ListsConst.typeBesionproduit[0]; // "En Attente"
    } else {
      final besoinDate = DateTime.parse(besoinDetails.first['date_cree'] as String);
      besoinStatus = dateDernierAchat.isBefore(besoinDate)
          ? ListsConst.typeBesionproduit[1] // "Commande"
          : ListsConst.typeBesionproduit[0]; // "En Attente"
    }

    return ProduitStats(
      quantiteDernierAchat: quantiteDernierAchat,
      dateDernierAchat: dateDernierAchat,
      totalAchat: _sumQuantite(entrees) + _sumQuantite(scans),
      totalVendu: _sumQuantite(paniers),
      totalRetourClient: _sumQuantite(retoursClient),
      totalRetourFournisseur: _sumQuantite(retoursFournisseur),
      besoin: besoin,
      besoinStatus: besoinStatus,
    );
  }

}