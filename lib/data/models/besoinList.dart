class BesoinList {
  int       id;
  int       nombreArticle;

  bool      etat;

  double    montant;
  double    quantite;

  String    code;
  String    numero;
  String    fournisseur;

  DateTime  date;

  String? observation;
  // Audit
  DateTime dateCree;
  String   creeParCode;

  DateTime? dateModif;
  String? modifParCode;
  DateTime? dateAnnul;
  String? annulPar;
  String? motifAnnul;

  BesoinList({
    required this.id,
    required this.code,
    required this.numero,
    required this.date,
    required this.montant,
    required this.nombreArticle,
    required this.quantite,
    required this.fournisseur,
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

  factory BesoinList.fromMap(Map<String, dynamic> map){
    return BesoinList(
      id            : map['id'],
      code          : map['code'],
      numero        : map['numero'],
      date          : DateTime.parse(map['date']),
      montant       : map['montant'],
      nombreArticle : map['nomber_article'],
      quantite      : map['quantite'],
      fournisseur   : map['fournisseur'],
      etat          : map['etat'] == 1 ,
      observation   : map['observation'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],

      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifParCode      : map['modif_par_code'],
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulPar      : map['annul_par'],
      motifAnnul    : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'              : id,
      'code'            : code,
      'numero'          : numero,
      'date'            : date.toIso8601String(),
      'montant'         : montant,
      'nomber_article'  : nombreArticle,
      'quantite'        : quantite,
      'fournisseur'     : fournisseur,
      'etat'            : etat ? 1 : 0,
      'observation'     : observation,
      'date_cree'       : dateCree.toIso8601String(),
      'cree_par_code'   : creeParCode,

      'date_modif'      : dateModif?.toIso8601String(),
      'modif_par_code'       : modifParCode,
      'date_annul'      : dateAnnul?.toIso8601String(),
      'annul_par'       : annulPar,
      'motif_annul'     : motifAnnul,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
