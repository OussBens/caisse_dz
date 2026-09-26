import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class CategorieServices{
  final Database db;
  CategorieServices(this.db);

  static Future<List<Categorie>> getAllCategorie() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('categories' , orderBy: 'nom ASC',);

    return result.map((e)  => Categorie.fromMap(e)).toList();

  }
  Future<Categorie?> getCategorieById(int id) async {

    final maps = await db.query('categories', where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Categorie.fromMap(maps.first);

    }

    return null;
  }

  Future<ApiResponse<int>> updateCategorie(Categorie categorie) async {
    try {
      final data = categorie.toMap()
        ..remove('id')
        ..remove('code')
        ..['date_modif'] = DateTime.now().toIso8601String();

      final rows = await db.update(
        'categories',
        data,
        where: 'id = ?',
        whereArgs: [categorie.id],
      );

      if (rows == 0) {
        return ApiResponse(
          message: "Categorie introuvable",
          success: false,
        );
      }

      return ApiResponse(
        message: "Modification réussie",
        success: true,
        data: rows,
      );

    } catch (e) {
      final error = e.toString();

      if (error.contains('UNIQUE constraint failed: categories.code')) {
        return ApiResponse(
          message: "Ce code catégorie existe déjà",
          success: false,
        );
      }

      if (error.contains('UNIQUE constraint failed: categories.nom')) {
        return ApiResponse(
          message: "Une catégorie avec ce nom existe déjà",
          success: false,
        );
      }

      return ApiResponse(
        message: "Erreur modification: $error",
        success: false,
      );
    }
  }


  static Future<int> getNextCategorieId(DatabaseExecutor db) async {

    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM categories');

    final maxId = result.first['maxId'] as int?;

    return (maxId ?? 0) + 1;
  }

  Future<ApiResponse<int>> addCategorie(Categorie categorie) async {
    try {

      final existing = await db.query(
        'categories',
        where: 'nom = ?',
        whereArgs: [categorie.nom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un categorie avec ce nom existe déjà",
        );
      }

      final id = await db.insert(
        'categories',
        categorie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Categorie ajouté avec succès",
        data: id,
      );

    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }

  Future<int> deleteCategorie(int id) async {
    return await db.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

}