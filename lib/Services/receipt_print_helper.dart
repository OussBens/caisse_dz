import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:printing/printing.dart';

import '../core/dialog/information_dialog.dart';
import '../data/models/imprimanteParam.dart';
import '../l10n/app_localizations.dart';
import 'ReceiptPreviewDialog.dart';
import 'printer_manager.dart';

/// Marqueur inséré par les générateurs de reçu (ReceiptLatin/ReceiptArabic)
/// à l'endroit où le code-barres du pannier doit être imprimé. Le texte du
/// reçu reste un simple texte monospace ; c'est ce fichier qui remplace le
/// marqueur par un vrai code-barres (commande ESC/POS ou widget graphique)
/// selon le type d'imprimante ciblé.
const String barcodeMarker = '__BARCODE__';

/// Découpe le texte du reçu de part et d'autre du [barcodeMarker].
(String before, String after) _splitAtBarcode(String receiptText) {
  final markerLine = '$barcodeMarker\n';
  final idx = receiptText.indexOf(markerLine);
  if (idx == -1) return (receiptText, '');
  return (
    receiptText.substring(0, idx),
    receiptText.substring(idx + markerLine.length),
  );
}

/// Construit un PDF au format rouleau (58/80mm) à partir du texte du ticket,
/// avec un vrai code-barres CODE128 (widget graphique) inséré à la place du
/// [barcodeMarker]. Utilisé à la fois pour l'aperçu (rastérisé en image) et
/// pour l'impression via une imprimante Windows "normale" (spouleur natif).
Future<Uint8List> _buildTicketPdfBytes(
  String receiptText,
  String barcodeData,
  int largeurRouleauMm,
) async {
  final (before, after) = _splitAtBarcode(receiptText);

  final pdf = pw.Document();
  const marginMm = 2.5;
  final pageFormat = PdfPageFormat(
    largeurRouleauMm * PdfPageFormat.mm,
    double.infinity,
    marginAll: marginMm * PdfPageFormat.mm,
  );
  final contentWidth = pageFormat.width - (marginMm * PdfPageFormat.mm * 2);
  final textStyle = pw.TextStyle(font: pw.Font.courier(), fontSize: 8.5);

  pdf.addPage(
    pw.Page(
      pageFormat: pageFormat,
      build: (pw.Context ctx) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(before, style: textStyle),
            if (after.isNotEmpty)
              pw.Center(
                child: pw.BarcodeWidget(
                  data: barcodeData,
                  barcode: pw.Barcode.code128(),
                  width: contentWidth * 0.85,
                  height: 45,
                  drawText: false,
                ),
              ),
            if (after.isNotEmpty) pw.Text(after, style: textStyle),
          ],
        );
      },
    ),
  );

  return pdf.save();
}

/// Rastérise le PDF du ticket en image PNG, pour l'aperçu avant impression.
Future<Uint8List> _buildTicketPreviewImage(
  String receiptText,
  String barcodeData,
  int largeurRouleauMm,
) async {
  final pdfBytes = await _buildTicketPdfBytes(receiptText, barcodeData, largeurRouleauMm);
  final page = await Printing.raster(pdfBytes, pages: [0], dpi: 203).first;
  return page.toPng();
}

