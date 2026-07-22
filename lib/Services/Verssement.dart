import 'package:caisse_dz/DBCreate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caisse_dz/data/models/verssement.dart';

import '../core/utilis/api_response.dart';



class VerssementServices{

  final Database db;

  VerssementServices(this.db);

  static Future<List<Verssement>> getAllverssement() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('verssements', orderBy: 'id ASC',);

    return result.map((e) => Verssement.fromMap(e)).toList();

  }
// Ajoutez ces méthodes dans VerssementServices.dart

  // ✅ Méthode avec transaction pour addverssement
  Future<ApiResponse<int>> addverssementWithTransaction(Transaction txn, Verssement verssement) async {
    try {
      final existing = await txn.query(
        'verssements',
        where: 'code = ?',
        whereArgs: [verssement.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un verssement avec ce code existe deja",
        );
      }

      final id = await txn.insert(
        'verssements',
        verssement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "verssement ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }
  Future<Verssement?> getverssementById(int id) async {

    final maps = await db.query('verssements' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Verssement.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateVerssement(Verssement verssement) async{
    try{

      final data = verssement.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'verssements',
        data,
        where: 'id = ?',
        whereArgs: [verssement.id],
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
          message : "Un verssement avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteverssement(int id) async {

    return await db.delete(
      'verssements',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addverssement(Verssement verssement) async {
    try{

      final existing = await db.query(
        'verssements',
        where: 'code = ?',
        whereArgs: [verssement.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un verssement avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'verssements',
        verssement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "verssement ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextVerssementId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM verssements',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}