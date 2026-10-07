/// Calcul du prix de vente automatique à partir d'un prix d'achat et d'une
/// marge — utilisé par la création rapide de produit (produit_nouveau.dart).
class PrixVenteCalculator {
  /// Arrondit au multiple de 5 DA supérieur (104 -> 105, 126 -> 130).
  static double arrondirAuMultipleDe5(double prix) {
    final prixArrondi = double.parse(prix.toStringAsFixed(2));
    return (prixArrondi / 5).ceil() * 5;
  }

  /// Prix de vente auto selon la marge système (Paramters.typeMarge /
  /// TauxMargeMontant / TauxMargePerncetage) : valeur exacte pour une marge
  /// en montant fixe, arrondi au multiple de 5 DA pour une marge en
  /// pourcentage.
  static double calculAuto(double prixAchat, {required String margeType, required double margeTaux}) {
    if (margeType == "Montant") {
      return prixAchat + margeTaux;
    }
    return arrondirAuMultipleDe5(prixAchat + (prixAchat * margeTaux / 100));
  }
}
