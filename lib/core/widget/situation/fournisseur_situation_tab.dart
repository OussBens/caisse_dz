import 'package:caisse_dz/Services/Fournisseur.dart';
import 'package:caisse_dz/Services/Retour.dart';
import 'package:caisse_dz/Services/SmartScan.dart';
import 'package:caisse_dz/Services/Verssement.dart';
import 'package:caisse_dz/core/dialog/fournisseur/fournisseur_situation.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/core/widget/button/main_button.dart';
import 'package:caisse_dz/core/widget/champ/champ_avec_label.dart';
import 'package:caisse_dz/core/widget/champ/liste_champ.dart';
import 'package:caisse_dz/data/models/fournisseur.dart';
import 'package:caisse_dz/data/models/retour.dart';
import 'package:caisse_dz/data/models/smart_scan.dart';
import 'package:caisse_dz/data/models/verssement.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

/// Onglet "Situation Fournisseur" (Dashboard > Situation) : équivalent de
/// [ClientSituationTab] pour [SituationFournisseurDialog], déjà utilisé
/// depuis le bouton "Situation" de fournisseur_screen.dart.
class FournisseurSituationTab extends StatefulWidget {
  const FournisseurSituationTab({super.key});

  @override
  State<FournisseurSituationTab> createState() => _FournisseurSituationTabState();
}

class _FournisseurSituationTabState extends State<FournisseurSituationTab> {
  bool loading = true;

  List<Fournisseur> fournisseurs = [];
  List<SmartScan> smartScans = [];
  List<Retour> retours = [];
  List<Verssement> versements = [];

  Fournisseur? selectedFournisseur;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    fournisseurs = await FournisseurServices.getAllFournisseurs();
    smartScans = await SmartScanServices.getAllSmartScans();
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
          Text(l10n.supplierSituationLabel, style: Appstyle.textLB.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: ChampAvecLabel(
                  label: l10n.fournisseur,
                  child: TextListe(
                    value: selectedFournisseur?.nom,
                    items: fournisseurs.map((f) => f.nom).toList(),
                    clearable: true,
                    onChanged: (v) {
                      setState(() => selectedFournisseur = fournisseurs.firstWhereOrNull((f) => f.nom == v));
                    },
                  ),
                ),
              ),
              const SizedBox(width: 20),
              MainButton(
                text: l10n.details,
                icon: Icons.visibility,
                color: Appstyle.violet,
                onPressed: selectedFournisseur == null
                    ? null
                    : () async {
                        await SituationFournisseurDialog(
                          context,
                          fournisseur: selectedFournisseur!,
                          smartScans: smartScans,
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
