import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Role.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

class MagasinServices {
  final Database db;

  MagasinServices(this.db);

  static Future<List<Magasin>> getAllMagasins() async {
    final db = await DbCreator.openDb();
    final List<Map<String, dynamic>> result = await db.query('magasins', orderBy: 'nom ASC');
    return result.map((e) => Magasin.fromMap(e)).toList();
  }

  /// Code -> nom de TOUS les magasins (actifs ou non) : affichage du magasin
  /// d'un mouvement (tableaux, détails, exports) via [nomMagasin].
  static Map<String, String> nomsParCode(Iterable<Magasin> magasins) => {for (final m in magasins) m.code: m.nom};

  static Future<Map<String, String>> getNomsMagasins() async => nomsParCode(await getAllMagasins());

  /// Nom affiché pour [code] : son nom, à défaut le code, '-' si aucun magasin.
  static String nomMagasin(Map<String, String> noms, String? code) => code == null ? '-' : noms[code] ?? code;

  /// Chiffres clés affichés en haut du détail magasin : produits ayant du
  /// stock dans ce magasin et leur valeur au prix d'achat (stock calculé
  /// depuis le journal des mouvements, comme Produit/Stock), utilisateurs
  /// actifs qui travaillent sur ce magasin (utilisateur_magasin + Admin — une caisse
  /// n'a plus de magasin depuis le multi-magasin, DB v52) et transferts
  /// actifs (entrants ou sortants).
  static Future<({int produitsEnStock, double valeurStock, int utilisateurs, int transferts})> getStatistiquesMagasin(
    String magasinCode,
  ) async {
    final db = await DbCreator.openDb();
    final totaux = await MouvementsServices.totauxParProduit(magasinCode: magasinCode);

    final prixRows = await db.query('produits', columns: ['code', 'prix_achat']);
    final prixAchat = {
      for (final r in prixRows) r['code'] as String: (r['prix_achat'] as num?)?.toDouble() ?? 0,
    };

    var produitsEnStock = 0;
    var valeurStock = 0.0;
    totaux.quantites.forEach((code, quantite) {
      if (quantite <= 0) return;
      produitsEnStock++;
      valeurStock += quantite * (prixAchat[code] ?? 0);
    });

    Future<int> compter(String sql, List<Object?> args) async {
      final rows = await db.rawQuery(sql, args);
      return (rows.first['n'] as num?)?.toInt() ?? 0;
    }

    // Utilisateurs actifs qui ont ce magasin dans leur liste, plus les Admin
    // (qui travaillent implicitement sur tous les magasins actifs, voir
    // UtilisateurMagasinServices.magasinsUtilisateur).
    final utilisateurs = await compter('''
      SELECT COUNT(*) AS n FROM utilisateur u
      WHERE u.etat = 1 AND (
        EXISTS (SELECT 1 FROM utilisateur_magasin um WHERE um.utilisateur_code = u.code AND um.magasin_code = ?)
        OR (${RoleServices.sqlEstAdmin('u.role')} AND EXISTS (SELECT 1 FROM magasins m WHERE m.code = ? AND m.etat = 1))
      )
    ''', [magasinCode, magasinCode]);
    final transferts = await compter(
      'SELECT COUNT(*) AS n FROM transfert_magasin WHERE etat = 1 AND (magasin_source_code = ? OR magasin_dest_code = ?)',
      [magasinCode, magasinCode],
    );

    return (produitsEnStock: produitsEnStock, valeurStock: valeurStock, utilisateurs: utilisateurs, transferts: transferts);
  }

  /// Retourne le magasin (autre que [excludeMagasinCode]) portant déjà ce nom
  /// (comparaison insensible à la casse et aux espaces) — null si le nom
  /// est libre.
  static Future<Magasin?> findMagasinByNom(String nom, {String? excludeMagasinCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'magasins',
      where: 'LOWER(TRIM(nom)) = ?',
      whereArgs: [nom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final magasin = Magasin.fromMap(maps.first);
    if (magasin.code == excludeMagasinCode) return null;
    return magasin;
  }

  Future<Magasin?> getMagasinById(int id) async {
    final maps = await db.query('magasins', where: 'id = ?', whereArgs: [id]);
    if (maps.isNotEmpty) return Magasin.fromMap(maps.first);
    return null;
  }

  Future<ApiResponse<int>> addMagasin(Magasin magasin) async {
    try {
      final existing = await db.query(
        'magasins',
        where: 'LOWER(TRIM(nom)) = ?',
        whereArgs: [magasin.nom.trim().toLowerCase()],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un magasin avec ce nom existe deja",
        );
      }

      final id = await db.insert(
        'magasins',
        magasin.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(
        success: true,
        message: "Magasin ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  Future<ApiResponse<int>> updateMagasin(Magasin magasin) async {
    try {
      final data = magasin.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'magasins',
        data,
        where: 'id = ?',
        whereArgs: [magasin.id],
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
          message: "Un magasin avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteMagasin(int id) async {
    return await db.delete('magasins', where: 'id = ?', whereArgs: [id]);
  }

  static Future<int> getNextMagasinId(DatabaseExecutor db) async {
    final result = await db.rawQuery('SELECT MAX(id) AS maxId FROM magasins');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
}
