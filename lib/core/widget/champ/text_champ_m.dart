import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
class TextChampM extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool numeric;

  const TextChampM({
    super.key,
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 40, // ✅ réduit la hauteur (ex: 28 ou 26)
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center, // ✅ centre verticalement
      decoration: BoxDecoration(
        color: enabled ? Appstyle.grischamp : Appstyle.grisC,
        borderRadius: BorderRadius.circular(Appstyle.radiusMD), // optionnel
        border: Border.all(color: Appstyle.neutral200, width: 1),
      ),
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType:
        numeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
        numeric ? [FilteringTextInputFormatter.digitsOnly] : null,

        style: Appstyle.textS.copyWith(
          fontSize: 12,   // ✅ réduit hauteur texte
          height: 1.0,    // ✅ supprime espace vertical interne
          color: enabled ? Appstyle.Tnoir : Appstyle.TgrisC,
        ),

        decoration: InputDecoration(
          isCollapsed: true,              // ✅ essentiel
          contentPadding: EdgeInsets.zero, // ✅ supprime padding interne
          border: InputBorder.none,
          hintText: hint,
          hintStyle: Appstyle.textS.copyWith(
            fontSize: 12,
            height: 1.0,
            color: enabled ? Appstyle.Tnoir : Appstyle.TgrisC,
          ),
        ),
      ),
    );
  }
}
