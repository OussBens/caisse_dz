import 'dart:convert';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/ClotureCaisse.dart';
import 'package:caisse_dz/Services/JournalFiscal.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';



class PannierServices{

  final Database db;

  PannierServices(this.db);

  /// Empreinte de départ d'une chaîne de scellement (caisse n'ayant encore
  /// aucun ticket scellé) — valeur fixe et documentée plutôt que null, pour
  /// que la chaîne soit vérifiable dès le premier ticket.
  static const String _genesisHash = 'GENESIS';

  /// Calcule le scellement fiscal d'un panier juste avant son insertion :
  /// empreinte SHA-256 de son contenu, chaînée à l'empreinte du dernier
  /// ticket scellé sur la même caisse. Altérer un ticket passé casserait
  /// la chaîne de tous les tickets suivants sur cette caisse — conformité
  /// art. 51 bis (aucune vente validée ne doit pouvoir être modifiée après
  /// coup sans que ce soit détectable). Doit s'exécuter sur le même
  /// executor que l'insert (transaction) pour lire le dernier hash de façon
  /// cohérente en cas d'écritures concurrentes.
  Future<void> _sealPannier(DatabaseExecutor executor, Pannier pannier) async {
    final lastMaps = await executor.query(
      'panniers',
      columns: ['hash'],
      where: 'caisse_code = ? AND hash IS NOT NULL',
      whereArgs: [pannier.caisse_code],
      orderBy: 'id DESC',
      limit: 1,
    );
    final hashPrecedent = lastMaps.isNotEmpty ? lastMaps.first['hash'] as String : _genesisHash;

    final payload = [
      pannier.code,
      pannier.date.toIso8601String(),
      pannier.montant.toStringAsFixed(2),
      pannier.montantAchat.toStringAsFixed(2),
      pannier.caisse_code,
      pannier.caissier_code,
      pannier.modePaiement ?? '',
      pannier.client_code ?? '',
      hashPrecedent,
    ].join('|');

    pannier.hashPrecedent = hashPrecedent;
    pannier.hash = sha256.convert(utf8.encode(payload)).toString();
  }

  /// Crédite le bonus/fidélité du client d'un panier (si le programme est
  /// actif dans Paramètres) juste après son insertion — sur le même
  /// executor (transaction) que l'insert, pour que le crédit ne soit
  /// jamais désynchronisé du ticket qui l'a généré. Ignoré pour les
  /// ventes sans client identifié (client comptoir) : un solde de points
  /// n'a de sens que pour un client suivi individuellement.
  Future<void> _accruerBonus(DatabaseExecutor executor, Pannier pannier) async {
    if (pannier.client_code == null || pannier.client_code!.isEmpty || pannier.montant <= 0) return;

    // ✅ getParamWithTransaction (pas getParam) : on est déjà dans la
    // transaction de addPannier, rouvrir la connexion partagée ici
    // provoquerait un interblocage (voir commentaire sur cette méthode).
    final param = await ParamServices.getParamWithTransaction(executor);
    if (!param.activeBonus || param.bonusTaux <= 0) return;

    final bonus = pannier.montant / param.bonusTaux;
    await _crediterSoldeBonus(executor, pannier.client_code!, bonus);
  }

  /// Reprend le bonus précédemment crédité pour un panier annulé, avec le
  /// même calcul que l'accrual — au taux courant, pas celui en vigueur au
  /// moment de la vente (simplification acceptée : le taux change
  /// rarement). Le solde ne descend jamais sous zéro.
  Future<void> _reprendreBonus(DatabaseExecutor executor, Pannier pannier) async {
    if (pannier.client_code == null || pannier.client_code!.isEmpty || pannier.montant <= 0) return;

    final param = await ParamServices.getParamWithTransaction(executor);
    if (!param.activeBonus || param.bonusTaux <= 0) return;

    final bonus = pannier.montant / param.bonusTaux;
    await _crediterSoldeBonus(executor, pannier.client_code!, -bonus);
  }

