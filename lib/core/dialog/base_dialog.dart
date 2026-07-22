import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

class BaseDialog extends StatefulWidget {
  final Widget header;
  final Widget content;
  final Widget footer;
  final double width;
  final double? height;
  final EdgeInsets padding;
  final Color? couleur;

  const BaseDialog({
    super.key,
    required this.header,
    required this.content,
    required this.footer,
    this.width = 500,
    this.height,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
    this.couleur = Colors.white,
  });

  @override
  State<BaseDialog> createState() => _BaseDialogState();
}

class _BaseDialogState extends State<BaseDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(30),
      backgroundColor: widget.couleur,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        width: widget.width,
        height: widget.height,
        padding: widget.padding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            widget.header,
            const SizedBox(height: 20),
            Flexible(child: widget.content),
            const SizedBox(height: 20),
            widget.footer,
          ],
        ),
      ),
    );
  }
}