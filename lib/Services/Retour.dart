import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class RetourServices{

  final Database db;

  RetourServices(this.db);

  static Future<List<Retour>> getAllRetour() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('retours', orderBy: 'id ASC',);

    return result.map((e) => Retour.fromMap(e)).toList();

  }

  Future<Retour?> getRetourById(int id) async {

    final maps = await db.query('retours' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Retour.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateRetour(Retour retour) async{
    try{

      final data = retour.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'retours',
        data,
        where: 'id = ?',
        whereArgs: [retour.id],
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
          message : "Un retour avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteRetour(int id) async {

    return await db.delete(
      'retours',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addRetour(Retour retour) async {
    try{

      final existing = await db.query(
        'retours',
        where: 'code = ?',
        whereArgs: [retour.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un retour avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'retours',
        retour.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "retour ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextRetourId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM retours',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}