import 'package:caisse_dz/Services/RepartitionStock.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class MouvementsServices {

  final Database db;

  MouvementsServices(this.db);

  // ✅ Méthode avec transaction
  Future<ApiResponse<int>> addMouvementWithTransaction(Transaction txn, Mouvement mouvement) async {
    try {
      final id = await txn.insert(
        'mouvements',
        mouvement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "mouvement ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // ✅ Garder l'ancienne méthode pour compatibilité (sans transaction)
  Future<ApiResponse<int>> addMouvement(Mouvement mouvement) async {
    try {
      final id = await db.insert(
        'mouvements',
        mouvement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "mouvement ajouté avec succès",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  Future<int> ActDis(List<Mouvement> mouvements) async {
    final db = await DbCreator.openDb();
    int count = 0;

    for (var mouvement in mouvements) {
      final data = {
        'etat': mouvement.etat ? 0 : 1,
      };

      int updated = await db.update(
        'mouvements',
        data,
        where: 'id = ?',
        whereArgs: [mouvement.id],
      );
      count += updated;
    }

    return count;
  }

  static Future<List<Mouvement>> getAllMouvements() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('mouvements', orderBy: 'id ASC');
    return result.map((e) => Mouvement.fromMap(e)).toList();
  }

  static Future<List<Mouvement>> getAllMouvementsByCodeOper(String code) async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('mouvements', where: 'code_operation = ?', whereArgs: [code]);
    return result.map((e) => Mouvement.fromMap(e)).toList();
  }

  static Future<bool> isProduitHaveMouvement(String code) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'mouvements',
      where: 'code_produit = ?',
      whereArgs: [code],
      limit: 1,
    );
    return result.isNotEmpty;
  }

  static Future<Mouvement?> getMouvementById(int id) async {
    final db = await DbCreator.openDb();
    final maps = await db.query('mouvements', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) {
      return Mouvement.fromMap(maps.first);
    }
    return null;
  }

  Future<ApiResponse<int>> updateMouvement(Mouvement mouvement) async {
    try {
      final data = mouvement.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'mouvements',
        data,
        where: 'id = ?',
        whereArgs: [mouvement.id],
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
          message: "Un Mouvement avec ce nom existe déjà",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification: ${e.toString()}",
      );
    }
  }

  static Future<int> deleteMouvement(int id) async {
    final db = await DbCreator.openDb();
    return await db.delete(
      'mouvements',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<int> getNextMouvementId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM mouvements');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Vrai si ce type/sousType de mouvement ajoute au stock (achat, retour
  /// client, distribution entrante) ou en retire (vente, sortie, retour
  /// fournisseur, distribution sortante) — centralisé ici pour que
  /// [quantiteProduit]/[nombreProduit] et tout futur code de calcul du stock
  /// utilisent exactement la même règle.
  static bool estEntree(String? type, {String? sousType, String? clientCode, String? fournisseurCode}) {
    switch (type) {
      case 'Achat':
        return true;
      case 'Vente':
      case 'Sortie':
        return false;
      case 'Retour':
        // Retour client : la marchandise revient (entrée). Retour
        // fournisseur : elle repart (sortie).
        return clientCode != null;
      case 'Distribution':
        return sousType == 'Entrée';
      case 'Transfert':
        return sousType == 'Entrée';
      default:
        // Type inconnu/futur : ne pas faire disparaître silencieusement la
        // quantité du calcul plutôt que de deviner un sens erroné.
        return true;
    }
  }

  /// Quantité en stock d'un produit calculée à partir du journal des
  /// mouvements (somme des entrées moins les sorties, mouvements annulés
  /// exclus) plutôt que lue depuis un compteur mis en cache — voir la
  /// dérive constatée entre Produit.quantite et produit_magasin_detail qui a
  /// motivé ce calcul.
  ///
  /// [magasinCode] absent : total TOUS magasins confondus, y compris les
  /// mouvements dont magasin_code est encore NULL (créés avant l'ajout de
  /// cette colonne, ou par des flux pas encore magasin-conscients comme
  /// SmartScan/IA) — vue admin.
  /// [magasinCode] fourni : ne compte QUE les mouvements explicitement
  /// attribués à ce magasin (les mouvements à magasin_code NULL sont
  /// exclus, on ne peut pas deviner leur magasin) — la somme par magasin
  /// peut donc être inférieure au total tant que tous les flux n'attribuent
  /// pas encore de magasin.
  static Future<double> quantiteProduit(String codeProduit, {String? magasinCode}) async {
    final db = await DbCreator.openDb();
    final where = StringBuffer('code_produit = ? AND etat = 1');
    final args = <dynamic>[codeProduit];
    if (magasinCode != null) {
      where.write(' AND magasin_code = ?');
      args.add(magasinCode);
    }

    final rows = await db.query('mouvements', where: where.toString(), whereArgs: args);

    double total = 0;
    for (final row in rows) {
      final quantite = (row['quantite'] as num?)?.toDouble() ?? 0;
      final estUneEntree = estEntree(
        row['type'] as String?,
        sousType: row['sous_type'] as String?,
        clientCode: row['client_code'] as String?,
        fournisseurCode: row['fournisseur_code'] as String?,
      );
      total += estUneEntree ? quantite : -quantite;
    }
    return total;
  }

  /// Version "en lot" de [quantiteProduit]/[nombreProduit] : UNE seule
  /// requête sur tout le journal (au lieu d'une par produit) puis agrégation
  /// en mémoire — indispensable pour alimenter un tableau (DataGridSource
  /// est synchrone, il faut la carte déjà calculée avant le rendu) sans
  /// déclencher des centaines de requêtes individuelles.
  static Future<({Map<String, double> quantites, Map<String, double> nombres})> totauxParProduit({
    String? magasinCode,
  }) async {
    final db = await DbCreator.openDb();
    final where = StringBuffer('etat = 1');
    final args = <dynamic>[];
    if (magasinCode != null) {
      where.write(' AND magasin_code = ?');
      args.add(magasinCode);
    }

    final rows = await db.query('mouvements', where: where.toString(), whereArgs: args);

    final quantites = <String, double>{};
    final nombres = <String, double>{};

    for (final row in rows) {
      final codeProduit = row['code_produit'] as String?;
      if (codeProduit == null) continue;

      final estUneEntree = estEntree(
        row['type'] as String?,
        sousType: row['sous_type'] as String?,
        clientCode: row['client_code'] as String?,
        fournisseurCode: row['fournisseur_code'] as String?,
      );

      final quantite = (row['quantite'] as num?)?.toDouble() ?? 0;
      quantites[codeProduit] = (quantites[codeProduit] ?? 0) + (estUneEntree ? quantite : -quantite);

      final nombre = row['nombre'] as num?;
      if (nombre != null) {
        nombres[codeProduit] = (nombres[codeProduit] ?? 0) + (estUneEntree ? nombre.toDouble() : -nombre.toDouble());
      }
    }

    return (quantites: quantites, nombres: nombres);
  }

  /// Même calcul que [quantiteProduit], pour le second stock parallèle
  /// "nombre" (Paramètres > Nombre et Quantité, voir Produit.nombre).
  static Future<double> nombreProduit(String codeProduit, {String? magasinCode}) async {
    final db = await DbCreator.openDb();
    final where = StringBuffer('code_produit = ? AND etat = 1 AND nombre IS NOT NULL');
    final args = <dynamic>[codeProduit];
    if (magasinCode != null) {
      where.write(' AND magasin_code = ?');
      args.add(magasinCode);
    }

    final rows = await db.query('mouvements', where: where.toString(), whereArgs: args);

    double total = 0;
    for (final row in rows) {
      final nombre = (row['nombre'] as num?)?.toDouble() ?? 0;
      final estUneEntree = estEntree(
        row['type'] as String?,
        sousType: row['sous_type'] as String?,
        clientCode: row['client_code'] as String?,
        fournisseurCode: row['fournisseur_code'] as String?,
      );
      total += estUneEntree ? nombre : -nombre;
    }
    return total;
  }

  // ── Multi-magasin ────────────────────────────────────────────────────────

  /// Stock d'un produit dans chaque magasin (journal des mouvements), limité
  /// à [magasins] si fourni. Sert à répartir une vente / une sortie
  /// (RepartitionStock) et à la distribution.
  static Future<Map<String, double>> quantitesParMagasin(String codeProduit, {Iterable<String>? magasins}) async {
    final db = await DbCreator.openDb();
    final where = StringBuffer('code_produit = ? AND etat = 1 AND magasin_code IS NOT NULL');
    final args = <dynamic>[codeProduit];
    final liste = magasins?.toList();
    if (liste != null) {
      if (liste.isEmpty) return {};
      where.write(' AND magasin_code IN (${List.filled(liste.length, '?').join(',')})');
      args.addAll(liste);
    }
    final rows = await db.query('mouvements', where: where.toString(), whereArgs: args);
    final resultat = <String, double>{};
    for (final row in rows) {
      final magasin = row['magasin_code'] as String;
      final quantite = (row['quantite'] as num?)?.toDouble() ?? 0;
      final entree = estEntree(
        row['type'] as String?,
        sousType: row['sous_type'] as String?,
        clientCode: row['client_code'] as String?,
        fournisseurCode: row['fournisseur_code'] as String?,
      );
      resultat[magasin] = (resultat[magasin] ?? 0) + (entree ? quantite : -quantite);
    }
    return resultat;
  }

  /// Comme [totauxParProduit], mais sommé sur un ENSEMBLE de magasins (les
  /// magasins consultables par l'utilisateur) — stock affiché dans Produit,
  /// Stock et la caisse.
  static Future<({Map<String, double> quantites, Map<String, double> nombres})> totauxParProduitPourMagasins(
    Iterable<String> magasins,
  ) async {
    final liste = magasins.toList();
    final quantites = <String, double>{};
    final nombres = <String, double>{};
    if (liste.isEmpty) return (quantites: quantites, nombres: nombres);

    final db = await DbCreator.openDb();
    final rows = await db.query(
      'mouvements',
      where: 'etat = 1 AND magasin_code IN (${List.filled(liste.length, '?').join(',')})',
      whereArgs: liste,
    );
    for (final row in rows) {
      final codeProduit = row['code_produit'] as String?;
      if (codeProduit == null) continue;
      final entree = estEntree(
        row['type'] as String?,
        sousType: row['sous_type'] as String?,
        clientCode: row['client_code'] as String?,
        fournisseurCode: row['fournisseur_code'] as String?,
      );
      final quantite = (row['quantite'] as num?)?.toDouble() ?? 0;
      quantites[codeProduit] = (quantites[codeProduit] ?? 0) + (entree ? quantite : -quantite);
      final nombre = row['nombre'] as num?;
      if (nombre != null) {
        nombres[codeProduit] = (nombres[codeProduit] ?? 0) + (entree ? nombre.toDouble() : -nombre.toDouble());
      }
    }
    return (quantites: quantites, nombres: nombres);
  }

  /// Stock affiché selon le filtre magasin d'un écran : un magasin précis
  /// ([magasinCode]) ou, à défaut, la somme des magasins consultables par
  /// l'utilisateur ([magasinsConsultation], voir AuthState).
  static Future<({Map<String, double> quantites, Map<String, double> nombres})> totauxPourFiltre({
    String? magasinCode,
    required List<String> magasinsConsultation,
  }) {
    return magasinCode != null
        ? totauxParProduit(magasinCode: magasinCode)
        : totauxParProduitPourMagasins(magasinsConsultation);
  }

  /// Répartition d'une SORTIE de stock entre les magasins de l'utilisateur
  /// ([magasins], principal en tête), selon le stock actuel de chacun :
  /// - vente (panier) : séquentielle (magasin 1, puis 2…) ;
  /// - retour fournisseur / sortie ([unSeulMagasinSiPossible]) : un magasin
  ///   qui a toute la quantité, sinon répartie dans l'ordre.
  /// Voir RepartitionStock. Une part = un mouvement à créer.
  static Future<List<PartMagasin>> repartirSortie(
    String codeProduit,
    double quantite,
    List<String> magasins, {
    bool unSeulMagasinSiPossible = false,
  }) async {
    final disponible = await quantitesParMagasin(codeProduit, magasins: magasins);
    return unSeulMagasinSiPossible
        ? RepartitionStock.unMagasinSinonSequentielle(quantite, magasins, disponible)
        : RepartitionStock.sequentielle(quantite, magasins, disponible);
  }

  /// Retour client d'un produit vendu dans le panier [codePannier] :
  /// répartition vers les magasins d'où la vente est sortie (le dernier servi
  /// d'abord), déduction faite des retours déjà enregistrés sur ce panier
  /// pour ce produit. Vide si le panier n'a aucun mouvement de ce produit.
  static Future<List<PartMagasin>> repartirRetourClient(String codePannier, String codeProduit, double quantite) async {
    final db = await DbCreator.openDb();
    final sorties = (await db.query(
      'mouvements',
      where: 'code_operation = ? AND code_produit = ? AND etat = 1 AND magasin_code IS NOT NULL',
      whereArgs: [codePannier, codeProduit],
      orderBy: 'id',
    ))
        .map((m) => PartMagasin(m['magasin_code'] as String, (m['quantite'] as num?)?.toDouble() ?? 0))
        .toList();
    if (sorties.isEmpty) return const [];

    // Déjà rendu par les retours précédents de ce panier (mouvements actifs).
    final dejaRetourne = <String, double>{};
    final rows = await db.rawQuery('''
      SELECT m.magasin_code, SUM(m.quantite) AS q
      FROM mouvements m
      JOIN retours r ON r.code = m.code_operation
      WHERE r.retour_correspond_de = ? AND m.code_produit = ? AND m.etat = 1 AND r.etat = 1
        AND m.magasin_code IS NOT NULL
      GROUP BY m.magasin_code
    ''', [codePannier, codeProduit]);
    for (final r in rows) {
      dejaRetourne[r['magasin_code'] as String] = (r['q'] as num?)?.toDouble() ?? 0;
    }
    return RepartitionStock.retourVersOrigine(quantite, sorties, dejaRetourne: dejaRetourne);
  }
}
