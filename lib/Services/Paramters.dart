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
    final result = await db.query('parametre');

    if (result.isEmpty) {
      return Paramters(
        id: 1,
        typeMarge: "Montant",
        TauxMargePerncetage: 0,
        TauxMargeMontant: 0,
        Maximum: 0,
        Minimum: 0,
        creePar: '',
        Datecree: DateTime.now(),
        creeParCode: '',
      );
    }
    return Paramters.fromMap(result.first);
  }


}