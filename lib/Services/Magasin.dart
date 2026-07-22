import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class MagasinServices {
  final Database db;

  MagasinServices(this.db);

  // 🔹 ACTIVATE / DEACTIVATE
  Future<int> activerDesactiver(List<Magasin> magasins) async {
    int count = 0;

    for (var m in magasins) {
      final updated = await db.update(
        'magasins',
        {
          'etat': m.etat ? 0 : 1,
          'date_modif': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [m.id],
      );

      count += updated;
    }
    return count;
  }

  // 🔹 GET ALL
  static Future<List<Magasin>> getAllMagasins() async {
     final db = await DbCreator.openDb();
    final result = await db.query(
        'magasins',
        orderBy: 'nom ASC'
    );

    return result.map((e) => Magasin.fromMap(e)).toList();
  }

  // 🔹 GET BY CODE
  Future<Magasin?> getMagasinByCode(String code) async {
    final maps = await db.query(
      'magasins',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );
    return maps.isNotEmpty ? Magasin.fromMap(maps.first) : null;
  } // 🔹 GET BY Nom

  Future<Magasin?> getMagasinByNom(String code) async {
    final maps = await db.query(
      'magasins',
      where: 'nom = ?',
      whereArgs: [code],
      limit: 1,
    );
    return maps.isNotEmpty ? Magasin.fromMap(maps.first) : null;
  }

  // 🔹 GET BY ID
  Future<Magasin?> getMagasinById(int id) async {
    final maps = await db.query(
      'magasins',
      where: 'id = ?',
      whereArgs: [id],
    );
    return maps.isNotEmpty ? Magasin.fromMap(maps.first) : null;
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addMagasin(Magasin magasin) async {
    try {
      final existing = await db.query(
        'magasins',
        where: 'nom = ?',
        whereArgs: [magasin.nom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(success: false, message: "nom magasin déjà utilisé");
      }

      final id = await db.insert(
        'magasins',
        magasin.toMap()..remove('id'),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(success: true, message: "Magasin ajouté", data: id);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur ajout: $e");
    }
  }

  // 🔹 UPDATE
  Future<ApiResponse<int>> updateMagasin(Magasin magasin) async {
    try {
      final data = magasin.toMap()
        ..remove('id')
        ..remove('code')
        ..['date_modif'] = DateTime.now().toIso8601String();

      final rows = await db.update(
        'magasins',
        data,
        where: 'id = ?',
        whereArgs: [magasin.id],
      );

      return ApiResponse(success: true, message: "Modification réussie", data: rows);
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(success: false, message: "Nom déjà utilisé");
      }
      return ApiResponse(success: false, message: "Erreur modification: $e");
    }
  }

  // 🔹 HARD DELETE
  Future<int> deleteMagasin(int id) async {
    return await db.delete('magasins', where: 'id = ?', whereArgs: [id]);
  }

  // 🔹 SOFT DELETE
  Future<int> annulerMagasin(int id, String user) async {
    return await db.update(
      'magasins',
      {
        'etat': 0,
        'date_annul': DateTime.now().toIso8601String(),
        'annul_par': user,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 NEXT ID
  static Future<int> getNextMagasinId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) as maxId FROM magasins');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}
