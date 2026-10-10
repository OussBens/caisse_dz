import 'package:caisse_dz/core/utilis/quantite_format.dart';
import 'package:caisse_dz/core/dialog/information_dialog.dart';
import 'package:caisse_dz/Services/export_spinner.dart';
import 'package:caisse_dz/Services/excel_generator.dart';
import 'package:caisse_dz/Services/excel_apercu.dart';
import 'package:caisse_dz/Services/Magasin.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:caisse_dz/Services/Produits.dart';
import 'package:caisse_dz/core/Auth/auth_state.dart';
import 'package:caisse_dz/core/tableau/situation/mouvement_produit_source.dart';
import 'package:caisse_dz/core/tableau/situation/tableau_mouvement_produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/Icon_button.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/date_champ.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/filtre/periode_rapide_filter.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/data/constant.dart';
import 'package:caisse_dz/data/models/mouvement.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Onglet "Situation Mouvement Produit" (Dashboard > Situation) : tous les
/// mouvements de stock (entrée, sortie, pannier, retour, distribution,
/// transfert...) d'un ou tous les produits, avec la quantité en stock juste
/// avant/après chaque mouvement — calculée ici par somme cumulée
/// chronologique par produit (ni [Mouvement] ni [MouvementsServices] ne
/// stockent cette info directement, voir MouvementsServices.estEntree pour
/// la règle entrée/sortie par type).
class MouvementProduitTab extends StatefulWidget {
  const MouvementProduitTab({super.key});

  @override
  State<MouvementProduitTab> createState() => _MouvementProduitTabState();
}

class _MouvementProduitTabState extends State<MouvementProduitTab> {
  bool loading = true;

  List<Produit> produits = [];
  List<Mouvement> mouvements = [];
  // Code magasin -> nom, pour la colonne Magasin.
  Map<String, String> nomsMagasins = {};

  String? selectedProduitNom;
  String? selectedType;
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

  @override
  void dispose() {
    _dateDebutCtrl.dispose();
    _dateFinCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    // Multi-magasin : seuls les mouvements des magasins consultables par
    // l'utilisateur (comme le stock affiché dans Produit / Stock) — la
    // quantité avant/après est donc celle de ces magasins réunis.
    final magasinsConsultation = Provider.of<AuthState>(context, listen: false).magasinsConsultation;
    produits = await ProduitServices.getAllProduits();
    mouvements = await MouvementsServices.getMouvements(magasins: magasinsConsultation);
    nomsMagasins = await MagasinServices.getNomsMagasins();
    if (!mounted) return;
    setState(() => loading = false);
  }

  String _nomProduit(String code) =>
      produits.firstWhereOrNull((p) => p.code == code)?.nom ?? code;

  String _motif(Mouvement m, ListsConstTranslator translator) {
    final typeTraduit = translator.translateTypeMouvement(m.type);
    if (m.type == 'Sortie' && m.sousType != null) {
      return "$typeTraduit (${translator.translateTypeSortie(m.sousType!)})";
    }
    return typeTraduit;
  }

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
        periodeRapide = null;
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
        periodeRapide = null;
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

  void _supprimerFiltre() {
    selectedProduitNom = null;
    selectedType = null;
    dateDebut = null;
    dateFin = null;
    periodeRapide = null;
    _dateDebutCtrl.clear();
    _dateFinCtrl.clear();
  }

  bool get _filtresProduitActifs =>
      selectedProduitNom != null || selectedType != null || dateDebut != null || dateFin != null;

  String _formatDate(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/"
        "${d.month.toString().padLeft(2, '0')}/"
        "${d.year}";
  }

  bool _dansPeriode(DateTime date, DateTime? debut, DateTime? fin) {
    if (debut != null && date.isBefore(DateTime(debut.year, debut.month, debut.day))) return false;
    if (fin != null && date.isAfter(DateTime(fin.year, fin.month, fin.day, 23, 59, 59))) return false;
    return true;
  }

  // ✅ Calculée sur la TOTALITÉ des mouvements de chaque produit (sans les
  // filtres écran) : la quantité "avant"/"après" doit rester correcte même
  // si l'utilisateur restreint ensuite l'affichage à une période ou un type
  // — sinon "qtt initiale" changerait selon le filtre au lieu de refléter le
  // stock réel à cet instant.
  List<LigneMouvementProduit> get _lignesBrutes {
    final translator = ListsConstTranslator(AppLocalizations.of(context)!);
    final parProduit = groupBy(mouvements, (Mouvement m) => m.codeProduit);
    final res = <LigneMouvementProduit>[];

    parProduit.forEach((codeProduit, liste) {
      final triee = [...liste]..sort((a, b) => a.date.compareTo(b.date));
      double cumul = 0;
      for (final m in triee) {
        final qttInitiale = cumul;
        // Un mouvement annulé (etat=false) n'a jamais impacté le stock réel
        // (voir MouvementsServices.totauxParProduit, qui filtre etat=1) :
        // on l'affiche pour la traçabilité, mais qtt avant == qtt après.
        final delta = m.etat
            ? (MouvementsServices.estEntree(
                  m.type,
                  sousType: m.sousType,
                  clientCode: m.clientCode,
                  fournisseurCode: m.fournisseurCode,
                )
                ? m.quantite
                : -m.quantite)
            : 0.0;
        cumul += delta;

        res.add(LigneMouvementProduit(
          numero: 0,
          date: m.date,
          nomProduit: _nomProduit(codeProduit),
          motif: _motif(m, translator),
          qttInitiale: qttInitiale,
          qttMouvement: delta,
          qttApres: cumul,
          etat: m.etat,
          magasin: MagasinServices.nomMagasin(nomsMagasins, m.magasinCode),
        ));
      }
    });

    return res;
  }

