import 'package:flutter/material.dart';

class MainIconButton extends StatefulWidget {
  final Color color;
  final VoidCallback onPressed;
  final String? imagePath;

  const MainIconButton({
    super.key,
    required this.color,
    required this.onPressed,
    this.imagePath,
  });

  @override
  State<MainIconButton> createState() => _MainIconButtonState();
}

class _MainIconButtonState extends State<MainIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final usedImage = widget.imagePath ?? "assets/icons/default.png";

    final Color currentColor = _isHovered ? widget.color : widget.color;
    final double size = _isHovered ? 50 : 40; // Taille qui change au survol
    final double borderWidth = _isHovered ? 1.8 : 1.4;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: size,
        height: size,
        curve: Curves.easeInOut,
        child: ElevatedButton(
          onPressed: widget.onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _isHovered ? currentColor.withOpacity(0.2) : Colors.white,
            elevation: _isHovered ? 8 : 4,
            shadowColor: Colors.black26,
            padding: const EdgeInsets.all(10),
            shape: CircleBorder(
              side: BorderSide(
                color: currentColor,
                width: borderWidth,
              ),
            ),
          ),
          child: Image.asset(
            usedImage,
            width: _isHovered ? 32 : 28,
            height: _isHovered ? 32 : 28,
            color: currentColor,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
