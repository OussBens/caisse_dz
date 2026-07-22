import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

// -----------------------------
// PACKS NON SUPPRIMABLES
// -----------------------------
class NonSupprimablePack {
  final String nom;
  final String code;

  const NonSupprimablePack({required this.nom, required this.code});
}

// -----------------------------
// ENUMS
// -----------------------------
enum TypeCalcul { Montant, Pourcentage }
enum Etat { actif, inactif }
enum MergeAuto { Oui, Non }
enum TvaAuto { Oui, Non }
enum SeuilAuto { Oui, Non }

// -----------------------------
// CONSTANTES SIMPLES
// -----------------------------
class AppConst {
  static const double tvaParDefaut = 19.0;
  static const double remiseMax = 50.0;
  static const String devise = "DZD";
  static const String msgErreurServeur = "Erreur du serveur !";
  static const String msgAucunResultat = "Aucun résultat trouvé.";
  static const double FontSizeTable = 13;
}
// Ajoutez cette classe dans votre fichier constant.dart (après les autres classes)

// -----------------------------
// PREFIXES POUR CODES (Code Generator)
// -----------------------------
class CodePrefix {
  // Dans constant.dart, ajoutez dans CodePrefix
   static const String produit = "PRD";
  static const String client = "CL";
  static const String pannier = "PN";
  static const String mouvement = "MV";
  static const String historique = "HS";
  static const String verssement = "VRS";
  static const String facture = "FAC";
  static const String bonLivraison = "BLSC";
  static const String categorie = "CAT";
  static const String sousCategorie = "SC";
  static const String fournisseur = "FRN";
  static const String magasin = "MAG";
  static const String remise = "REM";
  static const String pack = "PCK";
  static const String utilisateur = "USR";
  static const String caisse = "CS";
  static const String retour = "RET";
  static const String transfert = "TRF";
  static const String zakat = "ZKT";
  static const String entree = "EN"; // ✅ Ajout pour les entrées
  static const String role = "ROL"; // ✅ Ajout pour les entrées
  static const String smartscan = "SS"; // ✅ Ajout pour les entrées
  static const String sortie = "SRT"; // ✅ Ajout pour les entrées

  // Obtenir la liste complète des préfixes
  static List<String> get allPrefixes => [
    produit,
    client,
    pannier,
    mouvement,
    historique,
    verssement,
    facture,
    bonLivraison,
    categorie,
    sousCategorie,
    fournisseur,
    magasin,
    remise,
    pack,
    utilisateur,
    caisse,
    retour,
    transfert,
    zakat,
    entree,
    role,
    smartscan,
    sortie
  ];

  // Obtenir la liste des préfixes avec leurs descriptions
  static Map<String, String> get prefixDescriptions => {
    produit: "Produit",
    client: "Client",
    pannier: "Pannier",
    mouvement: "Mouvement de stock",
    historique: "Historique",
    verssement: "Versement",
    facture: "Facture",
    bonLivraison: "Bon de livraison",
    categorie: "Catégorie",
    sousCategorie: "Sous-catégorie",
    fournisseur: "Fournisseur",
    magasin: "Magasin",
    remise: "Remise",
    pack: "Pack",
    utilisateur: "Utilisateur",
    caisse: "Caisse",
    retour: "Retour",
    transfert: "Transfert",
    zakat: "Zakat",
    entree:"Entrée",
    role:"Role",
    smartscan:"Role",
    sortie:"Sortie"
  };
}
// -----------------------------
// TRANSLATOR CLASS FOR ALL LISTS
// -----------------------------
class ListsConstTranslator {
  final AppLocalizations l10n;

  ListsConstTranslator(this.l10n);

  // ==================== TYPE CALCUL ====================
  String translateTypeCalcul(String frenchValue) {
    switch (frenchValue) {
      case 'Montant': return l10n.montant;
      case 'Pourcentage': return l10n.pourcentage;
      default: return frenchValue;
    }
  }
  String translateColis(String frenchValue) {
    switch(frenchValue) {
      case 'Toujours demandé' : return l10n.alwaysAsked;
      case 'Petit colis'      : return l10n.smallParcel;
      case 'Grand colis'      : return l10n.largeParcel;
      default : return l10n.alwaysAsked;
    }
  }

