
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class TimeDateWidget extends StatelessWidget {
  final String heure;
  final String date;
  final String iconHeure;
  final String iconDate;

  const TimeDateWidget({
    super.key,
    required this.heure,
    required this.date,
    required this.iconHeure,
    required this.iconDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Heure
          Image.asset(
            iconHeure,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            heure,
            style:  Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),
          ),
          const SizedBox(width: 25),

          // Date
          Image.asset(
            iconDate,
            width: 18,
            height: 18,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 8),
          Text(
            date,
            style:  Appstyle.textXSB.copyWith(color: Appstyle.Tnoir),

          ),
        ],
      ),
    );
  }
}
