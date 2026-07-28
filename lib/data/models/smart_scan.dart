class SmartScan {
  int id;
  String code;
  DateTime date;
  double montant;
  double paye;
  double reste;
  double montantCalcul;
  int nbrProduit;
  int nbrProduitCalcul;
  double quantiteArticle;
  double quantiteArticleCalcul;
  bool ecart;
  String fournisseurCode;
  bool etat;
  String activity;
  String? observation;
  String creeParCode;
  DateTime dateCree;
  DateTime? dateModif;
  DateTime? dateAnnul;
  String? modifParCode;
  String? annulParCode;
  String? motifAnnul;

  SmartScan({
    required this.id,
    required this.code,
    required this.date,
    required this.montant,
    required this.paye,
    required this.reste,
    required this.quantiteArticle,
    required this.nbrProduit,
    required this.montantCalcul,
    required this.quantiteArticleCalcul,
    required this.nbrProduitCalcul,
    required this.etat,
    required this.dateCree,
    required this.activity,
    required this.ecart,
    required this.creeParCode,
    required this.fournisseurCode,
    this.observation,
    this.motifAnnul,
    this.dateModif,
    this.dateAnnul,
    this.annulParCode,
    this.modifParCode,
  });

  factory SmartScan.fromMap(Map<String, dynamic> map) {
    return SmartScan(
      id: map['id'],
      code: map['code'],
      date: DateTime.parse(map['date']),
      etat: map['etat'] == 1,
      ecart: map['ecart'] == 1,
      montant: _toDouble(map['montant']),
      paye: _toDouble(map['paye']),
      reste: _toDouble(map['reste']),
      nbrProduit: _toInt(map['nbr_produit']),
      quantiteArticle: _toDouble(map['quantite_article']),
      montantCalcul: _toDouble(map['montant_calcul']),
      nbrProduitCalcul: _toInt(map['nbr_produit_calcul']),
      quantiteArticleCalcul: _toDouble(map['quantite_article_calcul']),
      dateCree: DateTime.parse(map['date_cree']),
      activity: map['activity'],
      creeParCode: map['cree_par_code'],
      observation: map['observation'],
      fournisseurCode: map['fournisseur_code'],
      dateModif: map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
      modifParCode: map['modif_par_code'],
      dateAnnul: map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
      annulParCode: map['annul_par_code'],
      motifAnnul: map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'etat': etat ? 1 : 0,
      'date': date.toIso8601String(),
      'ecart': ecart ? 1 : 0,  // ✅ Fixed: using ecart, not etat
      'montant': montant,
      'paye': paye,
      'reste': reste,
      'nbr_produit': nbrProduit,
      'quantite_article': quantiteArticle,
      'montant_calcul': montantCalcul,
      'nbr_produit_calcul': nbrProduitCalcul,
      'quantite_article_calcul': quantiteArticleCalcul,
      'activity': activity,
      'date_cree': dateCree.toIso8601String(),
      'observation': observation,
      'cree_par_code': creeParCode,
      'fournisseur_code': fournisseurCode,
      'date_modif': dateModif?.toIso8601String(),
      'modif_par_code': modifParCode,
      'date_annul': dateAnnul?.toIso8601String(),
      'annul_par_code': annulParCode,
      'motif_annul': motifAnnul,
    };
  }

  // ✅ Helper methods for safe type conversion
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}