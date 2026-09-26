import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class RetourServices{

  final Database db;

  RetourServices(this.db);

  static Future<List<Retour>> getAllRetour() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('retours', orderBy: 'id ASC',);

    return result.map((e) => Retour.fromMap(e)).toList();

  }

  /// Retours (actifs) rattachés à ce panier (vente client) — un panier peut
  /// avoir plusieurs lignes de retour, une par produit rendu. Utilisé pour
  /// afficher un badge "a un retour" sur le panier concerné.
  static Future<List<Retour>> getRetoursByPannierCode(String codePannier) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'retours',
      where: 'retour_correspond_de = ? AND type = ? AND etat = 1',
      whereArgs: [codePannier, 'Client'],
    );
    return result.map((e) => Retour.fromMap(e)).toList();
  }

  /// Quantité déjà retournée (retours actifs) pour un produit donné, au sein
  /// d'un même document d'origine (panier ou smartscan/entrée rapide) — sert
  /// à plafonner la quantité d'un nouveau retour pour ne pas dépasser ce qui
  /// a été vendu/acheté sur ce document.
  static Future<double> getQuantiteDejaRetournee({
    required String retourCorrespondDe,
    required String codeProduit,
  }) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'retours',
      where: 'retour_correspond_de = ? AND code_produit = ? AND etat = 1',
      whereArgs: [retourCorrespondDe, codeProduit],
    );
    return result.fold<double>(0.0, (s, r) => s + (r['quantite'] as num).toDouble());
  }

  /// Vrai si ce code correspond à un retour existant. Sert à empêcher la
  /// modification/suppression directe d'un versement lié à un retour : ce
  /// versement doit uniquement être modifié/supprimé en passant par le
  /// retour lui-même (voir retour_modif.dart / retour_actif.dart).
  static Future<bool> estLieAUnRetour(String codeOperation) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'retours',
      where: 'code = ?',
      whereArgs: [codeOperation],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  Future<Retour?> getRetourById(int id) async {

    final maps = await db.query('retours' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Retour.fromMap(maps.first);

    }

    return null;

  }

  /// Modifie les métadonnées d'un retour déjà enregistré (date, observation
  /// uniquement). Refuse toute modification du contenu (produit, quantité,
  /// prix, type, bénéficiaire) — même principe que
  /// PannierServices.updatePannier/SmartScanServices.updateSmartScan : le
  /// remboursement lié (Versement) est toujours quantité×prix, jamais un
  /// paiement partiel séparé, donc rien ne justifie de rouvrir le contenu.
  /// Une correction du contenu passe par une annulation.
  Future<ApiResponse<int>> updateRetour(Retour retour) async{
    try{

      final existingMaps = await db.query('retours', where: 'id = ?', whereArgs: [retour.id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Retour introuvable");
      }
      final existingMap = existingMaps.first;

      if (existingMap['etat'] != 1) {
        return ApiResponse(
          success: false,
          message: "Ce retour est annulé — plus aucune modification possible",
        );
      }

      final existingQuantite = (existingMap['quantite'] as num).toDouble();
      final existingCodeProduit = existingMap['code_produit'] as String;
      final existingType = existingMap['type'] as String;
      final existingClientCode = existingMap['client_code'] as String?;
      final existingFournisseurCode = existingMap['fournisseur_code'] as String?;
      final existingPrixAchat = (existingMap['prix_achat'] as num?)?.toDouble();
      final existingPrixVente = (existingMap['prix_vente'] as num?)?.toDouble();

      if (existingQuantite != retour.quantite ||
          existingCodeProduit != retour.codeProduit ||
          existingType != retour.type ||
          existingClientCode != retour.client_code ||
          existingFournisseurCode != retour.fournisseur_code ||
          existingPrixAchat != retour.prixAchat ||
          existingPrixVente != retour.prixVente) {
        return ApiResponse(
          success: false,
          message: "Un retour enregistré ne peut plus être modifié sur son contenu — utilisez une annulation",
        );
      }

      final data = retour.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'retours',
        data,
        where: 'id = ?',
        whereArgs: [retour.id],
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
          message : "Un retour avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  /// Annulation "douce" d'un retour déjà enregistré : bascule etat=annulé
  /// avec motif obligatoire, sans toucher au contenu ni le supprimer
  /// physiquement (même principe que PannierServices.annulerPannier /
  /// SmartScanServices.annulerSmartScan).
  Future<ApiResponse<int>> annulerRetour(
    int id, {
    required String motif,
    required String userCode,
  }) async {
    try {
      final existingMaps = await db.query('retours', where: 'id = ? AND etat = 1', whereArgs: [id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Retour introuvable ou déjà annulé");
      }

      final rows = await db.update(
        'retours',
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
        return ApiResponse(success: false, message: "Retour introuvable ou déjà annulé");
      }

      return ApiResponse(success: true, message: "Retour annulé avec succès", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation : ${e.toString()}");
    }
  }

  Future<ApiResponse<int>> addRetour(Retour retour) async {
    try{

      final existing = await db.query(
        'retours',
        where: 'code = ?',
        whereArgs: [retour.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un retour avec ce code existe deja",
        );
      }

      final id = await db.insert(
        'retours',
        retour.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "retour ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextRetourId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM retours',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}