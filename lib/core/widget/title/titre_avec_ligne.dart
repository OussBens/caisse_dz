
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/cupertino.dart';

class TitreAvecLigne extends StatelessWidget {
  final String imagePath;
  final String text;
  final double imageSize;
  final Color? colligne;
  // Widget optionnel affiché en bout de ligne (ex. bouton fermer "X") — sur
  // la même rangée que l'icône/titre, pour que la ligne du bas reste sous
  // tout l'en-tête au lieu de n'être que sous le titre si ce widget était
  // placé à côté de TitreAvecLigne dans un Row englobant séparé.
  final Widget? trailing;

  const TitreAvecLigne({
    super.key,
    required this.imagePath,
    required this.text,
    this.imageSize =26, this.colligne=Appstyle.gris,
    this.trailing,

  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            // Image à gauche
            Image.asset(
              imagePath,
              width: imageSize,
              height: imageSize,
              color: Appstyle.gris,        // ➜ recolore l’icône en gris
              colorBlendMode: BlendMode.srcIn,

            ),

            const SizedBox(width: 12),

            // Texte à droite
            Expanded(
              child: Text(
                text,
                style:Appstyle.textLB.copyWith(color: Appstyle.gris)
              ),
            ),

            if (trailing != null) trailing!,
          ],
        ),

        const SizedBox(height: 8),

        // Ligne en bas
        Container(
          height: 2,
          color: colligne,
        ),
      ],
    );
  }
}
