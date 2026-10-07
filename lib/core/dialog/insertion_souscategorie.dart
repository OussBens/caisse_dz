import 'package:caisse_dz/core/dialog/sous_categorie/sous_categorie_nouveau.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../data/models/sous_categorie.dart';
import '../tableau/insertion/tableau_insertion_souscategorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

class InsertionSousCategorieDialog extends StatefulWidget {
  final List<SousCategorie> sousCategories;
  final Function(SousCategorie) onSousCategorieSelected;
  final bool newButton;

  const InsertionSousCategorieDialog({
    Key? key,
    required this.sousCategories,
    required this.onSousCategorieSelected,
    this.newButton = true,
  }) : super(key: key);

  @override
  State<InsertionSousCategorieDialog> createState() =>
      _InsertionSousCategorieDialogState();
}

class _InsertionSousCategorieDialogState extends State<InsertionSousCategorieDialog> {
  SousCategorie? sousCategorieSelectionnee;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sousCategoriesFiltres = widget.sousCategories.where((c) {
      if (searchText.isEmpty) return true;
      return c.nom.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: TitreAvecLigne(
        colligne: Appstyle.Tnoir,
        imagePath: 'assets/icons/cardwidget/sous_catego_icon.png',
        text: l10n.insertionSubcategory,
        trailing: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: Appstyle.gris),
        ),
      ),
      content: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 300,
                child: SearchField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() {
                      searchText = val.toLowerCase();
                    });
                  },
                ),
              ),
              if (widget.newButton)
                MainButton(
                  text: l10n.newWord,
                  color: Appstyle.crevete,
                  onPressed: () {
                    SousCategorieNouveau(context);
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TableauSousCategorieInsertion(
              sousCategories: sousCategoriesFiltres,
              selectedSousCategorie: sousCategorieSelectionnee,
              onSelectionChanged: (c) {
                setState(() => sousCategorieSelectionnee = c);
                widget.onSousCategorieSelected(c);
              },
              onDoubleTapSousCategorie: (c) {
                setState(() => sousCategorieSelectionnee = c);
                widget.onSousCategorieSelected(c);
                Navigator.pop(context);
              },
            ),
          ),
        ],
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
          MainButton(
            onPressed: () {
              if (sousCategorieSelectionnee == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelectSubcategory),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              widget.onSousCategorieSelected(sousCategorieSelectionnee!);
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