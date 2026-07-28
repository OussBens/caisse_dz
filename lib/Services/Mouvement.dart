import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class MouvementsServices {

  final Database db;

  MouvementsServices(this.db);

  // ✅ Méthode avec transaction
  Future<ApiResponse<int>> addMouvementWithTransaction(Transaction txn, Mouvement mouvement) async {
    try {
      final id = await txn.insert(
        'mouvements',
        mouvement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "mouvement ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // ✅ Garder l'ancienne méthode pour compatibilité (sans transaction)
  Future<ApiResponse<int>> addMouvement(Mouvement mouvement) async {
    try {
      final id = await db.insert(
        'mouvements',
        mouvement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "mouvement ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  Future<int> ActDis(List<Mouvement> mouvements) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var mouvement in mouvements) {
      final data = {
        'etat': mouvement.etat ? 0 : 1,
      };

      int updated = await db.update(
        'mouvements',
        data,
        where: 'id = ?',
        whereArgs: [mouvement.id],
      );
      count += updated;
    }

    return count;
  }

  static Future<List<Mouvement>> getAllMouvements() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('mouvements', orderBy: 'id ASC');
    return result.map((e) => Mouvement.fromMap(e)).toList();
  }

  static Future<List<Mouvement>> getAllMouvementsByCodeOper(String code) async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('mouvements', where: 'code_operation = ?', whereArgs: [code]);
    return result.map((e) => Mouvement.fromMap(e)).toList();
  }

  static Future<bool> isProduitHaveMouvement(String code) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'mouvements',
      where: 'code_produit = ?',
      whereArgs: [code],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<Mouvement?> getMouvementById(int id) async {
    final db = await DbCreator.openDb();
    final maps = await db.query('mouvements', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Mouvement.fromMap(maps.first);
    }
    return null;
  }

  Future<ApiResponse<int>> updateMouvement(Mouvement mouvement) async {
    try {
      final data = mouvement.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'mouvements',
        data,
        where: 'id = ?',
        whereArgs: [mouvement.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification réussie",
        data: rows,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Un Mouvement avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  static Future<int> deleteMouvement(int id) async {
    final db = await DbCreator.openDb();
    return await db.delete(
      'mouvements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getNextMouvementId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM mouvements');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}