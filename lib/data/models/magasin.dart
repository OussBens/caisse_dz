class Magasin {
  int id;

  String  code;
  String  nom;
  String? adresse;
  bool    etat;
  String? observation;

  // Audit
  DateTime  dateCree;
  String    creeParCode;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  Magasin({
    required this.id,
    required this.code,
    required this.nom,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,

    this.adresse,
    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  factory Magasin.fromMap(Map<String, dynamic> map) {
    return Magasin(
      id            : map['id'],
      code          : map['code'],
      nom           : map['nom'],
      adresse       : map['adresse'],
      etat          : map['etat'] == 1,
      observation   : map['observation'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],

      modifParCode  : map['modif_par_code'],
      annulParCode  : map['annul_par_code'],
      motifAnnul    : map['motif_annul'],
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'code'          : code,
      'nom'           : nom,
      'adresse'       : adresse,
      'etat'          : etat ? 1 : 0,
      'observation'   : observation,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par_code' : creeParCode,

      'date_modif'    : dateModif?.toIso8601String(),
      'modif_par_code': modifParCode,
      'date_annul'    : dateAnnul?.toIso8601String(),
      'annul_par_code': annulParCode,
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
