class Remise {
  int       id;
  bool      etat;
  String    code;
  String    nom;
  String    type;
  String    tauxType;
  double    taux;
  DateTime  debut;

  double?   montant;
  String?   observation;
  DateTime? fin;

  String    creeParCode;
  String    creePar;
  DateTime  creeLe;


  DateTime? modifLe;
  DateTime? annulLe;
  String? modifPar;
  String? annulPar;
  String? motifAnnul;

  Remise({
    required this.tauxType,
    required this.debut,
    required this.etat,
    required this.code,
    required this.type,
    required this.taux,
    required this.nom,
    required this.id,
    required this.fin,
    required this.creePar,
    required this.creeParCode,
    required this.creeLe,
    this.montant,
    this.observation,
    this.modifPar,
    this.modifLe,
    this.annulPar,
    this.annulLe,
    this.motifAnnul,
  });

  factory Remise.fromMap(Map<String, dynamic> map) {
    return Remise(
      id          : map['id'],
      nom         : map['nom'],
      code        : map['code'],
      etat        : map['etat'] == 1,
      type        : map['type'],
      debut       : DateTime.parse(map['debut']),
      creeLe      : DateTime.parse(map['cree_le']),
      montant     : map['montant'] ?? 0.0,
      creePar     : map['cree_par'],
      tauxType    : map['taux_type'],
      creeParCode : map['cree_par_code'],
      observation : map['observation'],

      modifPar    : map['modif_par'],
      annulPar    : map['annul_par'],
      motifAnnul  : map['motif_annul'],
      taux        : map['taux'] ?? 0.0,
      fin         : map['fin'] != null
          ? DateTime.parse(map['fin'])
          : null,
      annulLe     : map['annul_le'] != null
          ? DateTime.parse(map['annul_le'])
          : null,
      modifLe     : map['modif_le'] != null
          ? DateTime.parse(map['modif_le'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'code'          : code,
      'nom'           : nom,
      'etat'          : etat ? 1 : 0,
      'type'          : type,
      'observation'   : observation,
      'montant'       : montant,
      'taux_type'     : tauxType,
      'taux'          : taux,
      'cree_par_code' : creeParCode,
      'cree_par'      : creePar,
      'debut'         : debut.toIso8601String(),
      'cree_le'       : creeLe.toIso8601String(),

      'modif_par'     : modifPar,
      'annul_par'     : annulPar,
      'motif_annul'   : motifAnnul,
      'modif_le'      : modifLe?.toIso8601String(),
      'annul_le'      : annulLe?.toIso8601String(),
      'fin'           : fin?.toIso8601String(),
    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
