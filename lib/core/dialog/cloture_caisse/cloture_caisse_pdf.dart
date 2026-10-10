import 'dart:convert';

import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';
import 'package:caisse_dz/data/models/cloture_caisse.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Génère et affiche (impression/enregistrement, via [PDFPreviewDialog]) le
/// rapport de clôture (Z) correspondant à [cloture] — un résumé, pas un
/// listing de tickets, à l'image d'un rapport Z de caisse enregistreuse.
/// Partagé entre le dialog de nouvelle clôture (impression immédiate) et le
/// détail d'une clôture passée (réimpression) pour ne pas dupliquer la mise
/// en page du rapport.
Future<void> genererEtAfficherRapportZ(
  BuildContext context,
  AppLocalizations l10n,
  ClotureCaisse cloture,
  String nomCaisse,
) async {
  final repartition = cloture.repartitionPaiement != null
      ? (jsonDecode(cloture.repartitionPaiement!) as Map<String, dynamic>)
      : <String, dynamic>{};

  final rows = <List<String>>[
    [l10n.numberOfSales, cloture.nombreTickets.toString()],
    [l10n.totalAmount, "${NumberFormatUtil.formatMontant(cloture.totalVentes, decimales: 2)} ${l10n.currency}"],
    [l10n.cancelledTicketsCount, cloture.nombreTicketsAnnules.toString()],
    [l10n.totalCancelledAmount, "${NumberFormatUtil.formatMontant(cloture.totalAnnule, decimales: 2)} ${l10n.currency}"],
    for (final entry in repartition.entries)
      ["${l10n.paymentMethod}: ${entry.key}", "${NumberFormatUtil.formatMontant((entry.value as num).toDouble(), decimales: 2)} ${l10n.currency}"],
    [l10n.fiscalHash, cloture.hash],
  ];

  final pdfBytes = await PDFTableGenerator.generateTableReport(
    title: "${l10n.zReportTitle} - $nomCaisse",
    subtitleLines: [
      "${l10n.code}: ${cloture.code}",
      "${l10n.from}: ${_formatDate(cloture.dateDebut)}    ${l10n.to}: ${_formatDate(cloture.dateFin)}",
    ],
    headers: [l10n.description, l10n.amount],
    rows: rows,
  );

  if (!context.mounted) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PDFPreviewDialog(
      pdfBytes: pdfBytes,
      l10n: l10n,
      onPrint: () async {
        Navigator.pop(context);
        await PDFGeneratorLatin.printPDF(pdfBytes);
      },
      onSave: () async {
        final file = await PDFGeneratorLatin.savePDF(
          pdfBytes,
          '${cloture.code}.pdf',
        );
        if (!context.mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Appstyle.success),
        );
        await PDFGeneratorLatin.openPDF(file);
      },
      onShare: () => Navigator.pop(context),
      onCancel: () => Navigator.pop(context),
    ),
  );
}

String _formatDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:"
      "${d.minute.toString().padLeft(2, '0')}";
}
