
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/title/title_big.dart';
import 'package:caisse_dz/core/widget/title/title_small.dart';
import 'package:flutter/material.dart';

class AfficheurCaisse extends StatelessWidget {
  final Color couleur;
  final String npannier;
  final String nproduit;
  final String total;
  final String remise;


  const AfficheurCaisse({
    super.key,
    required this.couleur,
    required this.npannier,
    required this.nproduit,
    required this.total,
    required this.remise,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1.0 , // inactive -> opacity 50%
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              couleur.withOpacity(0.95),
              couleur.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TitleSmall(
                    imagePath: 'assets/icons/sidebar/pannier_icon.png',
                    imageSize: 22,
                    text: npannier,
                    couleur: Appstyle.Tblanc,
                  ),
                  TitleBig(
                    imagePath: 'assets/icons/cardwidget/euro_icon.png',
                    imageSize: 30,
                    text: total,
                    couleur: Appstyle.Tblanc,
                    iconRight: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TitleSmall(
                    imagePath: 'assets/icons/sidebar/produit_icon.png',
                    imageSize: 24,
                    text: nproduit,
                    couleur: Appstyle.Tblanc,
                  ),
                  TitleBig(
                    imagePath: 'assets/icons/cardwidget/remise_icon.png',
                    text: remise,
                    couleur: Appstyle.Tblanc,
                    iconRight: true,
                    imageSize: 28,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),

    );
  }
}
