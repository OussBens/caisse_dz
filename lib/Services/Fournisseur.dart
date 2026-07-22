import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

/// Statistiques financières calculées en direct pour un fournisseur
/// (entrées, smart scans, versements, retours) — aucune valeur
/// n'est mise en cache sur le fournisseur lui-même.
class FournisseurStats {
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

  FournisseurStats({
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

class FournisseurServices {

  final Database db;

  FournisseurServices(this.db);

  // 🔹 ACTIVATE / DEACTIVATE
  Future<int> ActDis(List<Fournisseur> fournisseurs) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var f in fournisseurs) {
      final data = {
        'etat': f.etat == 1 ? 0 : 1,
      };

      int updated = await db.update(
        'fournisseurs',
        data,
        where: 'id = ?',
        whereArgs: [f.id],
      );

      count += updated;
    }

    return count;
  }

  // 🔹 GET ALL
  static Future<List<Fournisseur>> getAllFournisseurs() async {

    final db = await DbCreator.openDb();

    final result = await db.query(
      'fournisseurs',
      orderBy: 'nom ASC',
    );

    return result.map((e) => Fournisseur.fromMap(e)).toList();
  }

  // 🔹 GET BY CODE
  static Future<Fournisseur?> getFournisseurByCode(String code) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'fournisseurs',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Fournisseur.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 GET BY ID
  static Future<Fournisseur?> getFournisseurById(int id) async {
    final db = await DbCreator.openDb();

    final maps = await db.query(
      'fournisseurs',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return Fournisseur.fromMap(maps.first);
    }

    return null;
  }

  // 🔹 UPDATE
  Future<ApiResponse<int>> updateFournisseur(Fournisseur fournisseur) async {
    try {
      final data = fournisseur.toMap()
        ..remove('id')
        ..remove('code'); // prevent editing unique key

      final rows = await db.update(
        'fournisseurs',
        data,
        where: 'id = ?',
        whereArgs: [fournisseur.id],
      );

      return ApiResponse(
        success: true,
        message: "Modification réussie",
        data: rows,
      );
    } catch (e) {
      if (e.toString().contains('UNIQUE constraint failed')) {
        return ApiResponse(
          success: false,
          message: "Un fournisseur avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  // 🔹 DELETE
  Future<int> deleteFournisseur(int id) async {
    final db = await DbCreator.openDb();

    return await db.delete(
      'fournisseurs',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 🔹 ADD
  Future<ApiResponse<int>> addFournisseur(Fournisseur fournisseur) async {
    try {
      final existing = await db.query(
        'fournisseurs',
        where: 'nom = ?',
        whereArgs: [fournisseur.nom],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un fournisseur avec ce nom existe déjà",
        );
      }

      final id = await db.insert(
        'fournisseurs',
        fournisseur.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Fournisseur ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // 🔹 NEXT ID
  static Future<int> getNextFournisseurId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM fournisseurs',
    );

    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Le solde/crédit/avance, les compteurs de versement et d'achat ne sont
  /// plus suivis sur Fournisseur ; le versement/achat/retour lui-même reste
  /// enregistré via les Services dédiés. Ces méthodes ne font donc plus rien
  /// côté Fournisseur, mais restent en place pour ne pas casser les
  /// dialogues appelants.
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
    return ApiResponse(success: true, message: "Achat ajouté avec succès");
  }
  Future<ApiResponse<void>> ajouterRetour(int clientId, double montant) async {
    return ApiResponse(success: true, message: "Achat ajouté avec succès");
  }

  /// Calcule en direct les statistiques financières d'un fournisseur
  /// (achats via entree/smartScan, versements, retours, solde) à
  /// partir des tables entree, smart_scan, verssements et retours.
  static Future<FournisseurStats> getFournisseurStats(Fournisseur fournisseur) async {
    final db = await DbCreator.openDb();

    final entrees = await db.query(
      'entree',
      where: 'fournisseur = ? AND etat = 1',
      whereArgs: [fournisseur.nom],
    );
    final scans = await db.query(
      'smart_scan',
      where: 'fournisseur = ? AND etat = 1',
      whereArgs: [fournisseur.nom],
    );
    final versements = await db.query(
      'verssements',
      where: 'beneficiare = ? AND typebeneficiare = ? AND etat = 1',
      whereArgs: [fournisseur.nom, 'Fournisseur'],
    );
    final retours = await db.query(
      'retours',
      where: 'fournisseur = ? AND type = ? AND etat = 1',
      whereArgs: [fournisseur.nom, 'Fournisseur'],
    );

    final double totalAchatEntree = entrees.fold(
        0.0, (sum, e) => sum + (e['montant'] as num).toDouble());
    final double totalAchatScan = scans.fold(
        0.0, (sum, e) => sum + (e['montant'] as num).toDouble());
    final int nbrAchat = entrees.length + scans.length;

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
    for (final e in entrees) {
      final date = DateTime.parse(e['date'] as String);
      if (dateDernierAchat == null || date.isAfter(dateDernierAchat)) {
        dateDernierAchat = date;
      }
    }
    for (final s in scans) {
      final date = DateTime.parse(s['date'] as String);
      if (dateDernierAchat == null || date.isAfter(dateDernierAchat)) {
        dateDernierAchat = date;
      }
    }

    final double totalAchat = totalAchatEntree + totalAchatScan;
    final double avance = (totalVerse - totalAchat) > 0 ? (totalVerse - totalAchat) : 0;
    final double credit = (totalAchat - totalVerse) > 0 ? (totalAchat - totalVerse) : 0;
    final double solde = avance > 0 ? avance : (credit > 0 ? -credit : 0);

    return FournisseurStats(
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
