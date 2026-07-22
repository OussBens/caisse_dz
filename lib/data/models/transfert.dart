class TransfertCaisse {
  int       id;
  String    code;
  DateTime  dateTransfert;

  /// Caisse source (expéditrice)
  String caisseExp;
  String caisseExpCode;

  /// Caisse destination
  String caisseDest;
  String caisseDestCode;

  double  montant;
  bool    etat;

  String? observation;
  // -----------------------------
  // Champs d’audit
  // -----------------------------
  DateTime  dateCree;
  String    creePar;
  String    creeParCode;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String?   motifAnnul;
  String?   modifPar;
  String?   annulPar;

  // -----------------------------
  // Constructeur
  // -----------------------------
  TransfertCaisse({
    required this.id,
    required this.code,
    required this.dateTransfert,
    required this.caisseExp,
    required this.caisseDest,
    required this.montant,
    required this.etat,
    required this.dateCree,
    required this.creePar,
    required this.creeParCode,
    required this.caisseDestCode,
    required this.caisseExpCode,

    this.observation,
    this.dateModif,
    this.modifPar,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,
  });

  // -----------------------------
  // map -> Objet
  // -----------------------------
  factory TransfertCaisse.fromMap(Map<String, dynamic> map) {
    return TransfertCaisse(
      id              : map['id'],
      code            : map['code'],
      dateTransfert   : DateTime.parse(map['date_transfert']),
      caisseExp       : map['caisse_exp'],
      caisseDest      : map['caisse_dest'],
      caisseDestCode  : map['caisse_dest_code'],
      caisseExpCode   : map['caisse_exp_code'],
      montant         : map['montant'],
      etat            : map['etat'] == 1,
      dateCree        : DateTime.parse(map['date_cree']),
      creePar         : map['cree_par'],
      creeParCode     : map['cree_par_code'],

      observation     : map['observation'],
      modifPar        : map['modif_par'],
      annulPar        : map['annul_par'],
      motifAnnul      : map['motif_annul'],
      dateAnnul       : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      dateModif       : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }

  // -----------------------------
  // Objet -> map
  // -----------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'                : id,
      'code'              : code,
      'date_transfert'    : dateTransfert.toIso8601String(),
      'caisse_exp'        : caisseExp,
      'caisse_dest'       : caisseDest,
      'montant'           : montant,
      'etat'              : etat ? 1 : 0,
      'date_cree'         : dateCree.toIso8601String(),
      'cree_par'          : creePar,
      'cree_par_code'     : creeParCode,
      'caisse_exp_code'   : caisseExpCode,
      'caisse_dest_code'  : caisseDestCode,

      'observation'       : observation,
      'date_modif'        : dateModif?.toIso8601String(),
      'modif_par'         : modifPar,
      'date_annul'        : dateAnnul?.toIso8601String(),
      'annul_par'         : annulPar,
      'motif_annul'       : motifAnnul,
    };
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
