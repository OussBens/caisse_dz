import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class MainButton extends StatelessWidget {
  final String text;
  final Color color;
  final VoidCallback? onPressed;

  final IconData? icon;
  final String? iconPath; // 🔹 NOUVEAU
  final bool iconOnRight;
  final bool noIcon;

  final EdgeInsets? padding;
  final Color? textColor;
  final Color? iconColor;
  final double iconSize;
  final double? width;
  final double? height;
  const MainButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.icon,
    this.iconPath, // 🔹 ajout
    this.iconOnRight = false,
    this.noIcon = false,
    this.padding,
    this.textColor,
    this.iconColor,
    this.iconSize = 22,
    this.width,
    this.height,
  });

  Widget _buildIcon() {
    if (iconPath != null) {
      return Image.asset(
        iconPath!,
        width: iconSize,
        height: iconSize,
        color: iconColor,
      );
    }

    return Icon(
      icon ?? Icons.add,
      color: iconColor ?? Colors.white,
      size: iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: padding ??
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
        child: noIcon
            ? Text(
          text,
          style:
          Appstyle.textSB.copyWith(color: textColor ?? Appstyle.Tblanc),
        )
            : Row(
          mainAxisSize: MainAxisSize.min,
          children: iconOnRight
              ? [
            Text(
              text,
              style: Appstyle.textSB
                  .copyWith(color: textColor ?? Appstyle.Tblanc),
            ),
            const SizedBox(width: 8),
            _buildIcon(),
          ]
              : [
            _buildIcon(),
            const SizedBox(width: 8),
            Text(
              text,
              style: Appstyle.textSB
                  .copyWith(color: textColor ?? Appstyle.Tblanc),
            ),
          ],
        ),
      ),
    );
  }
}
