import 'package:flutter/material.dart';
import '../../../data/models/histore.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';

class DashboardHistorique extends StatefulWidget {
  final List<Historique> historiques;

  const DashboardHistorique({
    super.key,
    required this.historiques,
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

    final total = widget.historiques.length;
    final creation = widget.historiques.where((h) => h.oper == "Création").length;
    final modification = widget.historiques.where((h) => h.oper == "Modification").length;
    final suppression = widget.historiques.where((h) => h.oper == "Suppression").length;
    final today = widget.historiques.where((h) =>
    h.dateCree.day == DateTime.now().day &&
        h.dateCree.month == DateTime.now().month &&
        h.dateCree.year == DateTime.now().year
    ).length;
    final lastUser = widget.historiques.isNotEmpty
        ? widget.historiques.last.creeParCode
        : "-";

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

  Widget _space() => const SizedBox(width: 14);
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
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
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
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Appstyle.textSB.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              if (showValueAsText && textValue != null)
                Text(
                  textValue!,
                  style: Appstyle.textLB.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
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
                        fontSize: 36,
                        height: 1,
                      ),
                      animation: animation,
                    ),
                    if (suffix.isNotEmpty) ...[
                      const SizedBox(width: 4),
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
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Appstyle.textXS.copyWith(
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w400,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              Container(
                height: 3,
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
          formattedValue = displayValue.toStringAsFixed(1);
        }
        return Text(
          formattedValue,
          style: style,
        );
      },
    );
  }
}