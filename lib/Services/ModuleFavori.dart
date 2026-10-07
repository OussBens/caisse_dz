import 'package:caisse_dz/DBCreate.dart';

/// Modules favoris d'un utilisateur (table `module_favori`) : routes des
/// modules épinglés en onglets en haut de l'écran (voir AppShell /
/// AuthState.favoris). La limite (AuthState.maxFavoris) est contrôlée par AuthState.
class ModuleFavoriServices {
  static Future<List<String>> getFavoris(String userCode) async {
    final db = await DbCreator.openDb();
    final rows = await db.query(
      'module_favori',
      columns: ['route'],
      where: 'user_code = ?',
      whereArgs: [userCode],
      orderBy: 'ordre ASC',
    );
    return rows.map((r) => r['route'] as String).toList();
  }

  static Future<void> ajouter(String userCode, String route, int ordre) async {
    final db = await DbCreator.openDb();
    await db.rawInsert(
      'INSERT OR IGNORE INTO module_favori (user_code, route, ordre, date_cree) VALUES (?, ?, ?, ?)',
      [userCode, route, ordre, DateTime.now().toIso8601String()],
    );
  }

  static Future<void> supprimer(String userCode, String route) async {
    final db = await DbCreator.openDb();
    await db.delete('module_favori', where: 'user_code = ? AND route = ?', whereArgs: [userCode, route]);
  }
}