  List<LigneMouvementProduit> get _lignesFiltrees {
    final liste = _lignesBrutes.where((l) {
      if (selectedProduitNom != null && l.nomProduit != selectedProduitNom) return false;
      if (selectedType != null) {
        final translator = ListsConstTranslator(AppLocalizations.of(context)!);
        if (!l.motif.startsWith(translator.translateTypeMouvement(selectedType!))) return false;
      }
      if (!_dansPeriode(l.date, dateDebut, dateFin)) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return List.generate(liste.length, (i) => liste[i].copyWith(numero: i + 1));
  }

  // Lignes cochées dans le tableau (Extract filtre). Pas de setState : seul
  // l'export les lit.
  List<LigneMouvementProduit> _lignesSelectionnees = [];

  String _formatDateHeure(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} "
      "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  /// Extract (liste filtrée), Extract filtre (lignes cochées) ou Extract PDF :
  /// mêmes colonnes que le tableau.
  Future<void> _exporter(AppLocalizations l10n, {bool selectionSeulement = false, bool enPdf = false}) async {
    final lignes = selectionSeulement ? _lignesSelectionnees : _lignesFiltrees;
    if (lignes.isEmpty) {
      await InformationDialog(
        context: context,
        titre_type_message: l10n.information,
        titre_concerne: l10n.product,
        message: selectionSeulement ? l10n.noRowSelected : l10n.noDataToExport,
      );
      return;
    }
    final titre = selectionSeulement ? "${l10n.productMovementSituation} (${l10n.selected})" : l10n.productMovementSituation;
    try {
      final fichier = await executerAvecSpinner(
        context,
        () => ExcelGenerator.generateOperationsExcel(
          title: titre,
          headers: [
            l10n.number,
            l10n.date,
            l10n.product,
            l10n.motifMouvement,
            l10n.magasin,
            l10n.initialQuantity,
            l10n.movementQuantity,
            l10n.quantityAfterMovement,
            l10n.status,
          ],
          rows: lignes
              .map((l) => [
                    l.numero.toString(),
                    _formatDateHeure(l.date),
                    l.nomProduit,
                    l.motif,
                    l.magasin,
                    QuantiteFormat.format(l.qttInitiale),
                    QuantiteFormat.format(l.qttMouvement),
                    QuantiteFormat.format(l.qttApres),
                    l.etat ? l10n.active : l10n.inactive,
                  ])
              .toList(),
          l10n: l10n,
        ),
      );
      if (!mounted) return;
      if (enPdf) {
        await ouvrirApercuPdfDepuisExcel(context, fichier: fichier, titre: titre, nomFeuille: 'Operations');
      } else {
        await ouvrirApercuExcel(context, fichier: fichier, nomFeuille: 'Operations', titre: titre, l10n: l10n);
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

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    showBadge: _filtresProduitActifs,
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
          TableauMouvementProduit(
            lignes: _lignesFiltrees,
            onSelectionChanged: (selection) => _lignesSelectionnees = selection,
          ),
        ],
      ),
    );
  }

  Widget _buildFiltres(AppLocalizations l10n) {
    final translator = ListsConstTranslator(l10n);
    return SectionDecorationFiltre(
      padding: const EdgeInsets.all(10),
      color: Appstyle.Tblanc,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.product,
                  child: TextListe(
                    value: selectedProduitNom,
                    items: produits.map((p) => p.nom).toList(),
                    clearable: true,
                    onChanged: (v) => setState(() => selectedProduitNom = v),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.type,
                  child: TextListe(
                    value: selectedType != null ? translator.translateTypeMouvement(selectedType!) : null,
                    items: ListsConst.typeMouvement.map(translator.translateTypeMouvement).toList(),
                    clearable: true,
                    onChanged: (v) {
                      setState(() {
                        selectedType = v == null
                            ? null
                            : ListsConst.typeMouvement.firstWhereOrNull(
                                (t) => translator.translateTypeMouvement(t) == v);
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
}
