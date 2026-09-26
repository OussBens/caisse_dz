import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Génère un PDF tabulaire générique (titre + lignes d'info + tableau),
/// pour les rapports de type liste (ex: Mouvement Caisse) qui n'ont pas la
/// structure d'une facture (voir PDFGeneratorLatin pour les factures/reçus).
class PDFTableGenerator {
  static const PdfColor primaryColor = PdfColor(0.2, 0.4, 0.6);
  static const PdfColor lightGray = PdfColor(0.9, 0.9, 0.9);

  static Future<Uint8List> generateTableReport({
    required String title,
    required List<String> subtitleLines,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: primaryColor,
              ),
            ),
            pw.SizedBox(height: 6),
            for (final line in subtitleLines)
              pw.Text(line, style: const pw.TextStyle(fontSize: 10)),
            pw.SizedBox(height: 10),
            pw.Divider(color: primaryColor),
          ],
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(color: primaryColor),
            cellStyle: const pw.TextStyle(fontSize: 8),
            cellAlignment: pw.Alignment.centerLeft,
            border: pw.TableBorder.all(color: lightGray, width: 0.5),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
          ),
        ],
      ),
    );

    return pdf.save();
  }
}
