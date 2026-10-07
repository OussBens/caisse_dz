import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class HistoriqueServices {

  final Database db;

  HistoriqueServices(this.db);

  /// Codification unique de l'historique (ex: "H000000001"), dérivée de son
  /// [id] — recalculée ici plutôt que passée par chaque appelant : les ~60
  /// sites d'appel construisaient historiquement leur propre code ad-hoc
  /// (timestamp concaténé, longueur variable), ce qui rendait le tri/affichage
  /// incohérent. Centraliser ici garantit un format fixe partout sans toucher
  /// chaque appelant.
  static String _formatCode(int id) => CodeGenerator.generateCode(
        prefix: CodePrefix.historique,
        id: id,
        digitCount: 9,
      );

  // ✅ Ajouter cette méthode pour la transaction
  Future<ApiResponse<int>> addHistoriqueWithTransaction(Transaction txn, Historique historique) async {
    try {
      historique.code = _formatCode(historique.id);
      final existing = await txn.query(
        'Historique',
        where: 'code = ?',
        whereArgs: [historique.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Historique avec ce code existe déjà",
        );
      }

      final id = await txn.insert(
        'Historique',
        historique.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Historique ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }
  // 🔹 GET ALL
  static Future<List<Historique>> getAllHistorique() async {

    final db = await DbCreator.openDb();

    final result = await db.query(
      'Historique',
      orderBy: 'date_cree DESC',
    );

    return result.map((e) => Historique.fromMap(e)).toList();
  }

  // 🔹 GET BY CODE
  static Future<Historique?> getHistoriqueByCode(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'Historique',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Historique.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 GET BY ID
  static Future<Historique?> getHistoriqueByCodeUser(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'Historique',
      where: 'cree_par_code = ?',
      whereArgs: [code],
    );

    if (maps.isNotEmpty) {
      return Historique.fromMap(maps.first);
    }

    return null;
  }
  // 🔹 DELETE
  Future<int> deleteHistorique(int id) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'Historique',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addHistorique(Historique Historique) async {
    try {
      Historique.code = _formatCode(Historique.id);
      final existing = await db.query(
        'Historique',
        where: 'code = ?',
        whereArgs: [Historique.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Historique avec ce code existe déjà",
        );
      }

      final id = await db.insert(
        'Historique',
        Historique.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Historique ajouté avec succès",
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
  static Future<int> getNextHistoriqueId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM Historique',
    );

    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