/// Affiche l'aperçu d'un reçu thermique puis l'imprime sur l'imprimante
/// configurée (USB/réseau/normale/bluetooth). Partagé entre l'encaissement
/// d'un ticket et la réimpression d'un ticket déjà enregistré.
///
/// [barcodeData] est la valeur encodée dans le code-barres CODE128 imprimé
/// à la place du [barcodeMarker] (le code du pannier, ex. "PN0000001").
Future<void> imprimerRecuThermique({
  required BuildContext context,
  required String receiptText,
  required String barcodeData,
  required AppLocalizations l10n,
  required ImprimanteParam imprimanteParam,
}) async {
  final receiptImage = await _buildTicketPreviewImage(
    receiptText,
    barcodeData,
    imprimanteParam.largeurRouleau,
  );

  bool isDialogActive = true;

  final shouldPrint = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (previewContext) {
      return ReceiptPreviewDialog(
        receiptImage: receiptImage,
        l10n: l10n,
        onPrint: () {
          isDialogActive = false;
          Navigator.pop(previewContext, true);
        },
        onCancel: () {
          isDialogActive = false;
          Navigator.pop(previewContext, false);
        },
      );
    },
  );

  if (shouldPrint != true || !isDialogActive) return;
  if (!context.mounted) return;

  final loadingContext = context;
  showDialog(
    context: loadingContext,
    barrierDismissible: false,
    builder: (loadingContext) => const Center(
      child: CircularProgressIndicator(),
    ),
  );

  try {
    final printerManager = PrinterManager();
    bool printed = false;

    // Chaîne d'octets brute (texte + commande ESC/POS native pour le
    // code-barres) utilisée par les 3 modes d'impression directe.
    List<int> buildRawBytes() {
      final (before, after) = _splitAtBarcode(receiptText);
      return <int>[
        ...utf8.encode(before),
        if (after.isNotEmpty) ...printerManager.buildBarcodeBytes(barcodeData),
        ...utf8.encode(after),
      ];
    }

    switch (imprimanteParam.typeImprimante) {
      case TypeImprimante.usb:
        final printerName = imprimanteParam.nomImprimante;
        if (printerName == null || printerName.isEmpty) {
          throw Exception(l10n.noPrinterFound);
        }
        printed = await printerManager.printRawToWindowsPrinter(printerName, buildRawBytes());
        break;

      case TypeImprimante.reseau:
        final ip = imprimanteParam.adresseIp;
        if (ip == null || ip.isEmpty) {
          throw Exception(l10n.noPrinterFound);
        }
        printed = await printerManager.printRawToNetworkPrinter(
          ip,
          imprimanteParam.port ?? 9100,
          buildRawBytes(),
        );
        break;

      case TypeImprimante.normale:
        final printerName = imprimanteParam.nomImprimante;
        if (printerName == null || printerName.isEmpty) {
          throw Exception(l10n.noPrinterFound);
        }
        final winPrinters = await Printing.listPrinters();
        Printer? windowsPrinter;
        for (final p in winPrinters) {
          if (p.name == printerName) {
            windowsPrinter = p;
            break;
          }
        }
        if (windowsPrinter == null) {
          throw Exception(l10n.noPrinterFound);
        }
        final pdfBytes = await _buildTicketPdfBytes(
          receiptText,
          barcodeData,
          imprimanteParam.largeurRouleau,
        );
        printed = await Printing.directPrintPdf(
          printer: windowsPrinter,
          onLayout: (_) async => pdfBytes,
        );
        break;

      case TypeImprimante.bluetooth:
      default:
        final bluetoothEnabled = await printerManager.initBluetooth();
        if (!bluetoothEnabled) {
          throw Exception(l10n.bluetoothDisabled);
        }

        // Reconnexion directe si un appareil a déjà été enregistré dans les
        // paramètres, pour éviter de redemander à chaque ticket.
        final savedMac = imprimanteParam.macBluetooth;
        if (savedMac != null && savedMac.isNotEmpty) {
          if (await printerManager.connect(savedMac)) {
            printed = await printerManager.print(buildRawBytes());
            await printerManager.disconnect();
          }
        }

        if (!printed) {
          final printers = await printerManager.getBondedPrinters();
          if (printers.isEmpty) {
            throw Exception(l10n.noPrinterFound);
          }

          BluetoothInfo? selectedPrinter;
          if (printers.length == 1) {
            selectedPrinter = printers.first;
          } else {
            Navigator.pop(loadingContext);

            selectedPrinter = await showDialog<BluetoothInfo>(
              context: loadingContext,
              builder: (context) => SimpleDialog(
                title: Text(l10n.selectPrinter),
                children: printers.map((printer) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(context, printer),
                  child: Text(printer.name),
                )).toList(),
              ),
            );

            if (selectedPrinter != null) {
              showDialog(
                context: loadingContext,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
          }

          if (selectedPrinter == null) {
            if (Navigator.canPop(loadingContext)) {
              Navigator.pop(loadingContext);
            }
            return;
          }

          final connected = await printerManager.connect(selectedPrinter.macAdress);
          if (!connected) {
            throw Exception(l10n.connectionFailed);
          }

          printed = await printerManager.print(buildRawBytes());
          await printerManager.disconnect();
        }
    }

    if (!printed) {
      throw Exception(l10n.printFailed);
    }

    if (Navigator.canPop(loadingContext)) {
      Navigator.pop(loadingContext);
    }

    await InformationDialog(
      context: context,
      titre_type_message: l10n.success,
      titre_concerne: l10n.ticket,
      message: l10n.ticketPrintedSuccess,
    );
  } catch (e) {
    if (Navigator.canPop(loadingContext)) {
      Navigator.pop(loadingContext);
    }
    await InformationDialog(
      context: context,
      titre_type_message: l10n.attention,
      titre_concerne: l10n.print,
      message: l10n.printError,
    );
  }
}
