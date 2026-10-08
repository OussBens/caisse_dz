import 'package:collection/collection.dart';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
import 'package:caisse_dz/Services/CaisseSession.dart' hide ApiResponse;
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/Services/Client.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Historique.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Mouvement.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart' hide ApiResponse;
import 'package:caisse_dz/Services/Produits.dart' hide ApiResponse;
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:caisse_dz/data/models/caisse.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/core/tableau/caisse/tableau_encaisserEnreget.dart';
import 'package:caisse_dz/core/widget/code_generateur.dart';

import '../../../Services/MagasinDetail.dart';
import '../../../Services/Verssement.dart' hide ApiResponse;
import '../../../data/models/verssement.dart';
import '../../utilis/api_response.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

// ✅ Fonction helper pour obtenir le prochain ID (simplifiée)
Future<int> _getNextId(String tableName) async {
  final db = await DbCreator.openDb();
  final result = await db.rawQuery('SELECT MAX(id) as maxId FROM $tableName');
  final maxId = result.first['maxId'] as int? ?? 0;
  return maxId + 1;
}

// ✅ Fonction _SavePannier - Version SIMPLE sans transaction (identique à EncaissementTicketDialog)
Future<ApiResponse<int>> _SavePannier({
  required Pannier pannier,
  required CaisseState caisse,
  required String userName,
  required String userCode,
  required Client client,
  required double montant,
  required String magasinCode,
  required String caisseCode,
}) async {
  print("🚀 _SavePannier: DEBUT");

  final db = await DbCreator.openDb();
  final serviceh = HistoriqueServices(db);
  final servicem = MouvementsServices(db);
  final services = PannierServices(db);
  final serviceP = ProduitServices(db);
  final servicep = PPServices(db);
  final serviceC = ClientServices(db);
  final versementService = VerssementServices(db);
  final pmdService = ProduitMagasinDetailServices(db);
  final caisseSessionService = CaisseSessionServices(db);

  final Produitse = await ProduitServices.getAllProduits();
  print("📦 Produits récupérés: ${Produitse.length}");

  // 1️⃣ Déstocker du magasin
  print("🏪 Déstockage...");
  for (var produit in caisse.produits) {
    final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
    print("   - ${produit.nom}: qte=$quantiteReelle");

    final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
      produit.code,
      magasinCode,
    );

    // Second stock parallèle "Nombre" (Paramètres > Nombre et Quantité) —
    // quantite n'est plus stockée ici (calculée depuis le journal des
    // mouvements), seul nombre reste un compteur réel à décrémenter.
    if (magasinDetail != null && produit.nombre != null) {
      final nombreADestock = produit.nombre! <= magasinDetail.nombre
          ? produit.nombre!
          : magasinDetail.nombre;
      if (nombreADestock > 0) {
        await pmdService.decrementNombre(magasinDetail.id, nombreADestock);
      }
    }
  }

  // 2️⃣ Ajouter le pannier
  print("💾 Sauvegarde du pannier...");
  final response = await services.addPannier(pannier);
  if (!response.success) {
    print("❌ Erreur addPannier: ${response.message}");
    return response;
  }
  print("✅ Pannier ajouté, id=${response.data}");

  // 3️⃣ Historique du pannier
  final idh = await _getNextId('Historique');
  Historique histo = Historique(
    id: idh,
    code: CodeGenerator.generateCodeWithTimestamp(
      prefix: CodePrefix.historique,
      id: idh,
    ),
    type: "panniers",
    desc: "L'utilisateur $userName a Ajoutee le Pannier ${pannier.code}",
    oper: ListsConst.typeHisto[0],
    dateCree: DateTime.now(),
    creeParCode: userCode,
  );
  await serviceh.addHistorique(histo);
  print("✅ Historique pannier ajouté");

  // 4️⃣ Produits du pannier
  for (var produit in caisse.produits) {
    final idpp = await _getNextId('pannierProduit');
    final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);

    // Chercher le produit original
    Produit? produitOriginal;
    try {
      produitOriginal = Produitse.firstWhere((p) => p.nom == produit.nom);
    } catch (e) {
      print("⚠️ Produit non trouvé: ${produit.nom}");
    }

    final prixAchat = produit.prixachat ?? 0.0;
    final totalAchat = prixAchat * quantiteReelle;

    PannierProduit prod = PannierProduit(
      id: idpp,
      prix: produit.prix,
      etat: true,
      total: produit.prix * produit.qte,
      creeLe: DateTime.now(),
      quantite: quantiteReelle,
      nombre: produit.nombre,
      codeProduit: produit.code,
      codePannier: pannier.code,
      creeParCode: userCode,
      prixAchat: prixAchat,
      totalAchat: totalAchat,
    );

    await servicep.addPP(prod);
    print("✅ PannierProduit ajouté: ${produit.nom}");

    // Historique produit
    final idh2 = await _getNextId('Historique');
    Historique histo2 = Historique(
      id: idh2,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh2,
      ),
      type: "pannierProduit",
      desc: "L'utilisateur $userName a Ajoutee le Produit ${produit.nom} au Pannier ${pannier.code}",
      oper: ListsConst.typeHisto[0],
      dateCree: DateTime.now(),
      creeParCode: userCode,
    );
    await serviceh.addHistorique(histo2);

    // Mouvement
    // Multi-magasin : la ligne est prise dans les magasins de l'utilisateur,
    // dans l'ordre (magasin 1, puis 2…) — un mouvement par magasin servi.
    final parts = await MouvementsServices.repartirSortie(
      prod.codeProduit,
      quantiteReelle,
      AuthState().magasins,
    );
    for (var p = 0; p < parts.length; p++) {
      final idm = await _getNextId('mouvements');
      Mouvement Mouv = Mouvement(
        id: idm,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.mouvement,
          id: idm,
          digitCount: 8,
        ),
        date: pannier.date,
        type: ListsConst.typeMouvement[0],
        etat: true,
        dateCree: DateTime.now(),
        quantite: parts[p].quantite,
        nombre: p == 0 ? produit.nombre : null,
        prixAchat: produitOriginal?.prixAchat ?? prixAchat,
        prixVente: prod.prix,
        codeProduit: prod.codeProduit,
        creeParCode: userCode,
        codeOperation: pannier.code,
        magasinCode: parts[p].magasinCode,
      );
      await servicem.addMouvement(Mouv);
    }
    print("✅ Mouvement ajouté: ${produit.nom}");

    // Mise à jour du produit
    if (produitOriginal != null) {
      if (!produitOriginal.service) {
        if (produit.nombre != null) {
          produitOriginal.nombre = produitOriginal.nombre - produit.nombre!;
        }
      }
      produitOriginal.dateModif = DateTime.now();
      produitOriginal.modifParCode = userCode;
      await serviceP.updateProduit(produitOriginal);
      print("✅ Produit mis à jour: ${produitOriginal.code}");

      // Historique mise à jour produit
      final idh3 = await _getNextId('Historique');
      Historique histo3 = Historique(
        id: idh3,
        code: CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idh3,
        ),
        type: "produits",
        desc: "La Quantite de Produit ${produitOriginal.nom} est mis a jour automatiquement Apres le Vente dans le Pannier ${pannier.code}",
        oper: ListsConst.typeHisto[0],
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await serviceh.addHistorique(histo3);
    }
  }

  // 5️⃣ Mise à jour du client
  print("👤 Mise à jour du client: ${client.nom}");
  client.dernierAchat = DateTime.now();
  client.modifParCode = userCode;
  await serviceC.updateClient(client);
  print("✅ Client mis à jour");

  // 6️⃣ Versement
  if (montant > 0) {
    print("💰 Ajout versement: $montant");
    final nextVerssementId = await _getNextId('verssements');
    Verssement versement = Verssement(
      id: nextVerssementId,
      code: CodeGenerator.generateCode(
        prefix: CodePrefix.verssement,
        id: nextVerssementId,
        digitCount: 6,
      ),
      date: DateTime.now(),
      typebeneficiare: "Client",
      beneficiareCode: client.code,
      montant: montant,
      etat: true,
      mode_paiement: pannier.modePaiement!,
      sense: 'Entrée',
      type: "Paiement",
      dateCree: DateTime.now(),
      creeParCode: userCode,
      caisse: pannier.caisse,
      codeOperation: pannier.code,
    );
    await versementService.addverssement(versement);
    print("✅ Versement ajouté");

    // 7️⃣ Mouvement de caisse (grand-livre) : encaissement de la vente,
    // journalisé dans la session ouverte de cette caisse.
    final sessionOuverte = await CaisseSessionServices.getSessionOuverte(caisseCode);
    if (sessionOuverte != null) {
      final nextMouvementId = await CaisseSessionServices.getNextMouvementId(db);
      final mouvementCaisse = CaisseMouvement(
        id: nextMouvementId,
        code: CodeGenerator.generateCode(
          prefix: CodePrefix.caisseMouvement,
          id: nextMouvementId,
          digitCount: 8,
        ),
        sessionCode: sessionOuverte.code,
        caisseCode: caisseCode,
        type: 'encaissement_vente',
        sens: 'Entrée',
        montant: montant,
        modePaiement: pannier.modePaiement,
        codeOperation: pannier.code,
        clientCode: client.code,
        date: DateTime.now(),
        etat: true,
        dateCree: DateTime.now(),
        creeParCode: userCode,
      );
      await caisseSessionService.ajouterMouvement(mouvementCaisse);
      print("✅ Mouvement de caisse ajouté");
    }
  }

  print("✅ _SavePannier: SUCCÈS");
  return ApiResponse(success: true, message: "Succès", data: pannier.id);
}

