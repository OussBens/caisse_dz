import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/paramZakat.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class ParamZAKATServices{

  final Database db;

  ParamZAKATServices(this.db);

  static Future<ParamZakat> getParamZakat() async {

    final db = await DbCreator.openDb();

    final  result = await db.query('zakatParam' , orderBy: 'id ASC',);

    return ParamZakat.fromMap(result.first);

  }

  Future<ApiResponse<int>> updateZakat(ParamZakat paramzakat) async{
    try{
      final data = paramzakat.toMap()
        ..remove('id');

      final rows = await db.update(
        'zakatParam',
        data,
        where: 'id = ?',
        whereArgs: [paramzakat.id],
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

  Future<int> deleteZakat(int id) async {

    return await db.delete(
      'zakatParam',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addZakat(ParamZakat paramzakat) async {
    try{
      final id = await db.insert(
        'zakatParam',
        paramzakat.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Paramteur Zakat ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }
}