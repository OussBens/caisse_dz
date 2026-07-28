import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

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
import 'package:caisse_dz/core/tableau/caisse/tableau_encaisserTicket.dart';
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
import 'package:flutter/cupertino.dart' as ui;
import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:provider/provider.dart';
import 'package:flutter/cupertino.dart';

import '../../../Services/MagasinDetail.dart';
import '../../../Services/ReceiptPreviewDialog.dart';
import '../../../Services/Receipt_Arabic.dart';
import '../../../Services/Receipt_EN_FR.dart';
import '../../../Services/Verssement.dart' hide ApiResponse;
import '../../../Services/printer_manager.dart';
import '../../../data/models/verssement.dart';
import '../../locale/locale_provider.dart';
import '../../utilis/api_response.dart';
import '../../widget/code_generateur.dart'; // ✅ Ajout de l'import
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

Future<ApiResponse<int>> _SavePannier({
  required Pannier pannier,
  required CaisseState caisse,
  required String userName,
  required String userCode,
  required Client client,
  required double montant,
  required String magasinCode,
}) async {
  final db = await DbCreator.openDb();
  final serviceh = HistoriqueServices(db);
  final servicem = MouvementsServices(db);
  final services = PannierServices(db);
  final serviceP = ProduitServices(db);
  final servicep = PPServices(db);
  final serviceC = ClientServices(db);
  final versementService = VerssementServices(db);
  final pmdService = ProduitMagasinDetailServices(db);

  final Produitse = await ProduitServices.getAllProduits();

  // 1. Déstocker du magasin
  for (var produit in caisse.produits) {
    final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
    final produitOriginal = Produitse.firstWhere((p) => p.nom == produit.nom);

    final magasinDetail = await pmdService.getSingleByProduitAndMagasin(
      produit.code,
      magasinCode,
    );

    if (magasinDetail != null && magasinDetail.quantite >= quantiteReelle) {
      await pmdService.decrementQuantite(magasinDetail.id, quantiteReelle);
    } else if (magasinDetail != null && magasinDetail.quantite < quantiteReelle) {
      await pmdService.decrementQuantite(magasinDetail.id, magasinDetail.quantite);
    }
  }

  // 2. Ajouter le pannier
  final response = await services.addPannier(pannier);
  if (!response.success) {
    return response;
  }

  // 3. Ajouter l'historique du pannier
  final idh = await _GetNextHistoriqueId();
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

  // 4. Ajouter les produits du panier
  for (var produit in caisse.produits) {
    final idpp = await _GetNextPPId();
    final quantiteReelle = produit.qte * (produit.piecesParEmballage ?? 1);
    final produitOriginal = Produitse.firstWhere((p) => p.nom == produit.nom);

    PannierProduit prod = PannierProduit(
      id: idpp,
      prix: produit.prix,
      etat: true,
      total: produit.prix * produit.qte,
      creeLe: DateTime.now(),
      quantite: quantiteReelle,
      codeProduit: produit.code,
      codePannier: pannier.code,
      creeParCode: userCode,
      prixAchat: produit.prixachat,
      totalAchat: produit.prixachat * quantiteReelle,
    );

    await servicep.addPP(prod);

    // Historique produit
    final idh2 = await _GetNextHistoriqueId();
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
    final idm = await _GetNextMouvementId();
    Mouvement Mouv = Mouvement(
      id: idm,
      code: CodeGenerator.generateCodeWithTimestamp(
        prefix: CodePrefix.mouvement,
        id: idm,
      ),
      date: pannier.date,
      type: ListsConst.typeMouvement[0],
      etat: true,
      dateCree: DateTime.now(),
      quantite: quantiteReelle,
      prixAchat: produitOriginal.prixAchat,
      prixVente: prod.prix,
      codeProduit: prod.codeProduit,
      creeParCode: userCode,
      codeOperation: pannier.code,
    );
    await servicem.addMouvement(Mouv);

    // Mise à jour du produit (quantité globale)
    produitOriginal.quantite = produitOriginal.quantite - quantiteReelle;
    produitOriginal.dateModif = DateTime.now();
    produitOriginal.modifParCode = userCode;
    await serviceP.updateProduit(produitOriginal);

    // Historique mise à jour produit
    final idh3 = await _GetNextHistoriqueId();
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

  // 5. Mise à jour du client
  client.dernierAchat = DateTime.now();
  client.modifParCode = userCode;
  await serviceC.updateClient(client);

  // 6. Ajout du versement
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
      type: "Pannier",
      dateCree: DateTime.now(),
      creeParCode: userCode,
      caisse: pannier.caisse,
    );
    await versementService.addverssement(versement);
  }

  return ApiResponse(success: true, message: "Succès", data: pannier.id);
}



