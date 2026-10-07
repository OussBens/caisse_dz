class RoleDetail {
  int     id;
  String  Rolecode;

  bool    dash;
  bool    caisse;
  bool    produit;
  bool    pannier;
  bool    client;
  bool    fournisseur;
  bool    entree;
  bool    sortie;
  bool    retour;
  bool    stock;
  bool    besoin;
  bool    utilisateur;
  bool    gestionCaisse;
  bool    zakat;
  bool    parametre;
  bool    historique;

  // Permissions spéciales : transversales (pas liées à un module de la
  // sidebar mais à une action sensible à l'intérieur d'un module déjà
  // accessible). Admin les a toutes implicitement, indépendamment de ces
  // champs (voir les usages de SpecialPermissions).
  bool    voirPrixAchat;
  bool    voirMarge;
  bool    modifierPrixVente;
  bool    annulerOperations;
  bool    changerCaisseMagasin;
  bool    gererTransfertsCaisse;
  bool    voirStockTousMagasins;

  // Audit
  DateTime  dateCree;
  String    creeParCode;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  RoleDetail({
    required this.id,
    required this.pannier,
    required this.fournisseur,
    required this.entree,
    required this.sortie,
    required this.produit,
    required this.client,
    required this.caisse,
    required this.retour,
    required this.creeParCode,
    required this.utilisateur,
    required this.historique,
    required this.zakat,
    required this.dateCree,
    required this.besoin,
    required this.dash,
    required this.gestionCaisse,
    required this.parametre,
    required this.Rolecode,
    required this.stock,

    this.voirPrixAchat = false,
    this.voirMarge = false,
    this.modifierPrixVente = false,
    this.annulerOperations = false,
    this.changerCaisseMagasin = false,
    this.gererTransfertsCaisse = false,
    this.voirStockTousMagasins = false,

    this.motifAnnul,
    this.dateAnnul,
    this.dateModif,
    this.modifParCode,
    this.annulParCode,
  });

  factory RoleDetail.fromMap(Map<String, dynamic> map)
  {
    return RoleDetail(

      id        : map['id'],
      Rolecode  : map['rolecode'],


      dash          : map['dash']           == 1,
      stock         : map['stock']          == 1,
      zakat         : map['zakat']          == 1,
      besoin        : map['besion']         == 1,
      client        : map['client']         == 1,
      entree        : map['entree']         == 1,
      sortie        : map['sortie']         == 1,
      caisse        : map['caisse']         == 1,
      retour        : map['retour']         == 1,
      pannier       : map['pannier']        == 1,
      produit       : map['produit']        == 1,
      parametre     : map['parametre']      == 1,
      historique    : map['historique']     == 1,
      fournisseur   : map['fournisseur']    == 1,
      utilisateur   : map['utilisateur']    == 1,
      gestionCaisse : map['gestionCaisse']  == 1,

      voirPrixAchat         : map['voirPrixAchat']         == 1,
      voirMarge             : map['voirMarge']             == 1,
      modifierPrixVente     : map['modifierPrixVente']     == 1,
      annulerOperations     : map['annulerOperations']     == 1,
      changerCaisseMagasin  : map['changerCaisseMagasin']  == 1,
      gererTransfertsCaisse : map['gererTransfertsCaisse'] == 1,
      voirStockTousMagasins : map['voirStockTousMagasins'] == 1,

      dateCree    : DateTime.parse(map['date_cree']),
      creeParCode : map['cree_par_code'],

      modifParCode    : map['modif_par_code'],
      annulParCode    : map['annul_par_code'],
      motifAnnul  : map['motif_annul'],
      dateAnnul   : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      dateModif   : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }

  Map<String, dynamic> toMap()
  {
    return{
      'id'                : id,
      'rolecode'          : Rolecode,

      'dash'          : dash          ? 1 : 0,
      'stock'         : stock         ? 1 : 0,
      'zakat'         : zakat         ? 1 : 0,
      'besion'        : besoin        ? 1 : 0,
      'client'        : client        ? 1 : 0,
      'entree'        : entree        ? 1 : 0,
      'sortie'        : sortie        ? 1 : 0,
      'caisse'        : caisse        ? 1 : 0,
      'retour'        : retour        ? 1 : 0,
      'pannier'       : pannier       ? 1 : 0,
      'produit'       : produit       ? 1 : 0,
      'parametre'     : parametre     ? 1 : 0,
      'historique'    : historique    ? 1 : 0,
      'fournisseur'   : fournisseur   ? 1 : 0,
      'utilisateur'   : utilisateur   ? 1 : 0,
      'gestionCaisse' : gestionCaisse ? 1 : 0,

      'voirPrixAchat'         : voirPrixAchat         ? 1 : 0,
      'voirMarge'             : voirMarge             ? 1 : 0,
      'modifierPrixVente'     : modifierPrixVente     ? 1 : 0,
      'annulerOperations'     : annulerOperations     ? 1 : 0,
      'changerCaisseMagasin'  : changerCaisseMagasin  ? 1 : 0,
      'gererTransfertsCaisse' : gererTransfertsCaisse ? 1 : 0,
      'voirStockTousMagasins' : voirStockTousMagasins ? 1 : 0,

      'date_cree'         : dateCree.toIso8601String(),
      'cree_par_code'     : creeParCode,

      'modif_par_code'         : modifParCode,
      'annul_par_code'         : annulParCode,
      'date_modif'        : dateModif?.toIso8601String(),
      'date_annul'        : dateAnnul?.toIso8601String(),
      'motif_annul'       : motifAnnul,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
