import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

/// Statistiques financières calculées en direct pour un client
/// (paniers, versements, retours) — aucune valeur n'est mise en
/// cache sur le client lui-même.
class ClientStats {
  final double totalAchat;
  final int nbrAchat;
  final double totalVerse;
  final int nbrVersement;
  final int nbrRetour;
  final double totalRetour;
  final DateTime? dateDernierAchat;
  final double avance;
  final double credit;
  final double solde;

  ClientStats({
    required this.totalAchat,
    required this.nbrAchat,
    required this.totalVerse,
    required this.nbrVersement,
    required this.nbrRetour,
    required this.totalRetour,
    required this.dateDernierAchat,
    required this.avance,
    required this.credit,
    required this.solde,
  });
}

class ClientServices{

  final Database db;

  ClientServices(this.db);

  static Future<List<Client>> getAllClients() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('clients', orderBy: 'nom ASC',);

    return result.map((e) => Client.fromMap(e)).toList();

  }
// Ajoutez ces méthodes dans ClientServices.dart

  // ✅ Méthode avec transaction pour updateClient
  Future<ApiResponse<int>> updateClientWithTransaction(Transaction txn, Client client) async {
    try {
      final data = client.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await txn.update(
        'clients',
        data,
        where: 'id = ?',
        whereArgs: [client.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification reussie",
        data: rows,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Un client avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }
  Future<Client?> getClientById(int id) async {

    final maps = await db.query('clients' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Client.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateClient(Client client) async{
    try{

      final data = client.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'clients',
        data,
        where: 'id = ?',
        whereArgs: [client.id],
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
          message : "Un client avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteClient(int id) async {

    return await db.delete(
      'clients',

      where: 'id = ?',

      whereArgs: [id],
    );
  }
  Future<ApiResponse<int>> addClient(Client client) async {
    try{

      final existing = await db.query(
        'clients',
        where: 'nom = ?',
        whereArgs: [client.nom],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un Client avec ce nom existe deja",
        );
      }

      final id = await db.insert(
        'clients',
        client.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );


      return ApiResponse(
        success : true,
        message : "Client ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }
  static Future<int> getNextClientId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM clients',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Le solde/crédit/avance et les compteurs de versement ne sont plus
  /// suivis sur Client ; le versement lui-même reste enregistré via
  /// VerssementServices. Ces méthodes ne font donc plus rien côté Client,
  /// mais restent en place pour ne pas casser les dialogues appelants.
  Future<ApiResponse<void>> modifVersementRetour(int clientId, double ancienMontant, double nouveauMontant) async {
    return ApiResponse(success: true, message: "Versement modifié avec succès");
  }
  Future<ApiResponse<void>> modifVersement(int clientId, double ancienMontant, double nouveauMontant) async {
    return ApiResponse(success: true, message: "Versement modifié avec succès");
  }
  Future<ApiResponse<void>> ajouterVersementSortie(int clientId, double montant) async {
    return ApiResponse(success: true, message: "Versement ajouté avec succès");
  }
  Future<ApiResponse<void>> ajouterVersement(int clientId, double montant) async {
    return ApiResponse(success: true, message: "Versement ajouté avec succès");
  }
  Future<ApiResponse<void>> supprimerVersementSortie(int clientId, double montant) async {
    return ApiResponse(success: true, message: "Versement supprimé avec succès");
  }
  Future<ApiResponse<void>> supprimerVersement(int clientId, double montant) async {
    return ApiResponse(success: true, message: "Versement supprimé avec succès");
  }

  Future<ApiResponse<void>> ajouterAchat(int clientId, double montant) async {
    try {

      final client = await getClientById(clientId);

      if (client == null) {
        return ApiResponse(
          success: false,
          message: "Client introuvable",
        );
      }

      await db.update(
        'clients',
        {
          'dernier_achat': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [clientId],
      );

      return ApiResponse(
        success: true,
        message: "Achat ajouté avec succès",
      );

    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur achat : $e",
      );
    }
  }
  Future<ApiResponse<void>> ajouterRetour(int clientId, double montant) async {
    try {

      final client = await getClientById(clientId);

      if (client == null) {
        return ApiResponse(
          success: false,
          message: "Client introuvable",
        );
      }

      await db.update(
        'clients',
        {
          'dernier_achat': DateTime.now().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [clientId],
      );

      return ApiResponse(
        success: true,
        message: "Achat ajouté avec succès",
      );

    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur achat : $e",
      );
    }
  }

  /// Calcule en direct les statistiques financières d'un client
  /// (achats, versements, retours, solde) à partir des tables
  /// panniers, verssements et retours.
  static Future<ClientStats> getClientStats(Client client) async {
    final db = await DbCreator.openDb();

    final panniers = await db.query(
      'panniers',
      where: 'client = ? AND etat = 1',
      whereArgs: [client.nom],
    );
    final versements = await db.query(
      'verssements',
      where: 'beneficiare = ? AND typebeneficiare = ? AND etat = 1',
      whereArgs: [client.nom, 'Client'],
    );
    final retours = await db.query(
      'retours',
      where: 'client = ? AND type = ? AND etat = 1',
      whereArgs: [client.nom, 'Client'],
    );

    final double totalAchat = panniers.fold(
        0.0, (sum, p) => sum + (p['montant'] as num).toDouble());
    final int nbrAchat = panniers.length;

    final double totalVerse = versements.fold(
        0.0, (sum, v) => sum + (v['montant'] as num).toDouble());
    final int nbrVersement = versements.length;

    final int nbrRetour = retours.length;
    final double totalRetour = retours.fold(0.0, (sum, r) {
      final qte = (r['quantite'] as num).toDouble();
      final prixVente = (r['prix_vente'] as num?)?.toDouble() ?? 0;
      return sum + (qte * prixVente);
    });

    DateTime? dateDernierAchat;
    for (final p in panniers) {
      final date = DateTime.parse(p['date'] as String);
      if (dateDernierAchat == null || date.isAfter(dateDernierAchat)) {
        dateDernierAchat = date;
      }
    }

    final double avance = (totalVerse - totalAchat) > 0 ? (totalVerse - totalAchat) : 0;
    final double credit = (totalAchat - totalVerse) > 0 ? (totalAchat - totalVerse) : 0;
    final double solde = avance > 0 ? avance : (credit > 0 ? -credit : 0);

    return ClientStats(
      totalAchat: totalAchat,
      nbrAchat: nbrAchat,
      totalVerse: totalVerse,
      nbrVersement: nbrVersement,
      nbrRetour: nbrRetour,
      totalRetour: totalRetour,
      dateDernierAchat: dateDernierAchat,
      avance: avance,
      credit: credit,
      solde: solde,
    );
  }

}
