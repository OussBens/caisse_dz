// core/theme/field_theme.dart
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';


// États des champs (design system CaisseDZ) : vide = surface-2 sans bordure
// visible, focus = fond blanc + bordure primary + halo (focus-ring),
// rempli = teinte succès (repère « champ renseigné » conservé), erreur = danger.
class FieldTheme {
  // Couleurs de fond selon l'état
  static const Color emptyBg = Appstyle.surface2;
  static const Color filledBg = Appstyle.successSoft;
  static const Color focusedBg = Appstyle.surface;
  static const Color errorBg = Appstyle.dangerSoft;
  static const Color disabledBg = Appstyle.disabledBg;

  // Couleurs de bordure
  static const Color emptyBorder = Appstyle.surface2;
  static const Color filledBorder = Appstyle.success;
  static const Color focusedBorder = Appstyle.primary;
  static const Color errorBorder = Appstyle.danger;

  // Ombres
  static const BoxShadow emptyShadow = BoxShadow(color: Colors.transparent);

  static final BoxShadow filledShadow = BoxShadow(
    color: Appstyle.success.withOpacity(0.12),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );

  // Halo de focus du design system : 4 px, primary à 32 %.
  static final BoxShadow focusedShadow = BoxShadow(
    color: Appstyle.focusRing,
    spreadRadius: 4,
  );

  static final BoxShadow errorShadow = BoxShadow(
    color: Appstyle.danger.withOpacity(0.15),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );
}

class FieldDecoration {
  static BoxDecoration getDecoration({
    required bool isFilled,
    required bool isFocused,
    bool hasError = false,
    bool enabled = true,
    double borderRadius = 12,
  }) {
    Color bgColor;
    Color borderColor;
    List<BoxShadow> shadows;
    double borderWidth = 1.5;

    if (!enabled) {
      bgColor = FieldTheme.disabledBg;
      borderColor = Appstyle.neutral200;
      shadows = [];
    } else if (hasError) {
      bgColor = FieldTheme.errorBg;
      borderColor = FieldTheme.errorBorder;
      shadows = [FieldTheme.errorShadow];
      borderWidth = 2;
    } else if (isFocused) {
      bgColor = FieldTheme.focusedBg;
      borderColor = FieldTheme.focusedBorder;
      shadows = [FieldTheme.focusedShadow];
      borderWidth = 1.5;
    } else if (isFilled) {
      bgColor = FieldTheme.filledBg;
      borderColor = FieldTheme.filledBorder;
      shadows = [FieldTheme.filledShadow];
      borderWidth = 2;
    } else {
      bgColor = FieldTheme.emptyBg;
      borderColor = FieldTheme.emptyBorder;
      shadows = [FieldTheme.emptyShadow];
    }

    return BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor,
        width: borderWidth,
      ),
      boxShadow: shadows,
    );
  }
}