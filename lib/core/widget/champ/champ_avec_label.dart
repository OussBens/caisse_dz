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
  final bool parent; // ← nouveau paramètre

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
    this.parent = false, // ← initialisé à false
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: parent ? double.infinity : width, // ← si parent est true, prend toute la largeur
      child: Row(
        mainAxisSize: parent ? MainAxisSize.max : MainAxisSize.min, // ← adapte le mainAxisSize
        crossAxisAlignment:
        alignmentStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: distance,
            child: Row(
              crossAxisAlignment:
              alignmentStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
              children: [
                // Expanded plutôt qu'un Text nu : un libellé plus long que
                // `distance` (ex. "Solde d'ouverture (DA)") passe à la ligne
                // au lieu de provoquer un RenderFlex overflow.
                Expanded(
                  child: Text(
                    label,
                    style: Appstyle.textSB.copyWith(color: Appstyle.TgrisF),
                    softWrap: true,
                  ),
                ),
                if (obligatoire)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      '*',
                      style: Appstyle.textLB.copyWith(
                        color: Appstyle.warning,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 15),
          Flexible(  // ← conserve Flexible pour permettre au child de s'adapter
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
                    borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}