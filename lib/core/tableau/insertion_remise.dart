import 'package:caisse_dz/core/dialog/remise/remise_nouveau.dart';
import 'package:flutter/material.dart';
import '../../data/models/remise.dart';
import '../../l10n/app_localizations.dart';
import '../tableau/insertion/tableau_insertion_remise.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/radio_champ.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import '../../Services/Remise.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionRemiseDialog extends StatefulWidget {
  final List<Remise> remises;
  final Function(Remise) onRemiseSelected;
  final bool multiselection;

  const InsertionRemiseDialog({
    Key? key,
    required this.remises,
    required this.onRemiseSelected,
    required this.multiselection,
  }) : super(key: key);

  @override
  State<InsertionRemiseDialog> createState() => _InsertionRemiseDialogState();
}

class _InsertionRemiseDialogState extends State<InsertionRemiseDialog> {
  bool multiple = false;
  Remise? remiseSelectionnee;
  List<Remise> remisesSelectionnees = [];
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des remises
  List<Remise> remisesLocale = [];

  @override
  void initState() {
    super.initState();
    remisesLocale = List.from(widget.remises);
  }

  // Méthode pour recharger les remises depuis la base de données
  Future<void> reloadRemises() async {
    final db = await DbCreator.openDb();
    final services = RemiseServices(db);
    final nouvellesRemises = await RemiseServices.getAllRemise();

    if (mounted) {
      setState(() {
        remisesLocale = nouvellesRemises;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final remisesFiltres = remisesLocale.where((r) {
      if (searchText.isEmpty) return true;
      return r.nom.toLowerCase().contains(searchText) ||
          r.code.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.violetC,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/cardwidget/remise_icon.png',
            text: l10n.insertionDiscount,
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
          // 🔍 Recherche + Nouveau
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              MainButton(
                text: l10n.newWord,
                color: Appstyle.crevete,
                onPressed: () async {
                  // Ouvrir le dialog de création
                  await RemiseNouveau(context);

                  // Recharger les remises après la fermeture du dialog
                  await reloadRemises();


                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Multiple
          if(widget.multiselection)
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
            child: TableauRemiseInsertion(
              remises: remisesFiltres,
              selectedRemise: remiseSelectionnee,
              selectedRemises: remisesSelectionnees,
              multiple: multiple,
              onSelectionChanged: (r) {
                if (!multiple) setState(() => remiseSelectionnee = r);
              },
              onSelectionMultipleChanged: (list) {
                if (multiple) setState(() => remisesSelectionnees = list);
              },
              onDoubleTapRemise: (r) {
                if (!multiple) {
                  setState(() => remiseSelectionnee = r);
                  widget.onRemiseSelected(r);
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
                if (remisesSelectionnees.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectDiscount),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                for (var r in remisesSelectionnees) widget.onRemiseSelected(r);
              } else {
                if (remiseSelectionnee == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectDiscount),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                widget.onRemiseSelected(remiseSelectionnee!);
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