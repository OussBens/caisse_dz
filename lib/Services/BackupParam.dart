import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/backupParam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class BackupParamServices {
  final Database db;

  BackupParamServices(this.db);

  static Future<BackupParam> getBackupParam() async {
    final db = await DbCreator.openDb();
    final result = await db.query('backup_param', where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) {
      return BackupParam(id: 1, autoBackupActif: false, frequence: FrequenceBackup.demarrage);
    }
    return BackupParam.fromMap(result.first);
  }

  Future<ApiResponse<int>> updateBackupParam(
    BackupParam param,
    String? modifiedByCode,
  ) async {
    try {
      param.modifParCode = modifiedByCode;

      final rows = await db.update(
        'backup_param',
        param.toMap(),
        where: 'id = ?',
        whereArgs: [param.id],
      );

      if (rows == 0) {
        await db.insert('backup_param', param.toMap());
      }

      return ApiResponse(success: true, message: "Paramètres de sauvegarde enregistrés", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur enregistrement: $e");
    }
  }
}
