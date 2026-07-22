import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class SousCategoriesServices{

  final Database db;

  SousCategoriesServices(this.db);

  static Future<List<SousCategorie>> getAllSousCategorie() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('sous_categories', orderBy: 'nom ASC',);

    return result.map((e) => SousCategorie.fromMap(e)).toList();

  }

  Future<List<SousCategorie>> getSousCategorieByCategorie(String cate) async {

    final List<Map<String, dynamic>> result = await db.query('sous_categories', where: 'categorie_nom = ?', whereArgs: [cate],);

    return result.map((e) => SousCategorie.fromMap(e)).toList();

  }
  Future<SousCategorie?> getSousCategorieById(int id) async {

    final maps = await db.query('sous_categories', where: 'id = ?', whereArgs: [id],);

    if(maps.isNotEmpty){

      return SousCategorie.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateSousCategorie(SousCategorie sousCategorie) async {
    try {
      final data = sousCategorie.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'sous_categories',
        data,
        where: 'id = ?',
        whereArgs: [sousCategorie.id],
      );

      if (rows == 0) {
        return ApiResponse(
          success: false,
          message: "Sous-catégorie introuvable",
        );
      }

      return ApiResponse(
        success: true,
        message: "Modification réussie",
        data: rows,
      );
    } catch (e) {
      final error = e.toString();
      if (error.contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Nom sous-catégorie existe déjà",
        );
      }
      return ApiResponse(
        success: false,
        message: "Erreur modification: $error",
      );
    }
  }

  // ✅ Méthode pour mettre à jour le nom de la catégorie dans les sous-catégories
  Future<void> updateCategorieNomInSousCategories(String oldCategorieNom, String newCategorieNom) async {
    try {
      await db.transaction((txn) async {
        await txn.rawUpdate(
          'UPDATE sous_categories SET categorie_nom = ? WHERE categorie_nom = ?',
          [newCategorieNom, oldCategorieNom],
        );
      });
      print('✅ Catégorie nom mis à jour dans les sous-catégories: $oldCategorieNom -> $newCategorieNom');
    } catch (e) {
      print('❌ Erreur updateCategorieNomInSousCategories: $e');
    }
  }




  Future<int> deleteSousCategorie(int id) async {

    return  await db.delete(

      'sous_categories',

      where: 'id = ?',

      whereArgs: [id],
    );
  }
  static Future<int> getNextSousCategorieId(DatabaseExecutor db) async {

    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM sous_categories');

    final maxId = result.first['maxId'] as int?;

    return (maxId ?? 0) + 1;

  }

  Future<ApiResponse<int>> addSousCategorie(SousCategorie souscategorie) async {
    try {
      final id = await db.insert(
        'sous_categories',
        souscategorie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Sous-catégorie ajoutée avec succès",
        data: id,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Cette sous-catégorie existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }


}