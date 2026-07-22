import 'dart:io';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/besoinList.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/entree.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/histore.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/pack.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/remise.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/role.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/sortie.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/data/models/zakat.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';

class ExcelGenerator {
  static Future<File> generateClientsExcel({
    required List<Client> clients,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Clients'];

    // ALL client fields - Export everything from the Client model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.code),
      TextCellValue(l10n.name),
      TextCellValue(l10n.phone),
      TextCellValue(l10n.email),
      TextCellValue(l10n.fax),
      TextCellValue(l10n.wilaya),
      TextCellValue(l10n.address),
      TextCellValue(l10n.typeClient),
      TextCellValue(l10n.activity),
      TextCellValue(l10n.nif),
      TextCellValue(l10n.nis),
      TextCellValue(l10n.nrc),
      TextCellValue(l10n.rib),
      TextCellValue(l10n.bank),
      TextCellValue(l10n.lastPurchase),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < clients.length; row++) {
      final client = clients[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(client.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(client.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(client.nom);
      // Phone
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(client.telephone);
      // Email
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(client.email ?? '-');
      // Fax
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(client.fax ?? '-');
      // Wilaya
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(client.wilaya ?? '-');
      // Address
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(client.adresse ?? '-');
      // Type Client (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateTypeClient(client.type));
      // Activity (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(client.activity != null
          ? translator.translateActiviteClient(client.activity!)
          : '-');
      // NIF
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(client.nif ?? '-');
      // NIS
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(client.nis ?? '-');
      // NRC
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(client.nrc ?? '-');
      // RIB
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(client.rib ?? '-');
      // Bank
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(client.banque ?? '-');
      // Last Purchase
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(client.dernierAchat != null
          ? _formatDate(client.dernierAchat!)
          : '-');
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(client.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(client.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(client.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(client.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex))
          .value = TextCellValue(client.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 21, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(client.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: rowIndex))
          .value = TextCellValue(client.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rowIndex))
          .value = TextCellValue(client.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeClients = clients.where((c) => c.etat).length;
    int inactiveClients = clients.where((c) => !c.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalClients);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(clients.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeClients.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveClients.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Clients_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generatePanniersExcel({
    required List<Pannier> panniers,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Panniers'];

    // ALL pannier fields - Export everything from the Pannier model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.code),
      TextCellValue(l10n.date),
      TextCellValue(l10n.client),
      TextCellValue(l10n.amount),
      TextCellValue(l10n.articles),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.paid),
      TextCellValue(l10n.remaining),
      TextCellValue(l10n.payment),
      TextCellValue(l10n.cashier),
      TextCellValue(l10n.typePannier),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < panniers.length; row++) {
      final pannier = panniers[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(pannier.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(pannier.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pannier.date));
      // Client
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(pannier.client);
      // Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(pannier.montant.toStringAsFixed(2));
      // Number of Articles
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue((pannier.nombreArticle ?? 0).toString());
      // Quantity of Products
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue((pannier.quantiteProduit ?? 0).toString());
      // Paid Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(pannier.verse.toStringAsFixed(2));
      // Remaining Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(pannier.reste.toStringAsFixed(2));
      // Payment Mode (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateModePaiement(pannier.modePaiement!));
      // Cashier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(pannier.caissier);
      // Type Pannier (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateTypePannier(pannier.typepannier));
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(pannier.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pannier.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(pannier.caissier_code);
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pannier.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(pannier.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pannier.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(pannier.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: rowIndex))
          .value = TextCellValue(pannier.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalAmount = panniers.fold(0.0, (sum, p) => sum + p.montant);
    double totalPaid = panniers.fold(0.0, (sum, p) => sum + p.verse);
    double totalRemaining = panniers.fold(0.0, (sum, p) => sum + p.reste);
    int totalArticles = panniers.fold(0, (sum, p) => sum + (p.nombreArticle ?? 0));
    int totalQuantity = panniers.fold(0, (sum, p) => sum + (p.quantiteProduit ?? 0));
    int activePanniers = panniers.where((p) => p.etat).length;
    int inactivePanniers = panniers.where((p) => !p.etat).length;
    double avgAmount = panniers.isEmpty ? 0 : totalAmount / panniers.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalPanniers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(panniers.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activePanniers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactivePanniers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalPaid);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalPaid.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.totalRemaining);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(totalRemaining.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalArticles);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalArticles.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(totalQuantity.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Panniers_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateProduitsExcel({
    required List<Produit> produits,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Produits'];

    // All product fields - EXPORT EVERYTHING
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.code),
      TextCellValue(l10n.name),
      TextCellValue(l10n.brand),
      TextCellValue(l10n.description),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.size),
      TextCellValue(l10n.color),
      TextCellValue(l10n.purchasePrice),
      TextCellValue(l10n.salePrice),
      TextCellValue(l10n.category),
      TextCellValue(l10n.subcategory),
      TextCellValue(l10n.discount),
      TextCellValue(l10n.service),
      TextCellValue(l10n.unit),
      TextCellValue(l10n.packaging1),
      TextCellValue(l10n.packaging2),
      TextCellValue(l10n.minThreshold),
      TextCellValue(l10n.maxThreshold),
      TextCellValue(l10n.need),
      TextCellValue(l10n.barcode),
      TextCellValue(l10n.serialNumber),
      TextCellValue(l10n.multicode),
      TextCellValue(l10n.marginBool),
      TextCellValue(l10n.marginRate),
      TextCellValue(l10n.marginRatePercent),
      TextCellValue(l10n.vat),
      TextCellValue(l10n.thresholdBool),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < produits.length; row++) {
      final produit = produits[row];
      final rowIndex = row + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(produit.etat ? l10n.active : l10n.inactive);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(produit.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(produit.nom);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(produit.marque ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(produit.description ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(produit.quantite.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(produit.taille ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(produit.couleur ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(produit.prixAchat.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(produit.prixVente.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(produit.categorie ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(produit.sousCategorie ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(produit.remise ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(produit.service ? l10n.yes : l10n.no);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(produit.uniteMesure ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(produit.emballage1!.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(produit.emballage2!.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(produit.seuilMin.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(produit.seuilMax.toString());

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex))
          .value = TextCellValue(produit.codeBarre ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 21, rowIndex: rowIndex))
          .value = TextCellValue(produit.numeroSerie ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: rowIndex))
          .value = TextCellValue(produit.multicodebar ? l10n.yes : l10n.no);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rowIndex))
          .value = TextCellValue(produit.margeBool ? l10n.yes : l10n.no);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rowIndex))
          .value = TextCellValue(produit.margeTaux.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 25, rowIndex: rowIndex))
          .value = TextCellValue(produit.margeTauxPrct!.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 26, rowIndex: rowIndex))
          .value = TextCellValue(produit.tva.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 27, rowIndex: rowIndex))
          .value = TextCellValue(produit.seuilBool ? l10n.yes : l10n.no);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 28, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(produit.dateCree));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 29, rowIndex: rowIndex))
          .value = TextCellValue(produit.creeParcode ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 30, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(produit.dateModif));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 31, rowIndex: rowIndex))
          .value = TextCellValue(produit.modifPar ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 32, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(produit.annulerLe));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 33, rowIndex: rowIndex))
          .value = TextCellValue(produit.annulerPar ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 34, rowIndex: rowIndex))
          .value = TextCellValue(produit.motifAnnul ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 35, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalPurchaseValue = produits.fold(0.0, (sum, p) => sum + (p.prixAchat * p.quantite));
    double totalSaleValue = produits.fold(0.0, (sum, p) => sum + (p.prixVente * p.quantite));
    int activeProduits = produits.where((p) => p.etat).length;
    int inactiveProduits = produits.where((p) => !p.etat).length;
    double avgPrice = produits.isEmpty ? 0 : produits.fold(0.0, (sum, p) => sum + p.prixVente) / produits.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalProducts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(produits.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeProduits.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveProduits.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalStockValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalPurchaseValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalSaleValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalSaleValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.averagePrice);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(avgPrice.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Produits_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateCategoriesExcel({
    required List<Categorie> categories,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Categories'];

    // ALL category fields - Export everything from the Categorie model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.categoryCode),
      TextCellValue(l10n.categoryName),
      TextCellValue(l10n.description),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < categories.length; row++) {
      final categorie = categories[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(categorie.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(categorie.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(categorie.nom);
      // Description/Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(categorie.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(categorie.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(categorie.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(categorie.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(categorie.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(categorie.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(categorie.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(categorie.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeCategories = categories.where((c) => c.etat).length;
    int inactiveCategories = categories.where((c) => !c.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalCategories);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(categories.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeCategories.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveCategories.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Categories_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateRemisesExcel({
    required List<Remise> remises,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Remises'];

    // ALL remise fields - Export everything from the Remise model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.discountCode),
      TextCellValue(l10n.discountName),
      TextCellValue(l10n.discountType),
      TextCellValue(l10n.discountValue),
      TextCellValue(l10n.rateType),
      TextCellValue(l10n.rate),
      TextCellValue(l10n.startDate),
      TextCellValue(l10n.endDate),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < remises.length; row++) {
      final remise = remises[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(remise.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(remise.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(remise.nom);
      // Discount Type
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(remise.type);
      // Discount Value (Montant)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(remise.montant.toString());
      // Rate Type (Pourcentage/Montant)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(remise.tauxType ?? '-');
      // Rate Value
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(remise.taux?.toString() ?? '-');
      // Start Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(remise.debut));
      // End Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(remise.fin != null ? _formatDate(remise.fin!) : '-');
      // Observation/Description
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(remise.observation ?? '-');
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(remise.creeParCode ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(remise.creeLe));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(remise.modifPar ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(remise.modifLe));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(remise.annulPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(remise.annulLe));
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(remise.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeRemises = remises.where((r) => r.etat).length;
    int inactiveRemises = remises.where((r) => !r.etat).length;
    int percentageTypeCount = remises.where((r) => r.tauxType == "Pourcentage").length;
    int fixedTypeCount = remises.where((r) => r.tauxType == "Montant").length;
    double avgDiscount = remises.isEmpty ? 0 : remises.fold(0.0, (sum, r) => sum + (r.montant ?? 0)) / remises.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalDiscounts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(remises.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeRemises.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveRemises.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.percentageDiscounts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(percentageTypeCount.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.fixedDiscounts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(fixedTypeCount.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.averageDiscount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(avgDiscount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Remises_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generatePacksExcel({
    required List<Pack> packs,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Packs'];

    // ALL pack fields - Export everything from the Pack model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.packCode),
      TextCellValue(l10n.packName),
      TextCellValue(l10n.description),
      TextCellValue(l10n.packPrice),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < packs.length; row++) {
      final pack = packs[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(pack.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(pack.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(pack.nom);
      // Description/Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(pack.observation ?? '-');
      // Pack Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(pack.prixVente.toStringAsFixed(2));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(pack.creeParCode ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pack.creeLe));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(pack.modifPar ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pack.modifLe));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(pack.annulPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(pack.annulLe));
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(pack.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activePacks = packs.where((p) => p.etat).length;
    int inactivePacks = packs.where((p) => !p.etat).length;
    double totalValue = packs.fold(0.0, (sum, p) => sum + p.prixVente);
    double avgPrice = packs.isEmpty ? 0 : totalValue / packs.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalPacks);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(packs.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activePacks.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactivePacks.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.averagePackPrice);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(avgPrice.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Packs_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateSousCategoriesExcel({
    required List<SousCategorie> sousCategories,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['SousCategories'];

    // ALL sub-category fields - Export everything from the SousCategorie model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.subCategoryCode),
      TextCellValue(l10n.subCategoryName),
      TextCellValue(l10n.category),
      TextCellValue(l10n.description),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < sousCategories.length; row++) {
      final sousCategorie = sousCategories[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.nom);
      // Category Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.categorieNom ?? '-');
      // Description/Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sousCategorie.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sousCategorie.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sousCategorie.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(sousCategorie.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeSubCategories = sousCategories.where((s) => s.etat).length;
    int inactiveSubCategories = sousCategories.where((s) => !s.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalSubCategories);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(sousCategories.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeSubCategories.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveSubCategories.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'SousCategories_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }
  // Add to excel_generator.dart after existing methods

  static Future<File> generateFournisseursExcel({
    required List<Fournisseur> fournisseurs,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Fournisseurs'];

    // ALL supplier fields - Export everything from the Fournisseur model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.supplierCode),
      TextCellValue(l10n.supplierName),
      TextCellValue(l10n.phone),
      TextCellValue(l10n.email),
      TextCellValue(l10n.fax),
      TextCellValue(l10n.wilaya),
      TextCellValue(l10n.address),
      TextCellValue(l10n.typeClient),
      TextCellValue(l10n.activity),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < fournisseurs.length; row++) {
      final fournisseur = fournisseurs[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.nom);
      // Phone
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.telephone);
      // Email
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.email ?? '-');
      // Fax
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.fax ?? '-');
      // Wilaya
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.wilaya ?? '-');
      // Address
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.adresse ?? '-');
      // Type (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateTypeFournisseur(fournisseur.type));
      // Activity (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.activity != null
          ? translator.translateActiviteFournisseur(fournisseur.activity!)
          : '-');
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(fournisseur.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(fournisseur.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(fournisseur.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(fournisseur.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeFournisseurs = fournisseurs.where((f) => f.etat).length;
    int inactiveFournisseurs = fournisseurs.where((f) => !f.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalSuppliers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(fournisseurs.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeFournisseurs.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveFournisseurs.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Fournisseurs_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateVersementsExcel({
    required List<Verssement> versements,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Versements'];

    // ALL payment fields - Export everything from the Verssement model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.paymentCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.type),
      TextCellValue(l10n.beneficiaryType),
      TextCellValue(l10n.beneficiary),
      TextCellValue(l10n.cashRegister),
      TextCellValue(l10n.amount),
      TextCellValue(l10n.paymentMethod),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < versements.length; row++) {
      final versement = versements[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(versement.etat ? l10n.validated : l10n.cancelled);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(versement.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(versement.date));
      // Type (Entrant/Sortant) - translated
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(
          versement.sense.toLowerCase() == 'entrant'
              ? l10n.incoming
              : l10n.outgoing
      );
      // Beneficiary Type (Client/Fournisseur)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(versement.typebeneficiare);
      // Beneficiary Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(versement.beneficiare);
      // Cash Register
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(versement.caisse ?? '-');
      // Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(versement.montant.toStringAsFixed(2));
      // Payment Method (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateModePaiement(versement.mode_paiement));
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(versement.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(versement.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(versement.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(versement.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(versement.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(versement.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(versement.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalAmount = versements.fold(0.0, (sum, v) => sum + v.montant);
    double incomingAmount = versements
        .where((v) => v.sense.toLowerCase() == 'entrant')
        .fold(0.0, (sum, v) => sum + v.montant);
    double outgoingAmount = versements
        .where((v) => v.sense.toLowerCase() == 'sortant')
        .fold(0.0, (sum, v) => sum + v.montant);
    int clientPayments = versements.where((v) => v.typebeneficiare == "Client").length;
    int supplierPayments = versements.where((v) => v.typebeneficiare == "Fournisseur").length;
    int activeVersements = versements.where((v) => v.etat).length;
    int inactiveVersements = versements.where((v) => !v.etat).length;
    double avgAmount = versements.isEmpty ? 0 : totalAmount / versements.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalPayments);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(versements.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.validated);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeVersements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.cancelled);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveVersements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.incomingAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(incomingAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.outgoingAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(outgoingAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.clientPayments);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(clientPayments.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.supplierPayments);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(supplierPayments.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Versements_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateEntreesExcel({
    required List<Entree> entrees,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Entrees'];

    // ALL entry fields - Export everything from the Entree model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.entryCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.product),
      TextCellValue(l10n.productCode),
      TextCellValue(l10n.supplier),
      TextCellValue(l10n.supplierCode),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.purchasePrice),
      TextCellValue(l10n.totalAmount),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.createdByCode),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < entrees.length; row++) {
      final entree = entrees[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(entree.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(entree.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(entree.date));
      // Product Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(entree.produit);
      // Product Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(entree.produitcode ?? '-');
      // Supplier Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(entree.fournisseur ?? '-');
      // Supplier Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(entree.fournisseurCode ?? '-');
      // Quantity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(entree.quantite.toString());
      // Purchase Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(entree.prix.toStringAsFixed(2));
      // Total Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(entree.montant.toStringAsFixed(2));
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(entree.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(entree.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(entree.creeParCode ?? '-');
      // Created By Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(entree.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(entree.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(entree.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(entree.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(entree.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(entree.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalQuantity = entrees.fold(0.0, (sum, e) => sum + e.quantite);
    double totalAmount = entrees.fold(0.0, (sum, e) => sum + e.montant);
    int activeEntrees = entrees.where((e) => e.etat).length;
    int inactiveEntrees = entrees.where((e) => !e.etat).length;
    double avgPrice = entrees.isEmpty ? 0 : entrees.fold(0.0, (sum, e) => sum + e.prix) / entrees.length;
    double avgQuantity = entrees.isEmpty ? 0 : totalQuantity / entrees.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalEntries);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(entrees.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeEntrees.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveEntrees.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.averagePrice);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(avgPrice.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.averageQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(avgQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Entrees_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateSmartScansExcel({
    required List<SmartScan> smartScans,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['SmartScans'];

    // ALL smart scan fields - Export everything from the SmartScan model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.scanCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.activity),
      TextCellValue(l10n.supplier),
      TextCellValue(l10n.products),
      TextCellValue(l10n.calculatedProducts),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.calculatedQuantity),
      TextCellValue(l10n.amount),
      TextCellValue(l10n.calculatedAmount),
      TextCellValue(l10n.gap),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < smartScans.length; row++) {
      final scan = smartScans[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(scan.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(scan.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(scan.date));
      // Activity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(scan.activity ?? '-');
      // Supplier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(scan.fournisseur ?? '-');
      // Number of Products (actual)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(scan.nbrProduit?.toString() ?? '0');
      // Number of Products (calculated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(scan.nbrProduitCalcul?.toString() ?? '0');
      // Quantity of Articles (actual)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(scan.quantiteArticle?.toString() ?? '0');
      // Quantity of Articles (calculated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(scan.quantiteArticleCalcul?.toString() ?? '0');
      // Amount (actual)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(scan.montant.toStringAsFixed(2));
      // Amount (calculated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue((scan.montantCalcul ?? 0).toStringAsFixed(2));
      // Gap (has discrepancy)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(scan.ecart ? l10n.yes : l10n.no);
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(scan.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(scan.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(scan.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(scan.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(scan.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(scan.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(scan.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: rowIndex))
          .value = TextCellValue(scan.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalAmount = smartScans.fold(0.0, (sum, s) => sum + s.montant);
    double totalCalculatedAmount = smartScans.fold(0.0, (sum, s) => sum + (s.montantCalcul ?? 0));
    int totalProducts = smartScans.fold(0, (sum, s) => sum + (s.nbrProduit ?? 0));
    int totalCalculatedProducts = smartScans.fold(0, (sum, s) => sum + (s.nbrProduitCalcul ?? 0));
    double totalQuantity = smartScans.fold(0, (sum, s) => sum + (s.quantiteArticle ?? 0));
    double totalCalculatedQuantity = smartScans.fold(0, (sum, s) => sum + (s.quantiteArticleCalcul ?? 0));
    int scansWithGap = smartScans.where((s) => s.ecart).length;
    int activeScans = smartScans.where((s) => s.etat).length;
    int inactiveScans = smartScans.where((s) => !s.etat).length;
    double avgAmount = smartScans.isEmpty ? 0 : totalAmount / smartScans.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalScans);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(smartScans.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeScans.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveScans.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalCalculatedAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalCalculatedAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.totalProducts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(totalProducts.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalCalculatedProducts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalCalculatedProducts.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(totalQuantity.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.totalCalculatedQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(totalCalculatedQuantity.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        .value = TextCellValue(l10n.scansWithGap);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
        .value = TextCellValue(scansWithGap.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 14))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 14))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'SmartScans_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateSortiesExcel({
    required List<Sortie> sorties,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Sorties'];

    // ALL sortie fields - Export everything from the Sortie model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.exitCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.product),
      TextCellValue(l10n.category),
      TextCellValue(l10n.subcategory),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.price),
      TextCellValue(l10n.amount),
      TextCellValue(l10n.type),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < sorties.length; row++) {
      final sortie = sorties[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(sortie.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(sortie.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sortie.dateCree));
      // Product Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(sortie.produit);
      // Category
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(sortie.categorie ?? '-');
      // Subcategory
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(sortie.souscategorie ?? '-');
      // Quantity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(sortie.quantite.toString());
      // Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(sortie.prix.toStringAsFixed(2));
      // Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(sortie.montant.toStringAsFixed(2));
      // Type (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(translator.translateTypeSortie(sortie.type));
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(sortie.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sortie.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(sortie.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sortie.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(sortie.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(sortie.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(sortie.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(sortie.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalQuantity = sorties.fold(0.0, (sum, s) => sum + s.quantite);
    double totalAmount = sorties.fold(0.0, (sum, s) => sum + s.montant);
    int activeSorties = sorties.where((s) => s.etat).length;
    int inactiveSorties = sorties.where((s) => !s.etat).length;
    double avgQuantity = sorties.isEmpty ? 0 : totalQuantity / sorties.length;
    double avgAmount = sorties.isEmpty ? 0 : totalAmount / sorties.length;

    // Group by type
    Map<String, int> typeCount = {};
    Map<String, double> typeQuantity = {};
    Map<String, double> typeAmount = {};

    for (var s in sorties) {
      typeCount[s.type] = (typeCount[s.type] ?? 0) + 1;
      typeQuantity[s.type] = (typeQuantity[s.type] ?? 0) + s.quantite;
      typeAmount[s.type] = (typeAmount[s.type] ?? 0) + s.montant;
    }

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalExits);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(sorties.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeSorties.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveSorties.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.averageQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(avgQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    // Add breakdown by type
    int typeRow = 10;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
        .value = TextCellValue(l10n.breakdownByType);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
        .cellStyle = CellStyle(bold: true, fontSize: 12);
    typeRow++;

    for (var entry in typeCount.entries) {
      final typeName = translator.translateTypeSortie(entry.key);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.count}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(entry.value.toString());
      typeRow++;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.quantity}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(typeQuantity[entry.key]?.toStringAsFixed(2) ?? '0');
      typeRow++;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.amount}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(typeAmount[entry.key]?.toStringAsFixed(2) ?? '0');
      typeRow++;
      typeRow++; // Add spacing
    }

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow + 2))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow + 2))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Sorties_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateRetoursExcel({
    required List<Retour> retours,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Retours'];

    // ALL return fields - Export everything from the Retour model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.returnCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.product),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.purchasePrice),
      TextCellValue(l10n.salePrice),
      TextCellValue(l10n.type),
      TextCellValue(l10n.client),
      TextCellValue(l10n.fournisseur),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < retours.length; row++) {
      final retour = retours[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(retour.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(retour.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(retour.dateCree));
      // Product Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(retour.nomProduit ?? '-');
      // Quantity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(retour.quantite.toString());
      // Purchase Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(retour.prixAchat!.toStringAsFixed(2));
      // Sale Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(retour.prixVente!.toStringAsFixed(2));
      // Type (Client/Fournisseur - translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(
          retour.type == "Client" ? l10n.clientType : l10n.supplierType
      );
      // Client
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(retour.client ?? '-');
      // Supplier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(retour.fournisseur ?? '-');
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(retour.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(retour.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(retour.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(retour.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(retour.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(retour.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(retour.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(retour.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalQuantity = retours.fold(0.0, (sum, r) => sum + r.quantite);
    double totalPurchaseValue = retours.fold(0.0, (sum, r) => sum + (r.prixAchat! * r.quantite));
    double totalSaleValue     = retours.fold(0.0, (sum, r) => sum + (r.prixVente! * r.quantite));
    int activeRetours = retours.where((r) => r.etat).length;
    int inactiveRetours = retours.where((r) => !r.etat).length;
    int clientRetours = retours.where((r) => r.client != null && r.client!.isNotEmpty).length;
    int supplierRetours = retours.where((r) => r.fournisseur != null && r.fournisseur!.isNotEmpty).length;
    double avgQuantity = retours.isEmpty ? 0 : totalQuantity / retours.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalReturn);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(retours.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeRetours.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveRetours.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.clientReturns);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(clientRetours.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.supplierReturns);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(supplierRetours.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(totalQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalPurchaseValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalPurchaseValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.totalSaleValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(totalSaleValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.averageQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(avgQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 12))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 12))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Retours_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateBesoinListsExcel({
    required List<BesoinList> besoinLists,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['BesoinLists'];

    // ALL need list fields - Export everything from the BesoinList model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.listCode),
      TextCellValue(l10n.number),
      TextCellValue(l10n.date),
      TextCellValue(l10n.supplier),
      TextCellValue(l10n.amount),
      TextCellValue(l10n.items),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.description),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < besoinLists.length; row++) {
      final besoinList = besoinLists[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.code);
      // Number
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.numero ?? '-');
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(besoinList.date));
      // Supplier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.fournisseur ?? '-');
      // Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.montant?.toString() ?? '0');
      // Number of Items (Articles)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.nombreArticle?.toString() ?? '0');
      // Total Quantity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.quantite?.toString() ?? '0');
      // Description/Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(besoinList.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(besoinList.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(besoinList.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(besoinList.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalAmount = besoinLists.fold(0.0, (sum, l) => sum + (l.montant));
    int totalItems = besoinLists.fold(0, (sum, l) => sum + (l.nombreArticle));
    double totalQuantity = besoinLists.fold(0.0, (sum, l) => (l.quantite) + sum);
    int activeLists = besoinLists.where((l) => l.etat).length;
    int inactiveLists = besoinLists.where((l) => !l.etat).length;
    int supplierCount = besoinLists.where((l) =>  l.fournisseur.isNotEmpty).length;
    double avgAmount = besoinLists.isEmpty ? 0 : totalAmount / besoinLists.length;
    double avgItems = besoinLists.isEmpty ? 0 : totalItems / besoinLists.length;
    double avgQuantity = besoinLists.isEmpty ? 0 : totalQuantity / besoinLists.length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalLists);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(besoinLists.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeLists.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveLists.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.withSuppliers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(supplierCount.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.totalAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.totalItems);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(totalItems.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalQuantity.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.averageItems);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(avgItems.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        .value = TextCellValue(l10n.averageQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
        .value = TextCellValue(avgQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 13))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 13))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'BesoinLists_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateMouvementsExcel({
    required List<Mouvement> mouvements,
    required AppLocalizations l10n,
    required ListsConstTranslator translator,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Mouvements'];

    // ALL movement fields - Export everything from the Mouvement model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.movementCode),
      TextCellValue(l10n.date),
      TextCellValue(l10n.type),
      TextCellValue(l10n.client),
      TextCellValue(l10n.fournisseur),
      TextCellValue(l10n.product),
      TextCellValue(l10n.quantity),
      TextCellValue(l10n.purchasePrice),
      TextCellValue(l10n.salePrice),
      TextCellValue(l10n.totalAmount),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < mouvements.length; row++) {
      final mouvement = mouvements[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.code);
      // Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(mouvement.date));
      // Type (translated)
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(_getTranslatedMovementType(mouvement.type, l10n));
      // Client
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.client ?? '-');
      // Supplier
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.fournisseur ?? '-');
      // Product Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.nomProduit ?? '-');
      // Quantity
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.quantite.toString());
      // Purchase Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.prixAchat?.toStringAsFixed(2) ?? '0');
      // Sale Price
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.prixVente?.toStringAsFixed(2) ?? '0');
      // Total Amount
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue((mouvement.quantite * (mouvement.prixVente ?? 0)).toStringAsFixed(2));
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(mouvement.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(mouvement.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(mouvement.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(mouvement.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalQuantity      = mouvements.fold(0.0, (sum, m) => sum + m.quantite);
    double totalAmount        = mouvements.fold(0.0, (sum, m) => sum + (m.quantite * (m.prixVente ?? 0)));
    double totalPurchaseValue = mouvements.fold(0.0, (sum, m) => sum + (m.quantite * (m.prixAchat ?? 0)));
    int activeMouvements      = mouvements.where((m)  => m.etat).length;
    int inactiveMouvements    = mouvements.where((m)  => !m.etat).length;
    int clientMouvements      = mouvements.where((m)  => m.client != null && m.client!.isNotEmpty).length;
    int supplierMouvements    = mouvements.where((m)  => m.fournisseur != null && m.fournisseur!.isNotEmpty).length;
    double avgQuantity        = mouvements.isEmpty ? 0 : totalQuantity / mouvements.length;
    double avgAmount          = mouvements.isEmpty ? 0 : totalAmount / mouvements.length;

    // Group by type
    Map<String, int> typeCount = {};
    Map<String, double> typeQuantity = {};
    Map<String, double> typeAmount = {};

    for (var m in mouvements) {
      typeCount[m.type] = (typeCount[m.type] ?? 0) + 1;
      typeQuantity[m.type] = (typeQuantity[m.type] ?? 0) + m.quantite;
      typeAmount[m.type] = (typeAmount[m.type] ?? 0) + (m.quantite * (m.prixVente ?? 0));
    }

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalMovements);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(mouvements.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeMouvements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveMouvements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.clientMovements);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(clientMouvements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.supplierMovements);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(supplierMouvements.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.totalQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(totalQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalPurchaseValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalPurchaseValue.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.totalSaleValue);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(totalAmount.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.averageQuantity);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(avgQuantity.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 11))
        .value = TextCellValue(l10n.averageAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 11))
        .value = TextCellValue(avgAmount.toStringAsFixed(2));

    // Add breakdown by type
    int typeRow = 13;
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
        .value = TextCellValue(l10n.breakdownByType);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
        .cellStyle = CellStyle(bold: true, fontSize: 12);
    typeRow++;

    for (var entry in typeCount.entries) {
      final typeName = _getTranslatedMovementType(entry.key, l10n);
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.count}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(entry.value.toString());
      typeRow++;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.quantity}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(typeQuantity[entry.key]?.toStringAsFixed(2) ?? '0');
      typeRow++;

      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow))
          .value = TextCellValue("$typeName ${l10n.amount}");
      summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow))
          .value = TextCellValue(typeAmount[entry.key]?.toStringAsFixed(2) ?? '0');
      typeRow++;
      typeRow++; // Add spacing
    }

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: typeRow + 2))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: typeRow + 2))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Mouvements_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateUtilisateursExcel({
    required List<Utilisateur> utilisateurs,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Utilisateurs'];

    // ALL user fields - Export everything from the Utilisateur model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.userCode),
      TextCellValue(l10n.userName),
      TextCellValue(l10n.phone),
      TextCellValue(l10n.role),
      TextCellValue(l10n.credit),
      TextCellValue(l10n.lastAccess),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < utilisateurs.length; row++) {
      final utilisateur = utilisateurs[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.code);
      // Username
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.username);
      // Phone
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.telephone);
      // Role
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.role);
      // Credit
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue((utilisateur.credit ?? 0).toStringAsFixed(2));
      // Last Access
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.dernierAcces != null
          ? _formatDate(utilisateur.dernierAcces!)
          : '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(utilisateur.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(utilisateur.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(utilisateur.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(utilisateur.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeUsers = utilisateurs.where((u) => u.etat).length;
    int inactiveUsers = utilisateurs.where((u) => !u.etat).length;
    int adminUsers = utilisateurs.where((u) => u.role == "Admin").length;
    int cashierUsers = utilisateurs.where((u) => u.role == "Caissier").length;
    int storekeeperUsers = utilisateurs.where((u) => u.role == "Magasinier").length;
    double totalCredit = utilisateurs.fold(0.0, (sum, u) => sum + (u.credit ?? 0));

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalUsers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(utilisateurs.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeUsers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveUsers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.adminUsers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(adminUsers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.cashierUsers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(cashierUsers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.storekeeperUsers);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(storekeeperUsers.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.totalCredit);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(totalCredit.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Utilisateurs_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateRolesExcel({
    required List<Role> roles,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Roles'];

    // ALL role fields - Export everything from the Role model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.roleCode),
      TextCellValue(l10n.roleName),
      TextCellValue(l10n.description),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < roles.length; row++) {
      final role = roles[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(role.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(role.code);
      // Role Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(role.rolenom);
      // Description/Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(role.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(role.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(role.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(role.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(role.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(role.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(role.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(role.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeRoles = roles.where((r) => r.etat).length;
    int inactiveRoles = roles.where((r) => !r.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalRoles);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(roles.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeRoles.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveRoles.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Roles_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateMagasinsExcel({
    required List<Magasin> magasins,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Magasins'];

    // ALL store fields - Export everything from the Magasin model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.storeCode),
      TextCellValue(l10n.storeName),
      TextCellValue(l10n.address),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < magasins.length; row++) {
      final magasin = magasins[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(magasin.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(magasin.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(magasin.nom);
      // Address
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(magasin.adresse ?? '-');
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(magasin.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(magasin.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(magasin.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(magasin.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(magasin.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(magasin.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(magasin.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(magasin.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int activeStores = magasins.where((m) => m.etat).length;
    int inactiveStores = magasins.where((m) => !m.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalStores);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(magasins.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeStores.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveStores.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Magasins_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateGestionCaissesExcel({
    required List<CaisseGestion> caisses,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Caisses'];

    // ALL cash register fields - Export everything from the CaisseGestion model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.cashRegisterCode),
      TextCellValue(l10n.cashRegisterName),
      TextCellValue(l10n.store),
      TextCellValue(l10n.type),
      TextCellValue(l10n.initialBalance),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < caisses.length; row++) {
      final caisse = caisses[row];
      final rowIndex = row + 1;

      // Status
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(caisse.etat ? l10n.active : l10n.inactive);
      // Code
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(caisse.code);
      // Name
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(caisse.nomCaisse);
      // Store
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(caisse.magasin ?? '-');
      // Type
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(caisse.typecaisse ?? '-');
      // Initial Balance
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(caisse.soldeInitial.toStringAsFixed(2));
      // Observation
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(caisse.observation ?? '-');
      // Created At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(caisse.dateCree));
      // Created By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(caisse.creeParCode ?? '-');
      // Modified At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(caisse.dateModif));
      // Modified By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(caisse.modifPar ?? '-');
      // Cancelled At
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(caisse.dateAnnul));
      // Cancelled By
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(caisse.annulPar ?? '-');
      // Cancellation Reason
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(caisse.motifAnnul ?? '-');
      // Generation Date
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalBalance = caisses.fold(0.0, (sum, c) => sum + c.soldeInitial);
    int activeCaisses = caisses.where((c) => c.etat).length;
    int inactiveCaisses = caisses.where((c) => !c.etat).length;
    int storeCount = caisses.map((c) => c.magasin).where((m) => m != null && m!.isNotEmpty).toSet().length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalCaisses);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(caisses.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeCaisses.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveCaisses.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalBalance);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalBalance.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.averageBalance);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue((totalBalance / (caisses.isEmpty ? 1 : caisses.length)).toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.storesWithCaisses);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(storeCount.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Caisses_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateHistoriquesExcel({
    required List<Historique> historiques,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Historiques'];

    List<TextCellValue> headers = [
      TextCellValue(l10n.code),
      TextCellValue(l10n.typeOperation),
      TextCellValue(l10n.operationOn),
      TextCellValue(l10n.description),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.creatorCode),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < historiques.length; row++) {
      final historique = historiques[row];
      final rowIndex = row + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(historique.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(_getTranslatedOperation(historique.oper, l10n));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(_getTranslatedType(historique.type, l10n));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(historique.observation ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(historique.creeParCode ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(historique.creeParCode ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(historique.dateCree));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    int insertions = historiques.where((h) => h.oper == "insertion").length;
    int modifications = historiques.where((h) => h.oper == "modification").length;
    int deletions = historiques.where((h) => h.oper == "suppression").length;
    int logins = historiques.where((h) => h.oper == "login").length;
    int logouts = historiques.where((h) => h.oper == "logout").length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalRecords);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(historiques.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.insertions);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(insertions.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.modifications);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(modifications.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.deletions);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(deletions.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.logins);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(logins.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.logouts);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(logouts.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 9))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 9))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Historiques_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }

  static Future<File> generateZakatExcel({
    required List<Zakat> zakats,
    required AppLocalizations l10n,
  }) async
  {
    var excel = Excel.createExcel();

    var sheet = excel['Zakat'];

    // ALL zakat fields - Export everything from the Zakat model
    List<TextCellValue> headers = [
      TextCellValue(l10n.status),
      TextCellValue(l10n.code),
      TextCellValue(l10n.year),
      TextCellValue(l10n.stock),
      TextCellValue(l10n.cash),
      TextCellValue(l10n.receivables),
      TextCellValue(l10n.debts),
      TextCellValue(l10n.totalCapital),
      TextCellValue(l10n.nissab),
      TextCellValue(l10n.rate),
      TextCellValue(l10n.zakatAmount),
      TextCellValue(l10n.mandatory),
      TextCellValue(l10n.statusField),
      TextCellValue(l10n.hawlStart),
      TextCellValue(l10n.dueDate),
      TextCellValue(l10n.paymentDate),
      TextCellValue(l10n.observation),
      TextCellValue(l10n.createdAt),
      TextCellValue(l10n.createdBy),
      TextCellValue(l10n.modifiedAt),
      TextCellValue(l10n.modifiedBy),
      TextCellValue(l10n.cancelledAt),
      TextCellValue(l10n.cancelledBy),
      TextCellValue(l10n.cancellationReason),
      TextCellValue(l10n.generationDate),
    ];

    // Add headers
    for (int i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = headers[i];
      cell.cellStyle = CellStyle(
        bold: true,
        horizontalAlign: HorizontalAlign.Center,
      );
    }

    // Add data rows
    for (int row = 0; row < zakats.length; row++) {
      final zakat = zakats[row];
      final rowIndex = row + 1;

      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex))
          .value = TextCellValue(zakat.etat ? l10n.active : l10n.inactive);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex))
          .value = TextCellValue(zakat.code);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex))
          .value = TextCellValue(zakat.annee.toString());
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: rowIndex))
          .value = TextCellValue(zakat.stock.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: rowIndex))
          .value = TextCellValue(zakat.liquidites.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: rowIndex))
          .value = TextCellValue(zakat.creances.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: rowIndex))
          .value = TextCellValue(zakat.dettes.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 7, rowIndex: rowIndex))
          .value = TextCellValue(zakat.capitalTotal.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 8, rowIndex: rowIndex))
          .value = TextCellValue(zakat.nissab.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 9, rowIndex: rowIndex))
          .value = TextCellValue(zakat.taux.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 10, rowIndex: rowIndex))
          .value = TextCellValue(zakat.montantZakat.toStringAsFixed(2));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 11, rowIndex: rowIndex))
          .value = TextCellValue(zakat.obligatoire ? l10n.yes : l10n.no);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 12, rowIndex: rowIndex))
          .value = TextCellValue(zakat.statut);
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 13, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.dateDebutHawl));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 14, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.dateZakatDue));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 15, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.datePaiement));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 16, rowIndex: rowIndex))
          .value = TextCellValue(zakat.observation ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 17, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.dateCree));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 18, rowIndex: rowIndex))
          .value = TextCellValue(zakat.creeParCode ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 19, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.dateModif));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 20, rowIndex: rowIndex))
          .value = TextCellValue(zakat.modifPar ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 21, rowIndex: rowIndex))
          .value = TextCellValue(_formatDate(zakat.dateAnnul));
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 22, rowIndex: rowIndex))
          .value = TextCellValue(zakat.annulPar ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 23, rowIndex: rowIndex))
          .value = TextCellValue(zakat.motifAnnul ?? '-');
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 24, rowIndex: rowIndex))
          .value = TextCellValue(_formatDateTime(DateTime.now()));
    }

    // Set column widths
    for (int i = 0; i < headers.length; i++) {
      sheet.setColumnWidth(i, 20);
    }

    // Create summary sheet
    var summarySheet = excel['Summary'];

    double totalZakat = zakats.fold(0.0, (sum, z) => sum + z.montantZakat);
    int paidZakat = zakats.where((z) => z.statut == "PAYEE").length;
    int unpaidZakat = zakats.where((z) => z.statut != "PAYEE").length;
    int mandatoryZakat = zakats.where((z) => z.obligatoire).length;
    int activeZakat = zakats.where((z) => z.etat).length;
    int inactiveZakat = zakats.where((z) => !z.etat).length;

    var titleCell = summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0));
    titleCell.value = TextCellValue(l10n.summary);
    titleCell.cellStyle = CellStyle(bold: true, fontSize: 14);

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 2))
        .value = TextCellValue(l10n.totalZakatRecords);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 2))
        .value = TextCellValue(zakats.length.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 3))
        .value = TextCellValue(l10n.active);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 3))
        .value = TextCellValue(activeZakat.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 4))
        .value = TextCellValue(l10n.inactive);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 4))
        .value = TextCellValue(inactiveZakat.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 5))
        .value = TextCellValue(l10n.totalZakatAmount);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 5))
        .value = TextCellValue(totalZakat.toStringAsFixed(2));

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 6))
        .value = TextCellValue(l10n.paidZakat);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 6))
        .value = TextCellValue(paidZakat.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 7))
        .value = TextCellValue(l10n.unpaidZakat);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 7))
        .value = TextCellValue(unpaidZakat.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 8))
        .value = TextCellValue(l10n.mandatoryZakat);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 8))
        .value = TextCellValue(mandatoryZakat.toString());

    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 10))
        .value = TextCellValue(l10n.generationDate);
    summarySheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: 10))
        .value = TextCellValue(_formatDateTime(DateTime.now()));

    summarySheet.setColumnWidth(0, 30);
    summarySheet.setColumnWidth(1, 20);

    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'Zakat_${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final filePath = '${directory.path}/$fileName';

    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    return file;
  }
  static String _formatDate(DateTime? date) {
    if (date == null) return '-';

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _formatDateTime(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  static Future<void> openExcel(File file) async {
    await OpenFile.open(file.path);
  }

  static Future<void> shareExcel(File file) async {
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Clients Export',
      subject: 'Clients List',
    );
  }


  static String _getTranslatedMovementType(String type, AppLocalizations l10n) {
    switch (type) {
      case "Vente":
        return l10n.sale;
      case "Achat":
        return l10n.purchase;
      case "Retour":
        return l10n.return_;
      case "Déstockage":
        return l10n.destocking;
      default:
        return type;
    }
  }

  static String _getTranslatedOperation(String oper, AppLocalizations l10n) {
    switch (oper) {
      case 'insertion':
        return l10n.insertion;
      case 'modification':
        return l10n.modification;
      case 'suppression':
        return l10n.deletion;
      case 'login':
        return l10n.login;
      case 'logout':
        return l10n.logout;
      default:
        return oper;
    }
  }

  static String _getTranslatedType(String type, AppLocalizations l10n) {
    switch (type) {
      case 'produit':
        return l10n.product;
      case 'client':
        return l10n.client;
      case 'fournisseur':
        return l10n.supplier;
      case 'caisse':
        return l10n.caisse;
      case 'panier':
        return l10n.panier;
      case 'versement':
        return l10n.versement;
      case 'transfert':
        return l10n.transfert;
      case 'zakat':
        return l10n.zakat;
      case 'utilisateur':
        return l10n.user;
      case 'role':
        return l10n.role;
      case 'magasin':
        return l10n.store;
      case 'categorie':
        return l10n.category;
      case 'souscategorie':
        return l10n.sousCategorie;
      case 'pack':
        return l10n.pack;
      case 'remise':
        return l10n.discount;
      case 'besoin':
        return l10n.need;
      default:
        return type;
    }
  }
}