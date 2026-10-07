import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/CaisseGestion.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/CaisseSession.dart';
import 'package:caisse_dz/data/models/caisse_mouvement.dart';
import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/ExcelPreviewDialog.dart';
import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/PDFPreviewDialog.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/pdf_generator_latin.dart';
import 'package:caisse_dz/Services/pdf_table_generator.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/tableau/mouvement_caisse/mouvement_caisse_source.dart';
import 'package:caisse_dz/core/tableau/mouvement_caisse/tableau_mouvement_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/gestion_caisse.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:flutter/material.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class MouvementCaisseTab extends StatefulWidget {
  const MouvementCaisseTab({super.key});

  @override
  State<MouvementCaisseTab> createState() => _MouvementCaisseTabState();
}

class _MouvementCaisseTabState extends State<MouvementCaisseTab> {
  bool loading = true;

  List<CaisseGestion> caisses = [];
  List<Verssement> versements = [];
  List<CaisseMouvement> mouvementsCaisse = [];
  List<Client> clients = [];
  List<Fournisseur> fournisseurs = [];

  String? selectedCaisse;
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
    versements = await VerssementServices.getAllverssement();
    mouvementsCaisse = await CaisseSessionServices.getAllMouvements();
    clients = await ClientServices.getAllClients();
    fournisseurs = await FournisseurServices.getAllFournisseurs();

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
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  // ✅ Vrai si au moins un champ de filtre est renseigné (pour l'indicateur visuel du bouton Filtre).
  // Note : dateDebut/dateFin sont pré-remplis avec "aujourd'hui" dans _loadData()
  // (jamais null par défaut), donc volontairement exclus ici.
  bool get _filtresMouvementCaisseActifs =>
      selectedCaisse != null ||
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

  static const _typesDocumentaires = [
    'encaissement_vente',
    'decaissement_achat',
    'retour_client',
    'retour_fournisseur',
  ];
  static const _typesVersement = ['versement_client', 'versement_fournisseur'];

  // ✅ Ancienne heuristique (déduction du type à partir du préfixe de
  // codeOperation) conservée uniquement pour les Versement antérieurs à la
  // mise en place du grand-livre caisse_mouvement (voir _versementCouvert).
  String _typeMouvementFallback(Verssement v) {
    if (v.codeOperation.startsWith('SS')) return "Entrée";
    if (v.codeOperation.startsWith('RET')) {
      return v.typebeneficiare == 'Client' ? "Retour Client" : "Retour Fournisseur";
    }
    if (v.codeOperation.startsWith('PN')) return "Pannier";
    return v.type;
  }

  CaisseGestion? get _caisseSelectionnee =>
      caisses.firstWhereOrNull((c) => c.nomCaisse == selectedCaisse);

  // Un Versement est "couvert" par un caisse_mouvement s'il a été créé après
  // la mise en place du grand-livre (Phases 1-3) : pour un versement lié à
  // un document (pannier/smart scan/retour), on cherche par codeOperation ;
  // pour un versement autonome (dialog Versement générique), le mouvement le
  // référence par son propre code (voir versement_nouveau.dart). Un
  // versement non couvert est historique — on retombe sur l'ancienne
  // dérivation pour ne pas perdre de données.
  bool _versementCouvert(Verssement v) {
    final estDocumentaire = v.codeOperation.startsWith('SS') ||
        v.codeOperation.startsWith('RET') ||
        v.codeOperation.startsWith('PN');
    if (estDocumentaire) {
      return mouvementsCaisse.any((m) =>
          _typesDocumentaires.contains(m.type) && m.codeOperation == v.codeOperation);
    }
    return mouvementsCaisse.any((m) =>
        _typesVersement.contains(m.type) && m.codeOperation == v.code);
  }

  bool _dansPeriode(DateTime date, DateTime? debut, DateTime? fin) {
    if (debut != null && date.isBefore(debut)) return false;
    if (fin != null && date.isAfter(DateTime(fin.year, fin.month, fin.day, 23, 59, 59))) return false;
    return true;
  }

  bool _caisseCorrespond(String? caisseCodeOuNom, {required bool estCode}) {
    if (selectedCaisse == null || selectedCaisse!.isEmpty) return true;
    if (estCode) return caisseCodeOuNom == _caisseSelectionnee?.code;
    return caisseCodeOuNom == selectedCaisse;
  }

