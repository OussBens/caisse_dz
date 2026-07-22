import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/RoleDetail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class RoleDetailServices {

  final Database db;

  RoleDetailServices(this.db);

  // 🔹 GET ALL
  static Future<List<RoleDetail>> getAllRolesDetail() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('roledetail', orderBy: 'id ASC',);

    return result.map((e) => RoleDetail.fromMap(e)).toList();

  }

  // 🔹 GET BY CODE
  static Future<RoleDetail?> getRoleByCode(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'roledetail',
      where: 'rolecode = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return RoleDetail.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 GET BY ID
  static Future<RoleDetail?> getRoleById(int id) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'roledetail',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return RoleDetail.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 UPDATE
  Future<ApiResponse<int>> updateRole(RoleDetail roledetail) async {
    try {
      final data = roledetail.toMap()
        ..remove('id');

      final rows = await db.update(
        'roledetail',
        data,
        where: 'id = ?',
        whereArgs: [roledetail.id],
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
          message: "Un Role detail avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  // 🔹 DELETE
  Future<int> deleteRoleDetail(String code) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'roledetail',
      where: 'rolecode = ?',
      whereArgs: [code],
    );
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addRole(RoleDetail roledetail) async {
    try {
      final existing = await db.query(
        'roledetail',
        where: 'rolecode = ?',
        whereArgs: [roledetail.Rolecode],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un role detail avec ce Nom existe déjà",
        );
      }

      final id = await db.insert(
        'roledetail',
        roledetail.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "role detail ajouté avec succès",
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
  static Future<int> getNextRoleDetailId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM roledetail',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
