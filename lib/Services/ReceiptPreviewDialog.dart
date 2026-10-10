import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';

class ReceiptPreviewDialog extends StatefulWidget {
  final Uint8List receiptImage;
  final AppLocalizations l10n;
  final VoidCallback onPrint;
  final VoidCallback onCancel;

  const ReceiptPreviewDialog({
    Key? key,
    required this.receiptImage,
    required this.l10n,
    required this.onPrint,
    required this.onCancel,
  }) : super(key: key);

  @override
  State<ReceiptPreviewDialog> createState() => _ReceiptPreviewDialogState();
}

class _ReceiptPreviewDialogState extends State<ReceiptPreviewDialog> {
  int _remainingSeconds = 5;
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
        width: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.receipt, color: Appstyle.violet),
                const SizedBox(width: 8),
                Text(
                  widget.l10n.ticketPreview,
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
                          _remainingSeconds = 5;
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

            // Receipt image preview
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Appstyle.grisC),
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                  child: Image.memory(
                    widget.receiptImage,
                    fit: BoxFit.contain,
                    width: double.infinity,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
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