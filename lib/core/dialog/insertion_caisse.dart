import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../data/models/gestion_caisse.dart';
import '../tableau/insertion/tableau_insertion_caisse.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'gestion_caisse/gestion_caisse_nouveau.dart';
import '../../Services/CaisseGestion.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionCaisseDialog extends StatefulWidget {
  final List<CaisseGestion> caisses;
  final Function(CaisseGestion) onCaisseSelected;

  const InsertionCaisseDialog({
    Key? key,
    required this.caisses,
    required this.onCaisseSelected,
  }) : super(key: key);

  @override
  State<InsertionCaisseDialog> createState() => _InsertionCaisseDialogState();
}

class _InsertionCaisseDialogState extends State<InsertionCaisseDialog> {
  CaisseGestion? caisseSelectionnee;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des caisses
  List<CaisseGestion> caissesLocale = [];

  @override
  void initState() {
    super.initState();
    caissesLocale = List.from(widget.caisses);
  }

  // Méthode pour recharger les caisses depuis la base de données
  Future<void> reloadCaisses() async {
    final db = await DbCreator.openDb();
    final services = GCServices(db);
    final nouvellesCaisses = await GCServices.getAllCaisses();

    if (mounted) {
      setState(() {
        caissesLocale = nouvellesCaisses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final caissesFiltres = caissesLocale.where((c) {
      if (searchText.isEmpty) return true;
      return c.nomCaisse.toLowerCase().contains(searchText) ||
          c.code.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.violetC,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/sidebar/caisse_icon.png',
            text: l10n.insertionCashRegister,
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
                  await CaisseGestionNouveau(context);

                  // Recharger les caisses après la fermeture du dialog
                  await reloadCaisses();

                },
              ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TableauCaisseInsertion(
              caisses: caissesFiltres,
              selectedCaisse: caisseSelectionnee,
              onSelectionChanged: (c) {
                setState(() => caisseSelectionnee = c);
                widget.onCaisseSelected(c);
              },
              onDoubleTapCaisse: (c) {
                setState(() => caisseSelectionnee = c);
                widget.onCaisseSelected(c);
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
              if (caisseSelectionnee == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelectCashRegister),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              widget.onCaisseSelected(caisseSelectionnee!);
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