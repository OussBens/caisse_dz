class ProduitMagasinDetail {
  int id;
  // --- Relation ---
  String magasinCode;
  String produitCode;
  // ⚠️ Le stock n'est plus stocké ici : il est calculé dynamiquement depuis
  // le journal des mouvements, voir MouvementsServices.quantiteProduit()/
  // totauxParProduit(magasinCode: ...).
  // Second stock parallèle (nombre de pièces) — voir Produit.nombre.
  double nombre;
  // --- Audit ---
  String    creeParCode;
  DateTime  dateCree;

  ProduitMagasinDetail({
    required this.id,
    required this.magasinCode,
    required this.produitCode,
    required this.dateCree,
    required this.creeParCode,
    this.nombre = 0,
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
      creeParCode : map['cree_par_code'],
      nombre      : (map['nombre'] as num?)?.toDouble() ?? 0,

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
      'cree_par_code' : creeParCode,
      'nombre'        : nombre,

    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
