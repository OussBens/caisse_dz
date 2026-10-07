import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';

/// Catégorie visuelle d'un dialogue (ConfirmationDialog / InformationDialog) :
/// confirmer = neutre, danger = action destructive, refuser = action bloquée
/// ou erreur, attention = avertissement qu'on peut confirmer.
enum DialogKind { confirmer, danger, refuser, attention }

extension DialogKindStyle on DialogKind {
  Color get couleur => switch (this) {
        DialogKind.confirmer => Appstyle.violet,
        DialogKind.danger => Colors.red,
        DialogKind.refuser => Appstyle.gris,
        DialogKind.attention => Colors.orange,
      };

  IconData get icone => switch (this) {
        DialogKind.confirmer => Icons.check_circle,
        DialogKind.danger => Icons.delete_forever,
        DialogKind.refuser => Icons.block,
        DialogKind.attention => Icons.warning_amber_rounded,
      };
}
