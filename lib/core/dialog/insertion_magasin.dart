import 'package:caisse_dz/core/dialog/produit/produit_nouveau.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../data/models/magasin.dart';
import '../tableau/insertion/tableau_insertion_magasin.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/radio_champ.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'magasin/magasin_nouveau.dart';
import '../../Services/Magasin.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionMagasinDialog extends StatefulWidget {
  final List<Magasin> magasins;
  final Function(Magasin) onMagasinSelected;
  final bool multiselection;

  const InsertionMagasinDialog({
    Key? key,
    required this.magasins,
    required this.onMagasinSelected,
    required this.multiselection,
  }) : super(key: key);

  @override
  State<InsertionMagasinDialog> createState() =>
      _InsertionMagasinDialogState();
}

class _InsertionMagasinDialogState extends State<InsertionMagasinDialog> {
  bool multiple = false;
  List<Magasin> magasinSelectionnees = [];
  Magasin? magasinSelectionne;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des magasins
  List<Magasin> magasinsLocale = [];

  @override
  void initState() {
    super.initState();
    magasinsLocale = List.from(widget.magasins);
  }

  // Méthode pour recharger les magasins depuis la base de données
  Future<void> reloadMagasins() async {
    final db = await DbCreator.openDb();
    final services = MagasinServices(db);
    final nouveauxMagasins = await MagasinServices.getAllMagasins();

    if (mounted) {
      setState(() {
        magasinsLocale = nouveauxMagasins;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final magasinsFiltres = magasinsLocale.where((m) {
      if (searchText.isEmpty) return true;
      return m.nom.toLowerCase().contains(searchText) ||
          m.code.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.violetC,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/sidebar/magasin_icon.png',
            text: l10n.insertionStore,
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
              MainButton(
                text: l10n.newWord,
                color: Appstyle.crevete,
                onPressed: () async {
                  // Ouvrir le dialog de création
                  await MagasinNouveau(context);

                  // Recharger les magasins après la fermeture du dialog
                  await reloadMagasins();


                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (widget.multiselection)
            ChampAvecLabel(
              alignmentStart: true,
              label: l10n.multipleSelection,
              child: TextRadio(
                value: multiple,
                onChanged: (v) => setState(() => multiple = v ?? false),
                auto: true,
              ),
            ),
          const SizedBox(height: 12),

          Expanded(
            child: TableauMagasinInsertion(
              magasins: magasinsFiltres,
              selectedMagasins: magasinSelectionnees,
              selectedMagasin: magasinSelectionne,
              multiple: multiple,
              onSelectionChanged: (m) {
                if (!multiple) magasinSelectionne = m;
              },
              onSelectionMultipleChanged: (list) {
                if (multiple) magasinSelectionnees = list;
              },
              onDoubleTapMagasin: (m) {
                if (!multiple) {
                  setState(() => magasinSelectionne = m);
                  widget.onMagasinSelected(m);
                  Navigator.pop(context);
                }
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
              if (multiple) {
                if (magasinSelectionnees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectStore),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                for (var m in magasinSelectionnees) widget.onMagasinSelected(m);
              } else {
                if (magasinSelectionne == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectStore),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                widget.onMagasinSelected(magasinSelectionne!);
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