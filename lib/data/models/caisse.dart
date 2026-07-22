import '../../core/tableau/caisse/tableau_caisse.dart';

class CaisseState {
  String client;
  String modePaiement;
  List<ProduitPanier> produits;
  List<String> sousCategories;
  String nom;
  String caisse;

  String? remisenom;
  double remise;
  double total;
  double totalAchat;
  double marge;
  DateTime date;
  double? remiseValeur;

  // ✅ Nouveaux champs pour la remise conditionnelle
  RemiseInfo? remiseInfo; // Stocke toutes les infos de la remise
  bool remiseActive = false; // Indique si la remise est activée

  CaisseState({
    required this.nom,
    required this.caisse,
    this.client = "Comptoire",
    this.remisenom = "",
    this.modePaiement = "Espèces",
    List<ProduitPanier>? produits,
    List<String>? sousCategories,
    this.remise = 0.0,
    this.total = 0.0,
    this.totalAchat = 0.0,
    this.marge = 0,
    DateTime? date,
    this.remiseValeur,
    this.remiseInfo,
    this.remiseActive = false,
  })  : produits = produits ?? [],
        sousCategories = sousCategories ?? [],
        date = date ?? DateTime.now();

  int get nombreProduits => produits.length;

  int get nombreArticles => produits.fold(0, (sum, p) => sum + p.qte.toInt());

  int get nombreArticlesReels => produits.fold(0, (sum, p) => sum + p.quantiteReelleEnPieces.toInt());

  void recalculerTotaux() {
    double sousTotal = 0;
    for (var p in produits) {
      sousTotal += p.prix * p.qte;
    }
    totalAchat = sousTotal;

    // ✅ Vérifier si la remise doit être activée
    if (remiseInfo != null && remiseInfo!.montantCondition > 0) {
      // La remise est conditionnelle : ne s'active que si le montant total atteint le seuil
      if (sousTotal >= remiseInfo!.montantCondition) {
        remiseActive = true;
        // Appliquer la remise selon son type
        if (remiseInfo!.tauxType.toLowerCase() == "pourcentage") {
          final reduction = sousTotal * remiseInfo!.taux / 100;
          total = sousTotal - reduction;
          remise = reduction;
        } else {
          // Remise en montant fixe
          total = sousTotal - remiseInfo!.taux;
          remise = remiseInfo!.taux;
          if (total < 0) total = 0;
        }
        remisenom = remiseInfo!.nom;
        remiseValeur = remiseInfo!.taux;
      } else {
        // Condition non atteinte : pas de remise
        remiseActive = false;
        total = sousTotal;
        remise = 0;
        remisenom = null;
        remiseValeur = null;
      }
    } else if (remiseInfo != null && remiseInfo!.montantCondition == 0) {
      // Remise sans condition (toujours active)
      remiseActive = true;
      if (remiseInfo!.tauxType.toLowerCase() == "pourcentage") {
        final reduction = sousTotal * remiseInfo!.taux / 100;
        total = sousTotal - reduction;
        remise = reduction;
      } else {
        total = sousTotal - remiseInfo!.taux;
        remise = remiseInfo!.taux;
        if (total < 0) total = 0;
      }
      remisenom = remiseInfo!.nom;
      remiseValeur = remiseInfo!.taux;
    } else {
      // Pas de remise
      remiseActive = false;
      total = sousTotal;
      remise = 0;
      remisenom = null;
      remiseValeur = null;
    }
  }
}

// ✅ Classe pour stocker les informations de remise
class RemiseInfo {
  final String nom;
  final double taux;
  final String tauxType; // "montant" ou "pourcentage"
  final double montantCondition; // Montant minimum pour activer la remise (0 = sans condition)

  RemiseInfo({
    required this.nom,
    required this.taux,
    required this.tauxType,
    this.montantCondition = 0,
  });
}