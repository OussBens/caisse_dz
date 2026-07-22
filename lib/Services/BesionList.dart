import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class BesoinListServices{

  final Database db;

  BesoinListServices(this.db);

  static Future<List<BesoinList>> getAllBesoinList() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('besionList', orderBy: 'id ASC',);

    return result.map((e) => BesoinList.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updatebesionList(BesoinList besionlist) async{
    try{
      final data = besionlist.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'besionList',
        data,
        where: 'id = ?',
        whereArgs: [besionlist.id],
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

  Future<int> deletebesionList(int id) async {

    return await db.delete(
      'besionList',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addbesionList(BesoinList besionlist) async {
    try{
      final id = await db.insert(
        'besionList',
        besionlist.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Besion List ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextbesionListId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM besionList',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}