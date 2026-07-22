import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../Services/Produits.dart';
import '../../data/models/produit.dart';
import '../tableau/insertion/tableau_insertion_produit.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/card/card_product.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/radio_champ.dart';
import '../widget/search_bar.dart';
import '../widget/section_decoration_filtre.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionProduitDialog extends StatefulWidget {
  final List<Produit> produits;
  final Function(Produit) onProduitSelected;
  final bool multiselection;
  final bool? filtreBesion;

  const InsertionProduitDialog({
    Key? key,
    required this.produits,
    required this.onProduitSelected,
    required this.multiselection,
    this.filtreBesion,
  }) : super(key: key);

  @override
  State<InsertionProduitDialog> createState() => _InsertionProduitDialogState();
}

class _InsertionProduitDialogState extends State<InsertionProduitDialog> {
  @override
  void initState() {
    super.initState();
    if (widget.filtreBesion == true) {
      produitbesoin = true;
    }
    // Initialiser la liste locale
    produitsLocale = List.from(widget.produits);
  }

  bool multiple = false;
  bool produitbesoin = true;
  List<Produit> produitsSelectionnees = [];
  Produit? produitSelectionne;

  bool affichageCard = true;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();
  String selectedSousCategorie = "";
  final ScrollController _scrollController = ScrollController();

  // Liste locale des produits
  List<Produit> produitsLocale = [];

  // Méthode pour recharger les produits depuis la base de données
  Future<void> reloadProduits() async {
    final db = await DbCreator.openDb();
    final services = ProduitServices(db);
    final nouveauxProduits = await ProduitServices.getAllProduits();

    if (mounted) {
      setState(() {
        produitsLocale = nouveauxProduits;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final produitsFiltres = produitsLocale.where((p) {
      final besoinOk = (widget.filtreBesion == true && produitbesoin)
          ? ((p.quantite) <= (p.seuilMin))
          : true;

      final sousCategorieOk = selectedSousCategorie.isEmpty
          ? true
          : p.sousCategorie == selectedSousCategorie;

      final rechercheOk = searchText.isEmpty
          ? true
          : p.nom != null && p.nom.toLowerCase().contains(searchText);

      return besoinOk && sousCategorieOk && rechercheOk;
    }).toList();

    return BaseDialog(
      couleur: Appstyle.violetC,
      width: 1080,
      height: 1000,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/sidebar/produit_icon.png',
            text: l10n.insertionProduct,
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(Icons.close, color: Appstyle.gris),
          ),
        ],
      ),
      content: Container(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 250,
                  child: SearchField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        searchText = val.toLowerCase();
                      });
                    },
                  ),
                ),
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          affichageCard = !affichageCard;
                        });
                      },
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Appstyle.indigo,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          affichageCard ? Icons.view_list : Icons.grid_view,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    MainButton(
                        text: l10n.newWord,
                        color: Appstyle.crevete,
                        onPressed: () async {
                          // Ouvrir le dialog de création
                          await ProduitNouveau(context);

                          // Recharger les produits après la fermeture du dialog
                          await reloadProduits();

                        }
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            Container(
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.multiselection)
                    ChampAvecLabel(
                      alignmentStart: true,
                      label: l10n.multipleSelection,
                      child: TextRadio(
                        value: multiple,
                        onChanged: (v) => setState(() => multiple = v ?? false),
                      ),
                    ),

                  if (widget.filtreBesion == true) ...[
                    const SizedBox(height: 12),
                    ChampAvecLabel(
                      alignmentStart: true,
                      label: l10n.need,
                      child: TextRadio(
                        value: produitbesoin,
                        onChanged: (v) => setState(() => produitbesoin = v ?? true),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

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
                            remise: p.remise,
                            text1: p.nom,
                            text2: "${p.prixAchat} ${l10n.currency}",
                            quantite: p.quantite,
                            selected: multiple
                                ? produitsSelectionnees.any((e) => e.id == p.id)
                                : produitSelectionne?.id == p.id,
                            seuil: p.seuilMin,
                            onTap: () {
                              setState(() {
                                if (multiple) {
                                  if (produitsSelectionnees.any((e) => e.id == p.id)) {
                                    produitsSelectionnees.removeWhere((e) => e.id == p.id);
                                  } else {
                                    produitsSelectionnees.add(p);
                                  }
                                } else {
                                  produitSelectionne = p;
                                }
                              });
                            },
                            onDoubleTap: () {
                              if (!multiple) widget.onProduitSelected(p);
                              Navigator.pop(context);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              )
                  : TableauProduitInsertion(
                produits: produitsFiltres,
                selectedProduits: produitsSelectionnees,
                selectedProduit: produitSelectionne,
                multiple: multiple,
                onSelectionChanged: (p) {
                  if (!multiple) produitSelectionne = p;
                },
                onSelectionMultipleChanged: (list) {
                  if (multiple) produitsSelectionnees = list;
                },
                onDoubleTapProduit: (p) {
                  if (!multiple) {
                    setState(() => produitSelectionne = p);
                    widget.onProduitSelected(p);
                    Navigator.pop(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          MainButton(
            onPressed: () => Navigator.pop(context),
            text: l10n.cancel,
            color: Appstyle.gris,
            icon: Icons.cancel,
          ),
          const SizedBox(width: 10),
          MainButton(
            onPressed: () {
              if (multiple) {
                if (produitsSelectionnees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectProduct),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                for (var p in produitsSelectionnees) widget.onProduitSelected(p);
              } else {
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
                widget.onProduitSelected(produitSelectionne!);
              }
              Navigator.pop(context);
            },
            text: l10n.add,
            color: Appstyle.violet,
          ),
        ],
      ),
    );
  }
}