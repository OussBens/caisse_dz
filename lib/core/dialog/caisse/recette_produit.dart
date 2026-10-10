import 'package:caisse_dz/core/widget/status_badge.dart';
import 'dart:ui';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/DBCreate.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/PannierProduit.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/SousCategories.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:collection/collection.dart';
import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/pannier_produit.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Une ligne de recette produit : un produit vendu dans un panier de la
/// caisse (un panier de N produits devient N lignes).
class _LigneRecetteProduit {
  final String codePannier;
  final String nomClient;
  final String codeProduit;
  final String nomProduit;
  final int? sousCategorieId;
  final double quantite;
  final double prix;
  final double montant;
  final String nomCaissier;
  // Ligne de vente ET panier non annulés.
  final bool actif;

  const _LigneRecetteProduit({
    required this.codePannier,
    required this.nomClient,
    required this.codeProduit,
    required this.nomProduit,
    required this.sousCategorieId,
    required this.quantite,
    required this.prix,
    required this.montant,
    required this.nomCaissier,
    required this.actif,
  });

  String get searchableText =>
      "$codePannier $nomClient $codeProduit $nomProduit $nomCaissier".toLowerCase();
}

Future<void> DialogRecetteProduit({
  required BuildContext context,
  required String caisseName,
}) async {
  final db = await DbCreator.openDb();
  final ppService = PPServices(db);

  // Comme la recette panier (pannier_vendu.dart) : uniquement les ventes
  // du jour en cours.
  final now = DateTime.now();
  final debutJour = DateTime(now.year, now.month, now.day);
  final allPanniers = await PannierServices.getAllPanniers();
  final panniersCaisse = allPanniers
      .where((p) => p.caisse == caisseName && p.typepannier != "SmartScan")
      .where((p) => !p.date.isBefore(debutJour) && !p.date.isAfter(now))
      .toList();
  final codesPanniersCaisse = panniersCaisse.map((p) => p.code).toSet();

  final allPannierProduits = await PPServices.getAllPP();
  final clients = await ClientServices.getAllClients();
  final produits = await ProduitServices.getAllProduits();
  final sousCategories = await SousCategoriesServices.getAllSousCategorie();
  final utilisateurs = await UtilisateurServices.getAllUtilisateurs();

  String nomProduit(String code) => produits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;
  int? sousCategorieProduit(String code) => produits.firstWhereOrNull((p) => p.code == code)?.sousCategorieId;
  String nomClient(String? code) => clients.firstWhereOrNull((c) => c.code == code)?.nom ?? '';
  String nomCaissier(String code) => utilisateurs.firstWhereOrNull((u) => u.code == code)?.username ?? code;

  final Map<String, Pannier> pannierParCode = {
    for (final p in panniersCaisse) if (p.code != null) p.code!: p,
  };

  final lignes = allPannierProduits
      .where((pp) => codesPanniersCaisse.contains(pp.codePannier))
      .map((pp) {
    final pannier = pannierParCode[pp.codePannier];
    return _LigneRecetteProduit(
      codePannier: pp.codePannier,
      nomClient: nomClient(pannier?.client_code),
      codeProduit: pp.codeProduit,
      nomProduit: nomProduit(pp.codeProduit),
      sousCategorieId: sousCategorieProduit(pp.codeProduit),
      quantite: pp.quantite,
      prix: pp.prix,
      montant: pp.total,
      nomCaissier: nomCaissier(pannier?.caissier_code ?? ''),
      actif: pp.etat && (pannier?.etat ?? true),
    );
  }).toList();

  final produitOptions = produits.map((p) => p.nom).toSet().toList();
  final sousCategorieOptions = sousCategories.map((sc) => sc.nom).toSet().toList();

  String? selectedProduitFilter;
  String? selectedSousCategorieFilter;
  double? quantiteMin;
  double? quantiteMax;
  double? prixMin;
  double? prixMax;
  String searchText = "";
  final searchController = TextEditingController();

  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) {
      return StatefulBuilder(
        builder: (context, setState) {
          final l10n = AppLocalizations.of(context)!;

          final lignesFiltrees = lignes.where((l) {
            final produitOk = selectedProduitFilter == null ||
                selectedProduitFilter!.isEmpty ||
                l.nomProduit == selectedProduitFilter;
            final sousCategorieOk = selectedSousCategorieFilter == null ||
                selectedSousCategorieFilter!.isEmpty ||
                sousCategories.firstWhereOrNull((sc) => sc.id == l.sousCategorieId)?.nom == selectedSousCategorieFilter;
            final quantiteOk = (quantiteMin == null || l.quantite >= quantiteMin!) &&
                (quantiteMax == null || l.quantite <= quantiteMax!);
            final prixOk = (prixMin == null || l.prix >= prixMin!) &&
                (prixMax == null || l.prix <= prixMax!);
            final searchOk = searchText.isEmpty || l.searchableText.contains(searchText.toLowerCase());

            return produitOk && sousCategorieOk && quantiteOk && prixOk && searchOk;
          }).toList();
          // Totaux = ventes actives uniquement (les lignes annulées restent
          // affichées, avec leur état).
          final lignesActives = lignesFiltrees.where((l) => l.actif).toList();

          Future<void> exportExcel() async {
            if (lignesFiltrees.isEmpty) {
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

              final clesFiltrees = lignesFiltrees.map((l) => '${l.codePannier}|${l.codeProduit}').toSet();
              final pannierProduitsAExporter = allPannierProduits
                  .where((pp) => clesFiltrees.contains('${pp.codePannier}|${pp.codeProduit}'))
                  .toList();

              final excelFile = await ExcelGenerator.generateRecetteCaisseProduitExcel(
                lignes: pannierProduitsAExporter,
                panniers: panniersCaisse,
                produits: produits,
                utilisateurs: utilisateurs,
                l10n: l10n,
              );

              fermerSpinner();

              final excel = Excel.decodeBytes(await excelFile.readAsBytes());
              var sheet = excel.tables['RecetteCaisseProduit'];
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
                      SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Appstyle.success),
                    );
                  },
                  onShare: () => Navigator.pop(context),
                  onCancel: () => Navigator.pop(context),
                ),
              );
            } catch (e) {
              fermerSpinner();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: Appstyle.danger),
              );
            }
          }

          Future<void> exportPdf() async {
            if (lignesFiltrees.isEmpty) {
              await InformationDialog(
                context: context,
                titre_type_message: l10n.information,
                titre_concerne: l10n.panier,
                message: l10n.noDataToExport,
              );
              return;
            }

            final pdfBytes = await PDFTableGenerator.generateTableReport(
              title: "${l10n.productRevenue} - $caisseName",
              subtitleLines: [
                "${l10n.date}: ${debutJour.day.toString().padLeft(2, '0')}/${debutJour.month.toString().padLeft(2, '0')}/${debutJour.year}    "
                    "${l10n.numberOfSales}: ${lignesActives.length}    "
                    "${l10n.totalSales}: ${NumberFormatUtil.formatMontant(lignesActives.fold(0.0, (sum, l) => sum + l.montant), decimales: 2)} ${l10n.currency}",
              ],
              headers: [
                l10n.panierCode,
                l10n.client,
                l10n.productCode,
                l10n.productName,
                l10n.quantity,
                l10n.price,
                l10n.amount,
                l10n.cashier,
                l10n.status,
              ],
              rows: lignesFiltrees.map((l) => [
                l.codePannier,
                l.nomClient,
                l.codeProduit,
                l.nomProduit,
                NumberFormatUtil.formatMontant(l.quantite, decimales: 0),
                NumberFormatUtil.formatMontant(l.prix, decimales: 2),
                NumberFormatUtil.formatMontant(l.montant, decimales: 2),
                l.nomCaissier,
                l.actif ? l10n.active : l10n.inactive,
              ]).toList(),
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
                    'RecetteCaisseProduit_${DateTime.now().millisecondsSinceEpoch}.pdf',
                  );
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.exportSuccess), backgroundColor: Appstyle.success),
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
                  imagePath: 'assets/icons/sidebar/produit_icon.png',
                  text: "${l10n.productRevenue} - $caisseName - "
                      "${debutJour.day.toString().padLeft(2, '0')}/${debutJour.month.toString().padLeft(2, '0')}/${debutJour.year}",
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionDecorationFiltre(
                      padding: const EdgeInsets.all(10),
                      color: Appstyle.Tblanc,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.product,
                                  child: TextListe(
                                    value: selectedProduitFilter,
                                    items: produitOptions,
                                    clearable: true,
                                    onChanged: (v) => setState(() => selectedProduitFilter = v),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.sousCategorie,
                                  child: TextListe(
                                    value: selectedSousCategorieFilter,
                                    items: sousCategorieOptions,
                                    clearable: true,
                                    onChanged: (v) => setState(() => selectedSousCategorieFilter = v),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.quantity,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: quantiteMin,
                                    maxValue: quantiteMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        quantiteMin = min;
                                        quantiteMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ChampAvecLabel(
                                  label: l10n.salePrice,
                                  child: FourchettePrixWidget(
                                    couleur: Appstyle.violet,
                                    minValue: prixMin,
                                    maxValue: prixMax,
                                    onChanged: (min, max) {
                                      setState(() {
                                        prixMin = min;
                                        prixMax = max;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: ChampAvecLabel(
                                  label: l10n.search,
                                  child: SearchField(
                                    controller: searchController,
                                    onChanged: (v) => setState(() => searchText = v),
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
                                        selectedProduitFilter = null;
                                        selectedSousCategorieFilter = null;
                                        quantiteMin = null;
                                        quantiteMax = null;
                                        prixMin = null;
                                        prixMax = null;
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

                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        MainButton(
                          text: l10n.extract,
                          textColor: Appstyle.success,
                          iconColor: Appstyle.success,
                          color: Appstyle.Tblanc,
                          icon: Icons.download,
                          onPressed: () async => await exportExcel(),
                        ),
                        const SizedBox(width: 10),
                        MainButton(
                          text: l10n.extractPdf,
                          textColor: Appstyle.danger,
                          iconColor: Appstyle.danger,
                          color: Appstyle.Tblanc,
                          icon: Icons.picture_as_pdf,
                          onPressed: () async => await exportPdf(),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Appstyle.violet.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(Appstyle.radiusSM),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "${l10n.numberOfSales}: ${lignesActives.length}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.violet),
                          ),
                          Text(
                            "${l10n.totalSales}: ${NumberFormatUtil.formatMontant(lignesActives.fold(0.0, (sum, l) => sum + l.montant), decimales: 2)} ${l10n.currency}",
                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
                          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                        ),
                        child: lignesFiltrees.isEmpty
                            ? Center(
                          child: Text(
                            l10n.noSalesFound,
                            style: Appstyle.textM.copyWith(color: Appstyle.gris),
                          ),
                        )
                            : LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: DataTable(
                                    headingRowColor: MaterialStateProperty.all(Appstyle.violet.withOpacity(0.1)),
                                    headingTextStyle: Appstyle.textSB.copyWith(color: Appstyle.violet),
                                    columns: [
                                      DataColumn(label: Text(l10n.panierCode)),
                                      DataColumn(label: Text(l10n.client)),
                                      DataColumn(label: Text(l10n.productCode)),
                                      DataColumn(label: Text(l10n.productName)),
                                      DataColumn(label: Text(l10n.quantity), numeric: true),
                                      DataColumn(label: Text(l10n.price), numeric: true),
                                      DataColumn(label: Text(l10n.amount), numeric: true),
                                      DataColumn(label: Text(l10n.cashier)),
                                      DataColumn(label: Text(l10n.status)),
                                    ],
                                    rows: lignesFiltrees.map((l) {
                                      return DataRow(cells: [
                                        DataCell(Text(l.codePannier)),
                                        DataCell(Text(l.nomClient)),
                                        DataCell(Text(l.codeProduit)),
                                        DataCell(Text(l.nomProduit)),
                                        DataCell(Text(NumberFormatUtil.formatMontant(l.quantite, decimales: 0))),
                                        DataCell(Text(NumberFormatUtil.formatMontant(l.prix, decimales: 2))),
                                        DataCell(
                                          Text(
                                            NumberFormatUtil.formatMontant(l.montant, decimales: 2),
                                            style: Appstyle.textSB.copyWith(color: Appstyle.crevete),
                                          ),
                                        ),
                                        DataCell(Text(l.nomCaissier)),
                                        DataCell(EtatBadge(isActive: l.actif)),
                                      ]);
                                    }).toList(),
                                  ),
                                ),
                              ),
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
