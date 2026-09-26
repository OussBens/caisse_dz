import 'package:caisse_dz/DBCreate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:caisse_dz/data/models/verssement.dart';

import '../core/utilis/api_response.dart';



class VerssementServices{

  final Database db;

  VerssementServices(this.db);

  /// Si [verssement] règle une créance client via le mode de paiement
  /// "Points" (voir ListsConst.modePaiementList / programme de bonus), vérifie
  /// et débite le solde de points du client sur le même executor que
  /// l'insertion — retourne un message d'erreur si le solde est insuffisant
  /// ou le client introuvable, `null` sinon (y compris pour tout versement
  /// qui n'est pas un paiement par points : aucune vérification n'est alors
  /// déclenchée).
  Future<String?> _validerEtDebiterPoints(DatabaseExecutor executor, Verssement verssement) async {
    if (verssement.mode_paiement != 'Points' ||
        verssement.typebeneficiare != 'Client' ||
        verssement.sense != 'Entrée') {
      return null;
    }

    final clientMaps = await executor.query(
      'clients',
      columns: ['solde_bonus'],
      where: 'code = ?',
      whereArgs: [verssement.beneficiareCode],
      limit: 1,
    );
    if (clientMaps.isEmpty) {
      return "Client introuvable pour le paiement par points";
    }

    final solde = (clientMaps.first['solde_bonus'] as num?)?.toDouble() ?? 0;
    if (solde < verssement.montant) {
      return "Solde de points insuffisant (disponible : ${solde.toStringAsFixed(2)})";
    }

    await executor.update(
      'clients',
      {'solde_bonus': solde - verssement.montant},
      where: 'code = ?',
      whereArgs: [verssement.beneficiareCode],
    );
    return null;
  }

  static Future<List<Verssement>> getAllverssement() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('verssements', orderBy: 'id ASC',);

    return result.map((e) => Verssement.fromMap(e)).toList();

  }

  /// Versements liés à une opération donnée (panier, retour ou smart scan),
  /// utilisé pour répercuter une modification du montant versé de l'opération.
  Future<List<Verssement>> getVerssementsByCodeOperation(String codeOperation) async {
    final result = await db.query(
      'verssements',
      where: 'code_operation = ?',
      whereArgs: [codeOperation],
    );

    return result.map((e) => Verssement.fromMap(e)).toList();
  }
// Ajoutez ces méthodes dans VerssementServices.dart

  // ✅ Méthode avec transaction pour addverssement
  Future<ApiResponse<int>> addverssementWithTransaction(Transaction txn, Verssement verssement) async {
    try {
      final existing = await txn.query(
        'verssements',
        where: 'code = ?',
        whereArgs: [verssement.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un verssement avec ce code existe deja",
        );
      }

      final erreurPoints = await _validerEtDebiterPoints(txn, verssement);
      if (erreurPoints != null) {
        return ApiResponse(success: false, message: erreurPoints);
      }

      final id = await txn.insert(
        'verssements',
        verssement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "verssement ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }
  Future<Verssement?> getverssementById(int id) async {

    final maps = await db.query('verssements' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Verssement.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateVerssement(Verssement verssement) async{
    try{

      final data = verssement.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'verssements',
        data,
        where: 'id = ?',
        whereArgs: [verssement.id],
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
          message : "Un verssement avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteverssement(int id) async {

    return await db.delete(
      'verssements',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  Future<ApiResponse<int>> addverssement(Verssement verssement) async {
    try{

      final existing = await db.query(
        'verssements',
        where: 'code = ?',
        whereArgs: [verssement.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un verssement avec ce code existe deja",
        );
      }

      // Vérification + débit du solde de points (si paiement par points) et
      // insertion dans une même transaction : évite qu'un double-appel
      // concurrent ne dépense deux fois le même solde.
      late final int id;
      await db.transaction((txn) async {
        final erreurPoints = await _validerEtDebiterPoints(txn, verssement);
        if (erreurPoints != null) {
          throw StateError(erreurPoints);
        }

        id = await txn.insert(
          'verssements',
          verssement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      });

      return ApiResponse(
        success : true,
        message : "verssement ajoute avec succes",
        data    : id,
      );

    } on StateError catch (e) {
      return ApiResponse(success: false, message: e.message);
    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextVerssementId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM verssements',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}