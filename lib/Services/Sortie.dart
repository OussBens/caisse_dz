import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';


class SortieServices{

  final Database db;

  SortieServices(this.db);

  static Future<List<Sortie>> getAllSortie() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('sortie', orderBy: 'id ASC',);

    return result.map((e) => Sortie.fromMap(e)).toList();

  }

  /// Modifie les métadonnées d'une sortie déjà enregistrée (date, observation
  /// uniquement). Refuse toute modification du contenu (produit, quantité,
  /// type, prix, montant) — même principe que
  /// PannierServices.updatePannier/RetourServices.updateRetour : une sortie
  /// est un mouvement de stock déjà appliqué, le corriger après coup passe
  /// par une annulation, pas par une réécriture de son contenu.
  Future<ApiResponse<int>> updateSortie(Sortie sortie) async{
    try{
      final existingMaps = await db.query('sortie', where: 'id = ?', whereArgs: [sortie.id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Sortie introuvable");
      }
      final existingMap = existingMaps.first;

      if (existingMap['etat'] != 1) {
        return ApiResponse(
          success: false,
          message: "Cette sortie est annulée — plus aucune modification possible",
        );
      }

      final existingQuantite = (existingMap['quantite'] as num).toDouble();
      final existingProduitCode = existingMap['produit_code'] as String;
      final existingType = existingMap['type'] as String;
      final existingPrix = (existingMap['prix'] as num).toDouble();
      final existingMontant = (existingMap['montant'] as num).toDouble();

      if (existingQuantite != sortie.quantite ||
          existingProduitCode != sortie.produitCode ||
          existingType != sortie.type ||
          existingPrix != sortie.prix ||
          existingMontant != sortie.montant) {
        return ApiResponse(
          success: false,
          message: "Une sortie enregistrée ne peut plus être modifiée sur son contenu — utilisez une annulation",
        );
      }

      final data = sortie.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'sortie',
        data,
        where: 'id = ?',
        whereArgs: [sortie.id],
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

  /// Annulation "douce" d'une sortie déjà enregistrée : bascule etat=annulé
  /// avec motif obligatoire, sans toucher au contenu ni la supprimer
  /// physiquement (même principe que les autres annulerXxx du projet).
  Future<ApiResponse<int>> annulerSortie(
    int id, {
    required String motif,
    required String userCode,
  }) async {
    try {
      final existingMaps = await db.query('sortie', where: 'id = ? AND etat = 1', whereArgs: [id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Sortie introuvable ou déjà annulée");
      }

      final rows = await db.update(
        'sortie',
        {
          'etat': 0,
          'date_annul': DateTime.now().toIso8601String(),
          'annul_par_code': userCode,
          'motif_annul': motif,
        },
        where: 'id = ? AND etat = 1',
        whereArgs: [id],
      );

      if (rows == 0) {
        return ApiResponse(success: false, message: "Sortie introuvable ou déjà annulée");
      }

      return ApiResponse(success: true, message: "Sortie annulée avec succès", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation : ${e.toString()}");
    }
  }

  Future<ApiResponse<int>> addSortie(Sortie sortie) async {
    try{
      final id = await db.insert(
        'sortie',
        sortie.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success : true,
        message : "Sortie ajoute avec succes",
        data    : id,
      );

    }catch(e){
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextSortieId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM sortie',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}