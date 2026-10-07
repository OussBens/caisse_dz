import 'package:flutter/services.dart';
import '../../Services/Paramters.dart';

/// Nombre de décimales à afficher/saisir sur tous les champs quantité de
/// l'app (panier caisse, entrée, retour, sortie, smart scan, liste de
/// besoin...), configurable dans Paramètres > Système (parametre.decimales_
/// quantite). Chargé une fois au démarrage (voir main.dart) puis mis à jour
/// en mémoire à chaque sauvegarde de l'écran Paramètres, pour éviter un
/// aller-retour DB à chaque champ affiché.
class QuantiteFormat {
  static int decimales = 0;

  static Future<void> load() async {
    final param = await ParamServices.getParam();
    decimales = param.decimalesQuantite;
  }

  /// Texte à afficher/pré-remplir dans un champ quantité (ex: "5" si 0
  /// décimale, "5.0" si 1, "5.00" si 2).
  static String format(num value) => value.toStringAsFixed(decimales);

  /// Parse la saisie utilisateur d'un champ quantité (tolère la virgule).
  static double parse(String text) {
    return double.tryParse(text.trim().replaceAll(',', '.')) ?? 0;
  }

  /// Restreint la saisie au nombre de décimales configuré (aucune décimale
  /// autorisée si [decimales] == 0).
  static List<TextInputFormatter> get inputFormatters => _formattersPour(decimales);

  // ── Selon l'unité de mesure du produit ─────────────────────────────────
  // Un produit vendu à la pièce ne se compte jamais en fraction : 0 décimale
  // quelle que soit la configuration ; les autres unités (kg, litre, mètre…)
  // suivent [decimales].

  /// Valeur stockée de l'unité "pièce" (ListsConst.uniteMesureList).
  static const String unitePiece = 'Pièce';

  static int decimalesPour(String? uniteMesure) => uniteMesure == unitePiece ? 0 : decimales;

  static String formatPour(num value, String? uniteMesure) =>
      value.toStringAsFixed(decimalesPour(uniteMesure));

  static List<TextInputFormatter> inputFormattersPour(String? uniteMesure) =>
      _formattersPour(decimalesPour(uniteMesure));

  static List<TextInputFormatter> _formattersPour(int nbDecimales) {
    if (nbDecimales <= 0) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,' '$nbDecimales' r'}')),
    ];
  }
}