  String colisToFrench(String translatedValue) {
    if(translatedValue  ==  l10n.alwaysAsked) return  'Toujours demandé';
    if(translatedValue  ==  l10n.smallParcel) return  'Petit colis';
    if(translatedValue  ==  l10n.largeParcel) return  'Grand colis';
    return translatedValue;
  }

  List<String> get colisDisplayList => [
    l10n.uniteParcel,
    l10n.smallParcel,
    l10n.largeParcel,
  ];

  String typeCalculToFrench(String translatedValue) {
    if (translatedValue == l10n.montant) return 'Montant';
    if (translatedValue == l10n.pourcentage) return 'Pourcentage';
    return translatedValue;
  }

  List<String> get typeCalculDisplayList => [
    l10n.montant,
    l10n.pourcentage,
  ];

  // ==================== ETAT ====================
  String translateEtat(String frenchValue) {
    switch (frenchValue) {
      case 'Actif': return l10n.actif;
      case 'Inactif': return l10n.inactif;
      default: return frenchValue;
    }
  }

  String etatToFrench(String translatedValue) {
    if (translatedValue == l10n.actif) return 'Actif';
    if (translatedValue == l10n.inactif) return 'Inactif';
    return translatedValue;
  }

  List<String> get etatDisplayList => [
    l10n.actif,
    l10n.inactif,
  ];

  // ==================== ETAT VERSEMENT ====================
  String translateEtatVersement(String frenchValue) {
    switch (frenchValue) {
      case 'Validé': return l10n.valide;
      case 'Annulé': return l10n.annule;
      default: return frenchValue;
    }
  }

  String etatVersementToFrench(String translatedValue) {
    if (translatedValue == l10n.valide) return 'Validé';
    if (translatedValue == l10n.annule) return 'Annulé';
    return translatedValue;
  }

  List<String> get etatVersementDisplayList => [
    l10n.valide,
    l10n.annule,
  ];

  // ==================== STATUT ZAKAT ====================
  String translateStatutZakat(String frenchValue) {
    switch (frenchValue) {
      case 'Non payé': return l10n.unpaid;
      case 'Payée': return l10n.paid;
      default: return frenchValue;
    }
  }

  String statutZakatToFrench(String translatedValue) {
    if (translatedValue == l10n.unpaid) return 'Non payé';
    if (translatedValue == l10n.paid) return 'Payée';
    return translatedValue;
  }

  List<String> get statutZakatDisplayList => [
    l10n.unpaid,
    l10n.paid,
  ];

  // ==================== TYPE REMISE ====================
  String translateTypeRemise(String frenchValue) {
    switch (frenchValue) {
      case 'Par Montant': return l10n.parMontant;
      case 'Par Produit': return l10n.parProduit;
      default: return frenchValue;
    }
  }

  String typeRemiseToFrench(String translatedValue) {
    if (translatedValue == l10n.parMontant) return 'Par Montant';
    if (translatedValue == l10n.parProduit) return 'Par Produit';
    return translatedValue;
  }

  List<String> get typeRemiseDisplayList => [
    l10n.parMontant,
    l10n.parProduit,
  ];

  // ==================== TYPE BESOIN PRODUIT ====================
  String translateTypeBesoinProduit(String frenchValue) {
    switch (frenchValue) {
      case 'En Attente': return l10n.enAttente;
      case 'Commande': return l10n.commande;
      case 'Disponible': return l10n.disponible;
      default: return frenchValue;
    }
  }

  String typeBesoinProduitToFrench(String translatedValue) {
    if (translatedValue == l10n.enAttente) return 'En Attente';
    if (translatedValue == l10n.commande) return 'Commande';
    if (translatedValue == l10n.disponible) return 'Disponible';
    return translatedValue;
  }

  List<String> get typeBesoinProduitDisplayList => [
    l10n.enAttente,
    l10n.commande,
    l10n.disponible,
  ];

  // ==================== TYPE SORTIE ====================
  String translateTypeSortie(String frenchValue) {
    switch (frenchValue) {
      case 'Expiration': return l10n.expiration;
      case 'Don': return l10n.don;
      case 'Autre': return l10n.autre;
      default: return frenchValue;
    }
  }

