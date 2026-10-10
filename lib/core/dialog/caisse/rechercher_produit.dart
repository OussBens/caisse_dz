import 'dart:ui';

import 'package:caisse_dz/core/dialog/base_dialog.dart';
import 'package:caisse_dz/core/tableau/insertion/tableau_insertion_produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/card/card_product.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/core/widget/champ/radio_champ.dart';
import 'package:caisse_dz/core/widget/fourchette._widget.dart';
import 'package:caisse_dz/core/widget/search_bar.dart';
import 'package:caisse_dz/core/widget/section_decoration_filtre.dart';
import 'package:caisse_dz/core/widget/title/titre_avec_ligne.dart';
import 'package:caisse_dz/data/models/categorie.dart';
import 'package:caisse_dz/data/models/produit.dart';
import 'package:caisse_dz/data/models/sous_categorie.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:caisse_dz/Services/Mouvement.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Filtres avancés de recherche produit : catégorie, sous-catégorie,
/// marque, unité de mesure, fourchette de prix de vente, fourchette de
/// quantité en stock et produits "service" uniquement. Utilisé uniquement
/// en interne par [RechercherProduitDialog] pour affiner sa propre liste
/// de résultats — n'affecte plus le tableau/wrap produit de l'écran caisse.
class ProduitFiltreCaisse {
  String? categorie;
  String? sousCategorie;
  String? marque;
  String? unite;
  double? prixVenteMin;
  double? prixVenteMax;
  double? quantiteMin;
  double? quantiteMax;
  bool serviceUniquement;

  ProduitFiltreCaisse({
    this.categorie,
    this.sousCategorie,
    this.marque,
    this.unite,
    this.prixVenteMin,
    this.prixVenteMax,
    this.quantiteMin,
    this.quantiteMax,
    this.serviceUniquement = false,
  });

  bool get estActif =>
      (categorie != null && categorie!.isNotEmpty) ||
      (sousCategorie != null && sousCategorie!.isNotEmpty) ||
      (marque != null && marque!.isNotEmpty) ||
      (unite != null && unite!.isNotEmpty) ||
      prixVenteMin != null ||
      prixVenteMax != null ||
      quantiteMin != null ||
      quantiteMax != null ||
      serviceUniquement;

  bool matches(
    Produit p, {
    required List<Categorie> categories,
    required List<SousCategorie> sousCategories,
    required Map<String, double> quantites,
  }) {
    final catNom = categorie == null || categorie!.isEmpty
        ? null
        : categories.firstWhereOrNull((c) => c.id == p.categorieId)?.nom;
    final catOk = categorie == null || categorie!.isEmpty || catNom == categorie;

    final sousCatNom = sousCategorie == null || sousCategorie!.isEmpty
        ? null
        : sousCategories.firstWhereOrNull((sc) => sc.id == p.sousCategorieId)?.nom;
    final sousCatOk = sousCategorie == null || sousCategorie!.isEmpty || sousCatNom == sousCategorie;

    final marqueOk = marque == null || marque!.isEmpty || p.marque == marque;
    final uniteOk = unite == null || unite!.isEmpty || p.uniteMesure == unite;

    final prixOk = (prixVenteMin == null || p.prixVente >= prixVenteMin!) &&
        (prixVenteMax == null || p.prixVente <= prixVenteMax!);
    final quantiteP = quantites[p.code] ?? 0;
    final qteOk = (quantiteMin == null || quantiteP >= quantiteMin!) &&
        (quantiteMax == null || quantiteP <= quantiteMax!);

    final serviceOk = !serviceUniquement || p.service;

    return catOk && sousCatOk && marqueOk && uniteOk && prixOk && qteOk && serviceOk;
  }
}

/// Recherche un produit (filtres avancés + texte libre, affichage tableau
/// ou cartes comme dans [InsertionProduitDialog]) et l'insère directement
/// dans le panier de la caisse via [onProduitSelected]. Ce dialog est
/// autonome : il ne filtre plus le tableau/wrap produit de l'écran caisse.
Future<void> RechercherProduitDialog({
  required BuildContext context,
  required List<Categorie> categories,
  required List<SousCategorie> sousCategories,
  required List<Produit> produits,
  required double seuilMinimum,
  required Map<String, List<String>> codeBarresSecondairesMap,
  required void Function(Produit) onProduitSelected,
}) {
  return showDialog(
    context: context,
    barrierColor: Appstyle.gris.withOpacity(0.2),
    builder: (_) => _RechercherProduitDialogContent(
      categories: categories,
      sousCategories: sousCategories,
      produits: produits,
      seuilMinimum: seuilMinimum,
      codeBarresSecondairesMap: codeBarresSecondairesMap,
      onProduitSelected: onProduitSelected,
    ),
  );
}