/// Helper function to generate receipt text based on language
String _generateReceiptText({
  required dynamic caisse,
  required dynamic client,
  required int panierNumber,
  required String magasinName,
  required String caissierName,
  required double verse,
  required double reste,
  required String languageCode,
})
{
  // Check if language is Arabic
  if (languageCode == 'ar') {
    return ReceiptArabic.generate(
      caisse: caisse,
      client: client,
      panierNumber: panierNumber,
      magasinName: magasinName,
      caissierName: caissierName,
      verse: verse,
      reste: reste,
    );
  } else {
    // French or English
    return ReceiptLatin.generate(
      caisse: caisse,
      client: client,
      panierNumber: panierNumber,
      magasinName: magasinName,
      caissierName: caissierName,
      verse: verse,
      reste: reste,
      lang: languageCode,
    );
  }
}

/// Helper function to convert text to image bytes for preview
Future<Uint8List> _textToImage(String text) async {
  // Create a TextPainter to measure and draw text
  final textPainter = ui.TextPainter(
    text: ui.TextSpan(
      text: text,
      style: const ui.TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        color: Colors.black,
        height: 1.2,
      ),
    ),
    textDirection: ui.TextDirection.ltr,
    maxLines: null,
  );

  textPainter.layout(maxWidth: 500);

  final width = textPainter.width.ceilToDouble();
  final height = textPainter.height.ceilToDouble();

  final padding = 20.0;
  final totalWidth = width + (padding * 2);
  final totalHeight = height + (padding * 2);

  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, totalWidth, totalHeight),
    Paint()..color = Colors.white,
  );

  final borderPaint = Paint()
    ..color = Colors.grey[300]!
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  canvas.drawRect(
    Rect.fromLTWH(0, 0, totalWidth, totalHeight),
    borderPaint,
  );

  textPainter.paint(canvas, Offset(padding, padding));

  final picture = recorder.endRecording();
  final image = await picture.toImage(totalWidth.toInt(), totalHeight.toInt());
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

  return byteData!.buffer.asUint8List();
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
Future<void> EncaissementTicketDialog({
  required  BuildContext  context,
  required  CaisseState   caisse,
  required  int           pannier,
  required  Client        client,
  required  Map<String, dynamic> clientInfo,
  required String selectedMagasinCode,
  required VoidCallback onSuccess,
}) async{
  final TextEditingController payeController = TextEditingController();
  final TextEditingController resteController = TextEditingController(
    text: caisse.total.toStringAsFixed(2),
  );
  int p = pannier;
  List<CaisseGestion> CaisseTest = [];

  Future<void> _LoadAllData() async {
    final db    = await DbCreator.openDb();
    CaisseTest  = await GCServices.getAllCaisses();
  }

  await _LoadAllData();

  final auth = Provider.of<AuthState>(context, listen: false);
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

  final String userName = auth.username!;
  final String userCode = auth.userCode!;

  /// Calculs
  int nombreProduits = caisse.produits.length;
  int nombreArticles = caisse.produits.fold(0, (s, p) => s + p.qte.toInt());

  String datePanier =
      "${caisse.date.day.toString().padLeft(2, '0')}/"
      "${caisse.date.month.toString().padLeft(2, '0')}/"
      "${caisse.date.year}";
  bool paiementTotal = true;

  void updateReste(String value) {
    final paye = double.tryParse(value) ?? 0;
    resteController.text = (caisse.total - paye).toStringAsFixed(2);
  }

  await _LoadAllData();

  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    barrierDismissible: false,
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final localeProvider = Provider.of<LocaleProvider>(context);
          final currentLanguage = localeProvider.locale.languageCode;

          if (paiementTotal && payeController.text.isEmpty) {
            payeController.text = caisse.total.toStringAsFixed(2);
            resteController.text = "0.00";
          }

          return BaseDialog(
            width: 1100,
            header: TitreAvecLigne(
              imagePath: 'assets/icons/sidebar/pannier_icon.png',
              text: l10n.cashTicket,
            ),

            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 12,
                    children: [
                      _info(l10n.cartNumber, pannier, l10n),
                      _info(l10n.client, caisse.client, l10n),
                      _info(l10n.date, datePanier, l10n),
                      _info(l10n.products, caisse.produits.length, l10n),
                      _info(l10n.articles, nombreArticles, l10n),

                      // ✅ TOTAL (avant remise)
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.totalBeforeDiscount,
                          "${caisse.totalAchat.toStringAsFixed(2)} ${l10n.currency}",
                          l10n,
                          valueColor: Appstyle.TgrisF,
                        ),

                      // ✅ Remise
                      if (caisse.remiseActive && caisse.remise > 0)
                        _info(
                          l10n.discount,
                          "${caisse.remise.toStringAsFixed(2)} ${l10n.currency}",
                          l10n,
                          valueColor: Colors.green,
                        ),

                      // ✅ TOTAL FINAL
                      _info(
                        l10n.totalFinal,
                        "${(caisse.total-caisse.remise).toStringAsFixed(2)} ${l10n.currency}",
                        l10n,
                        valueColor: caisse.remiseActive && caisse.remise > 0
                            ? Colors.green
                            : Appstyle.violet,
                      ),

                      _info(l10n.paid, payeController.text.isEmpty ? "0" : payeController.text, l10n),
                      _info(l10n.remaining, resteController.text, l10n),
                    ],
                  ),
                  const SizedBox(height: 20),

                  TableauEncaissementTicket(
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
                    SizedBox(width: 15,),

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
                          contentPadding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        ),
                        onChanged: (value) {
                          setState(() {
                            final paye = double.tryParse(value) ?? 0;
                            resteController.text =
                                (caisse.total - paye).toStringAsFixed(2);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const Spacer(),

                MainButton(
                  text: l10n.cancel,
                  color: Appstyle.gris,
                  icon: Icons.cancel,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                MainButton(
                  text: l10n.cashPrintTicket,
                  color: Appstyle.violet,
                  icon: Icons.print,
                  onPressed: () async {
                    final verse = double.tryParse(payeController.text) ?? 0;
                    final reste = double.tryParse(resteController.text) ??
                        caisse.total;

                    if (verse <= 0) {
                      await InformationDialog(
                        context: context,
                        titre_type_message: l10n.attention,
                        titre_concerne: l10n.payment,
                        message: l10n.paymentAmountMustBePositive,
                      );
                      return;
                    }

                    await ConfirmationDialog(
                      context: context,
                      titre: l10n.attention,
                      message: l10n.confirmPrint,
                      onConfirmer: () async {
                        try {
                          int idp = await _GetNextpannierId();
                          String Ccode = CaisseTest
                              .where((e) => e.nomCaisse == caisse.caisse)
                              .first
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
                            verse: caisse.total -
                                (double.parse(resteController.text)),
                            reste: double.parse(resteController.text),
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
                              pannier: pannier,
                              caisse: caisse,
                              userCode: userCode,
                              userName: userName,
                              client: client,
                              montant: montant,
                            magasinCode:selectedMagasinCode,
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
                          onSuccess();
                          // Generate receipt text based on current language
                          final receiptText = _generateReceiptText(
                            caisse: caisse,
                            client: client,
                            panierNumber: p,
                            magasinName: l10n.magaprinc,
                            caissierName: userName,
                            verse: verse,
                            reste: reste,
                            languageCode: currentLanguage,
                          );
                          final receiptImage = await _textToImage(receiptText);

                          bool isDialogActive = true;

                          final shouldPrint = await showDialog<bool>(
                            context: context,
                            barrierDismissible: false,
                            builder: (previewContext) {
                              return ReceiptPreviewDialog(
                                receiptImage: receiptImage,
                                l10n: l10n,
                                onPrint: () {
                                  isDialogActive = false;
                                  Navigator.pop(previewContext, true);
                                },
                                onCancel: () {
                                  isDialogActive = false;
                                  Navigator.pop(previewContext, false);
                                },
                              );
                            },
                          );

                          if (shouldPrint == true && isDialogActive) {
                            final loadingContext = context;
                            showDialog(
                              context: loadingContext,
                              barrierDismissible: false,
                              builder: (loadingContext) =>
                              const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );

                            try {
                              final printerManager = PrinterManager();

                              final bluetoothEnabled = await printerManager
                                  .initBluetooth();
                              if (!bluetoothEnabled) {
                                throw Exception(l10n.bluetoothDisabled);
                              }

                              final printers = await printerManager
                                  .getBondedPrinters();

                              if (printers.isEmpty) {
                                throw Exception(l10n.noPrinterFound);
                              }

                              BluetoothInfo? selectedPrinter;
                              if (printers.length == 1) {
                                selectedPrinter = printers.first;
                              } else {
                                Navigator.pop(loadingContext);

                                selectedPrinter = await showDialog<BluetoothInfo>(
                                  context: loadingContext,
                                  builder: (context) =>
                                      SimpleDialog(
                                        title: Text(l10n.selectPrinter),
                                        children: printers.map((printer) =>
                                            SimpleDialogOption(
                                              onPressed: () =>
                                                  Navigator.pop(context, printer),
                                              child: Text(printer.name),
                                            )).toList(),
                                      ),
                                );

                                if (selectedPrinter != null) {
                                  showDialog(
                                    context: loadingContext,
                                    barrierDismissible: false,
                                    builder: (context) =>
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                              }

                              if (selectedPrinter == null) {
                                if (Navigator.canPop(loadingContext)) {
                                  Navigator.pop(loadingContext);
                                }
                                return;
                              }

                              final connected = await printerManager.connect(
                                  selectedPrinter.macAdress);
                              if (!connected) {
                                throw Exception(l10n.connectionFailed);
                              }

                              final receiptBytes = utf8.encode(receiptText);
                              final printed = await printerManager.print(
                                  receiptBytes);
                              if (!printed) {
                                throw Exception(l10n.printFailed);
                              }

                              await printerManager.disconnect();

                              if (Navigator.canPop(loadingContext)) {
                                Navigator.pop(loadingContext);
                              }



                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.success,
                                titre_concerne: l10n.ticket,
                                message: l10n.ticketPrintedSuccess,
                              );

                            } catch (e) {
                              if (Navigator.canPop(loadingContext)) {
                                Navigator.pop(loadingContext);
                              }
                              await InformationDialog(
                                context: context,
                                titre_type_message: l10n.attention,
                                titre_concerne: l10n.print,
                                message: l10n.printError,
                              );
                            }
                          }

                          if (Navigator.canPop(context)) {
                            Navigator.pop(context, true);
                          }
                        } catch (e) {
                          await InformationDialog(
                            context: context,
                            titre_type_message: l10n.error,
                            titre_concerne: l10n.print,
                            message: ("Erreur : $e"),
                          );
                        }
                      },
                    );
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