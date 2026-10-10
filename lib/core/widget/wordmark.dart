import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

/// Wordmark du design system : « Caisse » en texte principal et « DZ » en
/// violet de marque, Inter 700, toujours de gauche à droite (même en arabe).
/// [inverse] : version blanche (« DZ » en violet clair) sur fond violet.
class Wordmark extends StatelessWidget {
  final double size;
  final bool inverse;

  const Wordmark({super.key, this.size = 24, this.inverse = false});

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontFamily: Appstyle.fontLatin,
      fontSize: size,
      height: 1,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.03 * size,
    );
    return Semantics(
      label: 'CaisseDZ',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(text: 'Caisse', style: base.copyWith(color: inverse ? Appstyle.Tblanc : Appstyle.textPrimary)),
            TextSpan(text: 'DZ', style: base.copyWith(color: inverse ? Appstyle.purple200 : Appstyle.primary)),
          ],
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      ),
    );
  }
}
