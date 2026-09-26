/// Formatage des nombres pour l'affichage (montants, quantités, totaux...)
/// avec séparateur de milliers (espace) — utilisé dans tous les afficheurs
/// en lecture seule (cards, tableaux, détails, dashboard, tickets).
///
/// Ne JAMAIS utiliser ce formatage sur le texte d'un champ de saisie
/// (TextField/TextFormField/TextChampL) dont la valeur est reparsée
/// (double.parse/tryParse) pour l'enregistrement — l'espace inséré casse
/// le parsing.
class NumberFormatUtil {
  /// Formate [value] avec [decimales] décimales et un espace comme
  /// séparateur de milliers (ex: 10000 -> "10 000.00").
  static String formatMontant(num value, {int decimales = 2}) {
    final fixed = value.toStringAsFixed(decimales);
    final dotIndex = fixed.indexOf('.');
    final intPart = dotIndex == -1 ? fixed : fixed.substring(0, dotIndex);
    final decimalPart = dotIndex == -1 ? '' : fixed.substring(dotIndex);

    final isNegative = intPart.startsWith('-');
    final digits = isNegative ? intPart.substring(1) : intPart;

    final buffer = StringBuffer();
    for (int i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }

    return '${isNegative ? '-' : ''}$buffer$decimalPart';
  }
}
