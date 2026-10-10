import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Compteurs affichés par AfficheurStockGlobalWidget (cards globales des
/// modules Stock, Entrée, Sortie, Retour). Uniquement les éléments actifs
/// (etat = 1) : un document annulé ne doit pas gonfler les cards.
class CompteursGlobaux {
  final int produitsEnStock;
  final int smartScans;
  final int panniers;
  final int retours;
  final int besoinLists;
  final int sorties;

  const CompteursGlobaux({
    this.produitsEnStock = 0,
    this.smartScans = 0,
    this.panniers = 0,
    this.retours = 0,
    this.besoinLists = 0,
    this.sorties = 0,
  });
}

class StatistiquesGlobalesServices {
  static Future<int> _compterActifs(DatabaseExecutor db, String table) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS n FROM $table WHERE etat = 1');
    return (result.first['n'] as num?)?.toInt() ?? 0;
  }

  /// Produits en stock = produits actifs dont la quantité calculée depuis le
  /// journal des mouvements est strictement positive, sur les magasins
  /// consultables par l'utilisateur ([magasinsConsultation], `null` = tous,
  /// voir AuthState) — même source que la colonne Quantité des écrans
  /// Produit/Stock.
  static Future<CompteursGlobaux> getCompteurs({List<String>? magasinsConsultation}) async {
    final db = await DbCreator.openDb();

    final quantites = await MouvementsServices.quantitesConsultables(magasinsConsultation);
    final produitsActifs = await db.query('produits', columns: ['code'], where: 'etat = 1');
    final produitsEnStock = produitsActifs
        .where((p) => (quantites[p['code'] as String] ?? 0) > 0)
        .length;

    return CompteursGlobaux(
      produitsEnStock: produitsEnStock,
      smartScans: await _compterActifs(db, 'smart_scan'),
      panniers: await _compterActifs(db, 'panniers'),
      retours: await _compterActifs(db, 'retours'),
      besoinLists: await _compterActifs(db, 'besionList'),
      sorties: await _compterActifs(db, 'sortie'),
    );
  }
}
