class Entree {
  int id;
  String code;
  DateTime date; //ok

  String produitcode;
  String produit; //ok

  double prix; //ok
  double quantite; //ok
  double montant;

  String fournisseur; //ok
  String fournisseurCode;

  bool etat; //ok
  String? observation;

  // Audit
  String creeParCode;
  DateTime dateCree;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String? modifParCode;
  String? annulParCode;
  String? motifAnnul;

  Entree({
    required this.id,
    required this.code,
    required this.date,
    required this.produitcode,
    required this.produit,
    required this.prix,
    required this.quantite,
    required this.montant,
    required this.fournisseur,
    required this.fournisseurCode,
    required this.etat,
    required this.creeParCode,
    required this.dateCree,

    this.observation,
    this.dateModif,
    this.dateAnnul,
    this.modifParCode,
    this.annulParCode,
    this.motifAnnul,
  });

  factory Entree.fromMap(Map<String, dynamic> map) {
    return Entree(
      id: map['id'],
      code: map['code'],
      date: DateTime.parse(map['date']),

      produitcode: map['produit_code'],
      produit: map['produit'],

      prix: (map['prix'] as num).toDouble(),
      quantite: (map['quantite'] as num).toDouble(),
      montant: (map['montant'] as num).toDouble(),

      fournisseur: map['fournisseur'],
      fournisseurCode: map['fournisseur_code'],

      etat: map['etat'] == 1,

      creeParCode: map['cree_par_code'],
      dateCree: DateTime.parse(map['date_cree']),

      observation: map['observation'],

      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,

      modifParCode: map['modif_par_code'],

      dateAnnul: map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,

      annulParCode: map['annul_par_code'],
      motifAnnul: map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'date': date.toIso8601String(),

      'produit_code': produitcode,
      'produit': produit,

      'prix': prix,
      'quantite': quantite,
      'montant': montant,

      'fournisseur': fournisseur,
      'fournisseur_code': fournisseurCode,

      'etat': etat ? 1 : 0,

      'cree_par_code': creeParCode,
      'date_cree': dateCree.toIso8601String(),

      'observation': observation,

      'date_modif': dateModif?.toIso8601String(),
      'modif_par_code': modifParCode,

      'date_annul': dateAnnul?.toIso8601String(),
      'annul_par_code': annulParCode,
      'motif_annul': motifAnnul,
    };
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}