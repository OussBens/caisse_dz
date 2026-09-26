import 'package:collection/collection.dart';
import '../../core/tableau/caisse/tableau_caisse.dart';
import '../../core/utilis/stock_guard.dart';
import '../../Services/Mouvement.dart';
import 'produit.dart';

/// Vrai si la date du jour est comprise entre [debut] et [fin] (bornes
/// incluses, comparaison au jour près). [fin] == null signifie "sans fin".
bool remiseEstDansPeriode(DateTime debut, DateTime? fin, {DateTime? maintenant}) {
  final now = maintenant ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final d = DateTime(debut.year, debut.month, debut.day);
  if (today.isBefore(d)) return false;
  if (fin != null) {
    final f = DateTime(fin.year, fin.month, fin.day);
    if (today.isAfter(f)) return false;
  }
  return true;
}

/// Vérifie, avant de finaliser une vente, qu'aucun produit du panier ne
/// ferait passer son stock en négatif compte tenu du stock ACTUEL (calculé
/// depuis le journal des mouvements, scope [magasinCode] = la caisse en
/// cours de vente — le stock peut avoir changé depuis l'ajout au panier,
/// ex. une autre vente entre-temps, ou une entrée supprimée entre-temps).
/// Regroupe par code produit (un même produit peut apparaître dans
/// plusieurs lignes, ex. vendu à l'unité puis en boîte).
Future<(Produit, double quantiteNecessaire, double quantiteDisponible)?> premierProduitInsuffisantPourVente(
    List<ProduitPanier> produitsPanier, List<Produit> catalogue, {String? magasinCode}) async {
  final deltasParCode = <String, double>{};
  for (final p in produitsPanier) {
    deltasParCode[p.code] = (deltasParCode[p.code] ?? 0) - p.quantiteReelleEnPieces;
  }

  final totaux = await MouvementsServices.totauxParProduit(magasinCode: magasinCode);

  for (final entry in deltasParCode.entries) {
    final prod = catalogue.where((pr) => pr.code == entry.key).firstOrNull;
    if (prod == null || prod.service) continue;
    final quantiteDisponible = totaux.quantites[prod.code] ?? 0;
    if (!StockGuard.suffisant(quantiteDisponible, -entry.value, service: prod.service)) {
      return (prod, -entry.value, quantiteDisponible);
    }
  }
  return null;
}

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

  /// Remise sélectionnée mais dont la date du jour tombe hors de sa
  /// période [debut, fin] (utilisé pour le badge gris côté UI).
  bool get remiseHorsPeriode =>
      remiseInfo != null && !remiseEstDansPeriode(remiseInfo!.debut, remiseInfo!.fin);

  void recalculerTotaux() {
    double sousTotal = 0;
    double margeCalculee = 0;
    for (var p in produits) {
      sousTotal += p.prix * p.qte;
      margeCalculee += (p.prix - p.prixachat) * p.qte;
    }
    totalAchat = sousTotal;
    marge = margeCalculee;

    // ✅ Une remise sélectionnée mais hors période ne s'applique jamais,
    // même si la condition de montant est remplie.
    if (remiseInfo != null && remiseHorsPeriode) {
      remiseActive = false;
      total = sousTotal;
      remise = 0;
      remisenom = null;
      remiseValeur = null;
    } else if (remiseInfo != null && remiseInfo!.montantCondition > 0) {
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
  final DateTime debut;
  final DateTime? fin;

  RemiseInfo({
    required this.nom,
    required this.taux,
    required this.tauxType,
    required this.debut,
    this.fin,
    this.montantCondition = 0,
  });
}