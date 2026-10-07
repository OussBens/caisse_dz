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

/// Statistiques globales agrégées sur l'ensemble des fournisseurs
/// (nombre de fournisseurs, total des achats, total du crédit et
/// les fournisseurs "top" associés) — calculées en direct à partir
/// des tables smart_scan et verssements.
class FournisseurGlobalStats {
  final int nombreFournisseurs;
  final double totalAchat;
  final Fournisseur? fournisseurTopAchat;
  final double montantTopAchat;
  final double totalCredit;
  final Fournisseur? fournisseurTopCredit;
  final double montantTopCredit;

  FournisseurGlobalStats({
    required this.nombreFournisseurs,
    required this.totalAchat,
    required this.fournisseurTopAchat,
    required this.montantTopAchat,
    required this.totalCredit,
    required this.fournisseurTopCredit,
    required this.montantTopCredit,
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

  /// Retourne le fournisseur (autre que [excludeFournisseurCode]) portant
  /// déjà ce nom (comparaison insensible à la casse et aux espaces) — null
  /// si le nom est libre.
  static Future<Fournisseur?> findFournisseurByNom(String nom, {String? excludeFournisseurCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'fournisseurs',
      where: 'LOWER(TRIM(nom)) = ?',
      whereArgs: [nom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final fournisseur = Fournisseur.fromMap(maps.first);
    if (fournisseur.code == excludeFournisseurCode) return null;
    return fournisseur;
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
  /// (achats via smartScan, versements, retours, solde) à
  /// partir des tables smart_scan, verssements et retours.
  static Future<FournisseurStats> getFournisseurStats(Fournisseur fournisseur) async {
    final db = await DbCreator.openDb();

    final scans = await db.query(
      'smart_scan',
      where: 'fournisseur_code = ? AND etat = 1',
      whereArgs: [fournisseur.code],
    );
    final versementsEntree = await db.query(
      'verssements',
      where: 'beneficiare_code = ? AND typebeneficiare = ? AND sense = ? AND etat = 1',
      whereArgs: [fournisseur.code, 'Fournisseur', 'Entrée'],
    );
    final versementsSortie = await db.query(
      'verssements',
      where: 'beneficiare_code = ? AND typebeneficiare = ? AND sense = ? AND etat = 1',
      whereArgs: [fournisseur.code, 'Fournisseur', 'Sortie'],
    );
    final retours = await db.query(
      'retours',
      where: 'fournisseur_code = ? AND type = ? AND etat = 1',
      whereArgs: [fournisseur.code, 'Fournisseur'],
    );

    final double totalAchatScan = scans.fold(
        0.0, (sum, e) => sum + (e['montant'] as num).toDouble());
    final int nbrAchat = scans.length;

    final double totalVerseEntree = versementsEntree.fold(
        0.0, (sum, v) => sum + (v['montant'] as num).toDouble());
    final double totalVerseSortie = versementsSortie.fold(
        0.0, (sum, v) => sum + (v['montant'] as num).toDouble());
    // Total versé sortie (règlement au fournisseur) - Total versé entrée (remboursement du fournisseur)
    // Total versement fournisseur = uniquement les versements Sortie (paiements
    // au fournisseur). Les remboursements reçus (Entrée) sont suivis via les
    // retours et ne sont pas déduits de ce total.
    final double totalVerse = totalVerseSortie;
    final int nbrVersement = versementsEntree.length + versementsSortie.length;

    final int nbrRetour = retours.length;
    final double totalRetour = retours.fold(0.0, (sum, r) {
      final qte = (r['quantite'] as num).toDouble();
      final prixAchat = (r['prix_achat'] as num?)?.toDouble() ?? 0;
      return sum + (qte * prixAchat);
    });

    DateTime? dateDernierAchat;
    for (final s in scans) {
      final date = DateTime.parse(s['date'] as String);
      if (dateDernierAchat == null || date.isAfter(dateDernierAchat)) {
        dateDernierAchat = date;
      }
    }

    final double totalAchat = totalAchatScan;
    // Solde = Total achat - Total versé (positif = on doit encore au fournisseur)
    final double solde = totalAchat - totalVerse;
    // Avance : on a versé plus qu'acheté (solde négatif)
    final double avance = solde < 0 ? -solde : 0;
    // Credit : on a acheté plus que versé (solde positif)
    final double credit = solde > 0 ? solde : 0;

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

  /// Calcule en direct les statistiques globales de tous les fournisseurs :
  /// total des achats (entree + smart_scan), fournisseur ayant le plus
  /// vendu, total du crédit (somme des soldes négatifs par fournisseur)
  /// et le fournisseur ayant le plus grand crédit.
  static Future<FournisseurGlobalStats> getGlobalFournisseurStats() async {
    final db = await DbCreator.openDb();
    final fournisseurs = await getAllFournisseurs();
    final soldes = await _achatEtCreditParFournisseur(db);

    double totalAchat = 0;
    double totalCredit = 0;
    Fournisseur? fournisseurTopAchat;
    double montantTopAchat = 0;
    Fournisseur? fournisseurTopCredit;
    double montantTopCredit = 0;

    for (final fournisseur in fournisseurs) {
      final achat = soldes[fournisseur.code]?.achat ?? 0;
      final credit = soldes[fournisseur.code]?.credit ?? 0;

      totalAchat += achat;
      totalCredit += credit;

      if (achat > montantTopAchat) {
        montantTopAchat = achat;
        fournisseurTopAchat = fournisseur;
      }
      if (credit > montantTopCredit) {
        montantTopCredit = credit;
        fournisseurTopCredit = fournisseur;
      }
    }

    return FournisseurGlobalStats(
      nombreFournisseurs: fournisseurs.length,
      totalAchat: totalAchat,
      fournisseurTopAchat: fournisseurTopAchat,
      montantTopAchat: montantTopAchat,
      totalCredit: totalCredit,
      fournisseurTopCredit: fournisseurTopCredit,
      montantTopCredit: montantTopCredit,
    );
  }

  /// Fournisseurs actifs envers lesquels on a un crédit (achats non réglés
  /// par les versements Sortie), du plus grand au plus petit — [limite]
  /// premiers.
  static Future<List<({Fournisseur fournisseur, double credit})>> getFournisseursParCredit({int limite = 3}) async {
    final db = await DbCreator.openDb();
    final fournisseurs = await getAllFournisseurs();
    final soldes = await _achatEtCreditParFournisseur(db);
    final resultat = [
      for (final f in fournisseurs)
        if (f.etat && (soldes[f.code]?.credit ?? 0) > 0) (fournisseur: f, credit: soldes[f.code]!.credit),
    ]..sort((a, b) => b.credit.compareTo(a.credit));
    return resultat.take(limite).toList();
  }

  /// Achats (smart scans actifs) et crédit (achats − versements Sortie) par
  /// code fournisseur.
  static Future<Map<String, ({double achat, double credit})>> _achatEtCreditParFournisseur(DatabaseExecutor db) async {
    final scansParFournisseur = await db.rawQuery('''
      SELECT fournisseur_code, SUM(montant) AS total
      FROM smart_scan
      WHERE etat = 1
      GROUP BY fournisseur_code
    ''');
    final versementsParFournisseur = await db.rawQuery('''
      SELECT beneficiare_code, sense, SUM(montant) AS total
      FROM verssements
      WHERE etat = 1 AND typebeneficiare = 'Fournisseur'
      GROUP BY beneficiare_code, sense
    ''');

    final Map<String, double> achatParFournisseurCode = {};
    for (final row in scansParFournisseur) {
      final code = row['fournisseur_code'] as String;
      achatParFournisseurCode[code] = (achatParFournisseurCode[code] ?? 0) + ((row['total'] as num?)?.toDouble() ?? 0);
    }

    final Map<String, double> sortieParFournisseurCode = {};
    for (final row in versementsParFournisseur) {
      final code = row['beneficiare_code'] as String;
      final total = (row['total'] as num?)?.toDouble() ?? 0;
      if (row['sense'] == 'Sortie') sortieParFournisseurCode[code] = total;
    }

    // Total versé sortie (règlement au fournisseur) − achats.
    final codes = {...achatParFournisseurCode.keys, ...sortieParFournisseurCode.keys};
    return {
      for (final code in codes)
        code: (
          achat: achatParFournisseurCode[code] ?? 0,
          credit: () {
            final solde = (sortieParFournisseurCode[code] ?? 0) - (achatParFournisseurCode[code] ?? 0);
            return solde < 0 ? -solde : 0.0;
          }(),
        ),
    };
  }

}
