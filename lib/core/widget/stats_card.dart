// core/widget/stats_card.dart
import 'package:caisse_dz/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../theme/app_style.dart';

/// Chiffres clés affichés en haut des dialogs « détail » des modules.
///
/// Chaque [StatsItem] est rendu comme une card de l'afficheur global
/// (carte blanche, bordure colorée, pastille d'icône, titre, grande valeur,
/// trait dégradé en bas), les cards étant réparties sur une ligne.
///
/// [backgroundColor] (conservé pour compatibilité) devient la couleur de la
/// première card ; les suivantes prennent la palette de l'afficheur.
class StatsCard extends StatelessWidget {
  final List<StatsItem> items;
  final Color? backgroundColor;
  final double? borderRadius;
  final EdgeInsetsGeometry? padding;
  final bool isCompact;

  const StatsCard({
    Key? key,
    required this.items,
    this.backgroundColor,
    this.borderRadius,
    this.padding,
    this.isCompact = false,
  }) : super(key: key);

  /// Même ordre de couleurs que les afficheurs globaux.
  static const List<Color> _palette = [
    Appstyle.violet,
    Appstyle.indigo,
    Appstyle.green,
    Appstyle.crevete,
    Appstyle.blueF,
    Appstyle.maron,
    Appstyle.blueC,
    Appstyle.green2,
  ];

  Color _couleur(int index) {
    if (index == 0 && backgroundColor != null) {
      // Les appelants passent souvent une couleur atténuée (withOpacity 0.7) :
      // la card a besoin de la teinte pleine.
      return backgroundColor!.withOpacity(1);
    }
    return _palette[index % _palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final devise = AppLocalizations.of(context)?.currency;
    final cards = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) cards.add(SizedBox(width: isCompact ? 8 : 10));
      cards.add(Expanded(
        child: _StatCard(
          item: items[i],
          color: _couleur(i),
          icon: items[i].icon ?? _iconeParDefaut(items[i].value, devise),
          radius: borderRadius ?? (isCompact ? 12 : 18),
          padding: padding ?? EdgeInsets.all(isCompact ? 10 : 14),
          compact: isCompact,
        ),
      ));
    }
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: cards),
    );
  }

  static final RegExp _date = RegExp(r'^\d{1,4}[-/]\d{1,2}[-/]\d{1,4}');
  static final RegExp _nombre = RegExp(r'^[-+]?[\d\s.,]+%?$');

  /// Icône déduite de la valeur quand l'appelant n'en fournit pas.
  static IconData _iconeParDefaut(dynamic value, String? devise) {
    if (value is num) return Icons.tag;
    final texte = value?.toString().trim() ?? '';
    if (devise != null && devise.isNotEmpty && texte.endsWith(devise)) {
      return Icons.payments_outlined;
    }
    if (_date.hasMatch(texte)) return Icons.event_outlined;
    if (texte.endsWith('%')) return Icons.percent;
    if (_nombre.hasMatch(texte)) return Icons.tag;
    return Icons.info_outline;
  }
}

class _StatCard extends StatelessWidget {
  final StatsItem item;
  final Color color;
  final IconData icon;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool compact;

  const _StatCard({
    required this.item,
    required this.color,
    required this.icon,
    required this.radius,
    required this.padding,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: color.withOpacity(0.2), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(compact ? 5 : 7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: compact ? 16 : 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.label,
                  style: Appstyle.textSB.copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: compact ? 8 : 11),
          // Les montants peuvent être longs : réduits plutôt que coupés.
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              item.value?.toString() ?? '-',
              style: Appstyle.textXXLB.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: compact ? 18 : 22,
                height: 1,
              ),
            ),
          ),
          const Spacer(),
          SizedBox(height: compact ? 6 : 10),
          Container(
            height: 2,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [color.withOpacity(0.6), color.withOpacity(0.1)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class StatsItem {
  final String label;
  final dynamic value;
  final IconData? icon;

  StatsItem({
    required this.label,
    required this.value,
    this.icon,
  });
}