  String typeSortieToFrench(String translatedValue) {
    if (translatedValue == l10n.expiration) return 'Expiration';
    if (translatedValue == l10n.don) return 'Don';
    if (translatedValue == l10n.autre) return 'Autre';
    return translatedValue;
  }

  List<String> get typeSortieDisplayList => [
    l10n.expiration,
    l10n.don,
    l10n.autre,
  ];

  // ==================== TYPE PANIER ====================
  String translateTypePannier(String frenchValue) {
    switch (frenchValue) {
      case 'BL': return l10n.bl;
      case 'BL_SC': return l10n.blSc;
      case 'Ticket': return l10n.ticket;
      default: return frenchValue;
    }
  }

  String typePannierToFrench(String translatedValue) {
    if (translatedValue == l10n.bl) return 'BL';
    if (translatedValue == l10n.blSc) return 'BL_SC';
    if (translatedValue == l10n.ticket) return 'Ticket';
    return translatedValue;
  }

  List<String> get typePannierDisplayList => [
    l10n.bl,
    l10n.blSc,
    l10n.ticket,
  ];

  // ==================== TYPE CAISSE ====================
  String translateTypeCaisse(String frenchValue) {
    switch (frenchValue) {
      case 'Physique': return l10n.physique;
      case 'Compte': return l10n.compte;
      default: return frenchValue;
    }
  }

  String typeCaisseToFrench(String translatedValue) {
    if (translatedValue == l10n.physique) return 'Physique';
    if (translatedValue == l10n.compte) return 'Compte';
    return translatedValue;
  }

  List<String> get typeCaisseDisplayList => [
    l10n.physique,
    l10n.compte,
  ];

  // ==================== UNITE MESURE ====================
  String translateUniteMesure(String frenchValue) {
    switch (frenchValue) {
      case 'Pièce': return l10n.piece;
      case 'Kg'   : return l10n.kg;
      case 'Litre': return l10n.litre;
      case 'Mètre': return l10n.metre;
      default: return frenchValue;
    }
  }

  String uniteMesureToFrench(String translatedValue) {
    if (translatedValue == l10n.piece) return 'Pièce';
    if (translatedValue == l10n.kg)   return 'Kg';
    if (translatedValue == l10n.litre) return 'Litre';
    if (translatedValue == l10n.metre) return 'Mètre';
    return translatedValue;
  }

  List<String> get uniteMesureDisplayList => [
    l10n.piece,
    l10n.kg,
    l10n.litre,
    l10n.metre,
  ];

  // ==================== MODE PAIEMENT ====================
  String translateModePaiement(String frenchValue) {
    switch (frenchValue) {
      case 'Espèces'  : return l10n.especes;
      case 'Carte'    : return l10n.carte;
      case 'Chèque'   : return l10n.cheque;
      case 'Virement' : return l10n.virement;
      default: return frenchValue;
    }
  }

  String modePaiementToFrench(String translatedValue) {
    if (translatedValue == l10n.especes)  return 'Espèces';
    if (translatedValue == l10n.carte)    return 'Carte';
    if (translatedValue == l10n.cheque)   return 'Chèque';
    if (translatedValue == l10n.virement) return 'Virement';
    return translatedValue;
  }

  List<String> get modePaiementDisplayList => [
    l10n.especes,
    l10n.carte,
    l10n.cheque,
    l10n.virement,
  ];

  // ==================== TYPE FOURNISSEUR ====================
  String translateTypeFournisseur(String frenchValue) {
    switch (frenchValue) {
      case 'Usine'          : return l10n.usine;
      case 'Société'        : return l10n.societe;
      case 'Importateur'    : return l10n.importateur;
      case 'Grossiste'      : return l10n.grossiste;
      case 'Semi-Grossiste' : return l10n.semiGrossiste;
      case 'Détaillant'     : return l10n.detailant;
      case 'Autre'          : return l10n.autre;
      default: return frenchValue;
    }
  }

