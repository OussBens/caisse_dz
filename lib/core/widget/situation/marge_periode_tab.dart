import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/tableau/marge_periode/marge_periode_source.dart';
import 'package:caisse_dz/core/tableau/marge_periode/tableau_marge_periode.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Situation "Bénéfice période (marge par jour)" : agrégat quotidien
/// (montant + marge) sur une plage de dates, pour une caisse.
class MargeParPeriodeTab extends StatefulWidget {
  const MargeParPeriodeTab({super.key});

  @override
  State<MargeParPeriodeTab> createState() => _MargeParPeriodeTabState();
}

class _MargeParPeriodeTabState extends State<MargeParPeriodeTab> {
  bool loading = true;

  List<CaisseGestion> caisses = [];
  List<Pannier> panniers = [];

  String? selectedCaisse;
  DateTime? dateDebut;
  DateTime? dateFin;
  double? montantMin;
  double? montantMax;
  double? margeMin;
  double? margeMax;
  String? periodeRapide;
  bool filtresActifs = true;

  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  Future<void> _loadData() async {
    caisses = await GCServices.getAllCaisses();
    panniers = await PannierServices.getAllPanniers();

    final now = DateTime.now();
    dateFin = DateTime(now.year, now.month, now.day);
    dateDebut = dateFin!.subtract(const Duration(days: 6));
    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _supprimerFiltre() {
    selectedCaisse = null;
    montantMin = null;
    montantMax = null;
    margeMin = null;
    margeMax = null;
    periodeRapide = null;
    final now = DateTime.now();
    dateFin = DateTime(now.year, now.month, now.day);
    dateDebut = dateFin!.subtract(const Duration(days: 6));
    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);
  }

