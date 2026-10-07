import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/core/tableau/cout_produit/cout_produit_source.dart';
import 'package:caisse_dz/core/tableau/cout_produit/tableau_cout_produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/filtre/ligne_filtre_tiers.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Situation "Coût produit" : prix d'achat et de vente constatés par produit
/// (min / max / moyen pondéré) et quantités achetées / vendues, sur une
/// période (toutes dates par défaut).
class CoutProduitTab extends StatefulWidget {
  const CoutProduitTab({super.key});

  @override
  State<CoutProduitTab> createState() => _CoutProduitTabState();
}

class _CoutProduitTabState extends State<CoutProduitTab> {
  bool loading = true;

  List<Produit> produits = [];
  List<LigneCoutProduit> _lignesPeriode = [];
  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit.
  List<LigneCoutProduit> _lignesSelectionnees = [];

  DateTime? dateDebut;
  DateTime? dateFin;
  String? periodeRapide;
  String? selectedProduit;
  bool filtresActifs = true;

  final TextEditingController _dateDebutCtrl = TextEditingController();
  final TextEditingController _dateFinCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _dateDebutCtrl.dispose();
    _dateFinCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

  /// Recharge les agrégats d'achat/vente pour la période choisie (le filtre
  /// produit / recherche s'applique ensuite en mémoire).
  Future<void> _loadData() async {
    if (produits.isEmpty) produits = await ProduitServices.getAllProduits();
    final achats = await ProduitServices.getPrixAchatParProduit(debut: dateDebut, fin: dateFin);
    final ventes = await ProduitServices.getPrixVenteParProduit(debut: dateDebut, fin: dateFin);

    final lignes = <LigneCoutProduit>[];
    for (final p in produits) {
      final a = achats[p.code];
      final v = ventes[p.code];
      if (a == null && v == null) continue; // ni acheté ni vendu sur la période
      lignes.add(LigneCoutProduit(
        codeProduit: p.code,
        nomProduit: p.nom,
        prixAchatMin: a?.min ?? 0,
        prixAchatMax: a?.max ?? 0,
        prixAchatMoyen: a?.moyen ?? 0,
        quantiteAchetee: a?.quantite ?? 0,
        prixVenteMin: v?.min ?? 0,
        prixVenteMax: v?.max ?? 0,
        prixVenteMoyen: v?.moyen ?? 0,
        quantiteVendue: v?.quantite ?? 0,
      ));
    }
    lignes.sort((a, b) => a.nomProduit.compareTo(b.nomProduit));

    if (!mounted) return;
    setState(() {
      _lignesPeriode = lignes;
      loading = false;
    });
  }

  List<LigneCoutProduit> get _lignes {
    final search = _searchCtrl.text.toLowerCase();
    return _lignesPeriode.where((l) {
      if (selectedProduit != null && selectedProduit!.isNotEmpty && l.nomProduit != selectedProduit) return false;
      if (search.isNotEmpty &&
          !l.nomProduit.toLowerCase().contains(search) &&
          !l.codeProduit.toLowerCase().contains(search)) {
        return false;
      }
      return true;
    }).toList();
  }

  bool get _filtresIndicateur =>
      dateDebut != null ||
      dateFin != null ||
      periodeRapide != null ||
      (selectedProduit != null && selectedProduit!.isNotEmpty) ||
      _searchCtrl.text.isNotEmpty;

  void _supprimerFiltre() {
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    selectedProduit = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
    _searchCtrl.clear();
    _loadData();
  }

