class ParamZakat {
  int       id;
  double    Nissab;
  double    Taux;

  DateTime  dateCree;
  String    creeParCode;
  String    creePar;

  DateTime? dateModif;
  String?   modifPar;

  ParamZakat({
    required this.id,
    required this.Nissab,
    required this.Taux,
    required this.creeParCode,
    required this.dateCree,
    required this.creePar,

    this.dateModif,
    this.modifPar,
  });

  /// ================= FROM map =================
  factory ParamZakat.fromMap(Map<String, dynamic> map){
    return ParamZakat(
      id            : map['id'],
      Taux          : map['taux'] ?? 200,
      Nissab        : map['nissab'],
      creePar       : map['cree_par'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],

      modifPar      : map['modif_par'],
      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
    );
  }
  /// ================= TO map =================
  Map<String, dynamic> toMap() {
    return{
      'id'              : id,
      'taux'            : Taux,
      'nissab'          : Nissab,
      'cree_par'        : creePar,
      'date_cree'       : dateCree.toIso8601String(),
      'cree_par_code'   : creeParCode,

      'modif_par'       : modifPar,
      'date_modif'      : dateModif?.toIso8601String(),
    };
  }
}
