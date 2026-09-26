class Pannier {
  int id;
  DateTime date;
  String code;
  int? nombreArticle;
  int? quantiteProduit;
  double montant;      // total du panier
  double montantAchat;      // total du panier
  double marge;      // total du panier
  String? client_code;
  String? modePaiement; // espèce, carte, chèque, etc.
  String caisse_code;
  String caissier_code;
  String caisse;

  bool    etat;         // actif, annulé, en cours, payé
  String  typepannier;  // ticket ou BL ou SC
  String? observation;  // optionnel, commentaire ou note

  // Audit
  DateTime  dateCree;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  // POST /api/sync/push/sale : uuid mobile (idempotence — évite les
  // doublons sur retry réseau) et appareil source, null pour les panniers
  // créés depuis le desktop.
  String? uuid;
  String? deviceIdMobile;

  // Scellement fiscal (voir PannierServices._sealPannier) : empreinte
  // SHA-256 de ce ticket et empreinte du ticket précédent sur la même
  // caisse — chaînage qui rend toute altération après coup détectable.
  // Renseignés uniquement par le service à la création, jamais en écriture
  // libre depuis l'UI.
  String? hash;
  String? hashPrecedent;

  Pannier({

    required this.id,
    required this.code,
    required this.montant,
    required this.montantAchat,
    required this.marge,
    required this.typepannier,
    required this.date,
    required this.dateCree,
    required this.etat,
    required this.caissier_code,
    required this.caisse_code,
    required this.caisse,

    this.client_code,
    this.modePaiement,
    this.observation,
    this.nombreArticle,
    this.quantiteProduit,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
    this.uuid,
    this.deviceIdMobile,
    this.hash,
    this.hashPrecedent,

  });

  factory Pannier.fromMap(Map<String, dynamic> map) {
    return Pannier(
      id              : map['id'],
      code            : map['code'],
      nombreArticle   : map['nombre_article'],
      quantiteProduit : map['quantite_produit'],
      montant         : map['montant'],
      montantAchat    : map['montant_achat']?? 0.0,
      marge           : map['marge']?? 0.0,
      client_code     : map['client_code'],
      modePaiement    : map['mode_paiement'],
      caissier_code   : map['caisser_code'],
      caisse          : map['caisse'],
      caisse_code     : map['caisse_code'],
      etat            : map['etat'] == 1,
      observation     : map['observation'],
      typepannier     : map['type_pannier'],
      dateCree        : DateTime.parse(map['date_cree']),
      date            : DateTime.parse(map['date']),
      dateModif       : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifParCode        : map['modif_par_code'],
      dateAnnul       : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
      annulParCode        : map['annul_par_code'],
      motifAnnul      : map['motif_annul'],
      uuid            : map['uuid'],
      deviceIdMobile  : map['device_id_mobile'],
      hash            : map['hash'],
      hashPrecedent   : map['hash_precedent'],
    );
  }

  Map<String, dynamic> toMap()
  {
    return{
      'id'                : id,
      'date'              : date.toIso8601String(),
      'code'              : code,
      'nombre_article'    : nombreArticle,
      'quantite_produit'  : quantiteProduit,
      'montant'           : montant,
      'montant_achat'     : montantAchat,
      'marge'             : marge,
      'client_code'       : client_code,
      'mode_paiement'     : modePaiement,
      'caisser_code'      : caissier_code,
      'caisse'            : caisse,
      'caisse_code'       : caisse_code,
      'etat'              : etat ? 1 : 0,
      'observation'       : observation,
      'type_pannier'      : typepannier,
      'date_cree'         : dateCree.toIso8601String(),
      'date_modif'        : dateModif?.toIso8601String(),
      'modif_par_code'         : modifParCode,
      'date_annul'        : dateAnnul?.toIso8601String(),
      'annul_par_code'         : annulParCode,
      'motif_annul'       : motifAnnul,
      'uuid'              : uuid,
      'device_id_mobile'  : deviceIdMobile,
      'hash'              : hash,
      'hash_precedent'    : hashPrecedent,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
