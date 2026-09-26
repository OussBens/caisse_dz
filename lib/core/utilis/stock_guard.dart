/// Vérifie, avant toute création/modification/suppression d'une opération
/// de stock (vente, entrée/smart scan, retour, sortie), que le retrait
/// demandé ne ferait pas passer la quantité du produit sous zéro — voir
/// le cas réel : entrée de 50 pièces, vente de 20, puis suppression de
/// l'entrée de 50 -> stock qui devient négatif si non vérifié.
///
/// [quantiteDisponible] doit venir du calcul dynamique
/// (MouvementsServices.quantiteProduit/totauxParProduit) — Produit.quantite
/// (compteur en cache, sujet à dérive) n'est plus la source de vérité.
/// L'appelant est responsable de fournir la bonne portée (magasin
/// spécifique ou tous magasins confondus selon le contexte).
class StockGuard {
  /// True si retirer [quantiteRetiree] de [quantiteDisponible] reste >= 0.
  /// Les produits "service" n'ont pas de stock à gérer (toujours true).
  static bool suffisant(double quantiteDisponible, double quantiteRetiree, {required bool service}) {
    if (service) return true;
    return quantiteDisponible - quantiteRetiree >= 0;
  }
}
