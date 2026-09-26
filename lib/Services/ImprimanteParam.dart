import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/imprimanteParam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class ImprimanteParamServices {
  final Database db;

  ImprimanteParamServices(this.db);

  static Future<ImprimanteParam> getImprimanteParam() async {
    final db = await DbCreator.openDb();
    final result = await db.query('imprimante_param', where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) {
      return ImprimanteParam(
        id: 1,
        typeImprimante: TypeImprimante.bluetooth,
        largeurRouleau: 80,
      );
    }
    return ImprimanteParam.fromMap(result.first);
  }

  Future<ApiResponse<int>> updateImprimanteParam(
    ImprimanteParam param,
    String modifiedByCode,
  ) async {
    try {
      param.dateModif = DateTime.now();
      param.modifParCode = modifiedByCode;

      final rows = await db.update(
        'imprimante_param',
        param.toMap(),
        where: 'id = ?',
        whereArgs: [param.id],
      );

      if (rows == 0) {
        await db.insert('imprimante_param', param.toMap());
      }

      return ApiResponse(success: true, message: "Paramètres imprimante enregistrés", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur enregistrement: $e");
    }
  }
}
