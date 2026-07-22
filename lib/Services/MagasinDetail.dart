import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/produit_magasin_detail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProduitMagasinDetailServices {
  final Database db;

  ProduitMagasinDetailServices(this.db);

  /// -----------------------------
  /// Get all ProduitMagasinDetails
  /// -----------------------------
  static Future<List<ProduitMagasinDetail>> getAllProduitMagasinDetails() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('produit_magasin_detail', orderBy: 'id ASC');
    return result.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }
// Dans ProduitMagasinDetailServices.dart

// ✅ Méthode pour récupérer les détails par magasin
  Future<List<ProduitMagasinDetail>> getDetailsByMagasin(String magasinCode) async {
    final List<Map<String, dynamic>> result = await db.query(
      'produit_magasin_detail',
      where: 'magasin_code = ?',
      whereArgs: [magasinCode],
      orderBy: 'produit_code ASC',
    );
    return result.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }
  /// -----------------------------
  /// Get by produit code
  /// -----------------------------
  Future<List<ProduitMagasinDetail>> getByProduitCode(String produitCode) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'produit_magasin_detail',
      where: 'produit_code = ?',
      whereArgs: [produitCode],
    );
    return maps.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }

  /// -----------------------------
  /// Get by produit code and magasin nom (single result) - VERSION TRANSACTION
  /// -----------------------------
  Future<ProduitMagasinDetail?> getSingleByProduitAndMagasinWithTransaction(
      Transaction txn,
      String produitCode,
      String magasinCode,
      ) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      'produit_magasin_detail',
      where: 'produit_code = ? AND magasin_code = ?',
      whereArgs: [produitCode, magasinCode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProduitMagasinDetail.fromMap(maps.first);
    }
    return null;
  }

  /// Version sans transaction (pour compatibilité)
  Future<ProduitMagasinDetail?> getSingleByProduitAndMagasin(String produitCode, String magasinCode) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'produit_magasin_detail',
      where: 'produit_code = ? AND magasin_code = ?',
      whereArgs: [produitCode, magasinCode],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return ProduitMagasinDetail.fromMap(maps.first);
    }
    return null;
  }

  /// -----------------------------
  /// Get by produit code and magasin code (list)
  /// -----------------------------
  Future<List<ProduitMagasinDetail>> getByProduitAndMagasin(String produitCode, String magasinCode) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'produit_magasin_detail',
      where: 'produit_code = ? AND magasin_code = ?',
      whereArgs: [produitCode, magasinCode],
    );
    return maps.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }

  /// -----------------------------
  /// Update quantity - VERSION TRANSACTION
  /// -----------------------------
  Future<int> updateQuantiteWithTransaction(Transaction txn, int id, double nouvelleQuantite) async {
    return await txn.update(
      'produit_magasin_detail',
      {'quantite': nouvelleQuantite},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Version sans transaction
  Future<int> updateQuantite(int id, double nouvelleQuantite) async {
    return await db.update(
      'produit_magasin_detail',
      {'quantite': nouvelleQuantite},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// -----------------------------
  /// Decrement quantity - VERSION TRANSACTION
  /// -----------------------------
  Future<int> decrementQuantiteWithTransaction(Transaction txn, int id, double quantiteADecrementer) async {
    final detail = await getProduitMagasinDetailByIdWithTransaction(txn, id);
    if (detail == null) return 0;

    final nouvelleQuantite = detail.quantite - quantiteADecrementer;
    if (nouvelleQuantite < 0) return -1;

    return await updateQuantiteWithTransaction(txn, id, nouvelleQuantite);
  }

  /// Version sans transaction
  Future<int> decrementQuantite(int id, double quantiteADecrementer) async {
    final detail = await getProduitMagasinDetailById(id);
    if (detail == null) return 0;

    final nouvelleQuantite = detail.quantite - quantiteADecrementer;
    if (nouvelleQuantite < 0) return -1;

    return await updateQuantite(id, nouvelleQuantite);
  }

  /// -----------------------------
  /// Increment quantity
  /// -----------------------------
  Future<int> incrementQuantite(int id, double quantiteAIncrementer) async {
    final detail = await getProduitMagasinDetailById(id);
    if (detail == null) return 0;

    final nouvelleQuantite = detail.quantite + quantiteAIncrementer;
    return await updateQuantite(id, nouvelleQuantite);
  }

  /// -----------------------------
  /// Get by ID - VERSION TRANSACTION
  /// -----------------------------
  Future<ProduitMagasinDetail?> getProduitMagasinDetailByIdWithTransaction(Transaction txn, int id) async {
    final List<Map<String, dynamic>> maps = await txn.query(
      'produit_magasin_detail',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProduitMagasinDetail.fromMap(maps.first);
    }
    return null;
  }

  /// Version sans transaction
  Future<ProduitMagasinDetail?> getProduitMagasinDetailById(int id) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'produit_magasin_detail',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      return ProduitMagasinDetail.fromMap(maps.first);
    }
    return null;
  }

  /// -----------------------------
  /// Add a new ProduitMagasinDetail
  /// -----------------------------
  Future<int> addProduitMagasinDetail(ProduitMagasinDetail detail) async {
    try {
      return await db.transaction((txn) async {
        final existing = await txn.query(
          'produit_magasin_detail',
          where: 'magasin_code = ? AND produit_code = ?',
          whereArgs: [
            detail.magasinCode,
            detail.produitCode,
          ],
          limit: 1,
        );

        if (existing.isNotEmpty) {
          print("Duplicate ignored for ${detail.produitCode}");
          return 0;
        }

        if (detail.id == 0) {
          detail.id = await ProduitMagasinDetailServices.getNextId(txn);
        }

        final data = detail.toMap();
        data['id'] = detail.id;

        final result = await txn.insert('produit_magasin_detail', data);
        return result > 0 ? detail.id : 0;
      });
    } catch (e, stack) {
      print('ADD produit magasin detail ERROR: $e');
      print(stack);
      return 0;
    }
  }

  /// -----------------------------
  /// Delete detail by object
  /// -----------------------------
  Future<void> deleteDetaile(ProduitMagasinDetail detail) async {
    await db.delete('produit_magasin_detail', where: 'id = ?', whereArgs: [detail.id]);
  }

  /// -----------------------------
  /// Get all details
  /// -----------------------------
  static Future<List<ProduitMagasinDetail>> getAllDetails() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('produit_magasin_detail', orderBy: 'magasin_code ASC');
    return result.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }

  /// -----------------------------
  /// Get details by produit code
  /// -----------------------------
  static Future<List<ProduitMagasinDetail>> getDetailsByCode(String code) async {
    final db = await DbCreator.openDb();
    final maps = await db.query('produit_magasin_detail', where: 'produit_code = ?', whereArgs: [code]);
    return maps.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }

  /// -----------------------------
  /// Update detail
  /// -----------------------------
  Future<int> updateDetail(ProduitMagasinDetail detail) async {
    final data = detail.toMap();
    data.remove('id');
    return await db.update('produit_magasin_detail', data, where: 'id = ?', whereArgs: [detail.id]);
  }

  /// -----------------------------
  /// Delete detail by product and magasin
  /// -----------------------------
  Future<void> deleteDetailes(String produitCode, String magasinCode) async {
    await db.delete(
      'produit_magasin_detail',
      where: 'produit_code = ? AND magasin_code = ?',
      whereArgs: [produitCode, magasinCode],
    );
  }

  /// -----------------------------
  /// Delete all details for a product
  /// -----------------------------
  Future<void> deleteAllDetailes(String produitCode) async {
    await db.delete('produit_magasin_detail', where: 'produit_code = ?', whereArgs: [produitCode]);
  }

  /// -----------------------------
  /// Delete detail by ID
  /// -----------------------------
  static Future<int> deleteDetail(int id) async {
    final db = await DbCreator.openDb();
    return await db.delete('produit_magasin_detail', where: 'id = ?', whereArgs: [id]);
  }

  /// -----------------------------
  /// Get next ID
  /// -----------------------------
  static Future<int> getNextId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM produit_magasin_detail');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// -----------------------------
  /// Check if exists
  /// -----------------------------
  Future<bool> exists({required String packCode, required String produitCode}) async {
    final result = await db.query(
      'produit_magasin_detail',
      where: 'magasin_code = ? AND produit_code = ?',
      whereArgs: [packCode, produitCode],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  /// -----------------------------
  /// Get total quantity for a product across all stores
  /// -----------------------------
  Future<double> getTotalQuantiteByProduitCode(String produitCode) async {
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        'SELECT SUM(quantite) as total FROM produit_magasin_detail WHERE produit_code = ?',
        [produitCode],
      );

      final total = result.first['total'];
      if (total == null) return 0.0;

      if (total is int) return total.toDouble();
      if (total is double) return total;

      return double.tryParse(total.toString()) ?? 0.0;
    } catch (e) {
      print('Erreur getTotalQuantiteByProduitCode: $e');
      return 0.0;
    }
  }

  /// -----------------------------
  /// Get all products with low stock
  /// -----------------------------
  Future<List<ProduitMagasinDetail>> getLowStockProducts(double seuil) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'produit_magasin_detail',
      where: 'quantite <= ?',
      whereArgs: [seuil],
      orderBy: 'quantite ASC',
    );
    return maps.map((e) => ProduitMagasinDetail.fromMap(e)).toList();
  }
}