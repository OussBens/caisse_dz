import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:caisse_dz/core/theme/app_style.dart';

class CardWidget extends StatefulWidget {
  final Color couleur;
  final String iconPath;
  final String text1;
  final String text2;
  final bool actif;
  final bool unSeulText;
  final VoidCallback? onTap;

  const CardWidget({
    super.key,
    required this.couleur,
    required this.iconPath,
    required this.text1,
    required this.text2,
    this.actif = true,
    this.unSeulText = false,
    this.onTap,
  });

  @override
  State<CardWidget> createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  bool isHovered = false;
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.actif;
    final screenWidth = MediaQuery.of(context).size.width;

    // Largeur responsive
    double cardWidth = 170;
    if (screenWidth > 1400) {
      cardWidth = 200;
    } else if (screenWidth > 1200) {
      cardWidth = 185;
    } else if (screenWidth > 1000) {
      cardWidth = 170;
    } else {
      cardWidth = 155;
    }

    // ✅ Calculer la translation Y en fonction de l'état
    double translateY = 0;
    if (isHovered && !isPressed && !selected) {
      translateY = -4; // Légère élévation au survol
    }

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
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..setTranslationRaw(0, translateY, 0) // ✅ Correction ici
            ..scale(isPressed ? 0.95 : 1.0),
          width: cardWidth,
          height: 110,
          decoration: BoxDecoration(
            gradient: selected
                ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.couleur,
                widget.couleur.withOpacity(0.85),
                widget.couleur.withOpacity(0.7),
              ],
            )
                : LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                isHovered
                    ? widget.couleur.withOpacity(0.05)
                    : Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? Colors.white.withOpacity(0.6)
                  : isHovered
                  ? widget.couleur.withOpacity(0.5)
                  : Colors.grey.shade300,
              width: selected ? 2.5 : 1.5,
            ),
            boxShadow: [
              if (selected)
                BoxShadow(
                  color: widget.couleur.withOpacity(0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                ),
              if (!selected && isHovered)
                BoxShadow(
                  color: widget.couleur.withOpacity(0.35),
                  blurRadius: 16,
                  spreadRadius: 3,
                  offset: const Offset(0, 6),
                ),
              if (!selected && !isHovered)
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: Stack(
            children: [
              // Effet de brillance au survol
              if (isHovered && !selected)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          widget.couleur.withOpacity(0.12),
                          widget.couleur.withOpacity(0.04),
                        ],
                      ),
                    ),
                  ),
                ),

              // Indicateur de clic (flèche) pour les cartes inactives
              if (!selected && isHovered)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.couleur.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: widget.couleur,
                    ),
                  ),
                ),

              // Badge pour les cartes actives
              if (selected && !widget.unSeulText)
                Positioned(
                  top: 8,
                  right: 8,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2,
                      ),
                    ),
                  ),
                ),

              /// Contenu principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Icône avec animation
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutBack,
                      transform: Matrix4.identity()
                        ..scale(isHovered && !selected && !isPressed ? 1.05 : 1.0),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: selected
                              ? Colors.white.withOpacity(0.25)
                              : isHovered
                              ? widget.couleur.withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(14),
                          border: isHovered && !selected
                              ? Border.all(
                            color: widget.couleur.withOpacity(0.2),
                            width: 1,
                          )
                              : null,
                        ),
                        child: Image.asset(
                          widget.iconPath,
                          width: selected ? 38 : 32,
                          height: selected ? 38 : 32,
                          fit: BoxFit.contain,
                          color: selected
                              ? Colors.white
                              : isHovered
                              ? widget.couleur
                              : Appstyle.TgrisC,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    /// Texte
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!widget.unSeulText) ...[
                            Text(
                              widget.text2,
                              style: TextStyle(
                                fontSize: selected ? 12 : 11,
                                fontWeight: selected ?FontWeight.w500 : FontWeight.w400,
                                color: selected
                                    ? Colors.white.withOpacity(0.9)
                                    : isHovered
                                    ? widget.couleur.withOpacity(0.8)
                                    : Appstyle.TgrisC.withOpacity(0.7),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            const SizedBox(height: 4),
                          ],
                          Text(
                            widget.text1,
                            style: TextStyle(
                              fontSize: widget.unSeulText
                                  ? (selected ? 18 : 14)
                                  : (selected ? 24 : 20),
                              fontWeight: FontWeight.bold,
                              color: selected
                                  ? Colors.white
                                  : isHovered
                                  ? widget.couleur
                                  : Appstyle.TgrisC,
                              letterSpacing: 0.5,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                          // Petit indicateur "Cliquez" au survol
                          if (!selected && isHovered && !widget.unSeulText)
                            Text(
                              "Cliquez pour accéder",
                              style: TextStyle(
                                fontSize: 9,
                                color: widget.couleur.withOpacity(0.5),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}