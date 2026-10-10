import 'package:caisse_dz/Services/Categorie.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/tableau/inventaire/inventaire_source.dart';
import 'package:caisse_dz/core/tableau/inventaire/tableau_inventaire.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Situation "Inventaire" : valorisation du stock actuel (quantité, valeur
/// d'achat, valeur de vente potentielle, marge potentielle) par produit.
class InventaireTab extends StatefulWidget {
  const InventaireTab({super.key});

  @override
  State<InventaireTab> createState() => _InventaireTabState();
}

class _InventaireTabState extends State<InventaireTab> {
  bool loading = true;

  List<Produit> produits = [];
  List<Categorie> categories = [];
  Map<String, double> prixMoyenAchatParProduit = {};
  Map<String, double> prixMoyenVenteParProduit = {};
  // Quantité par produit calculée depuis le journal des mouvements, sommée
  // sur les magasins consultables par l'utilisateur — voir produit_screen
  // .dart pour le même mécanisme. Remplace Produit.quantite.
  Map<String, double> quantitesParProduit = {};

  String? selectedCategorie;
  double? quantiteMin;
  double? quantiteMax;
  double? prixAchatMin;
  double? prixAchatMax;
  bool filtresActifs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final magasinsConsultation = Provider.of<AuthState>(context, listen: false).magasinsConsultation;
    produits = await ProduitServices.getAllProduits();
    categories = await CategorieServices.getAllCategorie();
    prixMoyenAchatParProduit = await ProduitServices.getPrixMoyenAchatParProduit();
    prixMoyenVenteParProduit = await ProduitServices.getPrixMoyenVenteParProduit();
    quantitesParProduit = await MouvementsServices.quantitesConsultables(magasinsConsultation);

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _supprimerFiltre() {
    selectedCategorie = null;
    quantiteMin = null;
    quantiteMax = null;
    prixAchatMin = null;
    prixAchatMax = null;
  }

  // ✅ Vrai si au moins un champ de filtre est renseigné (pour l'indicateur visuel du bouton Filtre).
  bool get _filtresActifsIndicateur =>
      (selectedCategorie != null && selectedCategorie!.isNotEmpty) ||
      quantiteMin != null ||
      quantiteMax != null ||
      prixAchatMin != null ||
      prixAchatMax != null;

  String _nomCategorie(int categorieId) =>
      categories.firstWhereOrNull((c) => c.id == categorieId)?.nom ?? '-';

  // Produits physiques actifs (les services n'ont pas de stock), filtrés par
  // catégorie et fourchettes de quantité/valeur d'achat.
  List<LigneInventaire> get _lignes {
    return produits.where((p) {
      if (p.service || !p.etat) return false;
      if (selectedCategorie != null && selectedCategorie!.isNotEmpty) {
        if (_nomCategorie(p.categorieId) != selectedCategorie) return false;
      }
      final qte = quantitesParProduit[p.code] ?? 0;
      if (quantiteMin != null && qte < quantiteMin!) return false;
      if (quantiteMax != null && qte > quantiteMax!) return false;
      if (prixAchatMin != null && p.prixAchat < prixAchatMin!) return false;
      if (prixAchatMax != null && p.prixAchat > prixAchatMax!) return false;
      return true;
    }).map((p) {
      return LigneInventaire(
        codeProduit: p.code,
        nomProduit: p.nom,
        nomCategorie: _nomCategorie(p.categorieId),
        quantite: quantitesParProduit[p.code] ?? 0,
        prixAchat: p.prixAchat,
        prixVente: p.prixVente,
        prixMoyenAchat: prixMoyenAchatParProduit[p.code] ?? 0,
        prixMoyenVente: prixMoyenVenteParProduit[p.code] ?? 0,
      );
    }).toList()
      ..sort((a, b) => a.nomProduit.compareTo(b.nomProduit));
  }

  int get _nbrProduits => _lignes.length;
  double get _quantiteTotale => _lignes.fold(0.0, (s, l) => s + l.quantite);
  double get _valeurStockAchat => _lignes.fold(0.0, (s, l) => s + l.valeurAchat);
  double get _valeurStockVente => _lignes.fold(0.0, (s, l) => s + l.valeurVente);
  double get _margePotentielle => _lignes.fold(0.0, (s, l) => s + l.margePotentielle);

  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit, et un rebuild recréerait la liste du tableau.
  List<LigneInventaire> _lignesSelectionnees = [];

