import 'dart:io';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../Services/Photos.dart';

class CardProduct extends StatelessWidget {
  final bool selected;
  final Color couleur;
  final String iconPath;
  final String text1;
  final String text2;
  final double quantite;
  final double seuil;
  final bool actif;
  final bool rupture;

  final bool hasRemise;
  final String? photo;
  // Sert uniquement de repli visuel (couleur automatique, voir
  // Appstyle.couleurSousCategorie) quand [photo] est absente.
  final int? sousCategorieId;

  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const CardProduct({
    super.key,
    required this.couleur,
    required this.iconPath,
    required this.text1,
    required this.text2,
    required this.quantite,
    required this.seuil,
    this.hasRemise = false,
    this.photo,
    this.sousCategorieId,
    this.selected = false,
    this.actif = true,
    this.rupture = false,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final bool isRupture = quantite <= 0;

    final Color backgroundColor = (quantite <= seuil && quantite > 0)
        ? Appstyle.danger
        : selected
        ? Appstyle.Tblanc
        : Appstyle.Tnoir;

    return Opacity(
      opacity: actif ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: onTap,
        onDoubleTap: onDoubleTap,
        child: Stack(
          children: [
            Container(
              width: 200, // ✅ Augmenté de 200 à 220
              decoration: BoxDecoration(
                color: selected
                    ? Appstyle.violet.withOpacity(0.3)
                    : couleur,
                borderRadius: BorderRadius.circular(Appstyle.radiusCard),
                border: selected
                    ? Border.all(
                  color: Appstyle.violet,
                  width: 2,
                )
                    : Border.all(
                  color: Appstyle.grisC,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Appstyle.shadowTint.withOpacity(0.08),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ✅ PHOTO DU PRODUIT À GAUCHE (TAILLE AUGMENTÉE)
                    _buildProductPhoto(),

                    const SizedBox(width: 12),

                    /// ✅ INFOS À DROITE
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            text1,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Appstyle.textpop_XS.copyWith(
                              color: selected
                                  ? Appstyle.Tblanc
                                  : Appstyle.Tnoir,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            text2,
                            style: Appstyle.textXSB.copyWith(
                              color: Appstyle.Tblue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                "${l10n.inStock}: ",
                                style: Appstyle.textpop_S.copyWith(
                                  color: backgroundColor,
                                ),
                              ),
                              Text(
                                quantite.toString(),
                                style: Appstyle.textpop_SB.copyWith(
                                  color: backgroundColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// BADGE RUPTURE
            /// PositionedDirectional (et non Positioned+left) car la Row
            /// [photo | infos] est inversée par Directionality en arabe : la
            /// photo passe à droite. "start" suit ce miroir et reste
            /// toujours au-dessus de la photo au lieu de chevaucher le nom
            /// du produit.
            if (isRupture)
              PositionedDirectional(
                top: 6,
                start: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Appstyle.danger,
                    borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                    boxShadow: [
                      BoxShadow(
                        color: Appstyle.shadowTint.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    l10n.outOfStock,
                    style: Appstyle.textXS.copyWith(
                      color: Colors.white,
                      fontSize: 9
                    ),
                  ),
                ),
              ),

            /// BADGE REMISE
            if (hasRemise )
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Appstyle.warning,
                    borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                  ),
                  child: Image.asset(
                    'assets/icons/cardwidget/remise_icon.png',
                    width: 14,
                    height: 14,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ✅ Widget pour afficher la photo (TAILLE AUGMENTÉE)
  Widget _buildProductPhoto() {
    if (photo == null || photo!.isEmpty) {
      final Color couleurPlaceholder =
          sousCategorieId != null ? Appstyle.couleurSousCategorie(sousCategorieId!) : Appstyle.violet;
      return Container(
        width: 70,  // ✅ Augmenté de 50 à 70
        height: 70, // ✅ Augmenté de 50 à 70
        decoration: BoxDecoration(
          color: couleurPlaceholder.withOpacity(0.1),
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        child: Icon(
          Icons.inventory_2,
          size: 40, // ✅ Augmenté de 30 à 40
          color: couleurPlaceholder.withOpacity(0.6),
        ),
      );
    }

    return FutureBuilder<File?>(
      future: PhotoService.getPhotoFile(photo),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
            child: Image.file(
              snapshot.data!,
              width: 70,  // ✅ Augmenté de 50 à 70
              height: 70, // ✅ Augmenté de 50 à 70
              fit: BoxFit.cover,
            ),
          );
        }

        return Container(
          width: 70,  // ✅ Augmenté de 50 à 70
          height: 70, // ✅ Augmenté de 50 à 70
          decoration: BoxDecoration(
            color: Appstyle.neutral150,
            borderRadius: BorderRadius.circular(Appstyle.radiusMD),
          ),
          child: const Icon(
            Icons.broken_image,
            size: 40, // ✅ Augmenté de 30 à 40
            color: Appstyle.gris,
          ),
        );
      },
    );
  }
}