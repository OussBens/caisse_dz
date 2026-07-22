class Role {
  int id;
  String code;
  String rolenom;
  bool etat;
  String? observation;

  // Audit
  DateTime dateCree;
  String creeParCode;

  DateTime? dateModif;
  String? modifPar;
  DateTime? dateAnnul;
  String? annulPar;
  String? motifAnnul;

  Role({
    required this.creeParCode,
    required this.dateCree,
    required this.rolenom,
    required this.etat,
    required this.code,
    required this.id,
    this.observation,
    this.motifAnnul,
    this.dateAnnul,
    this.dateModif,
    this.modifPar,
    this.annulPar,
  });

  factory Role.fromMap(Map<String, dynamic> map){
    return  Role(
      id                : map['id'],
      code              : map['code'],
      etat              : map['etat'] == 1,
      observation       : map['observation'],
      rolenom           : map['rolenom'],
      creeParCode       : map['cree_par_code'],
      dateCree          : DateTime.parse(map['date_cree']),
      dateModif         : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifPar          : map['modif_par'],
      dateAnnul         : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulPar          : map['annul_par'],
      motifAnnul        : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() => {
    'id'                  : id,
    'etat'                : etat ? 1 : 0,
    'code'                : code,
    'rolenom'             : rolenom,
    'date_cree'           : dateCree.toIso8601String(),
    'cree_par_code'       : creeParCode,

    'observation'         : observation,
    'date_modif'          : dateModif?.toIso8601String(),
    'modif_par'           : modifPar,
    'date_annul'          : dateAnnul?.toIso8601String(),
    'annul_par'           : annulPar,
    'motif_annul'         : motifAnnul,
  };  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