  String typeFournisseurToFrench(String translatedValue) {
    if (translatedValue == l10n.usine)          return 'Usine';
    if (translatedValue == l10n.societe)        return 'Société';
    if (translatedValue == l10n.importateur)    return 'Importateur';
    if (translatedValue == l10n.grossiste)      return 'Grossiste';
    if (translatedValue == l10n.semiGrossiste)  return 'Semi-Grossiste';
    if (translatedValue == l10n.detailant)      return 'Détaillant';
    if (translatedValue == l10n.autre)          return 'Autre';
    return translatedValue;
  }

  List<String> get typeFournisseurDisplayList => [
    l10n.usine,
    l10n.societe,
    l10n.importateur,
    l10n.grossiste,
    l10n.semiGrossiste,
    l10n.detailant,
    l10n.autre,
  ];

  // ==================== TYPE CLIENT ====================
  String translateTypeClient(String frenchValue) {
    switch (frenchValue) {
      case 'Usine'          : return l10n.usine;
      case 'Société'        : return l10n.societe;
      case 'Grossiste'      : return l10n.grossiste;
      case 'Semi-Grossiste' : return l10n.semiGrossiste;
      case 'Détaillant'     : return l10n.detailant;
      case 'Consommateur'   : return l10n.consommateur;
      case 'Autre'          : return l10n.autre;
      default: return frenchValue;
    }
  }

  String typeClientToFrench(String translatedValue) {
    if (translatedValue == l10n.usine)          return 'Usine';
    if (translatedValue == l10n.societe)        return 'Société';
    if (translatedValue == l10n.grossiste)      return 'Grossiste';
    if (translatedValue == l10n.semiGrossiste)  return 'Semi-Grossiste';
    if (translatedValue == l10n.detailant)      return 'Détaillant';
    if (translatedValue == l10n.consommateur)   return 'Consommateur';
    if (translatedValue == l10n.autre)          return 'Autre';
    return translatedValue;
  }

  List<String> get typeClientDisplayList => [
    l10n.usine,
    l10n.societe,
    l10n.grossiste,
    l10n.semiGrossiste,
    l10n.detailant,
    l10n.consommateur,
    l10n.autre,
  ];

  // ==================== TYPE MOUVEMENT ====================
  String translateTypeMouvement(String frenchValue) {
    switch (frenchValue) {
      case 'Vente'      : return l10n.vente;
      case 'Achat'      : return l10n.achat;
      case 'Retour'     : return l10n.retour;
      case 'Déstockage' : return l10n.destockage;
      default: return frenchValue;
    }
  }

  String typeMouvementToFrench(String translatedValue) {
    if (translatedValue == l10n.vente)      return 'Vente';
    if (translatedValue == l10n.achat)      return 'Achat';
    if (translatedValue == l10n.retour)     return 'Retour';
    if (translatedValue == l10n.destockage) return 'Déstockage';
    return translatedValue;
  }

  List<String> get typeMouvementDisplayList => [
    l10n.vente,
    l10n.achat,
    l10n.retour,
    l10n.destockage,
  ];

  // ==================== TYPE RETOUR ====================
  String translateTypeRetour(String frenchValue) {
    switch (frenchValue) {
      case 'Client'       : return l10n.client;
      case 'Fournisseur'  : return l10n.fournisseur;
      default             : return frenchValue;
    }
  }

  String typeRetourToFrench(String translatedValue) {
    if (translatedValue == l10n.client)       return 'Client';
    if (translatedValue == l10n.fournisseur)  return 'Fournisseur';
    return translatedValue;
  }

  List<String> get typeRetourDisplayList => [
    l10n.client,
    l10n.fournisseur,
  ];

  // ==================== TYPE VERSEMENT ====================
  String translateTypeVersement(String frenchValue) {
    switch (frenchValue) {
      case 'Client'       : return l10n.client;
      case 'Fournisseur'  : return l10n.fournisseur;
      default: return frenchValue;
    }
  }

  String typeVersementToFrench(String translatedValue) {
    if (translatedValue == l10n.client) return 'Client';
    if (translatedValue == l10n.fournisseur) return 'Fournisseur';
    return translatedValue;
  }

  List<String> get typeVersementDisplayList => [
    l10n.client,
    l10n.fournisseur,
  ];

