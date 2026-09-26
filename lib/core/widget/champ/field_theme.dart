// core/theme/field_theme.dart
import 'package:flutter/material.dart';


class FieldTheme {
  // Couleurs de fond selon l'état
  static const Color emptyBg = Color(0xFFF5F7FA);
  static const Color filledBg = Color(0xFFE8F5E9);
  static const Color focusedBg = Color(0xFFE3F2FD);
  static const Color errorBg = Color(0xFFFFEBEE);
  static const Color disabledBg = Color(0xFFF5F5F5);

  // Couleurs de bordure
  static const Color emptyBorder = Color(0xFFE0E0E0);
  static const Color filledBorder = Color(0xFF4CAF50);
  static const Color focusedBorder = Color(0xFF2196F3);
  static const Color errorBorder = Color(0xFFF44336);

  // Ombres
  static final BoxShadow emptyShadow = BoxShadow(
    color: Colors.black.withOpacity(0.04),
    blurRadius: 4,
    offset: const Offset(0, 2),
  );

  static final BoxShadow filledShadow = BoxShadow(
    color: Color(0xFF4CAF50).withOpacity(0.15),
    blurRadius: 8,
    offset: const Offset(0, 3),
  );

  static final BoxShadow focusedShadow = BoxShadow(
    color: Color(0xFF2196F3).withOpacity(0.2),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static final BoxShadow errorShadow = BoxShadow(
    color: Color(0xFFF44336).withOpacity(0.15),
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
      borderColor = Colors.grey.shade300;
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
      borderWidth = 2.5;
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