import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/entrepriseParam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class EntrepriseParamServices {
  final Database db;

  EntrepriseParamServices(this.db);

  static Future<EntrepriseParam> getEntrepriseParam() async {
    final db = await DbCreator.openDb();
    final result = await db.query('entreprise_param', where: 'id = ?', whereArgs: [1]);

    if (result.isEmpty) {
      return EntrepriseParam(id: 1, nomBoutique: 'Ma Boutique');
    }
    return EntrepriseParam.fromMap(result.first);
  }

  Future<ApiResponse<int>> updateEntrepriseParam(
    EntrepriseParam param,
    String modifiedByCode,
  ) async {
    try {
      param.dateModif = DateTime.now();
      param.modifParCode = modifiedByCode;

      final rows = await db.update(
        'entreprise_param',
        param.toMap(),
        where: 'id = ?',
        whereArgs: [param.id],
      );

      if (rows == 0) {
        await db.insert('entreprise_param', param.toMap());
      }

      return ApiResponse(success: true, message: "Informations boutique enregistrées", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur enregistrement: $e");
    }
  }
}
