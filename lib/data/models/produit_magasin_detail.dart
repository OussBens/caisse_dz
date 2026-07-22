class ProduitMagasinDetail {
  int id;
  // --- Relation ---
  String magasinCode;
  String produitCode;
  double quantite;
  // --- Audit ---
  String    creePar;
  String    creeParCode;
  DateTime  dateCree;

  ProduitMagasinDetail({
    required this.id,
    required this.magasinCode,
    required this.produitCode,
    required this.dateCree,
    required this.creePar,
    required this.creeParCode,
    this.quantite = 0 ,
  }
  );

  // ----------------------------------------------------
  // map -> Objet
  // ----------------------------------------------------
  factory ProduitMagasinDetail.fromMap(Map<String, dynamic> map) {
    return ProduitMagasinDetail(

      id          : map['id'],
      magasinCode : map['magasin_code'],
      produitCode : map['produit_code'],
      dateCree    : DateTime.parse(map['date_cree']),
      creePar     : map['cree_par'],
      creeParCode : map['cree_par_code'],
      quantite    : map['quantite'],

    );
  }

  // ----------------------------------------------------
  // Objet -> map
  // ----------------------------------------------------
  Map<String, dynamic> toMap() {
    return {

      'id'            : id,
      'magasin_code'  : magasinCode,
      'produit_code'  : produitCode,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par'      : creePar,
      'cree_par_code' : creeParCode,
      'quantite'      : quantite,

    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