  Future<void> _crediterSoldeBonus(DatabaseExecutor executor, String clientCode, double delta) async {
    final clientMaps = await executor.query(
      'clients',
      columns: ['solde_bonus'],
      where: 'code = ?',
      whereArgs: [clientCode],
      limit: 1,
    );
    if (clientMaps.isEmpty) return;

    final soldeActuel = (clientMaps.first['solde_bonus'] as num?)?.toDouble() ?? 0;
    final nouveauSolde = soldeActuel + delta < 0 ? 0.0 : soldeActuel + delta;
    await executor.update(
      'clients',
      {'solde_bonus': nouveauSolde},
      where: 'code = ?',
      whereArgs: [clientCode],
    );
  }

  /// Versements actifs (non annulés) liés à un pannier donné.
  /// Le montant versé/reste d'un pannier n'est plus stocké : il est
  /// recalculé à partir de ses versements pour rester toujours à jour.
  static List<Verssement> verssementsActifsDuPannier(
      List<Verssement> versements, String codePannier) {
    return versements
        .where((v) => v.codeOperation == codePannier && v.etat)
        .toList();
  }

  /// Montant total versé pour ce pannier.
  static double calculerVerse(List<Verssement> versements, String codePannier) {
    return verssementsActifsDuPannier(versements, codePannier)
        .fold(0.0, (s, v) => s + v.montant);
  }

  /// Nombre de versements actifs liés à ce pannier.
  static int calculerNbrVersement(List<Verssement> versements, String codePannier) {
    return verssementsActifsDuPannier(versements, codePannier).length;
  }

  /// Reste à payer = montant du pannier - montant versé.
  static double calculerReste(Pannier pannier, List<Verssement> versements) {
    return pannier.montant - calculerVerse(versements, pannier.code);
  }

  /// Regroupe le montant versé par code de pannier (versements actifs
  /// uniquement), pour éviter de reparcourir toute la liste des versements
  /// pour chaque ligne d'un tableau/export.
  static Map<String, double> verseParPannier(List<Verssement> versements) {
    final Map<String, double> resultat = {};
    for (final v in versements) {
      if (!v.etat) continue;
      resultat[v.codeOperation] = (resultat[v.codeOperation] ?? 0) + v.montant;
    }
    return resultat;
  }

  /// Regroupe le nombre de versements actifs par code de pannier.
  static Map<String, int> nbrVersementParPannier(List<Verssement> versements) {
    final Map<String, int> resultat = {};
    for (final v in versements) {
      if (!v.etat) continue;
      resultat[v.codeOperation] = (resultat[v.codeOperation] ?? 0) + 1;
    }
    return resultat;
  }

  // Ajoutez ces méthodes dans PannierServices.dart

  // ✅ Méthode avec transaction pour addPannier
  Future<ApiResponse<int>> addPannierWithTransaction(Transaction txn, Pannier pannier) async {
    try {
      final existing = await txn.query(
        'panniers',
        where: 'code = ?',
        whereArgs: [pannier.code],
      );

      if (existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un pannier avec ce code existe deja",
        );
      }

      await _sealPannier(txn, pannier);

      final id = await txn.insert(
        'panniers',
        pannier.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      await JournalFiscalServices.enregistrer(
        txn,
        typeOperation: 'VENTE',
        codeOperation: pannier.code,
        utilisateurCode: pannier.caissier_code,
        caisseCode: pannier.caisse_code,
        montant: pannier.montant,
        donneesApres: pannier.toMap(),
      );

      await _accruerBonus(txn, pannier);

      return ApiResponse(
        success: true,
        message: "pannier ajoute avec succes",
        data: id,
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );
    }
  }

  // ✅ Méthode avec transaction pour getNextPannierId
  static Future<int> getNextPannierIdWithTransaction(Transaction txn) async {
    final result = await txn.rawQuery('SELECT MAX(id) AS maxId FROM panniers');
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }

  static Future<List<Pannier>> getAllPanniers() async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query('panniers', orderBy: 'id ASC',);