class _RechercherProduitDialogContent extends StatefulWidget {
  final List<Categorie> categories;
  final List<SousCategorie> sousCategories;
  final List<Produit> produits;
  final double seuilMinimum;
  final Map<String, List<String>> codeBarresSecondairesMap;
  final void Function(Produit) onProduitSelected;

  const _RechercherProduitDialogContent({
    required this.categories,
    required this.sousCategories,
    required this.produits,
    required this.seuilMinimum,
    required this.codeBarresSecondairesMap,
    required this.onProduitSelected,
  });

  @override
  State<_RechercherProduitDialogContent> createState() => _RechercherProduitDialogContentState();
}

class _RechercherProduitDialogContentState extends State<_RechercherProduitDialogContent> {
  final ProduitFiltreCaisse etat = ProduitFiltreCaisse();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String searchText = "";
  bool affichageCard = true;
  Produit? produitSelectionne;

  // Quantité par produit calculée depuis le journal des mouvements — voir
  // insertion_produit.dart pour le même mécanisme. Remplace Produit.quantite.
  Map<String, double> quantitesMap = {};

  @override
  void initState() {
    super.initState();
    _loadQuantites();
  }

  Future<void> _loadQuantites() async {
    final totaux = await MouvementsServices.totauxParProduit();
    if (mounted) setState(() => quantitesMap = totaux.quantites);
  }

  // ✅ Ferme d'abord ce dialog de recherche, puis déclenche l'insertion —
  // dans cet ordre, car [onProduitSelected] (ouvrirDialogProduit côté
  // caisse_screen) pousse lui-même un nouveau dialog (afficher_produit_
  // selectionne). Comme un appel de fonction async s'exécute de façon
  // synchrone jusqu'à son premier "await", ce nouveau dialog serait déjà
  // ouvert avant l'appel à Navigator.pop() si celui-ci passait en second :
  // on fermerait alors par erreur le dialog produit qui vient de s'ouvrir
  // au lieu de ce dialog de recherche.
  void _inserer(Produit p) {
    Navigator.pop(context);
    widget.onProduitSelected(p);
  }

