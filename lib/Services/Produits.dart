import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:intl/intl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';
import '../data/constant.dart';
import '../data/models/produit_code_detail.dart';
import 'Mouvement.dart';
import 'Paramters.dart';
import 'Photos.dart';

/// Statistiques de stock calculées en direct pour un produit
/// (entrées, smart scans, ventes, retours) — aucune valeur n'est
/// mise en cache sur le produit lui-même.
class ProduitStats {
  final double quantiteDernierAchat;
  final DateTime? dateDernierAchat;
  final double totalAchat;
  final double totalVendu;
  final double totalRetourClient;
  final double totalRetourFournisseur;
  final bool besoin;
  final String besoinStatus;

  ProduitStats({
    required this.quantiteDernierAchat,
    required this.dateDernierAchat,
    required this.totalAchat,
    required this.totalVendu,
    required this.totalRetourClient,
    required this.totalRetourFournisseur,
    required this.besoin,
    required this.besoinStatus,
  });
}

class ProduitServices{

  final Database db;

  ProduitServices(this.db);

  static Future<List<Produit>> getAllProduits() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('produits', orderBy: 'nom ASC',);
    if (result.isNotEmpty) {
      print('Colonnes disponibles : ${result.first.keys}');
    }
    return result.map((e) => Produit.fromMap(e)).toList();

  }
