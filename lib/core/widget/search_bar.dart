
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final Function(String)? onChanged;

  const SearchField({
    super.key,
    required this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Get localization
    final l10n = AppLocalizations.of(context)!;

    return Container(
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Appstyle.radiusButton),
        boxShadow: [
          BoxShadow(
            color: Appstyle.shadowTint.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: l10n.search, // 🔥 Translated hint
          hintStyle: TextStyle(
            color: Appstyle.neutral500,
          ),

          /// 🔍 Icone gauche
          prefixIcon: Icon(
            Icons.search_rounded,
            color: Appstyle.violet,
          ),

          /// ❌ bouton clear automatique
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () {
              controller.clear();
              onChanged?.call("");
            },
          )
              : null,

          filled: true,
          fillColor: Colors.white,

          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),

          /// Bordures modernes
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            borderSide: BorderSide.none,
          ),

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            borderSide: BorderSide(
              color: Appstyle.neutral200,
            ),
          ),

          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            borderSide: BorderSide(
              color: Appstyle.violet,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}