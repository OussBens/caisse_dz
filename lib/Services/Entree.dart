import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/entree.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class EntreeServices{

  final Database db;

  EntreeServices(this.db);

  static Future<List<Entree>> getAllEntre() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('entree', orderBy: 'id ASC',);

    return result.map((e) => Entree.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updateEntree(Entree entree) async{
    try{
      final data = entree.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'entree',
        data,
        where: 'id = ?',
        whereArgs: [entree.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );

    } catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteEntree(int id) async {

    return await db.delete(
      'entree',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addEntree(Entree entree) async {
    try{
      final id = await db.insert(
        'entree',
        entree.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Entree ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextEntreeId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM entree',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}