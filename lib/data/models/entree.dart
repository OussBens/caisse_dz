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
  String creePar;
  String creeParCode;
  DateTime dateCree;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String? modifPar;
  String? annulPar;
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
    required this.creePar,
    required this.creeParCode,
    required this.dateCree,

    this.observation,
    this.dateModif,
    this.dateAnnul,
    this.modifPar,
    this.annulPar,
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

      creePar: map['cree_par'],
      creeParCode: map['cree_par_code'],
      dateCree: DateTime.parse(map['date_cree']),

      observation: map['observation'],

      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,

      modifPar: map['modif_par'],

      dateAnnul: map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,

      annulPar: map['annul_par'],
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

      'cree_par': creePar,
      'cree_par_code': creeParCode,
      'date_cree': dateCree.toIso8601String(),

      'observation': observation,

      'date_modif': dateModif?.toIso8601String(),
      'modif_par': modifPar,

      'date_annul': dateAnnul?.toIso8601String(),
      'annul_par': annulPar,
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