import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

/// Gère l'architecture caisse à 3 niveaux : Ouverture (CaisseSession) ->
/// Mouvements (CaisseMouvement) -> Clôture. Une session doit être ouverte
/// pour une caisse avant toute vente/achat/versement/retour — voir
/// [getSessionOuverte], utilisé comme verrou par les dialogues de saisie.
class CaisseSessionServices {
  final Database db;

  CaisseSessionServices(this.db);

  static Future<int> _getNextId(DatabaseExecutor executor, String table) async {
    final result = await executor.rawQuery('SELECT MAX(id) AS maxId FROM $table');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  /// Pour construire un CaisseMouvement en dehors de [ajouterMouvement]
  /// (ex. mouvement manuel saisi depuis un dialogue), même convention que
  /// GCServices.getNextCaisseId / VerssementServices.getNextVerssementId.
  static Future<int> getNextMouvementId(DatabaseExecutor db) async {
    return _getNextId(db, 'caisse_mouvement');
  }

  /// Session actuellement ouverte pour [caisseCode], ou `null` si aucune
  /// (caisse fermée). Une seule session ouverte peut exister à la fois par
  /// caisse — garanti par [ouvrirSession].
  static Future<CaisseSession?> getSessionOuverte(String caisseCode) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'caisse_session',
      where: 'caisse_code = ? AND statut = ?',
      whereArgs: [caisseCode, CaisseSession.statutOuverte],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return CaisseSession.fromMap(maps.first);
  }

  /// Toutes les sessions, toutes caisses confondues — utilisé par les écrans
  /// de consultation (voir gestion_caisse_screen.dart, onglet "Sessions de
  /// caisse"), qui filtrent ensuite par caisse si besoin.
  static Future<List<CaisseSession>> getAllSessions() async {
    final db = await DbCreator.openDb();
    final maps = await db.query('caisse_session', orderBy: 'id DESC');
    return maps.map((e) => CaisseSession.fromMap(e)).toList();
  }

