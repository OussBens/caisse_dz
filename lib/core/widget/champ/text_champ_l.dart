
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TextChampL extends StatelessWidget {

  final String hint;
  final TextEditingController controller;
  final bool enabled;
  final bool numeric;
  final double? maxValue; // ✅ nouveau
  final ValueChanged<String>? onChanged;
  final Color color;
  final Color colorEnabled;
  final int maxLines;
  final bool obligatoire;
  final String? Function(String?)? validator;
  final double? width;
  final bool obscureText;

  // ✅ Champ quantité : restreint la saisie au nombre de décimales défini
  // dans Paramètres > Système (QuantiteFormat), au lieu du nombre de
  // décimales libre habituel des champs numériques (prix, montant...).
  final bool isQuantite;
  // Unité du produit pour un champ quantité : 'Pièce' => entier uniquement
  // (voir QuantiteFormat.decimalesPour). null => réglage système.
  final String? uniteMesure;

  const TextChampL({
    super.key,
    required this.hint,
    required this.controller,
    this.enabled = true,
    this.numeric = false,
    this.maxValue, // ✅ nouveau
    this.onChanged,
    this.color = Appstyle.grisSC,
    this.colorEnabled = Appstyle.grisC,
    this.maxLines = 1,
    this.obligatoire = false,
    this.validator,
    this.width=350,
    this.obscureText = false,
    this.isQuantite = false,
    this.uniteMesure,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool isMultiLine = maxLines > 1;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final bool isFilled = enabled && value.text.trim().isNotEmpty;

        return SizedBox(
      width: width,
      child: Container(

        height: isMultiLine ? null : 40,

        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: isMultiLine ? 8 : 0,
        ),

        alignment:
        isMultiLine ? Alignment.topLeft : Alignment.centerLeft,

        decoration: BoxDecoration(
          color: enabled ? color : colorEnabled,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFilled ? Appstyle.violet : Colors.grey.shade300,
            width: isFilled ? 1.5 : 1,
          ),
        ),

        child: TextFormField(

          controller: controller,

          enabled: enabled,

          obscureText: obscureText,

          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : isMultiLine
              ? TextInputType.multiline
              : TextInputType.text,

          // ✅ autoriser double (nombre de décimales configurable pour les
          // champs quantité, libre pour les autres champs numériques)
          inputFormatters: numeric
              ? (isQuantite
                  ? QuantiteFormat.inputFormattersPour(uniteMesure)
                  : [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d*'),
                      ),
                    ])
              : null,

          maxLines: maxLines,

          style: Appstyle.textSB.copyWith(
            fontSize: 13,
            height: 1.0,
            color: enabled ? Appstyle.Tnoir : Appstyle.TgrisF,
          ),

          decoration: InputDecoration(
            isCollapsed: !isMultiLine,
            contentPadding: EdgeInsets.zero,
            border: InputBorder.none,
            hintText: hint,  // Pass translated hint from parent
            hintStyle: Appstyle.textS.copyWith(
              fontSize: 13,
              height: 1.0,
              color: Appstyle.TgrisF,
            ),
          ),

          onChanged: (value) {

            if (numeric && maxValue != null && value.isNotEmpty) {

              final number = double.tryParse(value);

              if (number != null && number > maxValue!) {

                controller.text = maxValue!.toString();

                controller.selection =
                    TextSelection.fromPosition(
                      TextPosition(
                        offset: controller.text.length,
                      ),
                    );

                return;
              }

            }

            if (onChanged != null) {
              onChanged!(value);
            }

          },

          validator: (value) {

            if (obligatoire &&
                (value == null || value.trim().isEmpty)) {
              return l10n.requiredField;  // 🔥 Translated
            }

            if (numeric &&
                maxValue != null &&
                value != null &&
                value.isNotEmpty) {

              final number = double.tryParse(value);

              if (number != null && number > maxValue!) {
                return "${l10n.max}: $maxValue";  // 🔥 Translated: "Max: 1000"
              }

            }

            if (validator != null &&
                value != null &&
                value.trim().isNotEmpty) {
              return validator!(value);
            }

            return null;
          },

        ),

      ),
    );
      },
    );
  }

}