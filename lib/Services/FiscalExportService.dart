import 'dart:convert';
import 'dart:io';

import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/ExportStorage.dart';
import 'package:caisse_dz/Services/JournalFiscal.dart';

/// Export destiné à un contrôle fiscal : rassemble, pour une période donnée,
/// le registre fiscal append-only (Phase 3), les tickets de caisse scellés
/// (Phase 2) et les clôtures de caisse (Phase 4) dans un unique fichier JSON
/// auto-descriptif — chaque ligne porte son empreinte SHA-256, vérifiable
/// indépendamment de l'application. La vérification d'intégrité du registre
/// (chaîne complète, pas seulement la période exportée) est incluse en tête
/// du fichier : un registre compromis doit être visible immédiatement, pas
/// noyé dans les données.
class FiscalExportService {
  static Future<File> exporterControleFiscal({
    required DateTime dateDebut,
    required DateTime dateFin,
  }) async {
    final db = await DbCreator.openDb();

    final verification = await JournalFiscalServices.verifierIntegrite();

    final journalMaps = await db.query(
      'journal_fiscal',
      where: 'date_evenement >= ? AND date_evenement <= ?',
      whereArgs: [dateDebut.toIso8601String(), dateFin.toIso8601String()],
      orderBy: 'id ASC',
    );
    final ticketMaps = await db.query(
      'panniers',
      where: 'date >= ? AND date <= ?',
      whereArgs: [dateDebut.toIso8601String(), dateFin.toIso8601String()],
      orderBy: 'id ASC',
    );
    final clotureMaps = await db.query(
      'cloture_caisse',
      where: 'date_fin >= ? AND date_fin <= ?',
      whereArgs: [dateDebut.toIso8601String(), dateFin.toIso8601String()],
      orderBy: 'id ASC',
    );

    final export = {
      'export': {
        'application': 'CaisseDZ',
        'genere_le': DateTime.now().toIso8601String(),
        'periode_debut': dateDebut.toIso8601String(),
        'periode_fin': dateFin.toIso8601String(),
      },
      'verification_integrite_registre_fiscal': {
        'intact': verification.integre,
        'nombre_evenements_registre_total': verification.nombreEvenements,
        'premier_evenement_compromis_id': verification.premierIdCompromis,
      },
      'registre_fiscal': journalMaps,
      'tickets': ticketMaps,
      'clotures_caisse': clotureMaps,
    };

    final directory = await getExportDirectory();
    final fileName = 'ExportFiscal_${_fmtCompact(dateDebut)}_${_fmtCompact(dateFin)}_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(const JsonEncoder.withIndent('  ').convert(export));

    return file;
  }

  static String _fmtCompact(DateTime d) =>
      "${d.year}${d.month.toString().padLeft(2, '0')}${d.day.toString().padLeft(2, '0')}";
}
