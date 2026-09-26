import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart' as bw;
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum TypeCodeGenere { qrCode, codeBarre }

/// Affiche un QR code ou un code barre (au choix) encodant [code], et un
/// bouton pour l'imprimer (PDF). Réutilisé partout où un code barre
/// auto-généré doit être montré/imprimé (création/modification de produit,
/// fiche produit en lecture seule). La configuration (taille, sous-label,
/// impression) reste identique quel que soit le type choisi : seul le
/// rendu visuel change.
class QrCodeAvecImpression extends StatefulWidget {
  final String code;
  final double taille;
  final String? sousLabel;
  final bool afficherImpression;

  const QrCodeAvecImpression({
    super.key,
    required this.code,
    this.taille = 120,
    this.sousLabel,
    this.afficherImpression = true,
  });

  @override
  State<QrCodeAvecImpression> createState() => _QrCodeAvecImpressionState();
}

class _QrCodeAvecImpressionState extends State<QrCodeAvecImpression> {
  TypeCodeGenere _type = TypeCodeGenere.qrCode;

  Future<void> _imprimer() async {
    final pdf = pw.Document();

    if (_type == TypeCodeGenere.qrCode) {
      final painter = QrPainter(
        data: widget.code,
        version: QrVersions.auto,
        gapless: true,
      );
      final imageData = await painter.toImageData(600);
      if (imageData == null) return;
      final Uint8List pngBytes = imageData.buffer.asUint8List();

      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.Image(pw.MemoryImage(pngBytes), width: 220, height: 220),
                  pw.SizedBox(height: 12),
                  pw.Text(widget.code, style: const pw.TextStyle(fontSize: 14)),
                  if (widget.sousLabel != null && widget.sousLabel!.isNotEmpty) ...[
                    pw.SizedBox(height: 4),
                    pw.Text(widget.sousLabel!, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ],
              ),
            );
          },
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          build: (pw.Context ctx) {
            return pw.Center(
              child: pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.center,
                children: [
                  pw.BarcodeWidget(
                    data: widget.code,
                    barcode: pw.Barcode.code128(),
                    width: 260,
                    height: 100,
                    drawText: true,
                  ),
                  if (widget.sousLabel != null && widget.sousLabel!.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(widget.sousLabel!, style: const pw.TextStyle(fontSize: 11)),
                  ],
                ],
              ),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  Widget _choixType(String label, IconData icone, TypeCodeGenere type) {
    final bool selectionne = _type == type;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 16, color: selectionne ? Colors.white : Appstyle.gris),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12)),
        ],
      ),
      selected: selectionne,
      onSelected: (_) => setState(() => _type = type),
      selectedColor: Appstyle.violet,
      labelStyle: TextStyle(color: selectionne ? Colors.white : Appstyle.Tnoir),
      backgroundColor: Colors.grey[200],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _choixType("QR Code", Icons.qr_code, TypeCodeGenere.qrCode),
            _choixType(l10n.barcode, Icons.view_week, TypeCodeGenere.codeBarre),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Appstyle.grisC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_type == TypeCodeGenere.qrCode)
                QrImageView(
                  data: widget.code,
                  version: QrVersions.auto,
                  size: widget.taille,
                  gapless: true,
                  backgroundColor: Colors.white,
                )
              else
                bw.BarcodeWidget(
                  data: widget.code,
                  barcode: bw.Barcode.code128(),
                  width: widget.taille * 1.6,
                  height: widget.taille * 1,
                  drawText: true,
                ),
              if (widget.sousLabel != null && widget.sousLabel!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.sousLabel!,
                  style: Appstyle.textS.copyWith(color: Appstyle.gris),
                ),
              ],
            ],
          ),
        ),
        if (widget.afficherImpression) ...[
          const SizedBox(height: 10),
          MainButton(
            text: l10n.print,
            icon: Icons.print,
            color: Appstyle.indigo,
            onPressed: _imprimer,
          ),
        ],
      ],
    );
  }
}
