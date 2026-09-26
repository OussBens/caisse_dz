class BonReception {
  int id;
  String? fournisseur;
  String? fournisseurCode;
  String? numBon;
  String? commentaire;
  String cheminPhoto;
  DateTime dateReception;
  String statut; // 'recu' | 'traite' | 'erreur'
  String? deviceId;
  DateTime? dateTraitement;
  String? traiteParCode;
  String? smartScanCode;

  BonReception({
    required this.id,
    this.fournisseur,
    this.fournisseurCode,
    this.numBon,
    this.commentaire,
    required this.cheminPhoto,
    required this.dateReception,
    this.statut = 'recu',
    this.deviceId,
    this.dateTraitement,
    this.traiteParCode,
    this.smartScanCode,
  });

  factory BonReception.fromMap(Map<String, dynamic> map) {
    return BonReception(
      id: map['id'],
      fournisseur: map['fournisseur'],
      fournisseurCode: map['fournisseur_code'],
      numBon: map['num_bon'],
      commentaire: map['commentaire'],
      cheminPhoto: map['chemin_photo'],
      dateReception: DateTime.parse(map['date_reception']),
      statut: map['statut'] ?? 'recu',
      deviceId: map['device_id'],
      dateTraitement: map['date_traitement'] != null ? DateTime.parse(map['date_traitement']) : null,
      traiteParCode: map['traite_par_code'],
      smartScanCode: map['smart_scan_code'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fournisseur': fournisseur,
      'fournisseur_code': fournisseurCode,
      'num_bon': numBon,
      'commentaire': commentaire,
      'chemin_photo': cheminPhoto,
      'date_reception': dateReception.toIso8601String(),
      'statut': statut,
      'device_id': deviceId,
      'date_traitement': dateTraitement?.toIso8601String(),
      'traite_par_code': traiteParCode,
      'smart_scan_code': smartScanCode,
    };
  }

  bool get estTraite => statut == 'traite';
  bool get estErreur => statut == 'erreur';

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
