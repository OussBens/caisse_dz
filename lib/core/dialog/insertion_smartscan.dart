import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../data/models/smart_scan.dart';
import '../tableau/insertion/tableau_insertion_smartscan.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

/// Dialog de sélection d'un SmartScan, construit sur le même modèle que
/// [InsertionProduitDialog] / [InsertionRemiseDialog] (recherche + tableau
/// paginé + double-clic ou bouton "Ajouter"). Sélection simple : utilisé
/// notamment dans le retour fournisseur pour choisir le SmartScan d'origine.
class InsertionSmartScanDialog extends StatefulWidget {
  final List<SmartScan> smartScans;
  final Function(SmartScan) onSmartScanSelected;

  const InsertionSmartScanDialog({
    Key? key,
    required this.smartScans,
    required this.onSmartScanSelected,
  }) : super(key: key);

  @override
  State<InsertionSmartScanDialog> createState() =>
      _InsertionSmartScanDialogState();
}

class _InsertionSmartScanDialogState extends State<InsertionSmartScanDialog> {
  SmartScan? smartScanSelectionne;
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

    final scansFiltres = widget.smartScans.where((s) {
      if (searchText.isEmpty) return true;
      return s.searchableText.contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/cardwidget/scan_icon.png',
            text: l10n.smartScan,
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
            child: TableauSmartScanInsertion(
              smartScans: scansFiltres,
              selectedSmartScan: smartScanSelectionne,
              onSelectionChanged: (s) {
                smartScanSelectionne = s;
              },
              onDoubleTapSmartScan: (s) {
                setState(() => smartScanSelectionne = s);
                widget.onSmartScanSelected(s);
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
              if (smartScanSelectionne == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelect),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              widget.onSmartScanSelected(smartScanSelectionne!);
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
