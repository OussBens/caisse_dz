/// État du quota Smart Scan d'un client, tel que calculé par le serveur BENS
/// (GET /smartscan/quota, et renvoyé après chaque scan). Aucune valeur de
/// forfait, de limite ou de prix n'est codée dans l'application : tout vient
/// de l'API, seule source de vérité.
class SmartScanQuota {
  final String plan;
  final String planNom;
  final int limiteMensuelle;
  final int utilises;
  final int restants;
  final DateTime? renouvellement;
  final DateTime? debutOffre;
  final DateTime? finOffre;

  /// "active" (offre payante en cours) ou "standard".
  final String statut;
  final bool offreDisponible;
  final List<SmartScanOffre> offres;
  final String contact;

  const SmartScanQuota({
    required this.plan,
    required this.planNom,
    required this.limiteMensuelle,
    required this.utilises,
    required this.restants,
    this.renouvellement,
    this.debutOffre,
    this.finOffre,
    this.statut = 'standard',
    this.offreDisponible = false,
    this.offres = const [],
    this.contact = '',
  });

  bool get offreActive => statut == 'active';
  bool get epuise => restants <= 0;

  /// Part utilisée, entre 0 et 1 (barre de progression).
  double get progression => limiteMensuelle <= 0 ? 1 : (utilises / limiteMensuelle).clamp(0, 1).toDouble();

  factory SmartScanQuota.fromJson(Map<String, dynamic> json) {
    DateTime? date(dynamic v) => v is String && v.isNotEmpty ? DateTime.tryParse(v) : null;
    int entier(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return SmartScanQuota(
      plan: json['plan']?.toString() ?? '',
      planNom: json['plan_nom']?.toString() ?? '',
      limiteMensuelle: entier(json['monthly_limit']),
      utilises: entier(json['used']),
      restants: entier(json['remaining']),
      renouvellement: date(json['renewal_date']),
      debutOffre: date(json['subscription_start']),
      finOffre: date(json['subscription_end']),
      statut: json['status']?.toString() ?? 'standard',
      offreDisponible: json['upgrade_available'] == true,
      offres: (json['offers'] as List? ?? [])
          .whereType<Map>()
          .map((o) => SmartScanOffre.fromJson(Map<String, dynamic>.from(o)))
          .toList(),
      contact: json['contact']?.toString() ?? '',
    );
  }
}

/// Offre payante proposée par le serveur (ex. Smart Scan 200).
class SmartScanOffre {
  final String code;
  final String nom;
  final int prixDa;
  final int quotaMensuel;
  final int dureeMois;

  const SmartScanOffre({
    required this.code,
    required this.nom,
    required this.prixDa,
    required this.quotaMensuel,
    required this.dureeMois,
  });

  factory SmartScanOffre.fromJson(Map<String, dynamic> json) {
    int entier(dynamic v) => v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    return SmartScanOffre(
      code: json['code']?.toString() ?? '',
      nom: json['nom']?.toString() ?? '',
      prixDa: entier(json['prix_da']),
      quotaMensuel: entier(json['quota_mensuel']),
      dureeMois: entier(json['duree_mois']),
    );
  }
}

/// Refus ou échec renvoyé par le serveur Smart Scan ({success:false, error,
/// message}). [code] permet d'afficher un message traduit ; [quota] est
/// présent quand le quota est atteint (SCAN_QUOTA_EXCEEDED).
class SmartScanErreur {
  static const quotaAtteint = 'SCAN_QUOTA_EXCEEDED';
  static const reseau = 'NETWORK_ERROR';

  final String code;
  final String message;
  final SmartScanQuota? quota;

  const SmartScanErreur(this.code, this.message, {this.quota});

  bool get estQuotaAtteint => code == quotaAtteint;
}
