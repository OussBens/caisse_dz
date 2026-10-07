import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../data/models/fournisseur.dart';
import '../tableau/insertion/tableau_insertion_fournisseur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'fournisseur/fournisseur_nouveau.dart';
import '../../Services/Fournisseur.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionFournisseurDialog extends StatefulWidget {
  final List<Fournisseur> fournisseurs;
  final Function(Fournisseur) onFournisseurSelected;
  final bool newButton;

  const InsertionFournisseurDialog({
    Key? key,
    required this.fournisseurs,
    required this.onFournisseurSelected,
    this.newButton = true,
  }) : super(key: key);

  @override
  State<InsertionFournisseurDialog> createState() =>
      _InsertionFournisseurDialogState();
}

class _InsertionFournisseurDialogState
    extends State<InsertionFournisseurDialog> {
  Fournisseur? fournisseurSelectionne;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des fournisseurs
  List<Fournisseur> fournisseursLocale = [];

  @override
  void initState() {
    super.initState();
    fournisseursLocale = List.from(widget.fournisseurs);
  }

  // Méthode pour recharger les fournisseurs depuis la base de données
  Future<void> reloadFournisseurs() async {
    final db = await DbCreator.openDb();
    final services = FournisseurServices(db);
    final nouveauxFournisseurs = await FournisseurServices.getAllFournisseurs();

    if (mounted) {
      setState(() {
        fournisseursLocale = nouveauxFournisseurs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final fournisseursFiltres = fournisseursLocale.where((f) {
      if (searchText.isEmpty) return true;
      return f.nom != null && f.nom!.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: TitreAvecLigne(
        colligne: Appstyle.Tnoir,
        imagePath: 'assets/icons/sidebar/fournisseur_icon.png',
        text: l10n.insertionSupplier,
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
                  onPressed: () async {
                    // Ouvrir le dialog de création
                    await FournisseurNouveau(context);

                    // Recharger les fournisseurs après la fermeture du dialog
                    await reloadFournisseurs();


                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TableauFournisseurInsertion(
              fournisseurs: fournisseursFiltres,
              selectedFournisseur: fournisseurSelectionne,
              onSelectionChanged: (f) {
                setState(() => fournisseurSelectionne = f);
                widget.onFournisseurSelected(f);
              },
              onDoubleTapFournisseur: (f) {
                setState(() => fournisseurSelectionne = f);
                widget.onFournisseurSelected(f);
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
              if (fournisseurSelectionne == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelectSupplier),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              widget.onFournisseurSelected(fournisseurSelectionne!);
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