class SousCategorie {
  int       id;
  int       categorieId;// id de la catégorie parente

  bool      etat;        // actif, inactif

  String    nom;
  String    code;
  String    categorieCode;

  String    creeParCode;
  DateTime  dateCree;

  String?   observation;
  String?   modifParCode;
  String?   annulParCode;
  String?   motifAnnul;
  DateTime? dateAnnul;
  DateTime? dateModif;

  // -----------------------------------------------------------
  // Constructeur
  // -----------------------------------------------------------
  SousCategorie({
    required this.id,
    required this.nom,
    required this.etat,
    required this.code,
    required this.dateCree,
    required this.creeParCode,
    required this.categorieId,
    required this.categorieCode,

    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  // -----------------------------------------------------------
  // map -> Objet
  // -----------------------------------------------------------
  factory SousCategorie.fromMap(Map<String, dynamic> map) {
    return SousCategorie(
      id            : map['id'],
      nom           : map['nom'],
      code          : map['code'],
      etat          : map['etat'] == 1,
      categorieId   : map['categorie_id'],
      categorieCode : map['categorie_code'],
      creeParCode   : map['cree_par_code'],
      dateCree      : DateTime.parse(map['date_cree']),

      observation   : map['observation'],
      modifParCode      : map['modif_par_code'],
      annulParCode      : map['annul_par_code'],
      motifAnnul    : map['motif_annul'],
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'] as String)
          : null,
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'] as String)
          : null,
    );
  }
  // -----------------------------------------------------------
  // Objet -> map
  // -----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'nom'           : nom,
      'code'          : code,
      'etat'          : etat ? 1 : 0,
      'date_cree'     : dateCree.toIso8601String(),
      'categorie_id'  : categorieId,
      'categorie_code' : categorieCode,
      'cree_par_code' : creeParCode,

      'annul_par_code'     : annulParCode,
      'modif_par_code'     : modifParCode,
      'motif_annul'   : motifAnnul,
      'observation'   : observation,
      'date_modif'    : dateModif?.toIso8601String(),
      'date_annul'    : dateAnnul?.toIso8601String(),
    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
