
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextRadio extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final bool auto;

  /// ✔️ nouveau paramètre
  final bool enabled;

  const TextRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.auto = false,
    this.enabled = true, // par défaut actif
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        GestureDetector(
          onTap: enabled ? () => onChanged(!value) : null,   // ❌ cliqué si disabled
          child: Opacity(
            opacity: enabled ? 1.0 : 0.5,  // 👁️ effet visuel disabled
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Appstyle.grischamp,
                borderRadius: BorderRadius.circular(Appstyle.radiusButton),
              ),
              child: Transform.scale(
                scale: 0.8,
                child:  Switch(
                  value: value,
                  onChanged: enabled ? onChanged : null,  // ❌ bloque changement
                ),
              ),
            ),
          ),
        ),
        if (auto) ...[
          const SizedBox(width: 26),
          Text(
            "(${l10n.auto})",  // 🔥 Translated
            style: Appstyle.textS.copyWith(color: Appstyle.ink500),
          ),
        ],
      ],
    );
  }
}