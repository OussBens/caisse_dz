import 'package:caisse_dz/core/widget/status_badge.dart';
import 'dart:ui';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/pannier/pannier_detail.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../Services/Client.dart';
import '../../../Services/Verssement.dart';
import '../../../data/models/verssement.dart';
import '../information_dialog.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

Future<void> DialogPannierVendu({
  required BuildContext context,
  required String caisseName,
}) async {
  final auth = Provider.of<AuthState>(context, listen: false);
  final userName = auth.username ?? '';
  final userCode = auth.userCode ?? '';

  // Charger les données
  final db = await DbCreator.openDb();
  final pannierService = PannierServices(db);
  final allPanniers = await PannierServices.getAllPanniers();
  final versements = await VerssementServices.getAllverssement();
  double resteDe(Pannier p) => p.montant - PannierServices.calculerVerse(versements, p.code);

  // Filtrer les paniers de la caisse actuelle
  List<Pannier> panniersCaisse = allPanniers
      .where((p) => p.caisse == caisseName && p.typepannier != "SmartScan")
      .toList();

  // Charger les clients pour les filtres
  final clients = await ClientServices.getAllClients();
  final clientNames = clients.map((c) => c.nom).toList();

  // État des filtres
  DateTime dateDebut = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime dateFin = DateTime.now();

  String? selectedClientFilter;
  String? selectedModePaiementFilter;
  String? selectedTypePannierFilter;
  String? selectedEtatFilter;

  double? montantMin;
  double? montantMax;
  double? resteMin;
  double? resteMax;

  String searchText = "";

  final searchController = TextEditingController();

  // Options pour les listes déroulantes
  final modePaiementOptions = ["Espèces", "Chèque", "Carte bancaire", "Virement"];
  final etatOptions = ["Actif", "Inactif"];

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;
          final translator = ListsConstTranslator(l10n);

          // Appliquer les filtres
          List<Pannier> panniersFiltres = panniersCaisse.where((p) {
            final dateOk = !p.date.isBefore(dateDebut) && !p.date.isAfter(dateFin);
            final clientOk = selectedClientFilter == null || selectedClientFilter!.isEmpty || clients.any((c) => c.code == p.client_code && c.nom == selectedClientFilter);
            final modeOk = selectedModePaiementFilter == null || selectedModePaiementFilter!.isEmpty || p.modePaiement == selectedModePaiementFilter;
            final typeOk = selectedTypePannierFilter == null || selectedTypePannierFilter!.isEmpty || p.typepannier == selectedTypePannierFilter;
            final etatOk = selectedEtatFilter == null || selectedEtatFilter!.isEmpty ||
                (selectedEtatFilter == "Actif" && p.etat) ||
                (selectedEtatFilter == "Inactif" && !p.etat);
            final montantOk = (montantMin == null || p.montant >= montantMin!) &&
                (montantMax == null || p.montant <= montantMax!);
            final reste = resteDe(p);
            final resteOk = (resteMin == null || reste >= resteMin!) &&
                (resteMax == null || reste <= resteMax!);
            final searchOk = searchText.isEmpty ||
                p.code!.toLowerCase().contains(searchText.toLowerCase()) ||
                (clients.firstWhereOrNull((c) => c.code == p.client_code)?.nom ?? '').toLowerCase().contains(searchText.toLowerCase());

            return dateOk && clientOk && modeOk && typeOk && etatOk && montantOk && resteOk && searchOk;
          }).toList();

          panniersFiltres.sort((a, b) => b.date.compareTo(a.date));
          // Totaux = paniers actifs uniquement (les paniers annulés restent
          // listés, avec leur état).
          final panniersActifs = panniersFiltres.where((p) => p.etat).toList();

          Future<void> exportExcel() async {
            if (panniersFiltres.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.panier,
                message: l10n.noDataToExport,
              );
              return;
            }

            final fermerSpinner = ouvrirSpinnerExport(context);
            try {

              final translator = ListsConstTranslator(l10n);
              final excelFile = await ExcelGenerator.generatePanniersExcel(
                panniers: panniersFiltres,
                versements: versements,
                l10n: l10n,
                translator: translator,
              );

              fermerSpinner();

              final excel = Excel.decodeBytes(await excelFile.readAsBytes());
              var sheet = excel.tables['Panniers'];
              if (sheet == null && excel.tables.isNotEmpty) sheet = excel.tables.values.first;
              if (sheet == null) return;

              final headers = <String>[];
              for (int col = 0; col < sheet.maxColumns; col++) {
                final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
                if (cell.value != null && cell.value.toString().isNotEmpty) headers.add(cell.value.toString());
              }

              final data = <List<dynamic>>[];
              for (int row = 1; row < sheet.maxRows; row++) {
                final rowData = <dynamic>[];
                bool hasData = false;
                for (int col = 0; col < sheet.maxColumns; col++) {
                  final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row));
                  if (cell.value != null && cell.value.toString().isNotEmpty) {
                    rowData.add(cell.value);
                    hasData = true;
                  } else {
                    rowData.add('-');
                  }
                }
                if (hasData) data.add(rowData);
              }

              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => ExcelPreviewDialog(
                  data: data,
                  headers: headers,
                  title: caisseName,
                  l10n: l10n,
                  excelFile: excelFile,
                  onSave: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Colors.green),
                    );
                  },
                  onShare: () => Navigator.pop(context),
                  onCancel: () => Navigator.pop(context),
                ),
              );
            } catch (e) {
              fermerSpinner();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: Colors.red),
              );
            }
          }

          Future<void> exportPdf() async {
            if (panniersFiltres.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.panier,
                message: l10n.noDataToExport,
              );
              return;
            }

            final pdfBytes = await PDFTableGenerator.generateTableReport(
              title: "${l10n.cashReceipt} - $caisseName",
              subtitleLines: [
                "${l10n.numberOfSales}: ${panniersActifs.length}    "
                    "${l10n.totalSales}: ${NumberFormatUtil.formatMontant(panniersActifs.fold(0.0, (sum, p) => sum + p.montant), decimales: 2)} ${l10n.currency}",
              ],
              headers: [
                l10n.code,
                l10n.date,
                l10n.client,
                l10n.typePannier,
                l10n.amount,
                l10n.paid,
                l10n.remaining,
                l10n.status,
              ],
              rows: panniersFiltres.map((p) {
                final reste = resteDe(p);
                return [
                  p.code ?? '',
                  _formatDate(p.date),
                  clients.firstWhereOrNull((c) => c.code == p.client_code)?.nom ?? '',
                  p.typepannier ?? '',
                  NumberFormatUtil.formatMontant(p.montant, decimales: 2),
                  NumberFormatUtil.formatMontant((p.montant - reste), decimales: 2),
                  NumberFormatUtil.formatMontant(reste, decimales: 2),
                  p.etat ? l10n.active : l10n.inactive,
                ];
              }).toList(),
            );

            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => PDFPreviewDialog(
                pdfBytes: pdfBytes,
                l10n: l10n,
                onPrint: () async {
                  Navigator.pop(context);
                  await PDFGeneratorLatin.printPDF(pdfBytes);
                },
                onSave: () async {
                  final file = await PDFGeneratorLatin.savePDF(
                    pdfBytes,
                    'RecetteCaisse_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Colors.green),
                  );
                  await PDFGeneratorLatin.openPDF(file);
                },
                onShare: () => Navigator.pop(context),
                onCancel: () => Navigator.pop(context),
              ),
            );
          }

          return ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
              child: BaseDialog(
                width: 1200,
                height: 900,
                header: TitreAvecLigne(
                  imagePath: 'assets/icons/sidebar/pannier_icon.png',
                  text: "${l10n.cashReceipt} - $caisseName - ${_formatDate(dateDebut)}",
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section des filtres
                    SectionDecorationFiltre(
                      padding: const EdgeInsets.all(10),
                      color: Appstyle.Tblanc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // LIGNE 1 : Client + Mode paiement + Type panier
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.client,
                                  child: TextListe(
                                    value: selectedClientFilter,
                                    items: clientNames,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedClientFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.payment,
                                  child: TextListe(
                                    value: selectedModePaiementFilter,
                                    items: modePaiementOptions,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedModePaiementFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.typePannier,
                                  child: TextListe(
                                    value: selectedTypePannierFilter != null
                                        ? translator.translateTypePannier(selectedTypePannierFilter!)
                                        : null,
                                    items: translator.typePannierDisplayList,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedTypePannierFilter = v == null || v.isEmpty ? null : translator.typePannierToFrench(v);
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // LIGNE 2 : Montant + Reste + Status
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.amount,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: montantMin,
                                    maxValue: montantMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        montantMin = min;
                                        montantMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.remaining,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: resteMin,
                                    maxValue: resteMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        resteMin = min;
                                        resteMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.status,
                                  child: TextListe(
                                    value: selectedEtatFilter,
                                    items: etatOptions,
                                    clearable: true,
                                    onChanged: (v) {
                                      setState(() {
                                        selectedEtatFilter = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // LIGNE 3 : Recherche + Bouton réinitialiser
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ChampAvecLabel(
                                  label: l10n.search,
                                  child: SearchField(
                                    controller: searchController,
                                    onChanged: (v) {
                                      setState(() {
                                        searchText = v;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 1,
                                child: Align(
                                  alignment: Alignment.bottomRight,
                                  child: MainButton(
                                    text: l10n.clearFilters,
                                    color: Appstyle.gris,
                                    icon: Icons.clear_all,
                                    onPressed: () {
                                      setState(() {
                                        selectedClientFilter = null;
                                        selectedModePaiementFilter = null;
                                        selectedTypePannierFilter = null;
                                        selectedEtatFilter = null;
                                        montantMin = null;
                                        montantMax = null;
                                        resteMin = null;
                                        resteMax = null;
                                        searchText = "";
                                        searchController.clear();
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 15),

                    // Boutons d'export
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        MainButton(
                          text: l10n.extract,
                          textColor: Colors.green,
                          iconColor: Colors.green,
                          color: Appstyle.Tblanc,
                          icon: Icons.download,
                          onPressed: () async => await exportExcel(),
                        ),
                        const SizedBox(width: 10),
                        MainButton(
                          text: l10n.extractPdf,
                          textColor: Colors.red,
                          iconColor: Colors.red,
                          color: Appstyle.Tblanc,
                          icon: Icons.picture_as_pdf,
                          onPressed: () async => await exportPdf(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    // Compteur des résultats
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Appstyle.violet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${l10n.numberOfSales}: ${panniersActifs.length}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                          ),
                          Text(
                            "${l10n.totalSales}: ${NumberFormatUtil.formatMontant(panniersActifs.fold(0.0, (sum, p) => sum + p.montant), decimales: 2)} ${l10n.currency}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Liste des paniers
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: panniersFiltres.isEmpty
                            ? Center(
                          child: Text(
                            l10n.noSalesFound,
                            style: Appstyle.textM.copyWith(color: Appstyle.gris),
                          ),
                        )
                            : ListView.builder(
                          itemCount: panniersFiltres.length,
                          itemBuilder: (context, index) {
                            final p = panniersFiltres[index];
                            return _pannierTile(
                              context: context,
                              pannier: p,
                              reste: resteDe(p),
                              nomClient: clients.firstWhereOrNull((c) => c.code == p.client_code)?.nom ?? '',
                              l10n: l10n,
                              onDetail: () async {
                                await PannierDetail(context, p);
                              },
                              onShowProducts: () async {
                                await _showProductsListDialog(context, p, l10n);
                              },
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                footer: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    MainButton(
                      text: l10n.close,
                      color: Appstyle.gris,
                      icon: Icons.close,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

/// Widget pour afficher une ligne de panier
Widget _pannierTile({
  required BuildContext context,
  required Pannier pannier,
  required double reste,
  required String nomClient,
  required AppLocalizations l10n,
  required VoidCallback onDetail,
  required VoidCallback onShowProducts,
}) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.grey.shade200),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.withOpacity(0.05),
          blurRadius: 2,
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pannier.code ?? "",
                style: Appstyle.textSB.copyWith(
                  color: Appstyle.violet,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "${pannier.date.day}/${pannier.date.month}/${pannier.date.year}",
                style: Appstyle.textXS.copyWith(color: Appstyle.gris),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            nomClient,
            style: Appstyle.textS,
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(pannier.typepannier).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  pannier.typepannier == "Ticket" ? l10n.ticket : l10n.facture,
                  style: Appstyle.textXS.copyWith(
                    color: _getTypeColor(pannier.typepannier),
                  ),
                ),
              ),
              Text(
                pannier.modePaiement ?? "",
                style: Appstyle.textXS.copyWith(color: Appstyle.gris),
              ),
            ],
          ),
        ),
        // État du panier (actif / annulé).
        Expanded(
          flex: 1,
          child: Align(
            alignment: Alignment.centerLeft,
            child: EtatBadge(isActive: pannier.etat),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${NumberFormatUtil.formatMontant(pannier.montant, decimales: 2)} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet),
              ),
              if (reste > 0)
                Text(
                  "${l10n.remaining}: ${NumberFormatUtil.formatMontant(reste, decimales: 2)}",
                  style: Appstyle.textXS.copyWith(color: Colors.orange),
                ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.info_outline, size: 20),
              color: Appstyle.violet,
              onPressed: onDetail,
              tooltip: l10n.details,
            ),
            IconButton(
              icon: const Icon(Icons.list, size: 20),
              color: Appstyle.crevete,
              onPressed: onShowProducts,
              tooltip: l10n.productsList,
            ),
          ],
        ),
      ],
    ),
  );
}

/// Afficher la liste des produits d'un panier
Future<void> _showProductsListDialog(BuildContext context, Pannier pannier, AppLocalizations l10n) async {
  final db = await DbCreator.openDb();
  final ppService = PPServices(db);
  final produits = await ppService.getPPByCodePannier(pannier.code!);
  final catalogueProduits = await ProduitServices.getAllProduits();
  String nomProduit(String code) =>
      catalogueProduits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;
  final catalogueClients = await ClientServices.getAllClients();
  final nomClientPannier = catalogueClients.firstWhereOrNull((c) => c.code == pannier.client_code)?.nom ?? '';

  showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.4),
    builder: (_) {
      return BaseDialog(
        width: 700,
        height: 550,
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.productsOfCart(pannier.code),
              style: Appstyle.textLB,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("${l10n.client} : $nomClientPannier", style: Appstyle.textSB),
                Text("${l10n.date} : ${pannier.date.toString().split(" ").first}", style: Appstyle.textSB),
              ],
            ),
            Text("${l10n.total} : ${pannier.montant ?? 0} ${l10n.currency}",
                style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
          ],
        ),
        content: produits.isEmpty
            ? Center(
          child: Text(
            l10n.noProducts,
            style: Appstyle.textSB.copyWith(color: Appstyle.gris),
          ),
        )
            : LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Appstyle.violet.withOpacity(0.1)),
                  headingTextStyle: Appstyle.textSB.copyWith(color: Appstyle.violet),
                  columns: [
                    DataColumn(label: Text(l10n.productCode)),
                    DataColumn(label: Text(l10n.productName)),
                    DataColumn(label: Text(l10n.quantity), numeric: true),
                    DataColumn(label: Text(l10n.price), numeric: true),
                    DataColumn(label: Text(l10n.total), numeric: true),
                  ],
                  rows: produits.map((p) {
                    return DataRow(
                      cells: [
                        DataCell(Text(p.codeProduit ?? "")),
                        DataCell(Text(nomProduit(p.codeProduit))),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Appstyle.violet.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${p.quantite ?? 0}",
                              style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                            ),
                          ),
                        ),
                        DataCell(Text(NumberFormatUtil.formatMontant(p.prix ?? 0, decimales: 2))),
                        DataCell(
                          Text(
                            NumberFormatUtil.formatMontant(p.total ?? 0, decimales: 2),
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          },
        ),
        footer: Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            icon: Icon(Icons.close, color: Appstyle.Tblanc),
            label: Text(l10n.close, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Appstyle.violet,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      );
    },
  );
}

/// Obtenir la couleur selon le type de panier (BL et BL_SC = Facture)
Color _getTypeColor(String? type) {
  switch (type) {
    case "Ticket":
      return Appstyle.violet;
    case "BL":
    case "BL_SC":
      return Appstyle.green;
    default:
      return Appstyle.gris;
  }
}

/// Formater une date
String _formatDate(DateTime d) {
  return "${d.day.toString().padLeft(2, '0')}/"
      "${d.month.toString().padLeft(2, '0')}/"
      "${d.year}";
}