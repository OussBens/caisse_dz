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