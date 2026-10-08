import 'package:caisse_dz/DBCreate.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Magasins d'un utilisateur (multi-magasin, licence Avancée).
///
/// Chaque utilisateur a une liste ORDONNÉE de magasins : le premier est son
/// magasin principal (alimenté par Entrée / Smart Scan, premier servi à la
/// vente), les suivants sont utilisés dans l'ordre quand le stock manque
/// (voir RepartitionStock). Un Admin a accès à tous les magasins actifs : les
/// siens d'abord, dans leur ordre, puis les autres.
class UtilisateurMagasinServices {
  /// Codes des magasins de l'utilisateur, dans l'ordre (principal en tête).
  /// Jamais vide : à défaut de configuration, le magasin par défaut.
  static Future<List<String>> magasinsUtilisateur(String userCode, {required bool estAdmin}) async {
    final db = await DbCreator.openDb();
    final propres = (await db.query(
      'utilisateur_magasin um JOIN magasins m ON m.code = um.magasin_code',
      columns: ['um.magasin_code AS code'],
      where: 'um.utilisateur_code = ? AND m.etat = 1',
      whereArgs: [userCode],
      orderBy: 'um.ordre',
    ))
        .map((r) => r['code'] as String)
        .toList();

    if (estAdmin) {
      final tous = (await db.query('magasins', columns: ['code'], where: 'etat = 1', orderBy: 'id'))
          .map((r) => r['code'] as String);
      return [...propres, ...tous.where((m) => !propres.contains(m))];
    }
    return propres.isNotEmpty ? propres : ['MAG0000'];
  }

  /// Magasins configurés pour l'utilisateur (écran Utilisateur), dans
  /// l'ordre — sans l'extension « tous les magasins » des Admin ni le
  /// magasin par défaut. Peut être vide.
  static Future<List<String>> magasinsConfigures(String userCode) async {
    final db = await DbCreator.openDb();
    return (await db.query(
      'utilisateur_magasin',
      columns: ['magasin_code'],
      where: 'utilisateur_code = ?',
      whereArgs: [userCode],
      orderBy: 'ordre',
    ))
        .map((r) => r['magasin_code'] as String)
        .toList();
  }

  /// Remplace les magasins de l'utilisateur par [magasins] (dans l'ordre :
  /// le premier devient le principal). Dans la transaction [txn] si fournie.
  static Future<void> definirMagasins(String userCode, List<String> magasins, {DatabaseExecutor? txn}) async {
    final db = txn ?? await DbCreator.openDb();
    final now = DateTime.now().toIso8601String();
    await db.delete('utilisateur_magasin', where: 'utilisateur_code = ?', whereArgs: [userCode]);
    final uniques = <String>[];
    for (final m in magasins) {
      if (!uniques.contains(m)) uniques.add(m);
    }
    for (var i = 0; i < uniques.length; i++) {
      await db.insert('utilisateur_magasin', {
        'utilisateur_code': userCode,
        'magasin_code': uniques[i],
        'ordre': i,
        'date_cree': now,
      });
    }
  }
}
