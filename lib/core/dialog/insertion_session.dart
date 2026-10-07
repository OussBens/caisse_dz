import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../data/models/caisse_session.dart';
import '../../data/models/gestion_caisse.dart';
import '../tableau/insertion/tableau_insertion_session.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';

/// Dialog de sélection d'une session de caisse, construit sur le même modèle
/// que [InsertionPannierDialog] (recherche + tableau paginé + double-clic ou
/// bouton "Ajouter"). Sélection simple : utilisé notamment dans l'onglet
/// Mouvements de Gestion Caisse pour choisir la session à filtrer.
class InsertionSessionDialog extends StatefulWidget {
  final List<CaisseSession> sessions;
  final List<CaisseGestion> caisses;
  final Function(CaisseSession) onSessionSelected;

  const InsertionSessionDialog({
    Key? key,
    required this.sessions,
    required this.caisses,
    required this.onSessionSelected,
  }) : super(key: key);

  @override
  State<InsertionSessionDialog> createState() => _InsertionSessionDialogState();
}

class _InsertionSessionDialogState extends State<InsertionSessionDialog> {
  CaisseSession? sessionSelectionnee;
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

    final sessionsFiltrees = widget.sessions.where((s) {
      if (searchText.isEmpty) return true;
      return s.searchableText.contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: TitreAvecLigne(
        colligne: Appstyle.Tnoir,
        imagePath: 'assets/icons/sidebar/caisse_icon.png',
        text: l10n.insertionSession,
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
            child: TableauSessionInsertion(
              sessions: sessionsFiltrees,
              caisses: widget.caisses,
              selectedSession: sessionSelectionnee,
              onSelectionChanged: (s) {
                sessionSelectionnee = s;
              },
              onDoubleTapSession: (s) {
                setState(() => sessionSelectionnee = s);
                widget.onSessionSelected(s);
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
              if (sessionSelectionnee == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelect),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }
              widget.onSessionSelected(sessionSelectionnee!);
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