  // ✅ Grand-livre unifié : mouvements de caisse (source privilégiée, tous
  // types y compris ouverture/clôture/manuel qui n'ont pas de Versement),
  // complété par les Versement non couverts (données antérieures à la mise
  // en place du grand-livre, voir _versementCouvert), toutes dates.
  List<LigneMouvementCaisse> get _lignesBrutes {
    final res = <LigneMouvementCaisse>[];

    for (final m in mouvementsCaisse) {
      if (!m.etat) continue;
      if (!_caisseCorrespond(m.caisseCode, estCode: true)) continue;
      final entrant = m.sens.toLowerCase() == 'entrée';
      res.add(LigneMouvementCaisse(
        numero: 0,
        date: m.date,
        codeVersement: m.code,
        type: ListsConst.labelTypeMouvementCaisse(m.type),
        codeOperation: m.codeOperation ?? '-',
        nomClient: m.clientCode != null
            ? (clients.firstWhereOrNull((c) => c.code == m.clientCode)?.nom ?? m.clientCode!)
            : '-',
        nomFournisseur: m.fournisseurCode != null
            ? (fournisseurs.firstWhereOrNull((f) => f.code == m.fournisseurCode)?.nom ?? m.fournisseurCode!)
            : '-',
        montantEntree: entrant ? m.montant : 0,
        montantSortie: entrant ? 0 : m.montant,
      ));
    }

    for (final v in versements) {
      if (!v.etat) continue;
      if (!_caisseCorrespond(v.caisse, estCode: false)) continue;
      if (_versementCouvert(v)) continue;
      final estClient = v.typebeneficiare == 'Client';
      final entrant = v.sense.toLowerCase() == 'entrée';
      res.add(LigneMouvementCaisse(
        numero: 0,
        date: v.date,
        codeVersement: v.code,
        type: _typeMouvementFallback(v),
        codeOperation: v.codeOperation,
        nomClient: estClient
            ? (clients.firstWhereOrNull((c) => c.code == v.beneficiareCode)?.nom ?? v.beneficiareCode)
            : '-',
        nomFournisseur: !estClient
            ? (fournisseurs.firstWhereOrNull((f) => f.code == v.beneficiareCode)?.nom ?? v.beneficiareCode)
            : '-',
        montantEntree: entrant ? v.montant : 0,
        montantSortie: entrant ? 0 : v.montant,
      ));
    }

    return res;
  }

  List<LigneMouvementCaisse> get _lignesPeriode {
    final debut = dateDebut;
    final fin = dateFin;
    final liste = _lignesBrutes.where((l) => _dansPeriode(l.date, debut, fin)).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return List.generate(liste.length, (i) => liste[i].copyWith(numero: i + 1));
  }

  // Solde juste avant le début de la période (net de tous les
  // mouvements/versements actifs antérieurs à cette date) — d'une seule
  // caisse si sélectionnée, ou la somme de toutes les caisses sinon.
  //
  // ⚠️ `caisse.soldeInitial` n'est PAS ajouté ici : c'est une simple valeur
  // par défaut pré-remplie dans le dialog d'ouverture de session
  // (ouverture_caisse.dart), pas un solde flottant persistant. Le vrai
  // montant d'ouverture saisi par l'utilisateur est déjà journalisé comme
  // mouvement `ouverture` dans `_lignesBrutes` (voir CaisseSessionServices.
  // ouvrirSession) — l'additionner en plus doublait le solde initial pour
  // toute période postérieure à au moins une ouverture de session.
  double get _soldeInitialPeriode {
    if (selectedCaisse != null && selectedCaisse!.isNotEmpty && _caisseSelectionnee == null) {
      return 0;
    }

    final debut = dateDebut;
    if (debut == null) return 0;

    double net = 0;
    for (final l in _lignesBrutes) {
      if (l.date.isBefore(debut)) {
        net += l.montantEntree - l.montantSortie;
      }
    }
    return net;
  }

  double get _totalEntree => _lignesPeriode.fold(0.0, (s, l) => s + l.montantEntree);

  double get _totalSortie => _lignesPeriode.fold(0.0, (s, l) => s + l.montantSortie);

  double get _soldeFinal => _soldeInitialPeriode + _totalEntree - _totalSortie;

