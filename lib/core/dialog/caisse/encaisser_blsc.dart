import 'dart:typed_data';
import 'package:caisse_dz/core/dialog/dialog_kind.dart';
import 'package:collection/collection.dart';
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
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/tableau/caisse/tableau_encaisserBLSC.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/caisse.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../Services/MagasinDetail.dart';
import '../../../Services/PDFPreviewDialog.dart';
import '../../../Services/Verssement.dart' hide ApiResponse;
import '../../../Services/pdf_generator_ar.dart';
import '../../../Services/pdf_generator_latin.dart';
import '../../../Services/EntrepriseParam.dart';
import '../../../Services/LogoService.dart';
import '../../../data/models/verssement.dart';
import '../../locale/locale_provider.dart';
import '../../utilis/api_response.dart';
import '../../widget/code_generateur.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<int> _GetNextpannierId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await PannierServices.getNextPannierId(txn);
  });
  return id;
}

Future<int> _GetNextPPId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await PPServices.getNextPPId(txn);
  });
  return id;
}

Future<int> _GetNextHistoriqueId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await HistoriqueServices.getNextHistoriqueId(txn);
  });
  return id;
}

Future<int> _GetNextMouvementId() async {
  final db = await DbCreator.openDb();
  int   id = 0;
  await db.transaction((txn) async {
    id = await MouvementsServices.getNextMouvementId(txn);
  });
  return id;
}
Future<ApiResponse<int>> _SavePannier ({
  required  Pannier     pannier,
  required  CaisseState caisse,
  required  String      userName,
  required  String      userCode,
  required  Client      client,
  required  double      montant,
  required String magasinCode,  // ✅ Ajouter ce paramètre
  required String caisseCode,
}) async
{
  final db        = await DbCreator.openDb();
  final serviceh  = HistoriqueServices(db);
  final servicem  = MouvementsServices(db);
  final services  = PannierServices(db);
  final serviceP  = ProduitServices(db);
  final servicep  = PPServices(db);
  final serviceC  = ClientServices(db);
  final versementService = VerssementServices(db);
  final pmdService = ProduitMagasinDetailServices(db); // ✅ Ajouter
  final caisseSessionService = CaisseSessionServices(db);
  final Produitse = await ProduitServices.getAllProduits();

  PannierProduit  prod;
  Produit Produite;
  int idp;
  int idh;
  int idm;

  // 1. Ajouter le pannier — tout le reste (déstockage, historique,
  // mouvements, versement) ne doit s'exécuter que si cette écriture a
  // réussi, sinon on se retrouve avec du stock décrémenté / de l'argent
  // enregistré pour une vente qui n'existe pas réellement en base.
  final response = await services.addPannier(pannier);
  if (!response.success) {
    return response;
  }

  // 2. Déstocker
  for (var produit in caisse.produits) {
    final quantiteReelle = produit.quantiteReelleEnPieces;
    final produitOriginal = Produitse.firstWhere((p) => p.nom == produit.nom);

    // Déstocker du magasin
    final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
      produit.code,
      magasinCode,
    );

    if (magasinDetail != null) {
      // Second stock parallèle "Nombre" (Paramètres > Nombre et Quantité) —
      // quantite n'est plus stockée ici (calculée depuis le journal des
      // mouvements), seul nombre reste un compteur réel à décrémenter.
      if (produit.nombre != null) {
        final nombreADestock = produit.nombre! <= magasinDetail.nombre
            ? produit.nombre!
            : magasinDetail.nombre;
        if (nombreADestock > 0) {
          await pmdService.decrementNombre(magasinDetail.id, nombreADestock);
        }
      }
    }
  }


  idh = await _GetNextHistoriqueId();
  Historique histo = Historique(
      id          : idh,
      code        : CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.historique,
        id: idh,
      ),
      type        : "panniers",
      desc        : "L'utilisateur $userName a Ajoutee le Pannier ${pannier.code}",
      oper        : ListsConst.typeHisto[0],
      dateCree    : DateTime.now(),
      creeParCode : userCode
  );
  await serviceh.addHistorique(histo);

  for(var produit in caisse.produits){
    idp = await _GetNextPPId();
    // Calculer la quantité réelle en pièces pour le mouvement de stock
    final quantiteReelle = produit.quantiteReelleEnPieces;

    prod = PannierProduit(
      id          : idp,
      prix        : produit.prix,
      etat        : true,
      total       : produit.montant,
      creeLe      : DateTime.now(),
      quantite    : quantiteReelle,
      nombre      : produit.nombre,
      codeProduit : produit.code,
      codePannier : pannier.code,
      creeParCode : userCode,
      prixAchat: produit.prixachat,
      totalAchat: produit.prixachat*quantiteReelle,
    );
    final respon = await servicep.addPP(prod);
    idh = await _GetNextHistoriqueId();
    Historique histo = Historique(
        id          : idh,
        code        : CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idh,
        ),
        type        : "pannierProduit",
        desc        : "L'utilisateur $userName a Ajoutee le Produit ${produit.nom} au Pannier ${pannier.code}",
        oper        : ListsConst.typeHisto[0],
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceh.addHistorique(histo);

    // Multi-magasin : la ligne est prise dans les magasins de l'utilisateur,
    // dans l'ordre (magasin 1, puis 2…) — un mouvement par magasin servi.
    final parts = await MouvementsServices.repartirSortie(
      prod.codeProduit,
      quantiteReelle,
      AuthState().magasins,
    );
    for (var p = 0; p < parts.length; p++) {
      idm = await _GetNextMouvementId();
      Mouvement Mouv = Mouvement(
        id            : idm,
        code          : CodeGenerator.generateCode(
          prefix: CodePrefix.mouvement,
          id: idm,
          digitCount: 8,
        ),
        date          : pannier.date,
        type          : ListsConst.typeMouvement[0],
        etat          : true,
        dateCree      : DateTime.now(),
        quantite      : parts[p].quantite,
        nombre        : p == 0 ? produit.nombre : null,
        prixAchat     : Produitse.where((e) => e.code == prod.codeProduit).first.prixAchat,
        prixVente     : prod.prix,
        codeProduit   : prod.codeProduit,
        creeParCode   : userCode,
        codeOperation : pannier.code,
        magasinCode   : parts[p].magasinCode,
      );

      await servicem.addMouvement(Mouv);
    }

    Produite = Produitse.where((e) => e.code == prod.codeProduit).first;
    if (!Produite.service) {
      if (produit.nombre != null) {
        Produite.nombre = Produite.nombre - produit.nombre!;
      }
    }
    Produite.dateModif  = DateTime.now();
    Produite.modifParCode   = userCode;
    await serviceP.updateProduit(Produite);

    idh = await _GetNextHistoriqueId();
    Historique histod = Historique(
        id          : idh,
        code        : CodeGenerator.generateCodeWithTimestamp(
          prefix: CodePrefix.historique,
          id: idh,
        ),
        type        : "produits",
        desc        : "La Quantite de Produit ${Produite.nom} est mis a jouree automatiquement Apres le Vente dans le Pannier ${pannier.code}",
        oper        : ListsConst.typeHisto[0],
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceh.addHistorique(histod);
  }

  client.dernierAchat = DateTime.now();
  client.modifParCode     = userCode;

  await serviceC.updateClient(client);


  if (montant > 0) {
    final nextVerssementId = await VerssementServices.getNextVerssementId(db);
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

    // Mouvement de caisse (grand-livre) : encaissement de la vente,
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
    }
  }

  return response;
}

