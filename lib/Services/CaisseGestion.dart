import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class GCServices{

  final Database db;

  GCServices(this.db);



  static Future<List<CaisseGestion>> getAllCaisses() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('caisseGestion', orderBy: 'nom_caisse ASC',);

    return result.map((e) => CaisseGestion.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updateCaisse(CaisseGestion caisse) async{
    try{

      final data = caisse.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'caisseGestion',
        data,
        where: 'id = ?',
        whereArgs: [caisse.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );

    } catch(e){
      if(e.toString().contains('UNIQUE constraint failed')){
        return ApiResponse(
          success : false,
          message : "Un Caisse avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteCaisse(int id) async {

    return await db.delete(
      'caisseGestion',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addCaisse(CaisseGestion caisse) async {
    try{

      final existing = await db.query(
        'caisseGestion',
        where: 'nom_caisse = ?',
        whereArgs: [caisse.nomCaisse],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Caisse avec ce nom existe deja",
        );
      }

      final id = await db.insert(
        'caisseGestion',
        caisse.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Caisse ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextCaisseId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM caisseGestion',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}