class Client {
  int id;

  // Identité
  String  code;
  String  nom;
  String  telephone;

  String? email;
  String? fax;

  // Adresse
  String  wilaya;
  String? adresse;

  // Classification
  bool    etat;
  String type;
  String? activity;

  // Identifiants administratifs (ALG)
  String? nif;
  String? nis;
  String? nrc;


  // Banque
  String? rib;
  String? banque;

  String?   observation;
  DateTime? dernierAchat;

  // Audit
  DateTime  dateCree;
  String    creeParCode;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String?   modifParCode;
  String?   annulPar;
  String?   motifAnnul;

  Client({

    required this.id,
    required this.nom,
    required this.etat,
    required this.type,
    required this.code,
    required this.wilaya,
    required this.dateCree,
    required this.telephone,
    required this.creeParCode,

    this.observation,
    this.activity,
    this.adresse,
    this.email,
    this.fax,
    this.nif,
    this.nis,
    this.nrc,

    this.rib,
    this.banque,
    this.annulPar,
    this.modifParCode,
    this.dateAnnul,
    this.dateModif,
    this.motifAnnul,
    this.dernierAchat,

  });

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(

      id            : map['id'],
      nom           : map['nom'],
      etat          : map['etat'] == 1,
      code          : map['code'],
      type          : map['type'],
      wilaya        : map['wilaya'],
      dateCree      : DateTime.parse(map['date_cree']),
      telephone     : map['telephone'],
      creeParCode   : map['cree_par_code'],


      observation   : map['observation'],
      activity      : map['activity'],
      adresse       : map['adresse'],
      email         : map['email'],
      fax           : map['fax'],
      nif           : map['nif'],
      nis           : map['nis'],
      nrc           : map['nrc'],

      rib           : map['rib'],
      banque        : map['banque'],
      modifParCode      : map['modif_par_code'],
      annulPar      : map['annul_par'],
      motifAnnul    : map['motif_annul'],
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      dernierAchat  : map['dernier_achat'] != null
          ? DateTime.parse(map['dernier_achat'])
          : null,
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,

    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'nom'           : nom,
      'code'          : code,
      'etat'          : etat ? 1 : 0,
      'type'          : type,
      'wilaya'        : wilaya,
      'telephone'     : telephone,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par_code' : creeParCode,

      'observation' : observation,
      'activity'    : activity,
      'adresse'     : adresse,
      'email'       : email,
      'fax'         : fax,
      'nif'         : nif,
      'nis'         : nis,
      'nrc'         : nrc,

      'rib'           : rib,
      'banque'        : banque,
      'dernier_achat' : dernierAchat?.toIso8601String(),
      'date_modif'    : dateModif?.toIso8601String(),
      'modif_par_code'     : modifParCode,
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
