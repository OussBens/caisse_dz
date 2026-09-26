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
  String? fournisseurCode;

  // --- Foreign keys ---
  int categorieId;
  int sousCategorieId;
  int? remiseId;

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
  // ⚠️ Le stock n'est plus stocké sur le produit : il est calculé
  // dynamiquement depuis le journal des mouvements, voir
  // MouvementsServices.quantiteProduit()/totauxParProduit().
  String  uniteMesure;

  // Second stock parallèle (Paramètres > Nombre et Quantité) : nombre de
  // pièces physiques en stock, indépendant du poids/mesure (quantite) — ex.
  // boucherie : quantite en kg, nombre en nombre de pièces. Mouvementé
  // exactement comme quantite (achat +, vente -, retour client +, retour
  // fournisseur -, sortie -) partout où quantite l'est.
  double  nombre;

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
  String?   modifParCode;
  String?   annulerParCode;
  DateTime? annulerLe;
  String?   motifAnnul;

  // --- Nouveaux champs ---
  bool    service;

  // Override par produit de Paramters.activeNombreQuantite : si l'option
  // globale est désactivée, ce produit garde quand même le champ "nombre"
  // (au lieu de "quantité") quand nombreActif=true.
  bool    nombreActif;


  // --Besion-----

  String? taille;
  String? couleur;

  // Appareil mobile source (POST /api/sync/push/product), null pour les
  // produits créés depuis le desktop.
  String? deviceIdMobile;

  Produit({
    required this.id,
    required this.nom,
    required this.code,
    required this.marque,
    required this.multicodebar,
    required this.prixVente,
    required this.uniteMesure,
    this.nombre = 0,
    required this.prixAchat,
    required this.margeBool,
    required this.tva,
    required this.etat,
    required this.dateCree,
    required this.creeParcode,
    required this.service,
    this.nombreActif = false,
    required this.categorieId,
    required this.sousCategorieId,
    this.remiseId,
    required this.margeTaux,
    this.margeTauxPrct,

    this.dateEmpreint,
    this.description,
    this.numeroSerie,
    this.fournisseurCode,
    this.observation,
    this.emballage1,
    this.emballage2,
    this.emballageP1,
    this.emballageP2,
    this.annulerParCode,
    this.motifAnnul,
    this.dateModif,
    this.codeBarre,
    this.annulerLe,
    this.modifParCode,
    this.couleur,
     this.photo,
    this.taille,
    this.deviceIdMobile,
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
      remiseId              : map['remise_id'],
      description           : map['description'],
      categorieId           : map['categorie_id'],
      uniteMesure           : map['unite_mesure'],
      margeBool             : map['marge_bool']   == 1,
      multicodebar          : map['multicodebar'] == 1,
      sousCategorieId       : map['sous_categorie_id'],
      nombre           : (map['nombre'] as num?)?.toDouble() ?? 0,
      etat                  : map['etat'] == 1,
      dateCree              : DateTime.parse(map['date_cree']),
      creeParcode           : map['cree_par_code'],
      service               : map['service'] == 1,
      nombreActif           : map['nombre_actif'] == 1,
      tva                   : double.parse(map['tva'].toString()),
      prixAchat             : double.parse(map['prix_achat'].toString()),
      prixVente             : double.parse(map['prix_vente'].toString()),
      margeTaux             : double.parse(map['marge_taux'].toString()),
      margeTauxPrct         : double.parse(map['marge_tauxPrct'].toString()),
      photo                 : _parsePhoto(map['photos']),
      numeroSerie           : map['numero_serie'],
      codeBarre             : map['code_barre'],
      fournisseurCode       : map['fournisseur_code'],
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
      modifParCode              : map['modif_par_code'],
      annulerParCode            : map['annuler_par_code'],
      annulerLe             : map['annuler_le'] != null
          ? DateTime.parse(map['annuler_le'])
          : null,
      motifAnnul            : map['motif_annul'],
      taille                : map['taille'],
      couleur               : map['couleur'],
      deviceIdMobile        : map['device_id_mobile'],


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
     'fournisseur_code'     : fournisseurCode,

     'categorie_id'         : categorieId,
     'sous_categorie_id'    : sousCategorieId,
     'remise_id'            : remiseId,

     'multicodebar'         : multicodebar ? 1 : 0,
      'photos': photo != null ? jsonEncode([photo]) : null,
     'prix_achat'           : prixAchat,
     'marge_bool'           : margeBool ? 1 : 0,
     'marge_taux'           : margeTaux,
     'marge_tauxPrct'       : margeTauxPrct,
     'tva'                  : tva,
     'prix_vente'           : prixVente,

     'unite_mesure'         : uniteMesure,
     'nombre'               : nombre,

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
     'modif_par_code'            : modifParCode,
     'annuler_par_code'          : annulerParCode,
     'annuler_le'           : annulerLe?.toIso8601String(),
     'motif_annul'          : motifAnnul,

     'service'              : service ? 1 : 0,
     'nombre_actif'         : nombreActif ? 1 : 0,
     'taille'               : taille,
     'couleur'              : couleur,
     'device_id_mobile'     : deviceIdMobile,
   };
 }
  String get searchableText {
    return toMap()
        .values
        .map((e) => e?.toString().toLowerCase() ?? '')
        .join(' ');
  }
}
