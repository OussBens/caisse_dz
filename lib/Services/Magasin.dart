import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class MagasinServices {
  final Database db;

  MagasinServices(this.db);

  static Future<List<Magasin>> getAllMagasins() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('magasins', orderBy: 'nom ASC');
    return result.map((e) => Magasin.fromMap(e)).toList();
  }

  /// Retourne le magasin (autre que [excludeMagasinCode]) portant déjà ce nom
  /// (comparaison insensible à la casse et aux espaces) — null si le nom
  /// est libre.
  static Future<Magasin?> findMagasinByNom(String nom, {String? excludeMagasinCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'magasins',
      where: 'LOWER(TRIM(nom)) = ?',
      whereArgs: [nom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final magasin = Magasin.fromMap(maps.first);
    if (magasin.code == excludeMagasinCode) return null;
    return magasin;
  }

  Future<Magasin?> getMagasinById(int id) async {
    final maps = await db.query('magasins', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Magasin.fromMap(maps.first);
    return null;
  }

  Future<ApiResponse<int>> addMagasin(Magasin magasin) async {
    try {
      final existing = await db.query(
        'magasins',
        where: 'LOWER(TRIM(nom)) = ?',
        whereArgs: [magasin.nom.trim().toLowerCase()],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un magasin avec ce nom existe deja",
        );
      }

      final id = await db.insert(
        'magasins',
        magasin.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Magasin ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<int>> updateMagasin(Magasin magasin) async {
    try {
      final data = magasin.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'magasins',
        data,
        where: 'id = ?',
        whereArgs: [magasin.id],
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
          message: "Un magasin avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteMagasin(int id) async {
    return await db.delete('magasins', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getNextMagasinId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM magasins');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
