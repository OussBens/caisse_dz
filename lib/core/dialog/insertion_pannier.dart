import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../data/models/pannier.dart';
import '../tableau/insertion/tableau_insertion_pannier.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

/// Dialog de sélection d'un panier, construit sur le même modèle que
/// [InsertionRemiseDialog] / [InsertionClientDialog] (recherche + tableau
/// paginé + double-clic ou bouton "Ajouter"). Sélection simple : utilisé
/// notamment dans le retour client pour choisir le panier d'origine.
class InsertionPannierDialog extends StatefulWidget {
  final List<Pannier> panniers;
  final Function(Pannier) onPannierSelected;

  const InsertionPannierDialog({
    Key? key,
    required this.panniers,
    required this.onPannierSelected,
  }) : super(key: key);

  @override
  State<InsertionPannierDialog> createState() => _InsertionPannierDialogState();
}

class _InsertionPannierDialogState extends State<InsertionPannierDialog> {
  Pannier? pannierSelectionne;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final panniersFiltres = widget.panniers.where((p) {
      if (searchText.isEmpty) return true;
      return p.searchableText.contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: TitreAvecLigne(
        colligne: Appstyle.Tnoir,
        imagePath: 'assets/icons/sidebar/pannier_icon.png',
        text: l10n.cart,
        trailing: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.close, color: Appstyle.gris),
        ),
      ),
      content: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 300,
                child: SearchField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => searchText = val.toLowerCase());
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TableauPannierInsertion(
              panniers: panniersFiltres,
              selectedPannier: pannierSelectionne,
              onSelectionChanged: (p) {
                pannierSelectionne = p;
              },
              onDoubleTapPannier: (p) {
                setState(() => pannierSelectionne = p);
                widget.onPannierSelected(p);
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
              if (pannierSelectionne == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelect),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              widget.onPannierSelected(pannierSelectionne!);
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
