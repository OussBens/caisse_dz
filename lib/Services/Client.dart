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

/// Statistiques globales agrégées sur l'ensemble des clients
/// (nombre de clients, total des achats, total du crédit et
/// les clients "top" associés) — calculées en direct à partir
/// des tables panniers et verssements.
class ClientGlobalStats {
  final int nombreClients;
  final double totalAchat;
  final Client? clientTopAchat;
  final double montantTopAchat;
  final double totalCredit;
  final Client? clientTopCredit;
  final double montantTopCredit;

  ClientGlobalStats({
    required this.nombreClients,
    required this.totalAchat,
    required this.clientTopAchat,
    required this.montantTopAchat,
    required this.totalCredit,
    required this.clientTopCredit,
    required this.montantTopCredit,
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

  /// Retourne le client (autre que [excludeClientCode]) portant déjà ce nom
  /// (comparaison insensible à la casse et aux espaces) — null si le nom
  /// est libre.
  static Future<Client?> findClientByNom(String nom, {String? excludeClientCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'clients',
      where: 'LOWER(TRIM(nom)) = ?',
      whereArgs: [nom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final client = Client.fromMap(maps.first);
    if (client.code == excludeClientCode) return null;
    return client;
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
      where: 'client_code = ? AND etat = 1',
      whereArgs: [client.code],
    );
    final versementsEntree = await db.query(
      'verssements',
      where: 'beneficiare_code = ? AND typebeneficiare = ? AND sense = ? AND etat = 1',
      whereArgs: [client.code, 'Client', 'Entrée'],
    );
    final versementsSortie = await db.query(
      'verssements',
      where: 'beneficiare_code = ? AND typebeneficiare = ? AND sense = ? AND etat = 1',
      whereArgs: [client.code, 'Client', 'Sortie'],
    );
    final retours = await db.query(
      'retours',
      where: 'client_code = ? AND type = ? AND etat = 1',
      whereArgs: [client.code, 'Client'],
    );

    final double totalAchat = panniers.fold(
        0.0, (sum, p) => sum + (p['montant'] as num).toDouble());
    final int nbrAchat = panniers.length;

    final double totalVerseEntree = versementsEntree.fold(
        0.0, (sum, v) => sum + (v['montant'] as num).toDouble());
    final double totalVerseSortie = versementsSortie.fold(
        0.0, (sum, v) => sum + (v['montant'] as num).toDouble());
    // Total versement client = uniquement les versements Entrée (encaissements
    // du client). Les remboursements (Sortie) sont suivis via les retours et ne
    // sont pas déduits de ce total.
    final double totalVerse = totalVerseEntree;
    final int nbrVersement = versementsEntree.length + versementsSortie.length;

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

    final double solde = totalVerse - totalAchat;
    final double avance = solde > 0 ? solde : 0;
    final double credit = solde < 0 ? -solde : 0;

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

  /// Calcule en direct les statistiques globales de tous les clients :
  /// total des achats, client ayant le plus acheté, total du crédit
  /// (somme des différences positives achat - versement par client)
  /// et le client ayant le plus grand crédit.
  static Future<ClientGlobalStats> getGlobalClientStats() async {
    final db = await DbCreator.openDb();
    final clients = await getAllClients();
    final soldes = await _achatEtCreditParClient(db);

    double totalAchat = 0;
    double totalCredit = 0;
    Client? clientTopAchat;
    double montantTopAchat = 0;
    Client? clientTopCredit;
    double montantTopCredit = 0;

    for (final client in clients) {
      final achat = soldes[client.code]?.achat ?? 0;
      final credit = soldes[client.code]?.credit ?? 0;

      totalAchat += achat;
      totalCredit += credit;

      if (achat > montantTopAchat) {
        montantTopAchat = achat;
        clientTopAchat = client;
      }
      if (credit > montantTopCredit) {
        montantTopCredit = credit;
        clientTopCredit = client;
      }
    }

    return ClientGlobalStats(
      nombreClients: clients.length,
      totalAchat: totalAchat,
      clientTopAchat: clientTopAchat,
      montantTopAchat: montantTopAchat,
      totalCredit: totalCredit,
      clientTopCredit: clientTopCredit,
      montantTopCredit: montantTopCredit,
    );
  }

  /// Clients actifs ayant un crédit (achats non couverts par leurs
  /// versements), du plus grand au plus petit — [limite] premiers.
  static Future<List<({Client client, double credit})>> getClientsParCredit({int limite = 3}) async {
    final db = await DbCreator.openDb();
    final clients = await getAllClients();
    final soldes = await _achatEtCreditParClient(db);
    final resultat = [
      for (final c in clients)
        if (c.etat && (soldes[c.code]?.credit ?? 0) > 0) (client: c, credit: soldes[c.code]!.credit),
    ]..sort((a, b) => b.credit.compareTo(a.credit));
    return resultat.take(limite).toList();
  }

  /// Achats (paniers actifs) et crédit (achats − versements Entrée) par code
  /// client — même règle que [getClientStats].
  static Future<Map<String, ({double achat, double credit})>> _achatEtCreditParClient(DatabaseExecutor db) async {
    final panniersParClient = await db.rawQuery('''
      SELECT client_code, SUM(montant) AS total
      FROM panniers
      WHERE etat = 1 AND client_code IS NOT NULL
      GROUP BY client_code
    ''');
    final versementsParClient = await db.rawQuery('''
      SELECT beneficiare_code, sense, SUM(montant) AS total
      FROM verssements
      WHERE etat = 1 AND typebeneficiare = 'Client'
      GROUP BY beneficiare_code, sense
    ''');

    final Map<String, double> achatParClientCode = {
      for (final row in panniersParClient)
        row['client_code'] as String: (row['total'] as num?)?.toDouble() ?? 0,
    };
    final Map<String, double> entreeParClientCode = {};
    for (final row in versementsParClient) {
      final code = row['beneficiare_code'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      if (row['sense'] == 'Entrée') entreeParClientCode[code] = total;
    }

    final codes = {...achatParClientCode.keys, ...entreeParClientCode.keys};
    return {
      for (final code in codes)
        code: (
          achat: achatParClientCode[code] ?? 0,
          credit: () {
            final solde = (entreeParClientCode[code] ?? 0) - (achatParClientCode[code] ?? 0);
            return solde < 0 ? -solde : 0.0;
          }(),
        ),
    };
  }

}
