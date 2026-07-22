import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

class TextChampS extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool enabled;
  final bool numeric;

  const TextChampS({
    super.key,
    required this.controller,
    required this.hint,
    this.enabled = true,
    this.numeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 40, // ✅ réduire ici (ex: 28 ou 26)
      padding: const EdgeInsets.symmetric(horizontal: 8), // pas de padding vertical
      decoration: BoxDecoration(
        color: enabled ? Appstyle.grischamp : Appstyle.grisC,
        borderRadius: BorderRadius.circular(10), // optionnel: réduire aussi
      ),
      alignment: Alignment.center, // ✅ centre verticalement
      child: TextField(
        controller: controller,
        enabled: enabled,
        keyboardType:
        numeric ? TextInputType.number : TextInputType.text,
        inputFormatters:
        numeric ? [FilteringTextInputFormatter.digitsOnly] : null,

        style: Appstyle.textS.copyWith(
          fontSize: 12, // ✅ important pour réduire hauteur
          height: 1.0,  // ✅ supprime espace vertical du texte
          color: enabled ? Appstyle.Tnoir : Appstyle.TgrisC,
        ),

        decoration: InputDecoration(
          isCollapsed: true, // ✅ TRÈS IMPORTANT
          border: InputBorder.none,
          hintText: hint,
          hintStyle: Appstyle.textS.copyWith(
            fontSize: 12,
            height: 1.0,
            color: enabled ? Appstyle.Tnoir : Appstyle.TgrisC,
          ),
          contentPadding: EdgeInsets.zero, // ✅ supprime padding interne
        ),
      ),
    );
  }
}
