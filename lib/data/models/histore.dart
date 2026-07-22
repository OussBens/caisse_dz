class Historique {
  int     id;
  String  oper;/////imsertion modif.....
  String  code;
  String? desc;/////type act
  String type;///////NOM TABLE
  String? observation;
  // Champs d’audit
  DateTime dateCree;
  String creeParCode;
  // -----------------------------------------------------------
  // Constructeur
  // -----------------------------------------------------------
  Historique({
    required this.id,
    required this.code,
    required this.type,
    required this.desc,
    required this.oper,
    required this.dateCree,
    required this.creeParCode,
    this.observation,
  });

  // -----------------------------------------------------------
  // map -> Objet
  // -----------------------------------------------------------
  factory Historique.fromMap(Map<String, dynamic> map) {
    return Historique(
      id            : map['id'],
      code          : map['code'],
      type          : map['type'],
      dateCree      : DateTime.parse(map['date_cree']),
      creeParCode   : map['cree_par_code'],
      oper          : map['operation'],
      desc          : map['description'],

      observation   : map['observation'],
    );
  }

  // -----------------------------------------------------------
  // Objet -> map
  // -----------------------------------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'            : id,
      'code'          : code,
      'type'          : type,
      'date_cree'     : dateCree.toIso8601String(),
      'operation'     : oper,
      'description'   : desc,
      'cree_par_code' : creeParCode,

      'observation'   : observation,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
