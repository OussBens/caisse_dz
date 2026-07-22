class Paramters {
  int id;

  String    creeParCode;
  String?   modifParCode;
  String    typeMarge;
  double    TauxMargePerncetage;
  double    TauxMargeMontant;
  double    Minimum;
  double    Maximum;

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
      'date_cree'              : Datecree.toIso8601String(),
      'date_modif'             : Datemodif?.toIso8601String(),
      'cree_par_code'          : creeParCode,
      'modif_par_code'              : modifParCode,
    };
  }

}