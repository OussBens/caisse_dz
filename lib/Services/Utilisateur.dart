import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class UtilisateurServices {

  final Database db;

  UtilisateurServices(this.db);

  // 🔹 ACTIVATE / DEACTIVATE
  Future<int> ActDis(List<Utilisateur> utilisateurs) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var f in utilisateurs) {
      final data = {
        'etat': f.etat == 1 ? 0 : 1,
      };

      int updated = await db.update(
        'utilisateur',
        data,
        where: 'id = ?',
        whereArgs: [f.id],
      );

      count += updated;
    }

    return count;
  }

  // 🔹 GET ALL
  static Future<List<Utilisateur>> getAllUtilisateurs() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('utilisateur', orderBy: 'id ASC',);

    return result.map((e) => Utilisateur.fromMap(e)).toList();

  }

  // 🔹 GET BY ROLE CODE
  static Future<List<Utilisateur>> getUtilisateursByRoleCode(String roleCode) async {
    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query(
      'utilisateur',
      where: 'role_code = ?',
      whereArgs: [roleCode],
    );

    return result.map((e) => Utilisateur.fromMap(e)).toList();
  }

  // 🔹 GET BY CODE
  static Future<Utilisateur?> getUtilisateurByCode(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'utilisateur',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Utilisateur.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 GET BY ID
  static Future<Utilisateur?> getUtilisateurById(int id) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'utilisateur',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Utilisateur.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 UPDATE
  Future<ApiResponse<int>> updateUtilisateur(Utilisateur utilisateur) async {
    try {
      final data = utilisateur.toMap()
        ..remove('id')
        ..remove('code'); // prevent editing unique key

      final rows = await db.update(
        'utilisateur',
        data,
        where: 'id = ?',
        whereArgs: [utilisateur.id],
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
          message: "Un Utilisateur avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  // 🔹 DELETE
  Future<int> deleteUtilisateur(int id) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'utilisateur',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addUtilisateur(Utilisateur utilisateur) async {
    try {
      final existing = await db.query(
        'utilisateur',
        where: 'username = ?',
        whereArgs: [utilisateur.username],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Utilisateur avec ce username existe déjà",
        );
      }

      final id = await db.insert(
        'utilisateur',
        utilisateur.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Utilisateur ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // 🔹 NEXT ID
  static Future<int> getNextUtilisateurId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM utilisateur',
    );

    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

}
