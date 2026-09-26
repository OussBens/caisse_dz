import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/data/models/paramters.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class ParamServices {

  final Database db;

  ParamServices(this.db);

  //---Modifi---

  Future<int> updateParam(Paramters param) async {
    return await db.update(

      'parametre',

      param.toMap(),

      where: 'id = ?',

      whereArgs: [param.id],

    );
  }

  //---Get Paramters---

  static Future<Paramters> getParam() async {
    final db = await DbCreator.openDb();
    return getParamWithTransaction(db);
  }

  /// Même lecture que [getParam], mais sur l'executor fourni (transaction en
  /// cours) au lieu de rouvrir la connexion partagée via DbCreator.openDb().
  /// Indispensable pour tout appelant déjà à l'intérieur d'un
  /// db.transaction(...) : rappeler DbCreator.openDb() y renverrait la même
  /// connexion (mise en cache) déjà verrouillée par cette transaction, et
  /// db.query() dessus attendrait indéfiniment la fin de... cette même
  /// transaction — interblocage (voir PannierServices._accruerBonus).
  static Future<Paramters> getParamWithTransaction(DatabaseExecutor executor) async {
    final result = await executor.query('parametre');

    if (result.isEmpty) {
      return Paramters(
        id: 1,
        typeMarge: "Montant",
        TauxMargePerncetage: 0,
        TauxMargeMontant: 0,
        Maximum: 0,
        Minimum: 0,
        activeBonus: false,
        bonusTaux: 0,
        activeNombreQuantite: false,
        Datecree: DateTime.now(),
        creeParCode: '',
      );
    }
    return Paramters.fromMap(result.first);
  }


}