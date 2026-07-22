class UserParam {
  int id;
  String nom;           // Changed from 'name' to 'nom' to match DB
  String magasin;
  String magasinid;
  String language;
  String currency;

  // Audit
  DateTime creeLe;      // Changed from 'dateCree' to 'creeLe' to match DB
  String creeParCode;

  DateTime? modifLe;    // Changed from 'dateModif' to 'modifLe'
  String? modifParCode;

  UserParam({
    required this.id,
    required this.nom,
    required this.magasin,
    required this.magasinid,
    required this.language,
    required this.currency,
    required this.creeParCode,
    required this.creeLe,
    this.modifLe,
    this.modifParCode,
  });

  factory UserParam.fromMap(Map<String, dynamic> map) {
    return UserParam(
      id: map['id'] as int,
      nom: map['nom'] as String,
      magasin: map['magasin'] as String,
      magasinid: map['magasinid'] as String,
      language: map['language'] as String,
      currency: map['currency'] as String,
      creeParCode: map['cree_par_code'] as String,
      creeLe: DateTime.parse(map['cree_le'] as String),
      modifLe: map['modif_le'] != null
          ? DateTime.parse(map['modif_le'] as String)
          : null,
      modifParCode: map['modif_par_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom': nom,
    'magasin': magasin,
    'magasinid': magasinid,
    'language': language,
    'currency': currency,
    'cree_par_code': creeParCode,
    'cree_le': creeLe.toIso8601String(),
    'modif_le': modifLe?.toIso8601String(),
    'modif_par_code': modifParCode,
  };
}