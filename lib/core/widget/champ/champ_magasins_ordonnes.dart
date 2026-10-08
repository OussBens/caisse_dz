import 'package:caisse_dz/core/theme/app_style.dart';
import 'package:caisse_dz/data/models/magasin.dart';
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

/// Sélection ORDONNÉE des magasins d'un utilisateur (multi-magasin) : le 1er
/// est le magasin principal (Entrée / Smart Scan, premier servi à la vente),
/// les suivants sont utilisés dans l'ordre. Flèches pour réordonner, croix
/// pour retirer, menu pour ajouter. Au moins un magasin reste toujours.
class ChampMagasinsOrdonnes extends StatelessWidget {
  final List<Magasin> magasins;
  final List<String> selection;
  final ValueChanged<List<String>> onChanged;

  const ChampMagasinsOrdonnes({
    super.key,
    required this.magasins,
    required this.selection,
    required this.onChanged,
  });

  String _nom(String code) => magasins.where((m) => m.code == code).firstOrNull?.nom ?? code;

  void _deplacer(int index, int delta) {
    final liste = [...selection];
    final cible = index + delta;
    if (cible < 0 || cible >= liste.length) return;
    final m = liste.removeAt(index);
    liste.insert(cible, m);
    onChanged(liste);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final disponibles = magasins.where((m) => !selection.contains(m.code)).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Appstyle.grischamp,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < selection.length; i++)
            Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: i == 0 ? Appstyle.violet.withOpacity(0.5) : Appstyle.grisC),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 11,
                    backgroundColor: i == 0 ? Appstyle.violet : Appstyle.gris,
                    child: Text('${i + 1}', style: Appstyle.textXS.copyWith(color: Colors.white, fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_nom(selection[i]), style: Appstyle.textSB, overflow: TextOverflow.ellipsis)),
                  if (i == 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Appstyle.violetC, borderRadius: BorderRadius.circular(8)),
                      child: Text(l10n.mainStore, style: Appstyle.textXS.copyWith(color: Appstyle.violet, fontWeight: FontWeight.w600)),
                    ),
                  IconButton(
                    tooltip: l10n.moveUp,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_upward, size: 18),
                    onPressed: i == 0 ? null : () => _deplacer(i, -1),
                  ),
                  IconButton(
                    tooltip: l10n.moveDown,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.arrow_downward, size: 18),
                    onPressed: i == selection.length - 1 ? null : () => _deplacer(i, 1),
                  ),
                  IconButton(
                    tooltip: l10n.remove,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.close, size: 18, color: Appstyle.red),
                    onPressed: selection.length <= 1 ? null : () => onChanged([...selection]..removeAt(i)),
                  ),
                ],
              ),
            ),
          if (disponibles.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: l10n.addStore,
              onSelected: (code) => onChanged([...selection, code]),
              itemBuilder: (_) => [
                for (final m in disponibles) PopupMenuItem(value: m.code, child: Text(m.nom)),
              ],
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add_circle_outline, size: 18, color: Appstyle.violet),
                    const SizedBox(width: 6),
                    Text(l10n.addStore, style: Appstyle.textSB.copyWith(color: Appstyle.violet)),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.storesOrderHelp, style: Appstyle.textXS.copyWith(color: Appstyle.gris)),
          ),
        ],
      ),
    );
  }
}
