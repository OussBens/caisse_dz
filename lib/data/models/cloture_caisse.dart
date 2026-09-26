/// Une clôture de caisse (rapport Z) : résumé figé d'une période de ventes
/// pour une caisse donnée. Une fois créée, une clôture n'est jamais modifiée
/// ni supprimée — voir ClotureCaisseServices (aucune méthode update/delete).
class ClotureCaisse {
  int       id;
  String    code;
  String    caisseCode;
  DateTime  dateDebut;
  DateTime  dateFin;
  double    totalVentes;
  double    totalAnnule;
  int       nombreTickets;
  int       nombreTicketsAnnules;
  String?   repartitionPaiement; // JSON {"Espèce": 1200.0, "Carte": 300.0, ...}
  String    utilisateurCode;
  DateTime  dateCree;
  String    hash;
  String    hashPrecedent;

  ClotureCaisse({
    required this.id,
    required this.code,
    required this.caisseCode,
    required this.dateDebut,
    required this.dateFin,
    required this.totalVentes,
    required this.totalAnnule,
    required this.nombreTickets,
    required this.nombreTicketsAnnules,
    required this.utilisateurCode,
    required this.dateCree,
    required this.hash,
    required this.hashPrecedent,
    this.repartitionPaiement,
  });

  factory ClotureCaisse.fromMap(Map<String, dynamic> map) {
    return ClotureCaisse(
      id                    : map['id'],
      code                  : map['code'],
      caisseCode            : map['caisse_code'],
      dateDebut             : DateTime.parse(map['date_debut']),
      dateFin               : DateTime.parse(map['date_fin']),
      totalVentes           : (map['total_ventes'] as num).toDouble(),
      totalAnnule           : (map['total_annule'] as num).toDouble(),
      nombreTickets         : map['nombre_tickets'],
      nombreTicketsAnnules  : map['nombre_tickets_annules'],
      repartitionPaiement   : map['repartition_paiement'],
      utilisateurCode       : map['utilisateur_code'],
      dateCree              : DateTime.parse(map['date_cree']),
      hash                  : map['hash'],
      hashPrecedent         : map['hash_precedent'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'                      : id,
      'code'                    : code,
      'caisse_code'             : caisseCode,
      'date_debut'              : dateDebut.toIso8601String(),
      'date_fin'                : dateFin.toIso8601String(),
      'total_ventes'            : totalVentes,
      'total_annule'            : totalAnnule,
      'nombre_tickets'          : nombreTickets,
      'nombre_tickets_annules'  : nombreTicketsAnnules,
      'repartition_paiement'    : repartitionPaiement,
      'utilisateur_code'        : utilisateurCode,
      'date_cree'               : dateCree.toIso8601String(),
      'hash'                    : hash,
      'hash_precedent'          : hashPrecedent,
    };
  }
}
