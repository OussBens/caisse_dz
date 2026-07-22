import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class PannierServices{

  final Database db;

  PannierServices(this.db);

  // Ajoutez ces méthodes dans PannierServices.dart

  // ✅ Méthode avec transaction pour addPannier
  Future<ApiResponse<int>> addPannierWithTransaction(Transaction txn, Pannier pannier) async {
    try {
      final existing = await txn.query(
        'panniers',
        where: 'code = ?',
        whereArgs: [pannier.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un pannier avec ce code existe deja",
        );
      }

      final id = await txn.insert(
        'panniers',
        pannier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "pannier ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // ✅ Méthode avec transaction pour getNextPannierId
  static Future<int> getNextPannierIdWithTransaction(Transaction txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM panniers');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  static Future<List<Pannier>> getAllPanniers() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('panniers', orderBy: 'id ASC',);

    return result.map((e) => Pannier.fromMap(e)).toList();

  }

  // 🔹 Panniers actifs d'un caissier (pour les stats vente utilisateur)
  static Future<List<Pannier>> getPanniersActifsByCaissierCode(String caissierCode) async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query(
      'panniers',
      where: 'caisser_code = ? AND etat = 1',
      whereArgs: [caissierCode],
    );

    return result.map((e) => Pannier.fromMap(e)).toList();

  }

  Future<Pannier?> getPannierById(int id) async {

    final maps = await db.query('panniers' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Pannier.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updatePannier(Pannier produit) async{
    try{

      final data = produit.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'panniers',
        data,
        where: 'id = ?',
        whereArgs: [produit.id],
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
          message : "Un pannier avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deletePannier(int id) async {

    return await db.delete(
      'panniers',

      where: 'id = ?',

      whereArgs: [id],

    );

  }
// Dans PannierServices
// Dans PannierServices
  // Dans PannierServices
  // Dans PannierServices
  // Dans PannierServices
  static Future<int> getLastPannierNumber() async {
    final db = await DbCreator.openDb();

    try {
      // Obtenir la date d'aujourd'hui (début de journée)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Récupérer le dernier code pour la date d'aujourd'hui uniquement
      final result = await db.rawQuery(
          '''SELECT code FROM panniers 
         WHERE date >= ? AND date <= ? 
         ORDER BY id DESC LIMIT 1''',
          [todayStart.toIso8601String(), todayEnd.toIso8601String()]
      );

      if (result.isNotEmpty && result.first['code'] != null) {
        // ✅ Convertir explicitement en String
        final String lastCode = result.first['code'].toString();

        // Extraire les chiffres à la fin du code
        final RegExp regex = RegExp(r'(\d+)$');
        final Match? match = regex.firstMatch(lastCode);

        if (match != null) {
          final int lastNumber = int.parse(match.group(1)!);
          return lastNumber + 1;
        }

        // Si le code est juste un nombre
        if (int.tryParse(lastCode) != null) {
          return int.parse(lastCode) + 1;
        }
      }

      // Si aucun panier n'existe pour aujourd'hui, commencer à 1
      return 1;
    } catch (e) {
      return 1;
    }
  }
// Ou si vous voulez récupérer le dernier ID
  static Future<int> getLastPannierId() async {
    final db = await DbCreator.openDb();

    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM panniers',
    );

    final maxId = result.first['maxId'] as int?;
    return maxId ?? 0; // Retourne le dernier ID
  }
  Future<ApiResponse<int>> addPannier(Pannier pannier) async {
    try{

      final existing = await db.query(
        'panniers',
        where: 'code = ?',
        whereArgs: [pannier.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un pannier avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'panniers',
        pannier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "pannier ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextPannierId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM panniers',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}