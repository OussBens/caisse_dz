import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/caisseParam.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';
import '../core/utilis/colis_translator.dart';



class CaisseParamServices{

  final Database db;

  CaisseParamServices(this.db);

  static Future<List<CaisseParam>> getAllCaisseParam() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('caisseparam', orderBy: 'id ASC',);

    return result.map((e) => CaisseParam.fromMap(e)).toList();

  }

  Future<CaisseParam?> getCaisseParamByUserCode(String code) async {

    final maps = await db.query('caisseparam' , where: 'user = ?' , whereArgs: [code],);

    if(maps.isNotEmpty){

      return CaisseParam.fromMap(maps.first);

    }

    return null;

  }

  /// Quand le magasin d'une caisse change (Gestion Caisse > Modifier), les
  /// paramètres de caisse (caisseparam) et les paramètres utilisateur
  /// (userparam, Paramètres > Utilisateur) des comptes qui utilisent cette
  /// caisse suivent le nouveau magasin. Retourne les codes utilisateur
  /// concernés.
  Future<List<String>> synchroniserMagasinDeCaisse({
    required String caisseCode,
    required String magasinCode,
    required String magasinNom,
    required String magasinId,
  }) async {
    return db.transaction((txn) async {
      final rows = await txn.query('caisseparam', columns: ['user'], where: 'caisseCode = ?', whereArgs: [caisseCode]);
      final userCodes = rows.map((r) => r['user'] as String).toSet().toList();

      await txn.update(
        'caisseparam',
        {'magasinCode': magasinCode, 'magasin': magasinNom},
        where: 'caisseCode = ?',
        whereArgs: [caisseCode],
      );

      for (final userCode in userCodes) {
        final user = await txn.query('utilisateur', columns: ['username'], where: 'code = ?', whereArgs: [userCode], limit: 1);
        if (user.isEmpty) continue;
        await txn.update(
          'userparam',
          {'magasin': magasinNom, 'magasinid': magasinId},
          where: 'nom = ?',
          whereArgs: [user.first['username']],
        );
      }
      return userCodes;
    });
  }

  // Ajoutez cette fonction dans votre service CaisseParamServices
  Future<void> migrateColisData() async {
    final allParams = await getAllCaisseParam();

    for (var param in allParams) {
      final oldValue = param.selectedColis;
      final newKey = ColisTranslator.migrateOldValue(oldValue);

      if (oldValue != newKey) {
        param.selectedColis = newKey;
        await updateCaisseParam(param);
        print('Migrated: "$oldValue" -> "$newKey"');
      }
    }
  }

  Future<ApiResponse<int>> updateCaisseParam(CaisseParam caisseParam) async{
    try{

      final data = caisseParam.toMap()
        ..remove('id');

      final rows = await db.update(
        'caisseparam',
        data,
        where: 'id = ?',
        whereArgs: [caisseParam.id],
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
          message : "Un caisseParam avec ce id existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteCaisseParam(int id) async {

    return await db.delete(
      'caisseparam',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addCaisseParam(CaisseParam CaisseParam) async {
    try{

      final existing = await db.query(
        'caisseparam',
        where: 'id = ?',
        whereArgs: [CaisseParam.id],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un caisseparam avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'caisseparam',
        CaisseParam.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "caisseparam ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextCaisseParamId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM caisseparam',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}