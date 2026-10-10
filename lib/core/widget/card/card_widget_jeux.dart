
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class CardWidgetJeux extends StatelessWidget {
  final Color couleur;
  final String text1;
  final String text2;
  final bool actif;

  const CardWidgetJeux({
    super.key,
    required this.couleur,
   required this.text1,
    required this.text2,
    this.actif = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: actif ? 1.0 : 0.5, // inactive -> opacity 50%
      child: Container(
        width: 120,
        height: 100,
        decoration: BoxDecoration(
          color: couleur,
          borderRadius: BorderRadius.circular(Appstyle.radiusCard),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              text1,
              style: Appstyle.textLB.copyWith(color: Appstyle.Tblanc),
            ),

            Text(
              text2,
              style: Appstyle.textLB.copyWith(color: Appstyle.Tblanc),

            ),
          ],
        ),
      ),
    );
  }
}
