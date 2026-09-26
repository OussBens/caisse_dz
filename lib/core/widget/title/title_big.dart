
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class TitleBig extends StatelessWidget {
  final String imagePath;
  final String text;
  final double imageSize;
  final Color couleur;
  final bool iconRight;
  final double textsize;// 👈 nouveau paramètre

  const TitleBig({
    super.key,
    required this.imagePath,
    required this.text,
    this.imageSize = 24,
    this.textsize = 28, // 👈 valeur par défaut
    required this.couleur,
    this.iconRight = false, // 👈 valeur par défaut
  });

  @override
  Widget build(BuildContext context) {
    // Le widget image
    final iconWidget = Image.asset(
      imagePath,
      width: imageSize,
      height: imageSize,
      color: couleur,
      colorBlendMode: BlendMode.srcIn,
    );

    // Le widget texte
    final textWidget = Text(
      text,
      style: Appstyle.textLB.copyWith(color: couleur,fontSize: textsize),
    );

    return Row(
      children: iconRight
          ? [
        // Texte d'abord
        textWidget,
        const SizedBox(width: 12),
        // Icône à droite
        iconWidget,
      ]
          : [
        // Icône à gauche
        iconWidget,
        const SizedBox(width: 12),
        // Texte après
        textWidget,
      ],
    );
  }
}
