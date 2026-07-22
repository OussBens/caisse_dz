import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../core/utilis/api_response.dart';

class ZakatServices {
  final Database db;

  ZakatServices(this.db);

  static Future<List<Zakat>> getAllZakat() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('zakat', orderBy: 'id ASC');
    return result.map((e) => Zakat.fromMap(e)).toList();
  }

  Future<ApiResponse<int>> updateZakat(Zakat zakat) async {
    try {
      final data = zakat.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'zakat',
        data,
        where: 'id = ?',
        whereArgs: [zakat.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteZakat(int id) async {
    return await db.delete(
      'zakat',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<ApiResponse<int>> addZakat(Zakat zakat) async {
    try {
      // ✅ Utiliser db.insert correctement
      final id = await db.insert(
        'zakat',
        zakat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Zakat ajouté avec succès",
        data: id,
      );
    } catch (e) {
      print('❌ Erreur addZakat: $e'); // ✅ Ajout de log pour déboguer
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  static Future<int> getNextZakatId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM zakat',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}