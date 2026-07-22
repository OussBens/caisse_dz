import 'package:flutter/material.dart';

class HeaderModule extends StatelessWidget {
  final Widget child; // contenu à afficher à l'intérieur
  final List<Color>? gradientColors; // couleurs du gradient
  final double borderRadius; // arrondi du container
  final EdgeInsetsGeometry padding; // padding interne
  final List<BoxShadow>? boxShadow; // ombre optionnelle
  final Alignment begin;
  final Alignment end;

  const HeaderModule({
    super.key,
    required this.child,
    this.gradientColors,
    this.borderRadius = 12,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.boxShadow,
    this.begin = Alignment.topLeft,
    this.end = Alignment.bottomRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors ??
              [
                Colors.purple.withOpacity(0.8),
                Colors.purple.withOpacity(0.4)
              ],
          begin: begin,
          end: end,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: child,
    );
  }
}
