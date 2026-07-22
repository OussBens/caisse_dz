
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class TitleSmall extends StatelessWidget {
  final String imagePath;
  final String text;
  final double imageSize;
  final Color couleur;
  final bool iconRight;
  final double opacity;
  final bool italic; // ⭐ NOUVEAU

  const TitleSmall({
    super.key,
    required this.imagePath,
    required this.text,
    this.imageSize = 20,
    required this.couleur,
    this.iconRight = false,
    this.opacity = 1.0,
    this.italic = false, // ⭐ par défaut normal
  });

  @override
  Widget build(BuildContext context) {
    final iconWidget = Image.asset(
      imagePath,
      width: imageSize,
      height: imageSize,
      color: couleur.withOpacity(opacity),
      colorBlendMode: BlendMode.srcIn,
    );

    final textWidget = Text(
      text,
      style: Appstyle.textLB.copyWith(
        color: couleur.withOpacity(opacity),
        fontStyle: italic ? FontStyle.italic : FontStyle.normal, // ⭐ ICI
      ),
    );

    return Opacity(
      opacity: opacity,
      child: Row(
        children: iconRight
            ? [
          textWidget,
          const SizedBox(width: 12),
          iconWidget,
        ]
            : [
          iconWidget,
          const SizedBox(width: 12),
          textWidget,
        ],
      ),
    );
  }
}
