import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

class PDFPreviewDialog extends StatefulWidget {
  final Uint8List pdfBytes;
  final AppLocalizations l10n;
  final VoidCallback onPrint;
  final VoidCallback onSave;
  final VoidCallback onShare;
  final VoidCallback onCancel;

  const PDFPreviewDialog({
    Key? key,
    required this.pdfBytes,
    required this.l10n,
    required this.onPrint,
    required this.onSave,
    required this.onShare,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<PDFPreviewDialog> createState() => _PDFPreviewDialogState();
}

class _PDFPreviewDialogState extends State<PDFPreviewDialog> {
  int _remainingSeconds = 10;
  bool _autoPrint = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 1) {
          _remainingSeconds--;
        } else {
          _timer?.cancel();
          if (_autoPrint && mounted) {
            widget.onPrint();
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
      ),
      child: Container(
        width: 800,
        height: 700,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.picture_as_pdf, color: Appstyle.violet, size: 28),
                const SizedBox(width: 8),
                Text(
                  widget.l10n.invoicePreview,
                  style: Appstyle.textLB.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _timer?.cancel();
                    widget.onCancel();
                  },
                ),
              ],
            ),
            const Divider(),

            // Timer and auto-print info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Appstyle.violet.withOpacity(0.1),
                borderRadius: BorderRadius.circular(Appstyle.radiusSM),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer,
                    color: Appstyle.violet,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _autoPrint
                          ? widget.l10n.autoPrintIn(_remainingSeconds)
                          : widget.l10n.autoPrintDisabled,
                      style: Appstyle.textSB.copyWith(
                        color: Appstyle.violet,
                      ),
                    ),
                  ),
                  Switch(
                    value: _autoPrint,
                    onChanged: (value) {
                      setState(() {
                        _autoPrint = value;
                        if (value && _timer == null) {
                          _remainingSeconds = 10;
                          _startTimer();
                        } else if (!value && _timer != null) {
                          _timer?.cancel();
                          _timer = null;
                        }
                      });
                    },
                    activeColor: Appstyle.violet,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // PDF Preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Appstyle.grisC),
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  child: PdfPreview(
                    build: (format) => Future.value(widget.pdfBytes),
                    allowPrinting: false,
                    allowSharing: false,
                    initialPageFormat: PdfPageFormat.a4,
                    padding: const EdgeInsets.all(8),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MainButton(
                  text: widget.l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () {
                    _timer?.cancel();
                    widget.onCancel();
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: widget.l10n.save,
                  color: Appstyle.success,
                  icon: Icons.save,
                  onPressed: () {
                    _timer?.cancel();
                    widget.onSave();
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: widget.l10n.share,
                  color: Appstyle.warning,
                  icon: Icons.share,
                  onPressed: () {
                    _timer?.cancel();
                    widget.onShare();
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: widget.l10n.printNow,
                  color: Appstyle.violet,
                  icon: Icons.print,
                  onPressed: () {
                    _timer?.cancel();
                    widget.onPrint();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}