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

  /// Retourne l'utilisateur (autre que [excludeUtilisateurCode]) portant
  /// déjà ce nom d'utilisateur (comparaison insensible à la casse et aux
  /// espaces) — null si le nom d'utilisateur est libre.
  static Future<Utilisateur?> findUtilisateurByUsername(String username, {String? excludeUtilisateurCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'utilisateur',
      where: 'LOWER(TRIM(username)) = ?',
      whereArgs: [username.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final utilisateur = Utilisateur.fromMap(maps.first);
    if (utilisateur.code == excludeUtilisateurCode) return null;
    return utilisateur;
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

  /// Désactive définitivement (etat = 0) sans supprimer la ligne — utilisé
  /// à la place de [deleteUtilisateur] quand [hasActivity] détecte que cet
  /// utilisateur a déjà des enregistrements liés en base.
  Future<int> deactivateUtilisateur(int id) async {
    final db = await DbCreator.openDb();

    return await db.update(
      'utilisateur',
      {'etat': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Vrai si [code] apparaît, dans une autre table, comme créateur,
  /// modificateur, annulateur ou dans tout autre rôle (vendeur, caissier,
  /// utilisateur traitant un scan…) d'au moins un enregistrement — c'est-à-
  /// dire si cet utilisateur a déjà une activité enregistrée. Parcourt
  /// dynamiquement `PRAGMA foreign_key_list` de chaque table plutôt que de
  /// maintenir à la main la liste des ~25 tables qui référencent
  /// utilisateur(code), pour rester valable si le schéma évolue.
  static Future<bool> hasActivity(String code) async {
    final db = await DbCreator.openDb();

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
    );

    for (final row in tables) {
      final table = row['name'] as String;
      final fks = await db.rawQuery('PRAGMA foreign_key_list("$table")');
      final userColumns = fks
          .where((fk) => fk['table'] == 'utilisateur')
          .map((fk) => fk['from'] as String)
          .toSet();

      // utilisateur.cree_par_code/modif_par_code/annul_par_code référencent
      // logiquement un autre utilisateur sans contrainte FK déclarée (pour
      // permettre l'auto-référence de l'admin créé au seed) : on les
      // vérifie quand même explicitement, en excluant la propre ligne.
      final isSelfTable = table == 'utilisateur';
      if (isSelfTable) {
        userColumns.addAll(['cree_par_code', 'modif_par_code', 'annul_par_code']);
      }
      if (userColumns.isEmpty) continue;

      final whereClause = userColumns.map((c) => '"$c" = ?').join(' OR ');
      final args = [for (final _ in userColumns) code];
      final extraWhere = isSelfTable ? ' AND code != ?' : '';
      if (isSelfTable) args.add(code);

      final result = await db.rawQuery(
        'SELECT 1 FROM "$table" WHERE ($whereClause)$extraWhere LIMIT 1',
        args,
      );
      if (result.isNotEmpty) return true;
    }
    return false;
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

  // 🔹 GET BY API TOKEN (app mobile compagnon — voir BonReceptionServer)
  static Future<Utilisateur?> getUtilisateurByApiToken(String token) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'utilisateur',
      where: 'api_token = ? AND etat = 1',
      whereArgs: [token],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Utilisateur.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 SET API TOKEN (POST /api/auth/login)
  Future<void> setApiToken(int id, String? token) async {
    await db.update(
      'utilisateur',
      {'api_token': token},
      where: 'id = ?',
      whereArgs: [id],
    );
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