Future<void> EnregistrerTicketDialog({
  required Map<String, dynamic> clientInfo,
  required BuildContext context,
  required CaisseState caisse,
  required Client client,
  required int pannier,
  required String selectedMagasinCode,
  required VoidCallback onSuccess,
}) async {
  print("🎫 EnregistrerTicketDialog: DEBUT");

  final l10n = AppLocalizations.of(context)!;
  final TextEditingController payeController = TextEditingController();
  final TextEditingController resteController = TextEditingController(
    text: caisse.total.toStringAsFixed(2),
  );

  // Récupérer les caisses
  List<CaisseGestion> CaisseTest = await GCServices.getAllCaisses();

  // Vérifier que la caisse existe
  final matchingCaisse = CaisseTest.where((e) => e.nomCaisse == caisse.caisse);
  if (matchingCaisse.isEmpty) {
    print("❌ ERREUR: Caisse '${caisse.caisse}' non trouvée!");
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.caisse,
      message: l10n.caisseNotFound(caisse.caisse),
    );
    return;
  }

  // ✅ Session de caisse obligatoire : aucune vente ne peut être encaissée
  // tant que la caisse n'a pas été ouverte (voir CaisseSessionServices).
  final sessionOuverte = await CaisseSessionServices.getSessionOuverte(matchingCaisse.first.code);
  if (sessionOuverte == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.attention,
      kind: DialogKind.attention,
      titre_concerne: l10n.caisse,
      message: l10n.aucuneSessionOuverte(caisse.caisse),
    );
    return;
  }

  final auth = Provider.of<AuthState>(context, listen: false);

  if (!auth.isAuthenticated || auth.username == null || auth.userCode == null) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.authentication,
      kind: DialogKind.refuser,
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
    );
    return;
  }

  final String userName = auth.username!;
  final String userCode = auth.userCode!;

  bool paiementTotal = true;
  payeController.text = caisse.total.toStringAsFixed(2);
  resteController.text = "0.00";

  void updateReste() {
    final paye = double.tryParse(payeController.text) ?? 0;
    resteController.text = (caisse.total - paye).toStringAsFixed(2);
  }

  int nombreProduits = caisse.produits.length;
  int nombreArticles = caisse.produits.fold(0, (s, p) => s + p.qte.toInt());

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return BaseDialog(
            width: 1100,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/sidebar/pannier_icon.png',
              text: l10n.ticketRegistration,
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _info("${l10n.cartNumber}", pannier, l10n),
                      _info(l10n.client, caisse.client, l10n),

                      // ✅ TOTAL (avant remise)
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.totalBeforeDiscount,
                          "${NumberFormatUtil.formatMontant(caisse.totalAchat, decimales: 2)} ${l10n.currency}",
                          l10n,
                          valueColor: Appstyle.TgrisF,
                        ),

                      // ✅ Remise
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.discount,
                          "${NumberFormatUtil.formatMontant(caisse.remise, decimales: 2)} ${l10n.currency}",
                          l10n,
                          valueColor: Colors.green,
                        ),

                      // ✅ TOTAL FINAL
                      _info(
                        l10n.totalFinal,
                        "${NumberFormatUtil.formatMontant((caisse.total-caisse.remise), decimales: 2)} ${l10n.currency}",
                        l10n,
                        valueColor: caisse.remiseActive && caisse.remise > 0
                            ? Colors.green
                            : Appstyle.violet,
                      ),

                      _info(l10n.paid, payeController.text.isEmpty ? "0" : payeController.text, l10n),
                      _info(l10n.remaining, resteController.text, l10n),
                      _info(l10n.products, nombreProduits, l10n),
                      _info(l10n.articles, nombreArticles, l10n),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TableauEncaissementEnreg(
                    produits: caisse.produits,
                    height: 500,
                    remiseValue: caisse.remise,           // ✅ Valeur de la remise
                    remiseActive: caisse.remiseActive,    // ✅ Si la remise est active
                    remiseNom: caisse.remisenom,          // ✅ Nom de la remise
                  ),
                ],
              ),
            ),
            footer: Row(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: paiementTotal,
                          onChanged: (value) {
                            setState(() {
                              paiementTotal = value ?? true;
                              if (paiementTotal) {
                                payeController.text = caisse.total.toStringAsFixed(2);
                                resteController.text = "0.00";
                              } else {
                                payeController.text = "";
                                resteController.text = caisse.total.toStringAsFixed(2);
                              }
                            });
                          },
                          activeColor: Appstyle.violet,
                        ),
                        const SizedBox(width: 4),
                        Text(l10n.fullPayment, style: Appstyle.textSB),
                      ],
                    ),
                    const SizedBox(width: 15),
                    SizedBox(
                      width: 150,
                      child: TextField(
                        controller: payeController,
                        enabled: !paiementTotal,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: l10n.paid,
                          labelStyle: TextStyle(color: Appstyle.Tnoir),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Appstyle.indigo),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onChanged: (value) => setState(updateReste),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                MainButton(
                  text: l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () {
                    print("❌ Annulation");
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.save,
                  color: Appstyle.crevete,
                  icon: Icons.save,
                  onPressed: () async {
                    print("💾 Enregistrement du ticket...");

                    // ✅ Vérifier que le stock (actuel, potentiellement changé
                    // depuis l'ajout au panier) permet toujours cette vente.
                    final catalogueActuel = await ProduitServices.getAllProduits();
                    final echecStock = await premierProduitInsuffisantPourVente(
                      caisse.produits,
                      catalogueActuel,
                      magasinCode: selectedMagasinCode,
                    );
                    if (echecStock != null) {
                      final (produitInsuffisant, quantiteNecessaire, quantiteDisponible) = echecStock;
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.cart,
                        message: l10n.stockInsuffisantPourProduit(
                          produitInsuffisant.code,
                          quantiteDisponible.toInt().toString(),
                          quantiteNecessaire.toInt().toString(),
                        ),
                      );
                      return;
                    }

                    // ✅ Nombre obligatoire pour les produits suivant le
                    // second stock "nombre" (nombreActif).
                    for (final ligne in caisse.produits) {
                      final nombreActifLigne = catalogueActuel
                              .firstWhereOrNull((p) => p.code == ligne.code)
                              ?.nombreActif ??
                          false;
                      if (nombreActifLigne && (ligne.nombre == null || ligne.nombre! <= 0)) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: ligne.nom,
                          message: l10n.numberMustBeGreaterThanZero,
                        );
                        return;
                      }
                    }

                    // Afficher un indicateur de chargement
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (loadingContext) => const Center(
                        child: CircularProgressIndicator(),
                      ),
                    );

                    try {
                      final nextPannierId = await _getNextId('panniers');
                      final codePannier = CodeGenerator.generateCode(
                        prefix: CodePrefix.pannier,
                        id: nextPannierId,
                        digitCount: 7,
                      );

                      final Ccode = matchingCaisse.first.code;

                      Pannier pannierObj = Pannier(
                        id: nextPannierId,
                        code: codePannier,
                        etat: true,
                        date: caisse.date,
                        client_code: client.code,
                        montant: caisse.total,
                        dateCree: DateTime.now(),
                        caisse_code: Ccode,
                        typepannier: ListsConst.typePannier[2],
                        modePaiement: caisse.modePaiement,
                        caissier_code: userCode,
                        nombreArticle: caisse.nombreArticles,
                        quantiteProduit: caisse.nombreProduits,
                        caisse: caisse.caisse,
                        montantAchat: caisse.totalAchat,
                        marge: caisse.marge,
                      );

                      final montant = double.parse(payeController.text);
                      final response = await _SavePannier(
                        pannier: pannierObj,
                        caisse: caisse,
                        userCode: userCode,
                        userName: userName,
                        montant: montant,
                        client: client,
                        magasinCode: selectedMagasinCode,
                        caisseCode: Ccode,
                      );

                      // Fermer l'indicateur de chargement
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      if (!response.success) {
                        await InformationDialog(
                          context: context,
                          titre_type_message: l10n.error,
                          kind: DialogKind.refuser,
                          titre_concerne: l10n.ticket,
                          message: response.message,
                        );
                        return;
                      }

                      // ✅ Afficher le message de succès
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.success,
                        titre_concerne: l10n.ticket,
                        message: l10n.ticketSavedSuccess,
                      );

                      // Fermer le dialogue principal
                      if (context.mounted) {
                        Navigator.pop(context, true);
                      }
                      onSuccess();
                    } catch (e) {
                      // Fermer l'indicateur de chargement
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }

                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.error,
                        kind: DialogKind.refuser,
                        titre_concerne: l10n.ticket,
                        message: "${l10n.errorOccurred}: ${e.toString()}",
                      );
                    }
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

Widget _info(String label, dynamic value, AppLocalizations l10n, {Color? valueColor}) {
  return SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir)),
        const SizedBox(height: 4),
        Text(
          value?.toString() ?? "-",
          style: Appstyle.textXSB.copyWith(
            color: valueColor ?? Appstyle.violet,
          ),
        ),
      ],
    ),
  );
}