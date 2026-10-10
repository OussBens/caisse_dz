import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Utilisateur.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/tableau/recette_caisse/recette_caisse_source.dart';
import 'package:caisse_dz/core/tableau/recette_caisse/tableau_recette_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/utilisateur.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class RecetteCaissePannierTab extends StatefulWidget {
  const RecetteCaissePannierTab({super.key});

  @override
  State<RecetteCaissePannierTab> createState() => _RecetteCaissePannierTabState();
}

class _RecetteCaissePannierTabState extends State<RecetteCaissePannierTab> {
  bool loading = true;

  List<CaisseGestion> caisses = [];
  List<Pannier> panniers = [];
  List<Client> clients = [];
  List<Utilisateur> utilisateurs = [];
  List<Verssement> versements = [];

  String? selectedCaisse;
  String? selectedClient;
  String? selectedEtat;
  DateTime? dateDebut;
  DateTime? dateFin;
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
    clients = await ClientServices.getAllClients();
    utilisateurs = await UtilisateurServices.getAllUtilisateurs();
    versements = await VerssementServices.getAllverssement();

    final now = DateTime.now();
    dateDebut = DateTime(now.year, now.month, now.day);
    dateFin = dateDebut;
    _dateDebutCtrl.text = _formatDate(dateDebut!);
    _dateFinCtrl.text = _formatDate(dateFin!);

    if (!mounted) return;
    setState(() => loading = false);
  }

  void _supprimerFiltre() {
    selectedCaisse = null;
    selectedClient = null;
    selectedEtat = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  // ✅ Vrai si au moins un champ de filtre est renseigné (pour l'indicateur visuel du bouton Filtre).
  // Note : dateDebut/dateFin sont pré-remplis avec "aujourd'hui" dans _loadData()
  // (jamais null par défaut), donc volontairement exclus ici.
  bool get _filtresRecetteCaissePannierActifs =>
      selectedCaisse != null ||
      selectedClient != null ||
      selectedEtat != null ||
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

  // Panniers (hors SmartScan) de la caisse sélectionnée, filtrés par période,
  // client et état.
  List<Pannier> get _panniersFiltres {
    final debut = dateDebut;
    final fin = dateFin;
    return panniers.where((p) {
      if (selectedCaisse != null && selectedCaisse!.isNotEmpty && p.caisse != selectedCaisse) return false;
      if (p.typepannier == "SmartScan") return false;
      if (debut != null && p.date.isBefore(debut)) return false;
      if (fin != null && p.date.isAfter(DateTime(fin.year, fin.month, fin.day, 23, 59, 59))) return false;
      if (selectedClient != null && selectedClient!.isNotEmpty) {
        final client = clients.firstWhereOrNull((c) => c.code == p.client_code);
        if (client?.nom != selectedClient) return false;
      }
      if (selectedEtat != null && selectedEtat!.isNotEmpty) {
        final actif = selectedEtat == 'Actif';
        if (p.etat != actif) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<LigneRecetteCaisse> get _lignes {
    return _panniersFiltres.map((p) {
      final paye = PannierServices.calculerVerse(versements, p.code);
      return LigneRecetteCaisse(
        dateCree: p.dateCree,
        codeCaisse: p.caisse, // nom de la caisse (déjà dénormalisé sur Pannier), pas le code
        datePannier: p.date,
        codePannier: p.code,
        montant: p.montant,
        paye: paye,
        reste: p.montant - paye,
        nomCaissier: utilisateurs.firstWhereOrNull((u) => u.code == p.caissier_code)?.username ?? p.caissier_code,
        etat: p.etat,
      );
    }).toList();
  }

  double get _totalVendu => _panniersFiltres.fold(0.0, (s, p) => s + p.montant);
  int get _nbrPannier => _panniersFiltres.length;

  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit, et un rebuild recréerait la liste du tableau.
  List<LigneRecetteCaisse> _lignesSelectionnees = [];

  Future<void> _exportExcel(AppLocalizations l10n, {bool selectionSeulement = false}) async {
    final codesSelection = _lignesSelectionnees.map((l) => l.codePannier).toSet();
    final panniersAExporter = selectionSeulement
        ? _panniersFiltres.where((p) => codesSelection.contains(p.code)).toList()
        : _panniersFiltres;
    if (panniersAExporter.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.panier,
        message: selectionSeulement ? l10n.noRowSelected : l10n.noDataToExport,
      );
      return;
    }

    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final translator = ListsConstTranslator(l10n);
      final excelFile = await ExcelGenerator.generatePanniersExcel(
        panniers: panniersAExporter,
        versements: versements,
        l10n: l10n,
        translator: translator,
      );

      if (!mounted) return;
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
        titre_concerne: l10n.panier,
        message: l10n.noDataToExport,
      );
      return;
    }

    final pdfBytes = await PDFTableGenerator.generateTableReport(
      title: "${l10n.cashRegister} - ${selectedCaisse ?? l10n.all}",
      subtitleLines: [
        "${l10n.from}: ${_dateDebutCtrl.text}    ${l10n.to}: ${_dateFinCtrl.text}",
        "${l10n.totalAmount}: ${NumberFormatUtil.formatMontant(_totalVendu, decimales: 2)}    ${l10n.numberOfSales}: $_nbrPannier",
      ],
      headers: [
        l10n.date,
        l10n.cashRegisterCode,
        "${l10n.date} ${l10n.panier}",
        l10n.panierCode,
        l10n.amount,
        l10n.paid,
        l10n.remaining,
        l10n.cashier,
        l10n.status,
      ],
      rows: lignes.map((l) => [
        _formatDate(l.dateCree),
        l.codeCaisse,
        _formatDate(l.datePannier),
        l.codePannier,
        NumberFormatUtil.formatMontant(l.montant, decimales: 2),
        NumberFormatUtil.formatMontant(l.paye, decimales: 2),
        NumberFormatUtil.formatMontant(l.reste, decimales: 2),
        l.nomCaissier,
        l.etat ? l10n.active : l10n.inactive,
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
            'RecetteCaisse_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
                    showBadge: _filtresRecetteCaissePannierActifs,
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
                  label: l10n.client,
                  child: TextListe(
                    value: selectedClient,
                    items: clients.map((c) => c.nom).toList(),
                    clearable: true,
                    onChanged: (v) => setState(() => selectedClient = v),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.status,
                  child: TextListe(
                    value: selectedEtat,
                    items: [l10n.active, l10n.inactive],
                    clearable: true,
                    onChanged: (v) => setState(() {
                      selectedEtat = v == l10n.active ? 'Actif' : (v == l10n.inactive ? 'Inactif' : null);
                    }),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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

    // ⚠️ Pas de key basée sur `lignes` : la liste est reconstruite à chaque
    // build (nouvelle identité), ce qui détruirait/recréerait tout l'état du
    // tableau (et donc le tri par en-tête actif) à chaque rafraîchissement.
    // didUpdateWidget() de TableauRecetteCaisse gère déjà la mise à jour des
    // données en conservant le tri.
    return TableauRecetteCaisse(
      lignes: lignes,
      onSelectionChanged: (selection) => _lignesSelectionnees = selection,
    );
  }
}
