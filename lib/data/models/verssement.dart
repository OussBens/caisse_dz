class Verssement {
  int       id;
  String    code;

  String    typebeneficiare;///client four///client four
  String    type;//list type versment

  String    sense;/// entre sortie
  String    caisse;/// entre sortie

  bool      etat;
  double    montant;
  String    beneficiare;
  String    mode_paiement;

  DateTime  date;

  DateTime  dateCree;
  String    creeParCode;


  String?   observation;
  // Audit
  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  Verssement({

    required this.typebeneficiare,
    required this.mode_paiement,
    required this.creeParCode,
    required this.beneficiare,
    required this.dateCree,
    required this.montant,
    required this.sense,
    required this.caisse,
    required this.etat,
    required this.date,
    required this.code,
    required this.type,
    required this.id,

    this.observation,
    this.motifAnnul,
    this.dateModif,
    this.dateAnnul,
    this.modifParCode,
    this.annulParCode,
  });

  factory Verssement.fromMap(Map<String, dynamic> map) {
    return
      Verssement(
        id              : map['id'],
        code            : map['code'],
        typebeneficiare : map['typebeneficiare'],
        type            : map['type'],
        sense           : map['sense'],
        caisse           : map['caisse'],
        etat            : map['etat'] == 1,
        observation     : map['observation'],
        montant         : map['montant'],
        beneficiare     : map['beneficiare'],
        mode_paiement   : map['mode_paiement'],
        dateCree        : DateTime.parse(map['date_cree']),
        creeParCode     : map['cree_par_code'],
        date            : DateTime.parse(map['date']),
        dateModif       : map['date_modif'] != null
            ? DateTime.parse(map['date_modif'])
            : null,
        modifParCode        : map['modif_par_code'],
        dateAnnul       : map['date_annul'] != null
            ? DateTime.parse(map['date_annul'])
            : null,
        annulParCode        : map['annul_par_code'],
        motifAnnul      : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'              : id,
      'code'            : code,
      'typebeneficiare' : typebeneficiare,
      'type'            : type,
      'sense'           : sense,
      'caisse'           : caisse,
      'etat'            : etat ? 1 : 0,
      'observation'     : observation,
      'montant'         : montant,
      'beneficiare'     : beneficiare,
      'mode_paiement'   : mode_paiement,
      'date'            : date.toIso8601String(),
      'date_cree'       : dateCree.toIso8601String(),
      'cree_par_code'   : creeParCode,
      'date_modif'      : dateModif?.toIso8601String(),
      'modif_par_code'       : modifParCode,
      'date_annul'      : dateAnnul?.toIso8601String(),
      'annul_par_code'       : annulParCode,
      'motif_annul'     : motifAnnul,
    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