  // ✅ Vrai si au moins un champ de filtre est renseigné (pour l'indicateur visuel du bouton Filtre).
  // Note : dateDebut/dateFin sont pré-remplis (7 derniers jours) dans _loadData()
  // (jamais null par défaut), donc volontairement exclus ici.
  bool get _filtresMargePeriodeActifs =>
      selectedCaisse != null ||
      montantMin != null ||
      montantMax != null ||
      margeMin != null ||
      margeMax != null ||
      periodeRapide != null;

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateDebut = picked;
        _dateDebutCtrl.text = _formatDate(picked);
      });
    }
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        dateFin = (dateDebut != null && picked.isBefore(dateDebut!)) ? dateDebut : picked;
        _dateFinCtrl.text = _formatDate(dateFin!);
      });
    }
  }

  void _appliquerPeriodeRapide(String key) {
    final periode = calculerPeriodeRapide(key);
    setState(() {
      periodeRapide = key;
      dateDebut = periode.debut;
      dateFin = periode.fin;
      _dateDebutCtrl.text = _formatDate(periode.debut);
      _dateFinCtrl.text = _formatDate(periode.fin);
    });
  }

  // Panniers (hors SmartScan) de la caisse sélectionnée, dans la période et
  // les fourchettes de montant/marge choisies.
  List<Pannier> get _panniersFiltres {
    final debut = dateDebut;
    final fin = dateFin;
    return panniers.where((p) {
      if (selectedCaisse != null && selectedCaisse!.isNotEmpty && p.caisse != selectedCaisse) return false;
      if (p.typepannier == "SmartScan") return false;
      if (debut != null && p.date.isBefore(debut)) return false;
      if (fin != null && p.date.isAfter(DateTime(fin.year, fin.month, fin.day, 23, 59, 59))) return false;
      if (montantMin != null && p.montant < montantMin!) return false;
      if (montantMax != null && p.montant > montantMax!) return false;
      if (margeMin != null && p.marge < margeMin!) return false;
      if (margeMax != null && p.marge > margeMax!) return false;
      return true;
    }).toList();
  }

  // Agrège les panniers filtrés par jour civil.
  List<LigneMargePeriode> get _lignes {
    final panniersFiltres = _panniersFiltres;
    final parJour = <DateTime, List<Pannier>>{};
    for (final p in panniersFiltres) {
      final jour = DateTime(p.date.year, p.date.month, p.date.day);
      parJour.putIfAbsent(jour, () => []).add(p);
    }

    final jours = parJour.keys.toList()..sort();
    return jours.map((jour) {
      final liste = parJour[jour]!;
      return LigneMargePeriode(
        codeCaisse: liste.first.caisse_code,
        date: jour,
        montantJour: liste.fold(0.0, (s, p) => s + p.montant),
        margeJour: liste.fold(0.0, (s, p) => s + p.marge),
      );
    }).toList();
  }

  double get _totalVendu => _panniersFiltres.fold(0.0, (s, p) => s + p.montant);
  double get _totalNet => _panniersFiltres.fold(0.0, (s, p) => s + p.marge);
  int get _nbrJours => _lignes.length;
  int get _nbrPannier => _panniersFiltres.length;

  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit, et un rebuild recréerait la liste du tableau.
  List<LigneMargePeriode> _lignesSelectionnees = [];

  Future<void> _exportExcel(AppLocalizations l10n, {bool selectionSeulement = false}) async {
    final lignes = selectionSeulement ? _lignesSelectionnees : _lignes;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.cashRegister,
        message: selectionSeulement ? l10n.noRowSelected : l10n.noDataToExport,
      );
      return;
    }

    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final excelFile = await ExcelGenerator.generateMargeParPeriodeExcel(
        lignes: lignes,
        l10n: l10n,
      );

      if (!mounted) return;
      fermerSpinner();

      final excel = Excel.decodeBytes(await excelFile.readAsBytes());
      var sheet = excel.tables['MargeParPeriode'];
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
          title: selectedCaisse ?? l10n.all,
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

  Future<void> _exportPdf(AppLocalizations l10n) async {
    final lignes = _lignes;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.cashRegister,
        message: l10n.noDataToExport,
      );
      return;
    }

    final pdfBytes = await PDFTableGenerator.generateTableReport(
      title: "${l10n.profitByPeriod} - ${selectedCaisse ?? l10n.all}",
      subtitleLines: [
        "${l10n.from}: ${_dateDebutCtrl.text}    ${l10n.to}: ${_dateFinCtrl.text}",
        "${l10n.totalAmount}: ${NumberFormatUtil.formatMontant(_totalVendu, decimales: 2)}    "
            "${l10n.net}: ${NumberFormatUtil.formatMontant(_totalNet, decimales: 2)}    "
            "${l10n.numberOfDays}: $_nbrJours    "
            "${l10n.numberOfSales}: $_nbrPannier",
      ],
      headers: [l10n.cashRegisterCode, l10n.date, l10n.amount, l10n.marge],
      rows: lignes.map((l) => [
        l.codeCaisse,
        _formatDate(l.date),
        NumberFormatUtil.formatMontant(l.montantJour, decimales: 2),
        NumberFormatUtil.formatMontant(l.margeJour, decimales: 2),
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
            'MargeParPeriode_${DateTime.now().millisecondsSinceEpoch}.pdf',
          );
          if (!mounted) return;
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

  @override
  void dispose() {
    _dateDebutCtrl.dispose();
    _dateFinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    if (caisses.isEmpty) {
      return Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(Appstyle.radiusCard)),
        child: Center(
          child: Text(
            "Aucune caisse configurée",
            style: Appstyle.textLB.copyWith(color: Appstyle.gris, fontWeight: FontWeight.bold),
          ),
        ),
      );
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
                    icon: filtresActifs ? Icons.visibility_off : Icons.visibility,
                    iconColor: Appstyle.violet,
                    showBadge: _filtresMargePeriodeActifs,
                    onPressed: () => setState(() => filtresActifs = !filtresActifs),
                  ),
                  if (filtresActifs) ...[
                    const SizedBox(width: 8),
                    MainIconButton(
                      color: Appstyle.neutral300,
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
                    textColor: Appstyle.success,
                    iconColor: Appstyle.success,
                    color: Appstyle.Tblanc,
                    icon: Icons.download,
                    onPressed: () async => await _exportExcel(l10n),
                  ),
                  const SizedBox(width: 10),
                  // Extract filtre : Excel des seules lignes cochées.
                  MainIconButton(
                    imagePath: "assets/icons/action/extacter_filtre_icon.png",
                    color: Appstyle.warning,
                    onPressed: () async => await _exportExcel(l10n, selectionSeulement: true),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.extractPdf,
                    textColor: Appstyle.danger,
                    iconColor: Appstyle.danger,
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
        borderRadius: BorderRadius.circular(Appstyle.radiusLG),
        boxShadow: [BoxShadow(color: Appstyle.shadowTint.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          _statCard(l10n.cashRegister, selectedCaisse ?? '-', Appstyle.violet),
          const SizedBox(width: 12),
          _statCard(l10n.from, _dateDebutCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.to, _dateFinCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.totalAmount, "${NumberFormatUtil.formatMontant(_totalVendu, decimales: 2)} ${l10n.currency}", Appstyle.success),
          const SizedBox(width: 12),
          _statCard(l10n.net, "${NumberFormatUtil.formatMontant(_totalNet, decimales: 2)} ${l10n.currency}", Appstyle.crevete),
          const SizedBox(width: 12),
          _statCard(l10n.numberOfDays, "$_nbrJours", Appstyle.blueF),
          const SizedBox(width: 12),
          _statCard(l10n.numberOfSales, "$_nbrPannier", Appstyle.blueC),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
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
                  label: l10n.from,
                  child: TextDate(hint: l10n.startDate, controller: _dateDebutCtrl, onTap: _pickDateDebut),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.to,
                  child: TextDate(hint: l10n.endDate, controller: _dateFinCtrl, onTap: _pickDateFin),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampPeriodeRapide(
                  l10n: l10n,
                  value: periodeRapide,
                  onSelected: _appliquerPeriodeRapide,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.cashRegister,
                  child: TextListe(
                    value: selectedCaisse,
                    items: caisses.map((c) => c.nomCaisse).toList(),
                    clearable: true,
                    onChanged: (v) => setState(() => selectedCaisse = v),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.amount,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.violet,
                    minValue: montantMin,
                    maxValue: montantMax,
                    onChanged: (min, max) => setState(() {
                      montantMin = min;
                      montantMax = max;
                    }),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.net,
                  child: FourchettePrixWidget(
                    couleur: Appstyle.crevete,
                    minValue: margeMin,
                    maxValue: margeMax,
                    onChanged: (min, max) => setState(() {
                      margeMin = min;
                      margeMax = max;
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
          borderRadius: BorderRadius.circular(Appstyle.radiusMD),
        ),
        padding: const EdgeInsets.all(40),
        child: Center(
          child: Text(l10n.noDataToExport, style: Appstyle.textM.copyWith(color: Appstyle.gris)),
        ),
      );
    }

    return TableauMargePeriode(
      lignes: lignes,
      onSelectionChanged: (selection) => _lignesSelectionnees = selection,
    );
  }
}
