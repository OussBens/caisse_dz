
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class TextDate extends StatelessWidget {
  final String hint;
  final TextEditingController controller;
  final VoidCallback onTap;
  final bool enabled;
  final bool obligatoire;
  final double width;

  const TextDate({
    super.key,
    required this.hint,
    required this.controller,
    required this.onTap,
    this.enabled = true,
    this.obligatoire = false,
    this.width = 300,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final bool isFilled = enabled && value.text.trim().isNotEmpty;

        return SizedBox(
      width: width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// 🔹 Champ date
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.white
                  : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFilled
                    ? Appstyle.violet
                    : enabled
                        ? Colors.grey.shade300
                        : Colors.grey.shade400,
                width: isFilled ? 1.5 : 1,
              ),
              boxShadow: enabled
                  ? [
                BoxShadow(
                  color: isFilled
                      ? Appstyle.violet.withOpacity(0.15)
                      : Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
                  : [],
            ),
            child: GestureDetector(
              onTap: enabled ? onTap : null,
              child: AbsorbPointer(
                child: TextFormField(
                  controller: controller,
                  readOnly: true,
                  enabled: enabled,
                  style: TextStyle(
                    color: enabled
                        ? Colors.black87
                        : Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,

                    /// padding interne
                    contentPadding:
                    const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),

                    /// icone calendrier
                    prefixIcon: Icon(
                      Icons.calendar_today_rounded,
                      size: 18,
                      color: enabled
                          ? Appstyle.violet
                          : Colors.grey,
                    ),

                    hintText: "${l10n.select} $hint",  // 🔥 Changed: "Sélectionner" → l10n.select
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                  validator: (value) {
                    if (obligatoire &&
                        (value == null ||
                            value.trim().isEmpty)) {
                      return l10n.requiredField;  // 🔥 Changed: "Champ obligatoire" → l10n.requiredField
                    }
                    return null;
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}