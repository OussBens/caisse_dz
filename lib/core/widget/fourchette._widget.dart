import 'package:caisse_dz/core/locale/locale_provider.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class FourchettePrixWidget extends StatelessWidget {
  final Color couleur;
  final double? minValue;
  final double? maxValue;
  final Function(double?, double?) onChanged;

  const FourchettePrixWidget({
    super.key,
    required this.couleur,
    this.minValue,
    this.maxValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return InkWell(
      onTap: () => _openBottomSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: couleur.withOpacity(.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: couleur, width: 1),
        ),
        child: Row(
          textDirection: textDirection,
          children: [
            Icon(Icons.filter_alt, color: couleur),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                minValue == null && maxValue == null
                    ? l10n.exampleRange
                    : " ${minValue ?? 0} → ${maxValue ?? 0}",
                style: Appstyle.textS.copyWith(color: Appstyle.Tnoir),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.black),
          ],
        ),
      ),
    );
  }

  void _openBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    TextEditingController minCtrl =
    TextEditingController(text: minValue?.toString() ?? '');
    TextEditingController maxCtrl =
    TextEditingController(text: maxValue?.toString() ?? '');

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Directionality(
          textDirection: textDirection,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  textDirection: textDirection,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.min,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.max,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                MainButton(
                  text: l10n.validate,
                  color: Appstyle.violet,
                  onPressed: () {
                    double? min = double.tryParse(minCtrl.text);
                    double? max = double.tryParse(maxCtrl.text);
                    onChanged(min, max);
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          ),
        );
      },
    );
  }
}