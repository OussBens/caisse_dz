import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class SmartScanServices{

  final Database db;

  SmartScanServices(this.db);

  static Future<List<SmartScan>> getAllSmartScans() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('smart_scan', orderBy: 'id ASC',);

    return result.map((e) => SmartScan.fromMap(e)).toList();

  }

  Future<SmartScan?> getSmartScanById(int id) async {

    final maps = await db.query('smart_scan' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return SmartScan.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateSmartScan(SmartScan SmartScan) async{
    try{

      final data = SmartScan.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'smart_scan',
        data,
        where: 'id = ?',
        whereArgs: [SmartScan.id],
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
          message : "Un SmartScan avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteSmartScan(int id) async {

    return await db.delete(
      'smart_scan',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addSmartScan(SmartScan SmartScan) async {
    try{

      final existing = await db.query(
        'smart_scan',
        where: 'code = ?',
        whereArgs: [SmartScan.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un SmartScan avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'smart_scan',
        SmartScan.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "SmartScan ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextSmartScanId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM smart_scan',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}