  Future<void> _pickDateDebut() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      dateDebut = picked;
      periodeRapide = null;
      _dateDebutCtrl.text = _formatDate(picked);
    });
    await _loadData();
  }

  Future<void> _pickDateFin() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: dateFin ?? dateDebut ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      dateFin = (dateDebut != null && picked.isBefore(dateDebut!)) ? dateDebut : picked;
      periodeRapide = null;
      _dateFinCtrl.text = _formatDate(dateFin!);
    });
    await _loadData();
  }

  Future<void> _appliquerPeriodeRapide(String key) async {
    final periode = calculerPeriodeRapide(key);
    setState(() {
      periodeRapide = key;
      dateDebut = periode.debut;
      dateFin = periode.fin;
      _dateDebutCtrl.text = _formatDate(periode.debut);
      _dateFinCtrl.text = _formatDate(periode.fin);
    });
    await _loadData();
  }

  /// Extract (liste filtrée), Extract filtre (lignes cochées) ou Extract PDF.
  Future<void> _exporter(AppLocalizations l10n, {bool selectionSeulement = false, bool enPdf = false}) async {
    final lignes = selectionSeulement ? _lignesSelectionnees : _lignes;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.productCostSituation,
        message: selectionSeulement ? l10n.noRowSelected : l10n.noDataToExport,
      );
      return;
    }
    final titre = selectionSeulement
        ? "${l10n.productCostSituation} (${l10n.selected})"
        : l10n.productCostSituation;
    try {
      final fichier = await executerAvecSpinner(
        context,
        () => ExcelGenerator.generateCoutProduitExcel(lignes: List.of(lignes), l10n: l10n),
      );
      if (!mounted) return;
      if (enPdf) {
        await ouvrirApercuPdfDepuisExcel(context, fichier: fichier, titre: titre, nomFeuille: 'CoutProduit');
      } else {
        await ouvrirApercuExcel(context, fichier: fichier, nomFeuille: 'CoutProduit', titre: titre, l10n: l10n);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${l10n.exportError}: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    final lignes = _lignes;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIndicateurs(l10n, lignes),
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
                    showBadge: _filtresIndicateur,
                    onPressed: () => setState(() => filtresActifs = !filtresActifs),
                  ),
                  if (filtresActifs) ...[
                    const SizedBox(width: 8),
                    MainIconButton(
                      color: Colors.grey.shade400,
                      imagePath: 'assets/icons/action/supprimer_icon.png',
                      onPressed: () => setState(_supprimerFiltre),
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
                    onPressed: () async => await _exporter(l10n),
                  ),
                  const SizedBox(width: 10),
                  // Extract filtre : Excel des seules lignes cochées.
                  MainIconButton(
                    imagePath: "assets/icons/action/extacter_filtre_icon.png",
                    color: Colors.orange,
                    onPressed: () async => await _exporter(l10n, selectionSeulement: true),
                  ),
                  const SizedBox(width: 10),
                  MainButton(
                    text: l10n.extractPdf,
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    color: Appstyle.Tblanc,
                    icon: Icons.picture_as_pdf,
                    onPressed: () async => await _exporter(l10n, enPdf: true),
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
          TableauCoutProduit(
            lignes: lignes,
            onSelectionChanged: (selection) => _lignesSelectionnees = selection,
          ),
        ],
      ),
    );
  }

  Widget _buildIndicateurs(AppLocalizations l10n, List<LigneCoutProduit> lignes) {
    final qteAchetee = lignes.fold(0.0, (s, l) => s + l.quantiteAchetee);
    final qteVendue = lignes.fold(0.0, (s, l) => s + l.quantiteVendue);
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
          _statCard(l10n.from, dateDebut == null ? '-' : _dateDebutCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.to, dateFin == null ? '-' : _dateFinCtrl.text, Appstyle.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.products, "${lignes.length}", Appstyle.violet),
          const SizedBox(width: 12),
          _statCard(l10n.totalPurchasedQuantity, QuantiteFormat.format(qteAchetee), Colors.indigo),
          const SizedBox(width: 12),
          _statCard(l10n.totalSoldQuantity, QuantiteFormat.format(qteVendue), Colors.green),
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
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.from,
                child: TextDate(hint: l10n.startDate, controller: _dateDebutCtrl, onTap: _pickDateDebut),
              ),
              ChampAvecLabel(
                label: l10n.to,
                child: TextDate(hint: l10n.endDate, controller: _dateFinCtrl, onTap: _pickDateFin),
              ),
              ChampPeriodeRapide(
                l10n: l10n,
                value: periodeRapide,
                onSelected: _appliquerPeriodeRapide,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LigneFiltreTiers(
            children: [
              ChampAvecLabel(
                label: l10n.product,
                child: TextListe(
                  value: selectedProduit,
                  items: _lignesPeriode.map((l) => l.nomProduit).toSet().toList(),
                  clearable: true,
                  onChanged: (v) => setState(() => selectedProduit = v),
                ),
              ),
              ChampAvecLabel(
                label: l10n.search,
                child: SearchField(
                  controller: _searchCtrl,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
