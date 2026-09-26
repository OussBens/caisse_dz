/// Une session de caisse : la période entre une ouverture (avec solde de
/// départ) et une clôture (avec solde théorique calculé, solde réel compté
/// et écart). Toute vente/achat/versement/retour doit être rattaché à une
/// session ouverte (`statut == 'ouverte'`) pour la caisse concernée — voir
/// CaisseSessionServices.getSessionOuverte, utilisé comme verrou avant
/// chaque opération monétaire.
class CaisseSession {
  int      id;
  String   code;
  String   caisseCode;
  String   statut; // 'ouverte' | 'cloturee'
  double   soldeOuverture;
  DateTime dateOuverture;

  double?   soldeTheorique;
  double?   soldeReel;
  double?   ecart;
  DateTime? dateCloture;

  String? observation;
  bool     etat;

  // Champs d'audit
  DateTime dateCree;
  String   creeParCode;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  static const String statutOuverte = 'ouverte';
  static const String statutCloturee = 'cloturee';

  bool get estOuverte => statut == statutOuverte;

  CaisseSession({
    required this.id,
    required this.code,
    required this.caisseCode,
    required this.statut,
    required this.soldeOuverture,
    required this.dateOuverture,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,
    this.soldeTheorique,
    this.soldeReel,
    this.ecart,
    this.dateCloture,
    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  factory CaisseSession.fromMap(Map<String, dynamic> map) {
    return CaisseSession(
      id             : map['id'],
      code           : map['code'],
      caisseCode     : map['caisse_code'],
      statut         : map['statut'],
      soldeOuverture : (map['solde_ouverture'] as num).toDouble(),
      dateOuverture  : DateTime.parse(map['date_ouverture']),
      etat           : map['etat'] == 1,
      dateCree       : DateTime.parse(map['date_cree']),
      creeParCode    : map['cree_par_code'],
      soldeTheorique : map['solde_theorique'] != null ? (map['solde_theorique'] as num).toDouble() : null,
      soldeReel      : map['solde_reel'] != null ? (map['solde_reel'] as num).toDouble() : null,
      ecart          : map['ecart'] != null ? (map['ecart'] as num).toDouble() : null,
      dateCloture    : map['date_cloture'] != null ? DateTime.parse(map['date_cloture']) : null,
      observation    : map['observation'],
      modifParCode   : map['modif_par_code'],
      dateModif      : map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
      annulParCode   : map['annul_par_code'],
      dateAnnul      : map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
      motifAnnul     : map['motif_annul'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'               : id,
      'code'             : code,
      'caisse_code'      : caisseCode,
      'statut'           : statut,
      'solde_ouverture'  : soldeOuverture,
      'date_ouverture'   : dateOuverture.toIso8601String(),
      'etat'             : etat ? 1 : 0,
      'date_cree'        : dateCree.toIso8601String(),
      'cree_par_code'    : creeParCode,
      'solde_theorique'  : soldeTheorique,
      'solde_reel'       : soldeReel,
      'ecart'            : ecart,
      'date_cloture'     : dateCloture?.toIso8601String(),
      'observation'      : observation,
      'modif_par_code'   : modifParCode,
      'date_modif'       : dateModif?.toIso8601String(),
      'annul_par_code'   : annulParCode,
      'date_annul'       : dateAnnul?.toIso8601String(),
      'motif_annul'      : motifAnnul,
    };
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