  // ==================== TYPE VERSEMENT DETAIL (Avancement, etc.) ====================
  String translateTypeVersementDetail(String frenchValue) {
    switch (frenchValue) {
      case 'Avancement'             : return l10n.avancement;
      case 'Complément de facture'  : return l10n.complementFacture;
      case 'Dette'                  : return l10n.dette;
      case 'Paiement'               : return l10n.paiement;
      case 'Remboursement'          : return l10n.remboursement;
      case 'Acompte'                : return l10n.acompte;
      case 'Remise'                 : return l10n.remiseVersement;
      default                       : return frenchValue;
    }
  }

  String typeVersementDetailToFrench(String translatedValue) {
    if (translatedValue == l10n.avancement)         return 'Avancement';
    if (translatedValue == l10n.complementFacture)  return 'Complément de facture';
    if (translatedValue == l10n.dette)              return 'Dette';
    if (translatedValue == l10n.paiement)           return 'Paiement';
    if (translatedValue == l10n.remboursement)      return 'Remboursement';
    if (translatedValue == l10n.acompte)            return 'Acompte';
    if (translatedValue == l10n.remiseVersement)    return 'Remise';
    return translatedValue;
  }

  List<String> get typeVersementDetailDisplayList => [
    l10n.avancement,
    l10n.complementFacture,
    l10n.dette,
    l10n.paiement,
    l10n.remboursement,
    l10n.acompte,
    l10n.remiseVersement,
  ];

  // ==================== ACTIVITES FOURNISSEUR ====================
  String translateActiviteFournisseur(String frenchValue) {
    switch (frenchValue) {
      case 'Cosmétique'                             : return l10n.cosmetique;
      case 'Alimentation'                           : return l10n.alimentation;
      case 'Quincaillerie'                          : return l10n.quincaillerie;
      case 'Électroménager'                         : return l10n.electromenager;
      case 'Hygiène & Nettoyage'                    : return l10n.hygieneNettoyage;
      case 'Textile & Habillement'                  : return l10n.textileHabillement;
      case 'Matériaux de construction'              : return l10n.materiauxConstruction;
      case 'Papeterie & Fournitures'                : return l10n.papeterieFournitures;
      case 'Pièces automobiles'                     : return l10n.piecesAutomobiles;
      case 'Informatique & Accessoires'             : return l10n.informatiqueAccessoires;
      case 'Téléphonie'                             : return l10n.telephonie;
      case 'Meubles & Décoration'                   : return l10n.meublesDecoration;
      case 'Produits agricoles'                     : return l10n.produitsAgricoles;
      case 'Produits ménagers'                      : return l10n.produitsMenagers;
      case 'Parfumerie'                             : return l10n.parfumerie;
      case 'Boulangerie / Pâtisserie (fournitures)' : return l10n.boulangeriePatisserie;
      case 'Bazar'                                  : return l10n.bazar;
      case 'Jouets'                                 : return l10n.jouets;
      case 'Produits médicaux non pharmaceutiques'  : return l10n.produitsMedicaux;
      case 'Autre'                                  : return l10n.autre;
      default                                       : return frenchValue;
    }
  }

  String activiteFournisseurToFrench(String translatedValue) {
    if (translatedValue == l10n.cosmetique)               return 'Cosmétique';
    if (translatedValue == l10n.alimentation)             return 'Alimentation';
    if (translatedValue == l10n.quincaillerie)            return 'Quincaillerie';
    if (translatedValue == l10n.electromenager)           return 'Électroménager';
    if (translatedValue == l10n.hygieneNettoyage)         return 'Hygiène & Nettoyage';
    if (translatedValue == l10n.textileHabillement)       return 'Textile & Habillement';
    if (translatedValue == l10n.materiauxConstruction)    return 'Matériaux de construction';
    if (translatedValue == l10n.papeterieFournitures)     return 'Papeterie & Fournitures';
    if (translatedValue == l10n.piecesAutomobiles)        return 'Pièces automobiles';
    if (translatedValue == l10n.informatiqueAccessoires)  return 'Informatique & Accessoires';
    if (translatedValue == l10n.telephonie)               return 'Téléphonie';
    if (translatedValue == l10n.meublesDecoration)        return 'Meubles & Décoration';
    if (translatedValue == l10n.produitsAgricoles)        return 'Produits agricoles';
    if (translatedValue == l10n.produitsMenagers)         return 'Produits ménagers';
    if (translatedValue == l10n.parfumerie)               return 'Parfumerie';
    if (translatedValue == l10n.boulangeriePatisserie)    return 'Boulangerie / Pâtisserie (fournitures)';
    if (translatedValue == l10n.bazar)                    return 'Bazar';
    if (translatedValue == l10n.jouets)                   return 'Jouets';
    if (translatedValue == l10n.produitsMedicaux)         return 'Produits médicaux non pharmaceutiques';
    if (translatedValue == l10n.autre)                    return 'Autre';
    return translatedValue;
  }

