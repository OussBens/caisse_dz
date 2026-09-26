/// Une ligne du grand-livre de caisse : chaque encaissement/décaissement
/// réel (vente, achat, versement, retour, ouverture/clôture de session,
/// mouvement manuel) y est journalisé. `codeOperation` référence, selon
/// `type`, le code d'un Pannier/SmartScan/Retour/Verssement (pas de
/// contrainte FK en base : polymorphe, comme Mouvement.codeOperation).
/// `etat=false` marque une ligne annulée (soft-cancel) — jamais de
/// suppression physique, voir CaisseSessionServices.annulerMouvement.
class CaisseMouvement {
  int      id;
  String   code;
  String   sessionCode;
  String   caisseCode;
  String   type; // ListsConst.typeMouvementCaisse
  String   sens; // 'Entrée' | 'Sortie'
  double   montant;

  String? modePaiement;
  String? codeOperation;
  String? clientCode;
  String? fournisseurCode;
  String? motif;
  String? reference;

  DateTime date;
  bool     etat;

  // Champs d'audit
  DateTime dateCree;
  String   creeParCode;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  CaisseMouvement({
    required this.id,
    required this.code,
    required this.sessionCode,
    required this.caisseCode,
    required this.type,
    required this.sens,
    required this.montant,
    required this.date,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,
    this.modePaiement,
    this.codeOperation,
    this.clientCode,
    this.fournisseurCode,
    this.motif,
    this.reference,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  factory CaisseMouvement.fromMap(Map<String, dynamic> map) {
    return CaisseMouvement(
      id              : map['id'],
      code            : map['code'],
      sessionCode     : map['session_code'],
      caisseCode      : map['caisse_code'],
      type            : map['type'],
      sens            : map['sens'],
      montant         : (map['montant'] as num).toDouble(),
      date            : DateTime.parse(map['date']),
      etat            : map['etat'] == 1,
      dateCree        : DateTime.parse(map['date_cree']),
      creeParCode     : map['cree_par_code'],
      modePaiement    : map['mode_paiement'],
      codeOperation   : map['code_operation'],
      clientCode      : map['client_code'],
      fournisseurCode : map['fournisseur_code'],
      motif           : map['motif'],
      reference       : map['reference'],
      modifParCode    : map['modif_par_code'],
      dateModif       : map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
      annulParCode    : map['annul_par_code'],
      dateAnnul       : map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
      motifAnnul      : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'                : id,
      'code'              : code,
      'session_code'      : sessionCode,
      'caisse_code'       : caisseCode,
      'type'              : type,
      'sens'              : sens,
      'montant'           : montant,
      'date'              : date.toIso8601String(),
      'etat'              : etat ? 1 : 0,
      'date_cree'         : dateCree.toIso8601String(),
      'cree_par_code'     : creeParCode,
      'mode_paiement'     : modePaiement,
      'code_operation'    : codeOperation,
      'client_code'       : clientCode,
      'fournisseur_code'  : fournisseurCode,
      'motif'             : motif,
      'reference'         : reference,
      'modif_par_code'    : modifParCode,
      'date_modif'        : dateModif?.toIso8601String(),
      'annul_par_code'    : annulParCode,
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