  void _reinitialiserFiltres() {
    setState(() {
      etat.categorie = null;
      etat.sousCategorie = null;
      etat.marque = null;
      etat.unite = null;
      etat.prixVenteMin = null;
      etat.prixVenteMax = null;
      etat.quantiteMin = null;
      etat.quantiteMax = null;
      etat.serviceUniquement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final marqueOptions = widget.produits.map((p) => p.marque).where((m) => m.trim().isNotEmpty).toSet().toList()..sort();
    final uniteOptions = widget.produits.map((p) => p.uniteMesure).where((u) => u.trim().isNotEmpty).toSet().toList()..sort();

    final sousCategorieOptions = (etat.categorie == null || etat.categorie!.isEmpty)
        ? widget.sousCategories.map((sc) => sc.nom).toSet().toList()
        : widget.sousCategories
            .where((sc) => sc.categorieId == widget.categories.firstWhereOrNull((c) => c.nom == etat.categorie)?.id)
            .map((sc) => sc.nom)
            .toSet()
            .toList();

    final produitsFiltres = widget.produits.where((p) {
      final rechercheOk = searchText.isEmpty ||
          p.nom.toLowerCase().contains(searchText) ||
          (p.codeBarre?.toLowerCase().contains(searchText) ?? false) ||
          (widget.codeBarresSecondairesMap[p.code]?.any((c) => c.contains(searchText)) ?? false);

      return rechercheOk &&
          etat.matches(
            p,
            categories: widget.categories,
            sousCategories: widget.sousCategories,
            quantites: quantitesMap,
          );
    }).toList();

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
        child: BaseDialog(
          couleur: Appstyle.Tblanc,
          width: 1400,
          height: 1000,
          header: Row(
            children: [
              TitreAvecLigne(
                colligne: Appstyle.Tnoir,
                imagePath: 'assets/icons/sidebar/produit_icon.png',
                text: l10n.search,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Icon(Icons.close, color: Appstyle.gris),
              ),
            ],
          ),
          content: Column(
            children: [
              // ── Filtres avancés (identiques à l'ancien dialog), 3 par ligne ──
              Row(
                children: [
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.categorie,
                      child: TextListe(
                        value: etat.categorie,
                        items: widget.categories.map((c) => c.nom).toList(),
                        onChanged: (v) => setState(() {
                          etat.categorie = v;
                          etat.sousCategorie = null;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.sousCategorie,
                      child: TextListe(
                        value: etat.sousCategorie,
                        items: sousCategorieOptions,
                        onChanged: (v) => setState(() => etat.sousCategorie = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.marque,
                      child: TextListe(
                        value: etat.marque,
                        items: marqueOptions,
                        onChanged: (v) => setState(() => etat.marque = v),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.unitOfMeasure,
                      child: TextListe(
                        value: etat.unite,
                        items: uniteOptions,
                        onChanged: (v) => setState(() => etat.unite = v),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.salePrice,
                      child: FourchettePrixWidget(
                        couleur: Appstyle.violet,
                        minValue: etat.prixVenteMin,
                        maxValue: etat.prixVenteMax,
                        onChanged: (min, max) => setState(() {
                          etat.prixVenteMin = min;
                          etat.prixVenteMax = max;
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ChampAvecLabel(
                      label: l10n.quantity,
                      child: FourchettePrixWidget(
                        couleur: Appstyle.violet,
                        minValue: etat.quantiteMin,
                        maxValue: etat.quantiteMax,
                        onChanged: (min, max) => setState(() {
                          etat.quantiteMin = min;
                          etat.quantiteMax = max;
                        }),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ChampAvecLabel(
                    label: l10n.service,
                    distance: 200,
                    child: TextRadio(
                      value: etat.serviceUniquement,
                      onChanged: (v) => setState(() => etat.serviceUniquement = v ?? false),
                    ),
                  ),
                  MainButton(
                    text: l10n.reset,
                    icon: Icons.refresh,
                    color: Appstyle.gris,
                    onPressed: _reinitialiserFiltres,
                  ),
                ],
              ),

              const SizedBox(height: 14),
              Divider(color: Appstyle.grisC),
              const SizedBox(height: 4),

              // ── Recherche texte + bascule tableau/cartes ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: 250,
                    child: SearchField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => searchText = val.toLowerCase()),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => affichageCard = !affichageCard),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Appstyle.indigo,
                        borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                      ),
                      child: Icon(
                        affichageCard ? Icons.view_list : Icons.grid_view,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Résultats : tableau ou cartes (même widgets que InsertionProduitDialog) ──
              Expanded(
                child: affichageCard
                    ? Scrollbar(
                        controller: _scrollController,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          child: SectionDecorationFiltre(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              width: double.infinity,
                              child: Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                alignment: WrapAlignment.start,
                                runAlignment: WrapAlignment.start,
                                children: produitsFiltres.map((p) {
                                  return CardProduct(
                                    couleur: Appstyle.Tblanc,
                                    iconPath: 'assets/icons/sidebar/produit_icon.png',
                                    hasRemise: p.remiseId != null && p.remiseId != 0,
                                    text1: p.nom,
                                    text2: "${p.prixVente} ${l10n.currency}",
                                    photo: p.photo,
                                    sousCategorieId: p.sousCategorieId,
                                    quantite: quantitesMap[p.code] ?? 0,
                                    actif: p.etat,
                                    selected: produitSelectionne?.id == p.id,
                                    seuil: widget.seuilMinimum,
                                    onTap: !p.etat ? null : () => setState(() => produitSelectionne = p),
                                    onDoubleTap: !p.etat ? null : () => _inserer(p),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      )
                    : TableauProduitInsertion(
                        produits: produitsFiltres,
                        selectedProduit: produitSelectionne,
                        multiple: false,
                        onSelectionChanged: (p) => setState(() => produitSelectionne = p),
                        onDoubleTapProduit: (p) => _inserer(p),
                        quantites: quantitesMap,
                      ),
              ),
            ],
          ),
          footer: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              MainButton(
                text: l10n.close,
                icon: Icons.close,
                color: Appstyle.gris,
                onPressed: () => Navigator.pop(context),
              ),
              MainButton(
                text: l10n.add,
                icon: Icons.add_shopping_cart,
                color: Appstyle.violet,
                onPressed: () {
                  if (produitSelectionne == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.pleaseSelectProduct),
                        backgroundColor: Appstyle.crevete,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    return;
                  }
                  _inserer(produitSelectionne!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
