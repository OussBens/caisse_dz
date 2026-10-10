import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

/// Carte "afficheur" globale du module Besoin (aucune sélection), commune
/// aux trois onglets : Besoin list, Produits en rupture, Produits expirés.
class AfficheurBesoinGlobalWidget extends StatefulWidget {
  final int nombreProduits;
  final int nombreBesoinList;
  final int nombreProduitsRupture;
  final int nombreProduitsExpires;

  const AfficheurBesoinGlobalWidget({
    super.key,
    required this.nombreProduits,
    required this.nombreBesoinList,
    required this.nombreProduitsRupture,
    required this.nombreProduitsExpires,
  });

  @override
  State<AfficheurBesoinGlobalWidget> createState() => _AfficheurBesoinGlobalWidgetState();
}

class _AfficheurBesoinGlobalWidgetState extends State<AfficheurBesoinGlobalWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _controller.forward();
  }

  @override
  void didUpdateWidget(AfficheurBesoinGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreProduits != widget.nombreProduits ||
        oldWidget.nombreBesoinList != widget.nombreBesoinList ||
        oldWidget.nombreProduitsRupture != widget.nombreProduitsRupture ||
        oldWidget.nombreProduitsExpires != widget.nombreProduitsExpires) {
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
              icon: Icons.inventory_2_outlined,
              title: l10n.products,
              value: widget.nombreProduits.toDouble(),
              subtitle: l10n.totalProducts,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.indigo,
              icon: Icons.playlist_add_check,
              title: l10n.besoinList,
              value: widget.nombreBesoinList.toDouble(),
              subtitle: l10n.stockRequests,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.warning,
              icon: Icons.remove_shopping_cart_outlined,
              title: l10n.outOfStock,
              value: widget.nombreProduitsRupture.toDouble(),
              subtitle: l10n.outOfStockProducts,
              suffix: "",
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.danger,
              icon: Icons.event_busy_outlined,
              title: l10n.expiredProducts,
              value: widget.nombreProduitsExpires.toDouble(),
              subtitle: l10n.expiryDate,
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
