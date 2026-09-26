class Sortie{
  int     id;
  bool    etat;
  double  quantite;
  // Nombre de pièces physiques sorties (Paramètres > Nombre et Quantité) —
  // voir Produit.nombre.
  double? nombre;
  double  prix;
  double  montant;
  String  produitCode;
  String  code;
  String  type;

  DateTime date;

  String? categorieCode;
  String? sousCategorieCode;
  // Magasin d'où le produit est sorti — voir DBCreate.dart oldVersion < 44.
  String? magasinCode;
  String? observation;
  // Audit
  String    creeParCode;
  DateTime  dateCree;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String?   modifParCode;
  String?   annulParCode;
  String?   motifAnnul;

  Sortie({
    required this.id,
    required this.code,
    required this.produitCode,
    required this.quantite,
    required this.prix,
    required this.montant,
    required this.type,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,

    required this.date,

    this.nombre,
    this.categorieCode,
    this.observation,
    this.sousCategorieCode,
    this.magasinCode,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  factory Sortie.fromMap(Map<String, dynamic> map) {
    return Sortie(
      id            : map['id'],
      etat          : map['etat'] == 1,
      type          : map['type'],
      prix          : map['prix'],
      code          : map['code'],
      produitCode   : map['produit_code'],
      montant       : map['montant'],
      quantite      : map['quantite'],
      nombre        : (map['nombre'] as num?)?.toDouble(),
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],
      date          : DateTime.parse(map['date']),

      sousCategorieCode : map['sous_categorie_code'],
      magasinCode   : map['magasin_code'],
      observation   : map['observation'],
      motifAnnul    : map['motif_annul'],
      categorieCode     : map['categorie_code'],
      modifParCode      : map['modif_par_code'],
      annulParCode      : map['annul_par_code'],
      dateAnnul     : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      dateModif     : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }
  Map<String, dynamic> toMap() {
    return{
      'id'            : id,
      'code'          : code,
      'type'          : type,
      'prix'          : prix,
      'etat'          : etat ? 1 : 0,
      'produit_code'  : produitCode,
      'montant'       : montant,
      'quantite'      : quantite,
      'nombre'        : nombre,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par_code' : creeParCode,
      'date'          : date.toIso8601String(),
      'sous_categorie_code' : sousCategorieCode,
      'magasin_code'  : magasinCode,
      'observation'   : observation,
      'date_modif'    : dateModif?.toIso8601String(),
      'categorie_code'     : categorieCode,
      'modif_par_code'     : modifParCode,
      'annul_par_code'     : annulParCode,
      'date_annul'    : dateAnnul?.toIso8601String(),
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
