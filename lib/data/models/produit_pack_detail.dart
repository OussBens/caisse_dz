class ProduitPackDetail {
  int? id;  // Rendre l'id optionnel (int? au lieu de int)

  // --- Relation ---
  String packCode;
  String produitCode;

  // --- Nouveaux champs ---
  double prixUnitaire;
  int    quantite;
  double montant;

  // --- Audit ---
  DateTime dateCree;
  String   creeParCode;

  ProduitPackDetail({
    this.id,  // Optionnel
    required this.packCode,
    required this.produitCode,
    required this.prixUnitaire,
    required this.quantite,
    required this.montant,
    required this.dateCree,
    required this.creeParCode
  });

  // ----------------------------------------------------
  // map -> Objet
  // ----------------------------------------------------
  factory ProduitPackDetail.fromMap(Map<String, dynamic> map) {
    return ProduitPackDetail(
        id:           map['id'],
        packCode:     map['pack_code'],
        produitCode:  map['produit_code'],
        prixUnitaire: (map['prix_unitaire'] ?? 0).toDouble(),
        quantite:     map['quantite'] ?? 1,
        montant:      (map['montant'] ?? 0).toDouble(),
        dateCree:     DateTime.parse(map['date_cree']),
        creeParCode : map['cree_par_code']
    );
  }

  // ----------------------------------------------------
  // Objet -> map (sans l'id si null ou 0)
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    final map = {
      'pack_code': packCode,
      'produit_code': produitCode,
      'prix_unitaire': prixUnitaire,
      'quantite': quantite,
      'montant': montant,
      'date_cree': dateCree.toIso8601String(),
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