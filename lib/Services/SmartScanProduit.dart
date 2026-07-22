import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/smart_scan_produit.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class SmartScanProduitServices{

  final Database db;

  SmartScanProduitServices(this.db);

  Future<int> ActDis(List<SmartScanProduit> smartscanproduits) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var pack in smartscanproduits) {

      final data = {
        'etat': pack.etat ? 0 : 1,
      };

      int updated = await db.update(
        'SmartScanProduit',
        data,
        where: 'id = ?',
        whereArgs: [pack.id],
      );
      count += updated;
    }

    return count;
  }


  static Future<List<SmartScanProduit>> getAllSmartScanProduits() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('SmartScanProduit', orderBy: 'id ASC',);

    return result.map((e) => SmartScanProduit.fromMap(e)).toList();

  }

  static Future<List<SmartScanProduit>> getSmartScanProduitByCode(String code) async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query(
      'SmartScanProduit',
      where: 'code_SmartScan = ?',
      whereArgs: [code],
    );

    return result.map((e) => SmartScanProduit.fromMap(e)).toList();
  }


  static Future<SmartScanProduit?> getSmartScanProduitById(int id) async {

    final db = await DbCreator.openDb();

    final maps = await db.query('SmartScanProduits' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return SmartScanProduit.fromMap(maps.first);

    }

    return null;
  }

  Future<ApiResponse<int>> updateSmartScanProduit(SmartScanProduit smartscanproduit) async {
    try {
      final data = smartscanproduit.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'SmartScanProduit',
        data,
        where: 'id = ?',
        whereArgs: [smartscanproduit.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification réussie",
        data: rows,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Un SmartScanProduit avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }


   Future<int> deleteSmartScanProduit(int id) async {
    final db = await DbCreator.openDb();
    return await db.delete(

      'SmartScanProduit',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addSmartScanProduit(SmartScanProduit smartscanproduit) async {
    try {
      final id = await db.insert(
        'smartScanProduit',
        smartscanproduit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "smartScanProduit ajouté avec succès",
        data    : id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }


  static Future<int> getNextSmartScanProduitId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM SmartScanProduit',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}