    return result.map((e) => Pannier.fromMap(e)).toList();

  }

  // 🔹 Panniers actifs d'un caissier (pour les stats vente utilisateur)
  static Future<List<Pannier>> getPanniersActifsByCaissierCode(String caissierCode) async {

    final db = await DbCreator.openDb();

    final List<Map<String, dynamic>> result = await db.query(
      'panniers',
      where: 'caisser_code = ? AND etat = 1',
      whereArgs: [caissierCode],
    );

    return result.map((e) => Pannier.fromMap(e)).toList();

  }

  Future<Pannier?> getPannierById(int id) async {

    final maps = await db.query('panniers' , where: 'id = ?' , whereArgs: [id],);

    if(maps.isNotEmpty){

      return Pannier.fromMap(maps.first);

    }

    return null;

  }

  /// Modifie les métadonnées d'un panier (client, mode de paiement...).
  /// Refuse toute modification du contenu fiscal de la vente (montant,
  /// marge, lignes, date) — conformité art. 51 bis du Code TVA : une vente
  /// encaissée ne doit plus pouvoir être altérée après coup. Une correction
  /// du contenu vendu passe par un Retour, une annulation par
  /// [annulerPannier] — jamais par cette méthode.
  Future<ApiResponse<int>> updatePannier(Pannier produit) async{
    try{

      final existingMaps = await db.query('panniers', where: 'id = ?', whereArgs: [produit.id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Panier introuvable");
      }
      final existing = Pannier.fromMap(existingMaps.first);

      if (!existing.etat) {
        return ApiResponse(
          success: false,
          message: "Ce ticket est annulé — plus aucune modification possible",
        );
      }

      if (existing.montant != produit.montant ||
          existing.montantAchat != produit.montantAchat ||
          existing.marge != produit.marge ||
          existing.nombreArticle != produit.nombreArticle ||
          existing.quantiteProduit != produit.quantiteProduit ||
          existing.date != produit.date) {
        return ApiResponse(
          success: false,
          message: "Un ticket encaissé ne peut plus être modifié sur son contenu — utilisez un Retour",
        );
      }

      final data = produit.toMap()
        ..remove('id')
        ..remove('code');

      final rows = await db.update(
        'panniers',
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
          message : "Un pannier avec ce code existe deja",
        );
      }

      return ApiResponse(
        success: false,
        message: "Erreur modification : ${e.toString()}",
      );
    }
  }

  /// Annulation "douce" d'un panier déjà encaissé : bascule etat=annulé avec
  /// motif obligatoire, sans toucher au contenu de la vente ni le supprimer
  /// physiquement — le ticket, ses lignes et son historique restent en base
  /// pour preuve (conformité art. 51 bis : aucune vente validée ne doit
  /// disparaître ou être altérée après coup).
  Future<ApiResponse<int>> annulerPannier(
    int id, {
    required String motif,
    required String userCode,
  }) async {
    try {
      final existingMaps = await db.query('panniers', where: 'id = ? AND etat = 1', whereArgs: [id], limit: 1);
      if (existingMaps.isEmpty) {
        return ApiResponse(success: false, message: "Panier introuvable ou déjà annulé");
      }
      final existing = Pannier.fromMap(existingMaps.first);

      if (await ClotureCaisseServices.estDansPeriodeCloturee(existing.caisse_code, existing.date)) {
        return ApiResponse(
          success: false,
          message: "Ce ticket appartient à une période déjà clôturée — impossible de l'annuler, utilisez un Retour",
        );
      }

      final dateAnnul = DateTime.now();
      final apres = {
        ...existing.toMap(),
        'etat': 0,
        'date_annul': dateAnnul.toIso8601String(),
        'annul_par_code': userCode,
        'motif_annul': motif,
      };

      late final int rows;
      await db.transaction((txn) async {
        rows = await txn.update(
          'panniers',
          {
            'etat': 0,
            'date_annul': dateAnnul.toIso8601String(),
            'annul_par_code': userCode,
            'motif_annul': motif,
          },
          where: 'id = ? AND etat = 1',
          whereArgs: [id],
        );

        if (rows > 0) {
          await JournalFiscalServices.enregistrer(
            txn,
            typeOperation: 'ANNULATION_VENTE',
            codeOperation: existing.code,
            utilisateurCode: userCode,
            caisseCode: existing.caisse_code,
            montant: existing.montant,
            donneesAvant: existing.toMap(),
            donneesApres: apres,
          );

          await _reprendreBonus(txn, existing);
        }
      });

      if (rows == 0) {
        return ApiResponse(success: false, message: "Panier introuvable ou déjà annulé");
      }

      return ApiResponse(success: true, message: "Panier annulé avec succès", data: rows);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur annulation : ${e.toString()}");
    }
  }
