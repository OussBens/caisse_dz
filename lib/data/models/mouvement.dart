class Mouvement {

  int       id;

  bool      etat;

  String    code;
  String    codeOperation;
  String    codeProduit;
  String    type; // SmartScan
  // Sous-type pour les mouvements de type "Sortie" (Don/Expiration/Autre) —
  // voir ListsConst.typeSortie. Non utilisé pour les autres types.
  String?   sousType;

  double    quantite;
  // Nombre de pièces physiques concernées par ce mouvement (Paramètres >
  // Nombre et Quantité) — voir Produit.nombre.
  double?   nombre;
  double    prixAchat;
  double    prixVente;

  String?   fournisseurCode;
  String?   clientCode;

  // Magasin où le mouvement a eu lieu (celui de la caisse active au moment
  // du mouvement) — absent (NULL) sur les mouvements créés avant l'ajout de
  // cette colonne, cf. DBCreate.dart oldVersion < 43.
  String?   magasinCode;

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
    required this.codeProduit,
    required this.quantite,
    required this.prixAchat,
    required this.prixVente,
    required this.type,
    required this.etat,
    required this.codeOperation,

    required this.dateCree,
    required this.creeParCode,

    this.nombre,
    this.sousType,
    this.fournisseurCode,
    this.clientCode,
    this.magasinCode,

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
        codeProduit   : map['code_produit'],
        quantite      : map['quantite'],
        nombre        : (map['nombre'] as num?)?.toDouble(),
        prixAchat     : map['prix_achat'],
        prixVente     : map['prix_vente'],
        clientCode        : map['client_code'],
        fournisseurCode   : map['fournisseur_code'],
        magasinCode   : map['magasin_code'],
        type          : map['type'],
        sousType      : map['sous_type'],
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
      'code_produit'    : codeProduit,
      'quantite'        : quantite,
      'nombre'          : nombre,
      'prix_achat'      : prixAchat,
      'prix_vente'      : prixVente,
      'client_code'     : clientCode,
      'code_operation'  : codeOperation,
      'fournisseur_code': fournisseurCode,
      'magasin_code'    : magasinCode,
      'type'            : type,
      'sous_type'       : sousType,
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