  List<String> get activiteFournisseurDisplayList => [
    l10n.cosmetique,
    l10n.alimentation,
    l10n.quincaillerie,
    l10n.electromenager,
    l10n.hygieneNettoyage,
    l10n.textileHabillement,
    l10n.materiauxConstruction,
    l10n.papeterieFournitures,
    l10n.piecesAutomobiles,
    l10n.informatiqueAccessoires,
    l10n.telephonie,
    l10n.meublesDecoration,
    l10n.produitsAgricoles,
    l10n.produitsMenagers,
    l10n.parfumerie,
    l10n.boulangeriePatisserie,
    l10n.bazar,
    l10n.jouets,
    l10n.produitsMedicaux,
    l10n.autre,
  ];

  // ==================== ACTIVITES CLIENT ====================
  String translateActiviteClient(String frenchValue) {
    switch (frenchValue) {
      case 'Particulier': return l10n.particulier;
      case 'Épicerie': return l10n.epicerie;
      case 'Superette': return l10n.superette;
      case 'Salon de coiffure': return l10n.salonCoiffure;
      case 'Institut de beauté': return l10n.institutBeaute;
      case 'Boutique de vêtements': return l10n.boutiqueVetements;
      case 'Boulangerie': return l10n.boulangerie;
      case 'Cafétéria / Fast-food': return l10n.cafeteriaFastFood;
      case 'Restaurant': return l10n.restaurant;
      case 'Café': return l10n.cafe;
      case 'Quincaillerie': return l10n.quincaillerie;
      case 'Magasin électroménager': return l10n.magasinElectromenager;
      case 'Parfumerie': return l10n.parfumerie;
      case 'Pharmacie': return l10n.pharmacie;
      case 'Papeterie': return l10n.papeterieFournitures;
      case 'Magasin de jouets': return l10n.magasinJouets;
      case 'Boutique téléphonie': return l10n.boutiqueTelephonie;
      case 'Garage / Pièces auto': return l10n.garagePiecesAuto;
      case 'Magasin informatique': return l10n.magasinInformatique;
      case 'Autre': return l10n.autre;
      default: return frenchValue;
    }
  }

  String activiteClientToFrench(String translatedValue) {
    if (translatedValue == l10n.particulier) return 'Particulier';
    if (translatedValue == l10n.epicerie) return 'Épicerie';
    if (translatedValue == l10n.superette) return 'Superette';
    if (translatedValue == l10n.salonCoiffure) return 'Salon de coiffure';
    if (translatedValue == l10n.institutBeaute) return 'Institut de beauté';
    if (translatedValue == l10n.boutiqueVetements) return 'Boutique de vêtements';
    if (translatedValue == l10n.boulangerie) return 'Boulangerie';
    if (translatedValue == l10n.cafeteriaFastFood) return 'Cafétéria / Fast-food';
    if (translatedValue == l10n.restaurant) return 'Restaurant';
    if (translatedValue == l10n.cafe) return 'Café';
    if (translatedValue == l10n.quincaillerie) return 'Quincaillerie';
    if (translatedValue == l10n.magasinElectromenager) return 'Magasin électroménager';
    if (translatedValue == l10n.parfumerie) return 'Parfumerie';
    if (translatedValue == l10n.pharmacie) return 'Pharmacie';
    if (translatedValue == l10n.papeterieFournitures) return 'Papeterie';
    if (translatedValue == l10n.magasinJouets) return 'Magasin de jouets';
    if (translatedValue == l10n.boutiqueTelephonie) return 'Boutique téléphonie';
    if (translatedValue == l10n.garagePiecesAuto) return 'Garage / Pièces auto';
    if (translatedValue == l10n.magasinInformatique) return 'Magasin informatique';
    if (translatedValue == l10n.autre) return 'Autre';
    return translatedValue;
  }

