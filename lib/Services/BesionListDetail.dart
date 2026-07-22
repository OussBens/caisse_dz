import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/besion_list_detail.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class BesoinListDetailServices{

  final Database db;

  BesoinListDetailServices(this.db);

  static Future<List<BesoinListDetail>> getAllBesoinListDetail() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('besion_list_detail', orderBy: 'id ASC',);

    return result.map((e) => BesoinListDetail.fromMap(e)).toList();

  }

  Future<List<BesoinListDetail>> getBesoinListDetailByBLCode(String code) async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('besion_list_detail',where: 'besion_list_code = ?',whereArgs: [code], orderBy: 'id ASC',);

    return result.map((e) => BesoinListDetail.fromMap(e)).toList();

  }

  Future<ApiResponse<int>> updateBesionListDetail(BesoinListDetail besionlistdetail) async{
    try{
      final data = besionlistdetail.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'besion_list_detail',
        data,
        where: 'id = ?',
        whereArgs: [besionlistdetail.id],
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

  Future<int> deletebesion_list_detail(int id) async {

    return await db.delete(
      'besion_list_detail',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addbesion_list_detail(BesoinListDetail besionlistdetail) async {
    try{
      final id = await db.insert(
        'besion_list_detail',
        besionlistdetail.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Besion List Detail ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextBesoinListDetailId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM besion_list_detail',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}