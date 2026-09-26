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
  static List<TextInputFormatter> get inputFormatters {
    if (decimales <= 0) {
      return [FilteringTextInputFormatter.digitsOnly];
    }
    return [
      FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,' '$decimales' r'}')),
    ];
  }
}
