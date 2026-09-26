import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class RoleServices {

  final Database db;

  RoleServices(this.db);

  // 🔹 ACTIVATE / DEACTIVATE
  Future<int> ActDis(List<Role> roles) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var f in roles) {
      final data = {
        'etat': f.etat == 1 ? 0 : 1,
      };

      int updated = await db.update(
        'role',
        data,
        where: 'id = ?',
        whereArgs: [f.id],
      );

      count += updated;
    }

    return count;
  }

  // 🔹 GET ALL
  static Future<List<Role>> getAllRoles() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('role', orderBy: 'id ASC',);

    return result.map((e) => Role.fromMap(e)).toList();

  }

  /// Rôles pouvant être assignés à un utilisateur — exclut le rôle Admin
  /// (unique, seedé au démarrage de l'application). Pour avoir d'autres
  /// administrateurs, il faut créer un nouveau rôle dédié (écran Rôles)
  /// puis un utilisateur avec ce rôle.
  static Future<List<Role>> getAssignableRoles() async {
    final all = await getAllRoles();
    return all.where((r) => r.rolenom.trim().toLowerCase() != 'admin').toList();
  }

  /// Retourne le rôle (autre que [excludeRoleCode]) portant déjà ce nom
  /// (comparaison insensible à la casse et aux espaces) — null si le nom
  /// est libre.
  static Future<Role?> findRoleByNom(String rolenom, {String? excludeRoleCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'role',
      where: 'LOWER(TRIM(rolenom)) = ?',
      whereArgs: [rolenom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final role = Role.fromMap(maps.first);
    if (role.code == excludeRoleCode) return null;
    return role;
  }

  // 🔹 GET BY CODE
  static Future<Role?> getRoleByCode(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'role',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Role.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 GET BY ID
  static Future<Role?> getRoleById(int id) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'role',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Role.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 UPDATE
  Future<ApiResponse<int>> updateRole(Role role) async {
    try {
      final data = role.toMap()
        ..remove('id')
        ..remove('code'); // prevent editing unique key

      final rows = await db.update(
        'role',
        data,
        where: 'id = ?',
        whereArgs: [role.id],
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
          message: "Un Role avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  // 🔹 DELETE
  Future<int> deleteRole(int id) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'role',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addRole(Role role) async {
    try {
      final existing = await db.query(
        'role',
        where: 'rolenom = ?',
        whereArgs: [role.rolenom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Role avec ce Nom existe déjà",
        );
      }

      final id = await db.insert(
        'role',
        role.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Role ajouté avec succès",
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
  static Future<int> getNextRoleId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM role',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
