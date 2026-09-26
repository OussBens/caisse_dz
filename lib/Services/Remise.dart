import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RemiseServices{

  final Database db;

  RemiseServices(this.db);

  static Future<int> getNextremiseId (DatabaseExecutor db) async {

    final result = await db.rawQuery( 'SELECT MAX(id) AS maxId FROM remises',);

    final maxId = result.first['maxId'] as int?;

    return (maxId ?? 0) + 1;

  }

  Future<List<Remise>> getRemisesByType(String type) async {
    final remisesData = await db.query('remises', where: 'type = ?', whereArgs: [type]);
    return remisesData.map((e) => Remise.fromMap(e)).toList();
  }

  Future<int> addRemise(Remise remise) async {

    try {
      // ✅ Check if a pack with the same name already exists
      final existing = await db.query(
        'remises',
        where: 'nom = ?',
        whereArgs: [remise.nom],
      );

      if (existing.isNotEmpty) {
        return 0;
      }

      final id = await db.insert(
        'remises',
        remise.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return id;
    } catch (e) {
      print(e);
      return 2001;
    }

  }

  static Future<List<Remise>> getAllRemise() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('remises' , orderBy: 'nom ASC',);

    return result.map((e) => Remise.fromMap(e)).toList();

  }

  /// Recale le statut actif/inactif de chaque remise sur sa période
  /// [debut, fin] (actif si la date du jour y est incluse, inactif sinon) et
  /// persiste les changements en base. Appelé à chaque ouverture de l'écran
  /// Remise pour que le statut reste toujours à jour, même sans action
  /// manuelle de l'utilisateur (remise qui démarre ou expire simplement en
  /// laissant le temps passer).
  static Future<List<Remise>> synchroniserEtatsSelonDates() async {
    final db = await DbCreator.openDb();
    final remises = await getAllRemise();

    for (final remise in remises) {
      final etatAttendu = remise.estActifSelonDates;
      if (remise.etat != etatAttendu) {
        await db.update(
          'remises',
          {'etat': etatAttendu ? 1 : 0},
          where: 'id = ?',
          whereArgs: [remise.id],
        );
        remise.etat = etatAttendu;
      }
    }

    return remises;
  }

  static Future<List<Remise>> getAllRemiseParProduit() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('remises', where: 'type = ?', whereArgs: ['Par Produit'],);

    return result.map((e) => Remise.fromMap(e)).toList();

  }

  Future<Remise?> getRemiseById(int id) async {

    final maps = await db.query('remises' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Remise.fromMap(maps.first);

    }

    return null;

  }

  static Future<Remise?> getRemiseByCode(String code) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'remises',
      where: 'code = ?',
      whereArgs: [code],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return Remise.fromMap(maps.first);
    }
    return null;
  }

  Future<int> updateRemise (Remise remise) async {
    final data = remise.toMap();

    data.remove('id');
    data.remove('code');

    return await db.update(
      'remises',
      data,
      where:'id = ?',
      whereArgs: [remise.id],
    );
  }

  static Future<int> deleteRemise (Remise remise) async {
    final db = await DbCreator.openDb();
    return await db.delete(

      'remises',

      where: 'id = ?',

      whereArgs: [remise.id],

    );
  }
}