class Utilisateur {
  int id;

  String username;
  String password;
  String telephone;
  String code;
  String role; // Admin Caissier Magasinier
  String role_code;
  DateTime dernierAcces;

  double credit;

  bool etat;

  String? observation;

  // Audit
  DateTime  dateCree;
  String    creeParCode;
  
  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  Utilisateur({
    required this.dernierAcces,
    required this.creeParCode,
    required this.telephone,
    required this.role_code,
    required this.dateCree,
    required this.username,
    required this.password,
    required this.credit,
    required this.code,
    required this.role,
    required this.etat,
    required this.id,
    
    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
    
  });

  factory Utilisateur.fromMap(Map<String, dynamic> map){
    return Utilisateur(
      id            : map['id'],
      code          : map['code'],
      role          : map['role'],
      etat          : map['etat'] == 1,
      credit        : map['credit'],
      username      : map['username'],
      password      : map['password'],
      dateCree      : DateTime.parse(map['date_cree']),
      role_code     : map['role_code'],
      telephone     : map['telephone'],
      creeParCode   : map['cree_par_code'],
      dernierAcces  : DateTime.parse(map['dernier_acces']),

      observation   : map['observation'],
      motifAnnul    : map['motif_annul'],
      modifParCode      : map['modif_par_code'],
      annulParCode      : map['annul_par_code'],
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,

    );
  }


  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'code'          : code,
      'role'          : role,
      'etat'          : etat ? 1 : 0,
      'credit'        : credit,
      'username'      : username,
      'password'      : password,
      'role_code'     : role_code,
      'date_cree'     : dateCree.toIso8601String(),
      'telephone'     : telephone,
      'cree_par_code' : creeParCode,
      'dernier_acces' : dernierAcces.toIso8601String(),

      'observation'   : observation,
      'motif_annul'   : motifAnnul,
      'date_modif'    : dateModif?.toIso8601String(),
      'date_annul'    : dateAnnul?.toIso8601String(),
      'modif_par_code'     : modifParCode,
      'annul_par_code'     : annulParCode,
    }
    ;
  }  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