// Dans PannierServices
// Dans PannierServices
  // Dans PannierServices
  // Dans PannierServices
  // Dans PannierServices
  static Future<int> getLastPannierNumber() async {
    final db = await DbCreator.openDb();

    try {
      // Obtenir la date d'aujourd'hui (début de journée)
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Récupérer le dernier code pour la date d'aujourd'hui uniquement
      final result = await db.rawQuery(
          '''SELECT code FROM panniers 
         WHERE date >= ? AND date <= ? 
         ORDER BY id DESC LIMIT 1''',
          [todayStart.toIso8601String(), todayEnd.toIso8601String()]
      );

      if (result.isNotEmpty && result.first['code'] != null) {
        // ✅ Convertir explicitement en String
        final String lastCode = result.first['code'].toString();

        // Extraire les chiffres à la fin du code
        final RegExp regex = RegExp(r'(\d+)$');
        final Match? match = regex.firstMatch(lastCode);

        if (match != null) {
          final int lastNumber = int.parse(match.group(1)!);
          return lastNumber + 1;
        }

        // Si le code est juste un nombre
        if (int.tryParse(lastCode) != null) {
          return int.parse(lastCode) + 1;
        }
      }

      // Si aucun panier n'existe pour aujourd'hui, commencer à 1
      return 1;
    } catch (e) {
      return 1;
    }
  }
// Ou si vous voulez récupérer le dernier ID
  static Future<int> getLastPannierId() async {
    final db = await DbCreator.openDb();

    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM panniers',
    );

    final maxId = result.first['maxId'] as int?;
    return maxId ?? 0; // Retourne le dernier ID
  }
  Future<ApiResponse<int>> addPannier(Pannier pannier) async {
    try{

      final existing = await db.query(
        'panniers',
        where: 'code = ?',
        whereArgs: [pannier.code],
      );

      if(existing.isNotEmpty) {
        return ApiResponse(
          success: false,
          message: "Un pannier avec ce code existe deja",
        );
      }

      // Scellement + insert dans une transaction : évite qu'un autre insert
      // concurrent sur la même caisse lise le même "dernier hash" et casse
      // le chaînage.
      late final int id;
      await db.transaction((txn) async {
        await _sealPannier(txn, pannier);
        id = await txn.insert(
          'panniers',
          pannier.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        await JournalFiscalServices.enregistrer(
          txn,
          typeOperation: 'VENTE',
          codeOperation: pannier.code,
          utilisateurCode: pannier.caissier_code,
          caisseCode: pannier.caisse_code,
          montant: pannier.montant,
          donneesApres: pannier.toMap(),
        );

        await _accruerBonus(txn, pannier);
      });

      return ApiResponse(
        success : true,
        message : "pannier ajoute avec succes",
        data    : id,
      );

    }catch(e){

      return ApiResponse(
        success: false,
        message: "Erreur ajout: ${e.toString()}",
      );

    }
  }



  static Future<int> getNextPannierId(DatabaseExecutor db) async{
    final result = await db.rawQuery(
      'SELECT MAX(id) AS maxId FROM panniers',
    );
    final maxId = result.first['maxId'] as int?;
    return (maxId ?? 0) + 1;
  }


}