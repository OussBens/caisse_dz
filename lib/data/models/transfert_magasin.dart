/// Transfert de marchandise entre deux magasins — distinct de
/// [TransfertCaisse] (transfert d'argent entre deux caisses, table
/// `transfert`). Chaque transfert génère 2 [Mouvement] liés (type
/// "Transfert", sousType Sortie@source / Entrée@destination, même
/// codeOperation) — voir lib/core/dialog/transfert_magasin/transfert_magasin_nouveau.dart.
class TransfertMagasin {
  int      id;
  String   code;
  DateTime date;

  String produitCode;
  double quantite;
  // Second stock parallèle (nombre de pièces) — voir Produit.nombre.
  double? nombre;

  String magasinSourceCode;
  String magasinDestCode;

  bool    etat;
  String? observation;

  // Audit
  String    creeParCode;
  DateTime  dateCree;

  DateTime? dateModif;
  String?   modifParCode;
  DateTime? dateAnnul;
  String?   annulParCode;
  String?   motifAnnul;

  TransfertMagasin({
    required this.id,
    required this.code,
    required this.date,
    required this.produitCode,
    required this.quantite,
    required this.magasinSourceCode,
    required this.magasinDestCode,
    required this.etat,
    required this.dateCree,
    required this.creeParCode,

    this.nombre,
    this.observation,
    this.dateModif,
    this.modifParCode,
    this.dateAnnul,
    this.annulParCode,
    this.motifAnnul,
  });

  factory TransfertMagasin.fromMap(Map<String, dynamic> map) {
    return TransfertMagasin(
      id                : map['id'],
      code              : map['code'],
      date              : DateTime.parse(map['date']),
      produitCode       : map['produit_code'],
      quantite          : map['quantite'],
      nombre            : (map['nombre'] as num?)?.toDouble(),
      magasinSourceCode : map['magasin_source_code'],
      magasinDestCode   : map['magasin_dest_code'],
      etat              : map['etat'] == 1,
      observation       : map['observation'],
      dateCree          : DateTime.parse(map['date_cree']),
      creeParCode       : map['cree_par_code'],
      modifParCode      : map['modif_par_code'],
      annulParCode      : map['annul_par_code'],
      motifAnnul        : map['motif_annul'],
      dateModif         : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      dateAnnul         : map['date_annul'] != null
          ? DateTime.parse(map['date_annul'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id'                  : id,
      'code'                : code,
      'date'                : date.toIso8601String(),
      'produit_code'        : produitCode,
      'quantite'            : quantite,
      'nombre'              : nombre,
      'magasin_source_code' : magasinSourceCode,
      'magasin_dest_code'   : magasinDestCode,
      'etat'                : etat ? 1 : 0,
      'observation'         : observation,
      'date_cree'           : dateCree.toIso8601String(),
      'cree_par_code'       : creeParCode,
      'date_modif'          : dateModif?.toIso8601String(),
      'modif_par_code'      : modifParCode,
      'date_annul'          : dateAnnul?.toIso8601String(),
      'annul_par_code'      : annulParCode,
      'motif_annul'         : motifAnnul,
    };
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
