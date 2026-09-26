class SmartScanProduit {
  int     id;
  String  codeSmartScan;
  String  codeProduit;

  double  quantite;
  // Nombre de pièces physiques achetées sur cette ligne (Paramètres > Nombre
  // et Quantité) — voir Produit.nombre.
  double? nombre;
  double  prix;
  double  prixVente;
  double  total;

  bool  etat; // "actif" ou "inactif"

  String    creeParCode;
  DateTime  creeLe;

  String? modifParCode;
  DateTime? modifLe;
  String? annulParCode;
  DateTime? annulLe;
  String? motifAnnul;

  SmartScanProduit({
    required this.id,
    required this.codeSmartScan,
    required this.codeProduit,
    required this.quantite,
    required this.prix,
    required this.prixVente,
    required this.total,
    required this.etat,
    required this.creeParCode,
    required this.creeLe,

    this.nombre,
    this.motifAnnul,
    this.annulParCode,
    this.annulLe,
    this.modifParCode,
    this.modifLe
  });

  // ------------------------------
  // map → Objet
  // ------------------------------
  factory SmartScanProduit.fromMap(Map<String, dynamic> map) {
    return SmartScanProduit(
      id            : map['id'],
      etat          : map['etat'] == 1,
      prix          : map['prix'],
      prixVente          : map['prixVente'],
      total         : map['total'],
      creeLe        : DateTime.parse(map['date_cree']),
      quantite      : map['quantite'],
      nombre        : (map['nombre'] as num?)?.toDouble(),
      creeParCode   : map['cree_par_code'],
      codeProduit   : map['code_produit'],
      codeSmartScan : map['code_SmartScan'],

      motifAnnul    : map['motif_annul'],
      modifParCode      : map['modif_par_code'],
      annulParCode      : map['annul_par_code'],
      modifLe       : map['modif_le'] != null
          ? DateTime.parse(map['modif_le'])
          : null,
      annulLe       : map['annul_le'] != null
          ? DateTime.parse(map['annul_le'])
          : null,
    );
  }

  // ------------------------------
  // Objet → map
  // ------------------------------
  Map<String, dynamic> toMap() {
    return {
      'id'              : id,
      'code_SmartScan'  : codeSmartScan,
      'code_produit'    : codeProduit,
      'quantite'        : quantite,
      'nombre'          : nombre,
      'prix'            : prix,
      'prixVente'       : prixVente,
      'total'           : total,
      'etat'            : etat ? 1 : 0,

      'cree_par_code'   : creeParCode,
      'date_cree'       : creeLe.toIso8601String(),

      'modif_par_code'       : modifParCode,
      'date_modif'      : modifLe?.toIso8601String(),
      'annul_par_code'       : annulParCode,
      'date_annul'      : annulLe?.toIso8601String(),
      'motif_annul'     : motifAnnul,
    };
  }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
  SmartScanProduit copy() => SmartScanProduit(
    id: id,
    codeSmartScan: codeSmartScan,
    codeProduit: codeProduit,
    quantite: quantite,
    nombre: nombre,
    prix: prix,
    prixVente: prixVente,
    total: total,
    etat: etat,
    creeParCode: creeParCode,
    creeLe: creeLe,
    modifParCode: modifParCode,
    modifLe: modifLe,
  );
}
