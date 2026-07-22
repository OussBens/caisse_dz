import 'package:caisse_dz/core/locale/locale_provider.dart';

import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PiedRecap extends StatelessWidget {
  final String remise;
  final String total;

  const PiedRecap({
    super.key,
    required this.remise,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final local = context.watch<LocaleProvider>();
    final isRTL = local.locale.languageCode == 'ar';
    final textDirection = isRTL ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: textDirection,
      child: Column(
        children: [
          Container(
            height: 3,
            color: Appstyle.gris,
          ),
          const SizedBox(width: 12),
          // Texte à droite
          Row(
            textDirection: textDirection,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  l10n.remise,
                  style: Appstyle.textMB.copyWith(color: Appstyle.TgrisC)
              ),
              Text(
                  remise,
                  style: Appstyle.textMB.copyWith(color: Appstyle.Tnoir)
              ),
            ],
          ),
          Row(
            textDirection: textDirection,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  l10n.total,
                  style: Appstyle.textMB.copyWith(color: Appstyle.TgrisC)
              ),
              Text(
                  total,
                  style: Appstyle.textMB.copyWith(color: Appstyle.Tnoir)
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Ligne en bas
        ],
      ),
    );
  }
}