  static Future<List<CaisseSession>> getSessionsByCaisse(String caisseCode) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'caisse_session',
      where: 'caisse_code = ?',
      whereArgs: [caisseCode],
      orderBy: 'id DESC',
    );
    return maps.map((e) => CaisseSession.fromMap(e)).toList();
  }

  /// Ouvre une nouvelle session pour [caisseCode] avec [soldeOuverture] comme
  /// fond de départ, et journalise immédiatement un mouvement `ouverture`
  /// pour ce montant. Refuse si une session est déjà ouverte pour cette
  /// caisse (une seule à la fois).
  Future<ApiResponse<CaisseSession>> ouvrirSession({
    required String caisseCode,
    required double soldeOuverture,
    required String userCode,
  }) async {
    try {
      final dejaOuverte = await getSessionOuverte(caisseCode);
      if (dejaOuverte != null) {
        return ApiResponse(
          success: false,
          message: "Une session de caisse est déjà ouverte pour cette caisse",
        );
      }

      late final CaisseSession session;
      await db.transaction((txn) async {
        final nextSessionId = await _getNextId(txn, 'caisse_session');
        final now = DateTime.now();

        session = CaisseSession(
          id: nextSessionId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.caisseSession,
            id: nextSessionId,
            digitCount: 6,
          ),
          caisseCode: caisseCode,
          statut: CaisseSession.statutOuverte,
          soldeOuverture: soldeOuverture,
          dateOuverture: now,
          etat: true,
          dateCree: now,
          creeParCode: userCode,
        );

        await txn.insert(
          'caisse_session',
          session.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        final nextMouvementId = await _getNextId(txn, 'caisse_mouvement');
        final mouvement = CaisseMouvement(
          id: nextMouvementId,
          code: CodeGenerator.generateCode(
            prefix: CodePrefix.caisseMouvement,
            id: nextMouvementId,
            digitCount: 8,
          ),
          sessionCode: session.code,
          caisseCode: caisseCode,
          type: 'ouverture',
          sens: 'Entrée',
          montant: soldeOuverture,
          date: now,
          etat: true,
          dateCree: now,
          creeParCode: userCode,
          motif: "Ouverture de caisse",
        );
        await txn.insert(
          'caisse_mouvement',
          mouvement.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      });

      return ApiResponse(success: true, message: "Caisse ouverte avec succès", data: session);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur ouverture caisse : ${e.toString()}");
    }
  }

  /// Solde courant d'une session ouverte : fond de départ + somme des
  /// mouvements actifs (`etat=1`), Entrée en plus, Sortie en moins.
  static Future<double> getSoldeCourant(String sessionCode) async {
    final db = await DbCreator.openDb();
    final session = await _getSessionByCode(db, sessionCode);
    if (session == null) return 0;

    final mouvements = await getMouvementsBySession(sessionCode);
    double solde = session.soldeOuverture;
    for (final m in mouvements.where((m) => m.etat)) {
      solde += m.sens == 'Entrée' ? m.montant : -m.montant;
    }
    return solde;
  }

  static Future<CaisseSession?> _getSessionByCode(DatabaseExecutor executor, String code) async {
    final maps = await executor.query('caisse_session', where: 'code = ?', whereArgs: [code], limit: 1);
    if (maps.isEmpty) return null;
    return CaisseSession.fromMap(maps.first);
  }

  /// Clôture [sessionCode] : calcule le solde théorique (fond de départ +
  /// mouvements actifs de la session), enregistre le solde réel compté par
  /// l'utilisateur et l'écart entre les deux. Si l'écart est non nul, un
  /// mouvement `cloture` est journalisé pour que la somme des mouvements de
  /// la session reste égale au solde réel compté.
  Future<ApiResponse<CaisseSession>> cloturerSession({
    required String sessionCode,
    required double soldeReel,
    required String userCode,
  }) async {
    try {
      final session = await _getSessionByCode(db, sessionCode);
      if (session == null) {
        return ApiResponse(success: false, message: "Session de caisse introuvable");
      }
      if (!session.estOuverte) {
        return ApiResponse(success: false, message: "Cette session de caisse est déjà clôturée");
      }

      final soldeTheorique = await getSoldeCourant(sessionCode);
      final ecart = soldeReel - soldeTheorique;
      final now = DateTime.now();

      await db.transaction((txn) async {
        if (ecart != 0) {
          final nextMouvementId = await _getNextId(txn, 'caisse_mouvement');
          final mouvementEcart = CaisseMouvement(
            id: nextMouvementId,
            code: CodeGenerator.generateCode(
              prefix: CodePrefix.caisseMouvement,
              id: nextMouvementId,
              digitCount: 8,
            ),
            sessionCode: sessionCode,
            caisseCode: session.caisseCode,
            type: 'cloture',
            sens: ecart >= 0 ? 'Entrée' : 'Sortie',
            montant: ecart.abs(),
            date: now,
            etat: true,
            dateCree: now,
            creeParCode: userCode,
            motif: "Écart de clôture",
          );
          await txn.insert(
            'caisse_mouvement',
            mouvementEcart.toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }

        await txn.update(
          'caisse_session',
          {
            'statut': CaisseSession.statutCloturee,
            'solde_theorique': soldeTheorique,
            'solde_reel': soldeReel,
            'ecart': ecart,
            'date_cloture': now.toIso8601String(),
            'modif_par_code': userCode,
            'date_modif': now.toIso8601String(),
          },
          where: 'code = ?',
          whereArgs: [sessionCode],
        );
      });

      session.statut = CaisseSession.statutCloturee;
      session.soldeTheorique = soldeTheorique;
      session.soldeReel = soldeReel;
      session.ecart = ecart;
      session.dateCloture = now;

      return ApiResponse(success: true, message: "Caisse clôturée avec succès", data: session);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur clôture caisse : ${e.toString()}");
    }
  }

  /// Journalise un mouvement dans la session ouverte de [caisseMouvement] —
  /// refuse si cette session n'est plus ouverte (garde-fou même si
  /// l'appelant a déjà vérifié [getSessionOuverte] avant de construire
  /// l'objet).
  Future<ApiResponse<int>> ajouterMouvement(CaisseMouvement mouvement) async {
    try {
      final session = await _getSessionByCode(db, mouvement.sessionCode);
      if (session == null || !session.estOuverte) {
        return ApiResponse(
          success: false,
          message: "Impossible d'ajouter un mouvement : aucune session ouverte pour cette caisse",
        );
      }

      final id = await db.insert(
        'caisse_mouvement',
        mouvement.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      return ApiResponse(success: true, message: "Mouvement ajouté avec succès", data: id);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur ajout mouvement : ${e.toString()}");
    }
  }

  /// Met à jour le montant d'un mouvement déjà journalisé (ex. répercuter un
  /// changement de montant versé sur une opération existante), sans changer
  /// son type/sens/session — voir usage dans `smart_screen_modif.dart`.
  Future<ApiResponse<int>> updateMontantMouvement({
    required String code,
    required double montant,
    required String userCode,
  }) async {
    try {
      final rows = await db.update(
        'caisse_mouvement',
        {
          'montant': montant,
          'date_modif': DateTime.now().toIso8601String(),
          'modif_par_code': userCode,
        },
        where: 'code = ?',
        whereArgs: [code],
      );
      return ApiResponse(success: true, message: "Mouvement mis à jour", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur mise à jour mouvement : ${e.toString()}");
    }
  }

  /// Annule (soft-cancel, `etat=0`) un mouvement — jamais de suppression
  /// physique, pour garder la traçabilité du grand-livre de caisse.
  Future<ApiResponse<int>> annulerMouvement({
    required String code,
    required String userCode,
    String? motif,
  }) async {
    try {
      final now = DateTime.now();
      final rows = await db.update(
        'caisse_mouvement',
        {
          'etat': 0,
          'date_annul': now.toIso8601String(),
          'annul_par_code': userCode,
          'motif_annul': motif,
        },
        where: 'code = ?',
        whereArgs: [code],
      );
      return ApiResponse(success: true, message: "Mouvement annulé", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation mouvement : ${e.toString()}");
    }
  }

  /// Tous les mouvements de caisse, toutes sessions/caisses confondues —
  /// utilisé par les écrans de reporting (voir mouvement_caisse_tab.dart),
  /// qui filtrent ensuite par caisse/période.
  static Future<List<CaisseMouvement>> getAllMouvements() async {
    final db = await DbCreator.openDb();
    final maps = await db.query('caisse_mouvement', orderBy: 'id ASC');
    return maps.map((e) => CaisseMouvement.fromMap(e)).toList();
  }

  static Future<List<CaisseMouvement>> getMouvementsBySession(String sessionCode) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'caisse_mouvement',
      where: 'session_code = ?',
      whereArgs: [sessionCode],
      orderBy: 'id ASC',
    );
    return maps.map((e) => CaisseMouvement.fromMap(e)).toList();
  }

  /// Mouvement(s) déjà journalisé(s) pour une opération donnée (vente,
  /// achat, retour ou versement), utilisé pour retrouver le mouvement lié
  /// lors d'une modification/annulation de cette opération.
  static Future<List<CaisseMouvement>> getMouvementsByCodeOperation(
    String codeOperation, {
    String? type,
  }) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'caisse_mouvement',
      where: type != null ? 'code_operation = ? AND type = ?' : 'code_operation = ?',
      whereArgs: type != null ? [codeOperation, type] : [codeOperation],
    );
    return maps.map((e) => CaisseMouvement.fromMap(e)).toList();
  }
}
