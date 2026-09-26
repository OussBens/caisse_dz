import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/radio_champ.dart';
import 'package:caisse_dz/core/widget/qr_code_avec_impression.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Génère un code barre automatique (QR code) pour un produit qui n'en
/// possède pas physiquement. Une fois généré, le code est écrit dans
/// [barcodeController] et le champ associé doit être désactivé par l'appelant.
class ProduitBarcodeGenerator extends StatefulWidget {
  final TextEditingController barcodeController;
  final bool sansCodeBar;
  final ValueChanged<bool> onSansCodeBarChanged;

  const ProduitBarcodeGenerator({
    super.key,
    required this.barcodeController,
    required this.sansCodeBar,
    required this.onSansCodeBarChanged,
  });

  @override
  State<ProduitBarcodeGenerator> createState() => _ProduitBarcodeGeneratorState();
}

class _ProduitBarcodeGeneratorState extends State<ProduitBarcodeGenerator> {
  bool _generating = false;

  Future<void> _genererCode() async {
    setState(() => _generating = true);
    final code = await ProduitServices.generateAutoBarcode();
    widget.barcodeController.text = code;
    if (mounted) setState(() => _generating = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final code = widget.barcodeController.text.trim();
    final hasCode = code.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ChampAvecLabel(
          distance: 200,
          label: l10n.noBarcodeProduct,
          alignmentStart: true,
          child: TextRadio(
            value: widget.sansCodeBar,
            onChanged: (v) => widget.onSansCodeBarChanged(v ?? false),
          ),
        ),
        if (widget.sansCodeBar) ...[
          const SizedBox(height: 10),
          if (!hasCode)
            MainButton(
              text: l10n.generateBarcode,
              icon: Icons.qr_code,
              color: Appstyle.violet,
              onPressed: _generating ? null : _genererCode,
            )
          else
            QrCodeAvecImpression(code: code),
        ],
      ],
    );
  }
}
