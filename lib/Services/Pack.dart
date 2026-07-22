import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class PackServices{

  final Database db;

  PackServices(this.db);

  Future<int> ActDis(List<Pack> packs) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var pack in packs) {

      final data = {
        'etat': pack.etat ? 0 : 1,
      };

      int updated = await db.update(
        'packs',
        data,
        where: 'id = ?',
        whereArgs: [pack.id],
      );
      count += updated;
    }

    return count;
  }


  static Future<List<Pack>> getAllPacks() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('packs', orderBy: 'nom ASC',);

    return result.map((e) => Pack.fromMap(e)).toList();

  }

  static Future<Pack?> getPackByCode(String code) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'packs',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Pack.fromMap(maps.first);
    }
    return null;
  }


  static Future<Pack?> getPackById(int id) async {

    final db = await DbCreator.openDb();

    final maps = await db.query('packs' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Pack.fromMap(maps.first);

    }

    return null;
  }

  Future<ApiResponse<int>> updatePack(Pack pack) async {
    try {
      final data = pack.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'packs',
        data,
        where: 'id = ?',
        whereArgs: [pack.id],
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
          message: "Un pack avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  static Future<int> deletePack(int id) async {
    final db = await DbCreator.openDb();
    return await db.delete(

      'packs',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addPack(Pack pack) async {
    try {
      // ✅ Check if a pack with the same name already exists
      final existing = await db.query(
        'packs',
        where: 'nom = ?',
        whereArgs: [pack.nom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un pack avec ce nom existe déjà",
        );
      }

      final id = await db.insert(
        'packs',
        pack.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Pack ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }


  static Future<int> getNextPackId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM packs',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

}