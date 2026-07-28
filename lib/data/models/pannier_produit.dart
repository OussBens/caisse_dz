class PannierProduit {
  int     id;
  String  codePannier;
  String  codeProduit;

  double  quantite;
  double  prix;
  double  total;
  double  prixAchat;
  double  totalAchat;


  bool      etat; // "actif" ou "inactif"
  String    creeParCode;
  DateTime  creeLe;

  String?   modifParCode;
  DateTime? modifLe;
  String?   annulParCode;
  DateTime? annulLe;
  String?   motifAnnul;
  PannierProduit({
    required this.id,
    required this.codePannier,
    required this.codeProduit,
    required this.quantite,
    required this.prix,
    required this.total,
    required this.prixAchat,
    required this.totalAchat,
    required this.etat,
    required this.creeParCode,
    required this.creeLe,

    this.modifLe,
    this.modifParCode,
    this.annulLe,
    this.annulParCode,
    this.motifAnnul,
  });

  // ------------------------------
  // map → Objet
  // ------------------------------
  factory PannierProduit.fromMap(Map<String, dynamic> map) {
    return PannierProduit(
      id          : map['id'],
      etat        : map['etat'] == 1,
      prix        : map['prix'],
      total       : map['total'],
      prixAchat        : map['prix_achat'] ?? 0.0,
      totalAchat       : map['total_achat']?? 0.0,
      creeLe      : DateTime.parse(map['date_cree']),
      quantite    : map['quantite'],
      codeProduit : map['code_produit'],
      codePannier : map['code_pannier'],
      creeParCode : map['cree_par_code'],

      motifAnnul  : map['motif_annul'],
      modifParCode    : map['modif_par_code'],
      annulParCode    : map['annul_par_code'],
      annulLe     : map['annul_le'] != null
          ? DateTime.parse(map['annul_le'])
          : null,
      modifLe     : map['modif_le'] != null
          ? DateTime.parse(map['modif_le'])
          : null,
    );
  }

  // ------------------------------
  // Objet → map
  // ------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'prix'          : prix,
      'etat'          : etat ? 1 : 0,
      'total'         : total,
      'total_achat'         : totalAchat,
      'prix_achat'         : prixAchat,
      'quantite'      : quantite,
      'date_cree'     : creeLe.toIso8601String(),
      'code_pannier'   : codePannier,
      'code_produit'  : codeProduit,
      'cree_par_code' : creeParCode,

      'modif_par_code'     : modifParCode,
      'annul_par_code'     : annulParCode,
      'date_annul'    : annulLe?.toIso8601String(),
      'date_modif'    : modifLe?.toIso8601String(),
      'motif_annul'   : motifAnnul,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
