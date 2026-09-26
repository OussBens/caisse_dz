class SmartScan {
  int id;
  String code;
  DateTime date;
  double montant;
  int nbrProduit;
  String fournisseurCode;
  bool etat;
  String? observation;
  String creeParCode;
  DateTime dateCree;
  DateTime? dateModif;
  DateTime? dateAnnul;
  String? modifParCode;
  String? annulParCode;
  String? motifAnnul;

  // Appareil mobile source (POST /api/sync/push/stock-movement), null pour
  // les SmartScan créés depuis le desktop.
  String? deviceIdMobile;

  // Photo jointe (bon de livraison/facture) envoyée depuis le mobile via
  // POST /api/smartscan/upload, chemin relatif comme BonReception.cheminPhoto.
  String? cheminPhoto;

  SmartScan({
    required this.id,
    required this.code,
    required this.date,
    required this.montant,
    required this.nbrProduit,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,
    required this.fournisseurCode,
    this.observation,
    this.motifAnnul,
    this.dateModif,
    this.dateAnnul,
    this.annulParCode,
    this.modifParCode,
    this.deviceIdMobile,
    this.cheminPhoto,
  });

  factory SmartScan.fromMap(Map<String, dynamic> map) {
    return SmartScan(
      id: map['id'],
      code: map['code'],
      date: DateTime.parse(map['date']),
      etat: map['etat'] == 1,
      montant: _toDouble(map['montant']),
      nbrProduit: _toInt(map['nbr_produit']),
      dateCree: DateTime.parse(map['date_cree']),
      creeParCode: map['cree_par_code'],
      observation: map['observation'],
      fournisseurCode: map['fournisseur_code'],
      dateModif: map['date_modif'] != null ? DateTime.parse(map['date_modif']) : null,
      modifParCode: map['modif_par_code'],
      dateAnnul: map['date_annul'] != null ? DateTime.parse(map['date_annul']) : null,
      annulParCode: map['annul_par_code'],
      motifAnnul: map['motif_annul'],
      deviceIdMobile: map['device_id_mobile'],
      cheminPhoto: map['chemin_photo'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'code': code,
      'etat': etat ? 1 : 0,
      'date': date.toIso8601String(),
      'montant': montant,
      'nbr_produit': nbrProduit,
      'date_cree': dateCree.toIso8601String(),
      'observation': observation,
      'cree_par_code': creeParCode,
      'fournisseur_code': fournisseurCode,
      'date_modif': dateModif?.toIso8601String(),
      'modif_par_code': modifParCode,
      'date_annul': dateAnnul?.toIso8601String(),
      'annul_par_code': annulParCode,
      'motif_annul': motifAnnul,
      'device_id_mobile': deviceIdMobile,
      'chemin_photo': cheminPhoto,
    };
  }

  // ✅ Helper methods for safe type conversion
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}