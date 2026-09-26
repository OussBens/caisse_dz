import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class SmartScanServices{

  final Database db;

  SmartScanServices(this.db);

  /// Versements actifs (non annulés) liés à un smart scan donné.
  /// Le montant versé/reste n'est plus stocké : il est recalculé à partir
  /// des versements pour rester toujours à jour.
  static List<Verssement> verssementsActifsDuSmartScan(
      List<Verssement> versements, String codeSmartScan) {
    return versements
        .where((v) => v.codeOperation == codeSmartScan && v.etat)
        .toList();
  }

  /// Montant total versé pour ce smart scan.
  static double calculerVerse(List<Verssement> versements, String codeSmartScan) {
    return verssementsActifsDuSmartScan(versements, codeSmartScan)
        .fold(0.0, (s, v) => s + v.montant);
  }

  /// Nombre de versements actifs liés à ce smart scan.
  static int calculerNbrVersement(List<Verssement> versements, String codeSmartScan) {
    return verssementsActifsDuSmartScan(versements, codeSmartScan).length;
  }

  /// Reste à payer = montant du smart scan - montant versé.
  static double calculerReste(SmartScan scan, List<Verssement> versements) {
    return scan.montant - calculerVerse(versements, scan.code);
  }

  /// Regroupe le montant versé par code de smart scan (versements actifs
  /// uniquement), pour éviter de reparcourir toute la liste des versements
  /// pour chaque ligne d'un tableau/export.
  static Map<String, double> verseParSmartScan(List<Verssement> versements) {
    final Map<String, double> resultat = {};
    for (final v in versements) {
      if (!v.etat) continue;
      resultat[v.codeOperation] = (resultat[v.codeOperation] ?? 0) + v.montant;
    }
    return resultat;
  }

  /// Regroupe le nombre de versements actifs par code de smart scan.
  static Map<String, int> nbrVersementParSmartScan(List<Verssement> versements) {
    final Map<String, int> resultat = {};
    for (final v in versements) {
      if (!v.etat) continue;
      resultat[v.codeOperation] = (resultat[v.codeOperation] ?? 0) + 1;
    }
    return resultat;
  }

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

  /// Modifie les métadonnées d'un achat déjà enregistré. Refuse toute
  /// modification du contenu (montant, nombre de produits, fournisseur,
  /// date, observation) — même principe que PannierServices.updatePannier :
  /// un achat encaissé/réceptionné ne doit plus pouvoir être altéré après
  /// coup. Seul le montant versé (via le Versement lié, géré à part) reste
  /// modifiable ; une correction du contenu passe par une annulation.
  Future<ApiResponse<int>> updateSmartScan(SmartScan SmartScan) async{
    try{

      // Comparaison sur la map brute (pas via SmartScan.fromMap) : le nom du
      // paramètre de cette méthode ("SmartScan") masque la classe elle-même
      // dans cette portée, un appel de constructeur nommé serait donc résolu
      // comme un accès de membre sur le paramètre.
      final existingMaps = await db.query('smart_scan', where: 'id = ?', whereArgs: [SmartScan.id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "SmartScan introuvable");
      }
      final existingMap = existingMaps.first;

      if (existingMap['etat'] != 1) {
        return ApiResponse(
          success: false,
          message: "Cette entrée est annulée — plus aucune modification possible",
        );
      }

      final existingMontant = (existingMap['montant'] as num).toDouble();
      final existingNbrProduit = existingMap['nbr_produit'] as int;
      final existingFournisseurCode = existingMap['fournisseur_code'] as String;
      final existingDate = DateTime.parse(existingMap['date'] as String);
      final existingObservation = existingMap['observation'] as String?;

      if (existingMontant != SmartScan.montant ||
          existingNbrProduit != SmartScan.nbrProduit ||
          existingFournisseurCode != SmartScan.fournisseurCode ||
          existingDate != SmartScan.date ||
          existingObservation != SmartScan.observation) {
        return ApiResponse(
          success: false,
          message: "Un achat enregistré ne peut plus être modifié sur son contenu — utilisez une annulation",
        );
      }

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

  /// Annulation "douce" d'un achat déjà enregistré : bascule etat=annulé
  /// avec motif obligatoire, sans toucher au contenu ni le supprimer
  /// physiquement — la ligne et son historique restent en base pour preuve
  /// (même principe que PannierServices.annulerPannier). Aucune vérification
  /// de période clôturée : contrairement aux ventes, les achats n'ont pas de
  /// concept de clôture fiscale.
  Future<ApiResponse<int>> annulerSmartScan(
    int id, {
    required String motif,
    required String userCode,
  }) async {
    try {
      final existingMaps = await db.query('smart_scan', where: 'id = ? AND etat = 1', whereArgs: [id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Entrée introuvable ou déjà annulée");
      }

      final rows = await db.update(
        'smart_scan',
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
        return ApiResponse(success: false, message: "Entrée introuvable ou déjà annulée");
      }

      return ApiResponse(success: true, message: "Entrée annulée avec succès", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation : ${e.toString()}");
    }
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