  List<String> get activiteClientDisplayList => [
    l10n.particulier,
    l10n.epicerie,
    l10n.superette,
    l10n.salonCoiffure,
    l10n.institutBeaute,
    l10n.boutiqueVetements,
    l10n.boulangerie,
    l10n.cafeteriaFastFood,
    l10n.restaurant,
    l10n.cafe,
    l10n.quincaillerie,
    l10n.magasinElectromenager,
    l10n.parfumerie,
    l10n.pharmacie,
    l10n.papeterieFournitures,
    l10n.magasinJouets,
    l10n.boutiqueTelephonie,
    l10n.garagePiecesAuto,
    l10n.magasinInformatique,
    l10n.autre,
  ];

  // ==================== ROLE ====================
  String translateRole(String frenchValue) {
    switch (frenchValue) {
      case 'Admin': return l10n.admin;
      case 'Caissier': return l10n.caissier;
      case 'Magasinier': return l10n.magasinier;
      default: return frenchValue;
    }
  }

  String roleToFrench(String translatedValue) {
    if (translatedValue == l10n.admin) return 'Admin';
    if (translatedValue == l10n.caissier) return 'Caissier';
    if (translatedValue == l10n.magasinier) return 'Magasinier';
    return translatedValue;
  }

  List<String> get roleDisplayList => [
    l10n.admin,
    l10n.caissier,
    l10n.magasinier,
  ];

  // ==================== TYPE HISTORIQUE ====================
  String translateTypeHisto(String frenchValue) {
    switch (frenchValue) {
      case 'insertion': return l10n.insertion;
      case 'modification': return l10n.modification;
      case 'suppression': return l10n.suppression;
      case 'login': return l10n.login;
      case 'logout': return l10n.logout;
      default: return frenchValue;
    }
  }

  String typeHistoToFrench(String translatedValue) {
    if (translatedValue == l10n.insertion) return 'insertion';
    if (translatedValue == l10n.modification) return 'modification';
    if (translatedValue == l10n.suppression) return 'suppression';
    if (translatedValue == l10n.login) return 'login';
    if (translatedValue == l10n.logout) return 'logout';
    return translatedValue;
  }

  List<String> get typeHistoDisplayList => [
    l10n.insertion,
    l10n.modification,
    l10n.suppression,
    l10n.login,
    l10n.logout,
  ];

  // ==================== TYPE ACTIVITY SMART SCAN ====================
  String translateTypeActivitySmartScan(String frenchValue) {
    switch (frenchValue) {
      case 'achat': return l10n.achat;
      case 'vente': return l10n.vente;
      default: return frenchValue;
    }
  }

  String typeActivitySmartScanToFrench(String translatedValue) {
    if (translatedValue == l10n.achat) return 'achat';
    if (translatedValue == l10n.vente) return 'vente';
    return translatedValue;
  }

  List<String> get typeActivitySmartScanDisplayList => [
    l10n.achat,
    l10n.vente,
  ];
}

// -----------------------------
// ORIGINAL LISTS (French values - keep for database storage)
// -----------------------------
class ListsConst {
  // Packs protégés (non supprimables)
  static const List<NonSupprimablePack> nonSupprimablePacks = [
    NonSupprimablePack(nom: "Caisse", code: "CIS0000"),
    NonSupprimablePack(nom: "Sous Categorie", code: "SC0000"),
    NonSupprimablePack(nom: "Categorie", code: "CATE0000"),
    NonSupprimablePack(nom: "Magasin", code: "MAG0000"),
    NonSupprimablePack(nom: "Client", code: "CLN0000"),
    NonSupprimablePack(nom: "Fournisseur", code: "FOR0000"),
  ];

