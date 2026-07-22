import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class AffichageChamp extends StatelessWidget {

  final String text;
  const AffichageChamp({super.key, required this.text,});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 8),
      decoration:  BoxDecoration(
        color: Appstyle.grischamp,
        borderRadius:  BorderRadius.circular(14),
      ),
      child: Text(
        text,style: Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),
      ),
    );
  }
}
