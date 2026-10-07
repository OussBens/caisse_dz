import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import '../theme/app_style.dart';

/// Contrôles de fenêtre intégrés à l'interface — il n'y a plus de barre de
/// titre séparée. Le cadre Windows est supprimé côté natif
/// (`bitsdojo_window_configure(BDW_CUSTOM_FRAME)`, voir
/// windows/runner/main.cpp) en gardant le redimensionnement/snap natifs.
///
/// Répartition :
/// - logo + titre : en-tête de la sidebar ([ZoneDeplacementFenetre]) ;
/// - réduire / agrandir / fermer : ligne du haut d'AppShell, à côté des
///   onglets favoris ([BoutonsFenetre]) ;
/// - écrans hors AppShell (login, activation…) : [BoutonsFenetreFlottants],
///   monté par le `builder:` de MaterialApp.router (main.dart).

/// Zone qui déplace la fenêtre quand on la fait glisser ; double-clic =
/// agrandir / restaurer si [doubleClicAgrandit]. Les clics simples restent
/// transmis aux enfants.
///
/// N'utilise pas `MoveWindow` de bitsdojo : celui-ci enveloppe son enfant
/// dans `Column > Expanded`, ce qui casse la mise en page dès que la hauteur
/// n'est pas bornée (en-tête de la sidebar → « RenderFlex children have
/// non-zero flex but incoming height constraints are unbounded »).
class ZoneDeplacementFenetre extends StatefulWidget {
  final Widget? child;

  /// false quand la zone contient des éléments cliquables (logo de la
  /// sidebar), pour qu'un double-clic sur eux n'agrandisse pas la fenêtre.
  final bool doubleClicAgrandit;

  const ZoneDeplacementFenetre({super.key, this.child, this.doubleClicAgrandit = true});

  @override
  State<ZoneDeplacementFenetre> createState() => _ZoneDeplacementFenetreState();
}

class _ZoneDeplacementFenetreState extends State<ZoneDeplacementFenetre> {
  static const Duration _delaiDoubleClic = Duration(milliseconds: 400);
  DateTime? _dernierClic;

  // Double-clic détecté à la main : un `onDoubleTap` de GestureDetector
  // entre en compétition avec `onPanStart` et empêche le glisser de démarrer.
  void _surAppui(PointerDownEvent _) {
    if (!widget.doubleClicAgrandit) return;
    final maintenant = DateTime.now();
    if (_dernierClic != null && maintenant.difference(_dernierClic!) < _delaiDoubleClic) {
      _dernierClic = null;
      appWindow.maximizeOrRestore();
    } else {
      _dernierClic = maintenant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _surAppui,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanStart: (_) => appWindow.startDragging(),
        child: widget.child ?? const SizedBox.expand(),
      ),
    );
  }
}

/// Réduire / agrandir-restaurer / fermer. Toujours à droite et dans cet
/// ordre (convention Windows), y compris en arabe (RTL).
class BoutonsFenetre extends StatelessWidget {
  final double hauteur;

  const BoutonsFenetre({super.key, this.hauteur = 32});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _WindowButton(icon: Icons.remove, hauteur: hauteur, onPressed: () => appWindow.minimize()),
          _WindowButton(icon: Icons.crop_square, iconSize: 14, hauteur: hauteur, onPressed: () => appWindow.maximizeOrRestore()),
          _WindowButton(
            icon: Icons.close,
            hauteur: hauteur,
            hoverColor: Appstyle.red,
            hoverIconColor: Colors.white,
            onPressed: () => appWindow.close(),
          ),
        ],
      ),
    );
  }
}

/// Boutons de fenêtre + bande de déplacement en haut de l'écran, pour les
/// écrans qui n'ont pas AppShell. Masqués tant qu'AppShell est monté
/// ([shellActif]), qui intègre lui-même ces contrôles.
class BoutonsFenetreFlottants extends StatelessWidget {
  /// Positionné par AppShell (initState / dispose).
  static final ValueNotifier<bool> shellActif = ValueNotifier<bool>(false);

  const BoutonsFenetreFlottants({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: shellActif,
      builder: (context, actif, _) {
        if (actif) return const SizedBox.shrink();
        return const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            height: 32,
            child: Row(
              children: [
                Expanded(child: ZoneDeplacementFenetre()),
                BoutonsFenetre(),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _WindowButton extends StatefulWidget {
  final IconData icon;
  final double iconSize;
  final double hauteur;
  final Color hoverColor;
  final Color hoverIconColor;
  final VoidCallback onPressed;

  const _WindowButton({
    required this.icon,
    required this.onPressed,
    required this.hauteur,
    this.iconSize = 16,
    this.hoverColor = Appstyle.violetC,
    this.hoverIconColor = Appstyle.violet,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 40,
          height: widget.hauteur,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: _hovered ? widget.hoverIconColor : Appstyle.gris,
          ),
        ),
      ),
    );
  }
}
