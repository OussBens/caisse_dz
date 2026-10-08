/// Répartition d'une quantité entre les magasins d'un utilisateur — un seul
/// endroit pour les règles multi-magasin, sans accès base (fonctions pures,
/// testées dans test/repartition_stock_test.dart).
///
/// [ordre] = magasins de l'utilisateur, principal en tête
/// (UtilisateurMagasinServices.magasinsUtilisateur) ; [disponible] = stock
/// actuel par magasin (MouvementsServices).
///
///   Vente (panier)        → [sequentielle] : magasin 1, puis 2…
///   Retour fournisseur,
///   Sortie                → [unMagasinSinonSequentielle] : un magasin qui a
///                           toute la quantité, sinon réparti dans l'ordre
///   Retour client         → [retourVersOrigine] : vers les magasins d'où
///                           la vente est sortie, le dernier servi d'abord
///   Entrée / Smart Scan   → magasin principal (ordre.first)
///   Distribution          → [distributionValide] : total conservé
class PartMagasin {
  final String magasinCode;
  final double quantite;

  const PartMagasin(this.magasinCode, this.quantite);

  @override
  bool operator ==(Object other) => other is PartMagasin && other.magasinCode == magasinCode && other.quantite == quantite;

  @override
  int get hashCode => Object.hash(magasinCode, quantite);

  @override
  String toString() => '$magasinCode:$quantite';
}

class RepartitionStock {
  static const double _epsilon = 1e-9;

  /// Prend dans les magasins dans l'ordre, chacun jusqu'à son stock
  /// disponible. Si le total ne suffit pas (la caisse limite déjà la vente
  /// au disponible), le reste est imputé au magasin principal.
  static List<PartMagasin> sequentielle(double quantite, List<String> ordre, Map<String, double> disponible) {
    if (quantite <= 0 || ordre.isEmpty) return const [];
    final parts = <String, double>{};
    var reste = quantite;
    for (final m in ordre) {
      if (reste <= _epsilon) break;
      final dispo = (disponible[m] ?? 0).clamp(0, double.infinity).toDouble();
      if (dispo <= _epsilon) continue;
      final pris = dispo < reste ? dispo : reste;
      parts[m] = (parts[m] ?? 0) + pris;
      reste -= pris;
    }
    if (reste > _epsilon) {
      parts[ordre.first] = (parts[ordre.first] ?? 0) + reste;
    }
    return _enListe(parts, ordre);
  }

  /// Le premier magasin (dans l'ordre) qui a toute la quantité ; sinon
  /// répartition [sequentielle].
  static List<PartMagasin> unMagasinSinonSequentielle(double quantite, List<String> ordre, Map<String, double> disponible) {
    if (quantite <= 0 || ordre.isEmpty) return const [];
    for (final m in ordre) {
      if ((disponible[m] ?? 0) + _epsilon >= quantite) return [PartMagasin(m, quantite)];
    }
    return sequentielle(quantite, ordre, disponible);
  }

  /// Retour client : remet [quantite] dans les magasins d'où la vente est
  /// sortie. [sorties] = parts sorties par la vente, dans l'ordre où elles
  /// ont été prises ; [dejaRetourne] = quantités déjà rendues par magasin
  /// (retours précédents). On rend d'abord au dernier magasin servi.
  /// Au-delà de ce qui a été vendu, le surplus va au premier magasin servi.
  static List<PartMagasin> retourVersOrigine(
    double quantite,
    List<PartMagasin> sorties, {
    Map<String, double> dejaRetourne = const {},
  }) {
    if (quantite <= 0 || sorties.isEmpty) return const [];
    final restantes = <String, double>{};
    for (final s in sorties) {
      restantes[s.magasinCode] = (restantes[s.magasinCode] ?? 0) + s.quantite;
    }
    // Ce qui a déjà été rendu à un magasin ne peut plus y être rendu.
    for (final e in dejaRetourne.entries) {
      if (restantes.containsKey(e.key)) {
        restantes[e.key] = (restantes[e.key]! - e.value).clamp(0, double.infinity).toDouble();
      }
    }
    final ordreInverse = sorties.map((s) => s.magasinCode).toSet().toList().reversed.toList();

    final parts = <String, double>{};
    var reste = quantite;
    for (final m in ordreInverse) {
      if (reste <= _epsilon) break;
      final possible = restantes[m]!;
      if (possible <= _epsilon) continue;
      final rendu = possible < reste ? possible : reste;
      parts[m] = (parts[m] ?? 0) + rendu;
      reste -= rendu;
    }
    if (reste > _epsilon) {
      final premier = sorties.first.magasinCode;
      parts[premier] = (parts[premier] ?? 0) + reste;
    }
    return _enListe(parts, ordreInverse);
  }

  /// Distribution : le total réparti doit rester égal au total à répartir
  /// (déplacement de stock entre magasins, jamais de création).
  static bool distributionValide(double total, Map<String, double> cibles) {
    if (cibles.values.any((q) => q < 0)) return false;
    final somme = cibles.values.fold<double>(0, (a, b) => a + b);
    return (somme - total).abs() < 1e-6;
  }

  /// Mouvements à créer pour passer de [actuel] à [cibles] : delta positif
  /// = entrée dans le magasin, négatif = sortie.
  static Map<String, double> deltasDistribution(Map<String, double> actuel, Map<String, double> cibles) {
    final deltas = <String, double>{};
    for (final m in {...actuel.keys, ...cibles.keys}) {
      final d = (cibles[m] ?? 0) - (actuel[m] ?? 0);
      if (d.abs() > 1e-6) deltas[m] = d;
    }
    return deltas;
  }

  static List<PartMagasin> _enListe(Map<String, double> parts, List<String> ordre) {
    return [
      for (final m in ordre)
        if ((parts[m] ?? 0) > _epsilon) PartMagasin(m, parts[m]!),
    ];
  }
}
