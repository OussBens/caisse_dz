/// Une ligne du registre fiscal append-only (voir JournalFiscalServices).
/// Représente un événement de caisse déjà survenu et scellé — jamais
/// destinée à être modifiée après création.
class JournalFiscal {
  int       id;
  String    code;
  String    typeOperation;   // ex: "VENTE", "ANNULATION_VENTE"
  String    codeOperation;   // code métier concerné (ex: code du panier)
  String?   caisseCode;
  String    utilisateurCode;
  double?   montant;
  String?   donneesAvant;    // snapshot JSON avant l'événement (null à la création)
  String?   donneesApres;    // snapshot JSON après l'événement
  String    hash;
  String    hashPrecedent;
  DateTime  dateEvenement;

  JournalFiscal({
    required this.id,
    required this.code,
    required this.typeOperation,
    required this.codeOperation,
    required this.utilisateurCode,
    required this.hash,
    required this.hashPrecedent,
    required this.dateEvenement,
    this.caisseCode,
    this.montant,
    this.donneesAvant,
    this.donneesApres,
  });

  factory JournalFiscal.fromMap(Map<String, dynamic> map) {
    return JournalFiscal(
      id              : map['id'],
      code            : map['code'],
      typeOperation   : map['type_operation'],
      codeOperation   : map['code_operation'],
      caisseCode      : map['caisse_code'],
      utilisateurCode : map['utilisateur_code'],
      montant         : map['montant'] != null ? (map['montant'] as num).toDouble() : null,
      donneesAvant    : map['donnees_avant'],
      donneesApres    : map['donnees_apres'],
      hash            : map['hash'],
      hashPrecedent   : map['hash_precedent'],
      dateEvenement   : DateTime.parse(map['date_evenement']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'                : id,
      'code'              : code,
      'type_operation'    : typeOperation,
      'code_operation'    : codeOperation,
      'caisse_code'       : caisseCode,
      'utilisateur_code'  : utilisateurCode,
      'montant'           : montant,
      'donnees_avant'     : donneesAvant,
      'donnees_apres'     : donneesApres,
      'hash'              : hash,
      'hash_precedent'    : hashPrecedent,
      'date_evenement'    : dateEvenement.toIso8601String(),
    };
  }
}
