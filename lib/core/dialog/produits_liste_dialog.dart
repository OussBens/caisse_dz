import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'base_dialog.dart';

/// Un élément du bandeau de statistiques affiché sous le titre.
class StatBadge {
  final String label;
  final String valeur;
  final Color couleur;

  const StatBadge({
    required this.label,
    required this.valeur,
    this.couleur = Appstyle.violet,
  });
}

/// Badge arrondi réutilisé pour les cellules qté/prix/taux des tableaux
/// "liste de produits" (pannier, pack, remise, besoin, magasin).
Widget pilluleCellule(String texte, Color couleur) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: couleur.withOpacity(0.1),
      borderRadius: BorderRadius.circular(Appstyle.radiusMD),
    ),
    child: Text(
      texte,
      style: Appstyle.textSB.copyWith(color: couleur),
    ),
  );
}

/// Dialogue unifié "liste des produits de X", utilisé par les modules
/// besoinlist / pannier / pack / remise / magasin pour afficher, en lecture
/// seule, le tableau des produits rattachés à une entité.
class ProduitsListeDialog extends StatelessWidget {
  final String titre;
  final List<Widget> sousTitre;
  final List<StatBadge> stats;
  final List<DataColumn> colonnes;
  final List<DataRow> lignes;
  final String messageVide;

  const ProduitsListeDialog({
    super.key,
    required this.titre,
    this.sousTitre = const [],
    this.stats = const [],
    required this.colonnes,
    required this.lignes,
    required this.messageVide,
  });

  /// Ouvre le dialogue. Point d'entrée unique pour les 5 modules.
  static Future<void> afficher({
    required BuildContext context,
    required String titre,
    List<Widget> sousTitre = const [],
    List<StatBadge> stats = const [],
    required List<DataColumn> colonnes,
    required List<DataRow> lignes,
    required String messageVide,
  }) {
    return showDialog(
      context: context,
      barrierColor: Appstyle.gris.withOpacity(0.4),
      builder: (_) => ProduitsListeDialog(
        titre: titre,
        sousTitre: sousTitre,
        stats: stats,
        colonnes: colonnes,
        lignes: lignes,
        messageVide: messageVide,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return BaseDialog(
      width: 900,
      height: 600,
      header: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: Appstyle.textLB),
          if (sousTitre.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...sousTitre,
          ],
          if (stats.isNotEmpty) ...[
            const SizedBox(height: 8),
            _bandeauStats(),
          ],
        ],
      ),
      content: lignes.isEmpty
          ? Center(
              child: Text(
                messageVide,
                style: Appstyle.textSB.copyWith(color: Appstyle.gris),
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: DataTable(
                      headingRowColor:
                          MaterialStateProperty.all(Appstyle.violet.withOpacity(0.1)),
                      headingTextStyle: Appstyle.textSB.copyWith(
                        color: Appstyle.violet,
                        fontWeight: FontWeight.bold,
                      ),
                      columnSpacing: 16,
                      columns: colonnes,
                      rows: lignes,
                    ),
                  ),
                );
              },
            ),
      footer: Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton.icon(
          icon: Icon(Icons.close, color: Appstyle.Tblanc),
          label: Text(l10n.close, style: Appstyle.textSB.copyWith(color: Appstyle.Tblanc)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Appstyle.violet,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Appstyle.radiusMD)),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _bandeauStats() {
    final enfants = <Widget>[];
    for (var i = 0; i < stats.length; i++) {
      if (i > 0) {
        enfants.add(Container(width: 1, height: 30, color: Appstyle.gris.withOpacity(0.3)));
      }
      final s = stats[i];
      enfants.add(Column(
        children: [
          Text(s.label, style: Appstyle.textSB.copyWith(fontSize: 12, color: Appstyle.gris)),
          Text(s.valeur, style: Appstyle.textLB.copyWith(color: s.couleur, fontSize: 16)),
        ],
      ));
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Appstyle.violet.withOpacity(0.1),
        borderRadius: BorderRadius.circular(Appstyle.radiusSM),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: enfants,
      ),
    );
  }
}