Future<void> EncaissementBLSCDialog({
  required  BuildContext context,
  required  CaisseState caisse,
  required  Client      client,
  required Map<String, dynamic> clientInfo,
  required String selectedMagasinCode,
  required VoidCallback onSuccess,
}) async {
  final TextEditingController payeController = TextEditingController();
  final TextEditingController resteController = TextEditingController(
    text: caisse.total.toStringAsFixed(2),
  );
  List<CaisseGestion> CaisseTest = await GCServices.getAllCaisses();
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username;
  final userCode = auth.userCode;
  final l10n = AppLocalizations.of(context)!;

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

  // ✅ Caisse existante + session de caisse obligatoire : aucune vente ne
  // peut être encaissée tant que la caisse n'a pas été ouverte.
  final matchingCaisse = CaisseTest.where((e) => e.nomCaisse == caisse.caisse);
  if (matchingCaisse.isEmpty) {
    await InformationDialog(
      context: context,
      titre_type_message: l10n.error,
      kind: DialogKind.refuser,
      titre_concerne: l10n.caisse,
      message: l10n.caisseNotFound(caisse.caisse),
    );
    return;
  }
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

  /// 🔹 Etat de la checkbox Paiement total
  bool paiementTotal = true;

  /// 🔹 Si paiement total coché au départ
  payeController.text = caisse.total.toStringAsFixed(2);
  resteController.text = "0.00";

  /// 🔹 Mise à jour du reste
  void updateReste() {
    final paye = double.tryParse(payeController.text) ?? 0;
    resteController.text = (caisse.total - paye).toStringAsFixed(2);
  }

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          return BaseDialog(
            width: 1100,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/sidebar/pannier_icon.png',
              text: l10n.cashBLSC,
            ),

            /// ───────── CONTENT ─────────
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  /// 🔹 INFOS BL
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _info(l10n.blNumber, caisse.nom, l10n),
                      _info(l10n.client, caisse.client, l10n),

                      // ✅ Afficher le sous-total (avant remise) si une remise est active
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.subtotal,
                          "${NumberFormatUtil.formatMontant(caisse.totalAchat, decimales: 2)} ${l10n.currency}",
                          l10n,
                          valueColor: Appstyle.TgrisF,
                        ),

                      // ✅ Afficher la remise si active
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.discount,
                          "${NumberFormatUtil.formatMontant(caisse.remise, decimales: 2)} ${l10n.currency}",
                          l10n,
                          valueColor: Colors.green,
                        ),

                      // ✅ Afficher le total APRÈS remise
                      _info(
                        l10n.total,
                        "${NumberFormatUtil.formatMontant(caisse.total, decimales: 2)} ${l10n.currency}",
                        l10n,
                        valueColor: caisse.remiseActive && caisse.remise > 0
                            ? Colors.green
                            : Appstyle.violet,
                      ),

                      _info(l10n.paid,
                          payeController.text.isEmpty ? "0" : payeController.text,
                          l10n),
                      _info(l10n.remaining, resteController.text, l10n),
                      _info(l10n.products, caisse.produits.length, l10n),
                      _info(
                        l10n.articles,
                        caisse.produits.fold(0, (s, p) => s + p.qte.toInt()),
                        l10n,
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  /// 🔹 TABLE PRODUITS
                  TableauEncaissementBLSC(
                    produits: caisse.produits,
                    height: 500,
                    remiseValue: caisse.remise,           // ✅ Valeur de la remise
                    remiseActive: caisse.remiseActive,    // ✅ Si la remise est active
                    remiseNom: caisse.remisenom,          // ✅ Nom de la remise
                  ),
                ],
              ),
            ),

            /// ───────── FOOTER ─────────
            footer: Row(
              children: [

                /// Paiement
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
                                payeController.text =
                                    NumberFormatUtil.formatMontant(caisse.total, decimales: 2);
                                resteController.text = "0.00";
                              } else {
                                payeController.text = "";
                                resteController.text =
                                    NumberFormatUtil.formatMontant(caisse.total, decimales: 2);
                              }
                            });
                          },
                          activeColor: Appstyle.violet,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          l10n.fullPayment,
                          style: Appstyle.textSB,
                        ),
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
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                        ),
                        onChanged: (value) {
                          setState(updateReste);
                        },
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                /// Bouton Cancel
                MainButton(
                  text: l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(width: 10),
                MainButton(
                  text: l10n.cashPrintBLSC,
                  color: Appstyle.violet,
                  icon: Icons.print,
                  onPressed: () async {

                    final verse =
                        double.tryParse(payeController.text) ?? 0;
                    final reste = double.tryParse(resteController.text) ??
                        caisse.total;

                    /// ✅ Vérification montant
                    if (verse <= 0) {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.attention,
                        kind: DialogKind.attention,
                        titre_concerne: l10n.payment,
                        message: l10n.paymentAmountMustBePositive,
                      );
                      return;
                    }

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

                    /// ✅ Confirmation utilisateur
                    await ConfirmationDialog(
                      context: context,
                      kind: DialogKind.attention,
                      titre: l10n.attention,
                      message: l10n.confirmPrint,
                      onConfirmer: () async {
                        // Sert uniquement à décider, dans le catch, si le
                        // panier doit être vidé malgré l'exception (vente
                        // déjà enregistrée avec succès, erreur survenue
                        // seulement pendant l'impression/sauvegarde ensuite).
                        bool venteEnregistree = false;
                        try
                        {

                          /// =========================
                          /// SAVE PANNIER — enregistré dès la confirmation du
                          /// bouton Encaisser/Imprimer, avant toute génération
                          /// d'impression : la Facture n'est jamais imprimée
                          /// pour une vente qui n'a pas été réellement
                          /// enregistrée en base.
                          /// =========================
                          int idp = await _GetNextpannierId();

                          String Ccode = CaisseTest
                              .firstWhere((e) => e.nomCaisse == caisse.caisse)
                              .code;

                          // ✅ Utilisation du générateur de code pour le pannier
                          final codePannier = CodeGenerator.generateCode(
                            prefix: CodePrefix.pannier,
                            id: idp,
                            digitCount: 7, // 6 chiffres pour "PN000001"
                          );

                          Pannier pannier = Pannier(
                            id: idp,
                            code: codePannier, // ✅ Code formaté
                            etat: true,
                            // ✅ Date de vente = moment du clic sur Encaisser,
                            // pas caisse.date (figée depuis l'ouverture de
                            // l'onglet caisse, potentiellement des heures plus tôt).
                            date: DateTime.now(),
                            client_code: client.code,
                            montant: caisse.total,
                            dateCree: DateTime.now(),
                            caisse_code: Ccode,
                            typepannier: ListsConst.typePannier[1],
                            modePaiement: caisse.modePaiement,
                            caissier_code: userCode!,
                            nombreArticle: caisse.nombreArticles,
                            quantiteProduit: caisse.nombreProduits,
                            caisse: caisse.caisse,
                            montantAchat: caisse.totalAchat,
                            marge: caisse.marge,
                          );

                          final response = await _SavePannier(
                            pannier: pannier,
                            caisse: caisse,
                            userCode: userCode!,
                            userName: userName!,
                            client: client,
                            montant: verse,
                            magasinCode: selectedMagasinCode,
                            caisseCode: Ccode,
                          );

                          await InformationDialog(
                            context: context,
                            titre_type_message:
                            response.success ? l10n.add : l10n.error,
                            titre_concerne: l10n.cart,
                            message: response.success
                                ? l10n.lepannierestenregestre
                                : l10n.lepanniernestpasenregestre,
                          );

                          if (!response.success) {
                            return;
                          }
                          venteEnregistree = true;

                          /// =========================
                          /// GENERATE INVOICE NUMBER
                          /// =========================
                          final invoiceNumber =
                              'BLSC-${DateTime.now().year}'
                              '${DateTime.now().month.toString().padLeft(2, '0')}'
                              '${DateTime.now().day.toString().padLeft(2, '0')}-'
                              '${DateTime.now().millisecondsSinceEpoch % 10000}';

                          Uint8List pdfBytes;
                          // ⚠️ `LocaleProvider()` créerait une instance
                          // fraîche dont la locale sauvegardée se charge de
                          // façon asynchrone (défaut 'fr' à la construction)
                          // : lue synchroniquement juste après, isRTL était
                          // donc toujours faux, même en arabe — d'où
                          // l'utilisation systématique de la police latine
                          // (sans glyphes arabes) pour le BLSC.
                          final local = Provider.of<LocaleProvider>(context, listen: false);
                          bool isRTL = local.locale.languageCode == 'ar';
                          final entreprise = await EntrepriseParamServices.getEntrepriseParam();
                          final logoBytes = await LogoService.loadLogoBytes(entreprise.logoPath);
                          if (isRTL) {
                            final arabicGenerator = PDFGeneratorArabic();
                            await arabicGenerator.loadFonts();
                            pdfBytes = await arabicGenerator.generateInvoice(
                              caisse: caisse,
                              client: client,
                              magasinName: entreprise.nomBoutique,
                              caissierName: userName!,
                              verse: verse,
                              reste: reste,
                              invoiceNumber: invoiceNumber,
                              invoiceType: "BLSC",
                              adresse: entreprise.adresse,
                              logoBytes: logoBytes,
                            );
                          } else {
                            pdfBytes = await PDFGeneratorLatin.generateInvoice(
                              caisse: caisse,
                              client: client,
                              magasinName: entreprise.nomBoutique,
                              caissierName: userName!,
                              verse: verse,
                              reste: reste,
                              invoiceNumber: invoiceNumber,
                              invoiceType: "BLSC",
                              l10n: l10n,
                              adresse: entreprise.adresse,
                              logoBytes: logoBytes,
                            );
                          }

                          /// =========================
                          /// PREVIEW PDF
                          /// =========================
                          final action = await showDialog<String>(
                            context: context,
                            barrierDismissible: false,
                            builder: (_) => PDFPreviewDialog(
                              pdfBytes: pdfBytes,
                              l10n: l10n,
                              onPrint: () => Navigator.pop(context, 'print'),
                              onSave: () => Navigator.pop(context, 'save'),
                              onShare: () => Navigator.pop(context, 'share'),
                              onCancel: () => Navigator.pop(context, 'cancel'),
                            ),
                          );

                          // La vente est déjà enregistrée à ce stade (voir
                          // SAVE PANNIER ci-dessus) : annuler l'aperçu annule
                          // seulement l'impression/sauvegarde/partage du
                          // document, pas la vente — le panier doit donc être
                          // vidé dans tous les cas.
                          if (action == null || action == 'cancel') {
                            onSuccess();
                            return;
                          }

                          /// =========================
                          /// PRINT
                          /// =========================
                          if (action == 'print') {
                            await Printing.layoutPdf(
                              onLayout: (_) async => pdfBytes,
                            );


                            await InformationDialog(
                              context: context,
                              titre_type_message: l10n.success,
                              titre_concerne: l10n.ticket,
                              message: l10n.printSuccess,
                            );
                          }

                          /// =========================
                          /// SAVE
                          /// =========================
                          if (action == 'save' || action == 'share') {
                            final fileName = 'Facture_$invoiceNumber.pdf';
                            final file =
                            await PDFGeneratorLatin.savePDF(pdfBytes, fileName);

                            if (action == 'share') {
                              await Share.shareXFiles(
                                [XFile(file.path)],
                                text: l10n.invoiceShared,
                                subject: l10n.invoice,
                              );
                            } else {

                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.invoice,
                                message: ('${l10n.invoiceSaved}: ${file.path}'),
                              );

                            }
                          }

                          // ✅ Le pannier est déjà enregistré à ce stade (voir
                          // le bloc SAVE PANNIER en tête de ce handler) ;
                          // onSuccess() vide le panier une fois l'impression/
                          // sauvegarde/partage de la Facture terminée.
                          onSuccess();

                        } catch (e) {

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            kind: DialogKind.refuser,
                            titre_concerne: l10n.ticket,
                            message: ("Erreur : $e"),
                          );

                          // La vente était déjà enregistrée avant l'erreur
                          // (échec seulement sur l'impression/sauvegarde) :
                          // vider quand même le panier pour éviter une
                          // double vente si l'utilisateur relance l'encaissement.
                          if (venteEnregistree) {
                            onSuccess();
                          }

                        }
                      },
                    );
                  },
                )

              ],
            ),
          );
        },
      );
    },
  );
}

/// 🔹 Widget info avec couleur optionnelle
Widget _info(String label, dynamic value, AppLocalizations l10n, {Color? valueColor}) {
  return SizedBox(
    width: 220,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Appstyle.textSB.copyWith(color: Appstyle.Tnoir),
        ),
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