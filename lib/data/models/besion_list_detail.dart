class BesoinListDetail {
  int id;

  // --- Relations ---
  String besoinListCode;
  String ProduitNom;
  String ProduitCode;
  double prix; // nouveau
  double montant; // nouveau (prix * quantite)
  double quantite;

  // --- Audit ---
  DateTime dateCree;
  String creeParCode;

  DateTime? dateModif;
  String? modifParCode;
  DateTime? dateAnnul;
  String? annulPar;
  String? motifAnnul;

  BesoinListDetail({
    required this.id,
    required this.besoinListCode,
    required this.ProduitNom,
    required this.ProduitCode,
    required this.quantite,
    required this.prix, // valeur par défaut
    required this.dateCree,
    required this.creeParCode,
    double? montant, // calculé automatiquement
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,
  }) : montant = montant ?? (quantite * (prix)); // calcul si non fourni

  // ================= map =================

  factory BesoinListDetail.fromMap(Map<String, dynamic> map) {
    final q = map['quantite'];
    final p = map['prix'];
    return BesoinListDetail(
      id: map['id'],
      besoinListCode  : map['besion_list_code'],
      ProduitNom      : map['produit_nom'],
      ProduitCode     : map['produit_code'],
      quantite        : q,
      prix            : p,
      montant         : map['montant'] ?? q * p,
      dateCree        : DateTime.parse(map['date_cree']),
      creeParCode     : map['cree_par_code'],

      dateModif       : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifParCode        : map['modif_par_code'],
      dateAnnul       : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulPar        : map['annul_par'],
      motifAnnul      : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'                : id,
      'prix'              : prix,
      'montant'           : montant,
      'quantite'          : quantite,
      'date_cree'         : dateCree.toIso8601String(),
      'produit_nom'       : ProduitNom,
      'produit_code'      : ProduitCode,
      'cree_par_code'     : creeParCode,
      'besion_list_code'  : besoinListCode,

      'modif_par_code'         : modifParCode,
      'annul_par'         : annulPar,
      'date_annul'        : dateAnnul?.toIso8601String(),
      'date_modif'        : dateModif?.toIso8601String(),
      'motif_annul'       : motifAnnul,
    };
  }
}
