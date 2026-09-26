import 'package:collection/collection.dart';

import '../DBCreate.dart';
import '../core/tableau/caisse/tableau_caisse.dart';
import '../data/models/caisse.dart';
import '../data/models/client.dart';
import '../data/models/pannier.dart';
import 'Client.dart';
import 'PannierProduit.dart';
import 'Produits.dart';

/// Reconstruit, à partir d'un [Pannier] déjà enregistré, les objets
/// [CaisseState]/[Client] attendus par les générateurs de reçu/facture
/// (ReceiptLatin/ReceiptArabic, PDFGeneratorLatin/PDFGeneratorArabic),
/// pour permettre la réimpression d'un ticket ou d'un BL depuis
/// l'historique des paniers sans revivre tout le flux d'encaissement.
class PannierReprintService {
  static Future<CaisseState> buildCaisseState(Pannier pannier) async {
    final db = await DbCreator.openDb();
    final ppService = PPServices(db);
    final produitsPannier = await ppService.getPPByCodePannier(pannier.code);
    final catalogue = await ProduitServices.getAllProduits();

    final produits = produitsPannier.map((pp) {
      final nom = catalogue.firstWhereOrNull((p) => p.code == pp.codeProduit)?.nom ?? pp.codeProduit;
      return ProduitPanier(
        nom: nom,
        code: pp.codeProduit,
        colis: '',
        prix: pp.prix,
        prixachat: pp.prixAchat,
        qte: pp.quantite,
      );
    }).toList();

    return CaisseState(
      nom: pannier.caisse,
      caisse: pannier.caisse,
      client: pannier.client_code ?? "Comptoire",
      modePaiement: pannier.modePaiement ?? "Espèces",
      produits: produits,
      total: pannier.montant,
      totalAchat: pannier.montantAchat,
      marge: pannier.marge,
      date: pannier.date,
    );
  }

  static Future<Client> resolveClient(String? clientCode) async {
    if (clientCode != null && clientCode.isNotEmpty) {
      final clients = await ClientServices.getAllClients();
      final client = clients.firstWhereOrNull((c) => c.code == clientCode);
      if (client != null) return client;
    }
    return Client(
      id: 0,
      nom: "Comptoire",
      code: "",
      telephone: "",
      adresse: "",
      type: "",
      etat: true,
      dateCree: DateTime.now(),
      wilaya: "",
      creeParCode: "SYSTEM",
    );
  }
}
