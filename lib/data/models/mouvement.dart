class Mouvement {

  int       id;

  bool      etat;

  String    code;
  String    codeOperation;
  String    nomProduit;
  String    codeProduit;
  String    type; // SmartScan

  double    quantite;
  double    prixAchat;
  double    prixVente;

  String?   fournisseur;
  String?   client;

  DateTime  date;

  // Audit
  String    creeParCode;
  DateTime  dateCree;

  DateTime? dateModif;
  DateTime? dateAnnul;

  String?   modifParCode;
  String?   annulParCode;
  String?   motifAnnul;

  Mouvement({
    required this.id,
    required this.code,
    required this.date,
    required this.nomProduit,
    required this.codeProduit,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
    required this.type,
    required this.etat,
    required this.codeOperation,

    required this.dateCree,
    required this.creeParCode,

    this.fournisseur,
    this.client,

    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,

  });

  factory Mouvement.fromMap(Map<String, dynamic> map){
    return Mouvement(
        id            : map['id'],
        code          : map['code'],
        nomProduit    : map['nom_produit'],
        codeProduit   : map['code_produit'],
        quantite      : map['quantite'],
        prixAchat     : map['prix_achat'],
        prixVente     : map['prix_vente'],
        client        : map['client'],
        fournisseur   : map['fournisseur'],
        type          : map['type'],
        etat          : map['etat'] == 1 ,
        date          : DateTime.parse(map['date']),
        creeParCode   : map['cree_par_code'],
        dateCree      : DateTime.parse(map['date_cree']),
        codeOperation : map['code_operation'],

        dateModif     : map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
        modifParCode      : map['modif_par_code'],
        dateAnnul     : map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
        annulParCode      : map['annul_par_code'],
        motifAnnul    : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return{
      'id'              : id,
      'code'            : code,
      'nom_produit'     : nomProduit,
      'code_produit'    : codeProduit,
      'quantite'        : quantite,
      'prix_achat'      : prixAchat,
      'prix_vente'      : prixVente,
      'client'          : client,
      'code_operation'  : codeOperation,
      'fournisseur'     : fournisseur,
      'type'            : type,
      'etat'            : etat ? 1 : 0,
      'date'            : date.toIso8601String(),
      'date_cree'       : dateCree.toIso8601String(),
      'cree_par_code'   : creeParCode,
      'date_modif'      : dateModif?.toIso8601String(),
      'modif_par_code'       : modifParCode,
      'date_annul'      : dateAnnul?.toIso8601String(),
      'annul_par_code'       : annulParCode,
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
