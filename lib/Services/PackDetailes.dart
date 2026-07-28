import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/produit_pack_detail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ProduitPackDetailServices {
  final Database db;

  ProduitPackDetailServices(this.db);

  /// -----------------------------
  /// Add a new ProduitPackDetail
  /// -----------------------------

  Future<int> addProduitPackDetail(ProduitPackDetail detail) async {
    try {
      return await db.transaction((txn) async {
        // ⚠️ NE PAS gérer l'ID manuellement - laisser SQLite auto-incrémenter
        // Supprimer la ligne qui définit l'id
        // detail.id = await ProduitPackDetailServices.getNextId(txn);  // À SUPPRIMER

        final data = detail.toMap();
        // ⚠️ Supprimer l'id du map pour que SQLite l'auto-génère
        data.remove('id');  // AJOUTER CETTE LIGNE

        // ⚠️ Ne pas ajouter 'id' au data
        // data['id'] = detail.id;  // À SUPPRIMER

        final result = await txn.insert(
          'produit_pack_detail',
          data,
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        // result contient le nouvel ID généré
        return result;
      });
    } catch (e, stack) {
      print('ADD PRODUIT_PACK_DETAIL ERROR: $e');
      print(stack);
      return 0;
    }
  }

  /// -----------------------------
  /// Get all ProduitPackDetails
  /// -----------------------------

  static Future<List<ProduitPackDetail>> getAllDetails() async {
    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query(
      'produit_pack_detail',
      orderBy: 'pack_code ASC',
    );

    return result.map((e) => ProduitPackDetail.fromMap(e)).toList();
  }

  /// Get ProduitPackDetail by code produit
  static Future<List<ProduitPackDetail>> getDetailsByNom(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'produit_pack_detail',
      where: 'produit_code = ?',
      whereArgs: [code],
    );

    return maps.map((e) => ProduitPackDetail.fromMap(e)).toList();
  }

  /// Get ProduitPackDetail by code pack
  static Future<List<ProduitPackDetail>> getDetailsByPackNom(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'produit_pack_detail',
      where: 'pack_code = ?',
      whereArgs: [code],
    );

    return maps.map((e) => ProduitPackDetail.fromMap(e)).toList();
  }

  /// -----------------------------
  /// Update ProduitPackDetail
  /// -----------------------------

  Future<int> updateDetail(ProduitPackDetail detail) async {
    final data = detail.toMap();
    final id = data['id'];
    data.remove('id');

    return await db.update(
      'produit_pack_detail',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// -----------------------------
  /// Delete ProduitPackDetail
  /// -----------------------------
  Future<void> deleteAllDetailes(String pack_code) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_pack_detail',
      where: 'pack_code = ?',
      whereArgs: [pack_code],
    );
  }

  Future<void> deleteAllDetailes2(String produit) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_pack_detail',
      where: 'produit_code = ?',
      whereArgs: [produit],
    );
  }

  static Future<int> deleteDetail(int id) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'produit_pack_detail',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteDetailes(String produitCode, String packCode) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_pack_detail',
      where: 'produit_code = ? AND pack_code = ?',
      whereArgs: [produitCode, packCode],
    );
  }

  /// -----------------------------
  /// Get next ID (à garder si utilisé ailleurs, mais plus utilisé dans addProduitPackDetail)
  /// -----------------------------

  static Future<int> getNextId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM produit_pack_detail',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  Future<bool> exists({
    required String packCode,
    required String produitCode,
  }) async {
    final db = await DbCreator.openDb();

    final result = await db.query(
      'produit_pack_detail',
      where: 'pack_code = ? AND produit_code = ?',
      whereArgs: [packCode, produitCode],
      limit: 1,
    );

    return result.isNotEmpty;
  }

  /// Get ProduitPackDetail by Pack code
  static Future<List<ProduitPackDetail>> getDetailsByPack(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'produit_pack_detail',
      where: 'pack_code = ?',
      whereArgs: [code],
    );

    return maps.map((e) => ProduitPackDetail.fromMap(e)).toList();
  }
}