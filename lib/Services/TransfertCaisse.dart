import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/transfert.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class TransfertcaisseServices{

  final Database db;

  TransfertcaisseServices(this.db);

  static Future<List<TransfertCaisse>> getAllTransfertcaisse() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('transfert', orderBy: 'id ASC',);

    return result.map((e) => TransfertCaisse.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updateTransfertcaisse(TransfertCaisse transfert) async{
    try{
      final data = transfert.toMap()
        ..remove('id')
        ..remove('code');
      final rows = await db.update(
        'transfert',
        data,
        where: 'id = ?',
        whereArgs: [transfert.id],
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
          message : "Un transfert avec ce nom existe deja",
        );
      }
      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteTransfertcaisse(int id) async {

    return await db.delete(
      'transfert',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addTransfertcaisse(TransfertCaisse transfert) async {
    try{
      final id = await db.insert(
        'transfert',
        transfert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "transfert ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextTransfertcaisseId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM transfert',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}