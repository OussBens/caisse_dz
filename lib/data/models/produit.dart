import 'dart:convert';

class Produit {
  // --- Informations générales ---
  int id;
  String nom;
  String code;
  String marque;

  String? description;
  String? codeBarre;
  String? numeroSerie;
  String fournisseur;

  // --- Foreign keys ---
  int categorieId;
  int sousCategorieId;
  int? remiseId;

  // --- Catégorie ---
  String categorie;
  String sousCategorie;
  String? remise;

  bool multicodebar;


  // --- Prix / Remise / TVA ---
  double prixAchat;
  double prixVente;
  bool   margeBool;
  double margeTaux;
  double? margeTauxPrct;

  double tva;
  String? photo;

  // --- Stock / Unité ---
  bool    seuilBool;
  double  quantite;
  double  seuilMin;
  double  seuilMax;
  String  uniteMesure;

  String?   observation;
  DateTime? dateEmpreint;

  // --- Emballage ---
  double? emballage1;
  double? emballageP1;
  double? emballageP2;
  double? emballage2;

  // --- Audit / Historique ---
  String    creeParcode;
  DateTime  dateCree;
  bool      etat;

  DateTime? dateModif;
  String?   modifPar;
  String?   annulerPar;
  DateTime? annulerLe;
  String?   motifAnnul;

  // --- Nouveaux champs ---
  bool    service;


  // --Besion-----

  String? taille;
  String? couleur;

  Produit({
    required this.id,
    required this.nom,
    required this.code,
    required this.marque,
    required this.categorie,
    required this.sousCategorie,
    required this.multicodebar,
    required this.prixVente,
    required this.uniteMesure,
    required this.quantite,
    required this.seuilBool,
    required this.seuilMin,
    required this.seuilMax,
    required this.prixAchat,
    required this.margeBool,
    required this.tva,
    required this.etat,
    required this.dateCree,
    required this.creeParcode,
    required this.service,
    required this.categorieId,
    required this.sousCategorieId,
    this.remiseId,
    required this.margeTaux,
    this.margeTauxPrct,

    this.dateEmpreint,
    this.description,
    this.numeroSerie,
    required this.fournisseur,
    this.observation,
    this.emballage1,
    this.emballage2,
    this.emballageP1,
    this.emballageP2,
    this.annulerPar,
    this.motifAnnul,
    this.dateModif,
    this.codeBarre,
    this.annulerLe,
    this.modifPar,
    this.couleur,
     this.photo,
    this.remise,
    this.taille,
  });

  // ------------------------------------------------------------------
  // map -> Objet
  // ------------------------------------------------------------------
  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final cleaned = value.trim().replaceAll(',', '.');
      final parsedDouble = double.tryParse(cleaned);
      if (parsedDouble != null) return parsedDouble.toInt();
      final parsedInt = int.tryParse(cleaned);
      if (parsedInt != null) return parsedInt;
    }
    return 0;
  }

  factory Produit.fromMap(Map<String, dynamic> map) {
    return Produit(
      id                    : map['id'],
      nom                   : map['nom'],
      code                  : map['code'],
      marque                : map['marque'],
      categorie             : map['categorie'],
      remiseId              : map['remise_id'],
      description           : map['description'],
      categorieId           : map['categorie_id'],
      uniteMesure           : map['unite_mesure'],
      sousCategorie         : map['sous_categorie'],
      seuilBool             : map['seuil_bool']   == 1,
      margeBool             : map['marge_bool']   == 1,
      multicodebar          : map['multicodebar'] == 1,
      sousCategorieId       : map['sous_categorie_id'],
      quantite              : double.parse(map['quantite'].toString()),
      seuilMin              : double.parse(map['seuil_min'].toString()),
      seuilMax              : double.parse(map['seuil_max'].toString()),
      etat                  : map['etat'] == 1,
      dateCree              : DateTime.parse(map['date_cree']),
      creeParcode           : map['cree_par_code'],
      service               : map['service'] == 1,
      tva                   : double.parse(map['tva'].toString()),
      prixAchat             : double.parse(map['prix_achat'].toString()),
      prixVente             : double.parse(map['prix_vente'].toString()),
      margeTaux             : double.parse(map['marge_taux'].toString()),
      margeTauxPrct         : double.parse(map['marge_tauxPrct'].toString()),
      photo                 : _parsePhoto(map['photos']),
       remise                : map['remise'],
      numeroSerie           : map['numero_serie'],
      codeBarre             : map['code_barre'],
      fournisseur           : map['fournisseur'],
      emballage1            : map['emballage1'],
      emballage2            : map['emballage2'],
      emballageP1            : map['emballagep1'],
      emballageP2            : map['emballagep2'],

      dateEmpreint          : map['date_empreint'] != null
          ? DateTime.parse(map['date_empreint'])
          : null,
      observation           : map['observation'],
      dateModif             : map['date_modif'] != null
          ? DateTime.parse(map['date_modif'])
          : null,
      modifPar              : map['modif_par'],
      annulerPar            : map['annuler_par'],
      annulerLe             : map['annuler_le'] != null
          ? DateTime.parse(map['annuler_le'])
          : null,
      motifAnnul            : map['motif_annul'],
      taille                : map['taille'],
      couleur               : map['couleur'],


    );
  }
  static String? _parsePhoto(dynamic photosData) {
    if (photosData == null) return null;
    if (photosData is String && photosData.isNotEmpty) {
      try {
        final list = List<String>.from(jsonDecode(photosData));
        return list.isNotEmpty ? list.first : null;
      } catch (e) {
        return photosData;
      }
    }
    return null;
  }

  // ------------------------------------------------------------------
  // Objet -> map
  // ------------------------------------------------------------------
  Map<String, dynamic> toMap() {
   return{
     'id'                   : id,
     'nom'                  : nom,
     'description'          : description,
     'marque'               : marque,
     'code_barre'           : codeBarre,
     'code'                 : code,
     'numero_serie'         : numeroSerie,
     'fournisseur'          : fournisseur,

     'categorie_id'         : categorieId,
     'sous_categorie_id'    : sousCategorieId,
     'remise_id'            : remiseId,

     'categorie'            : categorie,
     'sous_categorie'       : sousCategorie,
     'remise'               : remise,

     'multicodebar'         : multicodebar ? 1 : 0,
      'photos': photo != null ? jsonEncode([photo]) : null,
     'prix_achat'           : prixAchat,
     'marge_bool'           : margeBool ? 1 : 0,
     'marge_taux'           : margeTaux,
     'marge_tauxPrct'       : margeTauxPrct,
     'tva'                  : tva,
     'prix_vente'           : prixVente,

     'unite_mesure'         : uniteMesure,
     'quantite'             : quantite,
     'seuil_bool'           : seuilBool ? 1 : 0,
     'seuil_min'            : seuilMin,
     'seuil_max'            : seuilMax,

     'observation'          : observation,
     'date_empreint'        : dateEmpreint?.toIso8601String(),
     'emballage1'           : emballage1,
     'emballage2'           : emballage2,
     'emballagep1'           : emballageP1,
     'emballagep2'           : emballageP2,

     'etat'                 : etat ? 1 : 0,
     'date_cree'            : dateCree.toIso8601String(),
     'cree_par_code'        : creeParcode,

     'date_modif'           : dateModif?.toIso8601String(),
     'modif_par'            : modifPar,
     'annuler_par'          : annulerPar,
     'annuler_le'           : annulerLe?.toIso8601String(),
     'motif_annul'          : motifAnnul,

     'service'              : service ? 1 : 0,
     'taille'               : taille,
     'couleur'              : couleur,
   };
 }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
