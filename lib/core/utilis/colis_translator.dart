import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

class ColisTranslator {
  // Clés fixes à stocker en base de données
  static const String UNITE = 'unite';
  static const String SMALL = 'small';
  static const String LARGE = 'large';

  // Obtenir la valeur d'affichage selon la langue actuelle
  static String getDisplayValue(String? colisKey, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (colisKey) {
      case UNITE:
        return l10n.uniteParcel;
      case SMALL:
        return l10n.smallParcel;
      case LARGE:
        return l10n.largeParcel;
      default:
        return l10n.uniteParcel;
    }
  }

  // Obtenir la clé à partir de la valeur d'affichage (pour la sauvegarde)
  static String getKeyFromDisplay(String displayValue, BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (displayValue == l10n.uniteParcel) return UNITE;
    if (displayValue == l10n.smallParcel) return SMALL;
    if (displayValue == l10n.largeParcel) return LARGE;
    return UNITE;
  }

  // Liste des valeurs d'affichage pour le dropdown
  static List<String> getDisplayList(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return [
      l10n.uniteParcel,
      l10n.smallParcel,
      l10n.largeParcel,
    ];
  }

  // Convertir une ancienne valeur (français/arabe) en clé (pour migration)
  static String migrateOldValue(String? oldValue) {
    if (oldValue == null) return UNITE;

    // Français
    if (oldValue == 'Unité' || oldValue == 'Unite parcel' || oldValue == 'Unité parcel') return UNITE;
    if (oldValue == 'Petit colis' || oldValue == 'Small parcel') return SMALL;
    if (oldValue == 'Grand colis' || oldValue == 'Large parcel') return LARGE;

    // Arabe
    if (oldValue == 'وحدة') return UNITE;
    if (oldValue == 'طرد صغير') return SMALL;
    if (oldValue == 'طرد كبير') return LARGE;

    return UNITE;
  }
}