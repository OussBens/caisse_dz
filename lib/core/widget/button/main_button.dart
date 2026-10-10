import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class MainButton extends StatefulWidget {
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

  /// Raccourci clavier affiché entre le texte et l'icône (ex: "F4", "Ctrl+P").
  final String? shortcutLabel;

  /// ✅ Affiche un point rouge sur le bouton (ex: filtres actifs).
  final bool showBadge;

  /// Remplace le contenu par un spinner et désactive le clic (ex: soumission
  /// d'un formulaire en cours) — évite que chaque écran ne bricole son propre
  /// bouton de secours pour cet état.
  final bool loading;

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
    this.shortcutLabel,
    this.showBadge = false,
    this.loading = false,
  });

  @override
  State<MainButton> createState() => _MainButtonState();
}

// Hover/press géré une seule fois ici (au lieu d'être ré-implémenté à la
// main dans chaque écran/dialog qui a besoin d'un bouton) : léger effet de
// levée + assombrissement au survol, tassement au clic — même langage
// visuel que CardWidget/_ModuleTile ailleurs dans l'app.
class _MainButtonState extends State<MainButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  // Variante « neutre » du design system (Annuler, Fermer…) : un bouton
  // gris devient surface-2 avec texte foncé au lieu de blanc sur gris.
  bool get _neutre => widget.color == Appstyle.gris && widget.textColor == null;

  Widget? _buildShortcutBadge() {
    final label = widget.shortcutLabel;
    if (label == null || label.isEmpty) return null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: (_neutre ? Appstyle.textPrimary : Colors.white).withOpacity(_neutre ? 0.08 : 0.25),
        borderRadius: BorderRadius.circular(Appstyle.radiusXS),
      ),
      child: Text(
        label,
        style: Appstyle.textXS.copyWith(
          color: widget.textColor ?? (_neutre ? Appstyle.textPrimary : Appstyle.Tblanc),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildIcon() {
    if (widget.iconPath != null) {
      return Image.asset(
        widget.iconPath!,
        width: widget.iconSize,
        height: widget.iconSize,
        color: widget.iconColor ?? (_neutre ? Appstyle.textPrimary : null),
      );
    }

    return Icon(
      widget.icon ?? Icons.add,
      color: widget.iconColor ?? (_neutre ? Appstyle.textPrimary : Colors.white),
      size: widget.iconSize,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onPressed != null && !widget.loading;
    final bool neutre = _neutre;
    final Color fond = neutre ? Appstyle.surface2 : widget.color;
    final Color texte = widget.textColor ?? (neutre ? Appstyle.textPrimary : Appstyle.Tblanc);
    final Color hoverColor = neutre ? Appstyle.neutral200 : Color.lerp(widget.color, Colors.black, 0.08)!;
    final translateY = (_isHovered && enabled && !_isPressed) ? -2.0 : 0.0;
    final scale = (_isPressed && enabled) ? 0.97 : 1.0;

    final button = MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          transform: Matrix4.identity()
            ..translate(0.0, translateY)
            ..scale(scale),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Appstyle.radiusButton),
            boxShadow: (_isHovered && enabled && !neutre)
                ? Appstyle.shadowHover(color: widget.color)
                : const [],
          ),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: (_isHovered && enabled) ? hoverColor : fond,
                foregroundColor: texte,
                elevation: 0,
                padding: widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Appstyle.radiusButton),
                ),
              ),
              onPressed: widget.loading ? null : widget.onPressed,
              child: widget.loading
                  ? SizedBox(
                width: widget.iconSize,
                height: widget.iconSize,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: texte,
                ),
              )
                  : widget.noIcon
                  ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.text,
                      style: Appstyle.textSB
                          .copyWith(color: texte),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (_buildShortcutBadge() != null) ...[
                    const SizedBox(width: 6),
                    _buildShortcutBadge()!,
                  ],
                ],
              )
                  : Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.iconOnRight
                    ? [
                  Flexible(
                    child: Text(
                      widget.text,
                      style: Appstyle.textSB
                          .copyWith(color: texte),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_buildShortcutBadge() != null) ...[
                    _buildShortcutBadge()!,
                    const SizedBox(width: 8),
                  ],
                  _buildIcon(),
                ]
                    : [
                  _buildIcon(),
                  const SizedBox(width: 8),
                  if (_buildShortcutBadge() != null) ...[
                    _buildShortcutBadge()!,
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      widget.text,
                      style: Appstyle.textSB
                          .copyWith(color: texte),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.showBadge) return button;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        button,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Appstyle.danger,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
