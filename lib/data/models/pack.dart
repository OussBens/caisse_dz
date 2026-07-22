import 'package:caisse_dz/data/models/produit_pack_detail.dart';

class Pack {
  int     id;
  bool    etat;
  String  code;
  String  nom;
  int     quantiteTotale;  // NOUVEAU : Somme des quantités de tous les produits
  double  prixVente;   // Prix total calculé du pack
  double? prixVenteOriginal; // Optionnel : prix saisi manuellement

  String? observation;

  String    creePar;
  String    creeParCode;
  DateTime    creeLe;

  String? modifPar;
  DateTime? modifLe;
  String? annulPar;
  DateTime? annulLe;
  String? motifAnnul;

  Pack({
    required this.creeParCode,
    required this.prixVente,
    required this.creePar,
    required this.quantiteTotale,  // NOUVEAU
    required this.creeLe,
    required this.etat,
    required this.code,
    required this.nom,
    required this.id,
    this.observation,
    this.prixVenteOriginal,
    this.modifPar,
    this.modifLe,
    this.annulPar,
    this.annulLe,
    this.motifAnnul,
  });

  // --- Convertir map -> Objet
  factory Pack.fromMap(Map<String, dynamic> map) {
    return Pack(
      observation       : map['description'],
      creeParCode       : map['cree_par_code'],
      prixVente         : map['prix_vente'] ?? 0.0,
      prixVenteOriginal : map['prix_vente_original']?.toDouble(),
      creePar           : map['cree_par'],
      quantiteTotale    : map['quantite_totale'] ?? 0,
      creeLe            : DateTime.parse(map['cree_le']),
      code              : map['code'],
      etat              : map['etat'] == 1,
      nom               : map['nom'],
      id                : map['id'],
      modifPar          : map['modif_par'],
      modifLe           : map['modif_le'] != null
          ? DateTime.parse(map['modif_le'])
          : null,
      annulPar          : map['annul_par'],
      annulLe           : map['annul_le'] != null
          ? DateTime.parse(map['annul_le'])
          : null,
      motifAnnul        : map['motif_annul'],
    );
  }

  // --- Convertir Objet -> map
  Map<String, dynamic> toMap() {
    return {
      'id'                : id,
      'nom'               : nom,
      'code'              : code,
      'etat'              : etat ? 1 : 0,
      'description'       : observation,
      'quantite_totale'   : quantiteTotale,
      'prix_vente'        : prixVente,
      'prix_vente_original': prixVenteOriginal,
      'cree_par'          : creePar,
      'cree_par_code'     : creeParCode,
      'cree_le'           : creeLe.toIso8601String(),
      'modif_par'         : modifPar,
      'modif_le'          : modifLe?.toIso8601String(),
      'annul_par'         : annulPar,
      'annul_le'          : annulLe?.toIso8601String(),
      'motif_annul'       : motifAnnul,
    };
  }

  // Recalculer les totaux du pack à partir de la liste des détails
  void recalculerTotaux(List<ProduitPackDetail> details) {
    quantiteTotale = details.fold(0, (sum, item) => sum + item.quantite);
    prixVente = details.fold(0.0, (sum, item) => sum + item.montant);
  }

  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}