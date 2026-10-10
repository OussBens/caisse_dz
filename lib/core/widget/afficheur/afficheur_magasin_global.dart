import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Carte "afficheur" globale du module Magasin (aucune sélection) — même
/// structure que AfficheurStockGlobalWidget/AfficheurGestionCaisseGlobalWidget,
/// réutilisée par les deux onglets (Magasins et Transferts).
class AfficheurMagasinGlobalWidget extends StatefulWidget {
  final int nombreMagasins;
  final int nombreMagasinsActifs;
  final int nombreTransferts;
  final double quantiteTotaleTransferee;

  const AfficheurMagasinGlobalWidget({
    super.key,
    required this.nombreMagasins,
    required this.nombreMagasinsActifs,
    required this.nombreTransferts,
    required this.quantiteTotaleTransferee,
  });

  @override
  State<AfficheurMagasinGlobalWidget> createState() => _AfficheurMagasinGlobalWidgetState();
}

class _AfficheurMagasinGlobalWidgetState extends State<AfficheurMagasinGlobalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AfficheurMagasinGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreMagasins != widget.nombreMagasins ||
        oldWidget.nombreMagasinsActifs != widget.nombreMagasinsActifs ||
        oldWidget.nombreTransferts != widget.nombreTransferts ||
        oldWidget.quantiteTotaleTransferee != widget.quantiteTotaleTransferee) {
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
              icon: Icons.storefront_outlined,
              title: l10n.stores,
              value: widget.nombreMagasins.toDouble(),
              subtitle: l10n.stores,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.success,
              icon: Icons.check_circle_outline,
              title: l10n.active,
              value: widget.nombreMagasinsActifs.toDouble(),
              subtitle: l10n.stores,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.indigo,
              icon: Icons.swap_horiz,
              title: l10n.transfers,
              value: widget.nombreTransferts.toDouble(),
              subtitle: l10n.transfers,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.crevete,
              icon: Icons.inventory_2_outlined,
              title: l10n.quantity,
              value: widget.quantiteTotaleTransferee,
              subtitle: l10n.transfers,
              suffix: "",
              animation: _controller,
            ),
          ],
        ),
      ),
    );
  }

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

  const _AnimatedStatCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    required this.animation,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: animation,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(Appstyle.radiusCard),
            boxShadow: [
              BoxShadow(color: color.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
            ],
            border: Border.all(color: color.withOpacity(0.2), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 11),
              Text(
                title,
                style: Appstyle.textSB.copyWith(color: color, fontWeight: FontWeight.w600, letterSpacing: 0.4),
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _AnimatedCounter(
                    value: value,
                    style: Appstyle.textXXLB.copyWith(color: color, fontWeight: FontWeight.bold, fontSize: 26, height: 1),
                    animation: animation,
                  ),
                  if (suffix.isNotEmpty) ...[
                    const SizedBox(width: 3),
                    Text(" $suffix", style: Appstyle.textSB.copyWith(color: color.withOpacity(0.7), fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Appstyle.textXS.copyWith(color: color.withOpacity(0.8), fontWeight: FontWeight.w400, fontSize: 10),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
              const SizedBox(height: 8),
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
        if (animation.isCompleted) displayValue = value;
        final formattedValue = displayValue == displayValue.toInt()
            ? displayValue.toInt().toString()
            : NumberFormatUtil.formatMontant(displayValue, decimales: 1);
        return Text(formattedValue, style: style);
      },
    );
  }
}
