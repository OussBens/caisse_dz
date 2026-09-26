import 'package:flutter/material.dart';
import 'package:caisse_dz/core/theme/app_style.dart';
import '../../../l10n/app_localizations.dart';
import 'package:caisse_dz/core/utilis/number_format.dart';

class DashboardZakat extends StatefulWidget {
  final double totalZakat;
  final int zakatPayee;
  final int zakatNonPayee;
  final double nissab;
  final double tauxZakat;

  const DashboardZakat({
    super.key,
    required this.totalZakat,
    required this.zakatPayee,
    required this.zakatNonPayee,
    required this.nissab,
    required this.tauxZakat,
  });

  @override
  State<DashboardZakat> createState() => _DashboardZakatState();
}

class _DashboardZakatState extends State<DashboardZakat>
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
  void didUpdateWidget(DashboardZakat oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalZakat != widget.totalZakat ||
        oldWidget.zakatPayee != widget.zakatPayee ||
        oldWidget.zakatNonPayee != widget.zakatNonPayee ||
        oldWidget.nissab != widget.nissab ||
        oldWidget.tauxZakat != widget.tauxZakat) {
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
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.totalZakat,
              value: widget.totalZakat,
              subtitle: l10n.zakatPaid,
              suffix: l10n.currency,
              animation: _controller,
              isMoney: true,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.green,
              icon: Icons.check_circle_outline,
              title: l10n.paid,
              value: widget.zakatPayee.toDouble(),
              subtitle: l10n.zakatPaid,
              suffix: l10n.zakats,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Colors.red,
              icon: Icons.cancel_outlined,
              title: l10n.unpaid,
              value: widget.zakatNonPayee.toDouble(),
              subtitle: l10n.zakatUnpaid,
              suffix: l10n.zakats,
              animation: _controller,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.blueF,
              icon: Icons.trending_up,
              title: l10n.nissab,
              value: widget.nissab,
              subtitle: l10n.threshold,
              suffix: l10n.currency,
              animation: _controller,
              isMoney: true,
            ),
            _space(),
            _AnimatedStatCard(
              color: Appstyle.lavande,
              icon: Icons.percent,
              title: l10n.rate,
              value: widget.tauxZakat,
              subtitle: l10n.appliedRate,
              suffix: "%",
              animation: _controller,
              isPercentage: true,
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
  final bool isMoney;
  final bool isPercentage;

  const _AnimatedStatCard({
    required this.color,
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.suffix,
    required this.animation,
    this.isMoney = false,
    this.isPercentage = false,
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
                    isPercentage: isPercentage,
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
  final bool isMoney;
  final bool isPercentage;

  const _AnimatedCounter({
    required this.value,
    required this.style,
    required this.animation,
    this.isMoney = false,
    this.isPercentage = false,
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
        if (isPercentage) {
          formattedValue = NumberFormatUtil.formatMontant(displayValue, decimales: 1);
        } else if (displayValue == displayValue.toInt()) {
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