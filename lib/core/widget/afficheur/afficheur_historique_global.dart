import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import '../../../data/constant.dart';
import '../../../data/models/histore.dart';
import '../../../data/models/utilisateur.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class DashboardHistorique extends StatefulWidget {
  final List<Historique> historiques;
  final List<Utilisateur> utilisateurs;

  const DashboardHistorique({
    super.key,
    required this.historiques,
    this.utilisateurs = const [],
  });

  @override
  State<DashboardHistorique> createState() => _DashboardHistoriqueState();
}

class _DashboardHistoriqueState extends State<DashboardHistorique>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(DashboardHistorique oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.historiques.length != widget.historiques.length) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // `oper` contient les valeurs de ListsConst.typeHisto (insertion /
    // modification / suppression / login / logout), parfois avec une
    // majuscule pour d'anciennes lignes ('Login') : comparaison insensible
    // à la casse.
    int compter(String oper) =>
        widget.historiques.where((h) => h.oper.toLowerCase() == oper).length;

    final total = widget.historiques.length;
    final creation = compter(ListsConst.typeHisto[0]);
    final modification = compter(ListsConst.typeHisto[1]);
    final suppression = compter(ListsConst.typeHisto[2]);
    final now = DateTime.now();
    final today = widget.historiques.where((h) =>
        h.dateCree.day == now.day &&
        h.dateCree.month == now.month &&
        h.dateCree.year == now.year).length;

    // Dernière action = la plus récente par date (la liste n'est pas
    // forcément triée), affichée par nom d'utilisateur plutôt que par code.
    final derniere = widget.historiques.isEmpty
        ? null
        : widget.historiques.reduce((a, b) => a.dateCree.isAfter(b.dateCree) ? a : b);
    final lastUser = derniere == null
        ? "-"
        : (widget.utilisateurs.firstWhereOrNull((u) => u.code == derniere.creeParCode)?.username ??
            derniere.creeParCode);

    return FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic)),
        child: Row(
          children: [
            _AnimatedStatCard(
              color: Appstyle.violet,
              icon: Icons.history_outlined,
              title: l10n.total,
              value: total.toDouble(),
              subtitle: l10n.operations,
              suffix: l10n.operations,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.green,
              icon: Icons.add_circle_outline,
              title: l10n.creations,
              value: creation.toDouble(),
              subtitle: l10n.adds,
              suffix: l10n.creations,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.orange,
              icon: Icons.edit_outlined,
              title: l10n.modifications,
              value: modification.toDouble(),
              subtitle: l10n.updates,
              suffix: l10n.modifications,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.red,
              icon: Icons.delete_outline,
              title: l10n.deletions,
              value: suppression.toDouble(),
              subtitle: l10n.deletedItems,
              suffix: l10n.deletions,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.blueF,
              icon: Icons.today,
              title: l10n.today,
              value: today.toDouble(),
              subtitle: l10n.todayOperations,
              suffix: l10n.operations,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.lavande,
              icon: Icons.person_outline,
              title: l10n.lastUser,
              value: 0,
              subtitle: l10n.lastAction,
              suffix: "",
              animation: _controller,
              showValueAsText: true,
              textValue: lastUser,
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Espace réduit de 14 à 10 (70%)
  Widget _space() => const SizedBox(width: 10);
}

class _AnimatedStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final double value;
  final String subtitle;
  final String suffix;
  final Animation<double> animation;
  final bool showValueAsText;
  final String? textValue;

  const _AnimatedStatCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    required this.animation,
    this.showValueAsText = false,
    this.textValue,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          // ✅ Padding réduit de 20 à 14 (70%)
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18), // ✅ Réduit de 24 à 18
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Icone padding réduit de 10 à 7
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12), // ✅ Réduit de 16 à 12
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20, // ✅ Réduit de 28 à 20
                ),
              ),
              // ✅ Espace réduit de 16 à 11
              const SizedBox(height: 11),
              Text(
                title,
                style: Appstyle.textSB.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4, // ✅ Réduit de 0.5 à 0.4
                ),
              ),
              // ✅ Espace réduit de 8 à 6
              const SizedBox(height: 6),
              if (showValueAsText && textValue != null)
                Text(
                  textValue!,
                  style: Appstyle.textLB.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // ✅ Réduit de 24 à 18
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _AnimatedCounter(
                      value: value,
                      style: Appstyle.textXXLB.copyWith(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 26, // ✅ Réduit de 36 à 26
                        height: 1,
                      ),
                      animation: animation,
                    ),
                    if (suffix.isNotEmpty) ...[
                      // ✅ Espace réduit de 4 à 3
                      const SizedBox(width: 3),
                      Text(
                        " $suffix",
                        style: Appstyle.textSB.copyWith(
                          color: color.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              // ✅ Espace réduit de 8 à 6
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Appstyle.textXS.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                  fontSize: 10, // ✅ Taille réduite
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              // ✅ Espace réduit de 12 à 8
              const SizedBox(height: 8),
              Container(
                height: 2, // ✅ Réduit de 3 à 2
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      color.withOpacity(0.6),
                      color.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedCounter extends StatelessWidget {
  final double value;
  final TextStyle style;
  final Animation<double> animation;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        double displayValue = value * animation.value;
        if (animation.isCompleted) {
          displayValue = value;
        }
        String formattedValue;
        if (displayValue == displayValue.toInt()) {
          formattedValue = displayValue.toInt().toString();
        } else {
          formattedValue = NumberFormatUtil.formatMontant(displayValue, decimales: 1);
        }
        return Text(
          formattedValue,
          style: style,
        );
      },
    );
  }
}