class Zakat {
  /// ================= Identification =================
  int       id;
  String    code;        // ex: ZKT-2025-0001
  int       annee;          // année comptable (2024, 2025...)

  /// ================= Données financières =================
  double    stock;       // valeur stock marchandises
  double    liquidites;  // cash + banque
  double    creances;    // argent à recevoir
  double    dettes;      // dettes à court terme
  double    dattes;      // ✅ Nouveau champ: valeur des dattes

  double    capitalTotal; // (stock + liquidités + créances - dettes + dattes)

  /// ================= Règles Zakat =================
  double    nissab;       // seuil nissab
  double    taux;         // 2.5 %
  double    montantZakat; // résultat calculé
  bool      obligatoire;   // capital >= nissab

  /// ================= Hawl & échéance =================
  DateTime  dateDebutHawl; // début du hawl
  DateTime  dateZakatDue;  // date où la zakat est due
  DateTime? datePaiement;  // date réelle de paiement

  /// ================= Statut =================
  String    statut; //   | PAYEE /no Payé

  /// ================= Informations =================
  String?   observation;

  /// ================= Audit =================
  DateTime  dateCree;
  String    creeParCode;
  bool      etat;

  DateTime? dateModif;
  DateTime? dateAnnul;
  String?   modifPar;
  String?   annulPar;
  String?   motifAnnul;

  Zakat({
    required this.id,
    required this.code,
    required this.annee,
    required this.stock,
    required this.liquidites,
    required this.creances,
    required this.dettes,
    required this.dattes, // ✅ Ajout du champ
    required this.capitalTotal,
    required this.nissab,
    required this.taux,
    required this.montantZakat,
    required this.obligatoire,
    required this.statut,
    required this.etat,
    required this.dateDebutHawl,
    required this.dateZakatDue,
    required this.creeParCode,
    required this.dateCree,

    this.datePaiement,
    this.observation,
    this.dateModif,
    this.modifPar,
    this.dateAnnul,
    this.annulPar,
    this.motifAnnul,
  });

  /// ================= FROM map =================
  factory Zakat.fromMap(Map<String, dynamic> map){
    return Zakat(
      id            : map['id'],
      taux          : map['taux'],
      etat          : map['etat'] == 1,
      code          : map['code'],
      annee         : map['annee'],
      stock         : map['stock'],
      dettes        : map['dettes'],
      dattes        : map['dattes'] ?? 0.0, // ✅ Ajout avec valeur par défaut
      statut        : map['status'],
      nissab        : map['nissab'],
      dateCree      : DateTime.parse(map['date_cree']),
      creances      : map['creances'],
      liquidites    : map['liquidites'],
      obligatoire   : map['obligatoire'] == 1,
      creeParCode   : map['cree_par_code'],
      montantZakat  : map['montant_zakat'],
      capitalTotal  : map['capital_total'],
      dateZakatDue  : DateTime.parse(map['date_zakat_due']),
      dateDebutHawl : DateTime.parse(map['date_debut_hawl']),

      annulPar      : map['annul_par'],
      modifPar      : map['modif_par'],
      motifAnnul    : map['motif_annul'],
      observation   : map['observation'],
      datePaiement  : map['date_paiement'] != null
          ? DateTime.parse(map['date_paiement'])
          : null,
      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      dateAnnul: map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
    );
  }

  /// ================= TO map =================
  Map<String, dynamic> toMap() {
    return {
      'id'              : id,
      'taux'            : taux,
      'etat'            : etat ? 1 : 0,
      'code'            : code,
      'annee'           : annee,
      'stock'           : stock,
      'dettes'          : dettes,
      'dattes'          : dattes, // ✅ Ajout du champ
      'nissab'          : nissab,
      'status'          : statut,
      'creances'        : creances,
      'date_cree'       : dateCree.toIso8601String(),
      'liquidites'      : liquidites,
      'obligatoire'     : obligatoire ? 1 : 0,
      'montant_zakat'   : montantZakat,
      'capital_total'   : capitalTotal,
      'cree_par_code'   : creeParCode,
      'date_zakat_due'  : dateZakatDue.toIso8601String(),
      'date_debut_hawl' : dateDebutHawl.toIso8601String(),

      'date_paiement'   : datePaiement?.toIso8601String(),
      'observation'     : observation,
      'annul_par'       : annulPar,
      'modif_par'       : modifPar,
      'date_modif'      : dateModif?.toIso8601String(),
      'date_annul'      : dateAnnul?.toIso8601String(),
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