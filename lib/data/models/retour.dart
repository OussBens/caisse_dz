class Retour {
  int id;
  String code;
  String codeProduit;
  double quantite;
  DateTime date;
  // 🆕 Ajouts
  double? prixAchat;
  double? prixVente;

  String type; // client / fournisseur
  String? client_code;
  String? fournisseur_code;
  bool    etat;
  String? observation;

  // Audit
  DateTime  dateCree;
  String    creeParCode;

  DateTime? dateModif;
  String? modifParCode;
  DateTime? dateAnnul;
  String? annulParCode;
  String? motifAnnul;

  Retour({
    required this.codeProduit,
    required this.creeParCode,
    required this.quantite,
    required this.dateCree,
    required this.code,
    required this.date,
    required this.type,
    required this.etat,
    required this.id,

    this.client_code,
    this.fournisseur_code,
    this.observation,
    this.motifAnnul,
    this.prixVente,
    this.dateAnnul,
    this.dateModif,
    this.prixAchat,
    this.modifParCode,
    this.annulParCode,
  });

  factory Retour.fromMap(Map<String, dynamic> map)
  {
    return Retour(

      id                : map['id'],
      code              : map['code'],
      codeProduit       : map['code_produit'],
      quantite          : map['quantite'],
      prixAchat         : map['prix_achat'],
      prixVente         : map['prix_vente'],
      type              : map['type'],
      fournisseur_code  : map['fournisseur_code'],
      etat              : map['etat'] == 1,
      observation       : map['observation'],
      dateCree          : DateTime.parse(map['date_cree']),
      date              : DateTime.parse(map['date']),
      creeParCode       : map['cree_par_code'],
      client_code       : map['client_code'],

      modifParCode          : map['modif_par_code'],
      annulParCode          : map['annul_par_code'],
      motifAnnul        : map['motif_annul'],
      dateAnnul         : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      dateModif         : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }

  Map<String, dynamic> toMap()
  {
    return{
      'id'                : id,
      'code'              : code,
      'code_produit'      : codeProduit,
      'quantite'          : quantite,
      'prix_achat'        : prixAchat,
      'prix_vente'        : prixVente,
      'type'              : type,
      'client_code'       : client_code,
      'fournisseur_code'  : fournisseur_code,
      'etat'              : etat ? 1 : 0,
      'observation'       : observation,
      'date_cree'         : dateCree.toIso8601String(),
      'date'              : date.toIso8601String(),
      'cree_par_code'     :creeParCode,

      'date_modif'        : dateModif?.toIso8601String(),
      'modif_par_code'         : modifParCode,
      'date_annul'        : dateAnnul?.toIso8601String(),
      'annul_par_code'         : annulParCode,
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
