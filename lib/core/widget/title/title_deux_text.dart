
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class TitleDeuxText extends StatelessWidget {
  final String text1;
  final String text2;
  final Color couleur;

  const TitleDeuxText({
    super.key,
    required this.text1,
    required this.text2,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text1,
          style: Appstyle.textSB.copyWith(color: couleur),
        ),
        const SizedBox(width: 12),
        Text(
          text2,
          style: Appstyle.textSB.copyWith(color: couleur),
        ),
      ],
    );
  }
}