  Future<void> _exportExcel(AppLocalizations l10n, {bool selectionSeulement = false}) async {
    final lignes = selectionSeulement ? _lignesSelectionnees : _lignes;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.stock,
        message: selectionSeulement ? l10n.noRowSelected : l10n.noDataToExport,
      );
      return;
    }

    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final excelFile = await ExcelGenerator.generateInventaireExcel(
        lignes: lignes,
        l10n: l10n,
      );

      if (!mounted) return;
      fermerSpinner();

      final excel = Excel.decodeBytes(await excelFile.readAsBytes());
      var sheet = excel.tables['Inventaire'];
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

      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => ExcelPreviewDialog(
          data: data,
          headers: headers,
          title: l10n.inventory,
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

  Future<void> _exportPdf(AppLocalizations l10n) async {
    final lignes = _lignes;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.stock,
        message: l10n.noDataToExport,
      );
      return;
    }

    final pdfBytes = await PDFTableGenerator.generateTableReport(
      title: l10n.inventory,
      subtitleLines: [
        "${l10n.products}: $_nbrProduits    ${l10n.quantity}: ${NumberFormatUtil.formatMontant(_quantiteTotale, decimales: 0)}",
        "${l10n.purchaseValue}: ${NumberFormatUtil.formatMontant(_valeurStockAchat, decimales: 2)}    "
            "${l10n.saleValue}: ${NumberFormatUtil.formatMontant(_valeurStockVente, decimales: 2)}    "
            "${l10n.potentialMargin}: ${NumberFormatUtil.formatMontant(_margePotentielle, decimales: 2)}",
      ],
      headers: [
        l10n.code,
        l10n.products,
        l10n.category,
        l10n.quantity,
        l10n.purchasePrice,
        l10n.purchaseValue,
        l10n.saleValue,
        l10n.averagePurchasePrice,
        l10n.averageSalePrice,
        l10n.potentialMargin,
        l10n.status,
      ],
      rows: lignes.map((l) => [
        l.codeProduit,
        l.nomProduit,
        l.nomCategorie,
        NumberFormatUtil.formatMontant(l.quantite, decimales: 0),
        NumberFormatUtil.formatMontant(l.prixAchat, decimales: 2),
        NumberFormatUtil.formatMontant(l.valeurAchat, decimales: 2),
        NumberFormatUtil.formatMontant(l.valeurVente, decimales: 2),
        NumberFormatUtil.formatMontant(l.prixMoyenAchat, decimales: 2),
        NumberFormatUtil.formatMontant(l.prixMoyenVente, decimales: 2),
        NumberFormatUtil.formatMontant(l.margePotentielle, decimales: 2),
        l.quantite > 0 ? l10n.available : l10n.outOfStock,
      ]).toList(),
    );

    if (!mounted) return;
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
            'Inventaire_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicateurs(l10n),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  MainButton(
                    text: l10n.filter,
                    textColor: Appstyle.violet,
                    color: Appstyle.Tblanc,
                    showBadge: _filtresActifsIndicateur,
                    icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                    iconColor: Appstyle.violet,
                    onPressed: () => setState(() => filtresActifs = !filtresActifs),
                  ),
                  if (filtresActifs) ...[
                    const SizedBox(width: 8),
                    MainIconButton(
                      color: Colors.grey.shade400,
                      imagePath: 'assets/icons/action/supprimer_icon.png',
                      onPressed: () => setState(() => _supprimerFiltre()),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  MainButton(
                    text: l10n.extract,
                    textColor: Colors.green,
                    iconColor: Colors.green,
                    color: Appstyle.Tblanc,
                    icon: Icons.download,
                    onPressed: () async => await _exportExcel(l10n),
                  ),
                  const SizedBox(width: 10),
                  // Extract filtre : Excel des seules lignes cochées.
                  MainIconButton(
                    imagePath: "assets/icons/action/extacter_filtre_icon.png",
                    color: Colors.orange,
                    onPressed: () async => await _exportExcel(l10n, selectionSeulement: true),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.extractPdf,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    color: Appstyle.Tblanc,
                    icon: Icons.picture_as_pdf,
                    onPressed: () async => await _exportPdf(l10n),
                  ),
                ],
              ),
            ],
          ),
          if (filtresActifs) ...[
            const SizedBox(height: 12),
            _buildFiltres(l10n),
          ],
          const SizedBox(height: 16),
          _buildTable(l10n),
        ],
      ),
    );
  }

  Widget _buildIndicateurs(AppLocalizations l10n) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _statCard(l10n.products, "$_nbrProduits", Appstyle.violet),
          const SizedBox(width: 12),
          _statCard(l10n.quantity, NumberFormatUtil.formatMontant(_quantiteTotale, decimales: 0), Appstyle.blueC),
          const SizedBox(width: 12),
          _statCard(l10n.purchaseValue, "${NumberFormatUtil.formatMontant(_valeurStockAchat, decimales: 2)} ${l10n.currency}", Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.saleValue, "${NumberFormatUtil.formatMontant(_valeurStockVente, decimales: 2)} ${l10n.currency}", Colors.green),
          const SizedBox(width: 12),
          _statCard(l10n.potentialMargin, "${NumberFormatUtil.formatMontant(_margePotentielle, decimales: 2)} ${l10n.currency}", Appstyle.crevete),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltres(AppLocalizations l10n) {
    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.category,
                  child: TextListe(
                    value: selectedCategorie,
                    items: categories.map((c) => c.nom).toList(),
                    clearable: true,
                    onChanged: (v) => setState(() => selectedCategorie = v),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.quantity,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.blueC,
                    minValue: quantiteMin,
                    maxValue: quantiteMax,
                    onChanged: (min, max) => setState(() {
                      quantiteMin = min;
                      quantiteMax = max;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.purchasePrice,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.indigo,
                    minValue: prixAchatMin,
                    maxValue: prixAchatMax,
                    onChanged: (min, max) => setState(() {
                      prixAchatMin = min;
                      prixAchatMax = max;
                    }),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AppLocalizations l10n) {
    final lignes = _lignes;

    if (lignes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: Appstyle.violet.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(l10n.noDataToExport, style: Appstyle.textM.copyWith(color: Appstyle.gris)),
        ),
      );
    }

    return TableauInventaire(
      lignes: lignes,
      onSelectionChanged: (selection) => _lignesSelectionnees = selection,
    );
  }
}
