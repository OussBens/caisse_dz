import 'dart:convert';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/journal_fiscal.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../core/utilis/api_response.dart';

/// Registre fiscal append-only : chaque événement de caisse important
/// (vente, annulation de vente...) y est inséré avec un scellement SHA-256
/// chaîné sur l'ensemble du registre (toutes caisses confondues) —
/// indépendant du scellement par ticket (voir PannierServices._sealPannier),
/// qui lui est chaîné par caisse. Volontairement, aucune méthode
/// update/delete n'existe ici : une fois écrite, une ligne ne doit plus
/// jamais changer (conformité art. 51 bis du Code TVA).
class JournalFiscalServices {
  static const String _genesisHash = 'GENESIS';

  /// Enregistre un événement fiscal. À appeler sur le même executor
  /// (transaction) que l'opération métier qu'il documente, pour que
  /// l'écriture au registre soit atomique avec cette opération — un ticket
  /// créé/annulé sans sa ligne de journal (ou l'inverse) casserait la
  /// preuve d'audit. Pas d'état d'instance : toutes les méthodes sont
  /// statiques, l'executor est toujours fourni explicitement.
  static Future<ApiResponse<int>> enregistrer(
    DatabaseExecutor executor, {
    required String typeOperation,
    required String codeOperation,
    required String utilisateurCode,
    String? caisseCode,
    double? montant,
    Map<String, dynamic>? donneesAvant,
    Map<String, dynamic>? donneesApres,
  }) async {
    try {
      final lastMaps = await executor.query(
        'journal_fiscal',
        columns: ['id', 'hash'],
        orderBy: 'id DESC',
        limit: 1,
      );
      final hashPrecedent = lastMaps.isNotEmpty ? lastMaps.first['hash'] as String : _genesisHash;
      final nextId = lastMaps.isNotEmpty ? (lastMaps.first['id'] as int) + 1 : 1;

      final dateEvenement = DateTime.now();
      final donneesAvantJson = donneesAvant != null ? jsonEncode(donneesAvant) : null;
      final donneesApresJson = donneesApres != null ? jsonEncode(donneesApres) : null;

      final payload = [
        typeOperation,
        codeOperation,
        caisseCode ?? '',
        utilisateurCode,
        montant?.toStringAsFixed(2) ?? '',
        donneesAvantJson ?? '',
        donneesApresJson ?? '',
        dateEvenement.toIso8601String(),
        hashPrecedent,
      ].join('|');
      final hash = sha256.convert(utf8.encode(payload)).toString();

      final entry = JournalFiscal(
        id: nextId,
        code: CodeGenerator.generateCode(prefix: CodePrefix.journalFiscal, id: nextId, digitCount: 8),
        typeOperation: typeOperation,
        codeOperation: codeOperation,
        caisseCode: caisseCode,
        utilisateurCode: utilisateurCode,
        montant: montant,
        donneesAvant: donneesAvantJson,
        donneesApres: donneesApresJson,
        hash: hash,
        hashPrecedent: hashPrecedent,
        dateEvenement: dateEvenement,
      );

      final id = await executor.insert(
        'journal_fiscal',
        entry.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );

      return ApiResponse(success: true, message: "Événement fiscal enregistré", data: id);
    } catch (e) {
      return ApiResponse(success: false, message: "Erreur journal fiscal: ${e.toString()}");
    }
  }

  static Future<List<JournalFiscal>> getAll() async {
    final db = await DbCreator.openDb();
    final result = await db.query('journal_fiscal', orderBy: 'id ASC');
    return result.map((e) => JournalFiscal.fromMap(e)).toList();
  }

  static Future<List<JournalFiscal>> getByCodeOperation(String codeOperation) async {
    final db = await DbCreator.openDb();
    final result = await db.query(
      'journal_fiscal',
      where: 'code_operation = ?',
      whereArgs: [codeOperation],
      orderBy: 'id ASC',
    );
    return result.map((e) => JournalFiscal.fromMap(e)).toList();
  }

  /// Recalcule la chaîne complète du registre fiscal (genèse -> dernier
  /// événement) et compare chaque empreinte recalculée à celle stockée —
  /// détecte toute altération a posteriori d'une ligne ou toute rupture de
  /// chaînage. À exécuter avant tout export de contrôle fiscal.
  static Future<VerificationJournalFiscal> verifierIntegrite() async {
    final db = await DbCreator.openDb();
    final maps = await db.query('journal_fiscal', orderBy: 'id ASC');

    String hashPrecedentAttendu = _genesisHash;
    for (final m in maps) {
      final montant = m['montant'];
      final payload = [
        m['type_operation'],
        m['code_operation'],
        m['caisse_code'] ?? '',
        m['utilisateur_code'],
        montant != null ? (montant as num).toStringAsFixed(2) : '',
        m['donnees_avant'] ?? '',
        m['donnees_apres'] ?? '',
        m['date_evenement'],
        hashPrecedentAttendu,
      ].join('|');
      final hashCalcule = sha256.convert(utf8.encode(payload)).toString();

      if (m['hash_precedent'] != hashPrecedentAttendu || m['hash'] != hashCalcule) {
        return VerificationJournalFiscal(
          integre: false,
          nombreEvenements: maps.length,
          premierIdCompromis: m['id'] as int,
        );
      }
      hashPrecedentAttendu = hashCalcule;
    }

    return VerificationJournalFiscal(integre: true, nombreEvenements: maps.length);
  }
}

/// Résultat de [JournalFiscalServices.verifierIntegrite].
class VerificationJournalFiscal {
  final bool integre;
  final int nombreEvenements;
  final int? premierIdCompromis;

  VerificationJournalFiscal({
    required this.integre,
    required this.nombreEvenements,
    this.premierIdCompromis,
  });
}
