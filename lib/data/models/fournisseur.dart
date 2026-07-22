class Fournisseur {
  int id;

  // Identité
  String code;
  String nom;
  String telephone;
  String? email;
  String? fax;

  // Adresse / localisation
  String? wilaya;
  String? adresse;

  // Classification
  String  type;       // grossiste / détaillant
  String  activity;
  bool    etat;

  String?   observation;

  // Audit
  DateTime  dateCree;
  String    creeParCode;
  DateTime? dateModif;
  String? modifPar;
  DateTime? dateAnnul;
  String? annulPar;
  String? motifAnnul;

  Fournisseur({
    required this.creeParCode,
    required this.telephone,
    required this.dateCree,
    required this.activity,
    required this.etat,
    required this.type,
    required this.code,
    required this.nom,
    required this.id,

    this.observation,
    this.motifAnnul,
    this.dateModif,
    this.dateAnnul,
    this.modifPar,
    this.annulPar,
    this.adresse,
    this.wilaya,
    this.email,
    this.fax,
  });

  factory Fournisseur.fromMap(Map<String, dynamic> map) {
    return Fournisseur(
      id            : map['id'],
      code          : map['code'],
      nom           : map['nom'],
      telephone     : map['telephone'],
      email         : map['email'],
      fax           : map['fax'],
      wilaya        : map['wilaya'],
      adresse       : map['adresse'],
      type          : map['type'],
      activity      : map['activity'],
      etat          : map['etat'] == 1,
      observation   : map['observation'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifPar      : map['modif_par'],
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulPar      : map['annul_par'],
      motifAnnul    : map['motif_annul'],
    );
  }


  Map<String, dynamic> toMap() {
    return{
      'id'            : id,
      'code'          : code,
      'nom'           : nom,
      'telephone'     : telephone,
      'email'         : email,
      'fax'           : fax,
      'wilaya'        : wilaya,
      'adresse'       : adresse,
      'type'          : type,
      'activity'      : activity,
      'etat'          : etat ? 1 : 0,
      'observation'   : observation,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par_code' : creeParCode,
      'date_modif'    : dateModif?.toIso8601String(),
      'modif_par'     : modifPar,
      'date_annul'    : dateAnnul?.toIso8601String(),
      'annul_par'     : annulPar,
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
