import 'package:caisse_dz/core/dialog/pack/pack_nouveau.dart';
import 'package:flutter/material.dart';
import '../../data/models/pack.dart';
import '../../l10n/app_localizations.dart';
import '../tableau/insertion/tableau_insertion_pack.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/champ/champ_avec_label.dart';
import '../widget/champ/radio_champ.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import '../../Services/Pack.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionPackDialog extends StatefulWidget {
  final List<Pack> packs;
  final Function(Pack) onPackSelected;
  final bool multiselection;

  const InsertionPackDialog({
    Key? key,
    required this.packs,
    required this.onPackSelected,
    required this.multiselection,
  }) : super(key: key);

  @override
  State<InsertionPackDialog> createState() => _InsertionPackDialogState();
}

class _InsertionPackDialogState extends State<InsertionPackDialog> {
  bool multiple = false;
  List<Pack> packsSelectionnes = [];
  Pack? packSelectionne;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des packs
  List<Pack> packsLocale = [];

  @override
  void initState() {
    super.initState();
    packsLocale = List.from(widget.packs);
  }

  // Méthode pour recharger les packs depuis la base de données
  Future<void> reloadPacks() async {
    final db = await DbCreator.openDb();
    final services = PackServices(db);
    final nouveauxPacks = await PackServices.getAllPacks();

    if (mounted) {
      setState(() {
        packsLocale = nouveauxPacks;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final packsFiltres = packsLocale.where((p) {
      if (searchText.isEmpty) return true;
      return (p.nom.toLowerCase().contains(searchText) ||
          (p.code?.toLowerCase().contains(searchText) ?? false));
    }).toList();

    return BaseDialog(
      couleur: Appstyle.violetC,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/cardwidget/pack_icon.png',
            text: l10n.insertionPack,
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
                  await PackNouveau(context);

                  // Recharger les packs après la fermeture du dialog
                  await reloadPacks();


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
            child: TableauPackInsertion(
              packs: packsFiltres,
              selectedPacks: packsSelectionnes,
              selectedPack: packSelectionne,
              multiple: multiple,
              onSelectionChanged: (p) {
                if (!multiple) setState(() => packSelectionne = p);
              },
              onSelectionMultipleChanged: (list) {
                if (multiple) setState(() => packsSelectionnes = list);
              },
              onDoubleTapPack: (p) {
                if (!multiple) {
                  setState(() => packSelectionne = p);
                  widget.onPackSelected(p);
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
                if (packsSelectionnes.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectPack),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                for (var p in packsSelectionnes) widget.onPackSelected(p);
              } else {
                if (packSelectionne == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.pleaseSelectPack),
                      backgroundColor: Appstyle.crevete,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  return;
                }
                widget.onPackSelected(packSelectionne!);
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