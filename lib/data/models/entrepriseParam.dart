class EntrepriseParam {
  int id;
  String nomBoutique;
  String? logoPath;
  String? adresse;
  String? telephone;
  String? email;
  String? rc;
  String? nif;
  String? nis;
  String? article;
  String? messageTicket;

  DateTime? dateModif;
  String? modifParCode;

  EntrepriseParam({
    required this.id,
    required this.nomBoutique,
    this.logoPath,
    this.adresse,
    this.telephone,
    this.email,
    this.rc,
    this.nif,
    this.nis,
    this.article,
    this.messageTicket,
    this.dateModif,
    this.modifParCode,
  });

  factory EntrepriseParam.fromMap(Map<String, dynamic> map) {
    return EntrepriseParam(
      id: map['id'] as int,
      nomBoutique: map['nom_boutique'] as String? ?? '',
      logoPath: map['logo_path'] as String?,
      adresse: map['adresse'] as String?,
      telephone: map['telephone'] as String?,
      email: map['email'] as String?,
      rc: map['rc'] as String?,
      nif: map['nif'] as String?,
      nis: map['nis'] as String?,
      article: map['article'] as String?,
      messageTicket: map['message_ticket'] as String?,
      dateModif: map['date_modif'] != null
          ? DateTime.parse(map['date_modif'] as String)
          : null,
      modifParCode: map['modif_par_code'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nom_boutique': nomBoutique,
    'logo_path': logoPath,
    'adresse': adresse,
    'telephone': telephone,
    'email': email,
    'rc': rc,
    'nif': nif,
    'nis': nis,
    'article': article,
    'message_ticket': messageTicket,
    'date_modif': dateModif?.toIso8601String(),
    'modif_par_code': modifParCode,
  };
}
