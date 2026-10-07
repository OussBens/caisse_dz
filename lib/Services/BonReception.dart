import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/bon_reception.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class BonReceptionServices {
  final Database db;

  BonReceptionServices(this.db);

  static Future<List<BonReception>> getAllBonReceptions() async {
    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query(
      'bon_reception',
      orderBy: 'date_reception DESC',
    );

    return result.map((e) => BonReception.fromMap(e)).toList();
  }

  Future<ApiResponse<int>> addBonReception(BonReception bon) async {
    try {
      final data = bon.toMap()..remove('id');

      final id = await db.insert('bon_reception', data);

      return ApiResponse(
        success: true,
        message: "Bon de réception ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<int>> markAsTraite(int id, String smartScanCode, String traiteParCode) async {
    try {
      final rows = await db.update(
        'bon_reception',
        {
          'statut': 'traite',
          'date_traitement': DateTime.now().toIso8601String(),
          'traite_par_code': traiteParCode,
          'smart_scan_code': smartScanCode,
        },
        where: 'id = ?',
        whereArgs: [id],
      );

      return ApiResponse(
        success: true,
        message: "Bon marqué comme traité",
        data: rows,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  Future<int> deleteBonReception(int id) async {
    return await db.delete('bon_reception', where: 'id = ?', whereArgs: [id]);
  }
}
