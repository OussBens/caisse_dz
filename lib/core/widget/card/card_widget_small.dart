import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class CardWidgetSmall extends StatefulWidget {
  final Color couleur;
  final String iconPath;
  final String text1;
  final String text2;
  final bool actif;
  final VoidCallback? onTap;

  const CardWidgetSmall({
    super.key,
    required this.couleur,
    required this.iconPath,
    required this.text1,
    required this.text2,
    this.actif = true,
    this.onTap,
  });

  @override
  State<CardWidgetSmall> createState() => _CardWidgetSmallState();
}

class _CardWidgetSmallState extends State<CardWidgetSmall> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.actif;

    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => isPressed = true),
        onTapUp: (_) => setState(() => isPressed = false),
        onTapCancel: () => setState(() => isPressed = false),

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          transform: Matrix4.identity()..scale(isPressed ? 0.92 : 1.0),

          width: 160,
          height: 40,

          decoration: BoxDecoration(
            color: widget.couleur.withOpacity(selected ? 1 : 0.85),
            borderRadius: BorderRadius.circular(16),
            border: selected ? Border.all(color: Colors.white, width: 2) : null,
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: widget.couleur.withOpacity(0.55),
                  blurRadius: 14,
                  spreadRadius: 1,
                ),
              if (isHovered && !selected)
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
            ],
          ),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: selected ? 1.20 : 1.0,
                child: Image.asset(
                  widget.iconPath,
                  width: 20,
                  height: 20,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),

              Text(
                widget.text1,
                style: Appstyle.textpop_MB.copyWith(
                  color: Colors.white,
                  fontSize: selected ? 17 : 15,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                widget.text2,
                style: Appstyle.textSB.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: selected ? 13 : 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
