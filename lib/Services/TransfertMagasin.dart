import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/transfert_magasin.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class TransfertMagasinServices {
  final Database db;

  TransfertMagasinServices(this.db);

  static Future<List<TransfertMagasin>> getAllTransferts() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('transfert_magasin', orderBy: 'id ASC');
    return result.map((e) => TransfertMagasin.fromMap(e)).toList();
  }

  Future<ApiResponse<int>> addTransfert(TransfertMagasin transfert) async {
    try {
      final id = await db.insert(
        'transfert_magasin',
        transfert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Transfert enregistré avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  /// Annulation "douce" d'un transfert déjà enregistré : bascule etat=annulé
  /// avec motif obligatoire, sans toucher au contenu ni le supprimer
  /// physiquement (même principe que Sortie/Retour).
  Future<ApiResponse<int>> annulerTransfert(
    int id, {
    required String motif,
    required String userCode,
  }) async {
    try {
      final existingMaps = await db.query('transfert_magasin', where: 'id = ? AND etat = 1', whereArgs: [id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Transfert introuvable ou déjà annulé");
      }

      final rows = await db.update(
        'transfert_magasin',
        {
          'etat': 0,
          'date_annul': DateTime.now().toIso8601String(),
          'annul_par_code': userCode,
          'motif_annul': motif,
        },
        where: 'id = ? AND etat = 1',
        whereArgs: [id],
      );

      if (rows == 0) {
        return ApiResponse(success: false, message: "Transfert introuvable ou déjà annulé");
      }

      return ApiResponse(success: true, message: "Transfert annulé avec succès", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation : ${e.toString()}");
    }
  }

  static Future<int> getNextTransfertId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM transfert_magasin');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
