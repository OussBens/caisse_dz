import 'dart:typed_data';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart' hide ApiResponse;
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
import '../../../data/models/verssement.dart';
import '../../locale/locale_provider.dart';
import '../../utilis/api_response.dart';
import '../../widget/code_generateur.dart';
import '../confirmation_dialog.dart';
import '../information_dialog.dart';

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
// Ajoutez cette fonction dans chaque fichier de dialogue
Future<void> _decrementStockReel({
  required String produitCode,
  required String magasinCode,
  required double quantiteReelle,
  required String userName,
}) async {
  final db = await DbCreator.openDb();
  final pmdService = ProduitMagasinDetailServices(db);

  // Récupérer le détail produit-magasin
  final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
    produitCode,
    magasinCode,
  );

  if (magasinDetail != null && magasinDetail.quantite >= quantiteReelle) {
    // Déstocker du magasin
    await pmdService.decrementQuantite(magasinDetail.id, quantiteReelle);
  } else if (magasinDetail != null && magasinDetail.quantite < quantiteReelle) {
    // Déstocker ce qui est disponible (cas de stock partiel)
    await pmdService.decrementQuantite(magasinDetail.id, magasinDetail.quantite);
  }
}
Future<ApiResponse<int>> _SavePannier ({
  required  Pannier     pannier,
  required  CaisseState caisse,
  required  String      userName,
  required  String      userCode,
  required  Client      client,
  required  double      montant,
  required String magasinCode,  // ✅ Ajouter ce paramètre
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
  final Produitse = await ProduitServices.getAllProduits();

  PannierProduit  prod;
  Produit Produite;
  int idp;
  int idh;
  int idm;
  final response = await services.addPannier(pannier);

  // ✅ ÉTAPE 1: Déstocker avant d'enregistrer
  for (var produit in caisse.produits) {
    final quantiteReelle = produit.quantiteReelleEnPieces;
    final produitOriginal = Produitse.firstWhere((p) => p.nom == produit.nom);

    // Déstocker du magasin
    final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
      produit.code,
      magasinCode,
    );

    if (magasinDetail != null) {
      final quantiteADestock = quantiteReelle <= magasinDetail.quantite
          ? quantiteReelle
          : magasinDetail.quantite;

      if (quantiteADestock > 0) {
        await pmdService.decrementQuantite(magasinDetail.id, quantiteADestock);
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
      nomProduit  : produit.nom,
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
        desc        : "L'utilisateur $userName a Ajoutee le Produit ${prod.nomProduit} au Pannier ${pannier.code}",
        oper        : ListsConst.typeHisto[0],
        dateCree    : DateTime.now(),
        creeParCode : userCode
    );
    await serviceh.addHistorique(histo);

    idm = await _GetNextMouvementId();
    Mouvement Mouv = Mouvement(
      id            : idm,
      code          : CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.mouvement,
        id: idm,
      ),
      date          : pannier.date,
      type          : ListsConst.typeMouvement[0],
      etat          : true,
      dateCree      : DateTime.now(),
      quantite      : quantiteReelle,
      prixAchat     : Produitse.where((e) => e.nom == prod.nomProduit).first.prixAchat,
      prixVente     : prod.prix,
      nomProduit    : prod.nomProduit,
      codeProduit   : prod.codeProduit,
      creeParCode   : userCode,
      codeOperation : pannier.code,
    );

    await servicem.addMouvement(Mouv);

    Produite = Produitse.where((e) => e.nom == prod.nomProduit).first;
    Produite.quantite   = Produite.quantite   - quantiteReelle;
    Produite.dateModif  = DateTime.now();
    Produite.modifPar   = userName;
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
  client.modifPar     = userName;

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
      beneficiare: client.nom,
      montant: montant,
      etat: true,
      mode_paiement: pannier.modePaiement!,
      sense: 'Entrée',
      type: "Pannier",
      dateCree: DateTime.now(),
      creeParCode: userCode,
      caisse: pannier.caisse,
    );

    await versementService.addverssement(versement);
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
      titre_concerne: l10n.user,
      message: l10n.loginRequiredCreate,
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
                          "${caisse.totalAchat.toStringAsFixed(2)} ${l10n.currency}",
                          l10n,
                          valueColor: Appstyle.TgrisF,
                        ),

                      // ✅ Afficher la remise si active
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.discount,
                          "${caisse.remise.toStringAsFixed(2)} ${l10n.currency}",
                          l10n,
                          valueColor: Colors.green,
                        ),

                      // ✅ Afficher le total APRÈS remise
                      _info(
                        l10n.total,
                        "${(caisse.total-caisse.remise).toStringAsFixed(2)} ${l10n.currency}",
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
                                    caisse.total.toStringAsFixed(2);
                                resteController.text = "0.00";
                              } else {
                                payeController.text = "";
                                resteController.text =
                                    caisse.total.toStringAsFixed(2);
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
                        double.tryParse(payeController.text) ?? caisse.total;
                    final reste = double.tryParse(resteController.text) ?? 0;

                    /// ✅ Vérification montant
                    if (verse <= 0) {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.attention,
                        titre_concerne: l10n.payment,
                        message: l10n.paymentAmountMustBePositive,
                      );
                      return;
                    }

                    /// ✅ Confirmation utilisateur
                    await ConfirmationDialog(
                      context: context,
                      titre: l10n.attention,
                      message: l10n.confirmPrint,
                      onConfirmer: () async {
                        try
                        {

                          /// =========================
                          /// GENERATE INVOICE NUMBER
                          /// =========================
                          final invoiceNumber =
                              'BLSC-${DateTime.now().year}'
                              '${DateTime.now().month.toString().padLeft(2, '0')}'
                              '${DateTime.now().day.toString().padLeft(2, '0')}-'
                              '${DateTime.now().millisecondsSinceEpoch % 10000}';

                          Uint8List pdfBytes;
                          final local = LocaleProvider();
                          bool isRTL = local.locale.languageCode == 'ar';
                          if (isRTL) {
                            final arabicGenerator = PDFGeneratorArabic();
                            await arabicGenerator.loadFonts();
                            pdfBytes = await arabicGenerator.generateInvoice(
                              caisse: caisse,
                              client: client,
                              magasinName: l10n.magaprinc,
                              caissierName: userName!,
                              verse: verse,
                              reste: reste,
                              invoiceNumber: invoiceNumber,
                              invoiceType: "BLSC",
                            );
                          } else {
                            pdfBytes = await PDFGeneratorLatin.generateInvoice(
                              caisse: caisse,
                              client: client,
                              magasinName: l10n.magaprinc,
                              caissierName: userName!,
                              verse: verse,
                              reste: reste,
                              invoiceNumber: invoiceNumber,
                              invoiceType: "BLSC",
                              l10n: l10n,
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

                          if (action == null || action == 'cancel') return;

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

                          /// =========================
                          /// SAVE PANNIER
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
                            date: caisse.date,
                            verse: verse,
                            reste: double.parse(resteController.text),
                            client: caisse.client,
                            client_code: client.code,
                            montant: caisse.total,
                            caissier: userName,
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
                            userCode: userCode,
                            userName: userName,
                            client: client,
                            montant: verse,
                            magasinCode: selectedMagasinCode,
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

                          if (response.success) {
                            onSuccess();
                          }



                        } catch (e) {

                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.ticket,
                            message: ("Erreur : $e"),
                          );

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