
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/cupertino.dart';

class TitreAvecLigne extends StatelessWidget {
  final String imagePath;
  final String text;
  final double imageSize;
  final Color? colligne;

  const TitreAvecLigne({
    super.key,
    required this.imagePath,
    required this.text,
    this.imageSize =26, this.colligne=Appstyle.gris,

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
            Text(
              text,
              style:Appstyle.textLB.copyWith(color: Appstyle.gris)
            ),
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