  // Liste pour type de calcul
  static const List<String> operationHistoriqueDansList = [
    "BesionList",
    "Categorie",
    "Caisse",
    "Dash",
    "Entrée",
    "Fournisseur",
    "Magasin",
    "Pack",
    "Pannier",
    "Pannier",
    "Paramétre",
    "Paramétre produit",
    "Paramétre caisse",
    "Produit",
    "Remise",
    "Retour",
    "Role",
    "S_Categorie",
    "Sortie",
    "Transfert",
    "Utilisateur",
    "Versement",
    "Zakat",
  ];

  static const List<String> typeactivitySmartScan = [
    "achat",
    "vente"
  ];

  static const List<String> colis = [
    'Toujours demandé',
    'Petit colis',
    'Grand colis',
  ];

  static const List<String> typeHisto = [
    "insertion",
    "modification",
    "suppression",
    "login",
    "logout",
  ];

  static const List<String> etatList = [
    "Actif",
    "Inactif",
  ];

  static const List<String> etatVersementList = [
    "Validé",
    "Annulé",
  ];

  // Statut Zakat
  static const List<String> statutZakatList = [
    "Non payé",
    "Payée",
  ];

  static const List<String> typeRemiseList = [
    "Par Montant",
    "Par Produit",
  ];

  static const List<String> typeBesionproduit = [
    "En Attente",
    "Commande",
    "Disponible"
  ];

  static const List<String> typeSortie = [
    "Expiration",
    "Don",
    "Autre",
  ];

  static const List<String> typeCalculList = [
    "Montant",
    "Pourcentage",
  ];

  static const List<String> typePannier = [
    "BL",
    "BL_SC",
    "Ticket",
  ];

  static const List<String> typeCaisse = [
    "Physique",
    "Compte",
  ];

  // Exemple : liste unités de mesure
  static const List<String> uniteMesureList = [
    "Pièce",
    "Kg",
    "Litre",
    "Mètre",
  ];

  // Exemple : modes de paiement
  static const List<String> typeVersementList = [
    "Avancement",
    "Complément de facture",
    "Dette",
    "Paiement",
    "Remboursement",
    "Acompte",
    "Remise",
  ];

  static const List<String> modePaiementList = [
    "Espèces",
    "Carte",
    "Chèque",
    "Virement",
  ];

  static const List<String> typeFournisseur = [
    "Usine",
    "Société",
    "Importateur",
    "Grossiste",
    "Semi-Grossiste",
    "Détaillant",
    "Autre",
  ];

  static const List<String> typeClient = [
    "Usine",
    "Société",
    "Grossiste",
    "Semi-Grossiste",
    "Détaillant",
    "Consommateur",
    "Autre",
  ];

  static const List<String> typeMouvement = [
    "Vente",
    "Achat",
    "Retour",
    "Déstockage",
  ];

  static const List<String> typeRetour = [
    "Client",
    "Fournisseur",
  ];

  static const List<String> typeVersement = [
    "Client",
    "Fournisseur",
  ];

  static const List<String> activitesFournisseur = [
    "Cosmétique",
    "Alimentation",
    "Quincaillerie",
    "Électroménager",
    "Hygiène & Nettoyage",
    "Textile & Habillement",
    "Matériaux de construction",
    "Papeterie & Fournitures",
    "Pièces automobiles",
    "Informatique & Accessoires",
    "Téléphonie",
    "Meubles & Décoration",
    "Produits agricoles",
    "Produits ménagers",
    "Parfumerie",
    "Boulangerie / Pâtisserie (fournitures)",
    "Bazar",
    "Jouets",
    "Produits médicaux non pharmaceutiques",
    "Autre",
  ];

  static const List<String> activitesClient = [
    "Particulier",
    "Épicerie",
    "Superette",
    "Salon de coiffure",
    "Institut de beauté",
    "Boutique de vêtements",
    "Boulangerie",
    "Cafétéria / Fast-food",
    "Restaurant",
    "Café",
    "Quincaillerie",
    "Magasin électroménager",
    "Parfumerie",
    "Pharmacie",
    "Papeterie",
    "Magasin de jouets",
    "Boutique téléphonie",
    "Garage / Pièces auto",
    "Magasin informatique",
    "Autre",
  ];

  static const List<String> role = [
    "Admin",
    "Caissier",
    "Magasinier",
  ];
}