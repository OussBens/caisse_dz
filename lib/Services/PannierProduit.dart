import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../DBCreate.dart';
import '../core/utilis/api_response.dart';
import '../data/models/pannier_produit.dart';

class PPServices {
  final Database db;

  PPServices(this.db);

  static Future<List<PannierProduit>> getAllPP() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('pannierProduit', orderBy: 'id ASC');
    return result.map((e) => PannierProduit.fromMap(e)).toList();
  }

  Future<PannierProduit?> getPPById(int id) async {
    final maps = await db.query('pannierProduit', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return PannierProduit.fromMap(maps.first);
    }
    return null;
  }

  Future<List<PannierProduit>> getPPByCodePannier(String codePannier) async {
    final List<Map<String, dynamic>> maps = await db.query(
      'pannierProduit',
      where: 'code_pannier = ?',
      whereArgs: [codePannier],
      orderBy: 'id ASC',
    );
    return maps.map((e) => PannierProduit.fromMap(e)).toList();
  }

  Future<ApiResponse<int>> updatePP(PannierProduit produit) async {
    try {
      final data = produit.toMap()..remove('id');
      final rows = await db.update(
        'pannierProduit',
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
      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deletePP(int id) async {
    return await db.delete('pannierProduit', where: 'id = ?', whereArgs: [id]);
  }

  // ✅ Version simple sans transaction
  Future<ApiResponse<int>> addPP(PannierProduit produit) async {
    try {
      final id = await db.insert(
        'pannierProduit',
        produit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return ApiResponse(
        success: true,
        message: "Pannier Produit ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  static Future<int> getNextPPId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM pannierProduit');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}