// Ajoutez ces méthodes dans ProduitServices.dart

  // ✅ Méthode avec transaction pour updateProduit
  Future<ApiResponse<int>> updateProduitWithTransaction(Transaction txn, Produit produit) async {
    try {
      final data = produit.toMap()
        ..remove('id')
        ..remove('code')
        ..['date_modif'] = DateTime.now().toIso8601String();

      final rows = await txn.update(
        'produits',
        data,
        where: 'id = ?',
        whereArgs: [produit.id],
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
          message: "Un produit avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  // ✅ Méthode avec transaction pour getAllProduits
  static Future<List<Produit>> getAllProduitsWithTransaction(Transaction txn) async {
    final List<Map<String, dynamic>> result = await txn.query('produits', orderBy: 'nom ASC');
    return result.map((e) => Produit.fromMap(e)).toList();
  }
  static Future<int> getNextId(DatabaseExecutor db) async {
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM produit_code_detail',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }
// Services/Produits.dart - Ajoutez cette méthode
  Future<void> deleteProductWithPhotos(Produit produit) async {
    final db = await DbCreator.openDb();

    await db.transaction((txn) async {
      // Supprimer le produit
      await txn.delete(
        'produits',
        where: 'code = ?',
        whereArgs: [produit.code],
      );

      // Supprimer les photos physiquement
      await PhotoService.deletePhoto(produit.photo);

      // Supprimer les relations
      await txn.delete(
        'produit_magasin_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );

      await txn.delete(
        'produit_pack_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );

      await txn.delete(
        'produit_code_detail',
        where: 'produit_code = ?',
        whereArgs: [produit.code],
      );
    });
  }
  Future<void> deleteDetailes(String produitCode,String codebar) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_code_detail',
      where: 'produit_code = ? AND codebar = ?',
      whereArgs: [produitCode,codebar],
    );
  }

  /// Retrouve le code d'un produit à partir d'un code-barre scanné, en
  /// vérifiant le code-barre principal (produits.code_barre) puis les
  /// codes-barres secondaires (produit_code_detail). Retourne null si aucun
  /// produit ne correspond.
  static Future<String?> getProduitCodeByBarcode(String codebar) async {
    final db = await DbCreator.openDb();

    final produitMatch = await db.query(
      'produits',
      where: 'code_barre = ?',
      whereArgs: [codebar],
      limit: 1,
    );
    if (produitMatch.isNotEmpty) {
      return produitMatch.first['code'] as String?;
    }

    final detailMatch = await db.query(
      'produit_code_detail',
      where: 'codebar = ?',
      whereArgs: [codebar],
      limit: 1,
    );
    if (detailMatch.isNotEmpty) {
      return detailMatch.first['produit_code'] as String?;
    }

    return null;
  }

  /// Retourne le produit (autre que [excludeProduitCode]) qui utilise déjà ce
  /// code-barre, comme code-barre principal (produits.code_barre) ou
  /// secondaire (produit_code_detail) — null si le code-barre est libre.
  /// Sert à garantir l'unicité du code-barre lors de la création/modification
  /// d'un produit, sur les deux tables.
  static Future<Produit?> findProduitUsingBarcode(String codebar, {String? excludeProduitCode}) async {
    final code = await getProduitCodeByBarcode(codebar);
    if (code == null || code == excludeProduitCode) return null;

    final db = await DbCreator.openDb();
    final maps = await db.query('produits', where: 'code = ?', whereArgs: [code], limit: 1);
    if (maps.isEmpty) return null;
    return Produit.fromMap(maps.first);
  }

  /// Retourne le produit (autre que [excludeProduitCode]) portant déjà ce
  /// nom (comparaison insensible à la casse et aux espaces) — null si le
  /// nom est libre. Sert à empêcher la création/modification d'un produit
  /// avec un nom déjà utilisé.
  static Future<Produit?> findProduitByNom(String nom, {String? excludeProduitCode}) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'produits',
      where: 'LOWER(TRIM(nom)) = ?',
      whereArgs: [nom.trim().toLowerCase()],
      limit: 1,
    );
    if (maps.isEmpty) return null;
    final produit = Produit.fromMap(maps.first);
    if (produit.code == excludeProduitCode) return null;
    return produit;
  }

  static Future<List<ProduitCodeDetail>> getAllCodeDetailsByCode(String code) async {

    final db = await DbCreator.openDb();

    final maps = await db.query(
      'produit_code_detail',
      where: 'produit_code = ?',
      whereArgs: [code],
    );

    return maps.map((e) => ProduitCodeDetail.fromMap(e)).toList();
  }

  /// Retourne tous les codes-barres secondaires (produit_code_detail) de tous
  /// les produits, pour les écrans qui doivent chercher un produit à
  /// plusieurs codes-barres sans requêter la base à chaque frappe.
  static Future<List<ProduitCodeDetail>> getAllCodeDetails() async {
    final db = await DbCreator.openDb();
    final maps = await db.query('produit_code_detail');
    return maps.map((e) => ProduitCodeDetail.fromMap(e)).toList();
  }

  /// Génère un code barre auto (format CAISSEDZ + date du jour + séquence 0001)
  /// pour les produits qui n'ont pas de code barre physique.
  /// La séquence redémarre à 0001 chaque jour.
  static Future<String> generateAutoBarcode() async {
    final db = await DbCreator.openDb();
    final datePart = DateFormat('yyyyMMdd').format(DateTime.now());
    final prefix = '${CodePrefix.barcode}$datePart';

    int extractSeq(String? code) {
      if (code == null || code.length <= prefix.length || !code.startsWith(prefix)) {
        return 0;
      }
      return int.tryParse(code.substring(prefix.length)) ?? 0;
    }

    final produitsMatches = await db.query(
      'produits',
      where: 'code_barre LIKE ?',
      whereArgs: ['$prefix%'],
    );
    final detailsMatches = await db.query(
      'produit_code_detail',
      where: 'codebar LIKE ?',
      whereArgs: ['$prefix%'],
    );

    int maxSeq = 0;
    for (final row in produitsMatches) {
      maxSeq = maxSeq > extractSeq(row['code_barre'] as String?) ? maxSeq : extractSeq(row['code_barre'] as String?);
    }
    for (final row in detailsMatches) {
      maxSeq = maxSeq > extractSeq(row['codebar'] as String?) ? maxSeq : extractSeq(row['codebar'] as String?);
    }

    final nextSeq = (maxSeq + 1).toString().padLeft(4, '0');
    return '$prefix$nextSeq';
  }

  Future<void> deleteAllProduitCodeDetailes(String produitCode) async {
    final db = await DbCreator.openDb();

    await db.delete(
      'produit_code_detail',
      where: 'produit_code = ?',
      whereArgs: [produitCode],
    );
  }



  // Dans ProduitServices.dart
  // Dans ProduitServices.dart
  Future<int> addProduitCodeDetail(ProduitCodeDetail detail) async {
    try {
      print('📝 addProduitCodeDetail - Début');

      // ✅ Vérifier que la table existe
      final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='produit_code_detail'"
      );

      if (tables.isEmpty) {
        print('⚠️ Table produit_code_detail manquante - Création...');
        await db.execute('''
        CREATE TABLE produit_code_detail (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          codebar TEXT NOT NULL,
          produit_code TEXT NOT NULL,
          date_cree TEXT NOT NULL,
          cree_par_code TEXT NOT NULL
        )
      ''');
        print('✅ Table produit_code_detail créée');
      }

      // ✅ Obtenir le prochain ID SANS transaction
      final idResult = await db.rawQuery(
          'SELECT MAX(id) AS maxId FROM produit_code_detail'
      );
      final maxId = idResult.first['maxId'] as int?;
      final nextId = (maxId ?? 0) + 1;
      detail.id = nextId;

      // ✅ Préparer les données
      final data = detail.toMap();
      data['id'] = detail.id;

      print('📝 Insertion dans produit_code_detail: $data');

      // ✅ Insertion DIRECTE sans transaction
      final insertResult = await db.insert(
        'produit_code_detail',
        data,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      print('✅ Insertion réussie: $insertResult');
      return insertResult > 0 ? detail.id : 0;

    } catch (e, stack) {
      print('❌ addProduitCodeDetail ERROR: $e');
      print(stack);
      return 0;
    }
  }// Dans ProduitServices.dart - Corriger la méthode addProduitWithSystemMagasin
  Future<ApiResponse<int>> addProduitWithSystemMagasin(Produit produit, String systemMagasinNom) async {
    try {
      return await db.transaction((txn) async {
        // 1. Insérer le produit
        final insertData = produit.toMap();
        insertData['id'] = produit.id;
        final result = await txn.insert('produits', insertData);

        if (result == 0) {
          return ApiResponse(success: false, message: "Erreur lors de l'insertion du produit");
        }

        // 2. Récupérer le magasin "System"
        final magasinResult = await txn.query(
          'magasins',
          where: 'nom = ?',
          whereArgs: [systemMagasinNom],
        );

        if (magasinResult.isEmpty) {
          // Créer le magasin System s'il n'existe pas
          final systemMagasinId = await _getNextMagasinId(txn);
          final systemMagasin = {
            'id': systemMagasinId,
            'nom': systemMagasinNom,
            'code': 'SYS${systemMagasinId.toString().padLeft(6, '0')}',
            'etat': 1,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('magasins', systemMagasin);

          // 3. Créer la relation produit_magasin_detail
          final detailId = await _getNextMagasinDetailId(txn);
          final detail = {
            'id': detailId,
            'magasin_code': systemMagasin['code'],
            'produit_code': produit.code,
            'quantite': 0,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('produit_magasin_detail', detail);
        } else {
          final magasin = magasinResult.first;

          // 3. Créer la relation produit_magasin_detail
          final detailId = await _getNextMagasinDetailId(txn);
          final detail = {
            'id': detailId,
            'magasin_code': magasin['code'],
            'produit_code': produit.code,
            'quantite': 0,
            'date_cree': DateTime.now().toIso8601String(),
            'cree_par_code': produit.creeParcode,
          };
          await txn.insert('produit_magasin_detail', detail);
        }

        return ApiResponse(success: true, message: "Produit ajouté avec succès", data: produit.id);
      });
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur: $e");
    }
  }

  Future<int> _getNextMagasinId(DatabaseExecutor txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM magasins');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  Future<int> _getNextMagasinDetailId(DatabaseExecutor txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM produit_magasin_detail');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


  Future<List<Produit>> getProduitsByRemiseId(int remiseId) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'remise_id = ?' , whereArgs: [remiseId],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }

  Future<List<Produit>> getProduitsByCategorieId(int categorieId) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'categorie_id = ?' , whereArgs: [categorieId],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }
  Future<List<Produit>> getProduitsBySousCategorieId(int sousCategorieId) async {

    final List<Map<String, dynamic>> result = await db.query('produits' , where: 'sous_categorie_id = ?' , whereArgs: [sousCategorieId],);

    return result.map((e) => Produit.fromMap(e)).toList();

  }

  Future<Produit?> getProduitById(int id) async {

    final maps = await db.query('produits' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Produit.fromMap(maps.first);

    }

    return null;

  } Future<Produit?> getProduitByCode(String id) async {

    final maps = await db.query('produits' , where: 'code = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Produit.fromMap(maps.first);

    }

    return null;

  }

  Future<ApiResponse<int>> updateProduit(Produit produit) async{
    try{

      final data = produit.toMap()
          ..remove('id')
          ..remove('code')
          ..['date_modif'] = DateTime.now().toIso8601String();

      final rows = await db.update(
        'produits',
        data,
        where: 'id = ?',
        whereArgs: [produit.id],
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
          message : "Un produit avec ce nom existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  Future<int> deleteProduitt(int id) async {

    return await db.delete(
      'produits',

      where: 'id = ?',

      whereArgs: [id],

    );

  }

  // Dans ProduitServices.dart
  Future<ApiResponse<int>> addProduit(Produit produit) async {
    try {
      final id = await db.insert(
        'produits',
        produit.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return ApiResponse(success: true, message: "Produit ajouté avec succès", data: id);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur ajout: ${e.toString()}");
    }
  }


  static Future<int> getNextProduitId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM produits',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Prix moyen d'achat par produit = somme(prix * quantité) / somme(quantité)
  /// sur toutes les lignes SmartScan (achats fournisseur) actives, groupées
  /// par produit. Retourne une map code_produit -> prix moyen (0 si aucun achat).
  static Future<Map<String, double>> getPrixMoyenAchatParProduit() async {
    final db = await DbCreator.openDb();
    final rows = await db.rawQuery('''
      SELECT code_produit AS codeProduit,
             SUM(prix * quantite) AS montant,
             SUM(quantite) AS qte
      FROM smartScanProduit
      WHERE etat = 1
      GROUP BY code_produit
    ''');

    final Map<String, double> resultat = {};
    for (final row in rows) {
      final qte = (row['qte'] as num?)?.toDouble() ?? 0;
      final montant = (row['montant'] as num?)?.toDouble() ?? 0;
      resultat[row['codeProduit'] as String] = qte > 0 ? montant / qte : 0;
    }
    return resultat;
  }

  /// Prix moyen de vente par produit = somme(prix * quantité) / somme(quantité)
  /// sur toutes les lignes de pannier (ventes) actives, groupées par produit.
  /// Retourne une map code_produit -> prix moyen (0 si aucune vente).
  static Future<Map<String, double>> getPrixMoyenVenteParProduit() async {
    final db = await DbCreator.openDb();
    final rows = await db.rawQuery('''
      SELECT code_produit AS codeProduit,
             SUM(prix * quantite) AS montant,
             SUM(quantite) AS qte
      FROM pannierProduit
      WHERE etat = 1
      GROUP BY code_produit
    ''');

    final Map<String, double> resultat = {};
    for (final row in rows) {
      final qte = (row['qte'] as num?)?.toDouble() ?? 0;
      final montant = (row['montant'] as num?)?.toDouble() ?? 0;
      resultat[row['codeProduit'] as String] = qte > 0 ? montant / qte : 0;
    }
    return resultat;
  }

  /// Calcule en direct les statistiques de mouvement d'un produit
  /// (dernier achat, totaux achat/vente/retours, besoin) à partir
  /// des tables smartScanProduit, pannierProduit et retours.
  static Future<ProduitStats> getProduitStats(Produit produit) async {
    final db = await DbCreator.openDb();

    final scans = await db.query(
      'smartScanProduit',
      where: 'code_produit = ? AND etat = 1',
      whereArgs: [produit.code],
    );
    final paniers = await db.query(
      'pannierProduit',
      where: 'code_produit = ? AND etat = 1',
      whereArgs: [produit.code],
    );
    final retoursClient = await db.query(
      'retours',
      where: 'code_produit = ? AND etat = 1 AND type = ?',
      whereArgs: [produit.code, 'Client'],
    );
    final retoursFournisseur = await db.query(
      'retours',
      where: 'code_produit = ? AND etat = 1 AND type = ?',
      whereArgs: [produit.code, 'Fournisseur'],
    );
    final besoinDetails = await db.query(
      'besion_list_detail',
      where: 'produit_code = ?',
      whereArgs: [produit.code],
      orderBy: 'date_cree DESC',
      limit: 1,
    );

    double _sumQuantite(List<Map<String, dynamic>> rows) =>
        rows.fold(0.0, (sum, r) => sum + (r['quantite'] as num).toDouble());

    DateTime? dateDernierAchat;
    double quantiteDernierAchat = 0;
    for (final e in scans) {
      final date = DateTime.parse(e['date_cree'] as String);
      if (dateDernierAchat == null || date.isAfter(dateDernierAchat)) {
        dateDernierAchat = date;
        quantiteDernierAchat = (e['quantite'] as num).toDouble();
      }
    }

    final param = await ParamServices.getParam();
    final quantiteActuelle = await MouvementsServices.quantiteProduit(produit.code);
    final bool besoin = quantiteActuelle < param.Minimum;

    String besoinStatus;
    if (!besoin) {
      besoinStatus = ListsConst.typeBesionproduit[2]; // "Disponible"
    } else if (besoinDetails.isEmpty || dateDernierAchat == null) {
      besoinStatus = ListsConst.typeBesionproduit[0]; // "En Attente"
    } else {
      final besoinDate = DateTime.parse(besoinDetails.first['date_cree'] as String);
      besoinStatus = dateDernierAchat.isBefore(besoinDate)
          ? ListsConst.typeBesionproduit[1] // "Commande"
          : ListsConst.typeBesionproduit[0]; // "En Attente"
    }

    return ProduitStats(
      quantiteDernierAchat: quantiteDernierAchat,
      dateDernierAchat: dateDernierAchat,
      totalAchat: _sumQuantite(scans),
      totalVendu: _sumQuantite(paniers),
      totalRetourClient: _sumQuantite(retoursClient),
      totalRetourFournisseur: _sumQuantite(retoursFournisseur),
      besoin: besoin,
      besoinStatus: besoinStatus,
    );
  }

}