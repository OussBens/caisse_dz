class Pannier {
  int id;
  DateTime date;
  String code;
  int? nombreArticle;
  int? quantiteProduit;
  double montant;      // total du panier
  double montantAchat;      // total du panier
  double marge;      // total du panier
  double verse;        // montant payé
  double reste;        // reste à payer
  String client;
  String? client_code;
  String? modePaiement; // espèce, carte, chèque, etc.
  String caissier;     // personne qui a enregistré le panier
  String caisse_code;
  String caissier_code;
  String caisse;

  bool    etat;         // actif, annulé, en cours, payé
  String  typepannier;  // ticket ou BL ou SC
  String? observation;  // optionnel, commentaire ou note

  // Audit
  DateTime  dateCree;

  DateTime? dateModif;
  String?   modifPar;
  DateTime? dateAnnul;
  String?   annulPar;
  String?   motifAnnul;

  Pannier({

    required this.id,
    required this.code,
    required this.montant,
    required this.montantAchat,
    required this.marge,
    required this.verse,
    required this.reste,
    required this.client,
    required this.typepannier,
    required this.date,
    required this.dateCree,
    required this.etat,
    required this.caissier,
    required this.caissier_code,
    required this.caisse_code,
    required this.caisse,

    this.client_code,
    this.modePaiement,
    this.observation,
    this.nombreArticle,
    this.quantiteProduit,
    this.dateModif,
    this.modifPar,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,

  });

  factory Pannier.fromMap(Map<String, dynamic> map) {
    return Pannier(
      id              : map['id'],
      code            : map['code'],
      nombreArticle   : map['nombre_article'],
      quantiteProduit : map['quantite_produit'],
      montant         : map['montant'],
      montantAchat    : map['montant_achat']?? 0.0,
      marge           : map['marge']?? 0.0,
      verse           : map['verse']?? 0.0,
      reste           : map['reste']?? 0.0,
      client          : map['client'],
      client_code     : map['client_code'],
      modePaiement    : map['mode_paiement'],
      caissier        : map['caisser'],
      caissier_code   : map['caisser_code'],
      caisse          : map['caisse'],
      caisse_code     : map['caisse_code'],
      etat            : map['etat'] == 1,
      observation     : map['observation'],
      typepannier     : map['type_pannier'],
      dateCree        : DateTime.parse(map['date_cree']),
      date            : DateTime.parse(map['date']),
      dateModif       : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifPar        : map['modif_par'],
      dateAnnul       : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulPar        : map['annul_par'],
      motifAnnul      : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap()
  {
    return{
      'id'                : id,
      'date'              : date.toIso8601String(),
      'code'              : code,
      'nombre_article'    : nombreArticle,
      'quantite_produit'  : quantiteProduit,
      'montant'           : montant,
      'montant_achat'     : montantAchat,
      'marge'             : marge,
      'verse'             : verse,
      'reste'             : reste,
      'client'            : client,
      'client_code'       : client_code,
      'mode_paiement'     : modePaiement,
      'caisser'           : caissier,
      'caisser_code'      : caissier_code,
      'caisse'            : caisse,
      'caisse_code'       : caisse_code,
      'etat'              : etat ? 1 : 0,
      'observation'       : observation,
      'type_pannier'      : typepannier,
      'date_cree'         : dateCree.toIso8601String(),
      'date_modif'        : dateModif?.toIso8601String(),
      'modif_par'         : modifPar,
      'date_annul'        : dateAnnul?.toIso8601String(),
      'annul_par'         : annulPar,
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
