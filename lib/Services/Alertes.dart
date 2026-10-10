import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Paramters.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/data/models/caisse_session.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:flutter/foundation.dart';

/// Points d'attention affichés par le dialog « Alertes » (cloche de
/// l'en-tête, ouvert aussi automatiquement à la connexion).
class AlertesResume {
  /// Produits actifs dont le stock (journal des mouvements, tous magasins)
  /// est inférieur ou égal au seuil minimum (Paramètres) — même règle que
  /// l'onglet « Produits en rupture » du module Besoin.
  final List<({Produit produit, double quantite})> produitsRupture;

  /// Produits actifs dont la date d'expiration est passée (même règle que
  /// l'onglet « Produits expirés » du module Besoin).
  final List<Produit> produitsExpires;

  /// Produits actifs qui expirent dans les [AlertesServices.joursAvantExpiration]
  /// prochains jours (aujourd'hui inclus).
  final List<Produit> produitsBientotExpires;

  final List<({Client client, double credit})> clientsCredit;
  final List<({Fournisseur fournisseur, double credit})> fournisseursCredit;

  /// Sessions de caisse encore ouvertes alors qu'elles ont démarré un jour
  /// précédent (clôture oubliée), avec le nom de leur caisse.
  final List<({CaisseSession session, String nomCaisse})> sessionsNonCloturees;

  const AlertesResume({
    this.produitsRupture = const [],
    this.produitsExpires = const [],
    this.produitsBientotExpires = const [],
    this.clientsCredit = const [],
    this.fournisseursCredit = const [],
    this.sessionsNonCloturees = const [],
  });

  /// Nombre total d'alertes (badge de la cloche).
  int get total =>
      produitsRupture.length +
      produitsExpires.length +
      produitsBientotExpires.length +
      clientsCredit.length +
      fournisseursCredit.length +
      sessionsNonCloturees.length;
}

class AlertesServices {
  static const int joursAvantExpiration = 30;
  static const int nombreTopCredit = 3;

  /// Nombre d'alertes du dernier calcul — badge de la cloche de l'en-tête,
  /// mis à jour à chaque ouverture du dialog (dont l'ouverture automatique
  /// à la connexion), sans recalcul à chaque changement de module.
  static final ValueNotifier<int> nombreAlertes = ValueNotifier<int>(0);

  /// Calcule les alertes. Chaque bloc n'est chargé que si l'utilisateur a
  /// accès au module correspondant (voir AlerteDialog). Les ruptures portent
  /// sur le stock des magasins consultables ([magasinsConsultation], `null`
  /// = tous, voir AuthState), comme le Dashboard.
  static Future<AlertesResume> getAlertes({
    List<String>? magasinsConsultation,
    bool produits = true,
    bool clients = true,
    bool fournisseurs = true,
    bool sessions = true,
  }) async {
    var rupture = <({Produit produit, double quantite})>[];
    var expires = <Produit>[];
    var bientotExpires = <Produit>[];

    if (produits) {
      final liste = (await ProduitServices.getAllProduits()).where((p) => p.etat).toList();
      final quantites = await MouvementsServices.quantitesConsultables(magasinsConsultation);
      final seuil = (await ParamServices.getParam()).Minimum;

      rupture = [
        for (final p in liste)
          if ((quantites[p.code] ?? 0) <= seuil) (produit: p, quantite: quantites[p.code] ?? 0),
      ]..sort((a, b) => a.quantite.compareTo(b.quantite));

      final now = DateTime.now();
      final aujourdhui = DateTime(now.year, now.month, now.day);
      final limite = aujourdhui.add(const Duration(days: joursAvantExpiration + 1));
      expires = liste.where((p) => p.dateEmpreint != null && p.dateEmpreint!.isBefore(aujourdhui)).toList()
        ..sort((a, b) => a.dateEmpreint!.compareTo(b.dateEmpreint!));
      bientotExpires = liste
          .where((p) => p.dateEmpreint != null && !p.dateEmpreint!.isBefore(aujourdhui) && p.dateEmpreint!.isBefore(limite))
          .toList()
        ..sort((a, b) => a.dateEmpreint!.compareTo(b.dateEmpreint!));
    }

    var sessionsOuvertes = <({CaisseSession session, String nomCaisse})>[];
    if (sessions) {
      final now = DateTime.now();
      final aujourdhui = DateTime(now.year, now.month, now.day);
      final caisses = {for (final c in await GCServices.getAllCaisses()) c.code: c.nomCaisse};
      sessionsOuvertes = [
        for (final s in await CaisseSessionServices.getAllSessions())
          if (s.etat && s.statut == CaisseSession.statutOuverte && s.dateOuverture.isBefore(aujourdhui))
            (session: s, nomCaisse: caisses[s.caisseCode] ?? s.caisseCode),
      ];
    }

    return AlertesResume(
      produitsRupture: rupture,
      produitsExpires: expires,
      produitsBientotExpires: bientotExpires,
      clientsCredit: clients ? await ClientServices.getClientsParCredit(limite: nombreTopCredit) : const [],
      fournisseursCredit:
          fournisseurs ? await FournisseurServices.getFournisseursParCredit(limite: nombreTopCredit) : const [],
      sessionsNonCloturees: sessionsOuvertes,
    );
  }
}
