import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';

class AfficheurStockGlobalWidget extends StatefulWidget {
  final int nombreProduitsStock;
  final int nombreSmartScan;
  final int nombrePanniers;
  final int nombreRetours;
  final int nombreBesoinList;
  final int nombreSorties;

  const AfficheurStockGlobalWidget({
    super.key,
    required this.nombreProduitsStock,
    required this.nombreSmartScan,
    required this.nombrePanniers,
    required this.nombreRetours,
    required this.nombreBesoinList,
    required this.nombreSorties,
  });

  @override
  State<AfficheurStockGlobalWidget> createState() => _AfficheurStockGlobalWidgetState();
}

class _AfficheurStockGlobalWidgetState extends State<AfficheurStockGlobalWidget>
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
  void didUpdateWidget(AfficheurStockGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombreProduitsStock != widget.nombreProduitsStock ||
        oldWidget.nombreSmartScan != widget.nombreSmartScan ||
        oldWidget.nombrePanniers != widget.nombrePanniers ||
        oldWidget.nombreRetours != widget.nombreRetours ||
        oldWidget.nombreBesoinList != widget.nombreBesoinList ||
        oldWidget.nombreSorties != widget.nombreSorties) {
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
              color: Appstyle.blueC,
              icon: Icons.inventory_outlined,
              title: l10n.stock,
              value: widget.nombreProduitsStock.toDouble(),
              subtitle: l10n.availableProducts,
              suffix: l10n.products,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.blueF,
              icon: Icons.qr_code_scanner,
              title: l10n.smartScan,
              value: widget.nombreSmartScan.toDouble(),
              subtitle: l10n.scannedItems,
              suffix: l10n.smartScan,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.teal,
              icon: Icons.shopping_cart_outlined,
              title: l10n.carts,
              value: widget.nombrePanniers.toDouble(),
              subtitle: l10n.activeCarts,
              suffix: l10n.carts,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.redAccent.shade400,
              icon: Icons.undo,
              title: l10n.returns,
              value: widget.nombreRetours.toDouble(),
              subtitle: l10n.returnedProducts,
              suffix: l10n.returns,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.orange,
              icon: Icons.playlist_add_check,
              title: l10n.needs,
              value: widget.nombreBesoinList.toDouble(),
              subtitle: l10n.stockRequests,
              suffix: l10n.besoinList,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.gris,
              icon: Icons.exit_to_app,
              title: l10n.exits,
              value: widget.nombreSorties.toDouble(),
              subtitle: l10n.exitedProducts,
              suffix: l10n.exits,
              animation: _controller,
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