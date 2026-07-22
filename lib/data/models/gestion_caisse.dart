class CaisseGestion {
  int     id;
  bool    etat;
  String  nomCaisse;
  String  code;
  String  magasin;
  String  magasinCode;
  String  typecaisse;
  double  soldeInitial;

  String? observation;
  
  // Champs d’audit
  String creeParCode;
  DateTime dateCree;

  
  String? modifParCode;
  String? annulPar;
  String? motifAnnul;
  DateTime? dateAnnul;
  DateTime? dateModif;

  // -----------------------------------------------------------
  // Constructeur
  // -----------------------------------------------------------
  CaisseGestion({
    required this.id,
    required this.etat,
    required this.code,
    required this.magasin,
    required this.dateCree,
    required this.nomCaisse,
    required this.typecaisse,
    required this.magasinCode,
    required this.creeParCode,
    required this.soldeInitial,

    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,
  });

  // -----------------------------------------------------------
  // map -> Objet
  // -----------------------------------------------------------
  factory CaisseGestion.fromMap(Map<String, dynamic> map) {
    return CaisseGestion(
      id            : map['id'],
      code          : map['code'],
      etat          : map['etat'] == 1,
      magasin       : map['magasin'],
      dateCree      : DateTime.parse(map['date_cree']),
      nomCaisse     : map['nom_caisse'],
      typecaisse    : map['typecaisse'],
      magasinCode   : map['magasin_code'],
      creeParCode   : map['cree_par_code'],
      soldeInitial  : map['solde_initial'],

      observation   : map['observation'],
      modifParCode      : map['modif_par_code'],
      annulPar      : map['annul_par'],
      motifAnnul    : map['motif_annul'],
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }

  // -----------------------------------------------------------
  // Objet -> map
  // -----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'code'          : code,
      'etat'          : etat ? 1 : 0,
      'magasin'       : magasin,
      'magasin_code'  : magasinCode,
      'date_cree'     : dateCree.toIso8601String(),
      'typecaisse'    : typecaisse,
      'nom_caisse'    : nomCaisse,
      'cree_par_code' : creeParCode,
      'solde_initial' : soldeInitial,

      'observation'   : observation,
      'modif_par_code'     : modifParCode,
      'annul_par'     : annulPar,
      'motif_annul'   : motifAnnul,
      'date_modif'    : dateModif?.toIso8601String(),
      'date_annul'    : dateAnnul?.toIso8601String(),
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
