
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:flutter/material.dart';

class ChampAvecLabel extends StatelessWidget {
  final String label;
  final Widget child;
  final double? width;
  final double? distance;
  final bool obligatoire;
  final bool alignmentStart;
  final bool buttonAjout;
  final VoidCallback? onAjoutPressed;

  const ChampAvecLabel({
    super.key,
    required this.label,
    required this.child,
    this.width,
    this.obligatoire = false,
    this.alignmentStart = false,
    this.buttonAjout = false,
    this.onAjoutPressed,
    this.distance = 140,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Row(
        mainAxisSize: MainAxisSize.min,  // ← ajouté
        crossAxisAlignment:
        alignmentStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: distance,
            child: Row(
              crossAxisAlignment:
              alignmentStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: Appstyle.textSB.copyWith(color: Appstyle.TgrisF),
                ),
                if (obligatoire)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: Appstyle.textLB.copyWith(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Flexible(  // ← remplace Expanded
            fit: FlexFit.loose,
            child: child,
          ),
          if (buttonAjout)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: IconButton(
                icon: const Icon(Icons.menu_rounded),
                onPressed: onAjoutPressed,
                style: IconButton.styleFrom(
                  backgroundColor: Appstyle.violet,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
