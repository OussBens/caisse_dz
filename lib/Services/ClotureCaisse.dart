import 'dart:convert';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/JournalFiscal.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/cloture_caisse.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

/// Clôtures de caisse (rapport Z) : fige définitivement une période de
/// ventes pour une caisse donnée — les tickets couverts par une clôture ne
/// peuvent plus être annulés (voir PannierServices.annulerPannier), seul un
/// Retour reste possible ensuite. Comme le registre fiscal (JournalFiscal),
/// aucune méthode update/delete n'existe ici volontairement : une clôture
/// créée ne doit plus jamais changer.
class ClotureCaisseServices {
  static const String _genesisHash = 'GENESIS';

  /// Date de fin de la dernière clôture connue pour [caisseCode], ou `null`
  /// si cette caisse n'a jamais été clôturée.
  static Future<DateTime?> getDerniereClotureDate(String caisseCode) async {
    final db = await DbCreator.openDb();
    final maps = await db.query(
      'cloture_caisse',
      columns: ['date_fin'],
      where: 'caisse_code = ?',
      whereArgs: [caisseCode],
      orderBy: 'id DESC',
      limit: 1,
    );
    if (maps.isEmpty) return null;
    return DateTime.parse(maps.first['date_fin'] as String);
  }

  /// Clôture la période en cours pour [caisseCode] : depuis la dernière
  /// clôture (ou depuis le début si la caisse n'a jamais été clôturée)
  /// jusqu'à maintenant. Agrège les panniers de la période (ventes actives
  /// et annulées), scelle le résultat (chaînage SHA-256 propre à cette
  /// caisse) et l'enregistre, avec une ligne miroir dans le registre fiscal.
  static Future<ApiResponse<ClotureCaisse>> cloturer({
    required String caisseCode,
    required String userCode,
  }) async {
    try {
      final db = await DbCreator.openDb();
      final dateDebut = await getDerniereClotureDate(caisseCode) ?? DateTime(2000, 1, 1);
      final dateFin = DateTime.now();

      final panierMaps = await db.query(
        'panniers',
        where: 'caisse_code = ? AND date > ? AND date <= ?',
        whereArgs: [caisseCode, dateDebut.toIso8601String(), dateFin.toIso8601String()],
      );
      final panniers = panierMaps.map((m) => Pannier.fromMap(m)).toList();

      final actifs = panniers.where((p) => p.etat).toList();
      final annules = panniers.where((p) => !p.etat).toList();

      final totalVentes = actifs.fold<double>(0, (s, p) => s + p.montant);
      final totalAnnule = annules.fold<double>(0, (s, p) => s + p.montant);

      final repartition = <String, double>{};
      for (final p in actifs) {
        final mode = p.modePaiement ?? 'Espèce';
        repartition[mode] = (repartition[mode] ?? 0) + p.montant;
      }
      final repartitionJson = jsonEncode(repartition);

      late final ClotureCaisse cloture;
      await db.transaction((txn) async {
        final lastMaps = await txn.query(
          'cloture_caisse',
          columns: ['id', 'hash'],
          where: 'caisse_code = ?',
          whereArgs: [caisseCode],
          orderBy: 'id DESC',
          limit: 1,
        );
        final hashPrecedent = lastMaps.isNotEmpty ? lastMaps.first['hash'] as String : _genesisHash;

        final maxIdMaps = await txn.rawQuery('SELECT MAX(id) AS maxId FROM cloture_caisse');
        final nextId = ((maxIdMaps.first['maxId'] as int?) ?? 0) + 1;

        final payload = [
          caisseCode,
          dateDebut.toIso8601String(),
          dateFin.toIso8601String(),
          totalVentes.toStringAsFixed(2),
          totalAnnule.toStringAsFixed(2),
          actifs.length.toString(),
          annules.length.toString(),
          repartitionJson,
          hashPrecedent,
        ].join('|');
        final hash = sha256.convert(utf8.encode(payload)).toString();

        cloture = ClotureCaisse(
          id: nextId,
          code: CodeGenerator.generateCode(prefix: CodePrefix.clotureCaisse, id: nextId, digitCount: 6),
          caisseCode: caisseCode,
          dateDebut: dateDebut,
          dateFin: dateFin,
          totalVentes: totalVentes,
          totalAnnule: totalAnnule,
          nombreTickets: actifs.length,
          nombreTicketsAnnules: annules.length,
          repartitionPaiement: repartitionJson,
          utilisateurCode: userCode,
          dateCree: DateTime.now(),
          hash: hash,
          hashPrecedent: hashPrecedent,
        );

        await txn.insert(
          'cloture_caisse',
          cloture.toMap(),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );

        await JournalFiscalServices.enregistrer(
          txn,
          typeOperation: 'CLOTURE_CAISSE',
          codeOperation: cloture.code,
          utilisateurCode: userCode,
          caisseCode: caisseCode,
          montant: totalVentes,
          donneesApres: cloture.toMap(),
        );
      });

      return ApiResponse(success: true, message: "Clôture effectuée avec succès", data: cloture);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur clôture : ${e.toString()}");
    }
  }

  static Future<List<ClotureCaisse>> getAllClotures() async {
    final db = await DbCreator.openDb();
    final result = await db.query('cloture_caisse', orderBy: 'id DESC');
    return result.map((e) => ClotureCaisse.fromMap(e)).toList();
  }

  static Future<List<ClotureCaisse>> getCloturesByCaisse(String caisseCode) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'cloture_caisse',
      where: 'caisse_code = ?',
      whereArgs: [caisseCode],
      orderBy: 'id DESC',
    );
    return result.map((e) => ClotureCaisse.fromMap(e)).toList();
  }

  /// Vrai si [date] (celle d'un ticket, pour [caisseCode]) appartient à une
  /// période déjà clôturée — utilisé par PannierServices.annulerPannier pour
  /// refuser l'annulation d'un ticket verrouillé par une clôture.
  static Future<bool> estDansPeriodeCloturee(String caisseCode, DateTime date) async {
    final derniere = await getDerniereClotureDate(caisseCode);
    if (derniere == null) return false;
    return !date.isAfter(derniere);
  }
}
