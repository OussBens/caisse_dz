class Magasin {

  int     id;
  String  code;
  String  nom;
  bool    etat;

  String? adresse;
  String? observation;
  // Audit
  String    creeParCode;
  DateTime  dateCree;

  DateTime? dateModif;
  String? modifPar;
  DateTime? dateAnnul;
  String? annulPar;
  String? motifAnnul;

  Magasin({
    required this.creeParCode,
    required this.dateCree,
    required this.etat,
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
  });

  factory Magasin.fromMap(Map<String, dynamic> map) {
    return Magasin(
      id            : map['id'],
      nom           : map['nom'],
      etat          : map['etat'] == 1,
      code          : map['code'],
      adresse       : map['adresse'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],

      observation   : map['observation'],
      modifPar      : map['modif_par'],
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

  Map<String, dynamic> toMap(){
    return{
      'id'            : id,
      'nom'           : nom,
      'code'          : code,
      'adresse'       : adresse,
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
