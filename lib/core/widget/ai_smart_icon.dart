import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Enrobage animé pour le badge "Smart" (assets/icons/smart_icon.png),
/// réutilisé partout où une fonctionnalité IA doit se démarquer visuellement
/// (recherche produit par IA, scan de réception IA) : lueur qui respire en
/// boucle autour du badge (même silhouette arrondie que l'image) + léger
/// effet de respiration/échelle, pour un rendu moderne et vivant sans
/// surcharger l'interface.
class AiSmartIcon extends StatefulWidget {
  final String iconPath;
  final double width;
  final double height;

  /// Plus prononcé (lueur + échelle) quand le mode IA est sélectionné.
  final bool active;

  const AiSmartIcon({
    super.key,
    required this.iconPath,
    required this.width,
    required this.height,
    this.active = true,
  });

  @override
  State<AiSmartIcon> createState() => _AiSmartIconState();
}

class _AiSmartIconState extends State<AiSmartIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = Curves.easeInOut.transform(_controller.value);
        final baseGlow = widget.active ? 0.35 : 0.14;
        final glow = baseGlow + (widget.active ? 0.25 : 0.08) * t;
        final scale = 1.0 + (widget.active ? 0.05 : 0.02) * t;

        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular((widget.height + 6) / 2),
              boxShadow: [
                BoxShadow(
                  color: Appstyle.purple400.withOpacity(glow),
                  blurRadius: 14 + 10 * t,
                  spreadRadius: 1 + t,
                ),
                BoxShadow(
                  color: Appstyle.purple200.withOpacity(glow * 0.6),
                  blurRadius: 20 + 8 * t,
                  spreadRadius: 0.5,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: Image.asset(widget.iconPath, width: widget.width, height: widget.height, fit: BoxFit.contain),
    );
  }
}
