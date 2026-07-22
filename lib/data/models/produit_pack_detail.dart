class ProduitPackDetail {
  int? id;  // Rendre l'id optionnel (int? au lieu de int)

  // --- Relation ---
  String packNom;
  String packCode;
  String produitNom;
  String produitCode;

  // --- Nouveaux champs ---
  double prixUnitaire;
  int    quantite;
  double montant;

  // --- Audit ---
  DateTime dateCree;
  String   creePar;
  String   creeParCode;

  ProduitPackDetail({
    this.id,  // Optionnel
    required this.packNom,
    required this.packCode,
    required this.produitNom,
    required this.produitCode,
    required this.prixUnitaire,
    required this.quantite,
    required this.montant,
    required this.dateCree,
    required this.creePar,
    required this.creeParCode
  });

  // ----------------------------------------------------
  // map -> Objet
  // ----------------------------------------------------
  factory ProduitPackDetail.fromMap(Map<String, dynamic> map) {
    return ProduitPackDetail(
        id:           map['id'],
        packNom:      map['pack_nom'],
        packCode:     map['pack_code'],
        produitNom:   map['produit_nom'],
        produitCode:  map['produit_code'],
        prixUnitaire: (map['prix_unitaire'] ?? 0).toDouble(),
        quantite:     map['quantite'] ?? 1,
        montant:      (map['montant'] ?? 0).toDouble(),
        dateCree:     DateTime.parse(map['date_cree']),
        creePar:      map['cree_par'],
        creeParCode : map['cree_par_code']
    );
  }

  // ----------------------------------------------------
  // Objet -> map (sans l'id si null ou 0)
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    final map = {
      'pack_nom': packNom,
      'pack_code': packCode,
      'produit_nom': produitNom,
      'produit_code': produitCode,
      'prix_unitaire': prixUnitaire,
      'quantite': quantite,
      'montant': montant,
      'date_cree': dateCree.toIso8601String(),
      'cree_par': creePar,
      'cree_par_code': creeParCode,
    };

    // N'ajouter l'id que s'il est non null et > 0
    if (id != null && id! > 0) {
      map['id'] = id!;
    }

    return map;
  }

  // Méthode pour recalculer le montant
  void calculerMontant() {
    montant = prixUnitaire * quantite;
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}