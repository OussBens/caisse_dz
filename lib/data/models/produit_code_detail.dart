class ProduitCodeDetail {
  int     id;

  // --- Relation ---
  String CodeBar;
  String produitCode;

  // --- Audit ---
  DateTime dateCree;
  String   creeParCode;

  ProduitCodeDetail({
    required this.id,
    required this.produitCode,
    required this.CodeBar,
    required this.dateCree,
    required this.creeParCode,
  });

  // ----------------------------------------------------
  // map -> Objet
  // ----------------------------------------------------
  factory ProduitCodeDetail.fromMap(Map<String, dynamic> map) {
    return ProduitCodeDetail(
        id:           map['id'],
        produitCode:  map['produit_code'],
        dateCree:     DateTime.parse(map['date_cree']),
        creeParCode:  map['cree_par_code'],
        CodeBar:      map['codebar'],
    );
  }

  // ----------------------------------------------------
  // Objet -> map
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'produit_code': produitCode,
      'date_cree': dateCree.toIso8601String(),
      'cree_par_code': creeParCode,
      'codebar': CodeBar,

    };
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
