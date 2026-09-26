// pdf_generator_ar.dart (BULLETPROOF VERSION)

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:caisse_dz/Services/ExportStorage.dart';
import 'package:open_file/open_file.dart';
import 'package:caisse_dz/data/models/caisse.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class PDFGeneratorArabic {
  static const PdfColor primaryColor = PdfColor(0.2, 0.4, 0.6);
  static const PdfColor textColor = PdfColor(0.1, 0.1, 0.1);
  static const PdfColor lightGray = PdfColor(0.95, 0.95, 0.95);
  static const PdfColor borderColor = PdfColor(0.8, 0.8, 0.8);

  pw.Font? _regularFont;
  pw.Font? _boldFont;
  bool _fontsLoaded = false;

  // ✅ LOAD CAIRO FONT WITH BETTER ERROR HANDLING
  Future<void> loadFonts() async {
    if (_fontsLoaded) return;

    try {
      print('🔤 Loading Arabic fonts...');

      final regularData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');

      _regularFont = pw.Font.ttf(regularData);
      _boldFont = pw.Font.ttf(boldData);

      _fontsLoaded = true;
      print('✅ Arabic fonts loaded successfully');
    } catch (e, stackTrace) {
      print('❌ Error loading fonts: $e');
      print(stackTrace);
      throw Exception('Failed to load Arabic fonts: $e');
    }
  }

  // ✅ SAFE STYLE CREATION - ensures fonts are loaded first
  pw.TextStyle _style({
    double fontSize = 12,
    bool isBold = false,
    PdfColor? color,
    pw.TextDecoration? decoration,
  }) {
    if (!_fontsLoaded || _regularFont == null || _boldFont == null) {
      throw Exception('Fonts not loaded! Call loadFonts() first.');
    }

    final font = isBold ? _boldFont : _regularFont;

    return pw.TextStyle(
      font: font,
      fontFallback: [_regularFont!, _boldFont!], // Both as fallback
      fontSize: fontSize,
      color: color ?? textColor,
      decoration: decoration,
    );
  }

  Future<Uint8List> generateInvoice({
    required CaisseState caisse,
    required Client client,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
    required String invoiceNumber,
    required String invoiceType,
    String? adresse,
    Uint8List? logoBytes,
  }) async {
    // Ensure fonts are loaded
    if (!_fontsLoaded) {
      await loadFonts();
    }

    final pdf = pw.Document();
    final currency = "د.ج";

    // ✅ THEME WITH FALLBACK
    final theme = pw.ThemeData.withFont(
      base: _regularFont!,
      bold: _boldFont!,
      fontFallback: [_regularFont!, _boldFont!],
    );

    // Logo boutique (fourni par l'appelant via LogoService), asset de repli sinon
    pw.MemoryImage? logo;
    try {
      final bytes = logoBytes ?? await _loadLogo();
      if (bytes != null) {
        logo = pw.MemoryImage(bytes);
      }
    } catch (e) {
      print('⚠️ Logo not found: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        theme: theme,
        pageFormat: PdfPageFormat.a4,
        textDirection: pw.TextDirection.rtl,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(magasinName, adresse, logo, invoiceType, invoiceNumber),
            pw.SizedBox(height: 20),
            _buildClientInfo(client),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(caisse, caissierName),
            pw.SizedBox(height: 20),
            _buildProductsTable(caisse, currency, invoiceType),
            pw.SizedBox(height: 20),
            _buildTotalsSection(caisse, verse, reste, currency),
            pw.SizedBox(height: 30),
            _buildPaymentInfo(verse, reste, currency),
            pw.SizedBox(height: 20),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ================= HEADER =================
  pw.Widget _buildHeader(
      String magasinName,
      String? adresse,
      pw.MemoryImage? logo,
      String invoiceType,
      String invoiceNumber) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              magasinName,
              style: _style(fontSize: 20, isBold: true, color: primaryColor),
            ),
            if (adresse != null && adresse.isNotEmpty)
              pw.Text(adresse, style: _style(fontSize: 9)),
            pw.Text(
              _getInvoiceTitle(invoiceType),
              style: _style(isBold: true),
            ),
            pw.Text(
              "رقم الفاتورة: $invoiceNumber",
              style: _style(fontSize: 10),
            ),
          ],
        ),
        if (logo != null)
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(logo),
          ),
      ],
    );
  }

  String _getInvoiceTitle(String type) {
    return type == "BLSC" ? "مذكرة تسليم" : "إيصال مبيعات";
  }

  // ================= CLIENT =================
  pw.Widget _buildClientInfo(Client client) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        color: lightGray,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(
            "معلومات العميل",
            style: _style(isBold: true, color: primaryColor),
          ),
          pw.SizedBox(height: 10),
          _row("الاسم", client.nom),
          _row("الهاتف", client.telephone),
          _row("الكود", client.code),
        ],
      ),
    );
  }

  pw.Widget _row(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(value, style: _style()),
        pw.Text(label, style: _style(isBold: true)),
      ],
    );
  }

  // ================= DETAILS =================
  pw.Widget _buildInvoiceDetails(CaisseState caisse, String caissierName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
      ),
      child: pw.Column(
        children: [
          _row("التاريخ", DateFormat('yyyy/MM/dd').format(caisse.date)),
          _row("أمين الصندوق", caissierName),
          _row("الدفع", caisse.modePaiement),
        ],
      ),
    );
  }

  // ================= TABLE =================
  pw.Widget _buildProductsTable(CaisseState caisse, String currency, String invoiceType) {
    // ✅ Le BL (BLSC) a besoin du code produit et du colis pour préparer la
    // livraison ; les autres types de facture gardent la table simplifiée.
    final showColisCode = invoiceType == "BLSC";

    return pw.Column(
      children: [
        // Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: pw.BoxDecoration(color: primaryColor),
          child: pw.Row(
            children: [
              _cell("المنتج", flex: showColisCode ? 2 : 3, bold: true, color: PdfColors.white, fontSize: 9),
              if (showColisCode) _cell("الطرد", bold: true, color: PdfColors.white, fontSize: 9),
              if (showColisCode) _cell("الكود", bold: true, color: PdfColors.white, fontSize: 9),
              _cell("الكمية", bold: true, color: PdfColors.white, fontSize: 9),
              _cell("السعر", bold: true, color: PdfColors.white, fontSize: 9),
              _cell("الإجمالي", bold: true, color: PdfColors.white, fontSize: 9),
            ],
          ),
        ),
        // Body
        ...caisse.produits.asMap().entries.map((entry) {
          final index = entry.key;
          final p = entry.value;
          return pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: pw.BoxDecoration(
              color: index % 2 == 0 ? lightGray : PdfColors.white,
              border: pw.Border(
                bottom: pw.BorderSide(color: borderColor),
              ),
            ),
            child: pw.Row(
              children: [
                _cell(p.nom, flex: showColisCode ? 2 : 3, fontSize: 9),
                if (showColisCode) _cell(p.colis.isEmpty ? "---" : p.colis, fontSize: 9),
                if (showColisCode) _cell(p.code, fontSize: 9),
                _cell(p.qte.toInt().toString(), fontSize: 9),
                pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        if (p.aRemise == true)
                          pw.Text(
                            "${NumberFormatUtil.formatMontant((p.prixOriginal as double), decimales: 2)} $currency",
                            textAlign: pw.TextAlign.right,
                            style: _style(
                              fontSize: 7,
                              color: PdfColors.grey,
                              decoration: pw.TextDecoration.lineThrough,
                            ),
                          ),
                        pw.Text(
                          "${NumberFormatUtil.formatMontant(p.prix, decimales: 2)} $currency",
                          textAlign: pw.TextAlign.right,
                          style: _style(fontSize: 9, color: p.aRemise == true ? PdfColors.red : null),
                        ),
                      ],
                    ),
                  ),
                ),
                _cell("${NumberFormatUtil.formatMontant((p.prix * p.qte), decimales: 2)} $currency", fontSize: 9),
              ],
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _cell(String text, {int flex = 1, bool bold = false, PdfColor? color, double fontSize = 12}) {
    return pw.Expanded(
      flex: flex,
      child: pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(
          text,
          textAlign: pw.TextAlign.right,
          style: _style(isBold: bold, color: color, fontSize: fontSize),
        ),
      ),
    );
  }

  // ================= TOTAL =================
  pw.Widget _buildTotalsSection(
      CaisseState caisse, double verse, double reste, String currency) {
    final hasRemise = caisse.remiseActive == true && caisse.remise > 0;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          if (hasRemise) ...[
            _row("المجموع قبل الخصم", "${NumberFormatUtil.formatMontant(caisse.totalAchat, decimales: 2)} $currency"),
            _row(
              (caisse.remisenom != null && caisse.remisenom!.isNotEmpty)
                  ? "الخصم (${caisse.remisenom})"
                  : "الخصم",
              "-${NumberFormatUtil.formatMontant(caisse.remise, decimales: 2)} $currency",
            ),
          ],
          _row("الإجمالي", "${NumberFormatUtil.formatMontant(caisse.total, decimales: 2)} $currency"),
          _row("المدفوع", "${NumberFormatUtil.formatMontant(verse, decimales: 2)} $currency"),
          _row("المتبقي", "${NumberFormatUtil.formatMontant(reste, decimales: 2)} $currency"),
        ],
      ),
    );
  }

  // ================= PAYMENT =================
  pw.Widget _buildPaymentInfo(double verse, double reste, String currency) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        "تم الدفع: ${NumberFormatUtil.formatMontant(verse, decimales: 2)} $currency | المتبقي: ${NumberFormatUtil.formatMontant(reste, decimales: 2)} $currency",
        style: _style(isBold: true),
        textAlign: pw.TextAlign.right,
      ),
    );
  }

  // ================= FOOTER =================
  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        "شكراً لزيارتكم",
        style: _style(isBold: true),
      ),
    );
  }

  // ================= UTIL =================
  static Future<Uint8List?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/logo.png');
      return data.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  static Future<File> savePDF(Uint8List pdfBytes, String fileName) async {
    final dir = await getExportDirectory();
    final file = File('${dir.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<void> openPDF(File file) async {
    await OpenFile.open(file.path);
  }

  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(onLayout: (format) async => pdfBytes);
  }
}