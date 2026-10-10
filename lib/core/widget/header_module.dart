import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

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
                Appstyle.primary.withOpacity(0.8),
                Appstyle.primary.withOpacity(0.4)
              ],
          begin: begin,
          end: end,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Appstyle.shadowTint.withOpacity(0.1),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: child),
          const SizedBox(width: 14),
          const _HeaderExitButton(),
        ],
      ),
    );
  }
}

/// Bouton de déconnexion, déplacé depuis le pied de la sidebar vers le coin
/// haut-droit du header (présent sur tous les écrans via [HeaderModule]) —
/// petit bouton circulaire animé au survol, à l'image de [MainIconButton].
class _HeaderExitButton extends StatefulWidget {
  const _HeaderExitButton();

  @override
  State<_HeaderExitButton> createState() => _HeaderExitButtonState();
}

class _HeaderExitButtonState extends State<_HeaderExitButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final double size = _isHovered ? 40 : 34;

    return Tooltip(
      message: l10n.exit,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            final auth = Provider.of<AuthState>(context, listen: false);
            auth.logout(
              username: auth.username!,
              userCode: auth.userCode!,
            );
            context.go('/login');
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _isHovered ? Appstyle.danger : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Appstyle.danger, width: 1.6),
              boxShadow: [
                BoxShadow(
                  color: Appstyle.danger.withOpacity(_isHovered ? 0.35 : 0.15),
                  blurRadius: _isHovered ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.exit_to_app,
              color: _isHovered ? Colors.white : Appstyle.danger,
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}