  // ⚠️ L'export Excel (ExcelGenerator.generateVersementsExcel) ne connaît
  // que les Verssement — les mouvements sans Versement (ouverture, clôture,
  // entrée/sortie manuelle) n'y figurent pas, contrairement au tableau
  // écran et à l'export PDF (voir _lignesPeriode). Limitation connue.
  List<Verssement> get _versementsPeriodeExport {
    final debut = dateDebut;
    final fin = dateFin;
    return versements.where((v) {
      if (!v.etat) return false;
      if (!_caisseCorrespond(v.caisse, estCode: false)) return false;
      return _dansPeriode(v.date, debut, fin);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _exportExcel(AppLocalizations l10n) async {
    final versementsAExporter = _versementsPeriodeExport;
    if (versementsAExporter.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.cashRegister,
        message: l10n.noDataToExport,
      );
      return;
    }

    final fermerSpinner = ouvrirSpinnerExport(context);
    try {

      final translator = ListsConstTranslator(l10n);
      final excelFile = await ExcelGenerator.generateVersementsExcel(
        versements: versementsAExporter,
        l10n: l10n,
        translator: translator,
      );

      if (!mounted) return;
      fermerSpinner();

      final excel = Excel.decodeBytes(await excelFile.readAsBytes());
      var sheet = excel.tables['Versements'];
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

  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit.
  List<LigneMouvementCaisse> _lignesSelectionnees = [];

  /// Extract filtre : Excel des seules lignes cochées, avec les colonnes du
  /// tableau (y compris ouverture/clôture/mouvements manuels).
  Future<void> _exportSelectionExcel(AppLocalizations l10n) async {
    if (_lignesSelectionnees.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.cashRegister,
        message: l10n.noRowSelected,
      );
      return;
    }
    try {
      final fichier = await executerAvecSpinner(
        context,
        () => ExcelGenerator.generateMouvementsCaisseExcel(lignes: List.of(_lignesSelectionnees), l10n: l10n),
      );
      if (!mounted) return;
      await ouvrirApercuExcel(
        context,
        fichier: fichier,
        nomFeuille: 'MouvementsCaisse',
        titre: "${l10n.cashRegister} (${l10n.selected})",
        l10n: l10n,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportPdf(AppLocalizations l10n) async {
    final lignes = _lignesPeriode;
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
      title: "${l10n.cashRegister} - ${selectedCaisse ?? l10n.all}",
      subtitleLines: [
        "${l10n.from}: ${_dateDebutCtrl.text}    ${l10n.to}: ${_dateFinCtrl.text}",
        "${l10n.initialBalance}: ${NumberFormatUtil.formatMontant(_soldeInitialPeriode, decimales: 2)}    "
            "${l10n.incomingAmount}: ${NumberFormatUtil.formatMontant(_totalEntree, decimales: 2)}    "
            "${l10n.outgoingAmount}: ${NumberFormatUtil.formatMontant(_totalSortie, decimales: 2)}    "
            "${l10n.finalBalance}: ${NumberFormatUtil.formatMontant(_soldeFinal, decimales: 2)}",
      ],
      headers: [
        l10n.number,
        l10n.date,
        l10n.paymentCode,
        l10n.type,
        l10n.operationCode,
        l10n.client,
        l10n.fournisseur,
        l10n.incomingAmount,
        l10n.outgoingAmount,
      ],
      rows: lignes.map((l) => [
        l.numero.toString(),
        _formatDate(l.date),
        l.codeVersement,
        l.type,
        l.codeOperation,
        l.nomClient,
        l.nomFournisseur,
        l.montantEntree > 0 ? NumberFormatUtil.formatMontant(l.montantEntree, decimales: 2) : '-',
        l.montantSortie > 0 ? NumberFormatUtil.formatMontant(l.montantSortie, decimales: 2) : '-',
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
            'MouvementCaisse_${DateTime.now().millisecondsSinceEpoch}.pdf',
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
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
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
                  showBadge: _filtresMouvementCaisseActifs,
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
                  onPressed: () async => await _exportSelectionExcel(l10n),
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
          _statCard(l10n.cashRegister, selectedCaisse ?? '-', Appstyle.violet),
          const SizedBox(width: 12),
          _statCard(l10n.from, _dateDebutCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.to, _dateFinCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.initialBalance, "${NumberFormatUtil.formatMontant(_soldeInitialPeriode, decimales: 2)} ${l10n.currency}", Appstyle.gris),
          const SizedBox(width: 12),
          _statCard(l10n.incomingAmount, "${NumberFormatUtil.formatMontant(_totalEntree, decimales: 2)} ${l10n.currency}", Colors.green),
          const SizedBox(width: 12),
          _statCard(l10n.outgoingAmount, "${NumberFormatUtil.formatMontant(_totalSortie, decimales: 2)} ${l10n.currency}", Colors.red),
          const SizedBox(width: 12),
          _statCard(l10n.finalBalance, "${NumberFormatUtil.formatMontant(_soldeFinal, decimales: 2)} ${l10n.currency}", Appstyle.crevete),
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
          const SizedBox(height: 10),
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.cashRegister,
                child: TextListe(
                  value: selectedCaisse,
                  items: caisses.map((c) => c.nomCaisse).toList(),
                  clearable: true,
                  onChanged: (v) => setState(() => selectedCaisse = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTable(AppLocalizations l10n) {
    final lignes = _lignesPeriode;

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

    // ⚠️ Pas de key basée sur `lignes` : la liste est reconstruite à chaque
    // build (nouvelle identité), ce qui détruirait/recréerait tout l'état du
    // tableau (et donc le tri par en-tête actif) à chaque rafraîchissement.
    // didUpdateWidget() de TableauMouvementCaisse gère déjà la mise à jour
    // des données en conservant le tri.
    return TableauMouvementCaisse(
      lignes: lignes,
      onSelectionChanged: (selection) => _lignesSelectionnees = selection,
    );
  }
}
