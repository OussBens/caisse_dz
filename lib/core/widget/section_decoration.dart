import 'package:flutter/material.dart';

import 'package:caisse_dz/core/theme/app_style.dart';

class SectionDecoration extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;
  final EdgeInsetsGeometry? margin;

  const SectionDecoration({
    super.key,
    required this.title,
    required this.child,
    this.icon,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        // Gris très clair pour différencier du blanc
        color: Appstyle.grisC.withOpacity(0.005),
        borderRadius: BorderRadius.circular(10),

        // Petite ombre discrète
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],

        border: Border.all(
          color: Appstyle.grisC.withOpacity(0.1),
          width: 1,
        ),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Appstyle.violet.withOpacity(0.05), // header légèrement plus foncé
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                if (icon != null)
                  Icon(icon, size: 18, color: Appstyle.violet),
                if (icon != null) const SizedBox(width: 8),
                Text(
                  title,
                  style: Appstyle.textLB.copyWith(
                    color: Appstyle.violet,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(14),
            child: child,
          ),
        ],
      ),
    );
  }
}
