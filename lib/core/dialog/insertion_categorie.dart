import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../data/models/categorie.dart';
import '../tableau/insertion/tableau_insertion_categorie.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'categorie/categorie_nouveau.dart';

class InsertionCategorieDialog extends StatefulWidget {
  final List<Categorie> categories;
  final Function(Categorie) onCategorieSelected;
  final bool newButton;

  const InsertionCategorieDialog({
    Key? key,
    required this.categories,
    required this.onCategorieSelected,
    this.newButton = true,
  }) : super(key: key);

  @override
  State<InsertionCategorieDialog> createState() =>
      _InsertionCategorieDialogState();
}

class _InsertionCategorieDialogState extends State<InsertionCategorieDialog> {
  Categorie? categorieSelectionnee;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final categoriesFiltres = widget.categories.where((c) {
      if (searchText.isEmpty) return true;
      return c.nom.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/cardwidget/categorie_icon.png',
            text: l10n.insertionCategory,
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
                    CategorieNouveau(context);
                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TableauCategorieInsertion(
              categories: categoriesFiltres,
              selectedCategorie: categorieSelectionnee,
              onSelectionChanged: (c) {
                setState(() => categorieSelectionnee = c);
                widget.onCategorieSelected(c);
              },
              onDoubleTapCategorie: (c) {
                setState(() => categorieSelectionnee = c);
                widget.onCategorieSelected(c);
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
              if (categorieSelectionnee == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelectCategory),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              widget.onCategorieSelected(categorieSelectionnee!);
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