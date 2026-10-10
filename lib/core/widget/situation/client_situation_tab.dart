import 'package:caisse_dz/Services/Client.dart';
import 'package:caisse_dz/Services/Pannier.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/core/dialog/client/client_situation.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/data/models/client.dart';
import 'package:caisse_dz/data/models/pannier.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Onglet "Situation Client" (Dashboard > Situation) : point d'entrée
/// alternatif vers [SituationClientDialog] (déjà utilisé depuis le bouton
/// "Situation" de client_screen.dart, mais uniquement après avoir sélectionné
/// une ligne dans la liste) — ici on choisit directement le client dans un
/// menu déroulant, sans passer par le module Client.
class ClientSituationTab extends StatefulWidget {
  const ClientSituationTab({super.key});

  @override
  State<ClientSituationTab> createState() => _ClientSituationTabState();
}

class _ClientSituationTabState extends State<ClientSituationTab> {
  bool loading = true;

  List<Client> clients = [];
  List<Pannier> panniers = [];
  List<Retour> retours = [];
  List<Verssement> versements = [];

  Client? selectedClient;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    clients = await ClientServices.getAllClients();
    panniers = await PannierServices.getAllPanniers();
    retours = await RetourServices.getAllRetour();
    versements = await VerssementServices.getAllverssement();
    if (!mounted) return;
    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (loading) {
      return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Appstyle.radiusCard),
        boxShadow: [BoxShadow(color: Appstyle.shadowTint.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.clientSituationLabel, style: Appstyle.textLB.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.client,
                  child: TextListe(
                    value: selectedClient?.nom,
                    items: clients.map((c) => c.nom).toList(),
                    clearable: true,
                    onChanged: (v) {
                      setState(() => selectedClient = clients.firstWhereOrNull((c) => c.nom == v));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              MainButton(
                text: l10n.details,
                icon: Icons.visibility,
                color: Appstyle.violet,
                onPressed: selectedClient == null
                    ? null
                    : () async {
                        await SituationClientDialog(
                          context,
                          client: selectedClient!,
                          panniers: panniers,
                          retours: retours,
                          versements: versements,
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
