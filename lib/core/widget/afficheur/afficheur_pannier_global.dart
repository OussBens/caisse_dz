import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class AfficheurPaniersGlobalWidget extends StatefulWidget {
  final int nombrePaniers;
  final double totalPanier;
  final String produitStar;
  final double produitStarQuantite;
  final double moyenneParPanier;

  const AfficheurPaniersGlobalWidget({
    super.key,
    required this.nombrePaniers,
    required this.totalPanier,
    required this.produitStar,
    required this.produitStarQuantite,
    required this.moyenneParPanier,
  });

  @override
  State<AfficheurPaniersGlobalWidget> createState() => _AfficheurPaniersGlobalWidgetState();
}

class _AfficheurPaniersGlobalWidgetState extends State<AfficheurPaniersGlobalWidget>
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
  void didUpdateWidget(AfficheurPaniersGlobalWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nombrePaniers != widget.nombrePaniers ||
        oldWidget.totalPanier != widget.totalPanier ||
        oldWidget.produitStar != widget.produitStar ||
        oldWidget.produitStarQuantite != widget.produitStarQuantite ||
        oldWidget.moyenneParPanier != widget.moyenneParPanier) {
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
              icon: Icons.shopping_cart_outlined,
              title: l10n.totalPaniers,
              value: widget.nombrePaniers.toDouble(),
              subtitle: l10n.allCarts,
              suffix: l10n.panier,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.gris,
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.totalCartAmount,
              value: widget.totalPanier,
              subtitle: l10n.sumOfAllCarts,
              suffix: l10n.currency,
              animation: _controller,
              isMoney: true,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.blueF,
              icon: Icons.star,
              title: l10n.starProduct,
              value: widget.produitStarQuantite,
              subtitle: "${NumberFormatUtil.formatMontant(widget.produitStarQuantite, decimales: 0)} ${l10n.times}",
              suffix: "",
              animation: _controller,
              showValueAsText: true,
              textValue: widget.produitStar,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.successInk,
              icon: Icons.bar_chart,
              title: l10n.averagePerCart,
              value: widget.moyenneParPanier,
              subtitle: l10n.averageValue,
              suffix: l10n.currency,
              animation: _controller,
              isMoney: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _space() => const SizedBox(width: 10); // ✅ Réduit de 14 à 10
}

class _AnimatedStatCard extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String title;
  final double value;
  final String subtitle;
  final String suffix;
  final Animation<double> animation;
  final bool isMoney;
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
    this.isMoney = false,
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
            borderRadius: BorderRadius.circular(Appstyle.radiusCard), // ✅ Réduit de 24 à 18
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
                  borderRadius: BorderRadius.circular(Appstyle.radiusMD), // ✅ Réduit de 16 à 12
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
                      isMoney: isMoney,
                    ),
                    if (suffix.isNotEmpty) ...[
                      const SizedBox(width: 3), // ✅ Réduit de 4 à 3
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
                  fontSize: 10, // ✅ Ajout d'une taille réduite
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
  final bool isMoney;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    required this.animation,
    this.isMoney = false,
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
          formattedValue = isMoney
              ? NumberFormatUtil.formatMontant(displayValue, decimales: 0)
              : NumberFormatUtil.formatMontant(displayValue, decimales: 1);
        }
        return Text(
          formattedValue,
          style: style,
        );
      },
    );
  }
}