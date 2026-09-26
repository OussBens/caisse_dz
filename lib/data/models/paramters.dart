class Paramters {
  int id;

  String    creeParCode;
  String?   modifParCode;
  String    typeMarge;
  double    TauxMargePerncetage;
  double    TauxMargeMontant;
  double    Minimum;
  double    Maximum;

  // Nombre de décimales à afficher/saisir sur les champs quantité dans
  // toute l'app (Paramètres > Système) — voir QuantiteFormat.
  int       decimalesQuantite;

  // Programme de bonus/fidélité (Paramètres > Système) : activeBonus
  // active/désactive tout le système (accrual à la vente, mode de paiement
  // "Points", affichage sur le ticket) ; bonusTaux est le montant en DA de
  // vente nécessaire pour créditer 1 point au client (ex: 100 = 1 point
  // tous les 100 DA, points = montant / bonusTaux).
  bool      activeBonus;
  double    bonusTaux;

  // Second stock parallèle "Nombre" (pièces) en plus de "Quantité" (poids/
  // mesure) — voir Produit.nombre. Actif ou non pour toute l'application.
  bool      activeNombreQuantite;

  DateTime Datecree;
  DateTime? Datemodif;

  Paramters(

      {
        required this.id,
        required this.TauxMargePerncetage,
        required this.TauxMargeMontant,
        required this.Maximum,
        required this.typeMarge,
        required this.Minimum,
        required this.Datecree,
        required this.creeParCode,
        this.decimalesQuantite = 0,
        this.activeBonus = false,
        this.bonusTaux = 0,
        this.activeNombreQuantite = false,
        this.Datemodif,
        this.modifParCode,
      }

  );

  factory Paramters.fromMap(Map<String, dynamic> map){
    return Paramters(
        id                  : map['id'] ?? 1 ,
        TauxMargeMontant    : map['taux_marge_montant'],
        TauxMargePerncetage : map['taux_marge_percentage'],
        typeMarge           : map['type_marge'],
        Maximum             : map['maximum'],
        Minimum             : map['minimum'],
        decimalesQuantite   : map['decimales_quantite'] ?? 0,
        activeBonus         : map['active_bonus'] == 1,
        bonusTaux           : (map['bonus_taux'] as num?)?.toDouble() ?? 0,
        activeNombreQuantite : map['active_nombre_quantite'] == 1,
        Datecree            : DateTime.parse(map['date_cree']),
        creeParCode         : map['cree_par_code'],
        Datemodif           : map['date_modif'] != null ? DateTime.parse(map['date_modif']) : DateTime.parse('0000-00-00'),
        modifParCode            : map['modif_par_code']
    );
  }

  Map<String, dynamic> toMap(){
    return{
      'id'                     : id,
      'taux_marge_percentage'  : TauxMargePerncetage,
      'taux_marge_montant'     : TauxMargeMontant,
      'type_marge'             : typeMarge,
      'maximum'                : Maximum,
      'minimum'                : Minimum,
      'decimales_quantite'     : decimalesQuantite,
      'active_bonus'           : activeBonus ? 1 : 0,
      'bonus_taux'             : bonusTaux,
      'active_nombre_quantite' : activeNombreQuantite ? 1 : 0,
      'date_cree'              : Datecree.toIso8601String(),
      'date_modif'             : Datemodif?.toIso8601String(),
      'cree_par_code'          : creeParCode,
      'modif_par_code'              : modifParCode,
    };
  }

}