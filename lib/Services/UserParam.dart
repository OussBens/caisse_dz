import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/userparam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class UserParamServices {
  final Database db;

  UserParamServices(this.db);

  // GET USER PARAM BY USERNAME
  static Future<UserParam?> getUserParamByUsername(String username) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'userparam',
      where     : 'nom = ?',  // Changed from 'name' to 'nom'
      whereArgs : [username],
      limit     : 1,
    );

    if (maps.isNotEmpty) {
      return UserParam.fromMap(maps.first);
    }
    return null;
  }

  // GET USER PARAM BY ID
  static Future<UserParam?> getUserParamById(int id) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'userparam',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return UserParam.fromMap(maps.first);
    }
    return null;
  }

  // UPDATE USER PARAM
  Future<ApiResponse<int>> updateUserParam(
      UserParam userParam,
      String modifiedBy,
      String modifiedByCode,
      String modificationReason,
      ) async {
    try {
      final now = DateTime.now().toIso8601String();

      final data = userParam.toMap()
        ..remove('id')
        ..['modif_le'] = now
        ..['modif_par_code'] = modifiedBy;

      final rows = await db.update(
        'userparam',
        data,
        where: 'id = ?',
        whereArgs: [userParam.id],
      );

      // Save to history
      if (rows > 0) {
        await _saveToHistory(
          operation: 'MODIFICATION',
          modifiedBy: modifiedBy,
          modifiedByCode: modifiedByCode,
          reason: modificationReason,
          targetUser: userParam.nom,
          oldMagasin: userParam.magasin,
          newMagasin: userParam.magasin,
          oldLanguage: userParam.language,
          newLanguage: userParam.language,
          oldCurrency: userParam.currency,
          newCurrency: userParam.currency,
        );
      }

      return ApiResponse(
        success: true,
        message: "Paramètres modifiés avec succès",
        data: rows,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  // CREATE USER PARAM
  Future<ApiResponse<int>> addUserParam(
      UserParam userParam,
      String createdBy,
      String createdByCode,
      ) async {
    try {
      // Check if user param already exists
      final existing = await db.query(
        'userparam',
        where: 'nom = ?',
        whereArgs: [userParam.nom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un paramètre utilisateur existe déjà pour cet utilisateur",
        );
      }

      final now = DateTime.now().toIso8601String();
      final data = userParam.toMap()
        ..remove('id')
        ..['cree_le'] = now
        ..['cree_par_code'] = createdByCode;

      final id = await db.insert(
        'userparam',
        data,
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      // Save creation to history
      if (id > 0) {
        await _saveToHistory(
          operation: 'INSERTION',
          modifiedBy: createdBy,
          modifiedByCode: createdByCode,
          reason: "Création initiale des paramètres utilisateur",
          targetUser: userParam.nom,
          oldMagasin: null,
          newMagasin: userParam.magasin,
          oldLanguage: null,
          newLanguage: userParam.language,
          oldCurrency: null,
          newCurrency: userParam.currency,
        );
      }

      return ApiResponse(
        success: true,
        message: "Paramètres créés avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // SAVE TO HISTORY
  Future<void> _saveToHistory({
    required String operation,
    required String modifiedBy,
    required String modifiedByCode,
    required String reason,
    required String targetUser,
    String? oldMagasin,
    String? newMagasin,
    String? oldLanguage,
    String? newLanguage,
    String? oldCurrency,
    String? newCurrency,
  }) async {
    final now = DateTime.now().toIso8601String();
    final code = "UP_${DateTime.now().millisecondsSinceEpoch}";

    String description;
    if (operation == 'INSERTION') {
      description = "Création des paramètres pour l'utilisateur: $targetUser";
    } else {
      description = "Modification des paramètres de l'utilisateur: $targetUser - Motif: $reason";
    }

    final historiqueData = {
      'code': code,
      'type': 'USER_PARAM',
      'description': description,
      'operation': operation,
      'cree_par_code': modifiedByCode,
      'date_cree': now,
      'observation': '''
        Motif: $reason
        Anciennes valeurs: Magasin=${oldMagasin ?? 'N/A'}, Langue=${oldLanguage ?? 'N/A'}, Devise=${oldCurrency ?? 'N/A'}
        Nouvelles valeurs: Magasin=${newMagasin ?? 'N/A'}, Langue=${newLanguage ?? 'N/A'}, Devise=${newCurrency ?? 'N/A'}
      ''',
    };

    await db.insert('Historique', historiqueData);
  }

  static Future<int> getNextUPId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM userparam',
    );

    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}