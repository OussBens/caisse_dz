class CaisseParam {
  int       id;

  bool      caisseParDefaut;        // actif, inactif
  bool      magasinParDefaut;

  String    utilisteur;
  String    selectedColis;
  String    selectedCaisse;
  String    selectedMagasin;

  String    caisseCode;
  String    magasinCode;

  String    creeParCode;
  DateTime  dateCree;

  String?   modifParCode;
  DateTime? dateModif;

  // -----------------------------------------------------------
  // Constructeur
  // -----------------------------------------------------------
  CaisseParam({
    required  this.id,
    required  this.utilisteur,
    required  this.magasinParDefaut,
    required  this.selectedCaisse,
    required  this.selectedMagasin,
    required  this.selectedColis,
    required  this.caisseParDefaut,
    required  this.dateCree,
    required  this.creeParCode,
    required  this.magasinCode,
    required  this.caisseCode,

    this.dateModif,
    this.modifParCode,
  });

  // -----------------------------------------------------------
  // map -> Objet
  // -----------------------------------------------------------
  factory CaisseParam.fromMap(Map<String, dynamic> map) {
    return CaisseParam(
      id                : map['id'],
      utilisteur        : map['user'],
      selectedColis     : map['colis'],
      selectedCaisse    : map['caisse'],
      selectedMagasin   : map['magasin'],
      magasinParDefaut  : map['magasinPD']  == 1,
      caisseParDefaut   : map['caissePD']   == 1,
      caisseCode        : map['caisseCode'],
      magasinCode       : map['magasinCode'],

      creeParCode       : map['cree_par_code'],
      dateCree          : DateTime.parse(map['date_cree']),

      modifParCode          : map['modif_par_code'],
      dateModif         : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'] as String)
          : null,
    );
  }
  // -----------------------------------------------------------
  // Objet -> map
  // -----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'user'          : utilisteur,
      'caissePD'      : caisseParDefaut ? 1 : 0,
      'magasinPD'     : magasinParDefaut  ? 1 : 0,
      'magasin'       : selectedMagasin,
      'magasinCode'   : magasinCode,
      'caisse'        : selectedCaisse,
      'caisseCode'    : caisseCode,
      'colis'         : selectedColis,
      'date_cree'     : dateCree.toIso8601String(),
      'cree_par_code' : creeParCode,

      'modif_par_code'     : modifParCode,
      'date_modif'    : dateModif?.toIso8601String(),
    };
  }
}
