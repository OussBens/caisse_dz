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
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class PDFGeneratorLatin {
  static const PdfColor primaryColor = PdfColor(0.2, 0.4, 0.6);
  static const PdfColor accentColor = PdfColor(0.1, 0.3, 0.5);
  static const PdfColor textColor = PdfColor(0.1, 0.1, 0.1);
  static const PdfColor lightGray = PdfColor(0.95, 0.95, 0.95);
  static const PdfColor borderColor = PdfColor(0.8, 0.8, 0.8);

  static Future<Uint8List> generateInvoice({
    required CaisseState caisse,
    required Client client,
    required String magasinName,
    required String caissierName,
    required double verse,
    required double reste,
    required String invoiceNumber,
    required String invoiceType,
    required AppLocalizations l10n,
    String? adresse,
    Uint8List? logoBytes,
  }) async {
    final pdf = pw.Document();
    final currency = l10n.currency;

    // Logo boutique (fourni par l'appelant via LogoService), asset de repli sinon
    pw.MemoryImage? logo;
    try {
      final bytes = logoBytes ?? await _loadLogo();
      if (bytes != null) {
        logo = pw.MemoryImage(bytes);
      }
    } catch (e) {
      print('Logo loading error: $e');
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(magasinName, adresse, logo, invoiceType, invoiceNumber),
            pw.SizedBox(height: 20),
            _buildClientInfo(client, l10n),
            pw.SizedBox(height: 20),
            _buildInvoiceDetails(caisse, caissierName, l10n),
            pw.SizedBox(height: 20),
            _buildProductsTable(caisse, currency, invoiceType),
            pw.SizedBox(height: 20),
            _buildTotalsSection(caisse, verse, reste, currency),
            pw.SizedBox(height: 30),
            _buildPaymentInfo(verse, reste, currency, l10n),
            pw.SizedBox(height: 20),
            _buildFooter(l10n),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(
      String magasinName,
      String? adresse,
      pw.MemoryImage? logo,
      String invoiceType,
      String invoiceNumber,
      ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null)
          pw.Container(
            width: 80,
            height: 80,
            child: pw.Image(logo),
          ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                magasinName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: primaryColor,
                ),
              ),
              if (adresse != null && adresse.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(adresse, style: pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 8),
              pw.Text(
                _getInvoiceTitle(invoiceType),
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Number: $invoiceNumber',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now()),
              style: pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 4),
            pw.Container(
              padding: pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                _getInvoiceTypeLabel(invoiceType),
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _getInvoiceTitle(String invoiceType) {
    if (invoiceType == "BLSC") {
      return "Delivery Note";
    }
    return "Sales Receipt";
  }

  static String _getInvoiceTypeLabel(String invoiceType) {
    if (invoiceType == "BLSC") {
      return "BLSC";
    }
    return "INVOICE";
  }

  static pw.Widget _buildClientInfo(Client client, AppLocalizations l10n) {
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
        color: lightGray,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.clientInformation,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: primaryColor,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(l10n.clientName, client.nom),
                    pw.SizedBox(height: 8),
                    _buildInfoRow(l10n.clientCode, client.code),
                  ],
                ),
              ),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(l10n.phone, client.telephone),
                    pw.SizedBox(height: 8),
                    _buildInfoRow(l10n.email, client.email ?? '-'),
                  ],
                ),
              ),
            ],
          ),
          if (client.adresse != null && client.adresse!.isNotEmpty)
            pw.SizedBox(height: 8),
          if (client.adresse != null && client.adresse!.isNotEmpty)
            _buildInfoRow(l10n.address, client.adresse!),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Row(
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        pw.Text(
          '$label:',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(width: 4),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildInvoiceDetails(
      CaisseState caisse,
      String caissierName,
      AppLocalizations l10n,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildDetailItem(l10n.invoiceDate, DateFormat('dd/MM/yyyy').format(caisse.date)),
                pw.SizedBox(height: 8),
                _buildDetailItem(l10n.cashier, caissierName),
              ],
            ),
          ),
          pw.SizedBox(width: 24),
          pw.Expanded(
            child: pw.Column(
              children: [
                _buildDetailItem(l10n.paymentMethod, caisse.modePaiement),
                pw.SizedBox(height: 8),
                _buildDetailItem(l10n.register, caisse.caisse),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDetailItem(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          '$label:',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildProductsTable(
      CaisseState caisse,
      String currency,
      String invoiceType,
      ) {
    // ✅ Le BL (BLSC) a besoin du code produit et du colis pour préparer la
    // livraison ; les autres types de facture gardent la table simplifiée.
    final showColisCode = invoiceType == "BLSC";

    return pw.Container(
      child: pw.Column(
        children: [
          // Table Header
          pw.Container(
            padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: primaryColor,
              borderRadius: pw.BorderRadius.vertical(top: pw.Radius.circular(4)),
            ),
            child: pw.Row(
              children: [
                if (showColisCode) _buildTableHeaderCell("Code", flex: 1, alignment: pw.Alignment.center),
                _buildTableHeaderCell("Product", flex: showColisCode ? 2 : 3),
                if (showColisCode) _buildTableHeaderCell("Parcel", flex: 1, alignment: pw.Alignment.center),
                _buildTableHeaderCell("Quantity", flex: 1, alignment: pw.Alignment.center),
                _buildTableHeaderCell("Unit Price", flex: 1, alignment: pw.Alignment.center),
                _buildTableHeaderCell("Total", flex: 1, alignment: pw.Alignment.center),
              ],
            ),
          ),
          // Table Body
          ...caisse.produits.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: borderColor),
                  left: pw.BorderSide(color: borderColor),
                  right: pw.BorderSide(color: borderColor),
                ),
                color: index % 2 == 0 ? lightGray : PdfColors.white,
              ),
              child: pw.Row(
                children: [
                  if (showColisCode)
                    _buildTableCell(product.code, flex: 1, alignment: pw.Alignment.center),
                  _buildTableCell(product.nom, flex: showColisCode ? 2 : 3),
                  if (showColisCode)
                    _buildTableCell(
                      product.colis.isEmpty ? "---" : product.colis,
                      flex: 1,
                      alignment: pw.Alignment.center,
                    ),
                  _buildTableCell(
                    product.qte.toInt().toString(),
                    flex: 1,
                    alignment: pw.Alignment.center,
                  ),
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (product.aRemise == true)
                          pw.Text(
                            '${NumberFormatUtil.formatMontant((product.prixOriginal as double), decimales: 2)} $currency',
                            style: pw.TextStyle(
                              fontSize: 7,
                              color: PdfColors.grey,
                              decoration: pw.TextDecoration.lineThrough,
                            ),
                          ),
                        pw.Text(
                          '${NumberFormatUtil.formatMontant(product.prix, decimales: 2)} $currency',
                          style: pw.TextStyle(
                            fontSize: 9,
                            color: product.aRemise == true ? PdfColors.red : PdfColors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildTableCell(
                    '${NumberFormatUtil.formatMontant((product.prix * product.qte), decimales: 2)} $currency',
                    flex: 1,
                    alignment: pw.Alignment.center,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(
      String text, {
        int flex = 1,
        pw.Alignment alignment = pw.Alignment.centerLeft,
      }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.white,
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
      String text, {
        int flex = 1,
        pw.Alignment alignment = pw.Alignment.centerLeft,
      }) {
    return pw.Expanded(
      flex: flex,
      child: pw.Container(
        alignment: alignment,
        child: pw.Text(
          text,
          style: pw.TextStyle(fontSize: 9),
        ),
      ),
    );
  }

  static pw.Widget _buildTotalsSection(
      CaisseState caisse,
      double verse,
      double reste,
      String currency,
      ) {
    final hasRemise = caisse.remiseActive == true && caisse.remise > 0;
    return pw.Container(
      padding: pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: borderColor),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.SizedBox(width: 300),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (hasRemise) ...[
                      _buildTotalRow("Subtotal", caisse.totalAchat, currency),
                      pw.SizedBox(height: 4),
                      _buildTotalRow(
                        (caisse.remisenom != null && caisse.remisenom!.isNotEmpty)
                            ? "Discount (${caisse.remisenom})"
                            : "Discount",
                        -caisse.remise,
                        currency,
                        color: PdfColors.red,
                      ),
                      pw.SizedBox(height: 8),
                    ],
                    _buildTotalRow("Total", caisse.total, currency, isBold: true),
                    pw.SizedBox(height: 12),
                    pw.Divider(),
                    pw.SizedBox(height: 8),
                    _buildTotalRow("Paid", verse, currency),
                    _buildTotalRow("Remaining", reste, currency),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTotalRow(
      String label,
      double amount,
      String currency, {
        bool isBold = false,
        PdfColor? color,
      }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
        pw.Text(
          '${NumberFormatUtil.formatMontant(amount, decimales: 2)} $currency',
          style: pw.TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPaymentInfo(
      double verse,
      double reste,
      String currency,
      AppLocalizations l10n,
      ) {
    return pw.Container(
      padding: pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: lightGray,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            l10n.paymentDetails,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Row(
            children: [
              pw.Text(
                '${l10n.paid}: ${NumberFormatUtil.formatMontant(verse, decimales: 2)} $currency',
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              if (reste > 0) pw.SizedBox(width: 20),
              if (reste > 0)
                pw.Text(
                  '${l10n.remaining}: ${NumberFormatUtil.formatMontant(reste, decimales: 2)} $currency',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(AppLocalizations l10n) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.SizedBox(height: 20),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  l10n.receivedBy,
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '_________________________',
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  l10n.clientSignature,
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  l10n.cashierSignature,
                  style: pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  '_________________________',
                  style: pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 30),
        pw.Text(
          l10n.thankYou,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          l10n.seeYouSoon,
          style: pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static Future<Uint8List?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      return data.buffer.asUint8List();
    } catch (e) {
      print('Logo not found: $e');
      return null;
    }
  }

  static Future<File> savePDF(Uint8List pdfBytes, String fileName) async {
    final directory = await getExportDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  static Future<void> openPDF(File file) async {
    await OpenFile.open(file.path);
  }

  static Future<void> printPDF(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
    );
  }
}