class Categorie {
  int       id;
  String    nom;
  String    code;
  bool      etat;

  DateTime  dateCree;
  String    creeParCode;

  String?   modifParCode;
  String?   annulPar;
  String?   motifAnnul;
  String?   observation;
  DateTime? dateAnnul;
  DateTime? dateModif;

  // -----------------------------------------------------------
  // Constructeur
  // -----------------------------------------------------------
  Categorie({
    required this.id,
    required this.nom,
    required this.code,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,

    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,
  });

  // -----------------------------------------------------------
  // JSON -> Objet
  // -----------------------------------------------------------
  factory Categorie.fromMap(Map<String, dynamic> map) {
    return Categorie(
      id:           map['id'],
      nom:          map['nom'],
      code:         map['code'],
      etat:         map['etat'] == 1,
      observation:  map['observation'],
      creeParCode:  map['cree_par_code'],
      dateCree:     DateTime.parse(map['date_cree']),

      dateModif:    map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
      dateAnnul:    map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
      motifAnnul:   map['motif_annul'],
      modifParCode:     map['modif_par_code'],
      annulPar:     map['annul_par'],
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
      'cree_par_code' : creeParCode,
      'date_cree'     : dateCree.toIso8601String(),

      'modif_par_code'     : modifParCode,
      'annul_par'     : annulPar,
      'motif_annul'   : motifAnnul,
      'observation'   : observation,
      'date_annul'    : dateAnnul?.toIso8601String(),
      'date_modif'    : dateModif?.toIso8601String(),
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}