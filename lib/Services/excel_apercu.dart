import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';

import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

/// En-têtes + lignes (texte) de la feuille de données d'un fichier généré
/// par ExcelGenerator : la feuille [nomFeuille] si elle existe, sinon la
/// feuille la plus remplie hors "Summary" (Excel.createExcel crée aussi une
/// feuille vide par défaut).
({List<String> headers, List<List<String>> rows})? _lireFeuille(Excel excel, String? nomFeuille) {
  Sheet? sheet = nomFeuille == null ? null : excel.tables[nomFeuille];
  if (sheet == null) {
    final candidates = excel.tables.entries.where((e) => e.key != 'Summary').map((e) => e.value).toList()
      ..sort((a, b) => b.maxRows.compareTo(a.maxRows));
    sheet = candidates.isEmpty ? null : candidates.first;
  }
  if (sheet == null) return null;

  final List<String> headers = [];
  for (int col = 0; col < sheet.maxColumns; col++) {
    final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
    if (cell.value != null && cell.value.toString().isNotEmpty) {
      headers.add(cell.value.toString());
    }
  }

  final List<List<String>> rows = [];
  for (int row = 1; row < sheet.maxRows; row++) {
    final List<String> rowData = [];
    bool hasData = false;
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
      if (cell.value != null && cell.value.toString().isNotEmpty) {
        rowData.add(cell.value.toString());
        hasData = true;
      } else {
        rowData.add('-');
      }
    }
    if (hasData) rows.add(rowData);
  }
  return (headers: headers, rows: rows);
}

void _snack(BuildContext context, String message, Color color) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: color),
  );
}

/// Relit [fichier] généré par ExcelGenerator et ouvre l'aperçu ; [nomFeuille]
/// est la feuille affichée (repli sur la feuille de données sinon).
Future<void> ouvrirApercuExcel(
  BuildContext context, {
  required File fichier,
  required String nomFeuille,
  required String titre,
  required AppLocalizations l10n,
}) async {
  final excel = await executerAvecSpinner(
    context,
    () async => Excel.decodeBytes(await fichier.readAsBytes()),
  );

  final feuille = _lireFeuille(excel, nomFeuille);
  if (feuille == null) {
    _snack(context, 'Could not find data sheet in Excel file', Colors.red);
    return;
  }
  if (!context.mounted) return;
  if (feuille.rows.isEmpty) {
    _snack(context, 'No data found in Excel file', Colors.orange);
    return;
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => ExcelPreviewDialog(
      data: feuille.rows,
      headers: feuille.headers,
      title: titre,
      l10n: l10n,
      excelFile: fichier,
      onSave: () {
        Navigator.pop(dialogContext);
        _snack(context, l10n.exportSuccess, Colors.green);
      },
      onShare: () => Navigator.pop(dialogContext),
      onCancel: () => Navigator.pop(dialogContext),
    ),
  );
}

/// "Extract PDF" des modules : mêmes données et mêmes colonnes que leur
/// export Excel (on relit le fichier généré par ExcelGenerator), mises en
/// page en tableau PDF (PDFTableGenerator) avec aperçu imprimer/enregistrer.
Future<void> ouvrirApercuPdfDepuisExcel(
  BuildContext context, {
  required File fichier,
  required String titre,
  String? nomFeuille,
}) async {
  final l10n = AppLocalizations.of(context)!;
  try {
    final pdfBytes = await executerAvecSpinner(context, () async {
      final excel = Excel.decodeBytes(await fichier.readAsBytes());
      final feuille = _lireFeuille(excel, nomFeuille);
      if (feuille == null || feuille.rows.isEmpty) return null;
      final now = DateTime.now();
      return PDFTableGenerator.generateTableReport(
        title: titre,
        subtitleLines: [
          "${l10n.generationDate}: ${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} "
              "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}    "
              "${l10n.total}: ${feuille.rows.length}",
        ],
        headers: feuille.headers,
        rows: feuille.rows,
      );
    });

    if (!context.mounted) return;
    if (pdfBytes == null) {
      _snack(context, l10n.noDataToExport, Colors.orange);
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PDFPreviewDialog(
        pdfBytes: pdfBytes,
        l10n: l10n,
        onPrint: () async {
          Navigator.pop(dialogContext);
          await PDFGeneratorLatin.printPDF(pdfBytes);
        },
        onSave: () async {
          final nom = titre.replaceAll(RegExp(r'[^\w\-]+'), '_');
          final file = await PDFGeneratorLatin.savePDF(pdfBytes, '${nom}_${DateTime.now().millisecondsSinceEpoch}.pdf');
          if (dialogContext.mounted) Navigator.pop(dialogContext);
          _snack(context, l10n.exportSuccess, Colors.green);
          await PDFGeneratorLatin.openPDF(file);
        },
        onShare: () => Navigator.pop(dialogContext),
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  } catch (e) {
    debugPrint('PDF export error: $e');
    _snack(context, '${l10n.exportError}: $e', Colors.red);
  }
}
