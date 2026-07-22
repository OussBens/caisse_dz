import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class SortieServices{

  final Database db;

  SortieServices(this.db);

  static Future<List<Sortie>> getAllSortie() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('sortie', orderBy: 'id ASC',);

    return result.map((e) => Sortie.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updateSortie(Sortie sortie) async{
    try{
      final data = sortie.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'sortie',
        data,
        where: 'id = ?',
        whereArgs: [sortie.id],
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

  Future<int> deleteSortie(int id) async {

    return await db.delete(
      'sortie',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addSortie(Sortie sortie) async {
    try{
      final id = await db.insert(
        'sortie',
        sortie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Sortie ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextSortieId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM sortie',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}