import 'package:flutter/material.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import '../../data/models/client.dart';
import '../tableau/insertion/tableau_insertion_client.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../widget/button/main_button.dart';
import '../widget/search_bar.dart';
import '../widget/title/titre_avec_ligne.dart';
import 'base_dialog.dart';
import 'client/client_nouveau.dart';
import '../../Services/Client.dart'; // Ajouter cet import
import '../../DBCreate.dart'; // Ajouter cet import

class InsertionClientDialog extends StatefulWidget {
  final List<Client> clients;
  final Function(Client) onClientSelected;
  final bool newButton;

  const InsertionClientDialog({
    Key? key,
    required this.clients,
    required this.onClientSelected,
    this.newButton = true,
  }) : super(key: key);

  @override
  State<InsertionClientDialog> createState() =>
      _InsertionClientDialogState();
}

class _InsertionClientDialogState extends State<InsertionClientDialog> {
  Client? clientSelectionne;
  String searchText = "";
  final TextEditingController _searchController = TextEditingController();

  // Liste locale des clients
  List<Client> clientsLocale = [];

  @override
  void initState() {
    super.initState();
    clientsLocale = List.from(widget.clients);
  }

  // Méthode pour recharger les clients depuis la base de données
  Future<void> reloadClients() async {
    final db = await DbCreator.openDb();
    final services = ClientServices(db);
    final nouveauxClients = await ClientServices.getAllClients();

    if (mounted) {
      setState(() {
        clientsLocale = nouveauxClients;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final clientsFiltres = clientsLocale.where((c) {
      if (searchText.isEmpty) return true;
      return c.nom != null &&
          c.nom!.toLowerCase().contains(searchText);
    }).toList();

    return BaseDialog(
      couleur: Appstyle.Tblanc,
      width: 1000,
      height: 800,
      header: Row(
        children: [
          TitreAvecLigne(
            colligne: Appstyle.Tnoir,
            imagePath: 'assets/icons/sidebar/client_icon.png',
            text: l10n.insertionClient,
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
                  onPressed: () async {
                    // Ouvrir le dialog de création
                    await ClientNouveau(context);

                    // Recharger les clients après la fermeture du dialog
                    await reloadClients();


                  },
                ),
            ],
          ),

          const SizedBox(height: 12),

          Expanded(
            child: TableauClientInsertion(
              clients: clientsFiltres,
              selectedClient: clientSelectionne,
              onSelectionChanged: (c) {
                setState(() => clientSelectionne = c);
                widget.onClientSelected(c);
              },
              onDoubleTapClient: (c) {
                setState(() => clientSelectionne = c);
                widget.onClientSelected(c);
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
              if (clientSelectionne == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(l10n.pleaseSelectClient),
                    backgroundColor: Appstyle.crevete,
                    duration: const Duration(seconds: 2),
                  ),
                );
                return;
              }

              widget.onClientSelected(clientSelectionne!);
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