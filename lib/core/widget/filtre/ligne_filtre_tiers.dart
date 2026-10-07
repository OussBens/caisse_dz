import 'package:flutter/material.dart';

/// Ligne de filtre découpée en 3 colonnes égales, séparées de 20 px comme les
/// lignes de filtre à 3 champs `Expanded` des écrans (Produit, Stock…).
///
/// Les [children] (1 à 3) occupent les premières colonnes, les colonnes
/// restantes restent vides. Donne ainsi à un champ isolé (Rechercher,
/// Magasin, Caisse…) la largeur standard d'un tiers de ligne, identique dans
/// tous les modules.
class LigneFiltreTiers extends StatelessWidget {
  final List<Widget> children;
  final TextDirection? textDirection;

  const LigneFiltreTiers({
    super.key,
    required this.children,
    this.textDirection,
  }) : assert(children.length >= 1 && children.length <= 3);

  @override
  Widget build(BuildContext context) {
    return Row(
      textDirection: textDirection,
      children: [
        for (int i = 0; i < 3; i++) ...[
          if (i > 0) const SizedBox(width: 20),
          Expanded(child: i < children.length ? children[i] : const SizedBox.shrink()),
        ],
      ],
    );
  }
}
